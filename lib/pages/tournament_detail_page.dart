import 'package:flutter/material.dart';

import '../models/game.dart';
import '../models/tournament.dart';
import '../models/tournament_mode.dart';
import '../models/team.dart';
import '../services/app_data_service.dart';
import '../services/tournament_logic_service.dart';
import '../state/app_state.dart';
import '../widgets/app_drawer.dart';
import '../widgets/game_tile.dart';
import 'score_page.dart';

class TournamentDetailPage extends StatefulWidget {
  final AppState appState;
  final Function(AppState) onAppStateChanged;
  final String tournamentId;

  const TournamentDetailPage({
    super.key,
    required this.appState,
    required this.onAppStateChanged,
    required this.tournamentId,
  });

  @override
  State<TournamentDetailPage> createState() => _TournamentDetailPageState();
}

class _TournamentDetailPageState extends State<TournamentDetailPage> {
  late AppState _localState;

  @override
  void initState() {
    super.initState();
    _localState = widget.appState;
  }

  void _updateState(AppState newState) {
    setState(() {
      _localState = newState;
    });
    widget.onAppStateChanged(newState);
  }

  Tournament? get _tournament =>
      _localState.getTournamentById(widget.tournamentId);

  List<Team> get _teams {
    final tournament = _tournament;
    if (tournament == null) return [];
    return _localState.getTeamsByIds(tournament.teamIds);
  }

  List<Game> get _games {
    final tournament = _tournament;
    if (tournament == null) return [];
    return _localState.getTournamentGames(tournament.id);
  }

  Future<void> _showAssignTeamDialog() async {
    final tournament = _tournament;
    if (tournament == null) return;

    final availableTeams = _localState.teams
        .where((team) => !tournament.teamIds.contains(team.id))
        .toList();
    if (availableTeams.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No available teams to assign.')),
      );
      return;
    }

    String? selectedTeamId = availableTeams.first.id;

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Assign Team'),
          content: DropdownButtonFormField<String>(
            initialValue: selectedTeamId,
            items: availableTeams
                .map(
                  (team) =>
                      DropdownMenuItem(value: team.id, child: Text(team.name)),
                )
                .toList(),
            onChanged: (value) {
              selectedTeamId = value;
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (selectedTeamId != null) {
                  final newState = AppDataService.assignTeamToTournament(
                    _localState,
                    teamId: selectedTeamId!,
                    tournamentId: tournament.id,
                  );
                  _updateState(newState);
                }
                Navigator.of(context).pop();
              },
              child: const Text('Assign'),
            ),
          ],
        );
      },
    );
  }

  void _generateGames() {
    final tournament = _tournament;
    if (tournament == null) return;
    if (tournament.teamIds.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add at least two teams before generating games.'),
        ),
      );
      return;
    }

    final newState = AppDataService.generateGamesForTournament(
      _localState,
      tournament,
    );
    _updateState(newState);
  }

  @override
  Widget build(BuildContext context) {
    final tournament = _tournament;
    if (tournament == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Tournament Details'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        ),
        body: const Center(child: Text('Tournament not found.')),
      );
    }

    final standings = tournament.mode.type == TournamentModeType.league
        ? TournamentLogicService.calculateStandings(_localState, tournament)
        : <TournamentStanding>[];

    return Scaffold(
      drawer: AppDrawer(appState: _localState, onAppStateChanged: _updateState),
      appBar: AppBar(
        title: Text(tournament.name),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                color: Theme.of(context).colorScheme.primaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tournament.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text('Mode: ${tournament.mode.displayName}'),
                      Text('Status: ${tournament.status.name}'),
                      Text('Teams: ${tournament.teamIds.length}'),
                      Text('Games: ${tournament.gameIds.length}'),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 12,
                        runSpacing: 8,
                        children: [
                          ElevatedButton(
                            onPressed: _showAssignTeamDialog,
                            child: const Text('Assign Team'),
                          ),
                          ElevatedButton(
                            onPressed: tournament.gameIds.isEmpty
                                ? _generateGames
                                : null,
                            child: const Text('Generate Games'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Teams (${_teams.length})',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              if (_teams.isEmpty)
                const Center(child: Text('No teams assigned yet.'))
              else
                Column(
                  children: _teams
                      .map(
                        (team) => Card(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          child: ListTile(
                            title: Text(team.name),
                            subtitle: Text(
                              '${_localState.getUsersForTeam(team.id).length} member(s)',
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              const SizedBox(height: 20),
              if (standings.isNotEmpty) ...[
                const Text(
                  'League Standings',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Card(
                  child: Column(
                    children: standings.map((standing) {
                      final team = _localState.getTeamById(standing.teamId);
                      return ListTile(
                        title: Text(team?.name ?? 'Unknown'),
                        subtitle: Text(
                          'W:${standing.wins} D:${standing.draws} L:${standing.losses} PF:${standing.pointsFor} PA:${standing.pointsAgainst}',
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 20),
              ],
              Text(
                'Games (${_games.length})',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              if (_games.isEmpty)
                const Center(child: Text('No games created yet.'))
              else
                Column(
                  children: _games
                      .map(
                        (game) => GameTile(
                          game: game,
                          appState: _localState,
                          onScoreTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => ScorePage(
                                  appState: _localState,
                                  onAppStateChanged: _updateState,
                                  gameId: game.id,
                                ),
                              ),
                            );
                          },
                        ),
                      )
                      .toList(),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
