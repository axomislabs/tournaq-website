import 'dart:math';

import 'package:flutter/material.dart';

import '../models/game.dart';
import '../models/team.dart';
import '../services/app_data_service.dart';
import '../state/app_state.dart';

enum _TeamMethod { existing, createNew, random }

class QuickStartSheet extends StatefulWidget {
  final AppState appState;

  const QuickStartSheet({super.key, required this.appState});

  @override
  State<QuickStartSheet> createState() => _QuickStartSheetState();
}

class _QuickStartSheetState extends State<QuickStartSheet> {
  MatchFormat? _format;
  _TeamMethod? _method;
  late AppState _state;

  String? _team1Id;
  String? _team2Id;

  final _team1Controller = TextEditingController();
  final _team2Controller = TextEditingController();

  String _randomTeam1Name = '';
  String _randomTeam2Name = '';

  static const _adjectives = [
    'Thunder', 'Iron', 'Swift', 'Bold', 'Red', 'Blue', 'Gold', 'Silver',
    'Dark', 'Storm', 'Crimson', 'Blazing', 'Frozen', 'Shadow', 'Solar',
    'Mighty', 'Royal', 'Wild', 'Steel', 'Fire',
  ];
  static const _nouns = [
    'Hawks', 'Bears', 'Lions', 'Eagles', 'Wolves', 'Panthers', 'Sharks',
    'Tigers', 'Foxes', 'Dragons', 'Cobras', 'Ravens', 'Falcons', 'Jaguars',
    'Vipers', 'Stallions', 'Rhinos', 'Gladiators', 'Titans', 'Strikers',
  ];

  @override
  void initState() {
    super.initState();
    _state = widget.appState;
    _generateRandomNames();
  }

  @override
  void dispose() {
    _team1Controller.dispose();
    _team2Controller.dispose();
    super.dispose();
  }

  void _generateRandomNames() {
    final rng = Random();
    final adj1 = _adjectives[rng.nextInt(_adjectives.length)];
    final adj2 = _adjectives[rng.nextInt(_adjectives.length)];
    final noun1 = _nouns[rng.nextInt(_nouns.length)];
    String noun2;
    do {
      noun2 = _nouns[rng.nextInt(_nouns.length)];
    } while (noun2 == noun1);
    setState(() {
      _randomTeam1Name = '$adj1 $noun1';
      _randomTeam2Name = '$adj2 $noun2';
    });
  }

  void _startGame(String team1Id, String team2Id) {
    final newState = AppDataService.createQuickGame(
      _state,
      team1Id: team1Id,
      team2Id: team2Id,
      matchFormat: _format!,
    );
    final gameId = newState.games.last.id;
    Navigator.pop(context, (state: newState, gameId: gameId));
  }

  void _startWithNewTeams() {
    final name1 = _team1Controller.text.trim();
    final name2 = _team2Controller.text.trim();
    if (name1.isEmpty || name2.isEmpty) return;

    var newState = AppDataService.createTeamWithPlayers(
      _state,
      name: name1,
      scope: TeamScope.temporary,
    );
    final team1Id = newState.teams.last.id;
    newState = AppDataService.createTeamWithPlayers(
      newState,
      name: name2,
      scope: TeamScope.temporary,
    );
    final team2Id = newState.teams.last.id;
    _state = newState;
    _startGame(team1Id, team2Id);
  }

