import 'tournament_mode.dart';

enum TournamentStatus {
  draft,
  inProgress,
  completed,
}

class Tournament {
  final String id;
  final String name;
  final TournamentMode mode;
  final List<String> teamIds;
  final List<String> gameIds;
  final TournamentStatus status;

  const Tournament({
    required this.id,
    required this.name,
    required this.mode,
    this.teamIds = const [],
    this.gameIds = const [],
    this.status = TournamentStatus.draft,
  });

  Tournament copyWith({
    String? id,
    String? name,
    TournamentMode? mode,
    List<String>? teamIds,
    List<String>? gameIds,
    TournamentStatus? status,
  }) {
    return Tournament(
      id: id ?? this.id,
      name: name ?? this.name,
      mode: mode ?? this.mode,
      teamIds: teamIds ?? this.teamIds,
      gameIds: gameIds ?? this.gameIds,
      status: status ?? this.status,
    );
  }

  Tournament addTeamId(String teamId) {
    if (teamIds.contains(teamId)) return this;
    return copyWith(teamIds: [...teamIds, teamId]);
  }

  Tournament removeTeamId(String teamId) {
    return copyWith(
      teamIds: teamIds.where((id) => id != teamId).toList(),
    );
  }

  Tournament addGameId(String gameId) {
    if (gameIds.contains(gameId)) return this;
    return copyWith(gameIds: [...gameIds, gameId]);
  }

  Tournament removeGameId(String gameId) {
    return copyWith(
      gameIds: gameIds.where((id) => id != gameId).toList(),
    );
  }
}
