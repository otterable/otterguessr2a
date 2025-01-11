// lib\screens\scoreboard_page.dart, do not remove this line

import 'package:flutter/material.dart';
import '../widgets/common_app_bar.dart';
import '../theme.dart';

class ScoreboardPage extends StatelessWidget {
  const ScoreboardPage({Key? key}) : super(key: key);

  // Example data for demonstration
  final List<Map<String, dynamic>> _scoreData = const [
    {'name': 'Alice', 'bestRound': 2, 'worstRound': 4, 'totalScore': 12500},
    {'name': 'Bob', 'bestRound': 3, 'worstRound': 1, 'totalScore': 10000},
    {'name': 'Charlie', 'bestRound': 1, 'worstRound': 5, 'totalScore': 8500},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CommonAppBar(),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Container(
          decoration: BoxDecoration(
            color: fieldColor,
            borderRadius: BorderRadius.circular(borderRadiusValue),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Text(
                'Scoreboard',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              _buildScoreTable(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScoreTable() {
    if (_scoreData.isEmpty) {
      return const Text('No scores to display.');
    }

    // We can use a DataTable or custom list. Example: DataTable:
    return DataTable(
      columns: const [
        DataColumn(label: Text('Player Name')),
        DataColumn(label: Text('Best Round #')),
        DataColumn(label: Text('Worst Round #')),
        DataColumn(label: Text('Total Score')),
      ],
      rows: _scoreData.map((player) {
        return DataRow(cells: [
          DataCell(Text(player['name'].toString())),
          DataCell(Text(player['bestRound'].toString())),
          DataCell(Text(player['worstRound'].toString())),
          DataCell(Text(player['totalScore'].toString())),
        ]);
      }).toList(),
    );
  }
}
