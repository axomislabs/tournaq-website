import 'package:flutter/material.dart';

import '../models/team.dart';
import '../services/app_data_service.dart';
import '../state/app_state.dart';
import '../widgets/app_drawer.dart';
import '../widgets/tournaq_app_bar.dart';
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

  Future<void> _editPlayers() async {
    final team = _team;
    if (team == null) return;
    final users = _localState.getUsersForTeam(team.id);
    final p1Name = users.isNotEmpty ? users[0].name : 'Player 1 ${team.name}';
    final p2Name = users.length > 1 ? users[1].name : 'Player 2 ${team.name}';

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditPlayersSheet(
        teamName: team.name,
        initialP1: p1Name,
        initialP2: p2Name,
        onSave: (p1, p2) {
          final ns = AppDataService.updateTeamPlayers(
            _localState,
            teamId: widget.teamId,
            player1Name: p1,
            player2Name: p2,
          );
          _updateState(ns);
        },
      ),
    );
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
        appBar: const TournaQAppBar(title: 'Team Details'),
        body: const Center(child: Text('Team not found.')),
      );
    }

    final teamUsers = _localState.getUsersForTeam(team.id);
    final teamTournaments = _localState.getTeamTournaments(team.id);
    final teamClubs = _localState.getTeamClubs(team.id);

    return Scaffold(
      drawer: AppDrawer(appState: _localState, onAppStateChanged: _updateState),
      appBar: const TournaQAppBar(title: 'Team Details'),
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
                        onPressed: _editPlayers,
                        icon: const Icon(Icons.edit_rounded, size: 16),
                        label: const Text('Edit Players'),
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
                margin: const EdgeInsets.symmetric(vertical: 4),
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
                margin: const EdgeInsets.symmetric(vertical: 4),
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
                margin: const EdgeInsets.symmetric(vertical: 4),
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

class _EditPlayersSheet extends StatefulWidget {
  final String teamName;
  final String initialP1;
  final String initialP2;
  final void Function(String p1, String p2) onSave;

  const _EditPlayersSheet({
    required this.teamName,
    required this.initialP1,
    required this.initialP2,
    required this.onSave,
  });

  @override
  State<_EditPlayersSheet> createState() => _EditPlayersSheetState();
}

class _EditPlayersSheetState extends State<_EditPlayersSheet> {
  late final TextEditingController _p1;
  late final TextEditingController _p2;

  @override
  void initState() {
    super.initState();
    _p1 = TextEditingController(text: widget.initialP1);
    _p2 = TextEditingController(text: widget.initialP2);
  }

  @override
  void dispose() {
    _p1.dispose();
    _p2.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            Text(widget.teamName,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            const Text('Edit player names',
                style: TextStyle(color: Colors.black45, fontSize: 13)),
            const SizedBox(height: 20),
            _field('Player 1', _p1),
            const SizedBox(height: 14),
            _field('Player 2', _p2),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  final n1 = _p1.text.trim().isEmpty ? widget.initialP1 : _p1.text.trim();
                  final n2 = _p2.text.trim().isEmpty ? widget.initialP2 : _p2.text.trim();
                  widget.onSave(n1, n2);
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFB08B1E),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Save Players',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController ctrl) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.black54)),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
          textCapitalization: TextCapitalization.words,
        ),
      ],
    );
  }
}
