import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Google Mobile Ads only on supported platforms (iOS, Android, Web)
  if (defaultTargetPlatform == TargetPlatform.iOS ||
      defaultTargetPlatform == TargetPlatform.android ||
      kIsWeb) {
    await MobileAds.instance.initialize();
  }

  runApp(const MyApp());
}

// ENUM SECTION:
// Defines the two pairing modes available in the app.
enum PairingMode { dragAndDrop, listSelect }

class ScoreResult {
  ScoreResult({
    this.score1 = 0,
    this.score2 = 0,
    this.targetPoints = 15,
    this.winnerTeam,
  });

  int score1;
  int score2;
  int targetPoints;
  String? winnerTeam;
}

class LeagueStanding {
  LeagueStanding({
    required this.team,
    this.wins = 0,
    this.draws = 0,
    this.losses = 0,
    this.pointsFor = 0,
    this.pointsAgainst = 0,
  });

  final String team;
  int wins;
  int draws;
  int losses;
  int pointsFor;
  int pointsAgainst;

  int get pointDifference => pointsFor - pointsAgainst;
}

// APP START
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: const Color(0xFFB08B1E),
          brightness: Brightness.light,
        ).copyWith(
          primary: const Color(0xFFB08B1E),
          onPrimary: Colors.black,
          primaryContainer: const Color(0xFFF0D47A),
          onPrimaryContainer: Colors.black,
          secondary: const Color(0xFF65711D),
          onSecondary: Colors.white,
          secondaryContainer: const Color(0xFFDDE1A1),
          onSecondaryContainer: Colors.black,
          tertiary: const Color(0xFF8D6B2B),
          onTertiary: Colors.white,
          tertiaryContainer: const Color(0xFFF3D8A3),
          onTertiaryContainer: Colors.black,
          surface: const Color(0xFFFFF8E1),
          onSurface: Colors.black87,
          surfaceContainerHighest: const Color(0xFFE9DEB8),
          outline: const Color(0xFF7E7351),
          inverseSurface: const Color(0xFF303030),
          onInverseSurface: Colors.white,
          inversePrimary: const Color(0xFF6E7640),
        );

    return MaterialApp(
      title: 'Team Demo',

      // APP THEME
      theme: ThemeData(
        colorScheme: colorScheme,
        useMaterial3: true,
        appBarTheme: AppBarTheme(
          backgroundColor: colorScheme.inversePrimary,
          foregroundColor: colorScheme.onInverseSurface,
        ),
        drawerTheme: DrawerThemeData(
          backgroundColor: colorScheme.primaryContainer,
        ),
      ),

      // START / LANDING PAGE
      home: const LandingPage(),
    );
  }
}

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: _buildAppDrawer(
        context: context,
        onHomeTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const LandingPage()),
          );
        },
        onCreateUserTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (c) => const CreateUserPage()),
          );
        },
        onTournamentTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (c) => TournamentMenuPage(
                teams: const [],
                pairings: const [],
                scoreResults: const {},
              ),
            ),
          );
        },
        onSingleGamesTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (c) => const MyHomePage(title: 'Team Manager'),
            ),
          );
        },
        onPromoTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (c) => const PromoAdsPage()),
          );
        },
        onTeamsTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const LandingPage()),
          );
        },
        onPairingsTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (c) => const MyHomePage(title: 'Team Manager'),
            ),
          );
        },
      ),
      appBar: AppBar(
        title: const Text('Tournamaster'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FilledButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (c) => const MyHomePage(title: 'Team Manager'),
                ),
              ),
              child: const Text('Single Games'),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (c) => TournamentMenuPage(
                    teams: const [],
                    pairings: const [],
                    scoreResults: const {},
                  ),
                ),
              ),
              child: const Text('Create Tournament'),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (c) => const CreateUserPage()),
              ),
              child: const Text('Create User'),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (c) => const PromoAdsPage()),
              ),
              child: const Text('Promo & Ads'),
            ),
          ],
        ),
      ),
    );
  }
}

// FIRST SCREEN
class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

// MAIN APP STATE
// Stores teams and pairings permanently
// while navigating between pages.
class _MyHomePageState extends State<MyHomePage> {
  // CONTROLLER SECTION:
  // Controls the text input field.
  final TextEditingController _teamController = TextEditingController();
  final ScrollController _homeScrollController = ScrollController();
  final List<TextEditingController> _teamNameControllers = [];
  final Random _random = Random();

  // TEAM SECTION:
  // Stores all created teams.
  final List<String> _teams = [];

  // TEAM SECTION:
  // Name parts used for random team generation.
  static const _teamPrefixes = [
    'Red',
    'Blue',
    'Golden',
    'Silver',
    'Mighty',
    'Wild',
    'Thunder',
    'Iron',
    'Swift',
    'Shadow',
  ];
  static const _teamSuffixes = [
    'Dragons',
    'Titans',
    'Warriors',
    'Falcons',
    'Knights',
    'Pirates',
    'Rangers',
    'Storm',
    'Guardians',
    'Eagles',
  ];

  // PAIRING SECTION:
  // Stores all created pairings.
  //
  // Example:
  // [
  //   ["Team A", "Team B"],
  //   ["Team C", "Team D"]
  // ]
  final List<List<String>> _pairings = [];

  // SCORE SECTION:
  // Stores scores for every pairing.
  final Map<String, ScoreResult> _scoreResults = {};

  // TEAM SECTION:
  // Adds a new team to the list.
  void _addTeam() {
    // Read the text from the input field.
    final teamName = _teamController.text.trim();

    // Ignore empty team names.
    if (teamName.isEmpty) return;

    if (!mounted) return;

    setState(() {
      // Add team to the list.
      _teams.add(teamName);
      _teamNameControllers.add(TextEditingController(text: teamName));

      // Clear the text field afterwards.
      _teamController.clear();
    });
  }

  // TEAM SECTION:
  // Generates ten random teams and adds them to the team list.
  void _addRandomTeams() {
    if (!mounted) return;

    setState(() {
      for (var i = 0; i < 10; i++) {
        final teamName = _generateRandomTeamName();
        _teams.add(teamName);
        _teamNameControllers.add(TextEditingController(text: teamName));
      }
    });
  }

  String _generateRandomTeamName() {
    final prefix = _teamPrefixes[_random.nextInt(_teamPrefixes.length)];
    final suffix = _teamSuffixes[_random.nextInt(_teamSuffixes.length)];
    final number = _random.nextInt(100) + 1;
    final name = '$prefix $suffix $number';
    return _teams.contains(name) ? _generateRandomTeamName() : name;
  }

