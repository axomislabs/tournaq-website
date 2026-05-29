import 'package:flutter/material.dart';

import '../models/tournament.dart';
import '../services/app_data_service.dart';
import '../services/rating_service.dart';
import '../state/app_state.dart';

class SingleGamesDialog extends StatefulWidget {
  final AppState appState;
  final Tournament tournament;
  final Function(AppState) onGameCreated;

  const SingleGamesDialog({
    super.key,
    required this.appState,
    required this.tournament,
    required this.onGameCreated,
  });

  @override
  State<SingleGamesDialog> createState() => _SingleGamesDialogState();
}

class _SingleGamesDialogState extends State<SingleGamesDialog> {
  String? _selectedTeam1Id;
  String? _selectedTeam2Id;

  @override
  void initState() {
    super.initState();
    if (widget.tournament.teamIds.isNotEmpty) {
      _selectedTeam1Id = widget.tournament.teamIds.first;
    }
  }

  List<String> get _availableTeams => widget.tournament.teamIds;

  List<String> get _team2Options {
    if (_selectedTeam1Id == null) return _availableTeams;
    return _availableTeams.where((id) => id != _selectedTeam1Id).toList();
  }

  Future<void> _createGame() async {
    if (_selectedTeam1Id == null || _selectedTeam2Id == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select both teams')));
      return;
    }

    if (_selectedTeam1Id == _selectedTeam2Id) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Teams must be different')));
      return;
    }

    final existingGames = widget.appState.getTournamentGames(
      widget.tournament.id,
    );
    final nextRound = existingGames.isEmpty
        ? 1
        : existingGames.map((g) => g.round).reduce((a, b) => a > b ? a : b) + 1;

    final newState = AppDataService.createGame(
      widget.appState,
      tournamentId: widget.tournament.id,
      team1Id: _selectedTeam1Id!,
      team2Id: _selectedTeam2Id!,
      round: nextRound,
    );

    widget.onGameCreated(newState);
    await RatingService.onGameCreated(context);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create Game'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Select Team 1'),
            const SizedBox(height: 12),
            DropdownButtonFormField<String?>(
              initialValue: _selectedTeam1Id,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              items: _availableTeams.map((teamId) {
                final team = widget.appState.getTeamById(teamId);
                return DropdownMenuItem(
                  value: teamId,
                  child: Text(team?.name ?? 'Unknown Team'),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedTeam1Id = value;
                  // Reset team2 if it's the same as team1
                  if (_selectedTeam2Id == value) {
                    _selectedTeam2Id = null;
                  }
                });
              },
            ),
            const SizedBox(height: 20),
            const Text('Select Team 2'),
            const SizedBox(height: 12),
            DropdownButtonFormField<String?>(
              initialValue: _selectedTeam2Id,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              items: _team2Options.map((teamId) {
                final team = widget.appState.getTeamById(teamId);
                return DropdownMenuItem(
                  value: teamId,
                  child: Text(team?.name ?? 'Unknown Team'),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedTeam2Id = value;
                });
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(onPressed: _createGame, child: const Text('Create')),
      ],
    );
  }
}
