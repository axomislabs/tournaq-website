import 'package:flutter/material.dart';

import '../models/club.dart';
import '../services/app_data_service.dart';
import '../state/app_state.dart';
import '../widgets/app_drawer.dart';
import '../widgets/tournaq_app_bar.dart';
import '../widgets/assign_dialog.dart';
import '../widgets/scrollable_page.dart';
import 'team_detail_page.dart';
import 'tournament_detail_page.dart';
import 'user_detail_page.dart';

class ClubDetailPage extends StatefulWidget {
  final AppState appState;
  final Function(AppState) onAppStateChanged;
  final String clubId;

  const ClubDetailPage({
    super.key,
    required this.appState,
    required this.onAppStateChanged,
    required this.clubId,
  });

  @override
  State<ClubDetailPage> createState() => _ClubDetailPageState();
}

class _ClubDetailPageState extends State<ClubDetailPage> {
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

  Club? get _club => _localState.getClubById(widget.clubId);

  // ── Players ──────────────────────────────────────────────────────────────

  Future<void> _assignPlayer() async {
    final club = _club;
    if (club == null) return;
    final items = _localState.users
        .where((u) => !club.playerIds.contains(u.id))
        .map((u) => (id: u.id, name: u.name))
        .toList();
    final selected = await showAssignDialog(
      context: context, title: 'Add Player', items: items,
      emptyMessage: 'All players are already in this club.',
    );
    if (selected != null && mounted) {
      _updateState(AppDataService.assignPlayerToClub(_localState, playerId: selected, clubId: widget.clubId));
    }
  }

  Future<void> _removePlayer(String playerId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Player'),
        content: const Text('Remove this player from the club?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Remove')),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      _updateState(AppDataService.removePlayerFromClub(_localState, playerId: playerId, clubId: widget.clubId));
    }
  }

  // ── Teams ─────────────────────────────────────────────────────────────────

  Future<void> _assignTeam() async {
    final club = _club;
    if (club == null) return;
    final items = _localState.teams
        .where((t) => !club.teamIds.contains(t.id))
        .map((t) => (id: t.id, name: t.name))
        .toList();
    final selected = await showAssignDialog(
      context: context, title: 'Add Team', items: items,
      emptyMessage: 'All teams are already in this club.',
    );
    if (selected != null && mounted) {
      _updateState(AppDataService.assignTeamToClub(_localState, teamId: selected, clubId: widget.clubId));
    }
  }

  Future<void> _removeTeam(String teamId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Team'),
        content: const Text('Remove this team from the club?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Remove')),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      _updateState(AppDataService.removeTeamFromClub(_localState, teamId: teamId, clubId: widget.clubId));
    }
  }

  // ── Tournaments ───────────────────────────────────────────────────────────

  Future<void> _assignTournament() async {
    final club = _club;
    if (club == null) return;
    final items = _localState.tournaments
        .where((t) => !club.tournamentIds.contains(t.id))
        .map((t) => (id: t.id, name: t.name))
        .toList();
    final selected = await showAssignDialog(
      context: context, title: 'Add Tournament', items: items,
      emptyMessage: 'All tournaments are already in this club.',
    );
    if (selected != null && mounted) {
      _updateState(AppDataService.assignTournamentToClub(_localState, tournamentId: selected, clubId: widget.clubId));
    }
  }

  Future<void> _removeTournament(String tournamentId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Tournament'),
        content: const Text('Remove this tournament from the club?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Remove')),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      _updateState(AppDataService.removeTournamentFromClub(_localState, tournamentId: tournamentId, clubId: widget.clubId));
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final club = _club;
    if (club == null) {
      return Scaffold(
        appBar: const TournaQAppBar(title: 'Club Details'),
        body: const Center(child: Text('Club not found.')),
      );
    }

    final players = _localState.users.where((u) => club.playerIds.contains(u.id)).toList();
    final teams = _localState.teams.where((t) => club.teamIds.contains(t.id)).toList();
    final tournaments = _localState.tournaments.where((t) => club.tournamentIds.contains(t.id)).toList();

    return Scaffold(
      drawer: AppDrawer(appState: _localState, onAppStateChanged: _updateState),
      appBar: const TournaQAppBar(title: 'Club Details'),
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
                    Text(club.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    Wrap(spacing: 12, runSpacing: 8, children: [
                      ElevatedButton.icon(
                        onPressed: _assignPlayer,
                        icon: const Icon(Icons.person_rounded, size: 16),
                        label: const Text('Add Player'),
                      ),
                      ElevatedButton.icon(
                        onPressed: _assignTeam,
                        icon: const Icon(Icons.group_rounded, size: 16),
                        label: const Text('Add Team'),
                      ),
                      ElevatedButton.icon(
                        onPressed: _assignTournament,
                        icon: const Icon(Icons.emoji_events_rounded, size: 16),
                        label: const Text('Add Tournament'),
                      ),
                    ]),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Players section
            Text('Players (${players.length})', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            if (players.isEmpty)
              const Center(child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('No players yet.', style: TextStyle(color: Colors.black45)),
              ))
            else
              ...players.map((u) => Card(
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: ListTile(
                  leading: const Icon(Icons.person_rounded),
                  title: Text(u.name),
                  subtitle: Text(u.email ?? ''),
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => UserDetailPage(appState: _localState, onAppStateChanged: _updateState, userId: u.id),
                  )),
                  trailing: IconButton(
                    icon: const Icon(Icons.remove_circle_outline),
                    onPressed: () => _removePlayer(u.id),
                  ),
                ),
              )),

            const SizedBox(height: 20),

            // Teams section
            Text('Teams (${teams.length})', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            if (teams.isEmpty)
              const Center(child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('No teams yet.', style: TextStyle(color: Colors.black45)),
              ))
            else
              ...teams.map((t) => Card(
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: ListTile(
                  leading: const Icon(Icons.group_rounded),
                  title: Text(t.name),
                  subtitle: Text(t.scope.name),
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => TeamDetailPage(appState: _localState, onAppStateChanged: _updateState, teamId: t.id),
                  )),
                  trailing: IconButton(
                    icon: const Icon(Icons.remove_circle_outline),
                    onPressed: () => _removeTeam(t.id),
                  ),
                ),
              )),

            const SizedBox(height: 20),

            // Tournaments section
            Text('Tournaments (${tournaments.length})', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            if (tournaments.isEmpty)
              const Center(child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('No tournaments yet.', style: TextStyle(color: Colors.black45)),
              ))
            else
              ...tournaments.map((t) => Card(
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: ListTile(
                  leading: const Icon(Icons.emoji_events_rounded),
                  title: Text(t.name),
                  subtitle: Text(t.mode.displayName),
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => TournamentDetailPage(appState: _localState, onAppStateChanged: _updateState, tournamentId: t.id),
                  )),
                  trailing: IconButton(
                    icon: const Icon(Icons.remove_circle_outline),
                    onPressed: () => _removeTournament(t.id),
                  ),
                ),
              )),
          ],
        ),
      ),
    );
  }
}
