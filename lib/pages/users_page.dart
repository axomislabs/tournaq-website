import 'dart:math';

import 'package:flutter/material.dart';
import '../models/app_user.dart';
import '../services/app_data_service.dart';
import '../state/app_state.dart';
import '../widgets/app_drawer.dart';
import '../widgets/tournaq_app_bar.dart';
import '../widgets/assign_dialog.dart';
import '../widgets/create_player_sheet.dart';
import '../widgets/filter_bar.dart';
import '../widgets/scrollable_page.dart';
import 'user_detail_page.dart';

class UsersPage extends StatefulWidget {
  final AppState appState;
  final Function(AppState) onAppStateChanged;
  const UsersPage({super.key, required this.appState, required this.onAppStateChanged});
  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  late AppState _localState;
  final _rng = Random();
  final _searchCtrl = TextEditingController();
  final _teamFilter = <String>{};
  final _tournamentFilter = <String>{};
  final _clubFilter = <String>{};

  static const _firstNames = ['Alex','Charlie','Jordan','Taylor','Morgan','Casey','Jamie','Avery','Riley','Rowan','Skyler','Quinn','Parker','Drew','Reese'];
  static const _lastNames = ['Harper','Brooks','Cole','Reed','Blake','Carter','Lane','Hayes','Hart','West','Fox','Gray','Shaw','Mason','Finn'];

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

  String _randomName() =>
      '${_firstNames[_rng.nextInt(_firstNames.length)]} ${_lastNames[_rng.nextInt(_lastNames.length)]}';

  void _generateRandom(int count) {
    var s = _localState;
    for (var i = 0; i < count; i++) {
      s = AppDataService.createUser(s, name: _randomName());
    }
    _updateState(s);
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Generated $count random players.')));
  }

  Future<void> _showCreateSheet() async {
    final result = await showModalBottomSheet<AppState>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CreatePlayerSheet(appState: _localState),
    );
    if (result != null && mounted) _updateState(result);
  }

  // ── Actions ────────────────────────────────────────────────────────────────

  Future<void> _assignTeam(String userId) async {
    final user = _localState.getUserById(userId);
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
      _updateState(AppDataService.assignUserToTeam(_localState, userId: userId, teamId: selected));
    }
  }

  Future<void> _assignClub(String userId) async {
    final items = _localState.clubs
        .where((c) => !c.playerIds.contains(userId))
        .map((c) => (id: c.id, name: c.name))
        .toList();
    final selected = await showAssignDialog(
      context: context, title: 'Assign to Club', items: items,
      emptyMessage: 'Player is already in all clubs.',
    );
    if (selected != null && mounted) {
      _updateState(AppDataService.assignPlayerToClub(_localState, playerId: userId, clubId: selected));
    }
  }

  Future<void> _deletePlayer(String userId) async {
    final user = _localState.getUserById(userId);
    if (user == null) return;
    final ok = await showConfirmDeleteDialog(context, user.name);
    if (ok && mounted) _updateState(AppDataService.deleteUser(_localState, userId));
  }

  // ── Filter ─────────────────────────────────────────────────────────────────

  void _clearAll() {
    _searchCtrl.clear();
    setState(() {
      _teamFilter.clear();
      _tournamentFilter.clear();
      _clubFilter.clear();
    });
  }

  List<AppUser> get _filteredUsers {
    final q = _searchCtrl.text.toLowerCase();
    return _localState.users.where((user) {
      if (q.isNotEmpty && !user.name.toLowerCase().contains(q)) return false;
      if (_teamFilter.isNotEmpty && !user.teamIds.any(_teamFilter.contains)) return false;
      if (_tournamentFilter.isNotEmpty) {
        final inTournament = _localState.tournaments
            .where((t) => _tournamentFilter.contains(t.id))
            .any((t) => user.teamIds.any(t.teamIds.contains));
        if (!inTournament) return false;
      }
      if (_clubFilter.isNotEmpty) {
        final inClub = _localState.clubs
            .where((c) => _clubFilter.contains(c.id))
            .any((c) => c.playerIds.contains(user.id));
        if (!inClub) return false;
      }
      return true;
    }).toList();
  }

  bool get _hasActiveFilters =>
      _searchCtrl.text.isNotEmpty ||
      _teamFilter.isNotEmpty ||
      _tournamentFilter.isNotEmpty ||
      _clubFilter.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredUsers;
    final total = _localState.users.length;
    final countLabel = _hasActiveFilters ? '${filtered.length} of $total' : '$total';

    return Scaffold(
      drawer: AppDrawer(appState: _localState, onAppStateChanged: _updateState),
      appBar: const TournaQAppBar(title: 'Players'),
      body: ScrollablePage(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          ElevatedButton.icon(
            onPressed: _showCreateSheet,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Create Player', style: TextStyle(fontWeight: FontWeight.w700)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6E7640),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => _generateRandom(10),
            icon: const Icon(Icons.shuffle_rounded),
            label: const Text('Generate 10 Random Players'),
            style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          ),
          const SizedBox(height: 20),
          FilterBar(
            searchController: _searchCtrl,
            hintText: 'Search players...',
            onClearAll: _clearAll,
            groups: [
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
              FilterGroup(
                label: 'Club', icon: Icons.home_rounded,
                items: _localState.clubs.map((c) => (id: c.id, name: c.name)).toList(),
                selectedIds: _clubFilter,
                onToggle: (id, v) => setState(() { if (v) { _clubFilter.add(id); } else { _clubFilter.remove(id); } }),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text('Players ($countLabel)', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          if (total == 0)
            const Center(child: Padding(
              padding: EdgeInsets.all(24),
              child: Text('No players yet.', style: TextStyle(color: Colors.black45)),
            ))
          else if (filtered.isEmpty)
            const Center(child: Padding(
              padding: EdgeInsets.all(24),
              child: Text('No players match the current filters.', style: TextStyle(color: Colors.black45)),
            ))
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final user = filtered[index];
                return ListTile(
                  title: Text(user.name),
                  subtitle: Text('${user.teamIds.length} team(s)'),
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => UserDetailPage(appState: _localState, onAppStateChanged: _updateState, userId: user.id),
                  )),
                  trailing: PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, size: 20),
                    onSelected: (value) {
                      switch (value) {
                        case 'assign_team': _assignTeam(user.id);
                        case 'assign_club': _assignClub(user.id);
                        case 'delete': _deletePlayer(user.id);
                      }
                    },
                    itemBuilder: (_) => [
                      actionMenuItem('assign_team', Icons.group_rounded, 'Assign to Team'),
                      actionMenuItem('assign_club', Icons.home_rounded, 'Assign to Club'),
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
