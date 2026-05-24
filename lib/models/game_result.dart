class GameResult {
  final int score1;
  final int score2;
  final int targetPoints;
  final String? winnerTeamId;

  const GameResult({
    required this.score1,
    required this.score2,
    required this.targetPoints,
    this.winnerTeamId,
  });

  int get pointDifference => score1 - score2;

  GameResult copyWith({
    int? score1,
    int? score2,
    int? targetPoints,
    String? winnerTeamId,
  }) {
    return GameResult(
      score1: score1 ?? this.score1,
      score2: score2 ?? this.score2,
      targetPoints: targetPoints ?? this.targetPoints,
      winnerTeamId: winnerTeamId ?? this.winnerTeamId,
    );
  }

  Map<String, dynamic> toJson() => {
        'score1': score1,
        'score2': score2,
        'targetPoints': targetPoints,
        'winnerTeamId': winnerTeamId,
      };

  factory GameResult.fromJson(Map<String, dynamic> json) => GameResult(
        score1: json['score1'] as int,
        score2: json['score2'] as int,
        targetPoints: json['targetPoints'] as int? ?? 15,
        winnerTeamId: json['winnerTeamId'] as String?,
      );
}