  void _renameTeam(int index, String newName) {
    final trimmedName = newName.trim();
    final oldName = _teams[index];
    if (trimmedName.isEmpty || trimmedName == oldName) {
      _teamNameControllers[index].text = oldName;
      return;
    }

    setState(() {
      _teams[index] = trimmedName;
      final updatedPairings = <List<String>>[];
      for (final pairing in _pairings) {
        updatedPairings.add(
          pairing.map((team) {
            return team == oldName ? trimmedName : team;
          }).toList(),
        );
      }
      _pairings
        ..clear()
        ..addAll(updatedPairings);

      final updatedScoreResults = <String, ScoreResult>{};
      for (final entry in _scoreResults.entries) {
        final parts = entry.key.split('|');
        final team1 = parts[0] == oldName ? trimmedName : parts[0];
        final team2 = parts[1] == oldName ? trimmedName : parts[1];
        final newKey = '$team1|$team2';
        updatedScoreResults[newKey] = entry.value;
      }
      _scoreResults
        ..clear()
        ..addAll(updatedScoreResults);
      _teamNameControllers[index].text = trimmedName;
      _teamNameControllers[index].selection = TextSelection.collapsed(
        offset: trimmedName.length,
      );
    });
  }

  // TEAM SECTION:
  // Deletes a team from the list.
  void _deleteTeam(int index) {
    // Save the team name before deletion.
    final deletedTeam = _teams[index];

    setState(() {
      // Remove the team.
      _teams.removeAt(index);
      _teamNameControllers.removeAt(index).dispose();

      // Remove all pairings containing that team.
      _pairings.removeWhere((pairing) => pairing.contains(deletedTeam));
      _scoreResults.removeWhere(
        (key, value) => key.split('|').contains(deletedTeam),
      );
    });
  }

