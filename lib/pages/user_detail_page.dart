import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../services/app_data_service.dart';
import '../state/app_state.dart';
import '../widgets/app_drawer.dart';
import '../widgets/scrollable_page.dart';
import 'team_detail_page.dart';

class UserDetailPage extends StatefulWidget {
  final AppState appState;
  final Function(AppState) onAppStateChanged;
  final String userId;

  const UserDetailPage({
    super.key,
    required this.appState,
    required this.onAppStateChanged,
    required this.userId,
  });

  @override
  State<UserDetailPage> createState() => _UserDetailPageState();
}

class _UserDetailPageState extends State<UserDetailPage> {
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

  AppUser? get _user => _localState.getUserById(widget.userId);

  Future<void> _showAssignTeamDialog() async {
    final user = _user;
    if (user == null) return;

    final availableTeams = _localState.teams
        .where((team) => !user.teamIds.contains(team.id))
        .toList();

    if (availableTeams.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All teams are already assigned.')),
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
                  final newState = AppDataService.assignUserToTeam(
                    _localState,
                    userId: user.id,
                    teamId: selectedTeamId!,
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

  Future<void> _removeUserFromTeam(String teamId) async {
    final user = _user;
    if (user == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove from Team'),
        content: const Text('Remove this user from the team?'),
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
        userId: user.id,
        teamId: teamId,
      );
      _updateState(newState);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _user;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('User Details'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        ),
        body: const Center(child: Text('User not found.')),
      );
    }

    final userTeams = _localState.getTeamsByIds(user.teamIds);

    return Scaffold(
      drawer: AppDrawer(appState: _localState, onAppStateChanged: _updateState),
      appBar: AppBar(
        title: const Text('User Details'),
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
                      user.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (user.email != null) ...[
                      Text('Email: ${user.email}'),
                      const SizedBox(height: 8),
                    ],
                    if (user.role != null) ...[
                      Text('Role: ${user.role}'),
                      const SizedBox(height: 8),
                    ],
                    ElevatedButton(
                      onPressed: _showAssignTeamDialog,
                      child: const Text('Assign to Team'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Teams (${userTeams.length})',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (userTeams.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('Not assigned to any teams.'),
                ),
              )
            else
              Column(
                children: userTeams
                    .map(
                      (team) => Card(
                        child: ListTile(
                          title: Text(team.name),
                          subtitle: Text(team.scope.name),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => TeamDetailPage(
                                  appState: _localState,
                                  onAppStateChanged: _updateState,
                                  teamId: team.id,
                                ),
                              ),
                            );
                          },
                          trailing: IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            onPressed: () => _removeUserFromTeam(team.id),
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
