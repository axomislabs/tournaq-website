import 'dart:math';

import 'package:flutter/material.dart';
import '../app/app_colors.dart';
import '../models/king_of_the_court_tournament.dart';
import '../services/king_of_the_court_storage_service.dart';
import '../services/scramble_service.dart';
import '../models/player.dart';
import '../widgets/scramble_timer_widget.dart';
import '../widgets/sheet_helpers.dart';
import '../widgets/tournaq_app_bar.dart';
import 'king_of_the_court_history_page.dart';

const _kGold            = AppColors.goldDark;
const _kGoldLight       = AppColors.goldCream;
const _kGoldCardBg      = AppColors.goldCardBg;
const _kGoldCardLeading = AppColors.goldCardLeading;
const _kOlive           = AppColors.olive;
const _kOliveLight      = AppColors.oliveLight;

class KingOfTheCourtScoreboardPage extends StatefulWidget {
  final KingOfTheCourtTournament tournament;
  final List<Player> existingPlayers;
  final void Function(KingOfTheCourtTournament) onChanged;

  const KingOfTheCourtScoreboardPage({
    super.key,
    required this.tournament,
    required this.existingPlayers,
    required this.onChanged,
  });

  @override
  State<KingOfTheCourtScoreboardPage> createState() =>
      _KotcScoreboardState();
}

class _KotcScoreboardState extends State<KingOfTheCourtScoreboardPage> {
  late KingOfTheCourtTournament _t;

  // ── Scoring ───────────────────────────────────────────────────────────────
  List<KotcPlayer> _teamPlayers      = [];
  List<KotcPlayer> _pendingSelection = [];
  List<KotcPlayer> _pool             = [];
  int              _currentPoints    = 0;

  // ── Automated assignment ──────────────────────────────────────────────────
  List<List<KotcPlayer>> _candidates     = [];
  int                    _candidateIndex = 0;
  List<KotcPlayer>       _challengerTeam = [];

  // ── Admin (automatedAllPlay only) ─────────────────────────────────────────
  String? _adminPlayerId;
  String? _nextAdminPlayerId;

  // (undo state is derived from _t.games — no local storage needed)

  // ── Session timer ─────────────────────────────────────────────────────────
  final _sessionTimerKey = GlobalKey<ScrambleTimerWidgetState>();
  bool _timerRunning = false;

  // ── Game stopwatch (stint elapsed — info display, synced with session) ────
  final _gameWatch = Stopwatch();

  // ── Derived ───────────────────────────────────────────────────────────────
  bool get _hasTeam       => _teamPlayers.isNotEmpty;
  bool get _canAddPlayer  => _pendingSelection.length < _t.playersPerTeam;
  bool get _canStart      => _pendingSelection.length == _t.playersPerTeam;
  bool get _strikeEnabled => _t.strikePoints > 0;
  bool get _strikeReached =>
      _strikeEnabled && _currentPoints >= _t.strikePoints;
  bool get _isCompleted =>
      _t.status == KotcTournamentStatus.completed;
  bool get _isAllPlay  => _t.assignmentMode == KotcAssignmentMode.automatedAllPlay;
  bool get _isAutoMode => _t.assignmentMode == KotcAssignmentMode.automated || _isAllPlay;
  // Undo is available when there is a recorded game to restore.
  // In automated/allPlay mode the new team starts immediately, so undo is also
  // available while a team is on court (the current unrecorded game is discarded).
  bool get _canUndo => _t.games.isNotEmpty &&
      (!_hasTeam || _isAutoMode);

  // Pool available for suggestions — excludes current admin in automatedAllPlay.
  List<KotcPlayer> get _activePool => _isAllPlay && _adminPlayerId != null
      ? _pool.where((p) => p.id != _adminPlayerId).toList()
      : _pool;

  @override
  void initState() {
    super.initState();
    _t    = widget.tournament;
    _pool = List.from(_t.players);
    if (_isAllPlay && _t.players.isNotEmpty) {
      _adminPlayerId = _t.players[Random().nextInt(_t.players.length)].id;
    }
    _initSuggestion();
  }

  @override
  void dispose() {
    _gameWatch.stop();
    super.dispose();
  }

  // ── Persist helper ────────────────────────────────────────────────────────

  void _persist() {
    KingOfTheCourtStorageService.save(_t);
    widget.onChanged(_t);
  }

  // ── Timer control ─────────────────────────────────────────────────────────

  void _startOrRestart() {
    if (_isCompleted) return;
    _sessionTimerKey.currentState?.restart();
    _sessionTimerKey.currentState?.start();
    _gameWatch.reset();
    if (_hasTeam) _gameWatch.start();
    setState(() => _timerRunning = true);
  }

  void _pauseTimer() {
    _sessionTimerKey.currentState?.pause();
    _gameWatch.stop();
    setState(() => _timerRunning = false);
  }