  // NAVIGATION SECTION:
  // Opens the pairing page.
  void _openPairingPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PairingPage(
          teams: _teams,
          pairings: _pairings,
          scoreResults: _scoreResults,
        ),
      ),
    );
  }

  void _openCreateUserPage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CreateUserPage()),
    );
  }

  void _openTournamentMenuPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TournamentMenuPage(
          teams: _teams,
          pairings: _pairings,
          scoreResults: _scoreResults,
        ),
      ),
    );
  }

  void _openPromoAdsPage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PromoAdsPage()),
    );
  }

  // CLEANUP SECTION:
  // Remove controllers from memory.
  @override
  void dispose() {
    _teamController.dispose();
    _homeScrollController.dispose();
    for (final controller in _teamNameControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // MENU SECTION:
      // Same menu on all pages.
      drawer: _buildAppDrawer(
        context: context,
        onHomeTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const LandingPage()),
          );
        },
        onCreateUserTap: () {
          Navigator.pop(context);
          _openCreateUserPage();
        },
        onTournamentTap: () {
          Navigator.pop(context);
          _openTournamentMenuPage();
        },
        onSingleGamesTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (c) => const MyHomePage(title: 'Team Manager'),
            ),
          );
        },
        onPromoTap: () {
          Navigator.pop(context);
          _openPromoAdsPage();
        },
        onTeamsTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const LandingPage()),
          );
        },
        onPairingsTap: () {
          Navigator.pop(context);
          _openPairingPage();
        },
      ),

      // TOP APP BAR
      appBar: AppBar(
        title: Text(widget.title),

        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),

      // PAGE CONTENT
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Scrollbar(
          controller: _homeScrollController,
          thumbVisibility: true,
          trackVisibility: true,
          child: SingleChildScrollView(
            controller: _homeScrollController,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // TEAM INPUT FIELD
                TextField(
                  // Connect controller to text field.
                  controller: _teamController,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _addTeam(),

                  decoration: const InputDecoration(
                    labelText: 'Team name',

                    // Visible border around field.
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 10),

                // Quick navigation removed — use the app menu (LandingPage)
                const SizedBox.shrink(),
                const SizedBox(height: 20),

                // BUTTON SECTION:
                // Add new team.
                ElevatedButton(
                  onPressed: _addTeam,
                  child: const Text('Add Team'),
                ),

                const SizedBox(height: 10),

                // BUTTON SECTION:
                // Add ten random teams.
                ElevatedButton(
                  onPressed: _addRandomTeams,
                  child: const Text('Add 10 Random Teams'),
                ),

                const SizedBox(height: 10),

                // BUTTON SECTION:
                // Open pairings page.
                ElevatedButton(
                  onPressed: _openPairingPage,
                  child: const Text('Open Pairings'),
                ),

                const SizedBox(height: 20),

                // TEAM LIST SECTION
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _teams.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      title: TextField(
                        controller: _teamNameControllers[index],
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Team name',
                        ),
                        textInputAction: TextInputAction.done,
                        onSubmitted: (value) => _renameTeam(index, value),
                        onEditingComplete: () => _renameTeam(
                          index,
                          _teamNameControllers[index].text,
                        ),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => _deleteTeam(index),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// SECOND SCREEN:
// Handles team pairings.
class PairingPage extends StatefulWidget {
  const PairingPage({
    super.key,
    required this.teams,
    required this.pairings,
    required this.scoreResults,
  });

  // TEAM SECTION:
  // Teams from first screen.
  final List<String> teams;

  // PAIRING SECTION:
  // Pairings from first screen.
  final List<List<String>> pairings;

  // SCORE SECTION:
  // Shared score results across pages.
  final Map<String, ScoreResult> scoreResults;

  @override
  State<PairingPage> createState() => _PairingPageState();
}

class _PairingPageState extends State<PairingPage> {
  // MODE SECTION:
  // Current pairing mode.
  PairingMode _pairingMode = PairingMode.dragAndDrop;

  // SEARCH SECTION:
  // Controls search field.
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _pairingScrollController = ScrollController();
  late Map<String, ScoreResult> _scoreResults;

  @override
  void initState() {
    super.initState();
    _scoreResults = Map<String, ScoreResult>.from(widget.scoreResults);
  }

  // LIST SELECT SECTION:
  // Currently selected team.
  String? _selectedTeam;

  // SEARCH SECTION:
  // Current search text.
  String _searchText = '';

  // PAIRING SECTION:
  // Checks whether a team is already paired.
  bool _isTeamPaired(String team) {
    return widget.pairings.any((pairing) => pairing.contains(team));
  }

  // TEAM SECTION:
  // Returns all unpaired teams.
  List<String> get _availableTeams {
    return widget.teams.where((team) => !_isTeamPaired(team)).toList();
  }

  // SEARCH SECTION:
  // Returns filtered teams based on search.
  List<String> get _filteredAvailableTeams {
    return _availableTeams.where((team) {
      return team.toLowerCase().contains(_searchText.toLowerCase());
    }).toList();
  }

  // PAIRING SECTION:
  // Creates a new pairing.
  void _createPairing(String team1, String team2) {
    // Prevent same team vs itself.
    if (team1 == team2) return;

    // Prevent duplicate pairing usage.
    if (_isTeamPaired(team1) || _isTeamPaired(team2)) {
      return;
    }

    setState(() {
      // Add pairing to list.
      widget.pairings.add([team1, team2]);

      // Reset selected team.
      _selectedTeam = null;
    });
  }

  // PAIRING SECTION:
  // Deletes a pairing.
  void _deletePairing(int index) {
    setState(() {
      widget.pairings.removeAt(index);
    });
  }

  // LIST SELECT SECTION:
  // Select first team, then second team.
  void _selectTeamForPairing(String team) {
    // First selection.
    if (_selectedTeam == null) {
      setState(() {
        _selectedTeam = team;
      });

      return;
    }

    // Second selection creates pairing.
    _createPairing(_selectedTeam!, team);
  }

  // CLEANUP SECTION
  @override
  void dispose() {
    _searchController.dispose();
    _pairingScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // SAME MENU AS HOME PAGE
      drawer: _buildAppDrawer(
        context: context,
        onHomeTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const LandingPage()),
          );
        },
        onCreateUserTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateUserPage()),
          );
        },
        onTournamentTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TournamentMenuPage(
                teams: widget.teams,
                pairings: widget.pairings,
                scoreResults: widget.scoreResults,
              ),
            ),
          );
        },
        onSingleGamesTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const MyHomePage(title: 'Team Manager'),
            ),
          );
        },
        onPromoTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const PromoAdsPage()),
          );
        },
        onTeamsTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const LandingPage()),
          );
        },
        onPairingsTap: () {
          Navigator.pop(context);
        },
      ),

      // TOP APP BAR
      appBar: AppBar(
        title: const Text('Team Pairings'),

        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),

      // PAGE CONTENT
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Scrollbar(
          controller: _pairingScrollController,
          thumbVisibility: true,
          trackVisibility: true,
          child: SingleChildScrollView(
            controller: _pairingScrollController,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // MODE SWITCH SECTION:
                // Switch between drag/drop
                // and list selection.
                SegmentedButton<PairingMode>(
                  segments: const [
                    // Drag & drop mode button.
                    ButtonSegment(
                      value: PairingMode.dragAndDrop,
                      label: Text('Drag & Drop'),
                      icon: Icon(Icons.drag_indicator),
                    ),
                    // List selection mode button.
                    ButtonSegment(
                      value: PairingMode.listSelect,
                      label: Text('List Select'),
                      icon: Icon(Icons.list),
                    ),
                  ],
                  // Currently selected mode.
                  selected: {_pairingMode},
                  // Switch modes.
                  onSelectionChanged: (selection) {
                    setState(() {
                      _pairingMode = selection.first;
                      // Reset selected team.
                      _selectedTeam = null;
                    });
                  },
                ),

                const SizedBox(height: 20),

                // MODE SECTION:
                // Display different UI
                // depending on selected mode.
                _pairingMode == PairingMode.dragAndDrop
                    ? _buildDragAndDropView()
                    : _buildListSelectView(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // DRAG & DROP UI
  Widget _buildDragAndDropView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        // TITLE
        const Text(
          'Available Teams',

          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),

        const SizedBox(height: 10),

        // TEAM CHIPS
        Wrap(
          spacing: 8,
          runSpacing: 8,

          children: _availableTeams.map((team) {
            return DragTarget<String>(
              // Triggered when dropped.
              onAcceptWithDetails: (details) {
                _createPairing(details.data, team);
              },

              builder: (context, candidateData, rejectedData) {
                return Draggable<String>(
                  // Dragged data.
                  data: team,

                  // Widget shown while dragging.
                  feedback: Material(child: Chip(label: Text(team))),

                  // Widget while being dragged.
                  childWhenDragging: Chip(
                    label: Text(team),

                    backgroundColor: Colors.grey.shade300,
                  ),

                  // Normal widget.
                  child: Chip(label: Text(team)),
                );
              },
            );
          }).toList(),
        ),

        const SizedBox(height: 30),

        // PAIRINGS TITLE
        const Text(
          'Pairings',

          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),

        const SizedBox(height: 10),

        // PAIRING LIST
        _buildPairingsList(),
      ],
    );
  }

  // LIST SELECT UI
  Widget _buildListSelectView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        // SEARCH FIELD
        TextField(
          controller: _searchController,

          decoration: const InputDecoration(
            labelText: 'Search teams',

            border: OutlineInputBorder(),
          ),

          // Update search text.
          onChanged: (value) {
            setState(() {
              _searchText = value;
            });
          },
        ),

        const SizedBox(height: 10),

        // SELECTION INFO
        Text(
          _selectedTeam == null
              ? 'Select the first team'
              : 'Selected: $_selectedTeam. Now select the opponent.',
        ),

        const SizedBox(height: 10),

        // SEARCHABLE TEAM LIST
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _filteredAvailableTeams.length,

          itemBuilder: (context, index) {
            final team = _filteredAvailableTeams[index];

            return ListTile(
              // Highlight selected team.
              selected: team == _selectedTeam,

              title: Text(team),

              // Select team.
              onTap: () => _selectTeamForPairing(team),
            );
          },
        ),

        const SizedBox(height: 20),

        // PAIRINGS TITLE
        const Text(
          'Pairings',

          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),

        // PAIRING LIST
        _buildPairingsList(),
      ],
    );
  }

  // PAIRING LIST UI
  Widget _buildPairingsList() {
    // Empty state.
    if (widget.pairings.isEmpty) {
      return const Center(child: Text('No pairings yet'));
    }

    // Pairing list.
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: widget.pairings.length,

      itemBuilder: (context, index) {
        final pairing = widget.pairings[index];
        final key = '${pairing[0]}|${pairing[1]}';
        final result = _scoreResults.putIfAbsent(key, () => ScoreResult());
        final winnerLabel = result.winnerTeam?.isNotEmpty ?? false
            ? 'Winner: ${result.winnerTeam}'
            : null;

        return ListTile(
          // Pairing text.
          title: Text('${pairing[0]} vs ${pairing[1]}'),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${result.score1} - ${result.score2}   (${result.targetPoints} pts)',
              ),
              if (winnerLabel != null) Text(winnerLabel),
            ],
          ),

          // Open scoring screen.
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ScoreCounterPage(
                  team1: pairing[0],
                  team2: pairing[1],
                  result: result,
                  onResultChanged: (newResult) {
                    setState(() {
                      _scoreResults[key] = newResult;
                    });
                  },
                  teams: widget.teams,
                  pairings: widget.pairings,
                  scoreResults: _scoreResults,
                ),
              ),
            );
          },

          // Undo button.
          trailing: IconButton(
            icon: const Icon(Icons.undo),

            onPressed: () => _deletePairing(index),
          ),
        );
      },
    );
  }
}

class ScoreCounterPage extends StatefulWidget {
  const ScoreCounterPage({
    super.key,
    required this.team1,
    required this.team2,
    required this.result,
    required this.onResultChanged,
    required this.teams,
    required this.pairings,
    required this.scoreResults,
  });

