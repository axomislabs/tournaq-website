import 'game_result.dart';
import 'game_set.dart';
import 'game_team_lineup.dart';
import '../services/device_id_service.dart';

enum GameStatus {
  scheduled,
  inProgress,
  completed,
}

/// Where a [Game] originated.
///
/// Design decision: games created outside a tournament ([quickLocal]) must
/// work without any tournament structure. This enum is the flag that drives
/// UI branching (e.g. hiding tournament-specific controls in quick games).
enum GameSource {
  tournament,
  quickLocal,
}

enum MatchFormat {
  oneSet,
  bestOfThree,
  custom,
}

/// A single match between two teams.
///
/// The core domain object in TournaQ. A [Game] is self-contained: it holds
/// all score data, set progression, and lineup information needed to replay
/// or display the match result without querying any other entity.
///
/// Match lifecycle:
///   [GameStatus.scheduled] → score page opened → [GameStatus.inProgress]
///   → all required sets completed → [GameStatus.completed]
///
/// Set model:
///   A [Game] contains a list of [GameSet] objects. Each set tracks its own
///   score independently. [currentSetIndex] points to the active set.
///   [completeCurrentSet] in [AppDataService] advances this index and records
///   the set winner. The match winner is computed from set wins via
///   [matchWinnerTeamId] (set explicitly) or derived from [team1SetsWon] /
///   [team2SetsWon].
///
/// Design decision — [result] field:
///   The legacy [GameResult] field is kept for backwards compatibility with
///   previously serialized games. New code uses [sets], [matchWinnerTeamId],
///   and the computed helpers ([team1SetsWon], [isMatchComplete]).
///
/// Design decision — [isLocalOnly]:
///   Reserved for future multi-device sync. Local-only games will be
///   excluded from Firebase upload until the user explicitly publishes them.
///
/// Firebase: Each [Game] will map to a Firestore document in a `games`
///   collection, with [sets] stored as a subcollection or embedded array.
///   [tournamentId] will become a document reference.
class Game {
  static const int schemaVersion = 2;
  final String id;
  final String? tournamentId;
  final String team1Id;
  final String team2Id;
  final int round;
  final GameStatus status;
  final GameResult? result; // kept for backwards compatibility
  final GameSource source;
  final bool isLocalOnly;
  final MatchFormat matchFormat;
  final List<GameSet> sets;
  final int currentSetIndex;
  final String? matchWinnerTeamId;
  final List<GameTeamLineup> lineups;
  final bool hasShownScorecardIntro;
  final String deviceId;
  final DateTime createdAt;

  Game({
    required this.id,
    this.tournamentId,
    required this.team1Id,
    required this.team2Id,
    required this.round,
    this.status = GameStatus.scheduled,
    this.result,
    this.source = GameSource.tournament,
    this.isLocalOnly = false,
    this.matchFormat = MatchFormat.oneSet,
    this.sets = const [],
    this.currentSetIndex = 0,
    this.matchWinnerTeamId,
    this.lineups = const [],
    this.hasShownScorecardIntro = false,
    String? deviceId,
    DateTime? createdAt,
  })  : deviceId = deviceId ?? DeviceIdService.currentDeviceId,
        createdAt = createdAt ?? DateTime.now();

  // ── Match format helpers ──────────────────────────────────────────────────

  int get maxSets => switch (matchFormat) {
        MatchFormat.oneSet => 1,
        MatchFormat.bestOfThree => 3,
        MatchFormat.custom => sets.length,
      };

  int get setsToWin => switch (matchFormat) {
        MatchFormat.oneSet => 1,
        MatchFormat.bestOfThree => 2,
        MatchFormat.custom => (sets.length / 2).ceil(),
      };

  // ── Set helpers ───────────────────────────────────────────────────────────

  GameSet? get currentSet =>
      currentSetIndex < sets.length ? sets[currentSetIndex] : null;

  int get team1SetsWon =>
      sets.where((s) => s.isCompleted && s.winnerTeamId == team1Id).length;

  int get team2SetsWon =>
      sets.where((s) => s.isCompleted && s.winnerTeamId == team2Id).length;

  bool get isMatchComplete =>
      status == GameStatus.completed ||
      matchWinnerTeamId != null ||
      team1SetsWon >= setsToWin ||
      team2SetsWon >= setsToWin;

