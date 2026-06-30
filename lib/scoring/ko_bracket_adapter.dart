import '../models/ko_bracket_tournament.dart';
import '../services/ko_bracket_storage_service.dart';

/// Manages all scoring and set-navigation state for a KO bracket match.
///
/// Key design: [currentSetIndex] is explicit mutable state, not derived from
/// [KoMatch.sets.length]. This allows the user to freely navigate between
/// completed sets and the pending set without deleting model data.
class KoBracketAdapter {
  KoBracketTournament _tournament;
  late KoMatch _match;
  late KoRoundFormat _fmt;
  final String _matchId;
  final void Function(KoBracketTournament) _onChanged;

  // Which set is currently being viewed/scored (0-based).
  // Starts at _match.sets.length (the pending, unstarted set).
  int _activeSetIndex = 0;

  // Canonical (team1/team2) live scores for the pending set.
  int _pendingScore1 = 0;
  int _pendingScore2 = 0;

  KoBracketAdapter({
    required KoBracketTournament tournament,
    required String matchId,
    required void Function(KoBracketTournament) onChanged,
  })  : _tournament = tournament,
        _matchId = matchId,
        _onChanged = onChanged {
    _match = tournament.matches.firstWhere((m) => m.id == matchId);
    _fmt = tournament.formatForRound(_match.round);
    _activeSetIndex = _match.sets.length;
    _pendingScore1 = _match.liveScore1 ?? 0;
    _pendingScore2 = _match.liveScore2 ?? 0;
    // Consume persisted live scores into local state.
    if (_pendingScore1 != 0 || _pendingScore2 != 0) {
      _match = _match.copyWith(clearLiveScores: true);
      _tournament = _tournament.updateMatch(_match);
    }
  }

  // ── Read-only state ───────────────────────────────────────────────────────

  KoBracketTournament get tournament => _tournament;
  KoMatch get match => _match;
  KoRoundFormat get fmt => _fmt;

  int get currentSetIndex => _activeSetIndex;
  int get targetPoints => _fmt.pointsPerSet;
  bool get isMatchComplete => _match.isComplete;

  int get pendingScore1 => _pendingScore1;
  int get pendingScore2 => _pendingScore2;

  /// True when [currentSetIndex] points to an already-completed set (view mode).
  bool get isCurrentSetCompleted => _activeSetIndex < _match.sets.length;

  /// Team1-canonical score for the currently active set.
  int get currentScore1 {
    if (_activeSetIndex < _match.sets.length) {
      return _match.sets[_activeSetIndex].score1;
    }
    return _pendingScore1;
  }

  /// Team2-canonical score for the currently active set.
  int get currentScore2 {
    if (_activeSetIndex < _match.sets.length) {
      return _match.sets[_activeSetIndex].score2;
    }
    return _pendingScore2;
  }

  // ── Write operations ──────────────────────────────────────────────────────

  /// Switches the active view to [setIndex], saving current live scores first.
  /// No-op if [setIndex] is already active or points beyond existing sets.
  void onSetActivated(int setIndex, int liveScore1, int liveScore2) {
    if (setIndex == _activeSetIndex) return;
    if (setIndex > _match.sets.length) return;
    if (!isCurrentSetCompleted && (liveScore1 > 0 || liveScore2 > 0)) {
      _pendingScore1 = liveScore1;
      _pendingScore2 = liveScore2;
      _persistMatch(_match.copyWith(liveScore1: liveScore1, liveScore2: liveScore2));
    }
    _activeSetIndex = setIndex;
  }

  /// Marks the current pending set as completed. No-op if already completed.
  void onSetCompleted(int score1, int score2) {
    if (isCurrentSetCompleted || isMatchComplete) return;
    final newSet = KoSet(score1: score1, score2: score2, isCompleted: true);
    final newSets = [..._match.sets, newSet];
    var updatedMatch = _match.copyWith(sets: newSets, clearLiveScores: true);

    final setsToWin = (_fmt.setsPerGame / 2).ceil();
    final t1 = newSets.where((s) => s.isCompleted && s.score1 > s.score2).length;
    final t2 = newSets.where((s) => s.isCompleted && s.score2 > s.score1).length;
    final matchOver = t1 >= setsToWin || t2 >= setsToWin;
    if (matchOver) {
      updatedMatch = updatedMatch.copyWith(
        winnerId: t1 >= setsToWin ? _match.team1Id : _match.team2Id,
        status: KoMatchStatus.completed,
        completedAt: DateTime.now(),
      );
    }

    _pendingScore1 = 0;
    _pendingScore2 = 0;
    _activeSetIndex = newSets.length;
    _persistMatch(updatedMatch, propagateWinner: matchOver);
  }

