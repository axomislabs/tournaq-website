class GameTeamLineup {
  final String teamId;
  final List<String> playerNames;  // active players, ordered by position (0 = serves first)
  final List<String> benchNames;   // players sitting out

  const GameTeamLineup({
    required this.teamId,
    this.playerNames = const [],
    this.benchNames = const [],
  });

  String playerName(int index) {
    if (index < playerNames.length && playerNames[index].isNotEmpty) {
      return playerNames[index];
    }
    return 'Player ${index + 1}';
  }

  GameTeamLineup copyWith({
    String? teamId,
    List<String>? playerNames,
    List<String>? benchNames,
  }) {
    return GameTeamLineup(
      teamId: teamId ?? this.teamId,
      playerNames: playerNames ?? this.playerNames,
      benchNames: benchNames ?? this.benchNames,
    );
  }

  Map<String, dynamic> toJson() => {
        'teamId': teamId,
        'playerNames': playerNames,
        'benchNames': benchNames,
      };

  factory GameTeamLineup.fromJson(Map<String, dynamic> json) => GameTeamLineup(
        teamId: json['teamId'] as String,
        playerNames: List<String>.from(json['playerNames'] as List? ?? []),
        benchNames: List<String>.from(json['benchNames'] as List? ?? []),
      );
}
