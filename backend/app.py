"""
app.py

Flask app for OtterGuessr2:
 - /maps -> returns a list of .geojson files in assets/maps
 - /heartbeat -> quick connectivity check
 - /create_game, /submit_guess, /finish_game -> custom game logic
 - /download_game_data -> optional
"""

import logging
import os

from flask import Flask, jsonify, request, send_file, make_response
from flask_cors import CORS

from game_logic import (
    create_custom_game,
    record_guess,
    finish_game,
    export_game_data,
    GAMES
)

app = Flask(__name__)
CORS(app)  # Enable cross-origin requests from Flutter

logging.basicConfig(level=logging.DEBUG)

# Directory for .geojson maps
GEOJSON_FOLDER = os.path.join(os.path.dirname(__file__), "assets", "maps")

@app.route('/')
def index():
    """Basic debug route."""
    return jsonify({"message": "Custom GeoGuessr-like backend running"}), 200

@app.route('/heartbeat', methods=['GET'])
def heartbeat():
    """Check backend connectivity."""
    return jsonify({"status": "ok", "message": "Backend is reachable!"}), 200

@app.route('/maps', methods=['GET'])
def get_map_list():
    """
    Returns a JSON list of all .geojson filenames in assets/maps/.
    Example: ["Austria.geojson", "Argentina.geojson", "Antarctica.geojson"]
    """
    try:
        filenames = [
            f for f in os.listdir(GEOJSON_FOLDER)
            if f.lower().endswith('.geojson')
        ]
        logging.debug(f"[/maps] Found {len(filenames)} .geojson files.")
        return jsonify(filenames), 200
    except Exception as e:
        logging.exception("[/maps] Error listing .geojson files.")
        return jsonify({"error": str(e)}), 500

@app.route('/create_game', methods=['POST'])
def create_game_endpoint():
    """
    Creates a new game: random points in the polygon from .geojson.
    Expects JSON: { "mapName": "Austria.geojson", "timeLimit": 60, "roundCount": 5, "mode": "Classic" }
    Returns { "message": "Game created", "gameId": "<uuid>" }
    """
    data = request.get_json(force=True)
    map_name = data.get("mapName", "").strip()
    time_limit = int(data.get("timeLimit", 60))
    round_count = int(data.get("roundCount", 5))
    mode = data.get("mode", "Classic")  # future usage

    logging.debug(f"[/create_game] mapName={map_name}, timeLimit={time_limit}, roundCount={round_count}, mode={mode}")

    geo_path = os.path.join(GEOJSON_FOLDER, map_name)
    if not os.path.isfile(geo_path):
        logging.error(f"[/create_game] Map file not found: {map_name}")
        return jsonify({"error": f"Map file not found: {map_name}"}), 400

    try:
        game_id = create_custom_game(geo_path, time_limit, round_count)
        logging.debug(f"[/create_game] Created gameId={game_id}")
        return jsonify({"message": "Game created", "gameId": game_id}), 201
    except Exception as e:
        logging.exception("[/create_game] Exception while creating game.")
        return jsonify({"error": str(e)}), 500

@app.route('/submit_guess', methods=['POST'])
def submit_guess_endpoint():
    """
    Submit a guess for a specific round.
    JSON: { "gameId": "...", "roundIndex": 0, "userLat": 48.2, "userLng": 16.36 }
    Returns { "distanceKm", "score", "roundIndex", "correctLat", "correctLng", "totalPointsSoFar" }
    """
    data = request.get_json(force=True)
    game_id = data.get("gameId")
    round_index = int(data.get("roundIndex", 0))
    user_lat = float(data.get("userLat", 0.0))
    user_lng = float(data.get("userLng", 0.0))

    logging.debug(f"[/submit_guess] gameId={game_id}, roundIndex={round_index}, lat={user_lat}, lng={user_lng}")

    try:
        partial = record_guess(game_id, round_index, user_lat, user_lng)
        return jsonify(partial), 200
    except ValueError as ve:
        logging.error(f"[/submit_guess] ValueError: {ve}")
        return jsonify({"error": str(ve)}), 400
    except Exception as e:
        logging.exception("[/submit_guess] Error.")
        return jsonify({"error": str(e)}), 500

@app.route('/finish_game', methods=['POST'])
def finish_game_endpoint():
    """
    Finishes the game, returns scoreboard with round-by-round detail.
    JSON: { "gameId": "..." }
    Returns:
    {
      "gameId": "...",
      "settings": {...},
      "roundResults": [ { "roundIndex", "correctLat", "correctLng", "distanceKm", "score", ... } ],
      "totalScore": int
    }
    """
    data = request.get_json(force=True)
    game_id = data.get("gameId")
    logging.debug(f"[/finish_game] gameId={game_id}")

    try:
        final_data = finish_game(game_id)
        return jsonify(final_data), 200
    except ValueError as ve:
        logging.error(f"[/finish_game] ValueError: {ve}")
        return jsonify({"error": str(ve)}), 400
    except Exception as e:
        logging.exception("[/finish_game] Error finalizing game.")
        return jsonify({"error": str(e)}), 500

@app.route('/download_game_data', methods=['GET'])
def download_game_data():
    """
    GET /download_game_data?gameId=XXX
    Returns the entire game data as JSON for replays.
    """
    game_id = request.args.get("gameId", "")
    if not game_id:
        logging.error("[/download_game_data] Missing gameId param.")
        return jsonify({"error": "Missing gameId"}), 400
    if game_id not in GAMES:
        logging.error(f"[/download_game_data] Invalid gameId={game_id}")
        return jsonify({"error": "Invalid gameId"}), 404

    try:
        data_str = export_game_data(game_id)
        response = make_response(data_str)
        response.headers["Content-Disposition"] = f"attachment; filename=game_{game_id}.json"
        response.mimetype = "application/json"
        return response
    except Exception as e:
        logging.exception("[/download_game_data] Export error.")
        return jsonify({"error": str(e)}), 500

if __name__ == "__main__":
    app.run(debug=True, port=5000)
