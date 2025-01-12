// lib\screens\multiplayer_page.dart, do not remove this line

import 'package:flutter/material.dart';
import '../widgets/common_app_bar.dart';
import '../widgets/custom_button.dart';
import '../theme.dart';

class MultiplayerPage extends StatefulWidget {
  const MultiplayerPage({Key? key}) : super(key: key);

  @override
  State<MultiplayerPage> createState() => _MultiplayerPageState();
}

class _MultiplayerPageState extends State<MultiplayerPage> {
  // Filter fields
  bool showClassic = true;
  bool showFrenzy = true;
  bool showCreative = true;
  bool showCustom = true;

  bool showPasswordProtected = true;
  String searchQuery = '';
  String sortOption = 'Fullest'; // or 'Emptiest'

  // Example server data
  final List<Map<String, dynamic>> servers = [
    {
      'title': 'Server 1',
      'mode': 'Classic',
      'map': 'World',
      'players': 7,
      'maxPlayers': 10,
      'passwordProtected': false,
    },
    {
      'title': 'Fun Frenzy',
      'mode': 'Frenzy',
      'map': 'Europe',
      'players': 1,
      'maxPlayers': 5,
      'passwordProtected': true,
    },
    {
      'title': 'Creative Playground',
      'mode': 'Creative',
      'map': 'MyCustomMap.geojson',
      'players': 3,
      'maxPlayers': 8,
      'passwordProtected': false,
    },
    {
      'title': 'Custom World Tour',
      'mode': 'Custom',
      'map': 'CustomFile.geojson',
      'players': 8,
      'maxPlayers': 8,
      'passwordProtected': true,
    },
  ];

