// lib\screens\singleplayer_page.dart, do not remove this line

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../widgets/common_app_bar.dart';
import '../widgets/custom_button.dart';
import '../theme.dart';

class SingleplayerPage extends StatefulWidget {
  const SingleplayerPage({Key? key}) : super(key: key);

  @override
  State<SingleplayerPage> createState() => _SingleplayerPageState();
}

class _SingleplayerPageState extends State<SingleplayerPage> {
  // Game modes
  final List<String> modes = ['Classic', 'Frenzy', 'Creative', 'Custom'];
  String selectedMode = 'Classic';

  // If mode is "Custom," user can upload a file. Otherwise, pick from the retrieved map list.
  bool isCustomFileMode = false;

  // Round time in seconds (or minutes) — up to you how you interpret it
  final TextEditingController _roundTimeCtrl = TextEditingController(text: '60');

  // The full list of .geojson maps from the backend
  List<String> allMaps = [];

  // The filtered list after search
  List<String> filteredMaps = [];

  // The map currently selected
  String selectedMap = '';

  // For searching maps
  final TextEditingController _mapSearchCtrl = TextEditingController();

  // Example base URL for the Flask server (adjust as needed)
  final String baseUrl = 'http://127.0.0.1:5000';

  @override
  void initState() {
    super.initState();
    _fetchMapList();

    // Listen for search field changes to filter
    _mapSearchCtrl.addListener(_filterMapList);
  }

  @override
  void dispose() {
    _mapSearchCtrl.removeListener(_filterMapList);
    _mapSearchCtrl.dispose();
    super.dispose();
  }

  /// Fetch the list of .geojson maps from the Flask backend
  Future<void> _fetchMapList() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/maps'));
      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        setState(() {
          allMaps = jsonData.map((e) => e.toString()).toList();
          filteredMaps = List.from(allMaps);

          if (filteredMaps.isNotEmpty) {
            selectedMap = filteredMaps.first;
          }
        });
      } else {
        debugPrint('Failed to load maps. Status code: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error loading maps from backend: $e');
      setState(() {
        allMaps = [];
        filteredMaps = [];
      });
    }
  }

  /// Filter the maps based on the text in [_mapSearchCtrl].
  void _filterMapList() {
    final query = _mapSearchCtrl.text.trim().toLowerCase();
    setState(() {
      filteredMaps = allMaps
          .where((m) => m.toLowerCase().contains(query))
          .toList();

      if (!filteredMaps.contains(selectedMap) && filteredMaps.isNotEmpty) {
        selectedMap = filteredMaps.first;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CommonAppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Container(
          // "Source-engine" style: thick border, background color
          decoration: BoxDecoration(
            color: fieldColor,
            borderRadius: BorderRadius.circular(borderRadiusValue),
            border: Border.all(color: Colors.black, width: 3),
          ),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Singleplayer Setup',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              // Game Mode
              Row(
                children: [
                  const Text(
                    'Game Mode:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 10),
                  DropdownButton<String>(
                    value: selectedMode,
                    items: modes.map((mode) {
                      return DropdownMenuItem(value: mode, child: Text(mode));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          selectedMode = val;
                          isCustomFileMode = (val == 'Custom');
                        });
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // If NOT custom mode, show the map selection from server
              if (!isCustomFileMode) _buildMapSelection(),

              // If custom mode, allow user to upload a .geojson
              if (isCustomFileMode) _buildCustomFileUpload(),
              const SizedBox(height: 20),

              // Round Time
              _buildLabeledField(
                label: 'Round Time (seconds)',
                child: TextField(
                  controller: _roundTimeCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Start Button
              CustomButton(
                text: 'Start Game',
                onPressed: () {
                  final mode = selectedMode;
                  final mapName = selectedMap;
                  final roundTime = int.tryParse(_roundTimeCtrl.text.trim()) ?? 60;
                  debugPrint('Starting singleplayer:');
                  debugPrint('Mode: $mode');
                  debugPrint('Map: $mapName');
                  debugPrint('Round Time: $roundTime seconds');

                  // Insert logic to begin singleplayer game
                  // e.g., navigate to the game screen with these parameters
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Helper widget to show a label + field in a vertical layout
  Widget _buildLabeledField({required String label, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        child,
      ],
    );
  }

  /// Builds the map selection section with a search field + dropdown
  Widget _buildMapSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select a map:',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),

        // Search box
        TextField(
          controller: _mapSearchCtrl,
          decoration: const InputDecoration(
            labelText: 'Search maps...',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 10),

        if (filteredMaps.isEmpty)
          const Text('No matching maps found.'),
        if (filteredMaps.isNotEmpty)
          DropdownButton<String>(
            value: selectedMap.isNotEmpty ? selectedMap : filteredMaps.first,
            items: filteredMaps.map((m) {
              return DropdownMenuItem(value: m, child: Text(m));
            }).toList(),
            onChanged: (val) {
              if (val != null) {
                setState(() {
                  selectedMap = val;
                });
              }
            },
          ),
      ],
    );
  }

  /// Allows user to choose a custom .geojson outside of the known assets
  Widget _buildCustomFileUpload() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Upload your own .geojson:',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        CustomButton(
          text: 'Choose File',
          onPressed: () {
            // Typically call a file picker to get a local file path
            // Then store the path for your custom logic
            debugPrint('Custom file upload button clicked');
          },
        ),
      ],
    );
  }
}
