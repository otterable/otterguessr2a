// lib\main.dart, do not remove this line
//
// This updated main.dart uses both:
//  - named routes for '/', '/singleplayer', '/multiplayer', '/createServer', '/scoreboard', '/finishGame'
//  - onGenerateRoute to handle custom URLs like "/:sessionId/:roundNumber"
//
// We added '/finishGame' -> SingleplayerFinishPage so the user can
// finalize the match and see the scoreboard.
//
// Bullet Points:
//   • MyApp: root widget, sets MaterialApp's onGenerateRoute and initial named routes
//   • onGenerateRoute: checks if path matches e.g. "/mySessionId/3"
//   • If no match, falls back to named routes or default "/"

import 'package:flutter/material.dart';

// Screens
import 'screens/home_page.dart';
import 'screens/singleplayer_page.dart';
import 'screens/multiplayer_page.dart';
import 'screens/create_server_page.dart';
import 'screens/scoreboard_page.dart';
import 'screens/singleplayer_finish_page.dart'; // <-- ADDED
// Theme
import 'theme.dart';

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // onGenerateRoute handler:
  //  1) If pathSegments length=2 => interpret as "/sessionId/roundNumber"
  //  2) Otherwise, fallback to the named routes below
  Route<dynamic>? _onGenerateRoute(RouteSettings settings) {
    final uri = Uri.parse(settings.name ?? '/');
    final segments = uri.pathSegments;

    // If user goes to e.g. "/"
    if (segments.isEmpty) {
      // fallback => handle with the named routes or default
      return null;
    }

    // If exactly 2 segments => interpret as sessionId + roundNumber
    // e.g. "/ABC123/1"
    if (segments.length == 2) {
      final sessionId = segments[0];
      final roundStr = segments[1];
      final roundNumber = int.tryParse(roundStr) ?? 1;

      return MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: Text('Session: $sessionId - Round: $roundNumber'),
          ),
          body: const Center(
            child: Text('Session-based route placeholder'),
          ),
        ),
      );
    }

    // If we don't recognize the pattern, let Flutter fallback to named routes
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GeoGuessr-like Game',
      debugShowCheckedModeBanner: false,
      theme: buildThemeData(),

      // The initial route if no deeper path is specified:
      initialRoute: '/',

      // Named routes:
      routes: {
        '/': (context) => const HomePage(),
        '/singleplayer': (context) => const SingleplayerPage(),
        '/multiplayer': (context) => const MultiplayerPage(),
        '/createServer': (context) => const CreateServerPage(),
        '/scoreboard': (context) => const ScoreboardPage(),
        '/finishGame': (context) => const SingleplayerFinishPage(), // NEW
      },

      // Fallback for unknown routes => onGenerateRoute:
      onGenerateRoute: _onGenerateRoute,
    );
  }
}

void main() {
  runApp(const MyApp());
}
