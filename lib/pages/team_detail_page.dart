import 'package:flutter/material.dart';

import '../models/team.dart';
import '../services/app_data_service.dart';
import '../state/app_state.dart';
import '../widgets/app_drawer.dart';
import '../widgets/assign_dialog.dart';
import '../widgets/scrollable_page.dart';
import 'club_detail_page.dart';
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
    setState(() => _localState = newState);
    widget.onAppStateChanged(newState);
  }

  Team? get _team => _localState.getTeamById(widget.teamId);

  // ── Player ────────────────────────────────────────────────────────────────

  Future<void> _assignPlayer() async {
    final team = _team;
    if (team == null) return;
    final items = _localState.users
        .where((u) => !u.teamIds.contains(team.id))
        .map((u) => (id: u.id, name: u.name))
        .toList();
    final selected = await showAssignDialog(
      context: context, title: 'Assign Player', items: items,
      emptyMessage: 'All players are already in this team.',
    );
    if (selected != null && mounted) {
      _updateState(AppDataService.assignUserToTeam(_localState, userId: selected, teamId: widget.teamId));
    }
  }

  Future<void> _removePlayer(String userId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Player'),
        content: const Text('Remove this player from the team?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Remove')),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      _updateState(AppDataService.removeUserFromTeam(_localState, userId: userId, teamId: widget.teamId));
    }
  }

  // ── Tournament ────────────────────────────────────────────────────────────

  Future<void> _assignTournament() async {
    final team = _team;
    if (team == null) return;
    final items = _localState.tournaments
        .where((t) => !t.teamIds.contains(team.id))
        .map((t) => (id: t.id, name: t.name))
        .toList();
    final selected = await showAssignDialog(
      context: context, title: 'Assign to Tournament', items: items,
      emptyMessage: 'Team is already in all tournaments.',
    );
    if (selected != null && mounted) {
      _updateState(AppDataService.assignTeamToTournament(_localState, teamId: widget.teamId, tournamentId: selected));
    }
  }

  Future<void> _removeFromTournament(String tournamentId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove from Tournament'),
        content: const Text('Remove this team from the tournament?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Remove')),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      _updateState(AppDataService.removeTeamFromTournament(_localState, teamId: widget.teamId, tournamentId: tournamentId));
    }
  }

  // ── Club ──────────────────────────────────────────────────────────────────

  Future<void> _assignClub() async {
    final items = _localState.clubs
        .where((c) => !c.teamIds.contains(widget.teamId))
        .map((c) => (id: c.id, name: c.name))
        .toList();
    final selected = await showAssignDialog(
      context: context, title: 'Assign to Club', items: items,
      emptyMessage: 'Team is already in all clubs.',
    );
    if (selected != null && mounted) {
      _updateState(AppDataService.assignTeamToClub(_localState, teamId: widget.teamId, clubId: selected));
    }
  }

  Future<void> _removeFromClub(String clubId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove from Club'),
        content: const Text('Remove this team from the club?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Remove')),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      _updateState(AppDataService.removeTeamFromClub(_localState, teamId: widget.teamId, clubId: clubId));
    }
  }

  @override
  Widget build(BuildContext context) {
    final team = _team;
    if (team == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Team Details'), backgroundColor: Theme.of(context).colorScheme.inversePrimary),
        body: const Center(child: Text('Team not found.')),
      );
    }

    final teamUsers = _localState.getUsersForTeam(team.id);
    final teamTournaments = _localState.getTeamTournaments(team.id);
    final teamClubs = _localState.getTeamClubs(team.id);

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
            // Header card
            Card(
              color: Theme.of(context).colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(team.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('Scope: ${team.scope.name}', style: const TextStyle(color: Colors.black54)),
                    const SizedBox(height: 16),
                    Wrap(spacing: 10, runSpacing: 8, children: [
                      ElevatedButton.icon(
                        onPressed: _assignPlayer,
                        icon: const Icon(Icons.person_rounded, size: 16),
                        label: const Text('Add Player'),
                      ),
                      ElevatedButton.icon(
                        onPressed: _assignTournament,
                        icon: const Icon(Icons.emoji_events_rounded, size: 16),
                        label: const Text('Add to Tournament'),
                      ),
                      ElevatedButton.icon(
                        onPressed: _assignClub,
                        icon: const Icon(Icons.home_rounded, size: 16),
                        label: const Text('Add to Club'),
                      ),
                    ]),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Players section
            Text('Players (${teamUsers.length})', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            if (teamUsers.isEmpty)
              const Center(child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('No players yet.', style: TextStyle(color: Colors.black45)),
              ))
            else
              ...teamUsers.map((user) => Card(
                child: ListTile(
                  leading: const Icon(Icons.person_rounded),
                  title: Text(user.name),
                  subtitle: Text(user.email ?? ''),
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => UserDetailPage(appState: _localState, onAppStateChanged: _updateState, userId: user.id),
                  )),
                  trailing: IconButton(
                    icon: const Icon(Icons.remove_circle_outline),
                    onPressed: () => _removePlayer(user.id),
                  ),
                ),
              )),

            const SizedBox(height: 20),

            // Tournaments section
            Text('Tournaments (${teamTournaments.length})', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            if (teamTournaments.isEmpty)
              const Center(child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('Not in any tournaments yet.', style: TextStyle(color: Colors.black45)),
              ))
            else
              ...teamTournaments.map((tournament) => Card(
                child: ListTile(
                  leading: const Icon(Icons.emoji_events_rounded),
                  title: Text(tournament.name),
                  subtitle: Text(tournament.mode.displayName),
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => TournamentDetailPage(appState: _localState, onAppStateChanged: _updateState, tournamentId: tournament.id),
                  )),
                  trailing: IconButton(
                    icon: const Icon(Icons.remove_circle_outline),
                    onPressed: () => _removeFromTournament(tournament.id),
                  ),
                ),
              )),

            const SizedBox(height: 20),

            // Clubs section
            Text('Clubs (${teamClubs.length})', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            if (teamClubs.isEmpty)
              const Center(child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('Not in any clubs yet.', style: TextStyle(color: Colors.black45)),
              ))
            else
              ...teamClubs.map((club) => Card(
                child: ListTile(
                  leading: const Icon(Icons.home_rounded),
                  title: Text(club.name),
                  subtitle: Text('${club.playerIds.length} player(s) • ${club.tournamentIds.length} tournament(s)'),
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
