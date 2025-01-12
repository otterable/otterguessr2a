// lib/screens/final_score_page.dart
//
// After user completes all rounds, we call /end_game, get scoreboard, show results.

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class FinalScorePage extends StatefulWidget {
  final String sessionId;

  const FinalScorePage({Key? key, required this.sessionId}) : super(key: key);

  @override
  State<FinalScorePage> createState() => _FinalScorePageState();
}

class _FinalScorePageState extends State<FinalScorePage> {
  final String baseUrl = 'http://127.0.0.1:5000';
  List<dynamic> scoreboardRounds = [];
  int totalPoints = 0;
  Map<String, dynamic>? matchJson;

  @override
  void initState() {
    super.initState();
    _endGame();
  }

  Future<void> _endGame() async {
    final url = Uri.parse("$baseUrl/end_game");
    final payload = {
      "sessionId": widget.sessionId
    };
    try {
      final resp = await http.post(url,
        headers: {"Content-Type": "application/json"},
        body: json.encode(payload),
      );
      if (resp.statusCode == 200) {
        final data = json.decode(resp.body);
        setState(() {
          scoreboardRounds = data["rounds"];
          totalPoints = data["totalPoints"];
          matchJson = data["matchJson"];
        });
      } else {
        debugPrint("[_endGame] fail: ${resp.statusCode}, ${resp.body}");
      }
    } catch (e) {
      debugPrint("[_endGame] error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Final Scoreboard"),
      ),
      body: scoreboardRounds.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Total Points: $totalPoints",
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  ...scoreboardRounds.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final rd = entry.value;
                    final actualLat = rd["actualLat"];
                    final actualLng = rd["actualLng"];
                    final guessLat = rd["guessedLat"];
                    final guessLng = rd["guessedLng"];
                    final dist = rd["distanceKm"]?.toStringAsFixed(2);
                    final pts = rd["points"];

                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.black),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Round ${idx + 1}", style: const TextStyle(fontWeight: FontWeight.bold)),
                          Text("  Actual: ($actualLat, $actualLng)"),
                          Text("  Guess: ($guessLat, $guessLng)"),
                          Text("  Distance: $dist km"),
                          Text("  Points: $pts"),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      if (matchJson != null) {
                        final pretty = const JsonEncoder.withIndent("  ").convert(matchJson);
                        showDialog(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text("Match JSON"),
                            content: SingleChildScrollView(child: Text(pretty)),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text("Close"),
                              )
                            ],
                          ),
                        );
                      }
                    },
                    child: const Text("View Replay JSON"),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.popUntil(context, (route) => route.isFirst);
                    },
                    child: const Text("Back to Main"),
                  )
                ],
              ),
            ),
    );
  }
}
