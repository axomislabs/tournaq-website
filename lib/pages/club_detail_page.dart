import 'package:flutter/material.dart';

import '../models/club.dart';
import '../services/app_data_service.dart';
import '../state/app_state.dart';
import '../widgets/app_drawer.dart';
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
    setState(() {
      _localState = newState;
    });
    widget.onAppStateChanged(newState);
  }

  Club? get _club => _localState.getClubById(widget.clubId);

  // ── Players ──────────────────────────────────────────────────────────────

  Future<void> _showAssignPlayerDialog() async {
    final club = _club;
    if (club == null) return;

    final available = _localState.users
        .where((u) => !club.playerIds.contains(u.id))
        .toList();

    if (available.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All players are already in this club.')),
      );
      return;
    }

    String? selectedId = available.first.id;

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Player'),
        content: DropdownButtonFormField<String>(
          initialValue: selectedId,
          items: available
              .map((u) => DropdownMenuItem(value: u.id, child: Text(u.name)))
              .toList(),
          onChanged: (v) => selectedId = v,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (selectedId != null) {
                _updateState(AppDataService.assignPlayerToClub(
                  _localState,
                  playerId: selectedId!,
                  clubId: widget.clubId,
                ));
              }
              Navigator.of(context).pop();
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _removePlayer(String playerId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Player'),
        content: const Text('Remove this player from the club?'),
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
      _updateState(AppDataService.removePlayerFromClub(
        _localState,
        playerId: playerId,
        clubId: widget.clubId,
      ));
    }
  }

  // ── Teams ─────────────────────────────────────────────────────────────────

  Future<void> _showAssignTeamDialog() async {
    final club = _club;
    if (club == null) return;

    final available = _localState.teams
        .where((t) => !club.teamIds.contains(t.id))
        .toList();

    if (available.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All teams are already in this club.')),
      );
      return;
    }

    String? selectedId = available.first.id;

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Team'),
        content: DropdownButtonFormField<String>(
          initialValue: selectedId,
          items: available
              .map((t) => DropdownMenuItem(value: t.id, child: Text(t.name)))
              .toList(),
          onChanged: (v) => selectedId = v,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (selectedId != null) {
                _updateState(AppDataService.assignTeamToClub(
                  _localState,
                  teamId: selectedId!,
                  clubId: widget.clubId,
                ));
              }
              Navigator.of(context).pop();
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _removeTeam(String teamId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Team'),
        content: const Text('Remove this team from the club?'),
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
      _updateState(AppDataService.removeTeamFromClub(
        _localState,
        teamId: teamId,
        clubId: widget.clubId,
      ));
    }
  }

  // ── Tournaments ───────────────────────────────────────────────────────────

  Future<void> _showAssignTournamentDialog() async {
    final club = _club;
    if (club == null) return;

    final available = _localState.tournaments
        .where((t) => !club.tournamentIds.contains(t.id))
        .toList();

    if (available.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All tournaments are already in this club.'),
        ),
      );
      return;
    }

    String? selectedId = available.first.id;

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Tournament'),
        content: DropdownButtonFormField<String>(
          initialValue: selectedId,
          items: available
              .map((t) => DropdownMenuItem(value: t.id, child: Text(t.name)))
              .toList(),
          onChanged: (v) => selectedId = v,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (selectedId != null) {
                _updateState(AppDataService.assignTournamentToClub(
                  _localState,
                  tournamentId: selectedId!,
                  clubId: widget.clubId,
                ));
              }
              Navigator.of(context).pop();
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _removeTournament(String tournamentId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Tournament'),
        content: const Text('Remove this tournament from the club?'),
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
      _updateState(AppDataService.removeTournamentFromClub(
        _localState,
        tournamentId: tournamentId,
        clubId: widget.clubId,
      ));
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final club = _club;
    if (club == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Club Details'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        ),
        body: const Center(child: Text('Club not found.')),
      );
    }

    final players = _localState.users
        .where((u) => club.playerIds.contains(u.id))
        .toList();
    final teams = _localState.teams
        .where((t) => club.teamIds.contains(t.id))
        .toList();
    final tournaments = _localState.tournaments
        .where((t) => club.tournamentIds.contains(t.id))
        .toList();

    return Scaffold(
      drawer: AppDrawer(appState: _localState, onAppStateChanged: _updateState),
      appBar: AppBar(
        title: const Text('Club Details'),
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
                    Text(
                      club.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      children: [
                        ElevatedButton(
                          onPressed: _showAssignPlayerDialog,
                          child: const Text('Add Player'),
                        ),
                        ElevatedButton(
                          onPressed: _showAssignTeamDialog,
                          child: const Text('Add Team'),
                        ),
                        ElevatedButton(
                          onPressed: _showAssignTournamentDialog,
                          child: const Text('Add Tournament'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Players section
            Text(
              'Players (${players.length})',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (players.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('No players yet.'),
                ),
              )
            else
              ...players.map(
                (u) => Card(
                  child: ListTile(
                    leading: const Icon(Icons.person_rounded),
                    title: Text(u.name),
                    subtitle: Text(u.email ?? ''),
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => UserDetailPage(
                        appState: _localState,
                        onAppStateChanged: _updateState,
                        userId: u.id,
                      ),
                    )),
                    trailing: IconButton(
                      icon: const Icon(Icons.remove_circle_outline),
                      onPressed: () => _removePlayer(u.id),
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 20),

            // Teams section
            Text(
              'Teams (${teams.length})',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (teams.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('No teams yet.'),
                ),
              )
            else
              ...teams.map(
                (t) => Card(
                  child: ListTile(
                    leading: const Icon(Icons.group_rounded),
                    title: Text(t.name),
                    subtitle: Text(t.scope.name),
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => TeamDetailPage(
                        appState: _localState,
                        onAppStateChanged: _updateState,
                        teamId: t.id,
                      ),
                    )),
                    trailing: IconButton(
                      icon: const Icon(Icons.remove_circle_outline),
                      onPressed: () => _removeTeam(t.id),
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 20),

            // Tournaments section
            Text(
              'Tournaments (${tournaments.length})',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (tournaments.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('No tournaments yet.'),
                ),
              )
            else
              ...tournaments.map(
                (t) => Card(
                  child: ListTile(
                    leading: const Icon(Icons.emoji_events_rounded),
                    title: Text(t.name),
                    subtitle: Text(t.mode.displayName),
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => TournamentDetailPage(
                        appState: _localState,
                        onAppStateChanged: _updateState,
                        tournamentId: t.id,
                      ),
                    )),
                    trailing: IconButton(
                      icon: const Icon(Icons.remove_circle_outline),
                      onPressed: () => _removeTournament(t.id),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
