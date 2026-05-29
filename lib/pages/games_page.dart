import 'package:flutter/material.dart';
import '../models/game.dart';
import '../services/app_data_service.dart';
import '../services/rating_service.dart';
import '../state/app_state.dart';
import '../widgets/app_drawer.dart';
import '../widgets/tournaq_app_bar.dart';
import '../widgets/assign_dialog.dart';
import '../widgets/game_tile.dart';
import '../widgets/quick_start_sheet.dart';
import 'score_page.dart';
import 'scorecard_splash_page.dart';

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

  List<Game> get _filteredGames {
    final q = _searchCtrl.text.toLowerCase();
    return _localState.games.reversed.where((game) {
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

  Future<void> _deleteHistoryData() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete All Match History?'),
        content: const Text('This will permanently delete all local game records. This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      _updateState(AppDataService.clearLocalHistoryData(_localState));
    }
  }

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
    await RatingService.onGameCreated(context);
    if (!mounted) return;

    _navigateToScorecard(result.state, result.gameId);
  }

  void _navigateToScorecard(AppState state, String gameId) {
    final game = state.getGameById(gameId);
    final page = (game != null && !game.hasShownScorecardIntro)
        ? ScorecardSplashPage(appState: state, onAppStateChanged: _updateState, gameId: gameId)
        : ScorePage(appState: state, onAppStateChanged: _updateState, gameId: gameId);
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredGames;
    final total = _localState.games.length;

    return Scaffold(
      drawer: AppDrawer(appState: _localState, onAppStateChanged: _updateState),
      appBar: const TournaQAppBar(title: 'Games'),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Fixed: Quick Start card
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: _buildQuickStartCard(),
          ),
          const SizedBox(height: 20),
          // Fixed: Match History header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(children: [
              const Icon(Icons.sports_score_rounded, size: 20, color: Color(0xFF6E7640)),
              const SizedBox(width: 8),
              const Text('Match History', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const Spacer(),
              if (total > 0)
                TextButton.icon(
                  onPressed: _deleteHistoryData,
                  icon: const Icon(Icons.delete_outline, size: 16),
                  label: const Text('Delete History', style: TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(foregroundColor: Colors.red.shade400),
                ),
            ]),
          ),
          const SizedBox(height: 8),
          // Scrollable: games list
          Expanded(
            child: filtered.isEmpty
                ? _buildEmptyState(total)
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final game = filtered[index];
                      return GameTile(
                        game: game,
                        appState: _localState,
                        onScoreTap: () => _navigateToScorecard(_localState, game.id),
                        onDeleteTap: () => _deleteGame(game.id),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(int total) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
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
            Text('Quick Start Game', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
          ]),
          const SizedBox(height: 2),
          Text(
            'Beach Volleyball Match',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.95), fontSize: 13, fontWeight: FontWeight.w600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
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

}
