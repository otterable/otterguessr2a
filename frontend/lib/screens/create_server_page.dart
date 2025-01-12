// lib/screens/create_server_page.dart

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../widgets/common_app_bar.dart';
import '../widgets/custom_button.dart';
import '../theme.dart';

/// CreateServerPage: for multiplayer creation with a map dropdown
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

  // If mode == "Custom," user can upload a file. Otherwise pick from the retrieved map list
  final List<String> modes = ['Classic', 'Frenzy', 'Creative', 'Custom'];
  String selectedMode = 'Classic';
  bool isCustomFileMode = false;

  // The full list of .geojson maps retrieved from the backend
  List<String> allMaps = [];
  List<String> filteredMaps = [];
  String selectedMap = '';

  final TextEditingController _mapSearchCtrl = TextEditingController();

  final String baseUrl = 'http://127.0.0.1:5000';

  @override
  void initState() {
    super.initState();
    // 1) Check heartbeat, then fetch maps if alive
    _checkHeartbeat().then((alive) {
      if (alive) {
        _fetchMapList();
      } else {
        debugPrint("[CreateServerPage] Heartbeat failed, cannot fetch maps.");
      }
    });

    // Listen for map search changes
    _mapSearchCtrl.addListener(_filterMapList);
  }

  @override
  void dispose() {
    _mapSearchCtrl.removeListener(_filterMapList);
    _mapSearchCtrl.dispose();
    super.dispose();
  }

  /// Quick check if backend is reachable
  Future<bool> _checkHeartbeat() async {
    final url = Uri.parse('$baseUrl/heartbeat');
    try {
      final resp = await http.get(url);
      if (resp.statusCode == 200) {
        debugPrint("[_checkHeartbeat] success => ${resp.body}");
        return true;
      }
    } catch (e) {
      debugPrint("[_checkHeartbeat] error => $e");
    }
    return false;
  }

  /// GET /maps -> populate allMaps, filteredMaps
  Future<void> _fetchMapList() async {
    final url = Uri.parse('$baseUrl/maps');
    try {
      final resp = await http.get(url);
      if (resp.statusCode == 200) {
        final List<dynamic> data = json.decode(resp.body);
        setState(() {
          allMaps = data.map((e) => e.toString()).toList();
          filteredMaps = List.from(allMaps);
          if (filteredMaps.isNotEmpty) {
            selectedMap = filteredMaps.first;
          }
        });
        debugPrint("[_fetchMapList] loaded maps => $allMaps");
      } else {
        debugPrint("[_fetchMapList] fail => ${resp.statusCode}, ${resp.body}");
      }
    } catch (e) {
      debugPrint("[_fetchMapList] error => $e");
      setState(() {
        allMaps = [];
        filteredMaps = [];
      });
    }
  }

  /// Filter map list
  void _filterMapList() {
    final query = _mapSearchCtrl.text.trim().toLowerCase();
    setState(() {
      filteredMaps = allMaps.where((m) => m.toLowerCase().contains(query)).toList();
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

              // Server name
              _buildLabeledField(
                label: 'Server Name',
                child: TextField(
                  controller: _serverNameCtrl,
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                ),
              ),
              const SizedBox(height: 20),

              // Mode dropdown
              Row(
                children: [
                  const Text('Select a gamemode:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(width: 10),
                  DropdownButton<String>(
                    value: selectedMode,
                    items: modes.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
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

              // If NOT custom mode => show map selection
              if (!isCustomFileMode) _buildMapSelection(),

              // If custom => allow file upload
              if (isCustomFileMode) _buildCustomFileUpload(),

              const SizedBox(height: 20),

              // Round time
              _buildLabeledField(
                label: 'Round Time (seconds)',
                child: TextField(
                  controller: _roundTimeCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                ),
              ),
              const SizedBox(height: 20),

              // Password
              _buildLabeledField(
                label: 'Server Password (optional)',
                child: TextField(
                  controller: _passwordCtrl,
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                ),
              ),
              const SizedBox(height: 20),

              // Max players
              _buildLabeledField(
                label: 'Max player count',
                child: TextField(
                  controller: _maxPlayersCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                ),
              ),
              const SizedBox(height: 20),

              // Confirm
              CustomButton(
                text: 'Confirm',
                onPressed: _onConfirm,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Reusable label + child
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

  /// Map selection for non-custom modes
  Widget _buildMapSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Select a map:', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        TextField(
          controller: _mapSearchCtrl,
          decoration: const InputDecoration(
            labelText: 'Search maps...',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 10),
        if (filteredMaps.isEmpty) ...[
          const Text('No matching maps found.'),
        ] else ...[
          DropdownButton<String>(
            value: selectedMap.isNotEmpty ? selectedMap : filteredMaps.first,
            items: filteredMaps.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
            onChanged: (val) {
              if (val != null) {
                setState(() => selectedMap = val);
              }
            },
          ),
        ],
      ],
    );
  }

  /// For custom mode => file upload
  Widget _buildCustomFileUpload() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Upload map file:', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        CustomButton(
          text: 'Choose File',
          onPressed: () {
            debugPrint('[CustomFileUpload] TODO: Launch file picker plugin');
          },
        ),
      ],
    );
  }

  /// Called when user taps "Confirm"
  void _onConfirm() {
    final serverName = _serverNameCtrl.text.trim();
    final password = _passwordCtrl.text.trim();
    final maxPlayers = int.tryParse(_maxPlayersCtrl.text.trim()) ?? 8;
    final roundTime = int.tryParse(_roundTimeCtrl.text.trim()) ?? 60;

    debugPrint("=== Creating Server ===");
    debugPrint("Server Name: $serverName");
    debugPrint("Mode: $selectedMode");
    debugPrint("Map: $selectedMap");
    debugPrint("Round Time: $roundTime");
    debugPrint("Password: $password");
    debugPrint("Max Players: $maxPlayers");

    // Possibly do your /create_server logic or store in memory
    // if not custom mode => selectedMap is the chosen file
    // if custom => user must have uploaded a file
    // For now, we just debug print
    // ...
  }
}
