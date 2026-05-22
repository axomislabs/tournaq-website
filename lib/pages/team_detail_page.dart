import 'package:flutter/material.dart';

import '../models/team.dart';
import '../services/app_data_service.dart';
import '../state/app_state.dart';
import '../widgets/app_drawer.dart';
import '../widgets/scrollable_page.dart';
import 'tournament_detail_page.dart';
import 'user_detail_page.dart';

class TeamDetailPage extends StatefulWidget {
  final AppState appState;
  final Function(AppState) onAppStateChanged;
  final String teamId;

  const TeamDetailPage({
    super.key,
    required this.appState,
    required this.onAppStateChanged,
    required this.teamId,
  });

  @override
  State<TeamDetailPage> createState() => _TeamDetailPageState();
}

class _TeamDetailPageState extends State<TeamDetailPage> {
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

  Team? get _team => _localState.getTeamById(widget.teamId);

  Future<void> _showAssignUserDialog() async {
    final team = _team;
    if (team == null) return;

    final availableUsers = _localState.users
        .where((user) => !user.teamIds.contains(team.id))
        .toList();

    if (availableUsers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All users are already assigned.')),
      );
      return;
    }

    String? selectedUserId = availableUsers.first.id;

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Assign Player'),
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

  Future<void> _showAssignTournamentDialog() async {
    final team = _team;
    if (team == null) return;

    final availableTournaments = _localState.tournaments
        .where((tournament) => !tournament.teamIds.contains(team.id))
        .toList();

    if (availableTournaments.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All tournaments already have this team.'),
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

  Future<void> _removeUserFromTeam(String userId) async {
    final team = _team;
    if (team == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Player'),
        content: const Text('Remove this player from the team?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final newState = AppDataService.removeUserFromTeam(
        _localState,
        userId: userId,
        teamId: team.id,
      );
      _updateState(newState);
    }
  }

  Future<void> _removeTeamFromTournament(String tournamentId) async {
    final team = _team;
    if (team == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove from Tournament'),
        content: const Text('Remove this team from the tournament?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final newState = AppDataService.removeTeamFromTournament(
        _localState,
        teamId: team.id,
        tournamentId: tournamentId,
      );
      _updateState(newState);
    }
  }

  @override
  Widget build(BuildContext context) {
    final team = _team;
    if (team == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Team Details'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        ),
        body: const Center(child: Text('Team not found.')),
      );
    }

    final teamUsers = _localState.getUsersForTeam(team.id);
    final teamTournaments = _localState.getTeamTournaments(team.id);

    return Scaffold(
      drawer: AppDrawer(appState: _localState, onAppStateChanged: _updateState),
      appBar: AppBar(
        title: const Text('Team Details'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: ScrollablePage(
        padding: const EdgeInsets.all(16),
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
                      team.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('Scope: ${team.scope.name}'),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      children: [
                        ElevatedButton(
                          onPressed: _showAssignUserDialog,
                          child: const Text('Add Player'),
                        ),
                        ElevatedButton(
                          onPressed: _showAssignTournamentDialog,
                          child: const Text('Add to Tournament'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Members (${teamUsers.length})',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (teamUsers.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('No members yet.'),
                ),
              )
            else
              Column(
                children: teamUsers
                    .map(
                      (user) => Card(
                        child: ListTile(
                          title: Text(user.name),
                          subtitle: Text(user.email ?? 'No email'),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => UserDetailPage(
                                  appState: _localState,
                                  onAppStateChanged: _updateState,
                                  userId: user.id,
                                ),
                              ),
                            );
                          },
                          trailing: IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            onPressed: () => _removeUserFromTeam(user.id),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            const SizedBox(height: 20),
            Text(
              'Tournaments (${teamTournaments.length})',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (teamTournaments.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('Not in any tournaments yet.'),
                ),
              )
            else
              Column(
                children: teamTournaments
                    .map(
                      (tournament) => Card(
                        child: ListTile(
                          title: Text(tournament.name),
                          subtitle: Text(tournament.mode.displayName),
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
                          trailing: IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            onPressed: () =>
                                _removeTeamFromTournament(tournament.id),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }
}
