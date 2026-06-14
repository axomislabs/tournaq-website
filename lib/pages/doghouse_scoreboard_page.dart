import 'package:flutter/material.dart';
import '../app/app_colors.dart';
import '../l10n/app_localizations.dart';
import '../models/doghouse_drill.dart';
import '../services/doghouse_storage_service.dart';
import '../services/scramble_service.dart';
import '../models/player.dart';
import '../widgets/scramble_timer_widget.dart';
import '../widgets/sheet_helpers.dart';
import '../widgets/tournaq_app_bar.dart';
import 'doghouse_history_page.dart';

const _kGold            = AppColors.goldDark;
const _kGoldDark        = AppColors.gold;
const _kGoldLight       = AppColors.goldCream;
const _kGoldCardBg      = AppColors.goldCardBg;
const _kGoldCardLeading = AppColors.goldCardLeading;
const _kOlive           = AppColors.olive;
const _kOliveLight      = AppColors.oliveLight;

class DoghouseScoreboardPage extends StatefulWidget {
  final DoghouseTournament tournament;
  final List<Player> existingPlayers;
  final void Function(DoghouseTournament) onChanged;

  const DoghouseScoreboardPage({
    super.key,
    required this.tournament,
    required this.existingPlayers,
    required this.onChanged,
  });

  @override
  State<DoghouseScoreboardPage> createState() => _DoghouseScoreboardState();
}

class _DoghouseScoreboardState extends State<DoghouseScoreboardPage> {
  late DoghouseTournament _t;

  // ── Scoring ───────────────────────────────────────────────────────────────
  List<DoghousePlayer> _teamPlayers      = [];
  List<DoghousePlayer> _pendingSelection = [];
  List<DoghousePlayer> _pool             = [];
  int _currentSideOuts  = 0;
  int _currentGamesLost = 0;

  // ── Automated assignment ──────────────────────────────────────────────────
  List<List<DoghousePlayer>> _candidates     = [];
  int                        _candidateIndex = 0;
  List<DoghousePlayer>       _challengerTeam = [];

  // ── Session timer ─────────────────────────────────────────────────────────
  final _sessionTimerKey = GlobalKey<ScrambleTimerWidgetState>();
  bool _timerRunning = false;

  // ── Game stopwatch ────────────────────────────────────────────────────────
  final _gameWatch = Stopwatch();

  // ── Derived ───────────────────────────────────────────────────────────────
  bool get _hasTeam      => _teamPlayers.isNotEmpty;
  bool get _canAddPlayer => _pendingSelection.length < _t.playersPerTeam;
  bool get _canStart     => _pendingSelection.length == _t.playersPerTeam;
  bool get _isCompleted  => _t.status == DoghouseTournamentStatus.completed;
  bool get _canUndo => _t.games.isNotEmpty &&
      (!_hasTeam || _t.assignmentMode == DoghouseAssignmentMode.automated);

  bool get _escapeReached  => _currentSideOuts >= _t.escapePoints;
  bool get _ejectReached   => _currentGamesLost >= _t.lossLimit;

  @override
  void initState() {
    super.initState();
    _t    = widget.tournament;
    _pool = List.from(_t.players);
    _initSuggestion();
  }

  @override
  void dispose() {
    _gameWatch.stop();
    super.dispose();
  }

  // ── Persist ───────────────────────────────────────────────────────────────

  void _persist() {
    DoghouseStorageService.save(_t);
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
          Text(AppLocalizations.of(context)!.doghouseTimeUp,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
        ]),
        content: Text(
          AppLocalizations.of(context)!.doghouseTimerEndedBody,
          style: const TextStyle(fontSize: 14, height: 1.5),
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
              child: Text(AppLocalizations.of(context)!.doghouseCompleteTournament,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
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
              child: Text(AppLocalizations.of(context)!.doghouseContinueScoring,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
    if (end == true && mounted) _completeDrill();
  }

  // ── Team selection ────────────────────────────────────────────────────────

  void _toggleSelection(DoghousePlayer p) {
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
    if (_t.assignmentMode != DoghouseAssignmentMode.automated) return;
    _candidates     = _computeSuggestions();
    _candidateIndex = 0;
  }

  void _recomputeChallenger() {
    if (_t.assignmentMode != DoghouseAssignmentMode.automated || !_hasTeam) return;
    final challengerCands = _computeSuggestions();
    final newChallenger   = challengerCands.isNotEmpty ? challengerCands.first : <DoghousePlayer>[];
    final upNextPool      = _pool
        .where((p) => !newChallenger.any((c) => c.id == p.id))
        .toList();
    _candidates     = _computeSuggestions(fromPool: upNextPool);
    _candidateIndex = 0;
    setState(() => _challengerTeam = newChallenger);
  }

  void _recomputeUpNext() {
    if (_t.assignmentMode != DoghouseAssignmentMode.automated) return;
    final upNextPool = _pool
        .where((p) => !_challengerTeam.any((c) => c.id == p.id))
        .toList();
    setState(() {
      _candidates     = _computeSuggestions(fromPool: upNextPool);
      _candidateIndex = 0;
    });
  }

  void _reroll() {
    if (_candidates.length <= 1) return;
    setState(() =>
        _candidateIndex = (_candidateIndex + 1) % _candidates.length);
  }

  List<DoghousePlayer> get _currentSuggestion =>
      _candidates.isEmpty ? [] : _candidates[_candidateIndex];

  void _confirmSuggestedTeam() {
    final suggested = _currentSuggestion;
    if (suggested.length != _t.playersPerTeam) return;
    _startTeam(suggested);
    _recomputeChallenger();
  }

  void _startTeam(List<DoghousePlayer> players) {
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
      _currentSideOuts  = 0;
      _currentGamesLost = 0;
      _challengerTeam   = [];
    });
  }

