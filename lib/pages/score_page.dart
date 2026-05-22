import 'package:flutter/material.dart';

import '../models/game.dart';
import '../models/team.dart';
import '../services/app_data_service.dart';
import '../state/app_state.dart';
import '../widgets/app_drawer.dart';

class ScorePage extends StatefulWidget {
  final AppState appState;
  final Function(AppState) onAppStateChanged;
  final String gameId;

  const ScorePage({
    super.key,
    required this.appState,
    required this.onAppStateChanged,
    required this.gameId,
  });

  @override
  State<ScorePage> createState() => _ScorePageState();
}

class _ScorePageState extends State<ScorePage> {
  late AppState _localState;
  late Game _game;
  late Team? _team1;
  late Team? _team2;
  late int _score1;
  late int _score2;
  late int _targetPoints;
  String? _winnerTeamId;

  @override
  void initState() {
    super.initState();
    _localState = widget.appState;
    _game = _localState.getGameById(widget.gameId)!;
    _team1 = _localState.getTeamById(_game.team1Id);
    _team2 = _localState.getTeamById(_game.team2Id);
    _score1 = _game.result?.score1 ?? 0;
    _score2 = _game.result?.score2 ?? 0;
    _targetPoints = _game.result?.targetPoints ?? 15;
    _winnerTeamId = _game.result?.winnerTeamId;
  }

  void _updateState(AppState newState) {
    setState(() {
      _localState = newState;
      _game = _localState.getGameById(widget.gameId)!;
    });
    widget.onAppStateChanged(newState);
  }

  void _updateScore1(int delta) {
    setState(() {
      _score1 = (_score1 + delta).clamp(0, 999);
    });
  }

  void _updateScore2(int delta) {
    setState(() {
      _score2 = (_score2 + delta).clamp(0, 999);
    });
  }

  void _saveScore() {
    final winnerTeamId = _score1 > _score2
        ? _game.team1Id
        : _score2 > _score1
        ? _game.team2Id
        : null;
    final newState = AppDataService.updateGameResult(
      _localState,
      gameId: _game.id,
      score1: _score1,
      score2: _score2,
      targetPoints: _targetPoints,
      winnerTeamId: _winnerTeamId ?? winnerTeamId,
    );
    _updateState(newState);
    Navigator.of(context).pop();
  }

  void _setTargetPoints(int value) {
    setState(() {
      _targetPoints = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final team1Name = _team1?.name ?? 'Team 1';
    final team2Name = _team2?.name ?? 'Team 2';
    return Scaffold(
      drawer: AppDrawer(appState: _localState, onAppStateChanged: _updateState),
      appBar: AppBar(
        title: const Text('Score Game'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '$team1Name vs $team2Name',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildScoreRow(team1Name, _score1, _updateScore1),
            const SizedBox(height: 12),
            _buildScoreRow(team2Name, _score2, _updateScore2),
            const SizedBox(height: 20),
            const Text('Target Points'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                for (final value in [11, 15, 21])
                  ChoiceChip(
                    label: Text('$value'),
                    selected: _targetPoints == value,
                    onSelected: (_) => _setTargetPoints(value),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            const Text('Winner'),
            const SizedBox(height: 8),
            DropdownButtonFormField<String?>(
              initialValue: _winnerTeamId,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('Auto select based on score'),
                ),
                if (_team1 != null)
                  DropdownMenuItem(value: _team1!.id, child: Text(team1Name)),
                if (_team2 != null)
                  DropdownMenuItem(value: _team2!.id, child: Text(team2Name)),
              ],
              onChanged: (value) {
                setState(() {
                  _winnerTeamId = value;
                });
              },
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: _saveScore,
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 14),
                child: Text('Save Score'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreRow(
    String label,
    int score,
    ValueChanged<int> updateScore,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  onPressed: () => updateScore(-1),
                ),
                Text(
                  score.toString(),
                  style: const TextStyle(
                    fontSize: 20,
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