  final String team1;
  final String team2;
  final ScoreResult result;
  final ValueChanged<ScoreResult> onResultChanged;
  final List<String> teams;
  final List<List<String>> pairings;
  final Map<String, ScoreResult> scoreResults;

  @override
  State<ScoreCounterPage> createState() => _ScoreCounterPageState();
}

class _ScoreCounterPageState extends State<ScoreCounterPage> {
  late int _score1;
  late int _score2;
  late int _targetPoints;
  late String _winnerTeam;
  final ScrollController _scoreCounterScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _score1 = widget.result.score1;
    _score2 = widget.result.score2;
    _targetPoints = widget.result.targetPoints;
    _winnerTeam = widget.result.winnerTeam ?? '';
  }

  int get _totalPoints => _score1 + _score2;
  int get _sideChangeStep => _targetPoints == 21 ? 7 : 5;
  bool get _showSideChangeReminder {
    return _totalPoints > 0 &&
        _totalPoints < _targetPoints &&
        _totalPoints % _sideChangeStep == 0;
  }

  void _updateScore1(int delta) {
    setState(() {
      _score1 = (_score1 + delta).clamp(0, 999);
    });
    widget.onResultChanged(
      ScoreResult(
        score1: _score1,
        score2: _score2,
        targetPoints: _targetPoints,
        winnerTeam: _winnerTeam,
      ),
    );
  }

  void _updateScore2(int delta) {
    setState(() {
      _score2 = (_score2 + delta).clamp(0, 999);
    });
    widget.onResultChanged(
      ScoreResult(
        score1: _score1,
        score2: _score2,
        targetPoints: _targetPoints,
        winnerTeam: _winnerTeam,
      ),
    );
  }

  void _setTargetPoints(int points) {
    setState(() {
      _targetPoints = points;
    });
    widget.onResultChanged(
      ScoreResult(
        score1: _score1,
        score2: _score2,
        targetPoints: _targetPoints,
        winnerTeam: _winnerTeam,
      ),
    );
  }

  void _setWinnerTeam(String winner) {
    setState(() {
      _winnerTeam = winner;
    });
    widget.onResultChanged(
      ScoreResult(
        score1: _score1,
        score2: _score2,
        targetPoints: _targetPoints,
        winnerTeam: _winnerTeam,
      ),
    );
  }

  @override
  void dispose() {
    _scoreCounterScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: _buildAppDrawer(
        context: context,
        onHomeTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const LandingPage()),
          );
        },
        onCreateUserTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateUserPage()),
          );
        },
        onTournamentTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TournamentMenuPage(
                teams: widget.teams,
                pairings: widget.pairings,
                scoreResults: widget.scoreResults,
              ),
            ),
          );
        },
        onSingleGamesTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const MyHomePage(title: 'Team Manager'),
            ),
          );
        },
        onPromoTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const PromoAdsPage()),
          );
        },
        onTeamsTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const LandingPage()),
          );
        },
        onPairingsTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PairingPage(
                teams: widget.teams,
                pairings: widget.pairings,
                scoreResults: widget.scoreResults,
              ),
            ),
          );
        },
      ),
      appBar: AppBar(
        title: Text('${widget.team1} vs ${widget.team2}'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Scrollbar(
          controller: _scoreCounterScrollController,
          thumbVisibility: true,
          trackVisibility: true,
          child: SingleChildScrollView(
            controller: _scoreCounterScrollController,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Track points for each team',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                SegmentedButton<int>(
                  segments: const [
                    ButtonSegment(value: 15, label: Text('15 Points')),
                    ButtonSegment(value: 21, label: Text('21 Points')),
                  ],
                  selected: {_targetPoints},
                  onSelectionChanged: (selection) {
                    _setTargetPoints(selection.first);
                  },
                ),
                const SizedBox(height: 16),
                Card(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Sum Counter',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Total points: $_totalPoints',
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Change side every $_sideChangeStep points',
                          style: const TextStyle(fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                        if (_showSideChangeReminder) ...[
                          const SizedBox(height: 12),
                          Text(
                            'Change side now',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Winner',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: _winnerTeam == widget.team1
                              ? Theme.of(context).colorScheme.primary
                              : null,
                          foregroundColor: _winnerTeam == widget.team1
                              ? Colors.white
                              : null,
                        ),
                        onPressed: () => _setWinnerTeam(
                          _winnerTeam == widget.team1 ? '' : widget.team1,
                        ),
                        child: Text(widget.team1),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: _winnerTeam == widget.team2
                              ? Theme.of(context).colorScheme.primary
                              : null,
                          foregroundColor: _winnerTeam == widget.team2
                              ? Colors.white
                              : null,
                        ),
                        onPressed: () => _setWinnerTeam(
                          _winnerTeam == widget.team2 ? '' : widget.team2,
                        ),
                        child: Text(widget.team2),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _winnerTeam.isNotEmpty
                      ? 'Selected winner: $_winnerTeam'
                      : 'Tap a team to select the winner. Tap again to clear.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 179),
                  ),
                ),
                const SizedBox(height: 20),
                _buildScoreCard(widget.team1, _score1, _updateScore1),
                const SizedBox(height: 16),
                _buildScoreCard(widget.team2, _score2, _updateScore2),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  icon: const Icon(Icons.check),
                  label: const Text('Done'),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScoreCard(
    String team,
    int score,
    ValueChanged<int> updateScore,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              team,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  onPressed: () => updateScore(-1),
                ),
                Text(
                  '$score',
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: () => updateScore(1),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ScoreSummaryPage extends StatefulWidget {
  const ScoreSummaryPage({
    super.key,
    required this.teams,
    required this.pairings,
    required this.scoreResults,
  });

  final List<String> teams;
  final List<List<String>> pairings;
  final Map<String, ScoreResult> scoreResults;

  @override
  State<ScoreSummaryPage> createState() => _ScoreSummaryPageState();
}

class _ScoreSummaryPageState extends State<ScoreSummaryPage> {
  final ScrollController _summaryScrollController = ScrollController();
  late Map<String, ScoreResult> _scoreResults;

  @override
  void initState() {
    super.initState();
    _scoreResults = Map<String, ScoreResult>.from(widget.scoreResults);
  }

  @override
  void dispose() {
    _summaryScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: _buildAppDrawer(
        context: context,
        onHomeTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const LandingPage()),
          );
        },
        onCreateUserTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateUserPage()),
          );
        },
        onTournamentTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TournamentMenuPage(
                teams: widget.teams,
                pairings: widget.pairings,
                scoreResults: widget.scoreResults,
              ),
            ),
          );
        },
        onSingleGamesTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const MyHomePage(title: 'Team Manager'),
            ),
          );
        },
        onPromoTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const PromoAdsPage()),
          );
        },
        onTeamsTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const LandingPage()),
          );
        },
        onPairingsTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PairingPage(
                teams: widget.teams,
                pairings: widget.pairings,
                scoreResults: widget.scoreResults,
              ),
            ),
          );
        },
      ),
      appBar: AppBar(
        title: const Text('Scores Summary'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: widget.pairings.isEmpty
          ? const Center(child: Text('No pairings yet'))
          : Scrollbar(
              controller: _summaryScrollController,
              thumbVisibility: true,
              trackVisibility: true,
              child: ListView.builder(
                controller: _summaryScrollController,
                itemCount: widget.pairings.length,
                itemBuilder: (context, index) {
                  final pairing = widget.pairings[index];
                  final key = '${pairing[0]}|${pairing[1]}';
                  final result = _scoreResults[key] ?? ScoreResult();
                  return ListTile(
                    title: Text('${pairing[0]} vs ${pairing[1]}'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${result.score1} - ${result.score2}   (${result.targetPoints} pts)',
                        ),
                        if (result.winnerTeam?.isNotEmpty ?? false)
                          Text('Winner: ${result.winnerTeam}'),
                      ],
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ScoreCounterPage(
                            team1: pairing[0],
                            team2: pairing[1],
                            result: result,
                            onResultChanged: (newResult) {
                              setState(() {
                                _scoreResults[key] = newResult;
                              });
                            },
                            teams: widget.teams,
                            pairings: widget.pairings,
                            scoreResults: _scoreResults,
                          ),
                        ),
                      ).then((_) {
                        setState(() {});
                      });
                    },
                  );
                },
              ),
            ),
    );
  }
}