  void _startWithRandomTeams() {
    var newState = AppDataService.createTeamWithPlayers(
      _state,
      name: _randomTeam1Name,
      scope: TeamScope.temporary,
    );
    final team1Id = newState.teams.last.id;
    newState = AppDataService.createTeamWithPlayers(
      newState,
      name: _randomTeam2Name,
      scope: TeamScope.temporary,
    );
    final team2Id = newState.teams.last.id;
    _state = newState;
    _startGame(team1Id, team2Id);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 4),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
                child: _buildCurrentStep(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentStep() {
    if (_format == null) return _buildFormatPicker();
    if (_method == null) return _buildMethodPicker();
    return _buildTeamPicker();
  }

  // ── Step 1: Format ────────────────────────────────────────────────────────

  Widget _buildFormatPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Color(0xFFFFF8E1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.flash_on_rounded, color: Color(0xFFB08B1E), size: 22),
            ),
            const SizedBox(width: 12),
            const Text(
              'Quick Start a Game',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          'How long is the match?',
          style: TextStyle(color: Colors.black54, fontSize: 15),
        ),
        const SizedBox(height: 24),
        _buildOptionCard(
          icon: Icons.filter_1_rounded,
          label: 'One Set',
          subtitle: 'Single set to decide the winner',
          onTap: () => setState(() => _format = MatchFormat.oneSet),
        ),
        const SizedBox(height: 12),
        _buildOptionCard(
          icon: Icons.filter_3_rounded,
          label: 'Best of Three Sets',
          subtitle: 'First to win two sets wins the match',
          onTap: () => setState(() => _format = MatchFormat.bestOfThree),
        ),
      ],
    );
  }

  // ── Step 2: Team method ───────────────────────────────────────────────────

  Widget _buildMethodPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildBackHeader(
          _format == MatchFormat.oneSet ? 'One Set' : 'Best of Three',
          onBack: () => setState(() => _format = null),
        ),
        const SizedBox(height: 8),
        const Text(
          'How would you like to choose your teams?',
          style: TextStyle(color: Colors.black54, fontSize: 15),
        ),
        const SizedBox(height: 24),
        _buildOptionCard(
          icon: Icons.group_rounded,
          label: 'Select Existing Teams',
          subtitle: 'Choose from your saved teams',
          onTap: () => setState(() => _method = _TeamMethod.existing),
        ),
        const SizedBox(height: 12),
        _buildOptionCard(
          icon: Icons.edit_rounded,
          label: 'Create New Teams',
          subtitle: 'Name your teams on the fly',
          onTap: () => setState(() => _method = _TeamMethod.createNew),
        ),
        const SizedBox(height: 12),
        _buildOptionCard(
          icon: Icons.casino_rounded,
          label: 'Generate Random Teams',
          subtitle: 'Let us pick fun team names',
          onTap: () => setState(() => _method = _TeamMethod.random),
        ),
      ],
    );
  }

  // ── Step 3: Team picker ───────────────────────────────────────────────────

  Widget _buildTeamPicker() {
    switch (_method!) {
      case _TeamMethod.existing:
        return _buildExistingTeams();
      case _TeamMethod.createNew:
        return _buildCreateNew();
      case _TeamMethod.random:
        return _buildRandom();
    }
  }

  // ── Shared helpers ────────────────────────────────────────────────────────

  Widget _buildBackHeader(String title, {VoidCallback? onBack}) {
    return Row(
      children: [
        GestureDetector(
          onTap: onBack ?? () => setState(() => _method = null),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.grey[100], shape: BoxShape.circle),
            child: const Icon(Icons.arrow_back_ios_new_rounded, size: 16),
          ),
        ),
        const SizedBox(width: 12),
        Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
      ],
    );
  }

  Widget _buildOptionCard({
    required IconData icon,
    required String label,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFEEEEEE)),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(color: Color(0xFFFFF8E1), shape: BoxShape.circle),
              child: Icon(icon, color: const Color(0xFFB08B1E), size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                  Text(subtitle, style: const TextStyle(color: Colors.black45, fontSize: 13)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.black26),
          ],
        ),
      ),
    );
  }

  Widget _buildStartButton({required VoidCallback? onPressed}) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.play_arrow_rounded),
        label: const Text(
          'Start Game',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFB08B1E),
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.grey[200],
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _buildExistingTeams() {
    final teams = _state.teams;

    if (teams.length < 2) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBackHeader('Select Teams'),
          const SizedBox(height: 48),
          const Center(
            child: Column(
              children: [
                Icon(Icons.group_off_rounded, size: 52, color: Colors.black26),
                SizedBox(height: 12),
                Text(
                  'Not enough teams',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                ),
                SizedBox(height: 4),
                Text(
                  'You need at least 2 saved teams.\nTry creating or generating teams instead.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.black45),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildBackHeader('Select Teams'),
        const SizedBox(height: 24),
        const Text('Team 1', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.black54)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: _team1Id,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          hint: const Text('Choose Team 1'),
          items: teams
              .where((t) => t.id != _team2Id)
              .map((t) => DropdownMenuItem(value: t.id, child: Text(t.name)))
              .toList(),
          onChanged: (v) => setState(() => _team1Id = v),
        ),
        const SizedBox(height: 20),
        const Text('Team 2', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.black54)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: _team2Id,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          hint: const Text('Choose Team 2'),
          items: teams
              .where((t) => t.id != _team1Id)
              .map((t) => DropdownMenuItem(value: t.id, child: Text(t.name)))
              .toList(),
          onChanged: (v) => setState(() => _team2Id = v),
        ),
        const SizedBox(height: 28),
        _buildStartButton(
          onPressed: (_team1Id != null && _team2Id != null && _team1Id != _team2Id)
              ? () => _startGame(_team1Id!, _team2Id!)
              : null,
        ),
      ],
    );
  }

  Widget _buildCreateNew() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildBackHeader('Create Teams'),
        const SizedBox(height: 24),
        const Text('Team 1 Name', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.black54)),
        const SizedBox(height: 8),
        TextField(
          controller: _team1Controller,
          decoration: InputDecoration(
            hintText: 'e.g. Red Eagles',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          textCapitalization: TextCapitalization.words,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 20),
        const Text('Team 2 Name', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.black54)),
        const SizedBox(height: 8),
        TextField(
          controller: _team2Controller,
          decoration: InputDecoration(
            hintText: 'e.g. Blue Lions',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          textCapitalization: TextCapitalization.words,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 28),
        _buildStartButton(
          onPressed: (_team1Controller.text.trim().isNotEmpty && _team2Controller.text.trim().isNotEmpty)
              ? _startWithNewTeams
              : null,
        ),
      ],
    );
  }

  Widget _buildRandom() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildBackHeader('Random Teams'),
        const SizedBox(height: 36),
        Center(
          child: Column(
            children: [
              _buildRandomTeamBadge(_randomTeam1Name),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text('vs', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 22, color: Colors.black38)),
              ),
              _buildRandomTeamBadge(_randomTeam2Name),
            ],
          ),
        ),
        const SizedBox(height: 28),
        OutlinedButton.icon(
          onPressed: _generateRandomNames,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Re-roll Teams'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 12),
        _buildStartButton(onPressed: _startWithRandomTeams),
      ],
    );
  }

  Widget _buildRandomTeamBadge(String name) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8C84E), width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.casino_rounded, color: Color(0xFFB08B1E), size: 20),
          const SizedBox(width: 10),
          Text(name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18, color: Colors.black87)),
        ],
      ),
    );
  }
}
