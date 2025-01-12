// lib/screens/singleplayer_finish_page.dart
//
// After the last round is done, we land here (via route '/finishGame').
// We call /finish_game to get final scoreboard data and navigate to scoreboard.

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'singleplayer_scoreboard_page.dart';

class SingleplayerFinishPage extends StatefulWidget {
  const SingleplayerFinishPage({Key? key}) : super(key: key);

  @override
  State<SingleplayerFinishPage> createState() => _SingleplayerFinishPageState();
}

class _SingleplayerFinishPageState extends State<SingleplayerFinishPage> {
  final String baseUrl = 'http://127.0.0.1:5000';
  bool loading = true;
  String? errorMessage;
  Map<String, dynamic>? finalResults;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Grab the gameId from the route arguments:
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map && args.containsKey("gameId")) {
      final String gameId = args["gameId"];
      _finishGame(gameId);
    } else {
      setState(() {
        loading = false;
        errorMessage = "No gameId provided.";
      });
    }
  }

  Future<void> _finishGame(String gameId) async {
    final url = Uri.parse("$baseUrl/finish_game");
    try {
      final resp = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: json.encode({"gameId": gameId}),
      );
      if (resp.statusCode == 200) {
        final data = json.decode(resp.body);
        setState(() {
          finalResults = data;
        });

        // Once we have final data, navigate to scoreboard
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => SingleplayerScoreboardPage(roundResults: data["roundResults"]),
          ),
        );
      } else {
        setState(() {
          loading = false;
          errorMessage = resp.body;
        });
      }
    } catch (e) {
      setState(() {
        loading = false;
        errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading && errorMessage == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Finishing...")),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Finish Game Error")),
        body: Center(child: Text(errorMessage!)),
      );
    }

    // If we got here, it means we have finalResults but haven't navigated.
    // We'll just show a fallback:
    return Scaffold(
      appBar: AppBar(title: const Text("Finished")),
      body: const Center(child: Text("Redirecting to scoreboard...")),
    );
  }
}
