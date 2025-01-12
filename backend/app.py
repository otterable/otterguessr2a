# app.py, do not remove this line

import time
import os
from flask import Flask, jsonify, request, render_template, send_from_directory
from flask_cors import CORS

app = Flask(__name__, template_folder='templates')
CORS(app)  # Enable CORS if your Flutter app runs on a different host/port

#######################################
# Minimal "in-memory database" example
#######################################
servers = []     # Each: { "id": int, "name": str, "mode": str, "map": str, "password": str, ... }
scoreboard = []  # Each: { "playerName": str, "score": int }

#######################################
# Adjust path to .geojson map folder
#######################################
MAPS_FOLDER = os.path.join(os.path.dirname(__file__), 'assets', 'maps')

#######################################
# TEMPLATES / DEBUG
#######################################
@app.route('/')
def debug_index():
    """
    Simple debug index to verify that the Flask server is up.
    Renders templates/index.html
    """
    return render_template('index.html')  # Make sure you have templates/index.html

@app.route('/heartbeat', methods=['GET'])
def heartbeat():
    """
    Returns a simple JSON to confirm the server is alive and responding.
    """
    return jsonify({"status": "ok", "message": "GeoGuessr-like backend is reachable!"}), 200

#######################################
# MAPS Endpoints
#######################################
@app.route('/maps', methods=['GET'])
def get_map_list():
    """
    Returns a JSON list of all .geojson filenames in assets/maps.
    """
    try:
        filenames = [f for f in os.listdir(MAPS_FOLDER) if f.lower().endswith('.geojson')]
        return jsonify(filenames), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/maps/<path:filename>', methods=['GET'])
def get_map_file(filename):
    """
    Serves a specific .geojson file if needed (e.g. /maps/Canada.geojson).
    """
    try:
        return send_from_directory(MAPS_FOLDER, filename)
    except Exception as e:
        return jsonify({"error": str(e)}), 500

#######################################
# SERVER MANAGEMENT
#######################################
@app.route('/create_server', methods=['POST'])
def create_server():
    """
    Create a new game server. Expects JSON with fields like:
    {
        "name": "MyServer",
        "mode": "Classic",
        "map": "Canada.geojson",
        "password": "12345",
        "maxPlayers": 8,
        "roundTime": 60
    }
    """
    data = request.get_json(force=True)
    server_name = data.get('name', '').strip()
    mode = data.get('mode', 'Classic')
    map_file = data.get('map', '')
    password = data.get('password', '')
    max_players = data.get('maxPlayers', 8)
    round_time = data.get('roundTime', 60)

    # Generate unique ID for the server
    server_id = int(time.time())

    new_server = {
        "id": server_id,
        "name": server_name,
        "mode": mode,
        "map": map_file,
        "password": password,
        "maxPlayers": max_players,
        "roundTime": round_time,
        "createdAt": time.ctime(),
        "players": []
    }

    servers.append(new_server)

    return jsonify({
        "message": "Server created successfully.",
        "server": new_server
    }), 201

@app.route('/join_server', methods=['POST'])
def join_server():
    """
    Join an existing server. Expects JSON like:
    {
      "serverId": 1691938584,
      "playerName": "Alice",
      "passwordAttempt": ""
    }
    """
    data = request.get_json(force=True)
    server_id = data.get('serverId')
    player_name = data.get('playerName', '').strip()
    password_attempt = data.get('passwordAttempt', '')

    found_server = next((s for s in servers if s['id'] == server_id), None)
    if not found_server:
        return jsonify({"error": "Server not found."}), 404

    # Check password
    if found_server['password'] and found_server['password'] != password_attempt:
        return jsonify({"error": "Invalid password."}), 403

    # Check capacity
    if len(found_server['players']) >= found_server['maxPlayers']:
        return jsonify({"error": "Server is full."}), 403

    # Add player
    found_server['players'].append(player_name)

    return jsonify({
        "message": f"{player_name} joined server {found_server['name']}",
        "server": found_server
    }), 200

#######################################
# SCOREBOARD
#######################################
@app.route('/scoreboard', methods=['GET'])
def get_scoreboard():
    """
    Returns a JSON list of scoreboard entries, sorted by desc. score
    """
    sorted_board = sorted(scoreboard, key=lambda x: x['score'], reverse=True)
    return jsonify(sorted_board), 200

@app.route('/scoreboard', methods=['POST'])
def update_scoreboard():
    """
    Add or update a player's score. Expects JSON:
    {
      "playerName": "Alice",
      "score": 4500
    }
    """
    data = request.get_json(force=True)
    player_name = data.get('playerName', '').strip()
    new_score = data.get('score', 0)

    existing = next((p for p in scoreboard if p['playerName'] == player_name), None)
    if existing:
        existing['score'] = new_score
    else:
        scoreboard.append({"playerName": player_name, "score": new_score})

    return jsonify({"message": "Score updated successfully."}), 200

#######################################
# RUN THE APP
#######################################
if __name__ == '__main__':
    # For local dev; remove debug=True in production
    app.run(debug=True, port=5000)