  Future<void> _onSessionFinished() async {
    _gameWatch.stop();
    setState(() => _timerRunning = false);
    if (!mounted) return;

    final end = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Colors.white,
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
        contentPadding: const EdgeInsets.fromLTRB(24, 14, 24, 0),
        actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        title: Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
                color: _kGoldLight,
                borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.timer_off_rounded,
                color: _kGold, size: 20),
          ),
          const SizedBox(width: 12),
          const Text('Time is up',
              style: TextStyle(
                  fontSize: 17, fontWeight: FontWeight.w700)),
        ]),
        content: const Text(
          'The session timer has ended. Complete the tournament now?',
          style: TextStyle(fontSize: 14, height: 1.5),
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _kOlive,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Complete Tournament',
                  style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Continue scoring',
                  style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
    if (end == true && mounted) _completeTournament();
  }

  // ── Team selection ────────────────────────────────────────────────────────

  void _toggleSelection(KotcPlayer p) {
    setState(() {
      if (_pendingSelection.any((s) => s.id == p.id)) {
        _pendingSelection.removeWhere((s) => s.id == p.id);
        _pool.add(p);
      } else if (_canAddPlayer) {
        _pendingSelection.add(p);
        _pool.removeWhere((s) => s.id == p.id);
      }
    });
  }

  void _confirmTeam() {
    if (!_canStart) return;
    _startTeam(_pendingSelection);
  }

  // ── Automated assignment ──────────────────────────────────────────────────

  void _initSuggestion() {
    if (!_isAutoMode) return;
    _candidates     = _computeSuggestions(fromPool: _activePool);
    _candidateIndex = 0;
  }

  // Checks whether the admin would appear in Up Next using the full pool (admin included).
  // Only runs once Challengers are established. Sets or clears _nextAdminPlayerId accordingly.
  void _updateAdminHandoffCheck() {
    if (!_isAllPlay || _adminPlayerId == null) return;
    if (_challengerTeam.length != _t.playersPerTeam) return;

    final upNextPool = _pool
        .where((p) => !_challengerTeam.any((c) => c.id == p.id))
        .toList();
    final fullUpNext = _computeSuggestions(fromPool: upNextPool);
    final adminNeeded = fullUpNext.isNotEmpty &&
        fullUpNext.first.any((p) => p.id == _adminPlayerId);

    if (adminNeeded) {
      if (_nextAdminPlayerId == null && _teamPlayers.isNotEmpty) {
        setState(() => _nextAdminPlayerId =
            _teamPlayers[Random().nextInt(_teamPlayers.length)].id);
      }
    } else if (_nextAdminPlayerId != null) {
      setState(() => _nextAdminPlayerId = null);
    }
  }

  // Two-step compute: Challengers from active pool, then Up Next from pool minus Challengers.
  // No-op outside auto modes or when no team is playing.
  void _recomputeChallenger() {
    if (!_isAutoMode || !_hasTeam) return;
    final active          = _activePool;
    final challengerCands = _computeSuggestions(fromPool: active);
    final newChallenger   = challengerCands.isNotEmpty ? challengerCands.first : <KotcPlayer>[];
    final upNextPool      = active
        .where((p) => !newChallenger.any((c) => c.id == p.id))
        .toList();
    _candidates     = _computeSuggestions(fromPool: upNextPool);
    _candidateIndex = 0;
    setState(() => _challengerTeam = newChallenger);
    _updateAdminHandoffCheck();
  }

  // Updates Up Next candidates after the challenger team is already known.
  void _recomputeUpNext() {
    if (!_isAutoMode) return;
    final upNextPool = _activePool
        .where((p) => !_challengerTeam.any((c) => c.id == p.id))
        .toList();
    setState(() {
      _candidates     = _computeSuggestions(fromPool: upNextPool);
      _candidateIndex = 0;
    });
    _updateAdminHandoffCheck();
  }

  void _reroll() {
    if (_candidates.length <= 1) return;
    setState(() =>
        _candidateIndex = (_candidateIndex + 1) % _candidates.length);
  }

  List<KotcPlayer> get _currentSuggestion =>
      _candidates.isEmpty ? [] : _candidates[_candidateIndex];

  void _confirmSuggestedTeam() {
    final suggested = _currentSuggestion;
    if (suggested.length != _t.playersPerTeam) return;
    _startTeam(suggested);
    _recomputeChallenger();
  }

  void _startTeam(List<KotcPlayer> players) {
    final s = _sessionTimerKey.currentState;
    if (s != null && s.timerState == ScrambleTimerState.idle) {
      s.start();
      setState(() => _timerRunning = true);
    }
    _gameWatch
      ..reset()
      ..start();
    setState(() {
      _teamPlayers      = List.from(players);
      _pool             = _t.players
          .where((p) => !players.any((s) => s.id == p.id))
          .toList();
      _pendingSelection = [];
      _currentPoints    = 0;
      _challengerTeam   = [];
    });
  }

  List<List<KotcPlayer>> _computeSuggestions({List<KotcPlayer>? fromPool}) {
    final pool = fromPool ?? _pool;
    final n    = _t.playersPerTeam;
    if (pool.length < n) return [];

    final pairCounts = <String, int>{};
    for (final game in _t.games) {
      final ids = game.playerIds;
      for (var i = 0; i < ids.length; i++) {
        for (var j = i + 1; j < ids.length; j++) {
          final key = ([ids[i], ids[j]]..sort()).join(':');
          pairCounts[key] = (pairCounts[key] ?? 0) + 1;
        }
      }
    }

    final lastPlayed = <String, int>{};
    for (var i = 0; i < _t.games.length; i++) {
      for (final pid in _t.games[i].playerIds) {
        lastPlayed[pid] = i;
      }
    }
    final totalGames = _t.games.length;

    final combos = _kotcCombinations(pool, n);
    combos.sort((a, b) {
      final aPairs = _kotcPairScore(a, pairCounts);
      final bPairs = _kotcPairScore(b, pairCounts);
      if (aPairs != bPairs) return aPairs.compareTo(bPairs);
      return _kotcWaitScore(b, lastPlayed, totalGames)
          .compareTo(_kotcWaitScore(a, lastPlayed, totalGames));
    });
    return combos;
  }

  int _kotcPairScore(List<KotcPlayer> team, Map<String, int> counts) {
    var score = 0;
    for (var i = 0; i < team.length; i++) {
      for (var j = i + 1; j < team.length; j++) {
        final key = ([team[i].id, team[j].id]..sort()).join(':');
        score += counts[key] ?? 0;
      }
    }
    return score;
  }

  double _kotcWaitScore(List<KotcPlayer> team,
      Map<String, int> lastPlayed, int totalGames) {
    if (team.isEmpty) return 0;
    var total = 0.0;
    for (final p in team) {
      final last = lastPlayed[p.id];
      total += last == null ? totalGames + 1 : totalGames - last;
    }
    return total / team.length;
  }

  List<List<KotcPlayer>> _kotcCombinations(
      List<KotcPlayer> items, int k) {
    if (k == 0) return [[]];
    if (items.length < k) return [];
    final result = <List<KotcPlayer>>[];
    for (var i = 0; i <= items.length - k; i++) {
      for (final rest in _kotcCombinations(items.sublist(i + 1), k - 1)) {
        result.add([items[i], ...rest]);
      }
    }
    return result;
  }

  // ── Scoring ───────────────────────────────────────────────────────────────

  void _addPoint() {
    if (!_hasTeam || _isCompleted) return;
    setState(() => _currentPoints++);
    if (_strikeReached) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _showStrikeDialog());
    }
  }

  void _removePoint() {
    if (!_hasTeam || _isCompleted || _currentPoints <= 0) return;
    setState(() => _currentPoints--);
  }

  // ── Ejection ──────────────────────────────────────────────────────────────

  void _ejectTeam({required bool gameWon}) {
    if (!_hasTeam) return;
    final remaining = _sessionTimerKey.currentState?.remaining;
    final game = KotcGame(
      id:        KotcGame.generateId(),
      playerIds: _teamPlayers.map((p) => p.id).toList(),
      points:    _currentPoints,
      gamesWon:  gameWon ? 1 : 0,
      startTime: DateTime.now().subtract(_gameWatch.elapsed),
      endTime:   DateTime.now(),
    );

    _t = _t.copyWith(
      status:           KotcTournamentStatus.inProgress,
      games:            [..._t.games, game],
      remainingSeconds: remaining?.inSeconds,
    );
    _persist();

    _gameWatch
      ..stop()
      ..reset();

    if (_isAutoMode && _challengerTeam.length == _t.playersPerTeam) {
      // Transition chain: Challengers → Court, Up Next → Challengers, compute new Up Next.
      final nextCourt      = List<KotcPlayer>.from(_challengerTeam);
      final nextChallenger = List<KotcPlayer>.from(_currentSuggestion);
      // Hand off admin before starting next team so _activePool excludes the new admin.
      if (_isAllPlay && _nextAdminPlayerId != null) {
        _adminPlayerId     = _nextAdminPlayerId;
        _nextAdminPlayerId = null;
      }
      setState(() {
        _teamPlayers      = [];
        _pendingSelection = [];
        _currentPoints    = 0;
        _challengerTeam   = [];
      });
      _startTeam(nextCourt);
      if (nextChallenger.length == _t.playersPerTeam) {
        // Enough players for a pre-defined Up Next — promote it to Challengers.
        setState(() => _challengerTeam = nextChallenger);
        _recomputeUpNext();
      } else {
        // Too few players for Up Next — pick the best available from the pool.
        _recomputeChallenger();
      }
    } else {
      setState(() {
        _teamPlayers      = [];
        _pool             = List.from(_t.players);
        _pendingSelection = [];
        _currentPoints    = 0;
        _challengerTeam   = [];
      });
      _initSuggestion();
    }
  }

  void _undoEjection() {
    if (!_canUndo) return;
    // In automated mode a new team is already on court — stop and discard them.
    if (_hasTeam) {
      _gameWatch
        ..stop()
        ..reset();
    }

    final lastGame = _t.games.last;
    final restoredPlayers = lastGame.playerIds
        .map((id) => _t.players.firstWhere(
              (p) => p.id == id,
              orElse: () => KotcPlayer(
                  id: id, name: '?', source: KotcPlayerSource.random),
            ))
        .toList();

    _t = _t.copyWith(
        games: _t.games.sublist(0, _t.games.length - 1));
    _persist();

    _gameWatch.reset();
    if (_timerRunning) _gameWatch.start();

    setState(() {
      _teamPlayers      = restoredPlayers;
      _pool             = _t.players
          .where((p) => !restoredPlayers.any((r) => r.id == p.id))
          .toList();
      _pendingSelection = [];
      _currentPoints    = lastGame.points;
      _challengerTeam   = [];
    });
    _recomputeChallenger();
  }

  // ── Player substitution ───────────────────────────────────────────────────

  void _swapPlayer(KotcPlayer outgoing) {
    if (_pool.isEmpty) return;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => TournaQSheet(
        body: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Substitute ${outgoing.name}',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text(
                    '${outgoing.name} will return to the queue.',
                    style: const TextStyle(
                        fontSize: 13, color: Colors.black54),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              itemCount: _pool.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final incoming = _pool[i];
                return ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 4),
                  leading: CircleAvatar(
                    radius: 16,
                    backgroundColor: _kGoldLight,
                    child: Text(
                      incoming.name.isNotEmpty
                          ? incoming.name[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                          color: _kGold,
                          fontWeight: FontWeight.w700,
                          fontSize: 13),
                    ),
                  ),
                  title: Row(children: [
                    Text(incoming.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14)),
                    if (incoming.isLate) ...[
                      const SizedBox(width: 6),
                      _lateChip(),
                    ],
                  ]),
                  trailing: const Icon(Icons.swap_horiz_rounded,
                      color: _kGold),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    setState(() {
                      _teamPlayers
                          .removeWhere((t) => t.id == outgoing.id);
                      _teamPlayers.add(incoming);
                      _pool.removeWhere((q) => q.id == incoming.id);
                      _pool.add(outgoing);
                    });
                    _recomputeUpNext();
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // ── Add late player ───────────────────────────────────────────────────────

  Future<void> _showAddPlayerToQueue() async {
    final proceed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: const Text('Add Late Player?',
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w700)),
        content: const Text(
          'This player is joining late and won\'t have had the same '
          'opportunities as players who started at the beginning. '
          'Their stats will be tagged as "Late".',
          style: TextStyle(
              fontSize: 14, color: Colors.black54, height: 1.4),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: _kOlive,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
    if (proceed != true || !mounted) return;
    _showLatePlayersSheet();
  }

  void _showLatePlayersSheet() {
    final nameCtrl   = TextEditingController();
    final searchCtrl = TextEditingController();
    var searchActive = false;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) {
          final query       = searchCtrl.text.toLowerCase();
          final alreadyIn   = {..._t.players.map((p) => p.appUserId)};
          final allExisting = widget.existingPlayers
              .where((u) => !alreadyIn.contains(u.id))
              .toList();
          final filtered    = query.isEmpty
              ? allExisting
              : allExisting
                  .where((u) => u.name.toLowerCase().contains(query))
                  .toList();

          void rebuild() {
            setSheet(() {});
            setState(() {});
            _recomputeUpNext();
          }

          void addByName(String raw) {
            final name = raw.trim();
            if (name.isEmpty) return;
            final p = KotcPlayer(
              id:     KotcPlayer.generateId(),
              name:   name,
              source: KotcPlayerSource.created,
              isLate: true,
            );
            _t = _t.copyWith(players: [..._t.players, p]);
            _persist();
            _pool.add(p);
            nameCtrl.clear();
            rebuild();
          }

          void addExisting(String appUserId, String name) {
            if (alreadyIn.contains(appUserId)) return;
            final p = KotcPlayer(
              id:        KotcPlayer.generateId(),
              name:      name,
              source:    KotcPlayerSource.existing,
              appUserId: appUserId,
              isLate:    true,
            );
            _t = _t.copyWith(players: [..._t.players, p]);
            _persist();
            _pool.add(p);
            rebuild();
          }

          void fillRandom() {
            final generated = ScrambleService.generateRandomPlayers(4);
            for (final g in generated) {
              final p = KotcPlayer(
                id:     KotcPlayer.generateId(),
                name:   g.name,
                source: KotcPlayerSource.random,
                isLate: true,
              );
              _t = _t.copyWith(players: [..._t.players, p]);
              _pool.add(p);
            }
            _persist();
            rebuild();
          }

          final latePlayers =
              _t.players.where((p) => p.isLate).toList();

          return TournaQSheet(
            body: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(children: [
                    const Text('Add Players to Queue',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800)),
                    const Spacer(),
                    Text('${latePlayers.length} added',
                        style: const TextStyle(
                            color: Colors.black45, fontSize: 13)),
                  ]),
                  const SizedBox(height: 4),
                  const Text(
                    'All players added here will be tagged "Late" in stats.',
                    style: TextStyle(
                        fontSize: 12, color: Colors.black45),
                  ),
                  const SizedBox(height: 16),

                  // Add by name
                  Row(children: [
                    Expanded(
                      child: TextField(
                        controller: nameCtrl,
                        textCapitalization: TextCapitalization.words,
                        decoration: InputDecoration(
                          hintText: 'Player name',
                          isDense: true,
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10)),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 12),
                        ),
                        onSubmitted: addByName,
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () => addByName(nameCtrl.text),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _kOlive,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Add'),
                    ),
                  ]),

                  // Search existing app players
                  if (allExisting.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text('Existing Players (${allExisting.length})',
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.black54)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: searchCtrl,
                      decoration: InputDecoration(
                        hintText: 'Search players…',
                        isDense: true,
                        prefixIcon: const Icon(Icons.search_rounded,
                            size: 18, color: Colors.black45),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                      ),
                      onTap: () =>
                          setSheet(() => searchActive = true),
                      onChanged: (_) =>
                          setSheet(() => searchActive = true),
                    ),
                    if (searchActive) ...[
                      const SizedBox(height: 6),
                      if (filtered.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Text('No players match.',
                              style: TextStyle(
                                  color: Colors.black38,
                                  fontSize: 13)),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: filtered.length,
                          separatorBuilder: (_, _) =>
                              const Divider(height: 1),
                          itemBuilder: (_, i) {
                            final u = filtered[i];
                            return ListTile(
                              dense: true,
                              contentPadding:
                                  const EdgeInsets.symmetric(
                                      horizontal: 4),
                              title: Text(u.name,
                                  style: const TextStyle(
                                      fontSize: 13)),
                              trailing: IconButton(
                                icon: const Icon(
                                    Icons.add_circle_outline_rounded,
                                    size: 20,
                                    color: _kOlive),
                                onPressed: () =>
                                    addExisting(u.id, u.name),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            );
                          },
                        ),
                    ],
                  ],

                  // Fill random + added list
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                          '${latePlayers.length} player${latePlayers.length == 1 ? '' : 's'} added',
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.black54)),
                      TextButton.icon(
                        onPressed: fillRandom,
                        icon: const Icon(Icons.shuffle_rounded,
                            size: 16),
                        label: const Text('Add 4 random'),
                        style: TextButton.styleFrom(
                            foregroundColor: _kOlive),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  if (latePlayers.isEmpty)
                    const Text('No late players added yet.',
                        style: TextStyle(
                            color: Colors.black38, fontSize: 13))
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: latePlayers.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: 4),
                      itemBuilder: (_, i) {
                        final p = latePlayers[i];
                        return ListTile(
                          dense: true,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: BorderSide(
                                color: Colors.grey.shade200),
                          ),
                          leading: CircleAvatar(
                            radius: 14,
                            backgroundColor: _kGoldLight,
                            child: Text(
                              p.name.isNotEmpty
                                  ? p.name[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                  fontSize: 11,
                                  color: _kGold,
                                  fontWeight: FontWeight.w700),
                            ),
                          ),
                          title: Row(children: [
                            Text(p.name,
                                style: const TextStyle(
                                    fontSize: 13)),
                            const SizedBox(width: 6),
                            _lateChip(),
                          ]),
                          trailing: IconButton(
                            icon: const Icon(Icons.close_rounded,
                                size: 16, color: Colors.black38),
                            onPressed: () {
                              final updated = _t.players
                                  .where((q) => q.id != p.id)
                                  .toList();
                              _t = _t.copyWith(players: updated);
                              _persist();
                              _pool.removeWhere(
                                  (q) => q.id == p.id);
                              rebuild();
                            },
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          );
        },
      ),
    ).whenComplete(() {
      nameCtrl.dispose();
      searchCtrl.dispose();
    });
  }

  // ── Late chip ──────────────────────────────────────────────────────────────

  Widget _lateChip() => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.orange.shade100,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          'LATE',
          style: TextStyle(
            fontSize: 8,
            fontWeight: FontWeight.w800,
            color: Colors.orange.shade700,
            letterSpacing: 0.4,
          ),
        ),
      );

  // ── Admin tile (automatedAllPlay only) ───────────────────────────────────

  Widget _buildAdminTile() {
    final admin     = _t.players.where((p) => p.id == _adminPlayerId).firstOrNull;
    final nextAdmin = _t.players.where((p) => p.id == _nextAdminPlayerId).firstOrNull;

    return GestureDetector(
      onTap: _showAdminOverrideSheet,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(children: [
          const Icon(Icons.manage_accounts_rounded,
              size: 15, color: Colors.black45),
          const SizedBox(width: 6),
          const Text(
            'ADMIN',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: Colors.black45,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              admin?.name ?? '—',
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w700),
            ),
          ),
          if (nextAdmin != null) ...[
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward_rounded,
                size: 13, color: Colors.black38),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                nextAdmin.name,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 12, color: Colors.black54),
              ),
            ),
          ],
          const SizedBox(width: 8),
          const Icon(Icons.edit_rounded, size: 13, color: Colors.black38),
        ]),
      ),
    );
  }

  void _showAdminOverrideSheet() {
    if (!_isAllPlay) return;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => TournaQSheet(
        body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Change Admin',
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              const Text(
                'Select who keeps score. The current admin returns to the queue.',
                style: TextStyle(fontSize: 12, color: Colors.black45),
              ),
              const SizedBox(height: 16),
              // Current admin + pool players
              ..._pool.map((p) {
                final isCurrent = p.id == _adminPlayerId;
                return ListTile(
                  dense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 4),
                  leading: CircleAvatar(
                    radius: 14,
                    backgroundColor:
                        isCurrent ? _kGoldLight : Colors.grey.shade100,
                    child: Text(
                      p.name.isNotEmpty ? p.name[0].toUpperCase() : '?',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isCurrent ? _kGold : Colors.black54),
                    ),
                  ),
                  title: Text(p.name,
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: isCurrent
                              ? FontWeight.w700
                              : FontWeight.w500)),
                  trailing: isCurrent
                      ? const Icon(Icons.manage_accounts_rounded,
                          size: 18, color: _kGold)
                      : null,
                  onTap: isCurrent
                      ? null
                      : () {
                          Navigator.of(ctx).pop();
                          setState(() => _adminPlayerId = p.id);
                          if (_hasTeam) {
                            _recomputeChallenger();
                          } else {
                            _initSuggestion();
                          }
                        },
                );
              }),
              if (_hasTeam && _nextAdminPlayerId != null) ...[
                const Divider(height: 24),
                const Text(
                  'NEXT ADMIN',
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.black45,
                      letterSpacing: 0.5),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Suggested from the current court team.',
                  style: TextStyle(fontSize: 12, color: Colors.black45),
                ),
                const SizedBox(height: 8),
                ..._teamPlayers.map((p) {
                  final isNext = p.id == _nextAdminPlayerId;
                  return ListTile(
                    dense: true,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 4),
                    leading: CircleAvatar(
                      radius: 14,
                      backgroundColor: isNext
                          ? Colors.grey.shade200
                          : Colors.grey.shade100,
                      child: Text(
                        p.name.isNotEmpty ? p.name[0].toUpperCase() : '?',
                        style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.black54),
                      ),
                    ),
                    title: Text(p.name,
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: isNext
                                ? FontWeight.w700
                                : FontWeight.w500)),
                    trailing: isNext
                        ? const Icon(Icons.schedule_rounded,
                            size: 18, color: Colors.black45)
                        : null,
                    onTap: () {
                      Navigator.of(ctx).pop();
                      setState(() => _nextAdminPlayerId = p.id);
                    },
                  );
                }),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showStrikeDialog() async {
    if (!mounted) return;
    _gameWatch.stop();
    final names = _teamPlayers.map((p) => p.name).join(' & ');

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
        contentPadding: const EdgeInsets.fromLTRB(24, 14, 24, 0),
        actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
        title: Row(children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
                color: _kGoldLight,
                borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.emoji_events_rounded,
                color: _kGold, size: 24),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text('Game Won!',
                style: TextStyle(
                    fontSize: 20, fontWeight: FontWeight.w800)),
          ),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$names reached ${_t.strikePoints} points!',
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            const Text(
              'They will be ejected and return to the queue.',
              style: TextStyle(fontSize: 13, color: Colors.black54),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.logout_rounded, size: 18),
              label: const Text('Eject Team',
                  style: TextStyle(fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: _kGold,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                Navigator.of(ctx).pop();
                _ejectTeam(gameWon: true);
                if (_timerRunning) _gameWatch.start();
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmManualEject() async {
    final pts = _currentPoints;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: const Text('Eject Team?',
            style:
                TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        content: Text(
          pts > 0
              ? 'Current team will be ejected. Their $pts point${pts == 1 ? '' : 's'} will be recorded.'
              : 'Current team will be ejected and return to the queue.',
          style:
              const TextStyle(fontSize: 14, color: Colors.black54),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: _kGold,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Eject'),
          ),
        ],
      ),
    );
    if (ok == true) _ejectTeam(gameWon: false);
  }

  // ── Tournament completion ─────────────────────────────────────────────────

  void _completeTournament() {
    if (_hasTeam) _ejectTeam(gameWon: false);
    _sessionTimerKey.currentState?.pause();
    _gameWatch.stop();
    final remaining = _sessionTimerKey.currentState?.remaining;
    _t = _t.copyWith(
      status:           KotcTournamentStatus.completed,
      remainingSeconds: remaining?.inSeconds,
    );
    _persist();
    setState(() => _timerRunning = false);
    _showSummaryDialog().then((_) {
      if (mounted) Navigator.of(context).pop();
    });
  }

  void _undoCompletion() {
    _t = _t.copyWith(status: KotcTournamentStatus.inProgress);
    _persist();
    setState(() {});
  }

  Future<void> _saveAndReturn() async {
    if (_hasTeam) {
      final pts = _currentPoints;
      final ok  = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          title: const Text('Leave without ejecting?',
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w700)),
          content: Text(
            pts > 0
                ? 'The current team has $pts unrecorded point${pts == 1 ? '' : 's'}. Leaving now will discard them. Eject the team first to save their score.'
                : 'The current team\'s unrecorded data will be lost.',
            style: const TextStyle(
                fontSize: 14, color: Colors.black54, height: 1.4),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancel')),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: TextButton.styleFrom(
                  foregroundColor: Colors.red),
              child: const Text('Leave anyway'),
            ),
          ],
        ),
      );
      if (ok != true) return;
    }
    final remaining = _sessionTimerKey.currentState?.remaining;
    _t = _t.copyWith(remainingSeconds: remaining?.inSeconds);
    _persist();
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _showSummaryDialog() async {
    final pointsMap = _t.pointsPerPlayer;
    final gamesMap  = _t.gamesWonPerPlayer;
    final ranked    = _t.players.toList()
      ..sort((a, b) {
        final gDiff =
            (gamesMap[b.id] ?? 0) - (gamesMap[a.id] ?? 0);
        if (gDiff != 0) return gDiff;
        return (pointsMap[b.id] ?? 0) - (pointsMap[a.id] ?? 0);
      });

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: Row(children: [
          Icon(Icons.workspace_premium_rounded,
              color: _kGold, size: 24),
          const SizedBox(width: 8),
          const Text('Tournament Complete',
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w800)),
        ]),
        content: SizedBox(
          width: 280,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${_t.gameCount} game${_t.gameCount == 1 ? '' : 's'} · ${_t.totalPoints} pts total',
                style: const TextStyle(
                    fontSize: 13, color: Colors.black45),
              ),
              const SizedBox(height: 12),
              const Text('Final Standings',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.black54)),
              const SizedBox(height: 6),
              ...ranked.map((p) {
                final pts   = pointsMap[p.id] ?? 0;
                final games = gamesMap[p.id] ?? 0;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(children: [
                    Expanded(
                        child: Text(p.name,
                            style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600))),
                    Text(
                      games > 0
                          ? '$games 🏆 · $pts pts'
                          : '$pts pts',
                      style: const TextStyle(
                          fontSize: 13, color: Colors.black54),
                    ),
                  ]),
                );
              }),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: _kGold,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Done',
                style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  // ── Stats sheet ───────────────────────────────────────────────────────────

  void _openStats() {
    final pointsMap = _t.pointsPerPlayer;
    final gamesMap  = _t.gamesWonPerPlayer;
    final playedMap = _t.gamesPerPlayer;
    final ranked    = _t.players.toList()
      ..sort((a, b) {
        final gDiff =
            (gamesMap[b.id] ?? 0) - (gamesMap[a.id] ?? 0);
        if (gDiff != 0) return gDiff;
        return (pointsMap[b.id] ?? 0) - (pointsMap[a.id] ?? 0);
      });

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => TournaQSheet(
        body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Player Stats',
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text(
                '${_t.gameCount} game${_t.gameCount == 1 ? '' : 's'} · ${_t.totalPoints} pts total',
                style: const TextStyle(
                    fontSize: 13, color: Colors.black45),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 4),
                child: Row(children: const [
                  SizedBox(width: 28),
                  Expanded(
                      child: Text('Player',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.black45))),
                  SizedBox(
                    width: 44,
                    child: Text('Games',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.black45)),
                  ),
                  SizedBox(
                    width: 52,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.emoji_events_rounded,
                            size: 11, color: Colors.black45),
                        SizedBox(width: 2),
                        Text('Wins',
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Colors.black45)),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 44,
                    child: Text('Pts',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.black45)),
                  ),
                ]),
              ),
              ...ranked.asMap().entries.map((entry) {
                final i      = entry.key;
                final p      = entry.value;
                final pts    = pointsMap[p.id] ?? 0;
                final wins   = gamesMap[p.id] ?? 0;
                final played = playedMap[p.id] ?? 0;
                final isTop  = i == 0 && wins > 0;
                return Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color:
                        isTop ? _kGoldLight : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isTop
                          ? _kGold.withValues(alpha: 0.4)
                          : Colors.grey.shade200,
                    ),
                  ),
                  child: Row(children: [
                    SizedBox(
                      width: 28,
                      child: Text('${i + 1}',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: isTop
                                  ? _kGold
                                  : Colors.black45)),
                    ),
                    Expanded(
                      child: Row(children: [
                        Flexible(
                          child: Text(p.name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14))),
                        if (p.isLate) ...[
                          const SizedBox(width: 6),
                          _lateChip(),
                        ],
                      ]),
                    ),
                    SizedBox(
                      width: 44,
                      child: Text('$played',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.black54)),
                    ),
                    SizedBox(
                      width: 52,
                      child: Text('$wins',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: wins > 0
                                  ? _kGold
                                  : Colors.black38)),
                    ),
                    SizedBox(
                      width: 44,
                      child: Text('$pts',
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.black87)),
                    ),
                  ]),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  // ── Options sheet (tune button — History shortcut) ────────────────────────

  void _showOptions() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetCtx) {
        return TournaQSheet(
          body: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Options',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 8),
                  leading: Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                        color: _kGoldLight, shape: BoxShape.circle),
                    child: const Icon(Icons.history_rounded,
                        color: _kGold, size: 20),
                  ),
                  title: const Text('Game History',
                      style:
                          TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('View all completed games',
                      style: TextStyle(
                          fontSize: 12, color: Colors.black45)),
                  onTap: () {
                    Navigator.of(sheetCtx).pop();
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => KingOfTheCourtHistoryPage(
                          tournament: _t),
                    ));
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final optionsButton = IconButton(
      icon: const Icon(Icons.tune_rounded, size: 20, color: _kOlive),
      tooltip: 'Options',
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
      visualDensity: VisualDensity.compact,
      onPressed: _showOptions,
    );

    return Scaffold(
      appBar: TournaQAppBar(
        title: 'King of the Court',
        subtitle: 'Scoreboard',
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart_rounded,
                color: AppColors.goldLight),
            tooltip: 'Player Stats',
            onPressed: _openStats,
          ),
        ],
      ),
      body: SafeArea(
        child: OrientationBuilder(
          builder: (context, orientation) {
            final isLandscape = orientation == Orientation.landscape;
            return isLandscape
                ? _buildLandscapeBody(optionsButton)
                : _buildPortraitBody(optionsButton);
          },
        ),
      ),
    );
  }

  Widget _buildPortraitBody(Widget optionsButton) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _sectionHeader(
            'Gameplay Controls',
            Icons.sports_volleyball_rounded,
            trailing: optionsButton,
          ),
          const SizedBox(height: 10),
          // Timer above counter (Scramble-style)
          _buildSessionTimerRow(),
          const SizedBox(height: 10),
          if (_isCompleted)
            _buildCompletedBanner()
          else if (_hasTeam && _isAutoMode) ...[
            // Three-slot automated layout: Up Next → Challengers → Court Team
            _buildUpNextTile(),
            const SizedBox(height: 8),
            _buildChallengersTile(),
            const SizedBox(height: 8),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(flex: 4, child: _buildActiveScoringTile()),
                  const SizedBox(width: 8),
                  Expanded(flex: 1, child: _buildNarrowEjectButton()),
                ],
              ),
            ),
            if (_isAllPlay) ...[
              const SizedBox(height: 8),
              _buildAdminTile(),
            ],
          ] else if (_hasTeam)
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(flex: 4, child: _buildActiveScoringTile()),
                  const SizedBox(width: 8),
                  Expanded(flex: 1, child: _buildNarrowEjectButton()),
                ],
              ),
            )
          else ...[
            _buildSelectionTile(),
            if (_isAllPlay) ...[
              const SizedBox(height: 8),
              _buildAdminTile(),
            ],
          ],
          if (_canUndo) ...[
            const SizedBox(height: 10),
            _buildUndoEjectionButton(),
          ],
          const SizedBox(height: 24),
          _sectionHeader('Match Controls', Icons.emoji_events_rounded),
          const SizedBox(height: 10),
          _buildMatchControls(),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildLandscapeBody(Widget optionsButton) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Compact inline timer row (Scramble-style)
          Row(
            children: [
              const Icon(Icons.timer_rounded, size: 13, color: _kOlive),
              const SizedBox(width: 4),
              ScrambleTimerWidget(
                key: _sessionTimerKey,
                initial: Duration(
                    seconds: _t.remainingSeconds ??
                        _t.totalTime.inSeconds),
                mode: ScrambleTimerMode.countdown,
                autoStart: false,
                compact: true,
                onTick: (_) => setState(() {}),
                onFinished: _onSessionFinished,
              ),
              const SizedBox(width: 8),
              _refBtn(Icons.pause_rounded, 'Stop', _pauseTimer),
              const SizedBox(width: 4),
              _refBtn(Icons.replay_rounded, 'Start / Restart',
                  _startOrRestart,
                  primary: true),
              const SizedBox(width: 4),
              _refTextBtn('+30s',
                  () => _sessionTimerKey.currentState
                      ?.addTime(const Duration(seconds: 30))),
              const SizedBox(width: 4),
              _refTextBtn('−30s',
                  () => _sessionTimerKey.currentState
                      ?.addTime(const Duration(seconds: -30))),
              const Spacer(),
              optionsButton,
            ],
          ),
          const SizedBox(height: 4),
          // Landscape content: 3-column automated or classic 2-column
          Expanded(
            child: _hasTeam && _isAutoMode
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Column 1: Up Next (top) + Challengers (bottom)
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(child: _buildUpNextTile(compact: true)),
                            const SizedBox(height: 6),
                            Expanded(child: _buildChallengersTile(compact: true)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      // Column 2: Scoring tile + Admin tile below (allPlay only)
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(child: _buildActiveScoringTile(compact: true)),
                            if (_isAllPlay) ...[
                              const SizedBox(height: 6),
                              _buildAdminTile(),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      // Column 3: Eject (focal, flex 2) + Undo (secondary, flex 1)
                      SizedBox(
                        width: 64,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              flex: _canUndo ? 2 : 1,
                              child: _buildNarrowEjectButton(),
                            ),
                            if (_canUndo) ...[
                              const SizedBox(height: 6),
                              Expanded(
                                flex: 1,
                                child: _buildNarrowUndoButton(),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  )
                : (_hasTeam || _canUndo)
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                              flex: 4,
                              child: _buildScoringTile(compact: true)),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 1,
                            child: _hasTeam
                                ? _buildNarrowEjectButton()
                                : _buildNarrowUndoButton(),
                          ),
                        ],
                      )
                    : _buildScoringTile(compact: true),
          ),
        ],
      ),
    );
  }

  Widget _buildNarrowEjectButton() {
    return ElevatedButton(
      onPressed: _confirmManualEject,
      style: ElevatedButton.styleFrom(
        backgroundColor: _kGold,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.all(8),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.logout_rounded, size: 22),
            SizedBox(height: 6),
            Text(
              'Team\nEjected',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNarrowUndoButton() {
    return OutlinedButton(
      onPressed: _undoEjection,
      style: OutlinedButton.styleFrom(
        foregroundColor: _kGold,
        side: BorderSide(color: _kGold.withValues(alpha: 0.6)),
        padding: const EdgeInsets.all(8),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.undo_rounded, size: 16),
            SizedBox(height: 4),
            Text(
              'Undo\nEject',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUndoEjectionButton() {
    return OutlinedButton.icon(
      onPressed: _undoEjection,
      icon: const Icon(Icons.undo_rounded, size: 18),
      label: const Text('Undo Last Ejection',
          style: TextStyle(fontWeight: FontWeight.w600)),
      style: OutlinedButton.styleFrom(
        foregroundColor: _kGold,
        side: BorderSide(color: _kGold.withValues(alpha: 0.6)),
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // ── Session timer row ─────────────────────────────────────────────────────

  Widget _buildSessionTimerRow() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(children: [
            const Icon(Icons.timer_rounded,
                size: 14, color: _kOlive),
            const SizedBox(width: 6),
            const Text(
              'SESSION TIMER',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: _kOlive,
                letterSpacing: 0.6,
              ),
            ),
            const Spacer(),
            ScrambleTimerWidget(
              key: _sessionTimerKey,
              initial: Duration(
                  seconds: _t.remainingSeconds ??
                      _t.totalTime.inSeconds),
              mode: ScrambleTimerMode.countdown,
              autoStart: false,
              compact: true,
              onTick: (_) => setState(() {}),
              onFinished: _onSessionFinished,
            ),
          ]),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            alignment: WrapAlignment.center,
            children: [
              _refBtn(Icons.pause_rounded, 'Stop', _pauseTimer),
              _refBtn(Icons.replay_rounded, 'Start / Restart',
                  _startOrRestart,
                  primary: true),
              _refTextBtn('+30s',
                  () => _sessionTimerKey.currentState
                      ?.addTime(const Duration(seconds: 30))),
              _refTextBtn('−30s',
                  () => _sessionTimerKey.currentState
                      ?.addTime(const Duration(seconds: -30))),
            ],
          ),
        ],
      ),
    );
  }

  // ── Scoring tile ──────────────────────────────────────────────────────────

  Widget _buildScoringTile({bool compact = false}) {
    if (_isCompleted) return _buildCompletedBanner();
    return _hasTeam
        ? _buildActiveScoringTile(compact: compact)
        : _buildSelectionTile(compact: compact);
  }

  Widget _buildCompletedBanner() {
    final gamesMap = _t.gamesWonPerPlayer;
    final ranked   = _t.players.toList()
      ..sort((a, b) =>
          (gamesMap[b.id] ?? 0) - (gamesMap[a.id] ?? 0));
    final leader = ranked.isNotEmpty ? ranked.first : null;
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _kGoldLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: _kGold.withValues(alpha: 0.4)),
      ),
      child: Row(children: [
        const Icon(Icons.lock_rounded,
            size: 16, color: Colors.black54),
        const SizedBox(width: 8),
        const Expanded(
            child: Text('Tournament completed',
                style: TextStyle(
                    fontSize: 13,
                    color: Colors.black54,
                    fontWeight: FontWeight.w500))),
        if (leader != null && (gamesMap[leader.id] ?? 0) > 0)
          Text(
            '${gamesMap[leader.id]} 🏆 ${leader.name}',
            style: const TextStyle(
                fontSize: 12,
                color: _kGold,
                fontWeight: FontWeight.w700),
          ),
      ]),
    );
  }

  // ── Up Next tile (shown while game is in progress, automated mode) ─────────

  Widget _buildUpNextTile({bool compact = false}) {
    final team     = _currentSuggestion;
    final hasTeam  = team.length == _t.playersPerTeam;
    final canReroll = _candidates.length > 1;

    return Card(
      margin: compact ? EdgeInsets.zero : null,
      color: Colors.grey.shade50,
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: EdgeInsets.all(compact ? 10 : 14),
        child: Column(
          mainAxisSize: compact ? MainAxisSize.max : MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(children: [
              Icon(Icons.schedule_rounded,
                  size: 15, color: Colors.grey.shade500),
              const SizedBox(width: 6),
              Text('Up Next',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade500,
                    letterSpacing: 0.4,
                  )),
              const Spacer(),
              TextButton.icon(
                onPressed: canReroll ? _reroll : null,
                icon: const Icon(Icons.refresh_rounded, size: 13),
                label: const Text('Re-roll',
                    style: TextStyle(fontSize: 11)),
                style: TextButton.styleFrom(
                  foregroundColor: _kOlive,
                  disabledForegroundColor: Colors.black26,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 2),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ]),
            const SizedBox(height: 8),
            if (!hasTeam)
              Text('Not enough players in queue.',
                  style: TextStyle(
                      color: Colors.grey.shade400, fontSize: 12))
            else
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: team
                    .map((p) => Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(p.name,
                              style: TextStyle(
                                  fontSize: compact ? 11 : 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade600)),
                        ))
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }

  // ── Challengers tile (shown while game is in progress, automated mode) ─────

  Widget _buildChallengersTile({bool compact = false}) {
    final hasChallengers = _challengerTeam.length == _t.playersPerTeam;

    return Card(
      margin: compact ? EdgeInsets.zero : null,
      color: _kOliveLight,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: _kOlive.withValues(alpha: 0.35), width: 1.5),
      ),
      child: Padding(
        padding: EdgeInsets.all(compact ? 10 : 14),
        child: Column(
          mainAxisSize: compact ? MainAxisSize.max : MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(children: [
              const Icon(Icons.groups_rounded, size: 15, color: _kOlive),
              const SizedBox(width: 6),
              const Text('Challengers',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _kOlive,
                    letterSpacing: 0.4,
                  )),
            ]),
            const SizedBox(height: 8),
            if (!hasChallengers)
              const Text('Waiting for players...',
                  style: TextStyle(color: _kOlive, fontSize: 12))
            else
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: _challengerTeam
                    .map((p) => Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: _kOlive.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: _kOlive.withValues(alpha: 0.4)),
                          ),
                          child: Text(p.name,
                              style: TextStyle(
                                  fontSize: compact ? 11 : 13,
                                  fontWeight: FontWeight.w700,
                                  color: _kOlive)),
                        ))
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }

  // ── Initial suggested-team tile (shown before any team is on court) ─────────

  Widget _buildAutomatedSuggestionTile({bool compact = false}) {
    final suggested = _currentSuggestion;
    final canStart  = suggested.length == _t.playersPerTeam;
    final canReroll = _candidates.length > 1;

    return Card(
      margin: compact ? EdgeInsets.zero : null,
      color: canStart ? _kGoldCardBg : Colors.grey.shade50,
      elevation: canStart ? 3 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: canStart ? _kGold : Colors.grey.shade300,
          width: canStart ? 2 : 1,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(compact ? 10 : 16),
        child: Column(
          mainAxisSize: compact ? MainAxisSize.max : MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(children: [
              Icon(Icons.auto_awesome_rounded,
                  size: 16,
                  color: canStart ? _kGold : Colors.black45),
              const SizedBox(width: 8),
              Text(
                'Suggested Team',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: canStart ? _kGold : Colors.black54,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: canReroll ? _reroll : null,
                icon: const Icon(Icons.refresh_rounded, size: 14),
                label: const Text('Re-roll',
                    style: TextStyle(fontSize: 12)),
                style: TextButton.styleFrom(
                  foregroundColor: _kOlive,
                  disabledForegroundColor: Colors.black26,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ]),
            if (suggested.isEmpty) ...[
              SizedBox(height: compact ? 8 : 12),
              const Text('Not enough players in queue.',
                  style: TextStyle(color: Colors.black38, fontSize: 13)),
            ] else ...[
              SizedBox(height: compact ? 8 : 12),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: suggested
                    .map((p) => Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: _kGold,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(p.name,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14)),
                        ))
                    .toList(),
              ),
            ],
            if (compact) const Spacer(),
            SizedBox(height: compact ? 0 : 14),
            ElevatedButton.icon(
              onPressed: canStart ? _confirmSuggestedTeam : null,
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text('Start Game',
                  style: TextStyle(fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: _kGold,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey.shade200,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectionTile({bool compact = false}) {
    if (_isAutoMode) {
      return _buildAutomatedSuggestionTile(compact: compact);
    }
    final needed   = _t.playersPerTeam;
    final selected = _pendingSelection.length;
    final canStart = _canStart;

    return Card(
      margin: compact ? EdgeInsets.zero : null,
      color: canStart ? _kGoldCardBg : Colors.grey.shade50,
      elevation: canStart ? 3 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: canStart ? _kGold : Colors.grey.shade300,
          width: canStart ? 2 : 1,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(compact ? 10 : 16),
        child: Column(
          mainAxisSize: compact ? MainAxisSize.max : MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(children: [
              Icon(Icons.group_rounded,
                  size: 16,
                  color: canStart ? _kGold : Colors.black45),
              const SizedBox(width: 8),
              Text(
                'Select $needed players ($selected / $needed)',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: canStart ? _kGold : Colors.black54,
                ),
              ),
            ]),

            if (_pendingSelection.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: _pendingSelection
                    .map((p) => GestureDetector(
                          onTap: () => _toggleSelection(p),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: _kGold,
                              borderRadius:
                                  BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(p.name,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight:
                                            FontWeight.w700,
                                        fontSize: 14)),
                                const SizedBox(width: 6),
                                const Icon(Icons.close_rounded,
                                    size: 14,
                                    color: Colors.white70),
                              ],
                            ),
                          ),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 10),
              const Divider(height: 1),
            ],

            if (_pool.isNotEmpty) ...[
              SizedBox(height: compact ? 6 : 10),
              Text('Queue — tap to add',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade500)),
              SizedBox(height: compact ? 6 : 8),
              Wrap(
                spacing: compact ? 6 : 8,
                runSpacing: compact ? 6 : 8,
                children: _pool.map((p) {
                  final full = !_canAddPlayer;
                  return GestureDetector(
                    onTap: full
                        ? null
                        : () => _toggleSelection(p),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: compact ? 10 : 14,
                          vertical: compact ? 6 : 10),
                      decoration: BoxDecoration(
                        color: full
                            ? Colors.grey.shade100
                            : _kOliveLight,
                        borderRadius:
                            BorderRadius.circular(20),
                        border: Border.all(
                          color: full
                              ? Colors.grey.shade300
                              : _kOlive.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(p.name,
                          style: TextStyle(
                              fontSize: compact ? 12 : 14,
                              fontWeight: FontWeight.w600,
                              color: full
                                  ? Colors.black38
                                  : AppColors.oliveMedium)),
                    ),
                  );
                }).toList(),
              ),
            ],

            if (compact) const Spacer(),
            SizedBox(height: compact ? 0 : 14),
            ElevatedButton.icon(
              onPressed: canStart ? _confirmTeam : null,
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text('Start Game',
                  style:
                      TextStyle(fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: _kGold,
                foregroundColor: Colors.white,
                disabledBackgroundColor:
                    Colors.grey.shade200,
                padding: const EdgeInsets.symmetric(
                    vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveScoringTile({bool compact = false}) {
    final nearStrike = _strikeEnabled &&
        _currentPoints >=
            (_t.strikePoints - 1).clamp(0, _t.strikePoints);
    final cardBg =
        nearStrike ? _kGoldCardLeading : _kGoldCardBg;

    final elapsed  = _gameWatch.elapsed;
    final gameMin  =
        elapsed.inMinutes.toString().padLeft(2, '0');
    final gameSec  =
        (elapsed.inSeconds % 60).toString().padLeft(2, '0');
    final gameTimeLabel = '$gameMin:$gameSec';

    return Card(
      color: cardBg,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: _kGold, width: 2),
      ),
      child: Padding(
        padding: compact
            ? const EdgeInsets.fromLTRB(12, 10, 12, 8)
            : const EdgeInsets.fromLTRB(16, 16, 16, 12),
        child: Column(
          mainAxisSize: compact ? MainAxisSize.max : MainAxisSize.min,
          children: [
            // Player chips — tap to substitute
            Wrap(
              spacing: 6,
              runSpacing: 4,
              alignment: WrapAlignment.center,
              children: _teamPlayers
                  .map((p) => GestureDetector(
                        onTap: _pool.isNotEmpty
                            ? () => _swapPlayer(p)
                            : null,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _kGold.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: _kGold.withValues(alpha: 0.5)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(p.name,
                                  style: const TextStyle(
                                      color: _kGold,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13)),
                              if (_pool.isNotEmpty) ...[
                                const SizedBox(width: 4),
                                Icon(Icons.swap_horiz_rounded,
                                    size: 11,
                                    color:
                                        _kGold.withValues(alpha: 0.6)),
                              ],
                            ],
                          ),
                        ),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 8),

            // Game time + strike indicator
            Row(children: [
              Icon(Icons.timer_rounded,
                  size: 12,
                  color: _kGold.withValues(alpha: 0.7)),
              const SizedBox(width: 4),
              Text(gameTimeLabel,
                  style: TextStyle(
                    fontSize: 12,
                    color: _kGold.withValues(alpha: 0.8),
                    fontWeight: FontWeight.w600,
                    fontFeatures: const [
                      FontFeature.tabularFigures()
                    ],
                  )),
              if (_strikeEnabled) ...[
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: nearStrike
                        ? _kGold.withValues(alpha: 0.2)
                        : Colors.black.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.bolt_rounded,
                          size: 13,
                          color: nearStrike
                              ? _kGold
                              : Colors.black45),
                      const SizedBox(width: 2),
                      Text(
                          '$_currentPoints / ${_t.strikePoints}',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: nearStrike
                                  ? _kGold
                                  : Colors.black54)),
                    ],
                  ),
                ),
              ],
            ]),

            // Big score — scales to fill available space in compact/landscape mode
            if (compact)
              Expanded(
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.contain,
                    child: Text(
                      '$_currentPoints',
                      style: const TextStyle(
                        fontSize: 200.0,
                        fontWeight: FontWeight.bold,
                        height: 1.0,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ),
              )
            else
              Text(
                '$_currentPoints',
                style: const TextStyle(
                  fontSize: 96.0,
                  fontWeight: FontWeight.bold,
                  height: 1.0,
                  color: Colors.black87,
                ),
              ),

            // +/- buttons — disabled when timer is not running
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton.filled(
                  icon: const Icon(Icons.remove),
                  tooltip: '−1',
                  onPressed: (_timerRunning && _currentPoints > 0)
                      ? _removePoint
                      : null,
                  style: IconButton.styleFrom(
                    backgroundColor:
                        (_timerRunning && _currentPoints > 0)
                            ? _kGold
                            : Colors.grey.shade300,
                    foregroundColor:
                        (_timerRunning && _currentPoints > 0)
                            ? Colors.white
                            : Colors.grey,
                    fixedSize: const Size(52, 52),
                  ),
                ),
                IconButton.filled(
                  icon: const Icon(Icons.add),
                  tooltip: '+1',
                  onPressed: _timerRunning ? _addPoint : null,
                  style: IconButton.styleFrom(
                    backgroundColor:
                        _timerRunning ? _kGold : Colors.grey.shade300,
                    foregroundColor:
                        _timerRunning ? Colors.white : Colors.grey,
                    fixedSize: const Size(64, 64),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Match controls ────────────────────────────────────────────────────────

  Widget _buildMatchControls() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Info chips
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            _chip(Icons.emoji_events_rounded, _t.name,
                _kOliveLight, _kOlive),
            _chip(Icons.grid_view_rounded,
                '${_t.playersPerTeam}v${_t.playersPerTeam}',
                Colors.grey.shade100, Colors.black45),
            _chip(Icons.people_rounded,
                '${_t.playerCount} players',
                Colors.grey.shade100, Colors.black45),
            if (_strikeEnabled)
              _chip(Icons.bolt_rounded,
                  '${_t.strikePoints} pt strike',
                  _kGoldLight, _kGold),
          ],
        ),
        const SizedBox(height: 12),

        // Add late player to queue
        OutlinedButton.icon(
          onPressed: _isCompleted ? null : _showAddPlayerToQueue,
          icon: const Icon(Icons.person_add_rounded, size: 18),
          label: const Text('Add Player to Queue',
              style: TextStyle(fontWeight: FontWeight.w600)),
          style: OutlinedButton.styleFrom(
            foregroundColor: _kOlive,
            side: BorderSide(color: Colors.grey.shade300),
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 8),

        const Divider(height: 20),

        // Complete Tournament / Undo Completion
        if (_isCompleted)
          OutlinedButton.icon(
            onPressed: _undoCompletion,
            icon: const Icon(Icons.undo_rounded, size: 18),
            label: const Text('Undo Completion',
                style: TextStyle(fontWeight: FontWeight.w600)),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.black54,
              side: BorderSide(color: Colors.grey.shade300),
              padding:
                  const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          )
        else
          ElevatedButton.icon(
            onPressed: _completeTournament,
            icon: const Icon(Icons.emoji_events_rounded,
                size: 18),
            label: const Text('Complete Tournament',
                style: TextStyle(fontWeight: FontWeight.w700)),
            style: ElevatedButton.styleFrom(
              backgroundColor: _kOlive,
              foregroundColor: Colors.white,
              padding:
                  const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        const SizedBox(height: 8),

        // Save and Return
        OutlinedButton.icon(
          onPressed: _saveAndReturn,
          icon: const Icon(Icons.arrow_back_rounded, size: 18),
          label: const Text('Save and Return',
              style: TextStyle(fontWeight: FontWeight.w600)),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.black54,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }

  // ── Shared helpers ────────────────────────────────────────────────────────

  Widget _sectionHeader(String title, IconData icon,
          {Widget? trailing}) =>
      Row(children: [
        Icon(icon, size: 15, color: _kOlive),
        const SizedBox(width: 6),
        Text(
          title.toUpperCase(),
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: _kOlive,
            letterSpacing: 0.4,
          ),
        ),
        if (trailing != null) ...[const Spacer(), trailing],
      ]);

  Widget _chip(
          IconData icon, String label, Color bg, Color fg) =>
      Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(20)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 11, color: fg),
          const SizedBox(width: 3),
          Text(label,
              style: TextStyle(
                  fontSize: 11,
                  color: fg,
                  fontWeight: FontWeight.w600)),
        ]),
      );

  Widget _refBtn(
    IconData icon,
    String label,
    VoidCallback onTap, {
    bool enabled = true,
    bool primary = false,
  }) =>
      OutlinedButton.icon(
        onPressed: enabled ? onTap : null,
        icon: Icon(icon, size: 14),
        label: Text(label,
            style: const TextStyle(fontSize: 12)),
        style: OutlinedButton.styleFrom(
          foregroundColor: primary ? Colors.white : _kOlive,
          backgroundColor: primary ? _kOlive : null,
          disabledForegroundColor: Colors.black26,
          padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          side: BorderSide(
              color: primary
                  ? _kOlive
                  : enabled
                      ? Colors.grey.shade300
                      : Colors.grey.shade200),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8)),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      );

  Widget _refTextBtn(String label, VoidCallback onTap) =>
      OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: _kOlive,
          padding: const EdgeInsets.symmetric(
              horizontal: 12, vertical: 6),
          side: BorderSide(color: Colors.grey.shade300),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8)),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: Text(label,
            style: const TextStyle(fontSize: 12)),
      );
}
