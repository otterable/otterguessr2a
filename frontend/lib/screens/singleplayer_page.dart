// lib/screens/singleplayer_page.dart
//
// Singleplayer game creation screen. We default the mode to 'Classic',
// and after creating a game, we go to the first round (StreetViewPage).

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// We'll navigate to StreetViewPage after game creation
import 'streetview_page.dart';

class SingleplayerPage extends StatefulWidget {
  const SingleplayerPage({Key? key}) : super(key: key);

  @override
  State<SingleplayerPage> createState() => _SingleplayerPageState();
}

class _SingleplayerPageState extends State<SingleplayerPage> {
  // List of maps from backend
  List<String> allMaps = [];
  String selectedMap = '';

  // Form fields
  final TextEditingController _timeCtrl = TextEditingController(text: '60');
  final TextEditingController _roundCtrl = TextEditingController(text: '5');
  // Default to "Classic" for now:
  final TextEditingController _modeCtrl = TextEditingController(text: 'Classic');

  // Example base URL for your backend
  final String baseUrl = 'http://127.0.0.1:5000';

  @override
  void initState() {
    super.initState();
    _fetchMapList();
  }

  /// Fetch .geojson filenames from /maps
  Future<void> _fetchMapList() async {
    final url = Uri.parse('$baseUrl/maps');
    try {
      final resp = await http.get(url);
      if (resp.statusCode == 200) {
        final List<dynamic> data = json.decode(resp.body);
        setState(() {
          allMaps = data.map((e) => e.toString()).toList();
          if (allMaps.isNotEmpty) {
            selectedMap = allMaps.first;
          }
        });
        debugPrint("[_fetchMapList] Fetched maps: $allMaps");
      } else {
        debugPrint("[_fetchMapList] Failed, status=${resp.statusCode}, body=${resp.body}");
      }
    } catch (e) {
      debugPrint("[_fetchMapList] error => $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("OtterGuessr Singleplayer")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              "Start a New Game Session (Singleplayer)",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            if (allMaps.isEmpty) ...[
              const Text("Loading map list or none found..."),
              const SizedBox(height: 20),
            ] else ...[
              const Text("Select Map:", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              DropdownButton<String>(
                value: selectedMap,
                items: allMaps.map((m) {
                  return DropdownMenuItem(value: m, child: Text(m));
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() => selectedMap = val);
                  }
                },
              ),
              const SizedBox(height: 20),
            ],

            _buildLabeled("Time Limit (seconds)", _timeCtrl),
            _buildLabeled("Number of Rounds", _roundCtrl),
            _buildLabeled("Mode", _modeCtrl),

            ElevatedButton(
              onPressed: _startGame,
              child: const Text("Start Game"),
            ),
          ],
        ),
      ),
    );
  }

  /// Helper widget for labeled textfields
  Widget _buildLabeled(String label, TextEditingController ctrl) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextField(
          controller: ctrl,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  /// Sends a POST to /create_game with selected map + user inputs
  Future<void> _startGame() async {
    if (selectedMap.isEmpty) {
      debugPrint("[_startGame] No map selected!");
      return;
    }
    final timeLimit = int.tryParse(_timeCtrl.text.trim()) ?? 60;
    final roundCount = int.tryParse(_roundCtrl.text.trim()) ?? 5;
    final mode = _modeCtrl.text.trim().isEmpty ? "Classic" : _modeCtrl.text.trim();

    final payload = {
      "mapName": selectedMap,
      "timeLimit": timeLimit,
      "roundCount": roundCount,
      "mode": mode
    };

    final url = Uri.parse('$baseUrl/create_game');
    debugPrint("[_startGame] POST => $payload");
    try {
      final resp = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: json.encode(payload),
      );
      debugPrint("[_startGame] status=${resp.statusCode}, body=${resp.body}");
      if (resp.statusCode == 200 || resp.statusCode == 201) {
        final data = json.decode(resp.body);
        final gameId = data["gameId"];
        debugPrint("Game created: gameId=$gameId");

        // Navigate to Round 1
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => StreetViewPage(
              gameId: gameId,
              roundIndex: 1,
              roundCount: roundCount,
            ),
          ),
        );
      } else {
        // Possibly show an error to the user
        debugPrint("[_startGame] fail => ${resp.body}");
      }
    } catch (e) {
      debugPrint("[_startGame] error => $e");
    }
  }
}