// GLOBAL MENU WIDGET
Drawer _buildAppDrawer({
  required BuildContext context,
  required VoidCallback onHomeTap,
  required VoidCallback onCreateUserTap,
  required VoidCallback onTournamentTap,
  required VoidCallback onSingleGamesTap,
  required VoidCallback onPromoTap,
  required VoidCallback onTeamsTap,
  required VoidCallback onPairingsTap,
}) {
  return Drawer(
    child: ListView(
      children: [
        // MENU HEADER
        DrawerHeader(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
          ),

          child: const Text(
            'Menu',

            style: TextStyle(color: Colors.white, fontSize: 24),
          ),
        ),

        // HOME PAGE BUTTON
        ListTile(
          leading: const Icon(Icons.home),
          title: const Text('Home'),
          onTap: onHomeTap,
        ),

        // SINGLE GAMES BUTTON
        ListTile(
          leading: const Icon(Icons.sports_tennis),
          title: const Text('Single Games'),
          onTap: onSingleGamesTap,
        ),

        // TOURNAMENT BUTTON
        ListTile(
          leading: const Icon(Icons.emoji_events),
          title: const Text('Create Tournament'),
          onTap: onTournamentTap,
        ),

        // CREATE USER BUTTON
        ListTile(
          leading: const Icon(Icons.person_add),
          title: const Text('Create User'),
          onTap: onCreateUserTap,
        ),

        // PROMO PAGE BUTTON
        ListTile(
          leading: const Icon(Icons.campaign),
          title: const Text('Promo & Ads'),
          onTap: onPromoTap,
        ),
      ],
    ),
  );
}

class CreateUserPage extends StatelessWidget {
  const CreateUserPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: _buildAppDrawer(
        context: context,
        onHomeTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const LandingPage()),
          );
        },
        onCreateUserTap: () {
          Navigator.pop(context);
        },
        onTournamentTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TournamentMenuPage(
                teams: const [],
                pairings: const [],
                scoreResults: const {},
              ),
            ),
          );
        },
        onSingleGamesTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const MyHomePage(title: 'Team Manager'),
            ),
          );
        },
        onPromoTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const PromoAdsPage()),
          );
        },
        onTeamsTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const LandingPage()),
          );
        },
        onPairingsTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PairingPage(
                teams: const [],
                pairings: const [],
                scoreResults: const {},
              ),
            ),
          );
        },
      ),
      appBar: AppBar(
        title: const Text('Create User'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: const Center(
        child: Text('This is a placeholder Create User page.'),
      ),
    );
  }
}

class TournamentMenuPage extends StatelessWidget {
  final List<String> teams;
  final List<List<String>> pairings;
  final Map<String, ScoreResult> scoreResults;

  const TournamentMenuPage({
    super.key,
    required this.teams,
    required this.pairings,
    required this.scoreResults,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: _buildAppDrawer(
        context: context,
        onHomeTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const LandingPage()),
          );
        },
        onCreateUserTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateUserPage()),
          );
        },
        onTournamentTap: () {
          Navigator.pop(context);
        },
        onSingleGamesTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const MyHomePage(title: 'Team Manager'),
            ),
          );
        },
        onPromoTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const PromoAdsPage()),
          );
        },
        onTeamsTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const LandingPage()),
          );
        },
        onPairingsTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PairingPage(
                teams: teams,
                pairings: pairings,
                scoreResults: scoreResults,
              ),
            ),
          );
        },
      ),
      appBar: AppBar(
        title: const Text('Tournament Menu'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Create Tournament',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (c) => StandardModesPage(
                    teams: teams,
                    pairings: pairings,
                    scoreResults: scoreResults,
                  ),
                ),
              ),
              child: const Text('Standard Modes'),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (c) => HybridModesPage(
                    teams: teams,
                    pairings: pairings,
                    scoreResults: scoreResults,
                  ),
                ),
              ),
              child: const Text('Hybrid Modes'),
            ),
            const SizedBox(height: 20),
            Text('Teams: ${teams.length}'),
            Text('Pairings: ${pairings.length}'),
          ],
        ),
      ),
    );
  }
}

class StandardModesPage extends StatelessWidget {
  final List<String> teams;
  final List<List<String>> pairings;
  final Map<String, ScoreResult> scoreResults;

  const StandardModesPage({
    super.key,
    required this.teams,
    required this.pairings,
    required this.scoreResults,
  });

