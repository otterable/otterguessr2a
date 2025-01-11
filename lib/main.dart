// lib\main.dart, do not remove this line

import 'package:flutter/material.dart';

// Screens
import 'screens/home_page.dart';
import 'screens/singleplayer_page.dart';
import 'screens/multiplayer_page.dart';
import 'screens/create_server_page.dart';
import 'screens/scoreboard_page.dart';

// Theme
import 'theme.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GeoGuessr-like Game',
      debugShowCheckedModeBanner: false,
      theme: buildThemeData(),
      initialRoute: '/',
      routes: {
        '/': (context) => const HomePage(),
        '/singleplayer': (context) => const SingleplayerPage(),
        '/multiplayer': (context) => const MultiplayerPage(),
        '/createServer': (context) => const CreateServerPage(),
        '/scoreboard': (context) => const ScoreboardPage(),
      },
    );
  }
}
