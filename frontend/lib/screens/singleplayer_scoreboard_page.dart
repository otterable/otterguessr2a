// lib/screens/singleplayer_scoreboard_page.dart
//
// SingleplayerScoreboardPage: displays final scoreboard data, with an option to
// download the full match data as JSON for replay or record-keeping.

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

class SingleplayerScoreboardPage extends StatelessWidget {
  final List<dynamic> roundResults;

  const SingleplayerScoreboardPage({
    super.key,
    required this.roundResults,
  });

  @override
  Widget build(BuildContext context) {
    double totalPoints = 0;
    for (var rd in roundResults) {
      totalPoints += (rd['score'] ?? 0) as double;
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Scoreboard")),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: roundResults.length,
              itemBuilder: (context, index) {
                final rd = roundResults[index];
                /*
                  This might have:
                    roundIndex, correctLat, correctLng, userLat, userLng,
                    distanceKm, score
                */
                return ListTile(
                  title: Text("Round ${rd['roundIndex'] + 1} - Score: ${rd['score']}"),
                  subtitle: Text(
                    "Correct: (${rd['correctLat']}, ${rd['correctLng']})\n"
                    "Guess: (${rd['userLat']}, ${rd['userLng']})\n"
                    "Distance: ${rd['distanceKm']?.toStringAsFixed(2)} km"
                  ),
                );
              },
            ),
          ),
          Text(
            "Total Score: ${totalPoints.toStringAsFixed(0)}",
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () async {
              await _exportMatchData(context);
            },
            child: const Text("Export Match Data"),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  /// Simple demonstration of how you'd call /download_game_data
  /// and save it as a local file. On web, saving a file might differ.
  Future<void> _exportMatchData(BuildContext context) async {
    final scaffold = ScaffoldMessenger.of(context);
    final gameId = roundResults.isNotEmpty ? roundResults.first["roundIndex"].toString() : "0";
    // Not the best approach to get gameId from round index, but we only
    // demonstrate the concept. Instead, store gameId from the finish endpoint.

    final baseUrl = 'http://127.0.0.1:5000';
    final downloadUrl = Uri.parse("$baseUrl/download_game_data?gameId=$gameId");

    try {
      final resp = await http.get(downloadUrl);
      if (resp.statusCode == 200) {
        // In a real mobile/desktop scenario, you could save to device storage.
        // For simplicity, we just show a message with the length.
        final fileBytes = resp.bodyBytes;
        scaffold.showSnackBar(
          SnackBar(content: Text("Downloaded ${fileBytes.length} bytes of JSON.")),
        );
      } else {
        scaffold.showSnackBar(
          SnackBar(content: Text("Error code: ${resp.statusCode}")),
        );
      }
    } catch (e) {
      scaffold.showSnackBar(SnackBar(content: Text("Download error: $e")));
    }
  }
}