  @override
  Widget build(BuildContext context) {
    final modes = [
      'Single Games',
      'League',
      'Single Elimination',
      'Double Elimination',
      'King of the Court',
      'Randomizer',
      'Swiss',
      'Manual Tournament',
    ];

    return Scaffold(
      drawer: _buildAppDrawer(
        context: context,
        onHomeTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const LandingPage()),
          );
        },
        onCreateUserTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (c) => const CreateUserPage()),
          );
        },
        onTournamentTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (c) => TournamentMenuPage(
                teams: teams,
                pairings: pairings,
                scoreResults: scoreResults,
              ),
            ),
          );
        },
        onSingleGamesTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (c) => const MyHomePage(title: 'Team Manager'),
            ),
          );
        },
        onPromoTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (c) => const PromoAdsPage()),
          );
        },
        onTeamsTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const LandingPage()),
          );
        },
        onPairingsTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (c) => PairingPage(
                teams: teams,
                pairings: pairings,
                scoreResults: scoreResults,
              ),
            ),
          );
        },
      ),
      appBar: AppBar(
        title: const Text('Standard Modes'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: modes.map((m) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: FilledButton(
                onPressed: () {
                  if (m == 'Single Games') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (c) => const MyHomePage(title: 'Team Manager'),
                      ),
                    );
                  } else if (m == 'League') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (c) => LeaguePage(
                          teams: teams,
                          pairings: pairings,
                          scoreResults: scoreResults,
                        ),
                      ),
                    );
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (c) => ModePlaceholderPage(modeName: m),
                      ),
                    );
                  }
                },
                child: Text(m),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class LeaguePage extends StatefulWidget {
  final List<String> teams;
  final List<List<String>> pairings;
  final Map<String, ScoreResult> scoreResults;

  const LeaguePage({
    super.key,
    required this.teams,
    required this.pairings,
    required this.scoreResults,
  });

  @override
  State<LeaguePage> createState() => _LeaguePageState();
}

class _LeaguePageState extends State<LeaguePage> {
  final TextEditingController _teamController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final Random _random = Random();
  late List<String> _leagueTeams;
  late Map<String, ScoreResult> _scoreResults;

  static const _teamPrefixes = [
    'Red',
    'Blue',
    'Golden',
    'Silver',
    'Mighty',
    'Wild',
    'Thunder',
    'Iron',
    'Swift',
    'Shadow',
  ];
  static const _teamSuffixes = [
    'Dragons',
    'Titans',
    'Warriors',
    'Falcons',
    'Knights',
    'Pirates',
    'Rangers',
    'Storm',
    'Guardians',
    'Eagles',
  ];

  @override
  void initState() {
    super.initState();
    _leagueTeams = List<String>.from(widget.teams);
    _scoreResults = Map<String, ScoreResult>.from(widget.scoreResults);
  }

  @override
  void dispose() {
    _teamController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _addTeam() {
    final teamName = _teamController.text.trim();
    if (teamName.isEmpty) return;
    if (_leagueTeams.contains(teamName)) return;

    if (!mounted) return;

    setState(() {
      _leagueTeams.add(teamName);
      _teamController.clear();
    });
  }

  void _addRandomTeams() {
    if (!mounted) return;

    setState(() {
      for (var i = 0; i < 10; i++) {
        final teamName = _generateRandomTeamName();
        _leagueTeams.add(teamName);
      }
    });
  }

  String _generateRandomTeamName() {
    final prefix = _teamPrefixes[_random.nextInt(_teamPrefixes.length)];
    final suffix = _teamSuffixes[_random.nextInt(_teamSuffixes.length)];
    final number = _random.nextInt(100) + 1;
    final name = '$prefix $suffix $number';
    return _leagueTeams.contains(name) ? _generateRandomTeamName() : name;
  }

  List<List<String>> _buildRoundRobinPairings() {
    final pairs = <List<String>>[];
    for (var i = 0; i < _leagueTeams.length; i++) {
      for (var j = i + 1; j < _leagueTeams.length; j++) {
        pairs.add([_leagueTeams[i], _leagueTeams[j]]);
      }
    }
    return pairs;
  }

  @override
  Widget build(BuildContext context) {
    final canStartLeague = _leagueTeams.length >= 2;
    return Scaffold(
      drawer: _buildAppDrawer(
        context: context,
        onHomeTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const LandingPage()),
          );
        },
        onCreateUserTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (c) => const CreateUserPage()),
          );
        },
        onTournamentTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (c) => TournamentMenuPage(
                teams: widget.teams,
                pairings: widget.pairings,
                scoreResults: widget.scoreResults,
              ),
            ),
          );
        },
        onSingleGamesTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (c) => const MyHomePage(title: 'Team Manager'),
            ),
          );
        },
        onPromoTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (c) => const PromoAdsPage()),
          );
        },
        onTeamsTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const LandingPage()),
          );
        },
        onPairingsTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (c) => PairingPage(
                teams: widget.teams,
                pairings: widget.pairings,
                scoreResults: widget.scoreResults,
              ),
            ),
          );
        },
      ),
      appBar: AppBar(
        title: const Text('League Setup'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Scrollbar(
          controller: _scrollController,
          thumbVisibility: true,
          trackVisibility: true,
          child: SingleChildScrollView(
            controller: _scrollController,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Create league teams',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _teamController,
                  decoration: const InputDecoration(
                    labelText: 'Team name',
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => _addTeam(),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: _addTeam,
                  child: const Text('Add Team'),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: _addRandomTeams,
                  child: const Text('Add 10 Random Teams'),
                ),
                const SizedBox(height: 14),
                Text('Teams: ${_leagueTeams.length}'),
                const SizedBox(height: 10),
                if (_leagueTeams.isEmpty)
                  const Text('Add at least two teams to start the league.')
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _leagueTeams.length,
                    itemBuilder: (context, index) {
                      return ListTile(title: Text(_leagueTeams[index]));
                    },
                  ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: canStartLeague
                      ? () {
                          final leaguePairings = _buildRoundRobinPairings();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => LeaguePairingsPage(
                                leagueTeams: _leagueTeams,
                                leaguePairings: leaguePairings,
                                scoreResults: _scoreResults,
                              ),
                            ),
                          ).then((_) => setState(() {}));
                        }
                      : null,
                  child: const Text('Open League Pairings'),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: canStartLeague
                      ? () {
                          final leaguePairings = _buildRoundRobinPairings();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => LeagueOutcomePage(
                                leagueTeams: _leagueTeams,
                                leaguePairings: leaguePairings,
                                scoreResults: _scoreResults,
                              ),
                            ),
                          ).then((_) => setState(() {}));
                        }
                      : null,
                  child: const Text('View League Outcome'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class LeaguePairingsPage extends StatefulWidget {
  final List<String> leagueTeams;
  final List<List<String>> leaguePairings;
  final Map<String, ScoreResult> scoreResults;

  const LeaguePairingsPage({
    super.key,
    required this.leagueTeams,
    required this.leaguePairings,
    required this.scoreResults,
  });

  @override
  State<LeaguePairingsPage> createState() => _LeaguePairingsPageState();
}

class _LeaguePairingsPageState extends State<LeaguePairingsPage> {
  late Map<String, ScoreResult> _scoreResults;

  @override
  void initState() {
    super.initState();
    _scoreResults = Map<String, ScoreResult>.from(widget.scoreResults);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: _buildAppDrawer(
        context: context,
        onHomeTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const LandingPage()),
          );
        },
        onCreateUserTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (c) => const CreateUserPage()),
          );
        },
        onTournamentTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (c) => TournamentMenuPage(
                teams: widget.leagueTeams,
                pairings: widget.leaguePairings,
                scoreResults: widget.scoreResults,
              ),
            ),
          );
        },
        onSingleGamesTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (c) => const MyHomePage(title: 'Team Manager'),
            ),
          );
        },
        onPromoTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (c) => const PromoAdsPage()),
          );
        },
        onTeamsTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const LandingPage()),
          );
        },
        onPairingsTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (c) => PairingPage(
                teams: widget.leagueTeams,
                pairings: widget.leaguePairings,
                scoreResults: widget.scoreResults,
              ),
            ),
          );
        },
      ),
      appBar: AppBar(
        title: const Text('League Pairings'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView.builder(
          itemCount: widget.leaguePairings.length,
          itemBuilder: (context, index) {
            final pairing = widget.leaguePairings[index];
            final key = '${pairing[0]}|${pairing[1]}';
            final result = _scoreResults.putIfAbsent(key, () => ScoreResult());
            final winnerLabel = result.winnerTeam?.isNotEmpty ?? false
                ? 'Winner: ${result.winnerTeam}'
                : 'No winner yet';
            return ListTile(
              title: Text('${pairing[0]} vs ${pairing[1]}'),
              subtitle: Text(
                '${result.score1} - ${result.score2}  ($winnerLabel)',
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ScoreCounterPage(
                      team1: pairing[0],
                      team2: pairing[1],
                      result: result,
                      onResultChanged: (newResult) {
                        setState(() {
                          _scoreResults[key] = newResult;
                        });
                      },
                      teams: widget.leagueTeams,
                      pairings: widget.leaguePairings,
                      scoreResults: _scoreResults,
                    ),
                  ),
                ).then((_) {
                  setState(() {});
                });
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => LeagueOutcomePage(
                leagueTeams: widget.leagueTeams,
                leaguePairings: widget.leaguePairings,
                scoreResults: _scoreResults,
              ),
            ),
          ).then((_) => setState(() {}));
        },
        label: const Text('League Outcome'),
        icon: const Icon(Icons.leaderboard),
      ),
    );
  }
}

