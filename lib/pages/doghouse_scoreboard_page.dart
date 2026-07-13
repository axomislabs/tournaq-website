import 'package:flutter/material.dart';
import '../app/app_colors.dart';
import '../l10n/app_localizations.dart';
import '../models/doghouse_drill.dart';
import '../models/player_status.dart';
import '../services/fair_rotation_picker.dart';
import '../services/challenger_eject_state.dart';
import '../widgets/admin_rotation_tile.dart';
import '../widgets/challenger_eject_column.dart';
import '../widgets/editable_info_chip.dart';
import '../widgets/info_chip_sheets.dart';
import '../widgets/player_picker_sheet.dart';
import '../widgets/session_timer_persistence_mixin.dart';
import '../widgets/tournament_player_row.dart';
import '../models/group.dart';
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
  final List<Group> existingGroups;
  final void Function(DoghouseTournament) onChanged;
  final Player Function(String name)? onCreatePlayer;

  const DoghouseScoreboardPage({
    super.key,
    required this.tournament,
    required this.existingPlayers,
    this.existingGroups = const [],
    required this.onChanged,
    this.onCreatePlayer,
  });

  @override
  State<DoghouseScoreboardPage> createState() => _DoghouseScoreboardState();
}

class _DoghouseScoreboardState extends State<DoghouseScoreboardPage>
    with WidgetsBindingObserver, SessionTimerPersistenceMixin {
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

  // ── Admin (automatedAllPlay only) ─────────────────────────────────────────
  String? _adminPlayerId;
  String? _nextAdminPlayerId;

  // ── Challenger ejection undo (session-only; ejecting a challenger commits
  // no DoghouseGame, so it can't ride the games-list-based undo below) ──────
  final _challengerEject = ChallengerEjectState<DoghousePlayer>();

  // ── Session timer ─────────────────────────────────────────────────────────
  final _sessionTimerKey = GlobalKey<ScrambleTimerWidgetState>();

  // ── Game stopwatch ────────────────────────────────────────────────────────
  final _gameWatch = Stopwatch();

  // ── Derived ───────────────────────────────────────────────────────────────
  bool get _hasTeam      => _teamPlayers.isNotEmpty;
  bool get _canAddPlayer => _pendingSelection.length < _t.playersPerTeam;
  bool get _canStart     => _pendingSelection.length == _t.playersPerTeam;
  bool get _isCompleted  => _t.status == DoghouseTournamentStatus.completed;
  bool get _isAllPlay  => _t.assignmentMode == DoghouseAssignmentMode.automatedAllPlay;
  bool get _isAutoMode => _t.assignmentMode == DoghouseAssignmentMode.automated || _isAllPlay;
  bool get _canUndo => _t.games.isNotEmpty && (!_hasTeam || _isAutoMode);

  bool get _escapeReached  => _currentSideOuts >= _t.escapePoints;
  bool get _ejectReached   => _currentGamesLost >= _t.lossLimit;

  // Pool available for suggestions — excludes current admin in automatedAllPlay.
  List<DoghousePlayer> get _activePool => _isAllPlay && _adminPlayerId != null
      ? _pool.where((p) => p.id != _adminPlayerId).toList()
      : _pool;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _t    = widget.tournament;
    final activePlayers = _t.players.where((p) => p.isActive).toList();
    _pool = List.from(activePlayers);
    if (_isAllPlay && activePlayers.isNotEmpty) {
      _adminPlayerId = _pickFairestAdmin(activePlayers)?.id;
    }
    _initSuggestion();
    restoreTimer();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _gameWatch.stop();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) =>
      handleTimerLifecycleChange(state);

  // ── Session timer persistence adapter (SessionTimerPersistenceMixin) ──────

  @override
  GlobalKey<ScrambleTimerWidgetState> get sessionTimerKey => _sessionTimerKey;
  @override
  Duration get sessionTotalDuration => _t.totalTime;
  @override
  int? get sessionRemainingSecondsSnapshot => _t.remainingSeconds;
  @override
  DateTime? get sessionTimerAnchorSnapshot => _t.timerAnchor;
  @override
  bool get sessionIsCompleted => _isCompleted;

  @override
  void applySessionTimerSnapshot({
    int? remainingSeconds,
    DateTime? timerAnchor,
    bool clearTimerAnchor = false,
  }) {
    _t = _t.copyWith(
      remainingSeconds: remainingSeconds,
      timerAnchor: timerAnchor,
      clearTimerAnchor: clearTimerAnchor,
    );
    _persist();
  }

  @override
  void onSessionTimerRunningChanged(bool running) {
    if (running) {
      if (_hasTeam) _gameWatch.start();
    } else {
      _gameWatch.stop();
    }
  }

  // ── Persist ───────────────────────────────────────────────────────────────

  void _persist() {
    DoghouseStorageService.save(_t);
    widget.onChanged(_t);
  }

  // ── Timer control ─────────────────────────────────────────────────────────

  void _startOrRestart() {
    if (_isCompleted) return;
    _gameWatch.reset();
    startOrRestartTimer();
  }

  Future<void> _onSessionFinished() async {
    markSessionTimerStopped();
    applySessionTimerSnapshot(remainingSeconds: 0, clearTimerAnchor: true);
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
    if (!_isAutoMode) return;
    _candidates     = _computeSuggestions(fromPool: _activePool);
    _candidateIndex = 0;
  }

  // Picks the least-used scorekeeper from [candidates] so admin duty is shared
  // evenly over the session; ties broken by longest-since-last, then random.
  // Counts are derived from persisted DoghouseGame.adminPlayerId, so they
  // survive navigation/restart and self-correct on undo.
  DoghousePlayer? _pickFairestAdmin(Iterable<DoghousePlayer> candidates) {
    final list = candidates.toList();
    final id = FairRotationPicker.pickFairest(
        list.map((p) => p.id), _t.games.map((g) => g.adminPlayerId).toList());
    if (id == null) return null;
    return list.firstWhere((p) => p.id == id);
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
      if (_nextAdminPlayerId == null) {
        // Successor = fairest off-court player who won't be pulled onto court
        // next (exclude the incoming doghouse team and the up-next challenger);
        // fall back to any off-court player, then the just-played team.
        final incomingDoghouse = _challengerTeam.map((p) => p.id).toSet();
        final incomingChallenger = _currentSuggestion.map((p) => p.id).toSet();
        final eligible = _pool
            .where((p) => p.id != _adminPlayerId && !incomingDoghouse.contains(p.id))
            .toList();
        final preferred = eligible
            .where((p) => !incomingChallenger.contains(p.id))
            .toList();
        final pick = _pickFairestAdmin(preferred.isNotEmpty
            ? preferred
            : (eligible.isNotEmpty ? eligible : _teamPlayers));
        if (pick != null) {
          setState(() => _nextAdminPlayerId = pick.id);
        }
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
    final newChallenger   = challengerCands.isNotEmpty ? challengerCands.first : <DoghousePlayer>[];
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
    var startedTimer = false;
    if (s != null && s.timerState == ScrambleTimerState.idle) {
      s.start();
      startedTimer = true;
      noteTimerStartedExternally();
    }
    _gameWatch
      ..reset()
      ..start();
    setState(() {
      _teamPlayers      = List.from(players);
      _pool             = _t.players
          .where((p) => p.isActive && !players.any((s) => s.id == p.id))
          .toList();
      _pendingSelection = [];
      _currentSideOuts  = 0;
      _currentGamesLost = 0;
      _challengerTeam   = [];
    });
    if (startedTimer) persistTimerState();
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

  // ── Challenger ejection (queued, not-yet-on-court team) ───────────────────
  // Distinct from _endGame: no DoghouseGame is recorded, since the challenger
  // never actually played. We promote the already-displayed Up Next team into
  // the Challenger slot (rather than re-ranking the pool, which would
  // deterministically re-select the same team we just ejected).

  bool get _canEjectChallenger =>
      _isAutoMode &&
      _challengerTeam.length == _t.playersPerTeam &&
      _currentSuggestion.length == _t.playersPerTeam;

  bool get _canUndoEjectChallenger => _challengerEject.canUndo;

  void _ejectChallenger() {
    if (!_canEjectChallenger) return;
    final promoted = _challengerEject.eject(
        current: _challengerTeam,
        promoted: _currentSuggestion,
        teamSize: _t.playersPerTeam);
    if (promoted == null) return; // no full alternate to bring in
    setState(() => _challengerTeam = promoted);
    // Rebuild Up Next from the pool minus the new challenger. The ejected team
    // stays in the pool and is eligible to reappear as Up Next, so repeated
    // ejects cycle between teams (challengers can change at any time).
    _recomputeUpNext();
  }

  void _undoEjectChallenger() {
    final restored = _challengerEject.undo();
    if (restored == null) return;
    setState(() => _challengerTeam = restored);
    _recomputeUpNext();
  }

  // ── Mid-game config edits (assignment mode / escape points / loss limit /
  // team size) ────────────────────────────────────────────────────────────

  void _changeAssignmentMode(DoghouseAssignmentMode mode) {
    if (mode == _t.assignmentMode) return;
    setState(() {
      _t = _t.copyWith(assignmentMode: mode);
      _challengerEject.clear();
      _pendingSelection = [];
      if (mode == DoghouseAssignmentMode.automatedAllPlay) {
        // Scorekeeper must come from OFF-court players (the pool), never
        // someone already on court — mirrors the admin/handoff design.
        if (_adminPlayerId == null && _pool.isNotEmpty) {
          _adminPlayerId = _pickFairestAdmin(_pool)?.id;
        }
      } else {
        _adminPlayerId     = null;
        _nextAdminPlayerId = null;
      }
      if (!_isAutoMode) {
        _challengerTeam = [];
        _candidates     = [];
        _candidateIndex = 0;
      }
    });
    // Rebuild suggestions now that _t (and the admin exclusion) reflect the
    // new mode. Guards inside these helpers no-op outside auto mode.
    if (_isAutoMode) {
      if (_hasTeam) {
        _recomputeChallenger();
      } else {
        setState(_initSuggestion);
      }
    }
    _persist();
  }

  void _changeEscapePoints(int value) {
    final v = value.clamp(1, 999);
    if (v == _t.escapePoints) return;
    setState(() => _t = _t.copyWith(escapePoints: v));
    _persist();
    if (_hasTeam && !_isCompleted && _escapeReached) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _showEscapeDialog());
    }
  }

  void _changeLossLimit(int value) {
    final v = value.clamp(1, 999);
    if (v == _t.lossLimit) return;
    setState(() => _t = _t.copyWith(lossLimit: v));
    _persist();
    if (_hasTeam && !_isCompleted && _ejectReached) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _showAutoEjectDialog());
    }
  }

  void _changeTeamSize(int n) {
    final v = n.clamp(2, 6);
    if (v == _t.playersPerTeam) return;
    setState(() => _t = _t.copyWith(playersPerTeam: v));
    // Applies to future teams only: the team in the doghouse keeps its size
    // until it next rotates out. Rebuild challenger / Up Next at the new size.
    if (_isAutoMode) {
      if (_hasTeam) {
        _recomputeChallenger();
      } else {
        setState(_initSuggestion);
      }
    }
    _persist();
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
    }
  }

  void _removeGameLost() {
    if (!_hasTeam || _isCompleted || _currentGamesLost <= 0) return;
    setState(() => _currentGamesLost--);
  }

  // ── End game ──────────────────────────────────────────────────────────────

  void _endGame({required bool escaped}) {
    if (!_hasTeam) return;
    final game = DoghouseGame(
      id:        DoghouseGame.generateId(),
      playerIds: _teamPlayers.map((p) => p.id).toList(),
      points:  _currentSideOuts,
      gamesLost: _currentGamesLost,
      gamesWon:  escaped ? 1 : 0,
      startTime: DateTime.now().subtract(_gameWatch.elapsed),
      endTime:   DateTime.now(),
      adminPlayerId: _isAllPlay ? _adminPlayerId : null,
    );

    _t = _t.copyWith(
      status: DoghouseTournamentStatus.inProgress,
      games:  [..._t.games, game],
    );
    // Snapshot + re-anchor the session timer (it keeps running through an eject).
    persistTimerState();

    _gameWatch
      ..stop()
      ..reset();

    if (_isAutoMode && _challengerTeam.length == _t.playersPerTeam) {
      // Transition: Challengers → Doghouse, Up Next → Challengers, compute new Up Next.
      final nextDoghouse   = List<DoghousePlayer>.from(_challengerTeam);
      final nextChallenger = List<DoghousePlayer>.from(_currentSuggestion);
      // Hand off admin before starting next team so _activePool excludes the new admin.
      if (_isAllPlay && _nextAdminPlayerId != null) {
        _adminPlayerId     = _nextAdminPlayerId;
        _nextAdminPlayerId = null;
      }
      setState(() {
        _teamPlayers      = [];
        _pendingSelection = [];
        _currentSideOuts  = 0;
        _currentGamesLost = 0;
        _challengerTeam   = [];
        _challengerEject.clear();
      });
      _startTeam(nextDoghouse);
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
        _pool             = List.from(_t.players.where((p) => p.isActive));
        _pendingSelection = [];
        _currentSideOuts  = 0;
        _currentGamesLost = 0;
        _challengerTeam   = [];
        _challengerEject.clear();
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
    if (timerRunning) _gameWatch.start();

    setState(() {
      _teamPlayers      = restoredPlayers;
      _pool             = _t.players
          .where((p) => p.isActive && !restoredPlayers.any((r) => r.id == p.id))
          .toList();
      _pendingSelection = [];
      _currentSideOuts  = lastGame.points;
      _currentGamesLost = lastGame.gamesLost;
      _challengerTeam   = [];
      _challengerEject.clear();
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
                    if (incoming.status != PlayerStatus.active) ...[
                      const SizedBox(width: 6),
                      PlayerStatusChip(incoming.status),
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

  void _showLatePlayersSheet({bool isReplacement = false, String? outgoingName}) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) {
          final l10n = AppLocalizations.of(context)!;
          final playerStatus = isReplacement ? PlayerStatus.swappedIn : PlayerStatus.late;

          void rebuild() {
            setSheet(() {});
            setState(() {});
            _recomputeUpNext();
          }

          final latePlayers = _t.players
              .where((p) =>
                  p.status == PlayerStatus.late ||
                  p.status == PlayerStatus.swappedIn)
              .toList();

          return PlayerPickerSheet(
            title: isReplacement
                ? l10n.overviewSwapTitle(outgoingName ?? '')
                : l10n.doghouseAddPlayersToQueue,
            subtitle: isReplacement
                ? l10n.overviewSwapSubtitle(outgoingName ?? '')
                : l10n.overviewAddPlayerSubtitle,
            existingPlayers: widget.existingPlayers,
            existingGroups: widget.existingGroups,
            alreadyInIds: {
              for (final p in _t.players)
                if (p.appUserId != null) p.appUserId!,
            },
            nameHint: l10n.hintPlayerName,
            onCreateByName: (name) async {
              final globalPlayer = widget.onCreatePlayer?.call(name);
              final p = DoghousePlayer(
                id:        DoghousePlayer.generateId(),
                name:      name,
                source:    globalPlayer != null
                    ? DoghousePlayerSource.existing
                    : DoghousePlayerSource.created,
                appUserId: globalPlayer?.id,
                status:    playerStatus,
              );
              _t = _t.copyWith(players: [..._t.players, p]);
              _persist();
              _pool.add(p);
              rebuild();
              return false;
            },
            onAddExisting: (appUserId, name) async {
              final alreadyIn = {
                for (final p in _t.players)
                  if (p.appUserId != null) p.appUserId!,
              };
              if (alreadyIn.contains(appUserId)) return false;
              final p = DoghousePlayer(
                id:        DoghousePlayer.generateId(),
                name:      name,
                source:    DoghousePlayerSource.existing,
                appUserId: appUserId,
                status:    playerStatus,
              );
              _t = _t.copyWith(players: [..._t.players, p]);
              _persist();
              _pool.add(p);
              rebuild();
              return false;
            },
            addedPlayers: latePlayers
                .map((p) => PlayerPickerEntry(
                      id: p.id,
                      name: p.name,
                      status: p.status,
                    ))
                .toList(),
            onRemoveAdded: (id) {
              _t = _t.copyWith(
                  players: _t.players.where((p) => p.id != id).toList());
              _persist();
              _pool.removeWhere((q) => q.id == id);
              rebuild();
            },
            onFillRandom: () {
              final generated = ScrambleService.generateRandomPlayers(4);
              for (final g in generated) {
                final p = DoghousePlayer(
                  id:     DoghousePlayer.generateId(),
                  name:   g.name,
                  source: DoghousePlayerSource.random,
                  status: playerStatus,
                );
                _t = _t.copyWith(players: [..._t.players, p]);
                _pool.add(p);
              }
              _persist();
              rebuild();
            },
            addedCountLabel: l10n.doghouseNPlayersAdded(latePlayers.length),
            fillRandomLabel: l10n.doghouseAdd4Random,
          );
        },
      ),
    );
  }

  // ── Dialogs ───────────────────────────────────────────────────────────────

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
                if (timerRunning) _gameWatch.start();
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
                if (timerRunning) _gameWatch.start();
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
      clearTimerAnchor: true,
    );
    _persist();
    markSessionTimerStopped();
    _showSummaryDialog().then((_) {
      if (mounted) Navigator.of(context).pop();
    });
  }

  void _undoCompletion() {
    _t = _t.copyWith(
        status: DoghouseTournamentStatus.inProgress,
        clearRemainingSeconds: true,
        clearTimerAnchor: true);
    _persist();
    setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _sessionTimerKey.currentState?.setRemaining(_t.totalTime);
    });
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
    persistTimerState();
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
                        if (p.status != PlayerStatus.active) ...[
                          const SizedBox(width: 6),
                          PlayerStatusChip(p.status),
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
        title: 'Doghouse',
        subtitle: _t.name,
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
          else if (_hasTeam && _isAutoMode) ...[
            // Three-slot automated layout: Up Next → Challengers → Doghouse
            _buildUpNextTile(),
            const SizedBox(height: 8),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(flex: 4, child: _buildChallengersTile()),
                  const SizedBox(width: 8),
                  Expanded(flex: 1, child: _buildChallengerEjectColumn()),
                ],
              ),
            ),
            const SizedBox(height: 8),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(flex: 4, child: _buildActiveScoringTile()),
                  const SizedBox(width: 8),
                  Expanded(flex: 1, child: _buildGameLostColumn()),
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
                  Expanded(flex: 1, child: _buildGameLostColumn()),
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
                initial: timerInitialRemaining ??
                    Duration(
                        seconds: _t.remainingSeconds ??
                            _t.totalTime.inSeconds),
                mode: ScrambleTimerMode.countdown,
                autoStart: timerRunning,
                compact: true,
                onTick: (_) => setState(() {}),
                onFinished: _onSessionFinished,
              ),
              const SizedBox(width: 8),
              if (_sessionTimerKey.currentState?.timerState == ScrambleTimerState.paused)
                _refBtn(Icons.play_arrow_rounded, AppLocalizations.of(context)!.btnResume,
                    resumeTimer, primary: true),
              _refBtn(Icons.pause_rounded, AppLocalizations.of(context)!.btnStop, pauseTimer),
              const SizedBox(width: 4),
              _refBtn(Icons.replay_rounded, AppLocalizations.of(context)!.doghouseStartRestart,
                  _startOrRestart),
              const SizedBox(width: 4),
              _refTextBtn('+30s',
                  () => addSessionTime(const Duration(seconds: 30))),
              const SizedBox(width: 4),
              _refTextBtn('−30s',
                  () => addSessionTime(const Duration(seconds: -30))),
              const Spacer(),
              optionsButton,
            ],
          ),
          const SizedBox(height: 4),
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
                      // Challenger eject (focal) + Undo (secondary)
                      SizedBox(width: 56, child: _buildChallengerEjectColumn()),
                      const SizedBox(width: 6),
                      // Column 2: Doghouse + Score, Admin tile below (allPlay only)
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
                      // Column 3: Game Lost (2/3) + Undo (1/3) when available
                      SizedBox(
                        width: 64,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              flex: _canUndo ? 2 : 1,
                              child: _buildGameLostColumn(),
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
                                ? _buildGameLostColumn()
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

  // Add-loss (focal) stacked over a self-disabling "Undo Loss" — mirrors the
  // challenger eject column's shape (flex 2 primary / flex 1 secondary).
  Widget _buildGameLostColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(flex: 2, child: _buildAddGameLostButton()),
        const SizedBox(height: 6),
        Expanded(flex: 1, child: _buildUndoLossButton()),
      ],
    );
  }

  Widget _buildAddGameLostButton() {
    final atCap    = _currentGamesLost >= _t.lossLimit;
    final nearEject = _currentGamesLost >=
        (_t.lossLimit - 1).clamp(0, _t.lossLimit);
    final canAdd   = _hasTeam && !_isCompleted && !atCap;
    final bgColor  = nearEject ? Colors.red.shade600 : Colors.grey.shade700;

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Material(
        color: bgColor,
        child: InkWell(
          onTap: canAdd ? _addGameLost : null,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.sentiment_very_dissatisfied_rounded,
                    size: 22,
                    color: Colors.white.withValues(alpha: canAdd ? 1.0 : 0.5),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '$_currentGamesLost / ${_t.lossLimit}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                        color: Colors.white.withValues(alpha: canAdd ? 1.0 : 0.6),
                        height: 1.2),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    AppLocalizations.of(context)!.doghouseGameLost,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                        color: Colors.white.withValues(alpha: canAdd ? 0.85 : 0.45)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUndoLossButton() {
    final canUndo = _hasTeam && !_isCompleted && _currentGamesLost > 0;
    return OutlinedButton(
      onPressed: canUndo ? _removeGameLost : null,
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
            const Icon(Icons.undo_rounded, size: 16),
            const SizedBox(height: 4),
            Text(
              AppLocalizations.of(context)!.doghouseUndoLoss,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 10),
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

  // ── Narrow challenger eject button + column (mirrors the game-lost column) ─

  Widget _buildChallengerEjectColumn() {
    final l10n = AppLocalizations.of(context)!;
    return ChallengerEjectColumn(
      canEject: _canEjectChallenger,
      onEject: _ejectChallenger,
      canUndo: _canUndoEjectChallenger,
      onUndo: _undoEjectChallenger,
      ejectLabel: l10n.kotcEjectChallengerShort,
      undoLabel: l10n.kotcUndoEjectChallenger,
    );
  }

  // ── Admin tile (automatedAllPlay only) ────────────────────────────────────

  Widget _buildAdminTile() {
    final admin     = _t.players.where((p) => p.id == _adminPlayerId).firstOrNull;
    final nextAdmin = _t.players.where((p) => p.id == _nextAdminPlayerId).firstOrNull;
    return AdminRotationTile(
      adminName: admin?.name,
      nextAdminName: nextAdmin?.name,
      adminTag: AppLocalizations.of(context)!.kotcAdminTag,
      onTap: _showAdminOverrideSheet,
    );
  }

  void _showAdminOverrideSheet() {
    if (!_isAllPlay) return;
    final l10n = AppLocalizations.of(context)!;
    showAdminOverrideSheet(
      context: context,
      title: l10n.kotcChangeAdmin,
      subtitle: l10n.kotcChangeAdminSubtitle,
      pool: _pool.map((p) => (id: p.id, name: p.name)).toList(),
      currentAdminId: _adminPlayerId,
      onSetAdmin: (id) {
        setState(() => _adminPlayerId = id);
        if (_hasTeam) {
          _recomputeChallenger();
        } else {
          _initSuggestion();
        }
      },
      onCourtTeam: _hasTeam
          ? _teamPlayers.map((p) => (id: p.id, name: p.name)).toList()
          : null,
      nextAdminId: _hasTeam ? _nextAdminPlayerId : null,
      nextAdminLabel: l10n.kotcNextAdmin,
      nextAdminNote: l10n.kotcNextAdminNote,
      onSetNextAdmin: (id) => setState(() => _nextAdminPlayerId = id),
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
              initial: timerInitialRemaining ??
                  Duration(
                      seconds: _t.remainingSeconds ??
                          _t.totalTime.inSeconds),
              mode: ScrambleTimerMode.countdown,
              autoStart: timerRunning,
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
              if (_sessionTimerKey.currentState?.timerState == ScrambleTimerState.paused)
                _refBtn(Icons.play_arrow_rounded, AppLocalizations.of(context)!.btnResume,
                    resumeTimer, primary: true),
              _refBtn(Icons.pause_rounded, AppLocalizations.of(context)!.btnStop, pauseTimer),
              _refBtn(Icons.replay_rounded, AppLocalizations.of(context)!.doghouseStartRestart,
                  _startOrRestart),
              _refTextBtn('+30s',
                  () => addSessionTime(const Duration(seconds: 30))),
              _refTextBtn('−30s',
                  () => addSessionTime(const Duration(seconds: -30))),
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
              Text(AppLocalizations.of(context)!.kotcUpNext,
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
                label: Text(AppLocalizations.of(context)!.quickStartReRoll,
                    style: const TextStyle(fontSize: 11)),
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
              Text(AppLocalizations.of(context)!.doghouseNotEnoughInQueue,
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
              Text(AppLocalizations.of(context)!.kotcChallengers,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _kGold,
                    letterSpacing: 0.4,
                  )),
            ]),
            const SizedBox(height: 8),
            if (!hasChallengers)
              Text(AppLocalizations.of(context)!.kotcWaitingForPlayers,
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

  // ── Initial suggested-team tile (shown before any team is in the doghouse) ──

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
            if (_isAutoMode) ...[
              Row(children: [
                const Icon(Icons.pets_rounded, size: 13, color: _kGold),
                const SizedBox(width: 5),
                Text(AppLocalizations.of(context)!.doghouseInDoghouseLabel,
                    style: const TextStyle(
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
                      (timerRunning && _currentSideOuts > 0)
                          ? _removeSideOut
                          : null,
                  style: IconButton.styleFrom(
                    backgroundColor:
                        (timerRunning && _currentSideOuts > 0)
                            ? _kGold
                            : Colors.grey.shade300,
                    foregroundColor:
                        (timerRunning && _currentSideOuts > 0)
                            ? Colors.white
                            : Colors.grey,
                    fixedSize: const Size(52, 52),
                  ),
                ),
                IconButton.filled(
                  icon: const Icon(Icons.add),
                  tooltip: '+1 side-out',
                  onPressed:
                      timerRunning ? _addSideOut : null,
                  style: IconButton.styleFrom(
                    backgroundColor: timerRunning
                        ? _kGold
                        : Colors.grey.shade300,
                    foregroundColor: timerRunning
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
        // Info chips — tap to edit config mid-game
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            InfoChip(
                icon: Icons.pets_rounded,
                label: _t.name,
                bg: _kOliveLight,
                fg: _kOlive),
            InfoChip(
                icon: Icons.tune_rounded,
                label: _assignmentModeLabel(AppLocalizations.of(context)!),
                bg: _kOliveLight,
                fg: _kOlive,
                onTap: _showModeEditSheet),
            InfoChip(
                icon: Icons.grid_view_rounded,
                label: '${_t.playersPerTeam}v${_t.playersPerTeam}',
                bg: Colors.grey.shade100,
                fg: Colors.black45,
                onTap: _showTeamSizeEditSheet),
            InfoChip(
                icon: Icons.people_rounded,
                label: AppLocalizations.of(context)!.doghouseStatsPlayers(_t.playerCount),
                bg: Colors.grey.shade100,
                fg: Colors.black45,
                onTap: _showPlayersSheet,
                trailingIcon: Icons.chevron_right_rounded),
            InfoChip(
                icon: Icons.celebration_rounded,
                label: AppLocalizations.of(context)!.doghouseEscapePointsLabel(_t.escapePoints),
                bg: _kGoldLight,
                fg: _kGold,
                onTap: _showEscapePointsEditSheet),
            InfoChip(
                icon: Icons.sentiment_very_dissatisfied_rounded,
                label: AppLocalizations.of(context)!.doghouseLossLimitLabel(_t.lossLimit),
                bg: Colors.red.shade50,
                fg: Colors.red.shade400,
                onTap: _showLossLimitEditSheet),
          ],
        ),
        const Divider(height: 24),

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

  String _assignmentModeLabel(AppLocalizations l10n) =>
      switch (_t.assignmentMode) {
        DoghouseAssignmentMode.manual => l10n.doghouseAssignmentManual,
        DoghouseAssignmentMode.automated => l10n.doghouseAssignmentAutomated,
        DoghouseAssignmentMode.automatedAllPlay => l10n.setupFormatAutoAllplay,
      };

  // ── Mid-game config edit sheets ───────────────────────────────────────────

  Future<void> _showModeEditSheet() async {
    final l10n = AppLocalizations.of(context)!;
    final v = await showEnumPickerSheet<DoghouseAssignmentMode>(
      context: context,
      title: l10n.labelAssignment,
      helpText: l10n.kotcSetupAssignmentHelp,
      initialValue: _t.assignmentMode,
      items: [
        DropdownMenuItem(
            value: DoghouseAssignmentMode.manual,
            child: Text(l10n.doghouseAssignmentManual)),
        DropdownMenuItem(
            value: DoghouseAssignmentMode.automated,
            child: Text(l10n.doghouseAssignmentAutomated)),
        DropdownMenuItem(
            value: DoghouseAssignmentMode.automatedAllPlay,
            child: Text(l10n.setupFormatAutoAllplay)),
      ],
    );
    if (v != null) _changeAssignmentMode(v);
  }

  Future<void> _showTeamSizeEditSheet() async {
    final l10n = AppLocalizations.of(context)!;
    final v = await showTeamSizeSheet(
      context: context,
      title: l10n.kotcSetupStyleLabel,
      helpText: l10n.kotcTeamSizeChangeNote,
      initialValue: _t.playersPerTeam,
    );
    if (v != null) _changeTeamSize(v);
  }

  Future<void> _showEscapePointsEditSheet() async {
    final l10n = AppLocalizations.of(context)!;
    final v = await showNumericStepperSheet(
      context: context,
      title: l10n.labelEscapePoints,
      helpText: l10n.doghouseEscapePointsHelp,
      initialValue: _t.escapePoints,
      presets: const [1, 2, 3, 5, 7, 10],
      min: 1,
    );
    if (v != null) _changeEscapePoints(v);
  }

  Future<void> _showLossLimitEditSheet() async {
    final l10n = AppLocalizations.of(context)!;
    final v = await showNumericStepperSheet(
      context: context,
      title: l10n.labelLossLimit,
      helpText: l10n.doghouseLossLimitHelp,
      initialValue: _t.lossLimit,
      presets: const [1, 2, 3, 5, 7, 10],
      min: 1,
    );
    if (v != null) _changeLossLimit(v);
  }

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

  // ── Players section ───────────────────────────────────────────────────────

  void _showPlayersSheet() {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) {
          final players = _t.players;
          return TournaQSheet(
            body: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(l10n.sectionPlayersCount(players.length),
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 12),
                  if (!_isCompleted) ...[
                    OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        _showAddPlayerToQueue();
                      },
                      icon: const Icon(Icons.person_add_rounded, size: 16),
                      label: Text(l10n.menuAddPlayer,
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _kOlive,
                        side: BorderSide(
                            color: _kOlive.withValues(alpha: 0.4)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  ...players.map((p) {
                    final onCourt = _teamPlayers.any((t) => t.id == p.id);
                    final inPool  = _pool.any((q) => q.id == p.id);
                    final games   = _t.gamesPerPlayer[p.id] ?? 0;
                    final pts     = _t.pointsPerPlayer[p.id] ?? 0;
                    return TournamentPlayerRow(
                      name: p.name,
                      status: p.status,
                      statsLine: (games > 0 || pts > 0) ? '${games}g · ${pts}pts' : null,
                      isOnCourt: onCourt,
                      onEdit: !onCourt
                          ? () {
                              Navigator.of(ctx).pop();
                              _showEditDoghousePlayer(p);
                            }
                          : null,
                      onSwap: (inPool && !onCourt)
                          ? () {
                              Navigator.of(ctx).pop();
                              _replaceDoghousePlayer(p);
                            }
                          : null,
                      onEject: (inPool && !onCourt)
                          ? () {
                              _ejectDoghousePlayer(p);
                              setSheet(() {});
                            }
                          : null,
                      showDisabledActions: true,
                    );
                  }),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

    void _showEditDoghousePlayer(DoghousePlayer p) {
    final l10n     = AppLocalizations.of(context)!;
    final nameCtrl = TextEditingController(text: p.name);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => TournaQSheet(
        body: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(children: [
                Expanded(
                  child: Text(l10n.overviewEditPlayer,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w800)),
                ),
                TextButton(
                  onPressed: () =>
                      _saveDoghousePlayerName(ctx, p, nameCtrl.text),
                  style: TextButton.styleFrom(foregroundColor: _kOlive),
                  child: Text(l10n.btnSave,
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                ),
              ]),
              const SizedBox(height: 16),
              Text(l10n.labelName,
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.black54)),
              const SizedBox(height: 6),
              TextField(
                controller: nameCtrl,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                onSubmitted: (_) =>
                    _saveDoghousePlayerName(ctx, p, nameCtrl.text),
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _saveDoghousePlayerName(
      BuildContext ctx, DoghousePlayer p, String raw) {
    final name = raw.trim();
    if (name.isEmpty) return;
    setState(() {
      _t = _t.copyWith(
        players: _t.players
            .map((pl) => pl.id == p.id ? pl.copyWith(name: name) : pl)
            .toList(),
      );
      _pool = _pool
          .map((pl) => pl.id == p.id ? pl.copyWith(name: name) : pl)
          .toList();
      _teamPlayers = _teamPlayers
          .map((pl) => pl.id == p.id ? pl.copyWith(name: name) : pl)
          .toList();
    });
    _persist();
    Navigator.of(ctx).pop();
  }

  void _ejectDoghousePlayer(DoghousePlayer p) {
    setState(() {
      _t = _t.copyWith(
          players: _t.players
              .map((pl) => pl.id == p.id
                  ? pl.copyWith(status: PlayerStatus.ejected)
                  : pl)
              .toList());
      _pool.removeWhere((pl) => pl.id == p.id);
    });
    _recomputeUpNext();
    _persist();
  }

  void _replaceDoghousePlayer(DoghousePlayer outgoing) {
    setState(() {
      _t = _t.copyWith(
          players: _t.players
              .map((pl) => pl.id == outgoing.id
                  ? pl.copyWith(status: PlayerStatus.swappedOut)
                  : pl)
              .toList());
      _pool.removeWhere((pl) => pl.id == outgoing.id);
    });
    _persist();
    _showLatePlayersSheet(isReplacement: true, outgoingName: outgoing.name);
  }
}
