"""
custom_game_routes.py

Flask Blueprint for singleplayer sessions with unique session URLs:
 - /start_game  (POST) => Returns a sessionId
 - /join_game/<sessionId>/<roundNumber> => The user can rejoin a session, or move to that round
 - /submit_guess (POST)
 - /end_game (POST)

We store data in 'active_games' dict, keyed by sessionId.
Session-based route: otterguessr.at/<sessionId>/<roundNumber> (for client side).

Debug statements included.
"""

import os
import time
import logging
import json
import random
from flask import Blueprint, request, jsonify
from custom_mode_logic import (
    parse_geojson_and_get_polygon,
    get_random_location_in_polygon,
    get_nearest_streetview,
    compute_distance_km,
    compute_score
)

custom_mode_bp = Blueprint("custom_mode_bp", __name__)

# Adjust to your 'assets/maps' location
MAPS_DIR = os.path.join(os.path.dirname(__file__), 'assets', 'maps')

# In-memory store: sessionId -> gameData
# gameData = {
#   "mode": str,
#   "mapFile": str,
#   "timeLimit": int,
#   "roundCount": int,
#   "rounds": [
#       {
#         "lat": float,
#         "lng": float,
#         "streetLat": float,
#         "streetLng": float,
#         "guessedLat": float or None,
#         "guessedLng": float or None,
#         "distanceKm": float or None,
#         "points": int or None
#       }, ...
#   ],
#   "totalPoints": int
# }
active_games = {}

@custom_mode_bp.route('/start_game', methods=['POST'])
def start_game():
    """
    POST JSON:
    {
      "mapFile": "Argentina.geojson",
      "timeLimit": 60,
      "roundCount": 5,
      "mode": "Classic"
    }

    Returns:
    {
      "sessionId": "ABCDEFG12345",
      "roundCount": 5,
      "timeLimit": 60,
      "mode": "Classic"
    }

    We build session data, store in active_games[sessionId].
    """
    data = request.get_json(force=True)
    map_file = data.get('mapFile', '')
    time_limit = data.get('timeLimit', 60)
    round_count = data.get('roundCount', 5)
    mode = data.get('mode', 'Custom')

    logging.debug(f"[start_game] Received: mapFile={map_file}, timeLimit={time_limit}, roundCount={round_count}, mode={mode}")

    # Build absolute path
    abs_path = os.path.join(MAPS_DIR, map_file)
    try:
        polygon = parse_geojson_and_get_polygon(abs_path)
    except Exception as e:
        logging.error(f"[start_game] parse error: {str(e)}")
        return jsonify({"error": f"Could not parse .geojson: {str(e)}"}), 400

    # Generate random rounds
    rounds_data = []
    for i in range(round_count):
        lat, lng = get_random_location_in_polygon(polygon)
        if lat is None or lng is None:
            logging.error("[start_game] Could not generate random location.")
            return jsonify({"error": "Failed to generate random location."}), 500

        sLat, sLng = get_nearest_streetview(lat, lng)
        rounds_data.append({
            "lat": lat,
            "lng": lng,
            "streetLat": sLat,
            "streetLng": sLng,
            "guessedLat": None,
            "guessedLng": None,
            "distanceKm": None,
            "points": None
        })

    # Generate unique sessionId, store in dictionary
    session_id = _generate_session_id()
    active_games[session_id] = {
        "mode": mode,
        "mapFile": map_file,
        "timeLimit": time_limit,
        "roundCount": round_count,
        "rounds": rounds_data,
        "totalPoints": 0
    }

    logging.debug(f"[start_game] Created sessionId={session_id}")
    return jsonify({
        "sessionId": session_id,
        "timeLimit": time_limit,
        "roundCount": round_count,
        "mode": mode
    }), 200

@custom_mode_bp.route('/join_game/<sessionId>/<int:roundNumber>', methods=['GET'])
def join_game(sessionId, roundNumber):
    """
    GET route for continuing a session at a specific round.
    e.g. otterguessr.at/<sessionId>/<roundNumber>
    
    Returns data about that round if it exists, or an error if not found.
    """
    logging.debug(f"[join_game] sessionId={sessionId}, roundNumber={roundNumber}")

    game_data = active_games.get(sessionId)
    if not game_data:
        return jsonify({"error": "Session not found."}), 404

    if roundNumber < 1 or roundNumber > len(game_data['rounds']):
        return jsonify({"error": "Round out of range."}), 400

    # Return info about the round
    round_index = roundNumber - 1
    r = game_data['rounds'][round_index]

    return jsonify({
        "mode": game_data['mode'],
        "mapFile": game_data['mapFile'],
        "timeLimit": game_data['timeLimit'],
        "roundCount": game_data['roundCount'],
        "roundNumber": roundNumber,
        "roundInfo": {
            "streetLat": r['streetLat'],
            "streetLng": r['streetLng'],
            "distanceKm": r['distanceKm'],
            "points": r['points']
        },
        "totalPoints": game_data['totalPoints']
    }), 200

