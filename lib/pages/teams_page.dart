import 'package:flutter/material.dart';
import '../models/team.dart';
import '../services/app_data_service.dart';
import '../state/app_state.dart';
import '../widgets/app_drawer.dart';
import '../widgets/team_input_section.dart';

class TeamsPage extends StatefulWidget {
  final AppState appState;
  final Function(AppState) onAppStateChanged;

  const TeamsPage({
    super.key,
    required this.appState,
    required this.onAppStateChanged,
  });

  @override
  State<TeamsPage> createState() => _TeamsPageState();
}

class _TeamsPageState extends State<TeamsPage> {
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

  Future<void> _showAssignUserDialog(Team team) async {
    final availableUsers = _localState.users
        .where((user) => !user.teamIds.contains(team.id))
        .toList();

    if (availableUsers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All users are already assigned to this team.'),
        ),
      );
      return;
    }

    String? selectedUserId = availableUsers.first.id;
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Assign User'),
          content: DropdownButtonFormField<String>(
            initialValue: selectedUserId,
            items: availableUsers
                .map(
                  (user) =>
                      DropdownMenuItem(value: user.id, child: Text(user.name)),
                )
                .toList(),
            onChanged: (value) {
              selectedUserId = value;
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (selectedUserId != null) {
                  final newState = AppDataService.assignUserToTeam(
                    _localState,
                    userId: selectedUserId!,
                    teamId: team.id,
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

  Future<void> _showAssignTournamentDialog(Team team) async {
    final availableTournaments = _localState.tournaments
        .where((tournament) => !tournament.teamIds.contains(team.id))
        .toList();

    if (availableTournaments.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All tournaments already contain this team.'),
        ),
      );
      return;
    }

    String? selectedTournamentId = availableTournaments.first.id;
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Assign Tournament'),
          content: DropdownButtonFormField<String>(
            initialValue: selectedTournamentId,
            items: availableTournaments
                .map(
                  (tournament) => DropdownMenuItem(
                    value: tournament.id,
                    child: Text(tournament.name),
                  ),
                )
                .toList(),
            onChanged: (value) {
              selectedTournamentId = value;
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (selectedTournamentId != null) {
                  final newState = AppDataService.assignTeamToTournament(
                    _localState,
                    teamId: team.id,
                    tournamentId: selectedTournamentId!,
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
        title: const Text('Teams'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TeamInputSection(
                onTeamCreated: (teamName) {
                  final newState = AppDataService.createTeam(
                    _localState,
                    name: teamName,
                    scope: TeamScope.temporary,
                  );
                  _updateState(newState);
                },
              ),
              const SizedBox(height: 24),
              Text(
                'Teams (${_localState.teams.length})',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              if (_localState.teams.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text('No teams yet. Create one above!'),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _localState.teams.length,
                  itemBuilder: (context, index) {
                    final team = _localState.teams[index];
                    final teamUsers = _localState.getUsersForTeam(team.id);
                    final teamTournaments = _localState.getTeamTournaments(
                      team.id,
                    );
                    return ListTile(
                      title: Text(team.name),
                      subtitle: Text(
                        '${teamUsers.length} member(s) • ${teamTournaments.length} tournament(s)',
                      ),
                      trailing: PopupMenuButton<String>(
                        onSelected: (value) async {
                          if (value == 'assignUser') {
                            await _showAssignUserDialog(team);
                          } else if (value == 'assignTournament') {
                            await _showAssignTournamentDialog(team);
                          } else if (value == 'delete') {
                            final newState = AppDataService.deleteTeam(
                              _localState,
                              team.id,
                            );
                            _updateState(newState);
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'assignUser',
                            child: Text('Assign User'),
                          ),
                          const PopupMenuItem(
                            value: 'assignTournament',
                            child: Text('Assign Tournament'),
                          ),
                          const PopupMenuDivider(),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Text('Delete Team'),
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
