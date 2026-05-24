import 'package:flutter/material.dart';
import '../models/game.dart';
import '../services/app_data_service.dart';
import '../state/app_state.dart';
import '../widgets/app_drawer.dart';
import '../widgets/tournaq_app_bar.dart';
import '../widgets/assign_dialog.dart';
import '../widgets/filter_bar.dart';
import '../widgets/game_tile.dart';
import '../widgets/quick_start_sheet.dart';
import '../widgets/scrollable_page.dart';
import 'score_page.dart';

class GamesPage extends StatefulWidget {
  final AppState appState;
  final Function(AppState) onAppStateChanged;

  const GamesPage({
    super.key,
    required this.appState,
    required this.onAppStateChanged,
  });

  @override
  State<GamesPage> createState() => _GamesPageState();
}

class _GamesPageState extends State<GamesPage> {
  late AppState _localState;
  final _searchCtrl = TextEditingController();
  final _playerFilter = <String>{};
  final _teamFilter = <String>{};
  final _tournamentFilter = <String>{};
  final _clubFilter = <String>{};
  final _statusFilter = <String>{};   // GameStatus.name
  final _sourceFilter = <String>{};   // GameSource.name

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

  void _updateState(AppState newState) {
    setState(() => _localState = newState);
    widget.onAppStateChanged(newState);
  }

  void _clearAll() {
    _searchCtrl.clear();
    setState(() {
      _playerFilter.clear();
      _teamFilter.clear();
      _tournamentFilter.clear();
      _clubFilter.clear();
      _statusFilter.clear();
      _sourceFilter.clear();
    });
  }

  List<Game> get _filteredGames {
    final q = _searchCtrl.text.toLowerCase();
    return _localState.games.where((game) {
      if (q.isNotEmpty) {
        final t1 = _localState.getTeamById(game.team1Id)?.name.toLowerCase() ?? '';
        final t2 = _localState.getTeamById(game.team2Id)?.name.toLowerCase() ?? '';
        if (!t1.contains(q) && !t2.contains(q)) return false;
      }
      if (_playerFilter.isNotEmpty) {
        final involvedTeams = _localState.teams
            .where((t) => t.id == game.team1Id || t.id == game.team2Id);
        final hasPlayer = involvedTeams.any((t) => t.userIds.any(_playerFilter.contains));
        if (!hasPlayer) return false;
      }
      if (_teamFilter.isNotEmpty &&
          !_teamFilter.contains(game.team1Id) &&
          !_teamFilter.contains(game.team2Id)) { return false; }
      if (_tournamentFilter.isNotEmpty) {
        if (game.tournamentId == null || !_tournamentFilter.contains(game.tournamentId)) return false;
      }
      if (_clubFilter.isNotEmpty) {
        final inClub = _localState.clubs
            .where((c) => _clubFilter.contains(c.id))
            .any((c) =>
                c.teamIds.contains(game.team1Id) ||
                c.teamIds.contains(game.team2Id) ||
                (game.tournamentId != null && c.tournamentIds.contains(game.tournamentId)));
        if (!inClub) return false;
      }
      if (_statusFilter.isNotEmpty && !_statusFilter.contains(game.status.name)) return false;
      if (_sourceFilter.isNotEmpty && !_sourceFilter.contains(game.source.name)) return false;
      return true;
    }).toList();
  }

  bool get _hasActiveFilters =>
      _searchCtrl.text.isNotEmpty ||
      _playerFilter.isNotEmpty ||
      _teamFilter.isNotEmpty ||
      _tournamentFilter.isNotEmpty ||
      _clubFilter.isNotEmpty ||
      _statusFilter.isNotEmpty ||
      _sourceFilter.isNotEmpty;

  Future<void> _deleteGame(String gameId) async {
    final game = _localState.getGameById(gameId);
    if (game == null || !mounted) return;
    final t1 = _localState.getTeamById(game.team1Id)?.name ?? 'Unknown';
    final t2 = _localState.getTeamById(game.team2Id)?.name ?? 'Unknown';
    final ok = await showConfirmDeleteDialog(context, '$t1 vs $t2');
    if (ok && mounted) {
      _updateState(AppDataService.deleteGame(_localState, gameId));
    }
  }

