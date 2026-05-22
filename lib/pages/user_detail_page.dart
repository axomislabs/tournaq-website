import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../services/app_data_service.dart';
import '../state/app_state.dart';
import '../widgets/app_drawer.dart';
import '../widgets/assign_dialog.dart';
import '../widgets/scrollable_page.dart';
import 'club_detail_page.dart';
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
    setState(() => _localState = newState);
    widget.onAppStateChanged(newState);
  }

  AppUser? get _user => _localState.getUserById(widget.userId);

  // ── Team ─────────────────────────────────────────────────────────────────

  Future<void> _assignTeam() async {
    final user = _user;
    if (user == null) return;
    final items = _localState.teams
        .where((t) => !user.teamIds.contains(t.id))
        .map((t) => (id: t.id, name: t.name))
        .toList();
    final selected = await showAssignDialog(
      context: context, title: 'Assign to Team', items: items,
      emptyMessage: 'Player is already in all teams.',
    );
    if (selected != null && mounted) {
      _updateState(AppDataService.assignUserToTeam(_localState, userId: widget.userId, teamId: selected));
    }
  }

  Future<void> _removeFromTeam(String teamId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove from Team'),
        content: const Text('Remove this player from the team?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Remove')),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      _updateState(AppDataService.removeUserFromTeam(_localState, userId: widget.userId, teamId: teamId));
    }
  }

  // ── Club ──────────────────────────────────────────────────────────────────

  Future<void> _assignClub() async {
    final items = _localState.clubs
        .where((c) => !c.playerIds.contains(widget.userId))
        .map((c) => (id: c.id, name: c.name))
        .toList();
    final selected = await showAssignDialog(
      context: context, title: 'Assign to Club', items: items,
      emptyMessage: 'Player is already in all clubs.',
    );
    if (selected != null && mounted) {
      _updateState(AppDataService.assignPlayerToClub(_localState, playerId: widget.userId, clubId: selected));
    }
  }

  Future<void> _removeFromClub(String clubId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove from Club'),
        content: const Text('Remove this player from the club?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Remove')),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      _updateState(AppDataService.removePlayerFromClub(_localState, playerId: widget.userId, clubId: clubId));
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _user;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Player Details'), backgroundColor: Theme.of(context).colorScheme.inversePrimary),
        body: const Center(child: Text('Player not found.')),
      );
    }

    final userTeams = _localState.getTeamsByIds(user.teamIds);
    final userClubs = _localState.getPlayerClubs(user.id);

    return Scaffold(
      drawer: AppDrawer(appState: _localState, onAppStateChanged: _updateState),
      appBar: AppBar(
        title: const Text('Player Details'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: ScrollablePage(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header card
            Card(
              color: Theme.of(context).colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    if (user.email != null) ...[
                      const SizedBox(height: 6),
                      Text('Email: ${user.email}', style: const TextStyle(color: Colors.black54)),
                    ],
                    if (user.role != null) ...[
                      const SizedBox(height: 4),
                      Text('Role: ${user.role}', style: const TextStyle(color: Colors.black54)),
                    ],
                    const SizedBox(height: 16),
                    Wrap(spacing: 10, runSpacing: 8, children: [
                      ElevatedButton.icon(
                        onPressed: _assignTeam,
                        icon: const Icon(Icons.group_rounded, size: 16),
                        label: const Text('Assign to Team'),
                      ),
                      ElevatedButton.icon(
                        onPressed: _assignClub,
                        icon: const Icon(Icons.home_rounded, size: 16),
                        label: const Text('Assign to Club'),
                      ),
                    ]),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Teams section
            Text('Teams (${userTeams.length})', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            if (userTeams.isEmpty)
              const Center(child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('Not assigned to any teams.', style: TextStyle(color: Colors.black45)),
              ))
            else
              ...userTeams.map((team) => Card(
                child: ListTile(
                  leading: const Icon(Icons.group_rounded),
                  title: Text(team.name),
                  subtitle: Text(team.scope.name),
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => TeamDetailPage(appState: _localState, onAppStateChanged: _updateState, teamId: team.id),
                  )),
                  trailing: IconButton(
                    icon: const Icon(Icons.remove_circle_outline),
                    onPressed: () => _removeFromTeam(team.id),
                  ),
                ),
              )),

            const SizedBox(height: 20),

            // Clubs section
            Text('Clubs (${userClubs.length})', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            if (userClubs.isEmpty)
              const Center(child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('Not assigned to any clubs.', style: TextStyle(color: Colors.black45)),
              ))
            else
              ...userClubs.map((club) => Card(
                child: ListTile(
                  leading: const Icon(Icons.home_rounded),
                  title: Text(club.name),
                  subtitle: Text('${club.playerIds.length} player(s) • ${club.teamIds.length} team(s)'),
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => ClubDetailPage(appState: _localState, onAppStateChanged: _updateState, clubId: club.id),
                  )),
                  trailing: IconButton(
                    icon: const Icon(Icons.remove_circle_outline),
                    onPressed: () => _removeFromClub(club.id),
                  ),
                ),
              )),
          ],
        ),
      ),
    );
  }
}