class LeagueOutcomePage extends StatelessWidget {
  final List<String> leagueTeams;
  final List<List<String>> leaguePairings;
  final Map<String, ScoreResult> scoreResults;

  const LeagueOutcomePage({
    super.key,
    required this.leagueTeams,
    required this.leaguePairings,
    required this.scoreResults,
  });

  List<LeagueStanding> _buildStandings() {
    final standings = {
      for (final team in leagueTeams) team: LeagueStanding(team: team),
    };

    for (final pairing in leaguePairings) {
      final key = '${pairing[0]}|${pairing[1]}';
      final result = scoreResults[key] ?? ScoreResult();
      final left = standings[pairing[0]]!;
      final right = standings[pairing[1]]!;

      left.pointsFor += result.score1;
      left.pointsAgainst += result.score2;
      right.pointsFor += result.score2;
      right.pointsAgainst += result.score1;

      if (result.winnerTeam == pairing[0]) {
        left.wins += 1;
        right.losses += 1;
      } else if (result.winnerTeam == pairing[1]) {
        right.wins += 1;
        left.losses += 1;
      } else if (result.score1 > result.score2) {
        left.wins += 1;
        right.losses += 1;
      } else if (result.score2 > result.score1) {
        right.wins += 1;
        left.losses += 1;
      } else {
        left.draws += 1;
        right.draws += 1;
      }
    }

    final sorted = standings.values.toList();
    sorted.sort((a, b) {
      if (b.wins != a.wins) {
        return b.wins.compareTo(a.wins);
      }
      if (b.pointDifference != a.pointDifference) {
        return b.pointDifference.compareTo(a.pointDifference);
      }
      return b.pointsFor.compareTo(a.pointsFor);
    });
    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    final standings = _buildStandings();
    return Scaffold(
      drawer: _buildAppDrawer(
        context: context,
        onHomeTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const LandingPage()),
          );
        },
        onCreateUserTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (c) => const CreateUserPage()),
          );
        },
        onTournamentTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (c) => TournamentMenuPage(
                teams: leagueTeams,
                pairings: leaguePairings,
                scoreResults: scoreResults,
              ),
            ),
          );
        },
        onSingleGamesTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (c) => const MyHomePage(title: 'Team Manager'),
            ),
          );
        },
        onPromoTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (c) => const PromoAdsPage()),
          );
        },
        onTeamsTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const LandingPage()),
          );
        },
        onPairingsTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (c) => PairingPage(
                teams: leagueTeams,
                pairings: leaguePairings,
                scoreResults: scoreResults,
              ),
            ),
          );
        },
      ),
      appBar: AppBar(
        title: const Text('League Outcome'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView.builder(
          itemCount: standings.length,
          itemBuilder: (context, index) {
            final standing = standings[index];
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 6),
              child: ListTile(
                title: Text(standing.team),
                subtitle: Text(
                  'W:${standing.wins} D:${standing.draws} L:${standing.losses} • Scored: ${standing.pointsFor} • Against: ${standing.pointsAgainst} • Diff: ${standing.pointDifference}',
                ),
                trailing: Text('#${index + 1}'),
              ),
            );
          },
        ),
      ),
    );
  }
}

class ModePlaceholderPage extends StatelessWidget {
  final String modeName;
  const ModePlaceholderPage({super.key, required this.modeName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: _buildAppDrawer(
        context: context,
        onHomeTap: () => Navigator.popUntil(context, (route) => route.isFirst),
        onCreateUserTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (c) => const CreateUserPage()),
          );
        },
        onTournamentTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (c) => const TournamentMenuPage(
                teams: [],
                pairings: [],
                scoreResults: {},
              ),
            ),
          );
        },
        onSingleGamesTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (c) => const MyHomePage(title: 'Team Manager'),
            ),
          );
        },
        onPromoTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (c) => const PromoAdsPage()),
          );
        },
        onTeamsTap: () => Navigator.popUntil(context, (route) => route.isFirst),
        onPairingsTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (c) => const MyHomePage(title: 'Team Manager'),
            ),
          );
        },
      ),
      appBar: AppBar(
        title: Text(modeName),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(child: Text('$modeName placeholder page')),
    );
  }
}

class HybridModesPage extends StatefulWidget {
  final List<String> teams;
  final List<List<String>> pairings;
  final Map<String, ScoreResult> scoreResults;

  const HybridModesPage({
    super.key,
    required this.teams,
    required this.pairings,
    required this.scoreResults,
  });

  @override
  State<HybridModesPage> createState() => _HybridModesPageState();
}

