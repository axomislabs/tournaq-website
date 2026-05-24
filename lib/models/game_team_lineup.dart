class GameTeamLineup {
  final String teamId;
  final List<String> playerNames;

  const GameTeamLineup({
    required this.teamId,
    this.playerNames = const [],
  });

  String playerName(int index) {
    if (index < playerNames.length && playerNames[index].isNotEmpty) {
      return playerNames[index];
    }
    return 'Player ${index + 1}';
  }

  GameTeamLineup copyWith({String? teamId, List<String>? playerNames}) {
    return GameTeamLineup(
      teamId: teamId ?? this.teamId,
      playerNames: playerNames ?? this.playerNames,
    );
  }

  Map<String, dynamic> toJson() => {
        'teamId': teamId,
        'playerNames': playerNames,
      };

  factory GameTeamLineup.fromJson(Map<String, dynamic> json) => GameTeamLineup(
        teamId: json['teamId'] as String,
        playerNames: List<String>.from(json['playerNames'] as List? ?? []),
      );
}