  // Returns all possible teams from pool, sorted by best mixup then longest wait.
  List<List<DoghousePlayer>> _computeSuggestions({List<DoghousePlayer>? fromPool}) {
    final pool = fromPool ?? _pool;
    final n    = _t.playersPerTeam;
    if (pool.length < n) return [];

    // Pair repetition counts from game history
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

    // Most-recent game index each player appeared in (null = never played)
    final lastPlayed = <String, int>{};
    for (var i = 0; i < _t.games.length; i++) {
      for (final pid in _t.games[i].playerIds) {
        lastPlayed[pid] = i;
      }
    }
    final totalGames = _t.games.length;

    final combos = _combinations(pool, n);
    combos.sort((a, b) {
      final aPairs = _pairScore(a, pairCounts);
      final bPairs = _pairScore(b, pairCounts);
      if (aPairs != bPairs) return aPairs.compareTo(bPairs);
      // Higher wait = comes first (prefer players who waited longest)
      return _waitScore(b, lastPlayed, totalGames)
          .compareTo(_waitScore(a, lastPlayed, totalGames));
    });
    return combos;
  }

  int _pairScore(List<DoghousePlayer> team, Map<String, int> counts) {
    var score = 0;
    for (var i = 0; i < team.length; i++) {
      for (var j = i + 1; j < team.length; j++) {
        final key = ([team[i].id, team[j].id]..sort()).join(':');
        score += counts[key] ?? 0;
      }
    }
    return score;
  }

  double _waitScore(List<DoghousePlayer> team, Map<String, int> lastPlayed,
      int totalGames) {
    if (team.isEmpty) return 0;
    var total = 0.0;
    for (final p in team) {
      final last = lastPlayed[p.id];
      total += last == null ? totalGames + 1 : totalGames - last;
    }
    return total / team.length;
  }

  List<List<DoghousePlayer>> _combinations(List<DoghousePlayer> items, int k) {
    if (k == 0) return [[]];
    if (items.length < k) return [];
    final result = <List<DoghousePlayer>>[];
    for (var i = 0; i <= items.length - k; i++) {
      for (final rest in _combinations(items.sublist(i + 1), k - 1)) {
        result.add([items[i], ...rest]);
      }
    }
    return result;
  }

  // ── Scoring ───────────────────────────────────────────────────────────────

