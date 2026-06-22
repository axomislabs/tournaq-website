import 'dart:async';
import 'package:flutter/material.dart';
import '../app/app_colors.dart';
import '../models/ko_bracket_tournament.dart';
import '../services/ko_bracket_storage_service.dart';
import '../widgets/player_pill.dart';
import '../widgets/sheet_helpers.dart';
import '../widgets/tournaq_app_bar.dart';

const _kGold = AppColors.gold;
const _kGoldDark = AppColors.goldDark;
const _kGoldCream = AppColors.goldCream;
const _kGoldCardBg = AppColors.goldCardBg;
const _kGoldCardLeading = AppColors.goldCardLeading;
const _kOlive = AppColors.olive;
const _kOliveLight = AppColors.oliveLight;
const _kOliveCardBg = AppColors.oliveCardBg;
const _kOliveCardLeading = AppColors.oliveCardLeading;

class KoBracketMatchPage extends StatefulWidget {
  final KoBracketTournament tournament;
  final String matchId;
  final void Function(KoBracketTournament) onChanged;

  const KoBracketMatchPage({
    super.key,
    required this.tournament,
    required this.matchId,
    required this.onChanged,
  });

  @override
  State<KoBracketMatchPage> createState() => _KoBracketMatchPageState();
}

class _KoBracketMatchPageState extends State<KoBracketMatchPage> {
  late KoBracketTournament _tournament;
  late KoMatch _match;
  late KoRoundFormat _fmt;

  // ── Live scores for the active set ───────────────────────────────────────
  int _score1 = 0;
  int _score2 = 0;
  bool _isSwapped = false;

  // ── Timer ─────────────────────────────────────────────────────────────────
  Timer? _timer;
  DateTime _now = DateTime.now();
  int _fallbackSeconds = 0; // used only when no scheduledEndTime

  // ── Time-cap state ────────────────────────────────────────────────────────
  bool _timeUp = false;
  bool _suddenDeath = false;

  // ── Undo stack ────────────────────────────────────────────────────────────
  final List<({bool isTeam1, int prev1, int prev2})> _undoStack = [];

  @override
  void initState() {
    super.initState();
    _tournament = widget.tournament;
    _match = _tournament.matches.firstWhere((m) => m.id == widget.matchId);
    _fmt = _tournament.formatForRound(_match.round);
    _initScores();
    _now = DateTime.now();
    _initTimerState();
    if (!_isMatchComplete) {
      _startTimer();
      // Mark as started on first open if not already
      if (_match.startedAt == null &&
          _match.team1Id != null &&
          _match.team2Id != null) {
        final started = _match.copyWith(
          startedAt: DateTime.now(),
          status: KoMatchStatus.inProgress,
        );
        final t = _tournament.updateMatch(started);
        KoBracketStorageService.save(t);
        _tournament = t;
        _match = started;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) widget.onChanged(t);
        });
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  KoTeam? get _team1 => _match.team1Id != null ? _tournament.teamById(_match.team1Id!) : null;
  KoTeam? get _team2 => _match.team2Id != null ? _tournament.teamById(_match.team2Id!) : null;

  KoTeam? get _leftTeam => _isSwapped ? _team2 : _team1;
  KoTeam? get _rightTeam => _isSwapped ? _team1 : _team2;
  int get _leftScore => _isSwapped ? _score2 : _score1;
  int get _rightScore => _isSwapped ? _score1 : _score2;
  bool get _isLeftLeading => _leftScore > _rightScore;
  bool get _isRightLeading => _rightScore > _leftScore;

  bool get _isMatchComplete => _match.isComplete;
  int get _currentSetIndex => _match.sets.where((s) => s.isCompleted).length;
  bool get _currentSetDone {
    if (_match.sets.isEmpty) return false;
    final last = _match.sets.last;
    return last.isCompleted;
  }

  int get _team1SetsWon => _match.sets.where((s) => s.isCompleted && s.score1 > s.score2).length;
  int get _team2SetsWon => _match.sets.where((s) => s.isCompleted && s.score2 > s.score1).length;

