import 'package:flutter/material.dart';

import '../models/game.dart';
import '../models/team.dart';
import '../services/app_data_service.dart';
import '../state/app_state.dart';
import '../widgets/app_drawer.dart';
import '../widgets/tournaq_app_bar.dart';
import '../widgets/scrollable_page.dart';

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

  bool _shouldShowSideChangeReminder() {
    final total = _score1 + _score2;
    if (total == 0) return false;
    if (_targetPoints == 15) {
      return total % 5 == 0;
    } else if (_targetPoints == 21) {
      return total % 7 == 0;
    }
    return false;
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

  void _resetScores() {
    setState(() {
      _score1 = 0;
      _score2 = 0;
      _winnerTeamId = null;
    });
  }

  void _swapScores() {
    setState(() {
      final temp = _score1;
      _score1 = _score2;
      _score2 = temp;
    });
  }

  @override
  Widget build(BuildContext context) {
    final team1Name = _team1?.name ?? 'Team 1';
    final team2Name = _team2?.name ?? 'Team 2';
    final isTeam1Leading = _score1 > _score2;
    final isTeam2Leading = _score2 > _score1;
    final isTied = _score1 == _score2;

    return Scaffold(
      drawer: AppDrawer(appState: _localState, onAppStateChanged: _updateState),
      appBar: const TournaQAppBar(title: 'Score Game'),
      body: ScrollablePage(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '$team1Name vs $team2Name',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _buildScoreCounterCard(
                    teamName: team1Name,
                    score: _score1,
                    isLeading: isTeam1Leading,
                    onIncrement: () => _updateScore1(1),
                    onDecrement: () => _updateScore1(-1),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildScoreCounterCard(
                    teamName: team2Name,
                    score: _score2,
                    isLeading: isTeam2Leading,
                    onIncrement: () => _updateScore2(1),
                    onDecrement: () => _updateScore2(-1),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Status indicator
            Card(
              color: isTied
                  ? Colors.grey[300]
                  : isTeam1Leading
                  ? Theme.of(context).colorScheme.primaryContainer
                  : Theme.of(context).colorScheme.secondaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: Text(
                    isTied
                        ? 'Tied'
                        : isTeam1Leading
                        ? '$team1Name Leading'
                        : '$team2Name Leading',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            if (_shouldShowSideChangeReminder())
              Card(
                color: Colors.yellow[100],
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    'Side change reminder: total score is ${_score1 + _score2}.',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            const SizedBox(height: 12),
            // Quick action buttons
            Wrap(
              spacing: 12,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: _swapScores,
                  icon: const Icon(Icons.swap_horiz),
                  label: const Text('Swap'),
                ),
                ElevatedButton.icon(
                  onPressed: _resetScores,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reset'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 20),
            // Target points section
            const Text(
              'Target Points',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              alignment: WrapAlignment.center,
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
            // Winner section
            const Text(
              'Winner',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String?>(
              initialValue: _winnerTeamId,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
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
            const SizedBox(height: 24),
            // Save button
            ElevatedButton(
              onPressed: _saveScore,
              child: const Text('Save Score', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreCounterCard({
    required String teamName,
    required int score,
    required bool isLeading,
    required VoidCallback onIncrement,
    required VoidCallback onDecrement,
  }) {
    return Card(
      color: isLeading
          ? Theme.of(context).colorScheme.primaryContainer
          : Theme.of(context).colorScheme.surfaceContainer,
      elevation: isLeading ? 8 : 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              teamName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              score.toString(),
              style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton.filled(
                  icon: const Icon(Icons.remove),
                  onPressed: onDecrement,
                  tooltip: 'Decrease score',
                ),
                IconButton.filled(
                  icon: const Icon(Icons.add),
                  onPressed: onIncrement,
                  tooltip: 'Increase score',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