@custom_mode_bp.route('/submit_guess', methods=['POST'])
def submit_guess():
    """
    POST JSON:
    {
      "sessionId": "ABCDEFG12345",
      "roundNumber": 3,
      "guessedLat": 10.0,
      "guessedLng": 20.0
    }

    We'll update that round's distanceKm & points, totalPoints, and return result.
    """
    data = request.get_json(force=True)
    session_id = data.get('sessionId')
    round_number = data.get('roundNumber')
    guessed_lat = data.get('guessedLat')
    guessed_lng = data.get('guessedLng')

    logging.debug(f"[submit_guess] sessionId={session_id}, roundNumber={round_number}, guessedLat={guessed_lat}, guessedLng={guessed_lng}")

    game_data = active_games.get(session_id)
    if not game_data:
        return jsonify({"error": "Session not found."}), 404

    if round_number < 1 or round_number > len(game_data['rounds']):
        return jsonify({"error": "Round out of range."}), 400

    r_index = round_number - 1
    round_data = game_data['rounds'][r_index]

    if round_data['points'] is not None:
        logging.debug("[submit_guess] This round was already guessed.")
        return jsonify({"error": "Already guessed this round."}), 400

    actual_lat = round_data['streetLat']
    actual_lng = round_data['streetLng']

    distance_km = compute_distance_km(guessed_lat, guessed_lng, actual_lat, actual_lng)
    points = compute_score(distance_km)

    round_data['guessedLat'] = guessed_lat
    round_data['guessedLng'] = guessed_lng
    round_data['distanceKm'] = distance_km
    round_data['points'] = points

    game_data['totalPoints'] += points
    logging.debug(f"[submit_guess] distance={distance_km:.2f}, points={points}, totalPoints={game_data['totalPoints']}")

    return jsonify({
        "actualLat": actual_lat,
        "actualLng": actual_lng,
        "guessedLat": guessed_lat,
        "guessedLng": guessed_lng,
        "distanceKm": distance_km,
        "points": points,
        "totalPointsSoFar": game_data['totalPoints']
    }), 200

@custom_mode_bp.route('/end_game', methods=['POST'])
def end_game():
    """
    POST JSON:
    {
      "sessionId": "ABCDEFG12345"
    }

    We'll remove the session from active_games, compile final scoreboard, return JSON.
    """
    data = request.get_json(force=True)
    session_id = data.get('sessionId')
    logging.debug(f"[end_game] sessionId={session_id}")

    game_data = active_games.pop(session_id, None)
    if not game_data:
        return jsonify({"error": "Session not found or already ended."}), 404

    # Build scoreboard
    scoreboard = []
    for r in game_data['rounds']:
        scoreboard.append({
            "actualLat": r['streetLat'],
            "actualLng": r['streetLng'],
            "guessedLat": r['guessedLat'],
            "guessedLng": r['guessedLng'],
            "distanceKm": r['distanceKm'],
            "points": r['points']
        })

    total_points = game_data['totalPoints']

    # matchJson for replay
    match_json = {
        "mode": game_data['mode'],
        "mapFile": game_data['mapFile'],
        "timeLimit": game_data['timeLimit'],
        "roundCount": game_data['roundCount'],
        "rounds": [
            {
                "lat": rd['lat'],
                "lng": rd['lng'],
                "streetLat": rd['streetLat'],
                "streetLng": rd['streetLng']
            } for rd in game_data['rounds']
        ]
    }

    logging.debug("[end_game] Completed scoreboard return.")
    return jsonify({
        "rounds": scoreboard,
        "totalPoints": total_points,
        "matchJson": match_json
    }), 200

def _generate_session_id():
    """
    Utility to create a random session ID. 
    Could be more robust: use secrets.token_urlsafe(8), etc.
    """
    import secrets
    return secrets.token_urlsafe(8)
