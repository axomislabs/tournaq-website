import 'game_result.dart';

enum GameStatus {
  scheduled,
  inProgress,
  completed,
}

enum GameSource {
  tournament,
  quickLocal,
}

class Game {
  final String id;
  final String? tournamentId;
  final String team1Id;
  final String team2Id;
  final int round;
  final GameStatus status;
  final GameResult? result;
  final GameSource source;
  final bool isLocalOnly;

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
  });

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
    );
  }

  bool isTeamInvolved(String teamId) {
    return team1Id == teamId || team2Id == teamId;
  }

  String getOpponentTeamId(String teamId) {
    if (team1Id == teamId) return team2Id;
    if (team2Id == teamId) return team1Id;
    return '';
  }
}
