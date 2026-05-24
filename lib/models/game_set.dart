class GameSet {
  final String id;
  final int setNumber;
  final int score1;
  final int score2;
  final int targetPoints;
  final String? winnerTeamId;
  final bool isCompleted;
  final DateTime? completedAt;

  const GameSet({
    required this.id,
    required this.setNumber,
    this.score1 = 0,
    this.score2 = 0,
    this.targetPoints = 15,
    this.winnerTeamId,
    this.isCompleted = false,
    this.completedAt,
  });

  int get pointDifference => score1 - score2;
  bool get isDraw => isCompleted && winnerTeamId == null;

  GameSet copyWith({
    String? id,
    int? setNumber,
    int? score1,
    int? score2,
    int? targetPoints,
    String? winnerTeamId,
    bool? isCompleted,
    DateTime? completedAt,
  }) {
    return GameSet(
      id: id ?? this.id,
      setNumber: setNumber ?? this.setNumber,
      score1: score1 ?? this.score1,
      score2: score2 ?? this.score2,
      targetPoints: targetPoints ?? this.targetPoints,
      winnerTeamId: winnerTeamId ?? this.winnerTeamId,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'setNumber': setNumber,
        'score1': score1,
        'score2': score2,
        'targetPoints': targetPoints,
        'winnerTeamId': winnerTeamId,
        'isCompleted': isCompleted,
        'completedAt': completedAt?.toIso8601String(),
      };

  factory GameSet.fromJson(Map<String, dynamic> json) => GameSet(
        id: json['id'] as String,
        setNumber: json['setNumber'] as int,
        score1: json['score1'] as int? ?? 0,
        score2: json['score2'] as int? ?? 0,
        targetPoints: json['targetPoints'] as int? ?? 15,
        winnerTeamId: json['winnerTeamId'] as String?,
        isCompleted: json['isCompleted'] as bool? ?? false,
        completedAt: json['completedAt'] != null
            ? DateTime.parse(json['completedAt'] as String)
            : null,
      );
}
