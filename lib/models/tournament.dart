import 'tournament_mode.dart';

enum TournamentStatus { draft, inProgress, completed }

/// A tournament organizes teams into a structured competition with a defined
/// [TournamentMode] (league, elimination, swiss, etc.).
///
/// Design decision: Tournament objects hold only IDs referencing teams and
/// games — not the objects themselves. This keeps [AppState] as a normalized
/// store where entities have a single canonical copy.
///
/// Persistence note: Tournaments are NOT persisted to Hive in v1. The
/// tournament workflow requires all referenced teams and games to be available
/// simultaneously, so the most reliable approach is to reconstruct state from
/// the persisted games/teams and let the tournament scaffold be rebuilt on
/// each session. This is a conscious v1 trade-off that avoids complex
/// cross-entity migration logic.
///
/// Future: Add tournaments_v1 Hive persistence once the data model and
/// tournament workflows are stable. [toJson]/[fromJson] are implemented below
/// to unblock this.
///
/// Firebase: In a Firebase-backed version, Tournament maps to a top-level
/// `tournaments` collection. gameIds would become a subcollection or array
/// of document references.
class Tournament {
  static const int schemaVersion = 1;

  final String id;
  final String name;
  final TournamentMode mode;
  final List<String> teamIds;
  final List<String> gameIds;
  final TournamentStatus status;
  final List<List<TournamentModeType>> hybridGroups;

  const Tournament({
    required this.id,
    required this.name,
    required this.mode,
    this.teamIds = const [],
    this.gameIds = const [],
    this.status = TournamentStatus.draft,
    this.hybridGroups = const [],
  });

  Tournament copyWith({
    String? id,
    String? name,
    TournamentMode? mode,
    List<String>? teamIds,
    List<String>? gameIds,
    TournamentStatus? status,
    List<List<TournamentModeType>>? hybridGroups,
  }) {
    return Tournament(
      id: id ?? this.id,
      name: name ?? this.name,
      mode: mode ?? this.mode,
      teamIds: teamIds ?? this.teamIds,
      gameIds: gameIds ?? this.gameIds,
      status: status ?? this.status,
      hybridGroups: hybridGroups ?? this.hybridGroups,
    );
  }

  Tournament addTeamId(String teamId) {
    if (teamIds.contains(teamId)) return this;
    return copyWith(teamIds: [...teamIds, teamId]);
  }

  Tournament removeTeamId(String teamId) {
    return copyWith(teamIds: teamIds.where((id) => id != teamId).toList());
  }

  Tournament addGameId(String gameId) {
    if (gameIds.contains(gameId)) return this;
    return copyWith(gameIds: [...gameIds, gameId]);
  }

  Tournament removeGameId(String gameId) {
    return copyWith(gameIds: gameIds.where((id) => id != gameId).toList());
  }

  Map<String, dynamic> toJson() => {
        'schemaVersion': schemaVersion,
        'id': id,
        'name': name,
        'modeType': mode.type.name,
        'teamIds': teamIds,
        'gameIds': gameIds,
        'status': status.name,
        'hybridGroups': hybridGroups
            .map((group) => group.map((t) => t.name).toList())
            .toList(),
      };

  factory Tournament.fromJson(Map<String, dynamic> json) {
    final modeType = TournamentModeType.values.firstWhere(
      (e) => e.name == json['modeType'],
      orElse: () => TournamentModeType.singleGame,
    );
    return Tournament(
      id: json['id'] as String,
      name: json['name'] as String,
      mode: TournamentMode.fromType(modeType),
      teamIds: List<String>.from(json['teamIds'] as List? ?? []),
      gameIds: List<String>.from(json['gameIds'] as List? ?? []),
      status: TournamentStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => TournamentStatus.draft,
      ),
      hybridGroups: (json['hybridGroups'] as List? ?? [])
          .map((group) => (group as List)
              .map((name) => TournamentModeType.values.firstWhere(
                    (e) => e.name == name,
                    orElse: () => TournamentModeType.singleGame,
                  ))
              .toList())
          .toList(),
    );
  }
}
