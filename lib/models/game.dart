import 'game_result.dart';
import 'game_set.dart';
import 'game_team_lineup.dart';

enum GameStatus {
  scheduled,
  inProgress,
  completed,
}

enum GameSource {
  tournament,
  quickLocal,
}

enum MatchFormat {
  oneSet,
  bestOfThree,
  custom,
}

class Game {
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

  const Game({
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
  });

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
    );
  }

  Map<String, dynamic> toJson() => {
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
      );
}