  /// Reopens set [setIndex] for scoring, removing it and all subsequent sets.
  void onSetUndone(int setIndex) {
    if (setIndex < 0 || setIndex >= _match.sets.length) return;
    final target = _match.sets[setIndex];
    final newSets = _match.sets.sublist(0, setIndex);
    _pendingScore1 = target.score1;
    _pendingScore2 = target.score2;
    _activeSetIndex = setIndex;
    _persistMatch(_match.copyWith(
      sets: newSets,
      winnerId: null,
      status: newSets.isEmpty ? KoMatchStatus.inProgress : _match.status,
    ));
  }

  /// Finalises the match. Includes [score1]/[score2] as the current set if non-zero.
  void onMatchCompleted(int score1, int score2) {
    if (isMatchComplete) return;
    List<KoSet> sets = _match.sets;
    if (!isCurrentSetCompleted && (score1 > 0 || score2 > 0)) {
      sets = [...sets, KoSet(score1: score1, score2: score2, isCompleted: true)];
    }
    final t1 = sets.where((s) => s.isCompleted && s.score1 > s.score2).length;
    final t2 = sets.where((s) => s.isCompleted && s.score2 > s.score1).length;
    final winnerId = t1 > t2 ? _match.team1Id : _match.team2Id;
    _pendingScore1 = 0;
    _pendingScore2 = 0;
    _activeSetIndex = sets.length;
    _persistMatch(
      _match.copyWith(
        sets: sets,
        winnerId: winnerId,
        status: KoMatchStatus.completed,
        completedAt: DateTime.now(),
        clearLiveScores: true,
      ),
      propagateWinner: true,
    );
  }

  /// Reverts a completed match back to in-progress on the last set.
  void onMatchCompletionUndone() {
    if (_match.sets.isEmpty) return;
    final last = _match.sets.last;
    final newSets = _match.sets.sublist(0, _match.sets.length - 1);
    _pendingScore1 = last.score1;
    _pendingScore2 = last.score2;
    _activeSetIndex = newSets.length;
    _persistMatch(_match.copyWith(
      sets: newSets,
      winnerId: null,
      status: KoMatchStatus.inProgress,
      completedAt: null,
    ));
  }

  /// Persists live scores mid-set and notifies parent (called from _saveAndBack).
  void onLiveScoreChanged(int score1, int score2) {
    if (isCurrentSetCompleted || (score1 == 0 && score2 == 0)) return;
    _pendingScore1 = score1;
    _pendingScore2 = score2;
    _persistMatch(_match.copyWith(liveScore1: score1, liveScore2: score2));
  }

  /// Saves live scores to storage only — does NOT call [_onChanged] (safe to
  /// call from dispose() where setState is forbidden).
  void flushLiveScoreToStorage(int score1, int score2) {
    if (isCurrentSetCompleted || (score1 == 0 && score2 == 0)) return;
    _pendingScore1 = score1;
    _pendingScore2 = score2;
    final updatedMatch = _match.copyWith(liveScore1: score1, liveScore2: score2);
    final updated = _tournament.updateMatch(updatedMatch);
    KoBracketStorageService.save(updated);
    _tournament = updated;
    _match = updated.matches.firstWhere((m) => m.id == _matchId);
    _fmt = updated.formatForRound(_match.round);
    // Deliberately does NOT call _onChanged to avoid setState during tree finalisation.
  }

  /// Applies an arbitrary non-scoring mutation to the match (e.g. startedAt, suggestions).
  void updateMatch(KoMatch Function(KoMatch) mutate) {
    _persistMatch(mutate(_match));
  }

  // ── Internal ──────────────────────────────────────────────────────────────

  void _persistMatch(KoMatch updatedMatch, {bool propagateWinner = false}) {
    var updated = _tournament.updateMatch(updatedMatch);

    if (propagateWinner && updatedMatch.winnerId != null && updatedMatch.isComplete) {
      final propagated = updatedMatch.round == 0
          ? KoBracketGenerator.propagatePlayInWinner(updated.matches, updatedMatch.id)
          : KoBracketGenerator.propagateWinner(updated.matches, updatedMatch.id);
      updated = updated.copyWith(matches: propagated);
    }

    if (updated.allMatchesComplete) {
      updated = updated.copyWith(status: KoBracketStatus.completed);
    } else if (updated.status == KoBracketStatus.setup) {
      updated = updated.copyWith(status: KoBracketStatus.inProgress);
    } else if (updated.status == KoBracketStatus.completed && !updated.allMatchesComplete) {
      updated = updated.copyWith(status: KoBracketStatus.inProgress);
    }

    KoBracketStorageService.save(updated);
    _tournament = updated;
    _match = updated.matches.firstWhere((m) => m.id == _matchId);
    _fmt = updated.formatForRound(_match.round);
    _onChanged(updated);
  }
}
