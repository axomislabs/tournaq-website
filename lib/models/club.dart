/// A club groups players, teams, and tournaments under a single organization.
///
/// Clubs are currently in-memory only — they are NOT persisted to Hive in v1
/// because the full club management workflow is still evolving. This means
/// clubs are rebuilt from scratch on each app launch, which is intentional
/// for the initial release scope.
///
/// Future: Once club workflows stabilize, add a clubs_v1 Hive box in
/// [LocalStorageService] and drive persistence through [toJson]/[fromJson].
/// The serialization methods below are already implemented to remove the
/// blocker when that moment arrives.
///
/// Firebase note: In a Firebase-backed version, Club documents would live in
/// a `clubs` Firestore collection with subcollection references rather than
/// embedding ID lists directly.
class Club {
  static const int schemaVersion = 1;

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

  Map<String, dynamic> toJson() => {
        'schemaVersion': schemaVersion,
        'id': id,
        'name': name,
        'playerIds': playerIds,
        'teamIds': teamIds,
        'tournamentIds': tournamentIds,
      };

  factory Club.fromJson(Map<String, dynamic> json) => Club(
        id: json['id'] as String,
        name: json['name'] as String,
        playerIds: List<String>.from(json['playerIds'] as List? ?? []),
        teamIds: List<String>.from(json['teamIds'] as List? ?? []),
        tournamentIds: List<String>.from(json['tournamentIds'] as List? ?? []),
      );
}