  void _addSideOut() {
    if (!_hasTeam || _isCompleted) return;
    setState(() => _currentSideOuts++);
    if (_escapeReached) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _showEscapeDialog());
    }
  }

  void _removeSideOut() {
    if (!_hasTeam || _isCompleted || _currentSideOuts <= 0) return;
    setState(() => _currentSideOuts--);
  }

  void _rotateChallengers() {
    if (_t.assignmentMode != DoghouseAssignmentMode.automated) return;
    if (_currentSuggestion.length != _t.playersPerTeam) return;
    setState(() => _challengerTeam = List.from(_currentSuggestion));
    _recomputeUpNext();
  }

  void _addGameLost() {
    if (!_hasTeam || _isCompleted) return;
    if (_currentGamesLost >= _t.lossLimit) return;
    setState(() {
      _currentGamesLost++;
      _currentSideOuts = 0;
    });
    if (_ejectReached) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _showAutoEjectDialog());
    } else {
      // Rotate challengers on every non-ejecting game lost.
      _rotateChallengers();
    }
  }

  void _removeGameLost() {
    if (!_hasTeam || _isCompleted || _currentGamesLost <= 0) return;
    setState(() => _currentGamesLost--);
  }

  // ── End game ──────────────────────────────────────────────────────────────

  void _endGame({required bool escaped}) {
    if (!_hasTeam) return;
    final remaining = _sessionTimerKey.currentState?.remaining;
    final game = DoghouseGame(
      id:        DoghouseGame.generateId(),
      playerIds: _teamPlayers.map((p) => p.id).toList(),
      points:  _currentSideOuts,
      gamesLost: _currentGamesLost,
      gamesWon:  escaped ? 1 : 0,
      startTime: DateTime.now().subtract(_gameWatch.elapsed),
      endTime:   DateTime.now(),
    );

    _t = _t.copyWith(
      status:           DoghouseTournamentStatus.inProgress,
      games:            [..._t.games, game],
      remainingSeconds: remaining?.inSeconds,
    );
    _persist();

    _gameWatch
      ..stop()
      ..reset();

    if (_t.assignmentMode == DoghouseAssignmentMode.automated &&
        _challengerTeam.length == _t.playersPerTeam) {
      // Transition: Challengers → Dogs, Up Next → Challengers, compute new Up Next.
      final nextDogs       = List<DoghousePlayer>.from(_challengerTeam);
      final nextChallenger = List<DoghousePlayer>.from(_currentSuggestion);
      setState(() {
        _teamPlayers      = [];
        _pendingSelection = [];
        _currentSideOuts  = 0;
        _currentGamesLost = 0;
        _challengerTeam   = [];
      });
      _startTeam(nextDogs);
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
        _currentSideOuts  = 0;
        _currentGamesLost = 0;
        _challengerTeam   = [];
      });
      _initSuggestion();
    }
  }

  void _undoEjection() {
    if (!_canUndo) return;
    if (_hasTeam) {
      _gameWatch
        ..stop()
        ..reset();
    }

    final lastGame = _t.games.last;
    final restoredPlayers = lastGame.playerIds
        .map((id) => _t.players.firstWhere(
              (p) => p.id == id,
              orElse: () => DoghousePlayer(
                  id: id, name: '?', source: DoghousePlayerSource.random),
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
      _currentSideOuts  = lastGame.points;
      _currentGamesLost = lastGame.gamesLost;
      _challengerTeam   = [];
    });
    _recomputeChallenger();
  }

  // ── Player swap ───────────────────────────────────────────────────────────

  void _swapPlayer(DoghousePlayer outgoing) {
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
                  Text(AppLocalizations.of(context)!.doghouseSubstitute(outgoing.name),
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text(
                    AppLocalizations.of(context)!.doghouseReturnToQueue(outgoing.name),
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
    final l10n = AppLocalizations.of(context)!;
    final proceed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: Text(l10n.doghouseAddPlayersToQueue,
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.w700)),
        content: Text(
          l10n.doghouseLateTagInfo,
          style: const TextStyle(
              fontSize: 14, color: Colors.black54, height: 1.4),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(l10n.btnCancel)),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: _kOlive,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(l10n.btnStart),
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
            final p = DoghousePlayer(
              id:     DoghousePlayer.generateId(),
              name:   name,
              source: DoghousePlayerSource.created,
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
            final p = DoghousePlayer(
              id:        DoghousePlayer.generateId(),
              name:      name,
              source:    DoghousePlayerSource.existing,
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
              final p = DoghousePlayer(
                id:     DoghousePlayer.generateId(),
                name:   g.name,
                source: DoghousePlayerSource.random,
                isLate: true,
              );
              _t = _t.copyWith(players: [..._t.players, p]);
              _pool.add(p);
            }
            _persist();
            rebuild();
          }

          final latePlayers = _t.players.where((p) => p.isLate).toList();

          return TournaQSheet(
            body: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(children: [
                    Text(AppLocalizations.of(context)!.doghouseAddPlayersToQueue,
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800)),
                    const Spacer(),
                    Text(AppLocalizations.of(context)!.doghouseNAdded(latePlayers.length),
                        style: const TextStyle(
                            color: Colors.black45, fontSize: 13)),
                  ]),
                  const SizedBox(height: 4),
                  Text(
                    AppLocalizations.of(context)!.doghouseLateTagInfo,
                    style: const TextStyle(fontSize: 12, color: Colors.black45),
                  ),
                  const SizedBox(height: 16),

                  Row(children: [
                    Expanded(
                      child: TextField(
                        controller: nameCtrl,
                        textCapitalization: TextCapitalization.words,
                        decoration: InputDecoration(
                          hintText: AppLocalizations.of(context)!.hintPlayerName,
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
                      child: Text(AppLocalizations.of(context)!.btnAdd),
                    ),
                  ]),

                  if (allExisting.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text('${AppLocalizations.of(context)!.pagePlayers} (${allExisting.length})',
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.black54)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: searchCtrl,
                      decoration: InputDecoration(
                        hintText: AppLocalizations.of(context)!.hintSearchPlayers,
                        isDense: true,
                        prefixIcon: const Icon(Icons.search_rounded,
                            size: 18, color: Colors.black45),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                      ),
                      onTap: () => setSheet(() => searchActive = true),
                      onChanged: (_) =>
                          setSheet(() => searchActive = true),
                    ),
                    if (searchActive) ...[
                      const SizedBox(height: 6),
                      if (filtered.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(AppLocalizations.of(context)!.doghouseNoPlayersMatch,
                              style: const TextStyle(
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

                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                          AppLocalizations.of(context)!.doghouseNPlayersAdded(latePlayers.length),
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.black54)),
                      TextButton.icon(
                        onPressed: fillRandom,
                        icon: const Icon(Icons.shuffle_rounded, size: 16),
                        label: Text(AppLocalizations.of(context)!.doghouseAdd4Random),
                        style: TextButton.styleFrom(
                            foregroundColor: _kOlive),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  if (latePlayers.isEmpty)
                    Text(AppLocalizations.of(context)!.doghouseNoLatePlayersYet,
                        style: const TextStyle(
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
                                style: const TextStyle(fontSize: 13)),
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
                              _pool.removeWhere((q) => q.id == p.id);
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

  // ── Dialogs ───────────────────────────────────────────────────────────────

  Widget _lateChip() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.orange.shade100,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          AppLocalizations.of(context)!.labelLate,
          style: TextStyle(
            fontSize: 8,
            fontWeight: FontWeight.w800,
            color: Colors.orange.shade700,
            letterSpacing: 0.4,
          ),
        ),
      );

  Future<void> _showEscapeDialog() async {
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
            child: const Icon(Icons.celebration_rounded,
                color: _kGold, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(AppLocalizations.of(context)!.doghouseEscapedExcl,
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.w800)),
          ),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppLocalizations.of(context)!.doghouseEscapedScoreMsg(names, _t.escapePoints),
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(
              AppLocalizations.of(context)!.doghouseEscapeDesc,
              style: const TextStyle(fontSize: 13, color: Colors.black54),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.logout_rounded, size: 18),
              label: Text(AppLocalizations.of(context)!.doghouseEscapeBtn,
                  style: const TextStyle(fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: _kGold,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                Navigator.of(ctx).pop();
                _endGame(escaped: true);
                if (_timerRunning) _gameWatch.start();
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showAutoEjectDialog() async {
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
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12)),
            child: Icon(Icons.sentiment_very_dissatisfied_rounded,
                color: Colors.red.shade600, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(AppLocalizations.of(context)!.doghouseEjectedExcl,
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.w800)),
          ),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppLocalizations.of(context)!.doghouseEjectedScoreMsg(names, _t.lossLimit),
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(
              AppLocalizations.of(context)!.doghouseEjectDesc,
              style: const TextStyle(fontSize: 13, color: Colors.black54),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.logout_rounded, size: 18),
              label: Text(AppLocalizations.of(context)!.doghouseEjectTeam,
                  style: const TextStyle(fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                Navigator.of(ctx).pop();
                _endGame(escaped: false);
                if (_timerRunning) _gameWatch.start();
              },
            ),
          ),
        ],
      ),
    );
  }

  // ── Drill completion ──────────────────────────────────────────────────────

  void _completeDrill() {
    if (_hasTeam) _endGame(escaped: false);
    _sessionTimerKey.currentState?.pause();
    _gameWatch.stop();
    final remaining = _sessionTimerKey.currentState?.remaining;
    _t = _t.copyWith(
      status:           DoghouseTournamentStatus.completed,
      remainingSeconds: remaining?.inSeconds,
    );
    _persist();
    setState(() => _timerRunning = false);
    _showSummaryDialog().then((_) {
      if (mounted) Navigator.of(context).pop();
    });
  }

  void _undoCompletion() {
    _t = _t.copyWith(status: DoghouseTournamentStatus.inProgress);
    _persist();
    setState(() {});
  }

  Future<void> _saveAndReturn() async {
    if (_hasTeam) {
      final pts = _currentSideOuts;
      final ok  = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          title: Text(AppLocalizations.of(context)!.doghouseLeaveTitle,
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w700)),
          content: Text(
            pts > 0
                ? AppLocalizations.of(context)!.doghouseLeaveBodyPts(pts)
                : AppLocalizations.of(context)!.doghouseLeaveBodyEmpty,
            style: const TextStyle(
                fontSize: 14, color: Colors.black54, height: 1.4),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: Text(AppLocalizations.of(context)!.btnCancel)),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: Text(AppLocalizations.of(context)!.doghouseLeaveAnyway),
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
    final escapesMap  = _t.escapesPerPlayer;
    final lossesMap   = _t.gamesLostPerPlayer;
    final ranked      = _t.players.toList()
      ..sort((a, b) {
        final eDiff =
            (escapesMap[b.id] ?? 0) - (escapesMap[a.id] ?? 0);
        if (eDiff != 0) return eDiff;
        return (lossesMap[a.id] ?? 0) - (lossesMap[b.id] ?? 0);
      });

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: Row(children: [
          const Icon(Icons.pets_rounded, color: _kGold, size: 24),
          const SizedBox(width: 8),
          Text(AppLocalizations.of(context)!.doghouseTournamentComplete,
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w800)),
        ]),
        content: SizedBox(
          width: 280,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context)!.doghouseSummaryStats(_t.gameCount, _t.totalEscapes),
                style: const TextStyle(
                    fontSize: 13, color: Colors.black45),
              ),
              const SizedBox(height: 12),
              Text(AppLocalizations.of(context)!.doghouseFinalStandings,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.black54)),
              const SizedBox(height: 6),
              ...ranked.map((p) {
                final escapes = escapesMap[p.id] ?? 0;
                final losses  = lossesMap[p.id] ?? 0;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(children: [
                    Expanded(
                        child: Text(p.name,
                            style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600))),
                    Text(
                      AppLocalizations.of(context)!.doghousePairStat(escapes, losses),
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
            child: Text(AppLocalizations.of(context)!.btnDone,
                style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  // ── Stats sheet ───────────────────────────────────────────────────────────

  void _openStats() {
    final escapesMap = _t.escapesPerPlayer;
    final lossesMap  = _t.gamesLostPerPlayer;
    final soMap      = _t.pointsPerPlayer;
    final playedMap  = _t.gamesPerPlayer;
    final ranked     = _t.players.toList()
      ..sort((a, b) {
        final eDiff =
            (escapesMap[b.id] ?? 0) - (escapesMap[a.id] ?? 0);
        if (eDiff != 0) return eDiff;
        return (lossesMap[a.id] ?? 0) - (lossesMap[b.id] ?? 0);
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
              Text(AppLocalizations.of(context)!.doghousePlayerStats,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text(
                AppLocalizations.of(context)!.doghouseSummaryStats(_t.gameCount, _t.totalEscapes),
                style: const TextStyle(
                    fontSize: 13, color: Colors.black45),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 4),
                child: Row(children: [
                  const SizedBox(width: 28),
                  Expanded(
                      child: Text(AppLocalizations.of(context)!.filterPlayer,
                          style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.black45))),
                  SizedBox(
                    width: 44,
                    child: Text(AppLocalizations.of(context)!.statGames,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.black45)),
                  ),
                  SizedBox(
                    width: 44,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.celebration_rounded,
                            size: 11, color: Colors.black45),
                        const SizedBox(width: 2),
                        Text(AppLocalizations.of(context)!.statEsc,
                            style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Colors.black45)),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 40,
                    child: Text(AppLocalizations.of(context)!.statLost,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.black45)),
                  ),
                  SizedBox(
                    width: 40,
                    child: Text(AppLocalizations.of(context)!.statPts,
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.black45)),
                  ),
                ]),
              ),
              ...ranked.asMap().entries.map((entry) {
                final i       = entry.key;
                final p       = entry.value;
                final played  = playedMap[p.id] ?? 0;
                final escapes = escapesMap[p.id] ?? 0;
                final losses  = lossesMap[p.id] ?? 0;
                final sos     = soMap[p.id] ?? 0;
                final isTop   = i == 0 && escapes > 0;
                return Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: isTop ? _kGoldLight : Colors.grey.shade50,
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
                      width: 44,
                      child: Text('$escapes',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: escapes > 0
                                  ? _kGold
                                  : Colors.black38)),
                    ),
                    SizedBox(
                      width: 40,
                      child: Text('$losses',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: losses > 0
                                  ? Colors.red.shade400
                                  : Colors.black38)),
                    ),
                    SizedBox(
                      width: 40,
                      child: Text('$sos',
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

  // ── Options sheet ─────────────────────────────────────────────────────────

  void _showOptions() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetCtx) => TournaQSheet(
        body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(AppLocalizations.of(context)!.labelOptions,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 8),
                leading: Container(
                  width: 40, height: 40,
                  decoration: const BoxDecoration(
                      color: _kGoldLight, shape: BoxShape.circle),
                  child: const Icon(Icons.history_rounded,
                      color: _kGold, size: 20),
                ),
                title: Text(AppLocalizations.of(context)!.doghouseGameHistory,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(AppLocalizations.of(context)!.doghouseViewAllGames,
                    style: const TextStyle(
                        fontSize: 12, color: Colors.black45)),
                onTap: () {
                  Navigator.of(sheetCtx).pop();
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) =>
                        DoghouseHistoryPage(tournament: _t),
                  ));
                },
              ),
            ],
          ),
        ),
      ),
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

    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: TournaQAppBar(
        title: l10n.doghouseTitle,
        subtitle: l10n.doghouseScoreboard,
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart_rounded,
                color: _kGoldCardBg),
            tooltip: l10n.doghousePlayerStats,
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
    final l10n = AppLocalizations.of(context)!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _sectionHeader(
            l10n.doghouseGameplayControls,
            Icons.sports_volleyball_rounded,
            trailing: optionsButton,
          ),
          const SizedBox(height: 10),
          _buildSessionTimerRow(),
          const SizedBox(height: 10),
          if (_isCompleted)
            _buildCompletedBanner()
          else if (_hasTeam && _t.assignmentMode == DoghouseAssignmentMode.automated) ...[
            // Three-slot automated layout: Up Next → Challengers → Dogs
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
                  Expanded(flex: 1, child: _buildNarrowGameLostButton()),
                ],
              ),
            ),
          ] else if (_hasTeam)
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(flex: 4, child: _buildActiveScoringTile()),
                  const SizedBox(width: 8),
                  Expanded(flex: 1, child: _buildNarrowGameLostButton()),
                ],
              ),
            )
          else
            _buildSelectionTile(),
          if (_canUndo) ...[
            const SizedBox(height: 10),
            _buildUndoButton(),
          ],
          const SizedBox(height: 24),
          _sectionHeader(l10n.doghouseMatchControls, Icons.pets_rounded),
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
              _refBtn(Icons.pause_rounded, AppLocalizations.of(context)!.btnStop, _pauseTimer),
              const SizedBox(width: 4),
              _refBtn(Icons.replay_rounded, AppLocalizations.of(context)!.doghouseStartRestart,
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
          Expanded(
            child: _hasTeam && _t.assignmentMode == DoghouseAssignmentMode.automated
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
                      // Column 2: Dogs + Score
                      Expanded(
                        flex: 3,
                        child: _buildActiveScoringTile(compact: true),
                      ),
                      const SizedBox(width: 6),
                      // Column 3: Game Lost (2/3) + Undo (1/3) when available
                      SizedBox(
                        width: 64,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              flex: _canUndo ? 2 : 1,
                              child: _buildNarrowGameLostButton(),
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
                                ? _buildNarrowGameLostButton()
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

  // ── Narrow buttons ────────────────────────────────────────────────────────

  Widget _buildNarrowGameLostButton() {
    final atCap    = _currentGamesLost >= _t.lossLimit;
    final nearEject = _currentGamesLost >=
        (_t.lossLimit - 1).clamp(0, _t.lossLimit);
    final canAdd   = _hasTeam && !_isCompleted && !atCap;
    final canUndo  = _hasTeam && !_isCompleted && _currentGamesLost > 0;
    final bgColor  = nearEject ? Colors.red.shade600 : Colors.grey.shade700;

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Material(
        color: bgColor,
        child: Column(
          children: [
            // ── Main area: tap to add game lost ──────────────────────────
            Expanded(
              child: InkWell(
                onTap: canAdd ? _addGameLost : null,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.sentiment_very_dissatisfied_rounded,
                          size: 26,
                          color: Colors.white
                              .withValues(alpha: canAdd ? 1.0 : 0.5),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '$_currentGamesLost / ${_t.lossLimit}',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                              color: Colors.white
                                  .withValues(alpha: canAdd ? 1.0 : 0.6),
                              height: 1.2),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          AppLocalizations.of(context)!.doghouseGameLost,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                              color: Colors.white
                                  .withValues(alpha: canAdd ? 0.85 : 0.45)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // ── Divider ──────────────────────────────────────────────────
            Container(
              height: 1,
              color: Colors.white.withValues(alpha: 0.2),
            ),

            // ── Undo strip: tap to remove one game lost ──────────────────
            InkWell(
              onTap: canUndo ? _removeGameLost : null,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 9),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.undo_rounded,
                      size: 16,
                      color: Colors.white
                          .withValues(alpha: canUndo ? 0.9 : 0.3),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      AppLocalizations.of(context)!.btnUndo,
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.white
                              .withValues(alpha: canUndo ? 0.9 : 0.3)),
                    ),
                  ],
                ),
              ),
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.undo_rounded, size: 28),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context)!.doghouseUndoGame,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUndoButton() {
    return OutlinedButton.icon(
      onPressed: _undoEjection,
      icon: const Icon(Icons.undo_rounded, size: 18),
      label: Text(AppLocalizations.of(context)!.doghouseUndoLastGame,
          style: const TextStyle(fontWeight: FontWeight.w600)),
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
            const Icon(Icons.timer_rounded, size: 14, color: _kOlive),
            const SizedBox(width: 6),
            Text(
              AppLocalizations.of(context)!.doghouseSessionTimer,
              style: const TextStyle(
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
              _refBtn(Icons.pause_rounded, AppLocalizations.of(context)!.btnStop, _pauseTimer),
              _refBtn(Icons.replay_rounded, AppLocalizations.of(context)!.doghouseStartRestart,
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

  // ── Scoring tiles ─────────────────────────────────────────────────────────

  Widget _buildScoringTile({bool compact = false}) {
    if (_isCompleted) return _buildCompletedBanner();
    return _hasTeam
        ? _buildActiveScoringTile(compact: compact)
        : _buildSelectionTile(compact: compact);
  }

  Widget _buildCompletedBanner() {
    final escapesMap = _t.escapesPerPlayer;
    final ranked     = _t.players.toList()
      ..sort((a, b) =>
          (escapesMap[b.id] ?? 0) - (escapesMap[a.id] ?? 0));
    final leader = ranked.isNotEmpty ? ranked.first : null;
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _kGoldLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kGold.withValues(alpha: 0.4)),
      ),
      child: Row(children: [
        const Icon(Icons.lock_rounded,
            size: 16, color: Colors.black54),
        const SizedBox(width: 8),
        Expanded(
            child: Text(AppLocalizations.of(context)!.doghouseTournamentCompleted,
                style: const TextStyle(
                    fontSize: 13,
                    color: Colors.black54,
                    fontWeight: FontWeight.w500))),
        if (leader != null && (escapesMap[leader.id] ?? 0) > 0)
          Text(
            '${escapesMap[leader.id]} 🎉 ${leader.name}',
            style: const TextStyle(
                fontSize: 12,
                color: _kGold,
                fontWeight: FontWeight.w700),
          ),
      ]),
    );
  }

  // ── Up Next tile ────────────────────────────────────────────────────────────

  Widget _buildUpNextTile({bool compact = false}) {
    final team      = _currentSuggestion;
    final hasTeam   = team.length == _t.playersPerTeam;
    final canReroll = _candidates.length > 1;

    return Card(
      margin: compact ? EdgeInsets.zero : null,
      color: _kGoldLight,
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: _kGold.withValues(alpha: 0.35)),
      ),
      child: Padding(
        padding: EdgeInsets.all(compact ? 10 : 14),
        child: Column(
          mainAxisSize: compact ? MainAxisSize.max : MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(children: [
              Icon(Icons.schedule_rounded,
                  size: 15, color: _kGold.withValues(alpha: 0.7)),
              const SizedBox(width: 6),
              Text('Up Next',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _kGold.withValues(alpha: 0.7),
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
                      color: _kGold.withValues(alpha: 0.5), fontSize: 12))
            else
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: team
                    .map((p) => Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: _kGold.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: _kGold.withValues(alpha: 0.3)),
                          ),
                          child: Text(p.name,
                              style: TextStyle(
                                  fontSize: compact ? 11 : 13,
                                  fontWeight: FontWeight.w600,
                                  color: _kGold.withValues(alpha: 0.8))),
                        ))
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }

  // ── Challengers tile ────────────────────────────────────────────────────────

  Widget _buildChallengersTile({bool compact = false}) {
    final hasChallengers = _challengerTeam.length == _t.playersPerTeam;

    return Card(
      margin: compact ? EdgeInsets.zero : null,
      color: _kGoldCardBg,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: _kGold.withValues(alpha: 0.55), width: 1.5),
      ),
      child: Padding(
        padding: EdgeInsets.all(compact ? 10 : 14),
        child: Column(
          mainAxisSize: compact ? MainAxisSize.max : MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(children: [
              const Icon(Icons.groups_rounded, size: 15, color: _kGold),
              const SizedBox(width: 6),
              const Text('Challengers',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _kGold,
                    letterSpacing: 0.4,
                  )),
            ]),
            const SizedBox(height: 8),
            if (!hasChallengers)
              Text('Waiting for players...',
                  style: TextStyle(
                      color: _kGold.withValues(alpha: 0.5), fontSize: 12))
            else
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: _challengerTeam
                    .map((p) => Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: _kGold.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: _kGold.withValues(alpha: 0.5)),
                          ),
                          child: Text(p.name,
                              style: TextStyle(
                                  fontSize: compact ? 11 : 13,
                                  fontWeight: FontWeight.w700,
                                  color: _kGold)),
                        ))
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }

  // ── Initial suggested-team tile (shown before any Dogs team is on court) ────

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
                AppLocalizations.of(context)!.doghouseSuggestedTeam,
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
                label: Text(AppLocalizations.of(context)!.quickStartReRoll,
                    style: const TextStyle(fontSize: 12)),
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
              Text(AppLocalizations.of(context)!.doghouseNotEnoughInQueue,
                  style: const TextStyle(color: Colors.black38, fontSize: 13)),
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
              label: Text(AppLocalizations.of(context)!.doghouseEnterDoghouse,
                  style: const TextStyle(fontWeight: FontWeight.w700)),
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
    if (_t.assignmentMode == DoghouseAssignmentMode.automated) {
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
                AppLocalizations.of(context)!.doghouseSelectPlayers(needed, selected),
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
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(p.name,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
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
              Text(AppLocalizations.of(context)!.doghouseQueueTapToAdd,
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
                    onTap: full ? null : () => _toggleSelection(p),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: compact ? 10 : 14,
                          vertical: compact ? 6 : 10),
                      decoration: BoxDecoration(
                        color: full
                            ? Colors.grey.shade100
                            : _kOliveLight,
                        borderRadius: BorderRadius.circular(20),
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
              label: Text(AppLocalizations.of(context)!.doghouseEnterDoghouse,
                  style: const TextStyle(fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: _kGold,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey.shade200,
                padding:
                    const EdgeInsets.symmetric(vertical: 12),
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
    final nearEscape = _currentSideOuts >=
        (_t.escapePoints - 1).clamp(0, _t.escapePoints);
    final cardBg =
        nearEscape ? _kGoldCardLeading : _kGoldCardBg;

    final elapsed   = _gameWatch.elapsed;
    final gameMin   = elapsed.inMinutes.toString().padLeft(2, '0');
    final gameSec   =
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
            // "In Doghouse" label — only shown in three-slot automated layout
            if (_t.assignmentMode == DoghouseAssignmentMode.automated) ...[
              Row(children: [
                const Icon(Icons.pets_rounded, size: 13, color: _kGold),
                const SizedBox(width: 5),
                const Text('In Doghouse',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: _kGold,
                      letterSpacing: 0.4,
                    )),
              ]),
              const SizedBox(height: 6),
            ],
            // Player chips
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
                                color:
                                    _kGold.withValues(alpha: 0.5)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(p.name,
                                  style: const TextStyle(
                                      color: _kGoldDark,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13)),
                              if (_pool.isNotEmpty) ...[
                                const SizedBox(width: 4),
                                Icon(Icons.swap_horiz_rounded,
                                    size: 11,
                                    color: _kGold.withValues(
                                        alpha: 0.6)),
                              ],
                            ],
                          ),
                        ),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 8),

            // Game time + escape + games lost indicators
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
                  )),
              const Spacer(),
              // Escape progress
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: nearEscape
                      ? _kGold.withValues(alpha: 0.2)
                      : Colors.black.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.celebration_rounded,
                        size: 11,
                        color: nearEscape ? _kGold : Colors.black45),
                    const SizedBox(width: 2),
                    Text(
                        '$_currentSideOuts / ${_t.escapePoints}',
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: nearEscape
                                ? _kGold
                                : Colors.black54)),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              // Games lost indicator
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _currentGamesLost > 0
                      ? Colors.red.withValues(alpha: 0.10)
                      : Colors.black.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.sentiment_very_dissatisfied_rounded,
                        size: 11,
                        color: _currentGamesLost > 0
                            ? Colors.red.shade500
                            : Colors.black45),
                    const SizedBox(width: 2),
                    Text(
                        '$_currentGamesLost / ${_t.lossLimit}',
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: _currentGamesLost > 0
                                ? Colors.red.shade500
                                : Colors.black54)),
                  ],
                ),
              ),
            ]),

            // Big side-out score — fills available height in compact/landscape.
            if (compact)
              Expanded(
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.contain,
                    child: Text(
                      '$_currentSideOuts',
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
                '$_currentSideOuts',
                style: const TextStyle(
                  fontSize: 96.0,
                  fontWeight: FontWeight.bold,
                  height: 1.0,
                  color: Colors.black87,
                ),
              ),

            // +/- buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton.filled(
                  icon: const Icon(Icons.remove),
                  tooltip: '−1 side-out',
                  onPressed:
                      (_timerRunning && _currentSideOuts > 0)
                          ? _removeSideOut
                          : null,
                  style: IconButton.styleFrom(
                    backgroundColor:
                        (_timerRunning && _currentSideOuts > 0)
                            ? _kGold
                            : Colors.grey.shade300,
                    foregroundColor:
                        (_timerRunning && _currentSideOuts > 0)
                            ? Colors.white
                            : Colors.grey,
                    fixedSize: const Size(52, 52),
                  ),
                ),
                IconButton.filled(
                  icon: const Icon(Icons.add),
                  tooltip: '+1 side-out',
                  onPressed:
                      _timerRunning ? _addSideOut : null,
                  style: IconButton.styleFrom(
                    backgroundColor: _timerRunning
                        ? _kGold
                        : Colors.grey.shade300,
                    foregroundColor: _timerRunning
                        ? Colors.white
                        : Colors.grey,
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
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            _chip(Icons.pets_rounded, _t.name, _kOliveLight, _kOlive),
            _chip(Icons.grid_view_rounded,
                '${_t.playersPerTeam}v${_t.playersPerTeam}',
                Colors.grey.shade100, Colors.black45),
            _chip(Icons.people_rounded,
                AppLocalizations.of(context)!.doghouseStatsPlayers(_t.playerCount),
                Colors.grey.shade100, Colors.black45),
            _chip(Icons.celebration_rounded,
                AppLocalizations.of(context)!.doghouseEscapePointsLabel(_t.escapePoints),
                _kGoldLight, _kGold),
            _chip(Icons.sentiment_very_dissatisfied_rounded,
                AppLocalizations.of(context)!.doghouseLossLimitLabel(_t.lossLimit),
                Colors.red.shade50, Colors.red.shade400),
          ],
        ),
        const SizedBox(height: 12),

        OutlinedButton.icon(
          onPressed: _isCompleted ? null : _showAddPlayerToQueue,
          icon: const Icon(Icons.person_add_rounded, size: 18),
          label: Text(AppLocalizations.of(context)!.doghouseAddPlayerToQueue,
              style: const TextStyle(fontWeight: FontWeight.w600)),
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

        if (_isCompleted)
          OutlinedButton.icon(
            onPressed: _undoCompletion,
            icon: const Icon(Icons.undo_rounded, size: 18),
            label: Text(AppLocalizations.of(context)!.doghouseUndoCompletion,
                style: const TextStyle(fontWeight: FontWeight.w600)),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.black54,
              side: BorderSide(color: Colors.grey.shade300),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          )
        else
          ElevatedButton.icon(
            onPressed: _completeDrill,
            icon: const Icon(Icons.pets_rounded, size: 18),
            label: Text(AppLocalizations.of(context)!.doghouseCompleteTournament,
                style: const TextStyle(fontWeight: FontWeight.w700)),
            style: ElevatedButton.styleFrom(
              backgroundColor: _kOlive,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        const SizedBox(height: 8),

        OutlinedButton.icon(
          onPressed: _saveAndReturn,
          icon: const Icon(Icons.arrow_back_rounded, size: 18),
          label: Text(AppLocalizations.of(context)!.doghouseSaveAndReturn,
              style: const TextStyle(fontWeight: FontWeight.w600)),
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

  Widget _chip(IconData icon, String label, Color bg, Color fg) =>
      Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
            color: bg, borderRadius: BorderRadius.circular(20)),
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
        label: Text(label, style: const TextStyle(fontSize: 12)),
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
        child:
            Text(label, style: const TextStyle(fontSize: 12)),
      );
}