  void _initScores() {
    _score1 = 0;
    _score2 = 0;
  }

  // ── Timer ─────────────────────────────────────────────────────────────────

  void _initTimerState() {
    final end = _match.scheduledEndTime;
    if (end != null) {
      if (DateTime.now().isAfter(end)) _timeUp = true;
    } else {
      final started = _match.startedAt;
      final totalSecs = _tournament.minutesForRound(_match.round) * 60;
      if (started != null) {
        final elapsed = DateTime.now().difference(started).inSeconds;
        _fallbackSeconds = (totalSecs - elapsed).clamp(0, totalSecs);
      } else {
        _fallbackSeconds = totalSecs;
      }
      if (_fallbackSeconds == 0) _timeUp = true;
    }
  }

  void _startTimer() {
    final end = _match.scheduledEndTime;
    if (end != null) {
      _timer = Timer.periodic(const Duration(seconds: 30), (_) {
        if (!mounted) return;
        setState(() => _now = DateTime.now());
        if (!_isMatchComplete && !_timeUp && _now.isAfter(end)) {
          _timer?.cancel();
          _onTimeUp();
        }
      });
    } else {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        setState(() {
          if (_fallbackSeconds > 0) _fallbackSeconds--;
          if (_fallbackSeconds == 0 && !_isMatchComplete && !_timeUp) {
            _timer?.cancel();
            _onTimeUp();
          }
        });
      });
    }
  }

  // ── Time-cap logic ────────────────────────────────────────────────────────

  void _onTimeUp() {
    setState(() => _timeUp = true);
    _resolveByTime();
  }

  void _resolveByTime() {
    if (_isMatchComplete) return;

    // Fold any live in-progress scores into a partial set
    final s1 = _isSwapped ? _score2 : _score1;
    final s2 = _isSwapped ? _score1 : _score2;
    final sets = (!_currentSetDone && (s1 > 0 || s2 > 0))
        ? [..._match.sets, KoSet(score1: s1, score2: s2, isCompleted: true)]
        : List<KoSet>.from(_match.sets);

    final t1Sets =
        sets.where((s) => s.isCompleted && s.score1 > s.score2).length;
    final t2Sets =
        sets.where((s) => s.isCompleted && s.score2 > s.score1).length;

    if (t1Sets != t2Sets) {
      _applyTimeupResult(
          sets: sets,
          winnerId: t1Sets > t2Sets ? _match.team1Id : _match.team2Id);
      return;
    }

    // Tiebreak: total points across all completed sets
    final t1Pts = sets.fold<int>(0, (sum, s) => sum + s.score1);
    final t2Pts = sets.fold<int>(0, (sum, s) => sum + s.score2);

    if (t1Pts != t2Pts) {
      _applyTimeupResult(
          sets: sets,
          winnerId: t1Pts > t2Pts ? _match.team1Id : _match.team2Id);
      return;
    }

    // Still tied → sudden death
    setState(() {
      _suddenDeath = true;
      _score1 = 0;
      _score2 = 0;
      _undoStack.clear();
    });
  }

  void _applyTimeupResult(
      {required List<KoSet> sets, required String? winnerId}) {
    final resolved = _match.copyWith(
      sets: sets,
      winnerId: winnerId,
      status: KoMatchStatus.completed,
      completedAt: DateTime.now(),
    );
    setState(() {
      _timeUp = false;
      _suddenDeath = false;
      _score1 = 0;
      _score2 = 0;
      _undoStack.clear();
    });
    _persist(resolved, isComplete: true);
  }


  // ── Scoring ───────────────────────────────────────────────────────────────

  void _addScore({required bool isLeft}) {
    if (_isMatchComplete || _currentSetDone) return;
    if (_timeUp && !_suddenDeath) return;
    final isTeam1 = isLeft ? !_isSwapped : _isSwapped;
    setState(() {
      _undoStack.add((isTeam1: isTeam1, prev1: _score1, prev2: _score2));
      if (isTeam1) {
        _score1++;
      } else {
        _score2++;
      }
    });
    if (_suddenDeath) {
      // First point wins — resolve immediately
      final winnerId = isTeam1 ? _match.team1Id : _match.team2Id;
      _applyTimeupResult(sets: _match.sets, winnerId: winnerId);
    }
  }

  void _removeScore({required bool isLeft}) {
    if (_isMatchComplete || _currentSetDone) return;
    if (_timeUp) return; // no undo after time cap
    if (_undoStack.isEmpty) return;
    final isTeam1 = isLeft ? !_isSwapped : _isSwapped;
    // Find last event for this team and undo it.
    for (var i = _undoStack.length - 1; i >= 0; i--) {
      if (_undoStack[i].isTeam1 == isTeam1) {
        final prev = _undoStack.removeAt(i);
        setState(() {
          _score1 = prev.prev1;
          _score2 = prev.prev2;
        });
        return;
      }
    }
  }

  // ── Set & match completion ────────────────────────────────────────────────

  void _completeSet() {
    if (_isMatchComplete) return;
    final s1 = _isSwapped ? _score2 : _score1;
    final s2 = _isSwapped ? _score1 : _score2;
    final newSet = KoSet(score1: s1, score2: s2, isCompleted: true);
    final updatedSets = [..._match.sets, newSet];
    var updatedMatch = _match.copyWith(sets: updatedSets);

    // Determine winner if sets are decided.
    final setsToWin = (_fmt.setsPerGame / 2).ceil();
    final t1Sets = updatedSets.where((s) => s.isCompleted && s.score1 > s.score2).length;
    final t2Sets = updatedSets.where((s) => s.isCompleted && s.score2 > s.score1).length;

    if (t1Sets >= setsToWin || t2Sets >= setsToWin) {
      final winnerId = t1Sets >= setsToWin ? _match.team1Id : _match.team2Id;
      updatedMatch = updatedMatch.copyWith(
        winnerId: winnerId,
        status: KoMatchStatus.completed,
        completedAt: DateTime.now(),
      );
      _persist(updatedMatch, isComplete: true);
    } else {
      _persist(updatedMatch, isComplete: false);
    }

    setState(() {
      _undoStack.clear();
      _initScores();
    });
  }

  void _undoSetCompletion() {
    if (_match.sets.isEmpty) return;
    final last = _match.sets.last;
    if (!last.isCompleted) return;
    final updatedSets = _match.sets.sublist(0, _match.sets.length - 1);
    final updatedMatch = _match.copyWith(
      sets: updatedSets,
      winnerId: null,
      status: _match.sets.length == 1 ? KoMatchStatus.inProgress : _match.status,
    );
    setState(() {
      _score1 = last.score1;
      _score2 = last.score2;
    });
    _persist(updatedMatch, isComplete: false);
  }

  void _completeMatch() {
    if (_isMatchComplete) return;
    // Save current live scores as the final set if not yet done.
    final s1 = _isSwapped ? _score2 : _score1;
    final s2 = _isSwapped ? _score1 : _score2;
    List<KoSet> sets = _match.sets;
    if (!_currentSetDone && (s1 > 0 || s2 > 0)) {
      sets = [...sets, KoSet(score1: s1, score2: s2, isCompleted: true)];
    }

    final t1Sets = sets.where((s) => s.isCompleted && s.score1 > s.score2).length;
    final t2Sets = sets.where((s) => s.isCompleted && s.score2 > s.score1).length;
    final winnerId = t1Sets >= t2Sets ? _match.team1Id : _match.team2Id;

    final updatedMatch = _match.copyWith(
      sets: sets,
      winnerId: winnerId,
      status: KoMatchStatus.completed,
      completedAt: DateTime.now(),
    );
    _timer?.cancel();
    _persist(updatedMatch, isComplete: true);
  }

  void _undoMatchCompletion() {
    final updatedMatch = _match.copyWith(
      winnerId: null,
      status: KoMatchStatus.inProgress,
      completedAt: null,
    );
    _persist(updatedMatch, isComplete: false);
    _startTimer();
  }

  // ── Persist ───────────────────────────────────────────────────────────────

  void _persist(KoMatch updatedMatch, {required bool isComplete}) {
    var updated = _tournament.updateMatch(updatedMatch);

    if (isComplete && updatedMatch.winnerId != null) {
      final propagated = updatedMatch.round == 0
          ? KoBracketGenerator.propagatePlayInWinner(updated.matches, updatedMatch.id)
          : KoBracketGenerator.propagateWinner(updated.matches, updatedMatch.id);
      updated = updated.copyWith(matches: propagated);
    }

    if (updated.allMatchesComplete) {
      updated = updated.copyWith(status: KoBracketStatus.completed);
    } else if (updated.status == KoBracketStatus.setup) {
      updated = updated.copyWith(status: KoBracketStatus.inProgress);
    }

    KoBracketStorageService.save(updated);
    setState(() {
      _tournament = updated;
      _match = updated.matches.firstWhere((m) => m.id == widget.matchId);
      _fmt = updated.formatForRound(_match.round);
    });
    widget.onChanged(updated);
  }

  // ── Context chips ─────────────────────────────────────────────────────────

  String get _bracketPositionLabel {
    final total = _tournament.mainRoundCount;
    final stepsFromFinal = total - _match.round;
    final roundName = switch (stepsFromFinal) {
      0 => 'Final',
      1 => 'Semi-final',
      2 => 'Quarter-final',
      _ => 'Round ${_match.round}',
    };
    if (_match.status == KoMatchStatus.playIn) return 'Play-in · Match ${_match.matchIndex + 1}';
    if (_match.status == KoMatchStatus.repechage) return 'Repechage';
    return '$roundName · Match ${_match.matchIndex + 1}';
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final scoreLocked =
        _isMatchComplete || _currentSetDone || (_timeUp && !_suddenDeath);

    return Scaffold(
      appBar: TournaQAppBar(
        title: 'Single Elimination',
        subtitle: 'Scorecard',
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_rounded, size: 20, color: _kOlive),
            tooltip: 'Match Options',
            onPressed: _showOptions,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Match title ───────────────────────────────────────────────
            Text(
              '${_team1?.name ?? 'TBD'} vs ${_team2?.name ?? 'TBD'}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.black87),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 14),

            // ── Gameplay Controls ─────────────────────────────────────────
            _sectionHeader('Gameplay Controls', Icons.sports_volleyball_rounded),
            const SizedBox(height: 10),
            _buildScheduleCard(),
            const SizedBox(height: 10),
            _buildSetOverview(),

            // ── Banners ───────────────────────────────────────────────────
            const SizedBox(height: 10),
            if (_isMatchComplete)
              _buildLockBanner(
                'Match complete',
                winnerName: _match.winnerId != null
                    ? _tournament.teamById(_match.winnerId!)?.name
                    : null,
              )
            else if (_suddenDeath)
              _buildTimeUpBanner(suddenDeath: true)
            else if (_timeUp)
              _buildTimeUpBanner(suddenDeath: false)
            else if (_currentSetDone)
              _buildLockBanner('Set complete — confirm before next set'),

            // ── Score cards ───────────────────────────────────────────────
            const SizedBox(height: 10),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _buildScoreCard(
                      team: _leftTeam,
                      score: _leftScore,
                      isLeading: _isLeftLeading,
                      isTeam1: !_isSwapped,
                      onIncrement: scoreLocked ? null : () => _addScore(isLeft: true),
                      onDecrement: scoreLocked ? null : () => _removeScore(isLeft: true),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildScoreCard(
                      team: _rightTeam,
                      score: _rightScore,
                      isLeading: _isRightLeading,
                      isTeam1: _isSwapped,
                      onIncrement: scoreLocked ? null : () => _addScore(isLeft: false),
                      onDecrement: scoreLocked ? null : () => _removeScore(isLeft: false),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Match Controls ────────────────────────────────────────────
            _sectionHeader('Match Controls', Icons.emoji_events_rounded),
            const SizedBox(height: 10),
            _buildMatchActions(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ── Section header ────────────────────────────────────────────────────────

  Widget _sectionHeader(String title, IconData icon, {Widget? trailing}) => Row(
        children: [
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
        ],
      );

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
              const Text('Match Options',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              _optionTile(
                sheetCtx,
                icon: Icons.swap_horiz_rounded,
                iconBg: _isMatchComplete ? Colors.grey.shade100 : _kGoldCream,
                iconColor: _isMatchComplete ? Colors.grey : _kGoldDark,
                label: 'Swap Sides',
                subtitle: 'Switch left and right display',
                enabled: !_isMatchComplete,
                onTap: () {
                  Navigator.of(sheetCtx).pop();
                  setState(() => _isSwapped = !_isSwapped);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _optionTile(
    BuildContext sheetCtx, {
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String label,
    required String subtitle,
    required bool enabled,
    required VoidCallback onTap,
  }) =>
      ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 8),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        title: Text(label,
            style: TextStyle(
                fontWeight: FontWeight.w600,
                color: enabled ? Colors.black87 : Colors.grey)),
        subtitle: Text(subtitle,
            style: const TextStyle(fontSize: 12, color: Colors.black45)),
        onTap: enabled ? onTap : null,
      );

  // ── Schedule card ─────────────────────────────────────────────────────────

  Widget _buildScheduleCard() {
    final start = _match.scheduledStartTime;
    final end = _match.scheduledEndTime;
    final now = _now;

    if (start == null || end == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(children: [
          const Icon(Icons.schedule_rounded, size: 14, color: Colors.black38),
          const SizedBox(width: 6),
          const Text('MATCH SLOT',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.black38, letterSpacing: 0.6)),
          const Spacer(),
          Text('${_tournament.minutesForRound(_match.round)} min',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.black54)),
        ]),
      );
    }

    final beforeStart = now.isBefore(start);
    final afterEnd = !now.isBefore(end);

    String driftLabel;
    Color driftFg;
    Color driftBg;

    if (beforeStart) {
      final mins = start.difference(now).inMinutes;
      driftLabel = mins == 0 ? 'Now' : 'In ${mins}m';
      driftFg = _kOlive;
      driftBg = _kOliveLight;
    } else if (!afterEnd) {
      final left = end.difference(now).inMinutes;
      driftLabel = '${left}m left';
      driftFg = left <= 5 ? Colors.orange.shade700 : _kOlive;
      driftBg = left <= 5 ? Colors.orange.withValues(alpha: 0.1) : _kOliveLight;
    } else {
      final over = now.difference(end).inMinutes;
      driftLabel = over == 0 ? "Time's up" : '${over}m over';
      driftFg = Colors.red;
      driftBg = Colors.red.withValues(alpha: 0.08);
    }

    final bgColor = afterEnd ? Colors.red.withValues(alpha: 0.06) : Colors.grey.shade50;
    final borderColor = afterEnd ? Colors.red.withValues(alpha: 0.3) : Colors.grey.shade200;
    final labelColor = afterEnd ? Colors.red : Colors.black45;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(children: [
        Icon(Icons.schedule_rounded, size: 14, color: labelColor),
        const SizedBox(width: 6),
        Text('SCHEDULE',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: labelColor, letterSpacing: 0.6)),
        const SizedBox(width: 10),
        Text(
          '${_fmtTime(start)} – ${_fmtTime(end)}',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: afterEnd ? Colors.red.shade700 : Colors.black87,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(color: driftBg, borderRadius: BorderRadius.circular(20)),
          child: Text(driftLabel,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: driftFg)),
        ),
      ]),
    );
  }

  // ── Set overview ──────────────────────────────────────────────────────────

  Widget _buildSetOverview() {
    final maxSets = _fmt.setsPerGame;
    final sets = _match.sets;

    return Row(
      children: List.generate(maxSets, (i) {
        final hasSet = i < sets.length;
        final set = hasSet ? sets[i] : null;
        final isActive = i == _currentSetIndex && !_isMatchComplete;
        final isCompleted = set?.isCompleted ?? false;

        final displayScore1 = isActive && !isCompleted ? (_isSwapped ? _score2 : _score1) : (set?.score1 ?? 0);
        final displayScore2 = isActive && !isCompleted ? (_isSwapped ? _score1 : _score2) : (set?.score2 ?? 0);

        Color borderColor;
        Color bgColor;
        if (isActive) {
          borderColor = _kGold;
          bgColor = _kGoldCream;
        } else if (isCompleted) {
          borderColor = _kOlive;
          bgColor = _kOliveLight;
        } else {
          borderColor = Colors.grey.shade300;
          bgColor = Colors.grey.shade100;
        }

        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: i < maxSets - 1 ? 6 : 0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: borderColor, width: isActive ? 2 : 1),
              ),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text(
                  '${isCompleted ? '● ' : ''}Set ${i + 1} · ${_fmt.pointsPerSet}',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: isCompleted ? AppColors.inverseSurface : isActive ? _kGold : Colors.grey,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  set == null && !isActive ? '–' : '$displayScore1–$displayScore2',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isActive ? _kGold : isCompleted ? _kOlive : Colors.grey.shade400,
                  ),
                ),
              ]),
            ),
          ),
        );
      }),
    );
  }

  // ── Lock banner ───────────────────────────────────────────────────────────

  Widget _buildLockBanner(String message, {String? winnerName}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(children: [
        const Icon(Icons.lock_rounded, size: 16, color: Colors.black54),
        const SizedBox(width: 8),
        Expanded(
          child: Text(message,
              style: const TextStyle(fontSize: 12, color: Colors.black54, fontWeight: FontWeight.w500)),
        ),
        if (winnerName != null) ...[
          const SizedBox(width: 8),
          Text('🏆 $winnerName',
              style: const TextStyle(fontSize: 12, color: _kGoldDark, fontWeight: FontWeight.w700)),
        ],
      ]),
    );
  }

  Widget _buildTimeUpBanner({required bool suddenDeath}) {
    final color = suddenDeath ? Colors.deepOrange : Colors.red;
    final label = suddenDeath
        ? 'Sudden death — next point wins!'
        : "Time's up! Resolving…";
    final icon =
        suddenDeath ? Icons.flash_on_rounded : Icons.timer_off_rounded;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(label,
              style: TextStyle(
                  fontSize: 12,
                  color: color,
                  fontWeight: FontWeight.w700)),
        ),
      ]),
    );
  }

  // ── Score card ────────────────────────────────────────────────────────────

  Widget _buildScoreCard({
    required KoTeam? team,
    required int score,
    required bool isLeading,
    required bool isTeam1,
    required VoidCallback? onIncrement,
    required VoidCallback? onDecrement,
  }) {
    final teamColor = isTeam1 ? _kGold : _kOlive;
    final cardBg = isTeam1
        ? (isLeading ? _kGoldCardLeading : _kGoldCardBg)
        : (isLeading ? _kOliveCardLeading : _kOliveCardBg);
    final disabled = onIncrement == null;

    return Card(
      color: cardBg,
      elevation: isLeading ? 6 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: teamColor.withValues(alpha: isLeading ? 1.0 : 0.55),
          width: isLeading ? 2.5 : 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 12, 10, 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Team name
            Text(
              team?.name ?? 'TBD',
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Colors.black87),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            // Player pills
            if (team != null)
              Wrap(
                spacing: 4,
                runSpacing: 4,
                alignment: WrapAlignment.center,
                children: team.players
                    .map((p) => PlayerPill(
                          name: p.name,
                          isServing: false,
                          activeColor: teamColor,
                          compact: true,
                        ))
                    .toList(),
              ),
            // Score
            Text(
              '$score',
              style: TextStyle(
                fontSize: 56,
                fontWeight: FontWeight.bold,
                height: 1.0,
                color: disabled ? Colors.black38 : Colors.black87,
              ),
            ),
            // Sets won indicator (multi-set only)
            if (_fmt.setsPerGame > 1)
              Text(
                isTeam1 ? '$_team1SetsWon sets' : '$_team2SetsWon sets',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: teamColor.withValues(alpha: 0.8)),
              ),
            const SizedBox(height: 4),
            // +/- buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton.filled(
                  icon: const Icon(Icons.remove),
                  onPressed: onDecrement,
                  iconSize: 24,
                  style: IconButton.styleFrom(
                    backgroundColor: disabled ? Colors.grey.shade300 : teamColor,
                    foregroundColor: disabled ? Colors.grey : Colors.white,
                  ),
                ),
                IconButton.filled(
                  icon: const Icon(Icons.add),
                  onPressed: onIncrement,
                  iconSize: 24,
                  style: IconButton.styleFrom(
                    backgroundColor: disabled ? Colors.grey.shade300 : teamColor,
                    foregroundColor: disabled ? Colors.grey : Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Match actions ─────────────────────────────────────────────────────────

  String _fmtTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  Widget _chip(IconData icon, String label, Color bg, Color fg) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 11, color: fg),
          const SizedBox(width: 3),
          Text(label,
              style: TextStyle(
                  fontSize: 11, color: fg, fontWeight: FontWeight.w600)),
        ]),
      );

  Widget _buildMatchActions() {
    final isOneSet = _fmt.setsPerGame == 1;
    final startTime = _match.scheduledStartTime;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Info chips
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            _chip(Icons.account_tree_rounded, _bracketPositionLabel,
                _kGoldCream, _kGoldDark),
            if (_match.courtAssignment != null)
              _chip(Icons.sports_tennis_rounded,
                  'Court ${_match.courtAssignment}', _kOliveLight, _kOlive),
            _chip(Icons.info_outline_rounded, _fmt.label,
                Colors.grey.shade100, Colors.black45),
            if (startTime != null)
              _chip(Icons.schedule_rounded, 'Starts ${_fmtTime(startTime)}',
                  Colors.grey.shade100, Colors.black45),
            _chip(Icons.timer_rounded, '${_tournament.minutesForRound(_match.round)} min',
                _kOliveLight, _kOlive),
          ],
        ),
        const SizedBox(height: 12),

        // Resolve by time
        if (_timeUp && !_isMatchComplete && !_suddenDeath) ...[
          ElevatedButton.icon(
            onPressed: _resolveByTime,
            icon: const Icon(Icons.timer_off_rounded, size: 18),
            label: const Text('Resolve by Time',
                style: TextStyle(fontWeight: FontWeight.w700)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 8),
        ],

        // Complete Set (multi-set only)
        if (!isOneSet) ...[
          ElevatedButton.icon(
            onPressed: _isMatchComplete
                ? null
                : _currentSetDone
                    ? _undoSetCompletion
                    : _completeSet,
            icon: Icon(
              _currentSetDone
                  ? Icons.undo_rounded
                  : Icons.check_circle_outline_rounded,
              size: 18,
            ),
            label: Text(_currentSetDone ? 'Undo Set' : 'Complete Set',
                style: const TextStyle(fontWeight: FontWeight.w700)),
            style: ElevatedButton.styleFrom(
              backgroundColor: _isMatchComplete
                  ? null
                  : _currentSetDone
                      ? Colors.grey.shade500
                      : _kGold,
              foregroundColor: _isMatchComplete ? null : Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 8),
        ],

        // Complete / Undo Match
        ElevatedButton.icon(
          onPressed:
              _isMatchComplete ? _undoMatchCompletion : _completeMatch,
          icon: Icon(
            _isMatchComplete
                ? Icons.undo_rounded
                : Icons.emoji_events_rounded,
            size: 18,
          ),
          label: Text(
            _isMatchComplete ? 'Undo Match Completion' : 'Complete Match',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
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
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_rounded, size: 18),
          label: const Text('Back to Bracket'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }
}