  @override
  Widget build(BuildContext context) {
    // Simple check for "mobile" vs. "desktop"
    final bool isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      appBar: const CommonAppBar(),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            color: fieldColor,
            borderRadius: BorderRadius.circular(borderRadiusValue),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: isMobile
                ? _buildMobileLayout(context)
                : _buildDesktopLayout(context),
          ),
        ),
      ),
    );
  }

  // -------------------------------------------
  // MOBILE LAYOUT
  // -------------------------------------------
  Widget _buildMobileLayout(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        const Text(
          'Multiplayer:',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),

        // Row: Filter button (opens bottom sheet) + spacer + Create Server
        Row(
          children: [
            CustomButton(
              text: 'Filter',
              onPressed: () => _showMobileFilterSheet(context),
            ),
            const Spacer(),
            CustomButton(
              text: 'Create Server',
              onPressed: () {
                Navigator.pushNamed(context, '/createServer');
              },
            ),
          ],
        ),

        const SizedBox(height: 8),
        const Divider(
          color: Colors.black,
          thickness: 3,
          height: 8,
        ),
        const SizedBox(height: 8),

        // Server list in 2-line format
        Expanded(
          child: _buildServerListMobile(),
        ),
      ],
    );
  }

  // Display a bottom sheet with all filter options, "Save Changes" button
  void _showMobileFilterSheet(BuildContext context) {
    // We'll store temporary states here, so user can press "Save" to commit
    bool tempClassic = showClassic;
    bool tempFrenzy = showFrenzy;
    bool tempCreative = showCreative;
    bool tempCustom = showCustom;
    bool tempShowPw = showPasswordProtected;
    String tempSort = sortOption;
    String tempSearch = searchQuery;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // so it can expand more
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            // So that the bottom sheet is above keyboard if it appears
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text(
                    'Filter Options',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  // Mode checkboxes
                  _buildMobileModeCheckbox(
                    'Classic', tempClassic,
                    (val) => tempClassic = val ?? true,
                  ),
                  _buildMobileModeCheckbox(
                    'Frenzy', tempFrenzy,
                    (val) => tempFrenzy = val ?? true,
                  ),
                  _buildMobileModeCheckbox(
                    'Creative', tempCreative,
                    (val) => tempCreative = val ?? true,
                  ),
                  _buildMobileModeCheckbox(
                    'Custom', tempCustom,
                    (val) => tempCustom = val ?? true,
                  ),

                  const SizedBox(height: 16),

                  // Show PW servers
                  Row(
                    children: [
                      Checkbox(
                        value: tempShowPw,
                        onChanged: (val) => tempShowPw = val ?? true,
                      ),
                      const Text('Show PW Servers'),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Sort option
                  Row(
                    children: [
                      const Text('Sort by: '),
                      const SizedBox(width: 8),
                      DropdownButton<String>(
                        value: tempSort,
                        items: const [
                          DropdownMenuItem(
                            value: 'Fullest',
                            child: Text('Fullest'),
                          ),
                          DropdownMenuItem(
                            value: 'Emptiest',
                            child: Text('Emptiest'),
                          ),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            tempSort = val;
                          }
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Search field
                  TextField(
                    onChanged: (val) => tempSearch = val,
                    decoration: const InputDecoration(
                      labelText: 'Search...',
                      border: OutlineInputBorder(),
                    ),
                    controller: TextEditingController(text: tempSearch),
                  ),

                  const SizedBox(height: 16),

                  // Save Changes
                  CustomButton(
                    text: 'Save Changes',
                    onPressed: () {
                      // Commit temporary states to real states
                      setState(() {
                        showClassic = tempClassic;
                        showFrenzy = tempFrenzy;
                        showCreative = tempCreative;
                        showCustom = tempCustom;
                        showPasswordProtected = tempShowPw;
                        sortOption = tempSort;
                        searchQuery = tempSearch;
                      });
                      Navigator.pop(ctx); // Close bottom sheet
                    },
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Reusable row for each mode checkbox in the mobile filter
  Widget _buildMobileModeCheckbox(
      String label, bool value, ValueChanged<bool?> onChanged) {
    return Row(
      children: [
        Checkbox(value: value, onChanged: onChanged),
        Text(label),
      ],
    );
  }

  // Mobile server list: each item has 2 lines
  Widget _buildServerListMobile() {
    final filtered = _applyFiltersAndSort();
    if (filtered.isEmpty) {
      return const Center(child: Text('No servers found.'));
    }

    return ListView.builder(
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final server = filtered[index];
        final pwIcon = server['passwordProtected'] ? 'PW' : 'NoPW';

        return InkWell(
          onTap: () {
            // Join or show details
          },
          child: Card(
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1st line: ServerName | "Players"
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(server['title'].toString()),
                      Text('${server['players']}/${server['maxPlayers']}'),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // 2nd line: Mode | Map | PW?
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(server['mode'].toString()),
                      Text(server['map'].toString()),
                      Text(pwIcon),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // -------------------------------------------
  // DESKTOP / LARGE SCREEN LAYOUT
  // -------------------------------------------
  Widget _buildDesktopLayout(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        const Text(
          'Multiplayer:',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),

        // Filter row (the original approach)
        _buildFilterAndCreateRowDesktop(),

        // Thick divider
        const SizedBox(height: 8),
        const Divider(color: Colors.black, thickness: 3, height: 8),
        const SizedBox(height: 8),

        // Server table
        Expanded(
          child: _buildServerTableDesktop(),
        ),
      ],
    );
  }

  /// Desktop row for filters
  Widget _buildFilterAndCreateRowDesktop() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildModeToggles(),
          const SizedBox(width: 20),

          // Password protected toggle
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Checkbox(
                value: showPasswordProtected,
                onChanged: (val) {
                  setState(() => showPasswordProtected = val ?? true);
                },
              ),
              const Text('Show PW Servers'),
            ],
          ),
          const SizedBox(width: 20),

          // Search box
          SizedBox(
            width: 200,
            child: TextField(
              onChanged: (val) => setState(() => searchQuery = val),
              decoration: const InputDecoration(
                labelText: 'Search...',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ),
          const SizedBox(width: 20),

          // Sort dropdown
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Sort by: '),
              const SizedBox(width: 5),
              DropdownButton<String>(
                value: sortOption,
                items: const [
                  DropdownMenuItem(
                    value: 'Fullest',
                    child: Text('Fullest'),
                  ),
                  DropdownMenuItem(
                    value: 'Emptiest',
                    child: Text('Emptiest'),
                  ),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() => sortOption = val);
                  }
                },
              ),
            ],
          ),
          const SizedBox(width: 20),

          // Create Server
          CustomButton(
            text: 'Create Server',
            onPressed: () {
              Navigator.pushNamed(context, '/createServer');
            },
          ),
        ],
      ),
    );
  }

  /// Desktop table
  Widget _buildServerTableDesktop() {
    final filtered = _applyFiltersAndSort();
    if (filtered.isEmpty) {
      return const Center(child: Text('No servers found.'));
    }

    // We'll do the same approach as previously:
    // A LayoutBuilder that auto-sizes columns evenly
    return LayoutBuilder(
      builder: (context, constraints) {
        final columnWidth = constraints.maxWidth / 5;
        return SingleChildScrollView(
          child: DataTable(
            showCheckboxColumn: false,
            headingRowHeight: 40,
            dataRowHeight: 50,
            columns: [
              DataColumn(
                label: SizedBox(
                  width: columnWidth,
                  child: const Text('Server Name'),
                ),
              ),
              DataColumn(
                label: SizedBox(
                  width: columnWidth,
                  child: const Text('Mode'),
                ),
              ),
              DataColumn(
                label: SizedBox(
                  width: columnWidth,
                  child: const Text('Map'),
                ),
              ),
              DataColumn(
                label: SizedBox(
                  width: columnWidth,
                  child: const Text('Players'),
                ),
              ),
              DataColumn(
                label: SizedBox(
                  width: columnWidth,
                  child: const Text('PW?'),
                ),
              ),
            ],
            rows: filtered.map((server) {
              return DataRow(
                onSelectChanged: (_) {
                  // Join server or show details
                },
                cells: [
                  DataCell(SizedBox(
                    width: columnWidth,
                    child: Text(server['title'].toString()),
                  )),
                  DataCell(SizedBox(
                    width: columnWidth,
                    child: Text(server['mode'].toString()),
                  )),
                  DataCell(SizedBox(
                    width: columnWidth,
                    child: Text(server['map'].toString()),
                  )),
                  DataCell(SizedBox(
                    width: columnWidth,
                    child: Text('${server['players']}/${server['maxPlayers']}'),
                  )),
                  DataCell(SizedBox(
                    width: columnWidth,
                    child: server['passwordProtected']
                        ? const Icon(Icons.lock, size: 18)
                        : const Icon(Icons.lock_open, size: 18),
                  )),
                ],
              );
            }).toList(),
          ),
        );
      },
    );
  }

  // -------------------------------------------
  // SHARED LOGIC
  // -------------------------------------------
  /// The checkboxes used in both mobile and desktop
  Widget _buildModeToggles() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildCheck('Classic', showClassic, (val) {
          setState(() => showClassic = val ?? true);
        }),
        const SizedBox(width: 10),
        _buildCheck('Frenzy', showFrenzy, (val) {
          setState(() => showFrenzy = val ?? true);
        }),
        const SizedBox(width: 10),
        _buildCheck('Creative', showCreative, (val) {
          setState(() => showCreative = val ?? true);
        }),
        const SizedBox(width: 10),
        _buildCheck('Custom', showCustom, (val) {
          setState(() => showCustom = val ?? true);
        }),
      ],
    );
  }

  Widget _buildCheck(String label, bool value, ValueChanged<bool?> onChanged) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Checkbox(value: value, onChanged: onChanged),
        Text(label),
      ],
    );
  }

  /// Filter + sort logic
  List<Map<String, dynamic>> _applyFiltersAndSort() {
    List<Map<String, dynamic>> filtered = servers.where((s) {
      // Search
      if (!s['title'].toString().toLowerCase().contains(searchQuery.toLowerCase())) {
        return false;
      }
      // Mode toggles
      if (s['mode'] == 'Classic' && !showClassic) return false;
      if (s['mode'] == 'Frenzy' && !showFrenzy) return false;
      if (s['mode'] == 'Creative' && !showCreative) return false;
      if (s['mode'] == 'Custom' && !showCustom) return false;

      // Password-protected toggle
      if (!showPasswordProtected && s['passwordProtected'] == true) {
        return false;
      }
      return true;
    }).toList();

    // Sort by Fullest or Emptiest
    if (sortOption == 'Fullest') {
      filtered.sort((a, b) => b['players'].compareTo(a['players']));
    } else {
      filtered.sort((a, b) => a['players'].compareTo(b['players']));
    }
    return filtered;
  }
}
