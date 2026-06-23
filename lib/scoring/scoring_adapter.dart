import 'package:flutter/material.dart';
import '../models/game.dart';

/// Immutable snapshot of one set's state, as needed by [LiveScoringPage].
class AdapterSetInfo {
  final int score1;
  final int score2;
  final int targetPoints;
  final bool isCompleted;

  /// null = no winner yet; true = team1 won; false = team2 won.
  final bool? isTeam1Winner;

  const AdapterSetInfo({
    required this.score1,
    required this.score2,
    required this.targetPoints,
    required this.isCompleted,
    this.isTeam1Winner,
  });
}

/// Bridge between [LiveScoringPage] and a tournament-specific persistence layer.
///
/// All state exposed as getters is updated synchronously by the write
/// operations. After calling any write operation, [LiveScoringPage] calls
/// setState so the UI re-reads the updated getters.
///
/// Implementations:
///   - [QuickGameAdapter] — wraps AppState / AppDataService
///   - KOBracketAdapter (planned) — wraps KoBracketTournament
///   - LeagueAdapter, DoubleElimAdapter, … (future)
abstract class ScoringAdapter {
  // ── App-bar identity ───────────────────────────────────────────────────────
  String get pageTitle;
  String get pageSubtitle;

  // ── Teams ──────────────────────────────────────────────────────────────────
  String get team1Name;
  String get team2Name;

  /// Active-roster player names for each team (already resolved from
  /// whatever source the adapter uses — hub records, tournament snapshots, …).
  List<String> get team1Players;
  List<String> get team2Players;

  int get playersPerSide;

  // ── Format ─────────────────────────────────────────────────────────────────
  MatchFormat get matchFormat;
  int get maxSets;

  // ── Current state (re-read after every write operation) ────────────────────
  int get currentScore1;
  int get currentScore2;

  /// Target points for the active set, as persisted in the model.
  /// [LiveScoringPage] uses this as the initial value of its local
  /// [_targetPoints] state; changes made during a session are ephemeral until
  /// a set/match is completed.
  int get targetPoints;

  int get currentSetIndex;
  List<AdapterSetInfo> get sets;
  bool get isCurrentSetCompleted;
  bool get isMatchComplete;

  /// null = undecided; true = team1 won; false = team2 won.
  bool? get isTeam1Winner;

  // ── Capability flags ───────────────────────────────────────────────────────

  /// When true, [LiveScoringPage] renders the target-points ChoiceChips as
  /// interactive. Set false for tournament modes where target points are
  /// locked at tournament-creation time.
  bool get canEditTargetPoints;

  // ── Write operations ───────────────────────────────────────────────────────

  /// Persists the current live scores without completing the set.
  /// Called when navigating away mid-set.
  void onLiveScoreChanged(int score1, int score2);

  /// Marks the current set as completed with [score1]/[score2] and
  /// [targetPoints]. Updates internal state synchronously.
  void onSetCompleted(int score1, int score2, int targetPoints);

  /// Reverts the completion of [setIndex].
  void onSetUndone(int setIndex);

  /// Switches the active set to [setIndex], auto-saving the current live
  /// scores first.
  void onSetActivated(int setIndex, int currentScore1, int currentScore2);

  /// Finalises the match. For one-set formats, also completes the current set.
  void onMatchCompleted(int score1, int score2, int targetPoints);

  /// Reverts match completion back to in-progress.
  void onMatchCompletionUndone();

  // ── Optional capabilities (null = hide in UI) ──────────────────────────────

  /// When non-null, tapping a team name opens the lineup editor.
  /// The [BuildContext] is provided so the implementation can show sheets.
  /// [LiveScoringPage] calls setState after this Future resolves.
  Future<void> Function(bool isTeam1, BuildContext context)? get onEditLineup;

  /// When non-null, called instead of Navigator.pop() when the user
  /// presses "Save & Return". Useful when the caller's navigation stack
  /// doesn't have the expected page underneath.
  VoidCallback? get onSaveAndReturnOverride;
}
