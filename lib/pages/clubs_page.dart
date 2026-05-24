import 'package:flutter/material.dart';
// ignore: unused_import
import '../models/club.dart';
import '../services/app_data_service.dart';
import '../state/app_state.dart';
import '../widgets/app_drawer.dart';
import '../widgets/assign_dialog.dart';
import '../widgets/create_club_sheet.dart';
import '../widgets/filter_bar.dart';
import '../widgets/scrollable_page.dart';
import 'club_detail_page.dart';

class ClubsPage extends StatefulWidget {
  final AppState appState;
  final Function(AppState) onAppStateChanged;
  const ClubsPage({super.key, required this.appState, required this.onAppStateChanged});
  @override
  State<ClubsPage> createState() => _ClubsPageState();
}

class _ClubsPageState extends State<ClubsPage> {
  late AppState _localState;
  final _searchCtrl = TextEditingController();
  final _playerFilter = <String>{};
  final _teamFilter = <String>{};
  final _tournamentFilter = <String>{};

  @override
  void initState() {
    super.initState();
    _localState = widget.appState;
    _searchCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _updateState(AppState s) {
    setState(() => _localState = s);
    widget.onAppStateChanged(s);
  }

  Future<void> _showCreateSheet() async {
    final result = await showModalBottomSheet<AppState>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CreateClubSheet(appState: _localState),
    );
    if (result != null && mounted) _updateState(result);
  }

  // ── Actions ────────────────────────────────────────────────────────────────

  Future<void> _assignPlayer(String clubId) async {
    final club = _localState.getClubById(clubId);
    if (club == null) return;
    final items = _localState.users
        .where((u) => !club.playerIds.contains(u.id))
        .map((u) => (id: u.id, name: u.name))
        .toList();
    final selected = await showAssignDialog(
      context: context, title: 'Assign Player', items: items,
      emptyMessage: 'All players are already in this club.',
    );
    if (selected != null && mounted) {
      _updateState(AppDataService.assignPlayerToClub(_localState, playerId: selected, clubId: clubId));
    }
  }

  Future<void> _assignTeam(String clubId) async {
    final club = _localState.getClubById(clubId);
    if (club == null) return;
    final items = _localState.teams
        .where((t) => !club.teamIds.contains(t.id))
        .map((t) => (id: t.id, name: t.name))
        .toList();
    final selected = await showAssignDialog(
      context: context, title: 'Assign Team', items: items,
      emptyMessage: 'All teams are already in this club.',
    );
    if (selected != null && mounted) {
      _updateState(AppDataService.assignTeamToClub(_localState, teamId: selected, clubId: clubId));
    }
  }

  Future<void> _assignTournament(String clubId) async {
    final club = _localState.getClubById(clubId);
    if (club == null) return;
    final items = _localState.tournaments
        .where((t) => !club.tournamentIds.contains(t.id))
        .map((t) => (id: t.id, name: t.name))
        .toList();
    final selected = await showAssignDialog(
      context: context, title: 'Assign Tournament', items: items,
      emptyMessage: 'All tournaments are already in this club.',
    );
    if (selected != null && mounted) {
      _updateState(AppDataService.assignTournamentToClub(_localState, tournamentId: selected, clubId: clubId));
    }
  }

  Future<void> _deleteClub(String clubId) async {
    final club = _localState.getClubById(clubId);
    if (club == null) return;
    final ok = await showConfirmDeleteDialog(context, club.name);
    if (ok && mounted) _updateState(AppDataService.deleteClub(_localState, clubId));
  }

  // ── Filter ─────────────────────────────────────────────────────────────────

  void _clearAll() {
    _searchCtrl.clear();
    setState(() {
      _playerFilter.clear();
      _teamFilter.clear();
      _tournamentFilter.clear();
    });
  }

  bool get _hasActiveFilters =>
      _searchCtrl.text.isNotEmpty ||
      _playerFilter.isNotEmpty ||
      _teamFilter.isNotEmpty ||
      _tournamentFilter.isNotEmpty;

