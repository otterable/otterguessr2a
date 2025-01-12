# server.py, do not remove this line

from flask import Flask, jsonify, send_from_directory, render_template
import os
from flask_cors import CORS  

app = Flask(__name__, template_folder='templates')
CORS(app)  # Enable CORS if your Flutter app runs on a different host/port

# Adjust this path to where your .geojson files actually reside
MAPS_FOLDER = os.path.join(os.path.dirname(__file__), 'assets', 'maps')

@app.route('/')
def debug_index():
    """
    Simple debug index to verify that the Flask server is up.
    """
    return render_template('index.html')  # Renders templates/index.html

@app.route('/heartbeat', methods=['GET'])
def heartbeat():
    """
    Returns a simple JSON to confirm the server is alive and responding.
    """
    return jsonify({"status": "ok", "message": "Backend is reachable!"}), 200

@app.route('/maps', methods=['GET'])
def get_map_list():
    """
    Returns a JSON list of all .geojson filenames in assets/maps.
    """
    try:
        # List all files in MAPS_FOLDER that end with .geojson
        filenames = [
            f for f in os.listdir(MAPS_FOLDER)
            if f.lower().endswith('.geojson')
        ]
        return jsonify(filenames), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/maps/<path:filename>', methods=['GET'])
def get_map_file(filename):
    """
    Optionally: serve a specific .geojson file if needed (like /maps/Canada.geojson).
    """
    try:
        return send_from_directory(MAPS_FOLDER, filename)
    except Exception as e:
        return jsonify({"error": str(e)}), 500

if __name__ == '__main__':
    # For local dev; remove debug=True in production
    app.run(debug=True, port=5000)
