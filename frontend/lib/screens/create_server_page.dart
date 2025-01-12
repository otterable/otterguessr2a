// lib\screens\create_server_page.dart, do not remove this line

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../widgets/common_app_bar.dart';
import '../widgets/custom_button.dart';
import '../theme.dart';

class CreateServerPage extends StatefulWidget {
  const CreateServerPage({Key? key}) : super(key: key);

  @override
  State<CreateServerPage> createState() => _CreateServerPageState();
}

class _CreateServerPageState extends State<CreateServerPage> {
  final TextEditingController _serverNameCtrl = TextEditingController();
  final TextEditingController _passwordCtrl = TextEditingController();
  final TextEditingController _maxPlayersCtrl = TextEditingController(text: '8');

  // Round time in seconds
  final TextEditingController _roundTimeCtrl = TextEditingController(text: '60');

  // For the .geojson map search
  final TextEditingController _mapSearchCtrl = TextEditingController();

  // Available game modes
  final List<String> modes = ['Classic', 'Frenzy', 'Creative', 'Custom'];
  String selectedMode = 'Classic';

  // If mode == "Custom," user can upload a file; otherwise pick from retrieved map list
  bool isCustomFileMode = false;

  /// The full list of .geojson maps retrieved from the backend
  List<String> allMaps = [];

  /// The filtered list after search
  List<String> filteredMaps = [];

  /// The map currently selected
  String selectedMap = '';

  /// Example base URL for the Flask server (adjust as needed)
  final String baseUrl = 'http://127.0.0.1:5000';

  @override
  void initState() {
    super.initState();

    // 1. Check the backend heartbeat before fetching maps
    _checkHeartbeat().then((bool alive) {
      if (alive) {
        _fetchMapList();
      } else {
        debugPrint('Heartbeat check failed. Backend not reachable.');
      }
    });

    // 2. Listen for changes in the map search field to filter
    _mapSearchCtrl.addListener(_filterMapList);
  }

  @override
  void dispose() {
    _mapSearchCtrl.removeListener(_filterMapList);
    _mapSearchCtrl.dispose();
    super.dispose();
  }

  /// Check if the Flask backend is alive by calling /heartbeat
  Future<bool> _checkHeartbeat() async {
    final url = Uri.parse('$baseUrl/heartbeat');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        debugPrint('Heartbeat success: ${response.body}');
        return true;
      } else {
        debugPrint('Heartbeat failed with status: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      debugPrint('Heartbeat error: $e');
      return false;
    }
  }

  /// Fetch the list of .geojson maps from the Flask backend via GET /maps
  Future<void> _fetchMapList() async {
    final url = Uri.parse('$baseUrl/maps');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        setState(() {
          allMaps = jsonData.map((e) => e.toString()).toList();
          filteredMaps = List.from(allMaps);

          // Pick a default if available
          if (filteredMaps.isNotEmpty) {
            selectedMap = filteredMaps.first;
          }
        });
        debugPrint('Map list loaded successfully.');
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
      filteredMaps = allMaps.where((m) => m.toLowerCase().contains(query)).toList();

      // If the selectedMap is no longer in the filtered list, reset it
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
          // A "Source-engine" style box: thick border, background color
          decoration: BoxDecoration(
            color: fieldColor,
            borderRadius: BorderRadius.circular(borderRadiusValue),
            border: Border.all(color: Colors.black, width: 3),
          ),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const Text(
                'Create a Server',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              // Server Name
              _buildLabeledField(
                label: 'Name the server',
                child: TextField(
                  controller: _serverNameCtrl,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Game Mode
              Row(
                children: [
                  const Text(
                    'Select a gamemode:',
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
              // If custom mode, allow user to upload or pick a custom file
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

              // Password
              _buildLabeledField(
                label: 'Server Password (optional)',
                child: TextField(
                  controller: _passwordCtrl,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Max Players
              _buildLabeledField(
                label: 'Max player count',
                child: TextField(
                  controller: _maxPlayersCtrl,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),

              const SizedBox(height: 20),

              // Confirm Button
              CustomButton(
                text: 'Confirm',
                onPressed: () {
                  final serverName = _serverNameCtrl.text.trim();
                  final password = _passwordCtrl.text.trim();
                  final maxPlayers = int.tryParse(_maxPlayersCtrl.text.trim()) ?? 8;
                  final roundTime = int.tryParse(_roundTimeCtrl.text.trim()) ?? 60;

                  debugPrint('Server Name: $serverName');
                  debugPrint('Mode: $selectedMode');
                  debugPrint('Map: $selectedMap');
                  debugPrint('Round Time: $roundTime seconds');
                  debugPrint('Password: $password');
                  debugPrint('Max Players: $maxPlayers');

                  // Insert logic to actually create the server
                  // e.g., send an HTTP POST or GET request to the backend
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
        const Text('Select a map:', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),

        // Search box for maps
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
                setState(() => selectedMap = val);
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
        const Text('Upload map file:', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        CustomButton(
          text: 'Choose File',
          onPressed: () {
            // Typically call a file picker plugin to get a local file path
            // Then store the chosen file path in some variable for later
            debugPrint('Custom file upload button clicked.');
          },
        ),
      ],
    );
  }
}
