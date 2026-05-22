import 'game_result.dart';

enum GameStatus {
  scheduled,
  inProgress,
  completed,
}

class Game {
  final String id;
  final String tournamentId;
  final String team1Id;
  final String team2Id;
  final int round;
  final GameStatus status;
  final GameResult? result;

  const Game({
    required this.id,
    required this.tournamentId,
    required this.team1Id,
    required this.team2Id,
    required this.round,
    this.status = GameStatus.scheduled,
    this.result,
  });

  Game copyWith({
    String? id,
    String? tournamentId,
    String? team1Id,
    String? team2Id,
    int? round,
    GameStatus? status,
    GameResult? result,
  }) {
    return Game(
      id: id ?? this.id,
      tournamentId: tournamentId ?? this.tournamentId,
      team1Id: team1Id ?? this.team1Id,
      team2Id: team2Id ?? this.team2Id,
      round: round ?? this.round,
      status: status ?? this.status,
      result: result ?? this.result,
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
