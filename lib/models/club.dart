class Club {
  final String id;
  final String name;
  final List<String> playerIds;
  final List<String> teamIds;
  final List<String> tournamentIds;

  const Club({
    required this.id,
    required this.name,
    this.playerIds = const [],
    this.teamIds = const [],
    this.tournamentIds = const [],
  });

  Club copyWith({
    String? id,
    String? name,
    List<String>? playerIds,
    List<String>? teamIds,
    List<String>? tournamentIds,
  }) {
    return Club(
      id: id ?? this.id,
      name: name ?? this.name,
      playerIds: playerIds ?? this.playerIds,
      teamIds: teamIds ?? this.teamIds,
      tournamentIds: tournamentIds ?? this.tournamentIds,
    );
  }

  Club addPlayerId(String playerId) {
    if (playerIds.contains(playerId)) return this;
    return copyWith(playerIds: [...playerIds, playerId]);
  }

  Club removePlayerId(String playerId) {
    return copyWith(playerIds: playerIds.where((id) => id != playerId).toList());
  }

  Club addTeamId(String teamId) {
    if (teamIds.contains(teamId)) return this;
    return copyWith(teamIds: [...teamIds, teamId]);
  }

  Club removeTeamId(String teamId) {
    return copyWith(teamIds: teamIds.where((id) => id != teamId).toList());
  }

  Club addTournamentId(String tournamentId) {
    if (tournamentIds.contains(tournamentId)) return this;
    return copyWith(tournamentIds: [...tournamentIds, tournamentId]);
  }

  Club removeTournamentId(String tournamentId) {
    return copyWith(
      tournamentIds: tournamentIds.where((id) => id != tournamentId).toList(),
    );
  }
}
