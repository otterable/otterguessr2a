// lib\screens\create_server_page.dart, do not remove this line

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle; // For loading assets
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

  // For the .geojson map search
  final TextEditingController _mapSearchCtrl = TextEditingController();

  // For demonstration, let's assume these modes
  final List<String> modes = ['Classic', 'Frenzy', 'Creative', 'Custom'];
  String selectedMode = 'Classic';

  // If mode is "Custom," user can upload a file. Otherwise, pick from assets.
  bool isCustomFileMode = false;

  /// The full list of .geojson maps read from `assets/maps_list.txt`
  List<String> allMaps = [];

  /// The filtered list after search
  List<String> filteredMaps = [];

  /// The map currently selected
  String selectedMap = '';

  @override
  void initState() {
    super.initState();
    // Start loading the list of .geojson files
    _loadMaps();

    // Listen for changes in the map search field to filter
    _mapSearchCtrl.addListener(_filterMapList);
  }

  @override
  void dispose() {
    _mapSearchCtrl.removeListener(_filterMapList);
    _mapSearchCtrl.dispose();
    super.dispose();
  }

  /// Load `maps_list.txt` from assets and parse out each line for .geojson filenames.
  Future<void> _loadMaps() async {
    try {
      final data = await rootBundle.loadString('assets/maps/maps_list.txt');
      final lines = data.split('\n').map((line) => line.trim()).where((line) => line.isNotEmpty);
      setState(() {
        allMaps = lines.toList();
        filteredMaps = List.from(allMaps);

        // Pick a default if available
        if (filteredMaps.isNotEmpty) {
          selectedMap = filteredMaps.first;
        }
      });
    } catch (e) {
      // If there's an error (file missing, etc.), handle it gracefully
      debugPrint('Error loading map list: $e');
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
                  const Text('Select a gamemode:', style: TextStyle(fontWeight: FontWeight.bold)),
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

              // If NOT custom mode, we show the map selection from assets
              if (!isCustomFileMode) _buildMapSelection(),

              // If custom mode, allow user to upload or pick a custom file
              if (isCustomFileMode) _buildCustomFileUpload(),

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
                  // Example: create server with user data
                  final serverName = _serverNameCtrl.text.trim();
                  final password = _passwordCtrl.text.trim();
                  final maxPlayers = int.tryParse(_maxPlayersCtrl.text.trim()) ?? 8;

                  // If not custom mode, the map is from 'selectedMap'
                  // If custom mode, user might have chosen an external file
                  debugPrint('Server Name: $serverName');
                  debugPrint('Mode: $selectedMode');
                  debugPrint('Map: $selectedMap');
                  debugPrint('Password: $password');
                  debugPrint('Max Players: $maxPlayers');

                  // Insert your logic to actually create the server
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

        // Dropdown to pick from [filteredMaps]
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
            // You’d typically call a file picker plugin to get a local file path
            // Then store the chosen file path in some variable for later
          },
        ),
      ],
    );
  }
}
