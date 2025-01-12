"""
game_logic.py

Manages in-memory GAMES dict, random coords from .geojson, scoring, scoreboard.
"""

import uuid
import random
import math
import logging
import json

from shapely.geometry import shape, Point
from shapely.ops import unary_union

# In-memory store: gameId -> { settings:..., rounds:[], guesses:[], finished:bool }
GAMES = {}

def load_geojson_polygons(geojson_path):
    """
    Loads a .geojson, merges polygons, returns a shapely geometry.
    Raises ValueError if empty or invalid.
    """
    logging.debug(f"[load_geojson_polygons] Loading from {geojson_path}")
    with open(geojson_path, 'r', encoding='utf-8') as f:
        data = json.load(f)

    polygons = []
    if data.get('type') == 'FeatureCollection':
        for feat in data['features']:
            polygons.append(shape(feat['geometry']))
    else:
        # single geometry or 'Feature'
        if data.get('type') == 'Feature':
            polygons.append(shape(data['geometry']))
        else:
            polygons.append(shape(data))

    unified = unary_union(polygons)
    if not unified or unified.is_empty:
        raise ValueError("No Shapely geometry can be created from the .geojson")
    return unified

def get_random_point_in_shape(shp):
    """
    Rejection sample up to 10k tries to find a point inside shape.
    """
    minx, miny, maxx, maxy = shp.bounds
    for _ in range(10000):
        x = random.uniform(minx, maxx)
        y = random.uniform(miny, maxy)
        p = Point(x, y)
        if shp.contains(p):
            return p
    logging.warning("[get_random_point_in_shape] Could not find point within shape after 10k tries.")
    return None

def get_nearest_street_view(lat, lng):
    """
    Mock function, returns the same lat/lng + a fake pano ID.
    In production, you'd call the actual Google Street View API.
    """
    logging.debug(f"[get_nearest_street_view] lat={lat}, lng={lng}")
    return (lat, lng, "mockpanoid-12345")

def haversine_distance_km(lat1, lng1, lat2, lng2):
    """
    Haversine formula => kilometers
    """
    R = 6371.0
    dLat = math.radians(lat2 - lat1)
    dLng = math.radians(lng2 - lng1)
    a = math.sin(dLat/2)**2 + math.cos(math.radians(lat1)) * math.cos(math.radians(lat2)) * math.sin(dLng/2)**2
    c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))
    dist = R * c
    return dist

def compute_score(distance_km):
    """
    If distance < 50m => 5000 points; else linear decay: max(0, 5000 - distance_km*5)
    """
    if distance_km < 0.05:
        return 5000
    raw = 5000 - (distance_km * 5)
    return max(0, int(round(raw)))

def create_custom_game(geojson_path, time_limit, round_count):
    """
    1) Load shape
    2) Generate round_count random coords
    3) For each coord => nearest StreetView
    4) Store in GAMES with a unique gameId
    """
    logging.debug(f"[create_custom_game] path={geojson_path}, time={time_limit}, rounds={round_count}")
    shp = load_geojson_polygons(geojson_path)

    rounds_data = []
    for i in range(round_count):
        pt = get_random_point_in_shape(shp)
        if pt is None:
            raise ValueError("Failed to find random location inside polygon.")
        lat, lng = pt.y, pt.x
        sv_lat, sv_lng, pano_id = get_nearest_street_view(lat, lng)
        round_info = {
            "roundIndex": i,
            "correctLat": sv_lat,
            "correctLng": sv_lng,
            "panoId": pano_id
        }
        rounds_data.append(round_info)

    game_id = str(uuid.uuid4())
    GAMES[game_id] = {
        "settings": {
            "geojsonPath": geojson_path,
            "timeLimit": time_limit,
            "roundCount": round_count
        },
        "rounds": rounds_data,
        "guesses": [],
        "finished": False
    }
    logging.debug(f"[create_custom_game] Created gameId={game_id}")
    return game_id

def record_guess(game_id, round_index, user_lat, user_lng):
    """
    Adds guess => distance => score. Round result returned as partial.
    Also includes correctLat/correctLng in the response for immediate feedback.
    """
    if game_id not in GAMES:
        raise ValueError("Game ID not found.")

    game_data = GAMES[game_id]
    if game_data["finished"]:
        raise ValueError("Game is already finished.")

    if round_index < 0 or round_index >= len(game_data["rounds"]):
        raise ValueError("Invalid round index.")

    correct = game_data["rounds"][round_index]
    dist_km = haversine_distance_km(
        correct["correctLat"], correct["correctLng"],
        user_lat, user_lng
    )
    points = compute_score(dist_km)

    guess_record = {
        "roundIndex": round_index,
        "userLat": user_lat,
        "userLng": user_lng,
        "distanceKm": dist_km,
        "score": points
    }
    game_data.setdefault("guesses", []).append(guess_record)
    logging.debug(f"[record_guess] game={game_id}, round={round_index}, dist={dist_km:.2f}km, pts={points}")

    # Return partial
    res = {
        "distanceKm": dist_km,
        "score": points,
        "roundIndex": round_index,
        "correctLat": correct["correctLat"],
        "correctLng": correct["correctLng"]
    }

    # keep track of totalPointsSoFar
    total_so_far = sum(g["score"] for g in game_data["guesses"])
    res["totalPointsSoFar"] = total_so_far
    return res

def finish_game(game_id):
    """
    Merge guesses with rounds => final scoreboard.
    Return scoreboard JSON: { gameId, settings, roundResults, totalScore }
    """
    if game_id not in GAMES:
        raise ValueError("Game ID not found.")
    game_data = GAMES[game_id]
    if game_data["finished"]:
        logging.debug(f"[finish_game] game={game_id} is already finished.")
        return build_final_results(game_id)

    game_data["finished"] = True
    logging.debug(f"[finish_game] game={game_id} finishing.")
    return build_final_results(game_id)

def build_final_results(game_id):
    """
    Build final scoreboard from GAMES data: each round's correct location + user guess + distance + score.
    """
    game_data = GAMES[game_id]
    rounds_data = game_data["rounds"]
    guesses_data = game_data.get("guesses", [])

    guesses_by_round = {g["roundIndex"]: g for g in guesses_data}
    total_score = 0
    final_info = []

    for rd in rounds_data:
        idx = rd["roundIndex"]
        guess = guesses_by_round.get(idx)
        if guess:
            distance_km = guess["distanceKm"]
            sc = guess["score"]
            total_score += sc
            round_res = {
                "roundIndex": idx,
                "correctLat": rd["correctLat"],
                "correctLng": rd["correctLng"],
                "panoId": rd["panoId"],
                "userLat": guess["userLat"],
                "userLng": guess["userLng"],
                "distanceKm": distance_km,
                "score": sc
            }
        else:
            # Round was never guessed => 0 score
            round_res = {
                "roundIndex": idx,
                "correctLat": rd["correctLat"],
                "correctLng": rd["correctLng"],
                "panoId": rd["panoId"],
                "userLat": None,
                "userLng": None,
                "distanceKm": None,
                "score": 0
            }
        final_info.append(round_res)

    return {
        "gameId": game_id,
        "settings": game_data["settings"],
        "roundResults": final_info,
        "totalScore": total_score
    }

def export_game_data(game_id):
    """Return entire final scoreboard JSON as a string."""
    if game_id not in GAMES:
        raise ValueError("Game not found.")
    final = build_final_results(game_id)
    return json.dumps(final, indent=2)