  Future<void> _showQuickStart() async {
    final result = await showModalBottomSheet<({AppState state, String gameId})>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => QuickStartSheet(appState: _localState),
    );

    if (result == null || !mounted) return;
    _updateState(result.state);
    if (!mounted) return;

    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => ScorePage(
        appState: result.state,
        onAppStateChanged: _updateState,
        gameId: result.gameId,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: AppDrawer(appState: _localState, onAppStateChanged: _updateState),
      appBar: const TournaQAppBar(title: 'Games'),
      body: ScrollablePage(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildQuickStartCard(),
            const SizedBox(height: 28),
            _buildGameBrowser(),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStartCard() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFB08B1E), Color(0xFFC9A030)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFB08B1E).withValues(alpha: 0.28),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [
            Icon(Icons.flash_on_rounded, color: Colors.white, size: 22),
            SizedBox(width: 8),
            Text('Quick Start', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
          ]),
          const SizedBox(height: 4),
          Text(
            'Jump into a game instantly — no tournament needed.',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 13),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _showQuickStart,
            icon: const Icon(Icons.play_arrow_rounded),
            label: const Text('Quick Start Game', style: TextStyle(fontWeight: FontWeight.w700)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFFB08B1E),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameBrowser() {
    final filtered = _filteredGames;
    final total = _localState.games.length;
    final countLabel = _hasActiveFilters ? '${filtered.length} of $total' : '$total';

    const statusItems = [
      (id: 'scheduled', name: 'Scheduled'),
      (id: 'inProgress', name: 'In Progress'),
      (id: 'completed', name: 'Completed'),
    ];
    const sourceItems = [
      (id: 'tournament', name: 'Tournament'),
      (id: 'quickLocal', name: 'Quick Game'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(children: [
          Icon(Icons.sports_score_rounded, size: 20, color: Color(0xFF6E7640)),
          SizedBox(width: 8),
          Text('Game Browser', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        ]),
        const SizedBox(height: 12),
        FilterBar(
          searchController: _searchCtrl,
          hintText: 'Search by team name...',
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
              label: 'Team',
              icon: Icons.group_rounded,
              items: _localState.teams.map((t) => (id: t.id, name: t.name)).toList(),
              selectedIds: _teamFilter,
              onToggle: (id, v) => setState(() { if (v) { _teamFilter.add(id); } else { _teamFilter.remove(id); } }),
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
            FilterGroup(
              label: 'Status',
              icon: Icons.pending_actions_rounded,
              items: statusItems.toList(),
              selectedIds: _statusFilter,
              onToggle: (id, v) => setState(() { if (v) { _statusFilter.add(id); } else { _statusFilter.remove(id); } }),
            ),
            FilterGroup(
              label: 'Source',
              icon: Icons.category_rounded,
              items: sourceItems.toList(),
              selectedIds: _sourceFilter,
              onToggle: (id, v) => setState(() { if (v) { _sourceFilter.add(id); } else { _sourceFilter.remove(id); } }),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          '$countLabel ${filtered.length == 1 ? 'game' : 'games'}',
          style: const TextStyle(fontSize: 13, color: Colors.black45, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        if (filtered.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Column(children: [
                const Icon(Icons.sports_score_rounded, size: 48, color: Colors.black26),
                const SizedBox(height: 12),
                Text(
                  total == 0 ? 'No games yet' : 'No games match the current filters',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: Colors.black45),
                ),
                const SizedBox(height: 4),
                Text(
                  total == 0
                      ? 'Use Quick Start above or create a tournament.'
                      : 'Try clearing some filters.',
                  style: const TextStyle(color: Colors.black38, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ]),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final game = filtered[index];
              return GameTile(
                game: game,
                appState: _localState,
                onScoreTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => ScorePage(
                    appState: _localState,
                    onAppStateChanged: _updateState,
                    gameId: game.id,
                  ),
                )),
                onDeleteTap: () => _deleteGame(game.id),
              );
            },
          ),
      ],
    );
  }
}