class _HybridModesPageState extends State<HybridModesPage> {
  final List<String> _modes = [
    'Single Games',
    'League',
    'Single Elimination',
    'Double Elimination',
    'King of the Court',
    'Randomizer',
    'Swiss',
    'Manual Tournament',
  ];
  final List<String> _group = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: _buildAppDrawer(
        context: context,
        onHomeTap: () => Navigator.popUntil(context, (route) => route.isFirst),
        onCreateUserTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (c) => const CreateUserPage()),
          );
        },
        onTournamentTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (c) => TournamentMenuPage(
                teams: widget.teams,
                pairings: widget.pairings,
                scoreResults: widget.scoreResults,
              ),
            ),
          );
        },
        onSingleGamesTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (c) => const MyHomePage(title: 'Team Manager'),
            ),
          );
        },
        onPromoTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (c) => const PromoAdsPage()),
          );
        },
        onTeamsTap: () => Navigator.popUntil(context, (route) => route.isFirst),
        onPairingsTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (c) => PairingPage(
                teams: widget.teams,
                pairings: widget.pairings,
                scoreResults: widget.scoreResults,
              ),
            ),
          );
        },
      ),
      appBar: AppBar(
        title: const Text('Hybrid Modes'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Drag modes into the group to create a hybrid'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: _modes.map((m) {
                return Draggable<String>(
                  data: m,
                  feedback: Material(child: Chip(label: Text(m))),
                  childWhenDragging: Chip(
                    label: Text(m),
                    backgroundColor: Colors.grey.shade300,
                  ),
                  child: Chip(label: Text(m)),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: DragTarget<String>(
                onAcceptWithDetails: (details) {
                  final data = details.data;
                  setState(() {
                    if (!_group.contains(data)) _group.add(data);
                  });
                },
                builder: (context, candidateData, rejected) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Grouped Modes',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (_group.isEmpty) const Text('Drop modes here'),
                          Wrap(
                            spacing: 8,
                            children: _group
                                .map((g) => Chip(label: Text(g)))
                                .toList(),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SingleGamesPage extends StatelessWidget {
  final List<String> teams;
  final List<List<String>> pairings;
  final Map<String, ScoreResult> scoreResults;

  const SingleGamesPage({
    super.key,
    required this.teams,
    required this.pairings,
    required this.scoreResults,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: _buildAppDrawer(
        context: context,
        onHomeTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const LandingPage()),
          );
        },
        onCreateUserTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateUserPage()),
          );
        },
        onTournamentTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TournamentMenuPage(
                teams: teams,
                pairings: pairings,
                scoreResults: scoreResults,
              ),
            ),
          );
        },
        onSingleGamesTap: () {
          Navigator.pop(context);
        },
        onPromoTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const PromoAdsPage()),
          );
        },
        onTeamsTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const LandingPage()),
          );
        },
        onPairingsTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PairingPage(
                teams: teams,
                pairings: pairings,
                scoreResults: scoreResults,
              ),
            ),
          );
        },
      ),
      appBar: AppBar(
        title: const Text('Single Games'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Single games placeholder screen.'),
            const SizedBox(height: 12),
            Text('Teams available: ${teams.length}'),
          ],
        ),
      ),
    );
  }
}

class PromoAdsPage extends StatefulWidget {
  const PromoAdsPage({super.key});

  @override
  State<PromoAdsPage> createState() => _PromoAdsPageState();
}

class _PromoAdsPageState extends State<PromoAdsPage> {
  BannerAd? _bannerAd1;
  BannerAd? _bannerAd2;
  bool _isAdLoaded1 = false;
  bool _isAdLoaded2 = false;
  bool _adsSupported = false;

  @override
  void initState() {
    super.initState();
    _adsSupported =
        defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.android ||
        kIsWeb;
    if (_adsSupported) {
      _initializeBannerAds();
    }
  }

  void _initializeBannerAds() {
    // Test Banner Ad 1
    _bannerAd1 = BannerAd(
      adUnitId:
          'ca-app-pub-3940256099942544/6300978111', // Google test banner ad unit
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (Ad ad) {
          if (mounted) {
            setState(() {
              _isAdLoaded1 = true;
            });
          }
        },
        onAdFailedToLoad: (Ad ad, LoadAdError error) {
          ad.dispose();
        },
      ),
    );
    _bannerAd1!.load();

    // Test Banner Ad 2 (Medium Rectangle)
    _bannerAd2 = BannerAd(
      adUnitId:
          'ca-app-pub-3940256099942544/6300978111', // Google test banner ad unit
      size: AdSize.mediumRectangle,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (Ad ad) {
          if (mounted) {
            setState(() {
              _isAdLoaded2 = true;
            });
          }
        },
        onAdFailedToLoad: (Ad ad, LoadAdError error) {
          ad.dispose();
        },
      ),
    );
    _bannerAd2!.load();
  }

  @override
  void dispose() {
    _bannerAd1?.dispose();
    _bannerAd2?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: _buildAppDrawer(
        context: context,
        onHomeTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const LandingPage()),
          );
        },
        onCreateUserTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateUserPage()),
          );
        },
        onTournamentTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TournamentMenuPage(
                teams: const [],
                pairings: const [],
                scoreResults: const {},
              ),
            ),
          );
        },
        onSingleGamesTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const MyHomePage(title: 'Team Manager'),
            ),
          );
        },
        onPromoTap: () {
          Navigator.pop(context);
        },
        onTeamsTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const LandingPage()),
          );
        },
        onPairingsTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PairingPage(
                teams: const [],
                pairings: const [],
                scoreResults: const {},
              ),
            ),
          );
        },
      ),
      appBar: AppBar(
        title: const Text('Promo & Ads'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _adsSupported
          ? SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Test Mobile Ads',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Standard Banner Ad (320x50)',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_isAdLoaded1)
                      SizedBox(
                        width: 320,
                        height: 50,
                        child: AdWidget(ad: _bannerAd1!),
                      )
                    else
                      Container(
                        width: 320,
                        height: 50,
                        color: Colors.grey.shade200,
                        child: const Center(
                          child: Text('Banner Ad Loading...'),
                        ),
                      ),
                    const SizedBox(height: 24),
                    const Text(
                      'Medium Rectangle Ad (300x250)',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_isAdLoaded2)
                      SizedBox(
                        width: 300,
                        height: 250,
                        child: AdWidget(ad: _bannerAd2!),
                      )
                    else
                      Container(
                        width: 300,
                        height: 250,
                        color: Colors.grey.shade200,
                        child: const Center(
                          child: Text('Medium Rectangle Ad Loading...'),
                        ),
                      ),
                    const SizedBox(height: 24),
                    Card(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'Using Google Test Ad Units',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'These are Google-provided test ad units for development and testing. '
                              'Replace with your actual Ad Unit IDs before publishing.',
                              style: TextStyle(fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 48,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Mobile Ads Not Available',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Google Mobile Ads are only available on iOS, Android, and Web platforms. '
                      'Test this feature on a mobile device or emulator.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
