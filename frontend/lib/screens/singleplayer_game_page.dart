// lib/screens/singleplayer_scoreboard_page.dart

import 'package:flutter/material.dart';

class SingleplayerScoreboardPage extends StatelessWidget {
  final List<dynamic> roundResults;
  // You might have other fields, e.g. final int totalPoints, etc.

  // Use super.key to fix the "use_super_parameters" lint
  const SingleplayerScoreboardPage({
    super.key,
    required this.roundResults,
    // required this.totalPoints, // if you want more parameters
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Scoreboard")),
      body: ListView.builder(
        itemCount: roundResults.length,
        itemBuilder: (context, index) {
          final round = roundResults[index];
          // round might have { distance, points, etc. }
          return ListTile(
            title: Text("Round $index => $round"),
          );
        },
      ),
    );
  }
}
