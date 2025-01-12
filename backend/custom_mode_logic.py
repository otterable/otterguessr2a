"""
custom_mode_logic.py

- parse_geojson_and_get_polygon: Reads a .geojson into a shapely polygon.
- get_random_location_in_polygon: Chooses random lat/lng inside the polygon.
- get_nearest_streetview: Mock or partial example of using Google Street View.
- compute_distance_km, compute_score: Haversine & GeoGuessr-like scoring.

Dependencies:
  pip install shapely

Debug statements with logging are included.
"""

import json
import math
import random
import logging
import os
from shapely.geometry import shape, Point

def parse_geojson_and_get_polygon(geojson_path):
    """
    Reads a .geojson file from an absolute path, returns shapely polygon.
    
    - geojson_path: absolute path to the .geojson file
    """
    logging.debug(f"[parse_geojson_and_get_polygon] Reading file: {geojson_path}")
    with open(geojson_path, 'r', encoding='utf-8') as f:
        data = json.load(f)

    if data.get('type') == 'FeatureCollection':
        polygon_geom = shape(data['features'][0]['geometry'])
    elif data.get('type') == 'Feature':
        polygon_geom = shape(data['geometry'])
    else:
        polygon_geom = shape(data)

    logging.debug("[parse_geojson_and_get_polygon] Polygon parsed successfully.")
    return polygon_geom

def get_random_location_in_polygon(polygon):
    """
    Returns (lat, lng) inside 'polygon' or (None, None) if not found.
    Rejection sampling up to 10k tries.
    """
    minx, miny, maxx, maxy = polygon.bounds
    logging.debug(f"[get_random_location_in_polygon] polygon.bounds = {polygon.bounds}")

    for _ in range(10000):
        randx = random.uniform(minx, maxx)
        randy = random.uniform(miny, maxy)
        candidate = Point(randx, randy)
        if polygon.contains(candidate):
            # shapely uses x=lng, y=lat
            lat = randy
            lng = randx
            logging.debug(f"[get_random_location_in_polygon] Found lat={lat}, lng={lng}")
            return (lat, lng)

    logging.warning("[get_random_location_in_polygon] Could not find valid point after many attempts.")
    return (None, None)

def get_nearest_streetview(lat, lng):
    """
    Mock function. For real usage, you'd call Google Street View / Street View Publish APIs.
    Here, we simply return the same lat/lng.
    """
    logging.debug(f"[get_nearest_streetview] Called with lat={lat}, lng={lng}")
    return (lat, lng)

def compute_distance_km(lat1, lng1, lat2, lng2):
    """
    Haversine distance between two lat/lng in kilometers.
    """
    logging.debug("[compute_distance_km] Calculating haversine distance.")
    rlat1 = math.radians(lat1)
    rlng1 = math.radians(lng1)
    rlat2 = math.radians(lat2)
    rlng2 = math.radians(lng2)

    dlon = rlng2 - rlng1
    dlat = rlat2 - rlat1
    a = (math.sin(dlat/2)**2) + math.cos(rlat1)*math.cos(rlat2)*(math.sin(dlon/2)**2)
    c = 2*math.atan2(math.sqrt(a), math.sqrt(1 - a))
    radius_earth_km = 6371
    dist = radius_earth_km * c
    return dist

def compute_score(distance_km):
    """
    Converts distance to a GeoGuessr-like score.
    - ~0 km => 5000
    - 10 km => ~300
    - 500 km => 0
    """
    logging.debug(f"[compute_score] distance_km={distance_km}")
    if distance_km < 0.01:
        return 5000
    elif distance_km <= 10:
        return max(300, int(5000 - distance_km*470))
    elif distance_km <= 500:
        diff = distance_km - 10
        frac = diff / 490
        raw_pts = 300 - int(frac * 300)
        return max(0, raw_pts)
    else:
        return 0
