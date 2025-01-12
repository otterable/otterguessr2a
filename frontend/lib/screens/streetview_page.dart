// lib/screens/streetview_page.dart
//
// Displays the “Street View” (placeholder) and a map overlay to submit guesses.
// After the user guesses, we show results, then proceed to next round or finish.

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class StreetViewPage extends StatefulWidget {
  final String gameId;
  final int roundIndex;
  final int roundCount;

  const StreetViewPage({
    Key? key,
    required this.gameId,
    required this.roundIndex,
    required this.roundCount,
  }) : super(key: key);

  @override
  State<StreetViewPage> createState() => _StreetViewPageState();
}

class _StreetViewPageState extends State<StreetViewPage> {
  final String baseUrl = 'http://127.0.0.1:5000'; // Adjust if needed

  bool showingMapOverlay = false;
  bool roundCompleted = false;
  String resultMessage = "";

  // The Street View lat/lng for this round (if we wanted to fetch it from backend).
  // Currently, we have a placeholder.
  double streetLat = 0.0;
  double streetLng = 0.0;

  // The user's guess
  double? guessedLat;
  double? guessedLng;

  @override
  void initState() {
    super.initState();
    // Real usage might do a GET to retrieve the actual lat/lng for the round.
    // For now, let's mock. You can do:
    // _fetchRoundInfo();
    _fetchPlaceholderLocation();
  }

  /// Example placeholder for how you'd do "round info"
  void _fetchPlaceholderLocation() {
    // In a real scenario, you'd do GET: /some_route?gameId=xxx&roundIndex=xxx
    // Then set 'streetLat' and 'streetLng' from the JSON response.
    // For now, let's pretend a random location is loaded:
    setState(() {
      streetLat = 47.5162; // e.g. middle of Austria
      streetLng = 14.5501;
    });
  }

  @override
  Widget build(BuildContext context) {
    final title = "Round ${widget.roundIndex} / ${widget.roundCount}";
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            icon: const Text("🗺️"),
            onPressed: () => setState(() => showingMapOverlay = !showingMapOverlay),
          )
        ],
      ),
      body: Stack(
        children: [
          _buildStreetViewPlaceholder(),
          if (showingMapOverlay) _buildMapOverlay(),
        ],
      ),
    );
  }

  Widget _buildStreetViewPlaceholder() {
    if (streetLat == 0.0 && streetLng == 0.0) {
      return const Center(child: CircularProgressIndicator());
    }
    return Container(
      color: Colors.grey[800],
      alignment: Alignment.center,
      child: Text(
        "StreetView: ($streetLat, $streetLng)\n(Placeholder only.)",
        style: const TextStyle(color: Colors.white, fontSize: 18),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildMapOverlay() {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 600;

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 200),
      right: isMobile ? 0 : 20,
      bottom: isMobile ? 0 : 20,
      width: isMobile ? size.width : 300,
      height: isMobile ? size.height * 0.5 : 300,
      child: Material(
        color: Colors.white70,
        elevation: 5,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: roundCompleted ? _buildResultUI() : _buildGuessUI(),
        ),
      ),
    );
  }

  Widget _buildGuessUI() {
    return SingleChildScrollView(
      child: Column(
        children: [
          const Text(
            "Where do you think you are?\nEnter lat/lng or tap a map widget here.",
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          TextField(
            decoration: const InputDecoration(labelText: "Guess Latitude"),
            keyboardType: TextInputType.number,
            onChanged: (val) => guessedLat = double.tryParse(val),
          ),
          const SizedBox(height: 8),
          TextField(
            decoration: const InputDecoration(labelText: "Guess Longitude"),
            keyboardType: TextInputType.number,
            onChanged: (val) => guessedLng = double.tryParse(val),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _submitGuess,
            child: const Text("Confirm Guess"),
          )
        ],
      ),
    );
  }

  Widget _buildResultUI() {
    return SingleChildScrollView(
      child: Column(
        children: [
          Text(
            resultMessage,
            style: const TextStyle(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _goNextRound,
            child: const Text("Next Round"),
          )
        ],
      ),
    );
  }

  Future<void> _submitGuess() async {
    if (guessedLat == null || guessedLng == null) {
      debugPrint("[_submitGuess] Missing lat/lng");
      return;
    }

    final url = Uri.parse("$baseUrl/submit_guess");
    final payload = {
      "gameId": widget.gameId,
      // Some backends might be 0-based indexing. If so, subtract 1 below:
      "roundIndex": widget.roundIndex - 1,
      "userLat": guessedLat,
      "userLng": guessedLng,
    };

    try {
      final resp = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: json.encode(payload),
      );
      if (resp.statusCode == 200) {
        final data = json.decode(resp.body);
        final distKm = data["distanceKm"] as double;
        final pts = data["score"] as int;
        final correctLat = data["correctLat"] as double;
        final correctLng = data["correctLng"] as double;
        final totalSoFar = data["totalPointsSoFar"] as int;

        setState(() {
          roundCompleted = true;
          resultMessage =
              "Correct location: ($correctLat, $correctLng)\n"
              "Your guess: ($guessedLat, $guessedLng)\n"
              "Distance: ${distKm.toStringAsFixed(2)} km\n"
              "Points this round: $pts\n"
              "Total so far: $totalSoFar";
        });
      } else {
        debugPrint("[_submitGuess] fail => ${resp.statusCode}, body=${resp.body}");
      }
    } catch (e) {
      debugPrint("[_submitGuess] error => $e");
    }
  }

  void _goNextRound() {
    final next = widget.roundIndex + 1;
    if (next > widget.roundCount) {
      // All done => go to finishGame
      Navigator.pushReplacementNamed(
        context,
        '/finishGame',
        arguments: {"gameId": widget.gameId},
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => StreetViewPage(
            gameId: widget.gameId,
            roundIndex: next,
            roundCount: widget.roundCount,
          ),
        ),
      );
    }
  }
}
