import 'dart:math';

import 'package:flutter/material.dart';
import '../models/team.dart';
import '../services/app_data_service.dart';
import '../state/app_state.dart';
import '../widgets/app_drawer.dart';
import '../widgets/create_team_sheet.dart';
import '../widgets/filter_bar.dart';
import '../widgets/scrollable_page.dart';
import 'team_detail_page.dart';

class TeamsPage extends StatefulWidget {
  final AppState appState;
  final Function(AppState) onAppStateChanged;
  const TeamsPage({super.key, required this.appState, required this.onAppStateChanged});
  @override
  State<TeamsPage> createState() => _TeamsPageState();
}

class _TeamsPageState extends State<TeamsPage> {
  late AppState _localState;
  final _rng = Random();
  final _searchCtrl = TextEditingController();
  final _playerFilter = <String>{};
  final _tournamentFilter = <String>{};
  final _clubFilter = <String>{};

  static const _prefixes = ['Falcon','Phoenix','Lion','Tiger','Eagle','Storm','Dragon','Viper','Thunder','Raven','Comet','Shadow','Blaze','Orbit','Nova'];
  static const _suffixes = ['Squad','Team','Crew','Force','Unit','Pack','Alliance','Legion','Clan','Dynasty'];

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
      '${_prefixes[_rng.nextInt(_prefixes.length)]} ${_suffixes[_rng.nextInt(_suffixes.length)]}';

  void _generateRandom(int count) {
    var s = _localState;
    for (var i = 0; i < count; i++) {
      s = AppDataService.createTeam(s, name: _randomName(), scope: TeamScope.temporary);
    }
    _updateState(s);
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Generated $count random teams.')));
  }

  Future<void> _showCreateSheet() async {
    final result = await showModalBottomSheet<AppState>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CreateTeamSheet(appState: _localState),
    );
    if (result != null && mounted) _updateState(result);
  }

  void _clearAll() {
    _searchCtrl.clear();
    setState(() {
      _playerFilter.clear();
      _tournamentFilter.clear();
      _clubFilter.clear();
    });
  }

  List<Team> get _filteredTeams {
    final q = _searchCtrl.text.toLowerCase();
    return _localState.teams.where((team) {
      if (q.isNotEmpty && !team.name.toLowerCase().contains(q)) return false;
      if (_playerFilter.isNotEmpty && !team.userIds.any(_playerFilter.contains)) return false;
      if (_tournamentFilter.isNotEmpty && !team.tournamentIds.any(_tournamentFilter.contains)) return false;
      if (_clubFilter.isNotEmpty) {
        final inClub = _localState.clubs
            .where((c) => _clubFilter.contains(c.id))
            .any((c) => c.teamIds.contains(team.id));
        if (!inClub) return false;
      }
      return true;
    }).toList();
  }

  bool get _hasActiveFilters =>
      _searchCtrl.text.isNotEmpty ||
      _playerFilter.isNotEmpty ||
      _tournamentFilter.isNotEmpty ||
      _clubFilter.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredTeams;
    final total = _localState.teams.length;
    final countLabel = _hasActiveFilters ? '${filtered.length} of $total' : '$total';

    return Scaffold(
      drawer: AppDrawer(appState: _localState, onAppStateChanged: _updateState),
      appBar: AppBar(title: const Text('Teams'), backgroundColor: Theme.of(context).colorScheme.inversePrimary),
      body: ScrollablePage(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          ElevatedButton.icon(
            onPressed: _showCreateSheet,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Create Team', style: TextStyle(fontWeight: FontWeight.w700)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD9A520),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => _generateRandom(10),
            icon: const Icon(Icons.shuffle_rounded),
            label: const Text('Generate 10 Random Teams'),
            style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          ),
          const SizedBox(height: 20),
          FilterBar(
            searchController: _searchCtrl,
            hintText: 'Search teams...',
            onClearAll: _clearAll,
            groups: [
              FilterGroup(
                label: 'Player',
                icon: Icons.person_rounded,
                items: _localState.users.map((u) => (id: u.id, name: u.name)).toList(),
                selectedIds: _playerFilter,
                onToggle: (id, v) => setState(() { if (v) { _playerFilter.add(id); } else { _playerFilter.remove(id); } }),
              ),
              FilterGroup(
                label: 'Tournament',
                icon: Icons.emoji_events_rounded,
                items: _localState.tournaments.map((t) => (id: t.id, name: t.name)).toList(),
                selectedIds: _tournamentFilter,
                onToggle: (id, v) => setState(() { if (v) { _tournamentFilter.add(id); } else { _tournamentFilter.remove(id); } }),
              ),
              FilterGroup(
                label: 'Club',
                icon: Icons.home_rounded,
                items: _localState.clubs.map((c) => (id: c.id, name: c.name)).toList(),
                selectedIds: _clubFilter,
                onToggle: (id, v) => setState(() { if (v) { _clubFilter.add(id); } else { _clubFilter.remove(id); } }),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text('Teams ($countLabel)', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          if (total == 0)
            const Center(child: Padding(
              padding: EdgeInsets.all(24),
              child: Text('No teams yet.', style: TextStyle(color: Colors.black45)),
            ))
          else if (filtered.isEmpty)
            const Center(child: Padding(
              padding: EdgeInsets.all(24),
              child: Text('No teams match the current filters.', style: TextStyle(color: Colors.black45)),
            ))
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final team = filtered[index];
                final memberCount = _localState.getUsersForTeam(team.id).length;
                final tournamentCount = _localState.getTeamTournaments(team.id).length;
                return ListTile(
                  title: Text(team.name),
                  subtitle: Text('$memberCount member(s) • $tournamentCount tournament(s)'),
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => TeamDetailPage(appState: _localState, onAppStateChanged: _updateState, teamId: team.id),
                  )),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'delete') { _updateState(AppDataService.deleteTeam(_localState, team.id)); }
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(value: 'delete', child: Text('Delete Team')),
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
