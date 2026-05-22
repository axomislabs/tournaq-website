enum TeamScope {
  temporary,
  tournament,
  club,
}

class Team {
  final String id;
  final String name;
  final List<String> userIds;
  final List<String> tournamentIds;
  final TeamScope scope;

  const Team({
    required this.id,
    required this.name,
    this.userIds = const [],
    this.tournamentIds = const [],
    this.scope = TeamScope.temporary,
  });

  Team copyWith({
    String? id,
    String? name,
    List<String>? userIds,
    List<String>? tournamentIds,
    TeamScope? scope,
  }) {
    return Team(
      id: id ?? this.id,
      name: name ?? this.name,
      userIds: userIds ?? this.userIds,
      tournamentIds: tournamentIds ?? this.tournamentIds,
      scope: scope ?? this.scope,
    );
  }

  Team addUserId(String userId) {
    if (userIds.contains(userId)) return this;
    return copyWith(userIds: [...userIds, userId]);
  }

  Team removeUserId(String userId) {
    return copyWith(
      userIds: userIds.where((id) => id != userId).toList(),
    );
  }

  Team addTournamentId(String tournamentId) {
    if (tournamentIds.contains(tournamentId)) return this;
    return copyWith(tournamentIds: [...tournamentIds, tournamentId]);
  }

  Team removeTournamentId(String tournamentId) {
    return copyWith(
      tournamentIds: tournamentIds.where((id) => id != tournamentId).toList(),
    );
  }
}
