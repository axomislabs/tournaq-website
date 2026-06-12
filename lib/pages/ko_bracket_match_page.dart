import 'dart:async';
import 'package:flutter/material.dart';
import '../app/app_colors.dart';
import '../models/ko_bracket_tournament.dart';
import '../services/ko_bracket_storage_service.dart';
import '../widgets/player_pill.dart';
import '../widgets/tournaq_app_bar.dart';
import '../widgets/scrollable_page.dart';

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
  late int _remainingSeconds;
  Timer? _timer;
  bool _timerRunning = false;

  // ── Undo stack ────────────────────────────────────────────────────────────
  final List<({bool isTeam1, int prev1, int prev2})> _undoStack = [];

  @override
  void initState() {
    super.initState();
    _tournament = widget.tournament;
    _match = _tournament.matches.firstWhere((m) => m.id == widget.matchId);
    _fmt = _tournament.formatForRound(_match.round);
    _remainingSeconds = _tournament.minutesPerGame * 60;
    _initScores();
    _startTimer();
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

  void _startTimer() {
    _timerRunning = true;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
        } else {
          _timer?.cancel();
          _timerRunning = false;
        }
      });
    });
  }

  void _toggleTimer() {
    setState(() {
      if (_timerRunning) {
        _timer?.cancel();
        _timerRunning = false;
      } else {
        _startTimer();
      }
    });
  }

  Color get _timerColor {
    if (_remainingSeconds <= 30) return Colors.red;
    if (_remainingSeconds <= 120) return Colors.orange;
    return _kGoldDark;
  }

  String get _timerLabel {
    final m = _remainingSeconds ~/ 60;
    final s = _remainingSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  // ── Scoring ───────────────────────────────────────────────────────────────

  void _addScore({required bool isLeft}) {
    if (_isMatchComplete || _currentSetDone) return;
    final isTeam1 = isLeft ? !_isSwapped : _isSwapped;
    setState(() {
      _undoStack.add((isTeam1: isTeam1, prev1: _score1, prev2: _score2));
      if (isTeam1) {
        _score1++;
      } else {
        _score2++;
      }
    });
  }

  void _removeScore({required bool isLeft}) {
    if (_isMatchComplete || _currentSetDone) return;
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
    final team1Name = _team1?.name ?? 'Team 1';
    final team2Name = _team2?.name ?? 'Team 2';
    final scoreLocked = _isMatchComplete || _currentSetDone;

    return Scaffold(
      appBar: TournaQAppBar(
        title: '$team1Name vs $team2Name',
        subtitle: 'KO Bracket · Scorecard',
        actions: [
          IconButton(
            icon: const Icon(Icons.swap_horiz_rounded, size: 20, color: _kOlive),
            tooltip: 'Swap sides',
            onPressed: scoreLocked ? null : () => setState(() => _isSwapped = !_isSwapped),
          ),
        ],
      ),
      body: ScrollablePage(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Context chips ────────────────────────────────────────────
            _buildContextChips(),
            const SizedBox(height: 12),

            // ── Timer ────────────────────────────────────────────────────
            _buildTimer(),
            const SizedBox(height: 16),

            // ── Set overview ─────────────────────────────────────────────
            _buildSetOverview(),
            const SizedBox(height: 12),

            // ── Lock banner ───────────────────────────────────────────────
            if (_isMatchComplete)
              _buildLockBanner(
                'Match complete',
                winnerName: _match.winnerId != null
                    ? _tournament.teamById(_match.winnerId!)?.name
                    : null,
              )
            else if (_currentSetDone)
              _buildLockBanner('Set complete — confirm before next set'),

            // ── Score cards ──────────────────────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
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
            const SizedBox(height: 24),

            // ── Match actions ────────────────────────────────────────────
            _buildMatchActions(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ── Context chips ─────────────────────────────────────────────────────────

  Widget _buildContextChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _contextChip(Icons.account_tree_rounded, _bracketPositionLabel, _kGold),
        if (_match.courtAssignment != null)
          _contextChip(Icons.sports_tennis_rounded, 'Court ${_match.courtAssignment}', _kOlive),
        _contextChip(Icons.info_outline_rounded, _fmt.label, Colors.black45),
      ],
    );
  }

  Widget _contextChip(IconData icon, String label, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color == _kGold ? _kGoldCream : _kOliveLight,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 5),
          Text(label,
              style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w600, color: color)),
        ]),
      );

  // ── Timer ─────────────────────────────────────────────────────────────────

  Widget _buildTimer() {
    return GestureDetector(
      onTap: _isMatchComplete ? null : _toggleTimer,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: _timerColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _timerColor.withValues(alpha: 0.3)),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(
            _timerRunning ? Icons.pause_circle_outline_rounded : Icons.play_circle_outline_rounded,
            size: 20,
            color: _timerColor,
          ),
          const SizedBox(width: 8),
          Text(
            _timerLabel,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: _timerColor,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _timerRunning ? 'Tap to pause' : 'Tap to resume',
            style: TextStyle(fontSize: 11, color: _timerColor.withValues(alpha: 0.6)),
          ),
        ]),
      ),
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

  Widget _buildMatchActions() {
    final isOneSet = _fmt.setsPerGame == 1;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Complete Set — hidden for single-set format
          if (!isOneSet) ...[
            ElevatedButton.icon(
              onPressed: _isMatchComplete
                  ? null
                  : _currentSetDone
                      ? _undoSetCompletion
                      : _completeSet,
              icon: Icon(
                _currentSetDone ? Icons.undo_rounded : Icons.check_circle_outline_rounded,
                size: 18,
              ),
              label: Text(_currentSetDone ? 'Undo Set' : 'Complete Set'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _isMatchComplete
                    ? null
                    : _currentSetDone
                        ? Colors.grey.shade500
                        : _kGold,
                foregroundColor: _isMatchComplete ? null : Colors.white,
              ),
            ),
            const SizedBox(height: 8),
          ],

          // Complete / Undo Match
          ElevatedButton.icon(
            onPressed: _isMatchComplete ? _undoMatchCompletion : _completeMatch,
            icon: Icon(
              _isMatchComplete ? Icons.undo_rounded : Icons.emoji_events_rounded,
              size: 18,
            ),
            label: Text(_isMatchComplete ? 'Undo Match Completion' : 'Complete Match'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _kOlive,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
          const SizedBox(height: 8),

          OutlinedButton.icon(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back_rounded, size: 18),
            label: const Text('Back to Bracket'),
          ),
        ],
      ),
    );
  }
}