  List<Club> get _filteredClubs {
    final q = _searchCtrl.text.toLowerCase();
    return _localState.clubs.where((club) {
      if (q.isNotEmpty && !club.name.toLowerCase().contains(q)) return false;
      if (_playerFilter.isNotEmpty && !_playerFilter.any(club.playerIds.contains)) return false;
      if (_teamFilter.isNotEmpty && !_teamFilter.any(club.teamIds.contains)) return false;
      if (_tournamentFilter.isNotEmpty && !_tournamentFilter.any(club.tournamentIds.contains)) return false;
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredClubs;
    final total = _localState.clubs.length;
    final countLabel = _hasActiveFilters ? '${filtered.length} of $total' : '$total';

    return Scaffold(
      drawer: AppDrawer(appState: _localState, onAppStateChanged: _updateState),
      appBar: AppBar(title: const Text('Clubs'), backgroundColor: Theme.of(context).colorScheme.inversePrimary),
      body: ScrollablePage(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          ElevatedButton.icon(
            onPressed: _showCreateSheet,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Create Club', style: TextStyle(fontWeight: FontWeight.w700)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6E7640),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 20),
          FilterBar(
            searchController: _searchCtrl,
            hintText: 'Search clubs...',
            onClearAll: _clearAll,
            groups: [
              FilterGroup(
                label: 'Player', icon: Icons.person_rounded,
                items: _localState.users.map((u) => (id: u.id, name: u.name)).toList(),
                selectedIds: _playerFilter,
                onToggle: (id, v) => setState(() { if (v) { _playerFilter.add(id); } else { _playerFilter.remove(id); } }),
              ),
              FilterGroup(
                label: 'Team', icon: Icons.group_rounded,
                items: _localState.teams.map((t) => (id: t.id, name: t.name)).toList(),
                selectedIds: _teamFilter,
                onToggle: (id, v) => setState(() { if (v) { _teamFilter.add(id); } else { _teamFilter.remove(id); } }),
              ),
              FilterGroup(
                label: 'Tournament', icon: Icons.emoji_events_rounded,
                items: _localState.tournaments.map((t) => (id: t.id, name: t.name)).toList(),
                selectedIds: _tournamentFilter,
                onToggle: (id, v) => setState(() { if (v) { _tournamentFilter.add(id); } else { _tournamentFilter.remove(id); } }),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text('Clubs ($countLabel)', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          if (total == 0)
            const Center(child: Padding(
              padding: EdgeInsets.all(24),
              child: Text('No clubs yet.', style: TextStyle(color: Colors.black45)),
            ))
          else if (filtered.isEmpty)
            const Center(child: Padding(
              padding: EdgeInsets.all(24),
              child: Text('No clubs match the current filters.', style: TextStyle(color: Colors.black45)),
            ))
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final club = filtered[index];
                return ListTile(
                  title: Text(club.name),
                  subtitle: Text('${club.playerIds.length} player(s) • ${club.teamIds.length} team(s) • ${club.tournamentIds.length} tournament(s)'),
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => ClubDetailPage(appState: _localState, onAppStateChanged: _updateState, clubId: club.id),
                  )),
                  trailing: PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, size: 20),
                    onSelected: (value) {
                      switch (value) {
                        case 'assign_player': _assignPlayer(club.id);
                        case 'assign_team': _assignTeam(club.id);
                        case 'assign_tournament': _assignTournament(club.id);
                        case 'delete': _deleteClub(club.id);
                      }
                    },
                    itemBuilder: (_) => [
                      actionMenuItem('assign_player', Icons.person_rounded, 'Assign Player'),
                      actionMenuItem('assign_team', Icons.group_rounded, 'Assign Team'),
                      actionMenuItem('assign_tournament', Icons.emoji_events_rounded, 'Assign Tournament'),
                      const PopupMenuDivider(),
                      actionMenuItem('delete', Icons.delete_outline, 'Delete', destructive: true),
                    ],
                  ),
                );
              },
            ),
        ]),
      ),
    );
  }
}
