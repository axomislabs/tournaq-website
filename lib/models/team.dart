/// How a team was created and how long it should be kept.
///
/// [temporary] — created for a single quick game; can be cleaned up later.
/// [tournament] — created as part of a tournament structure.
/// [club] — a standing team belonging to a club (persisted long-term).
///
/// Note: Scope is informational in v1. No automatic cleanup is implemented —
/// all teams persist in Hive until explicitly deleted.
enum TeamScope {
  temporary,
  tournament,
  club,
}

/// A team that participates in games and tournaments.
///
/// Teams hold references to their member [AppUser]s and [Tournament]s by ID.
/// The team's display name is the primary label shown throughout the scoring
/// and tournament UI.
///
/// Design decision — [schemaVersion]:
///   Added to prepare for future Hive or Firestore migration. When the Team
///   schema changes (e.g. adding a logoUrl), increment this version and add
///   a migration path in [LocalStorageService] or a future repository layer.
class Team {
  static const int schemaVersion = 1;
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

  Map<String, dynamic> toJson() => {
        'schemaVersion': schemaVersion,
        'id': id,
        'name': name,
        'userIds': userIds,
        'tournamentIds': tournamentIds,
        'scope': scope.name,
      };

  factory Team.fromJson(Map<String, dynamic> json) => Team(
        id: json['id'] as String,
        name: json['name'] as String,
        userIds: List<String>.from(json['userIds'] as List? ?? []),
        tournamentIds: List<String>.from(json['tournamentIds'] as List? ?? []),
        scope: TeamScope.values.firstWhere(
          (e) => e.name == json['scope'],
          orElse: () => TeamScope.temporary,
        ),
      );
}