  String? get effectiveWinnerTeamId {
    if (matchWinnerTeamId != null) return matchWinnerTeamId;
    if (team1SetsWon >= setsToWin) return team1Id;
    if (team2SetsWon >= setsToWin) return team2Id;
    // Fallback for stored games where winnerTeamId was not persisted on sets:
    // derive from raw set scores.
    var t1 = 0, t2 = 0;
    for (final s in sets) {
      if (s.isCompleted) {
        if (s.score1 > s.score2) t1++;
        else if (s.score2 > s.score1) t2++;
      }
    }
    if (t1 >= setsToWin) return team1Id;
    if (t2 >= setsToWin) return team2Id;
    return null;
  }

  // ── Existing helpers ──────────────────────────────────────────────────────

  bool isTeamInvolved(String teamId) =>
      team1Id == teamId || team2Id == teamId;

  String getOpponentTeamId(String teamId) {
    if (team1Id == teamId) return team2Id;
    if (team2Id == teamId) return team1Id;
    return '';
  }

  Game copyWith({
    String? id,
    String? tournamentId,
    String? team1Id,
    String? team2Id,
    int? round,
    GameStatus? status,
    GameResult? result,
    GameSource? source,
    bool? isLocalOnly,
    MatchFormat? matchFormat,
    List<GameSet>? sets,
    int? currentSetIndex,
    String? matchWinnerTeamId,
    List<GameTeamLineup>? lineups,
    bool? hasShownScorecardIntro,
  }) {
    return Game(
      id: id ?? this.id,
      tournamentId: tournamentId ?? this.tournamentId,
      team1Id: team1Id ?? this.team1Id,
      team2Id: team2Id ?? this.team2Id,
      round: round ?? this.round,
      status: status ?? this.status,
      result: result ?? this.result,
      source: source ?? this.source,
      isLocalOnly: isLocalOnly ?? this.isLocalOnly,
      matchFormat: matchFormat ?? this.matchFormat,
      sets: sets ?? this.sets,
      currentSetIndex: currentSetIndex ?? this.currentSetIndex,
      matchWinnerTeamId: matchWinnerTeamId ?? this.matchWinnerTeamId,
      lineups: lineups ?? this.lineups,
      hasShownScorecardIntro: hasShownScorecardIntro ?? this.hasShownScorecardIntro,
      deviceId: deviceId,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'schemaVersion': schemaVersion,
        'id': id,
        'tournamentId': tournamentId,
        'team1Id': team1Id,
        'team2Id': team2Id,
        'round': round,
        'status': status.name,
        'result': result?.toJson(),
        'source': source.name,
        'isLocalOnly': isLocalOnly,
        'matchFormat': matchFormat.name,
        'sets': sets.map((s) => s.toJson()).toList(),
        'currentSetIndex': currentSetIndex,
        'matchWinnerTeamId': matchWinnerTeamId,
        'lineups': lineups.map((l) => l.toJson()).toList(),
        'hasShownScorecardIntro': hasShownScorecardIntro,
        'deviceId': deviceId,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Game.fromJson(Map<String, dynamic> json) => Game(
        id: json['id'] as String,
        tournamentId: json['tournamentId'] as String?,
        team1Id: json['team1Id'] as String,
        team2Id: json['team2Id'] as String,
        round: json['round'] as int,
        status: GameStatus.values.firstWhere(
          (e) => e.name == json['status'],
          orElse: () => GameStatus.scheduled,
        ),
        result: json['result'] != null
            ? GameResult.fromJson(Map<String, dynamic>.from(json['result'] as Map))
            : null,
        source: GameSource.values.firstWhere(
          (e) => e.name == json['source'],
          orElse: () => GameSource.quickLocal,
        ),
        isLocalOnly: json['isLocalOnly'] as bool? ?? false,
        matchFormat: MatchFormat.values.firstWhere(
          (e) => e.name == json['matchFormat'],
          orElse: () => MatchFormat.oneSet,
        ),
        sets: (json['sets'] as List<dynamic>? ?? [])
            .map((s) => GameSet.fromJson(Map<String, dynamic>.from(s as Map)))
            .toList(),
        currentSetIndex: json['currentSetIndex'] as int? ?? 0,
        matchWinnerTeamId: json['matchWinnerTeamId'] as String?,
        lineups: (json['lineups'] as List<dynamic>? ?? [])
            .map((l) => GameTeamLineup.fromJson(Map<String, dynamic>.from(l as Map)))
            .toList(),
        hasShownScorecardIntro: json['hasShownScorecardIntro'] as bool? ?? false,
        deviceId: json['deviceId'] as String? ?? '',
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'] as String)
            : DateTime.fromMillisecondsSinceEpoch(0),
      );
}
