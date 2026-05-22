import 'package:flutter/material.dart';
import '../models/tournament.dart';
import '../services/app_data_service.dart';
import '../state/app_state.dart';
import '../widgets/app_drawer.dart';
import '../widgets/tournament_input_section.dart';
import 'tournament_detail_page.dart';

class TournamentsPage extends StatefulWidget {
  final AppState appState;
  final Function(AppState) onAppStateChanged;

  const TournamentsPage({
    super.key,
    required this.appState,
    required this.onAppStateChanged,
  });

  @override
  State<TournamentsPage> createState() => _TournamentsPageState();
}

class _TournamentsPageState extends State<TournamentsPage> {
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

  Future<void> _showAssignTeamDialog(Tournament tournament) async {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: AppDrawer(appState: _localState, onAppStateChanged: _updateState),
      appBar: AppBar(
        title: const Text('Tournaments'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TournamentInputSection(
                onTournamentCreated: (name, mode) {
                  final newState = AppDataService.createTournament(
                    _localState,
                    name: name,
                    mode: mode,
                  );
                  _updateState(newState);
                },
              ),
              const SizedBox(height: 24),
              Text(
                'Tournaments (${_localState.tournaments.length})',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              if (_localState.tournaments.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text('No tournaments yet. Create one above!'),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _localState.tournaments.length,
                  itemBuilder: (context, index) {
                    final tournament = _localState.tournaments[index];
                    final teamCount = tournament.teamIds.length;
                    final gameCount = tournament.gameIds.length;
                    return ListTile(
                      title: Text(tournament.name),
                      subtitle: Text(
                        '${tournament.mode.displayName} • $teamCount teams • $gameCount games',
                      ),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => TournamentDetailPage(
                              appState: _localState,
                              onAppStateChanged: _updateState,
                              tournamentId: tournament.id,
                            ),
                          ),
                        );
                      },
                      trailing: PopupMenuButton<String>(
                        onSelected: (value) async {
                          if (value == 'assignTeam') {
                            await _showAssignTeamDialog(tournament);
                          } else if (value == 'delete') {
                            final newState = AppDataService.deleteTournament(
                              _localState,
                              tournament.id,
                            );
                            _updateState(newState);
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'assignTeam',
                            child: Text('Assign Team'),
                          ),
                          const PopupMenuDivider(),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Text('Delete Tournament'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}
