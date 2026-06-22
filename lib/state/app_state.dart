import 'package:uuid/uuid.dart';
import '../models/player.dart';
import '../models/group.dart';
import '../models/team.dart';
import '../models/game.dart';

/// Central, immutable application state tree for TournaQ.
///
/// Architecture principle:
///   Every entity lives exactly once in this tree. Pages and widgets receive
///   [AppState] as a parameter and return a new [AppState] (via [copyWith])
///   when they make changes. Nothing mutates in place — all writes produce a
///   new object and bubble up through the [onAppStateChanged] callback chain
///   to [_MyAppState] in main.dart, which persists the new state via
///   [LocalStorageService.saveAppState].
///
/// Storage model (v1):
///   - [games], [teams], [players] are persisted to Hive on every state change.
///   - [tournaments] and [groups] are in-memory only in v1. They are rebuilt
///     from the app's navigation flow on each session.
///
/// Design decision — normalized IDs, not embedded objects:
///   Entities reference each other by ID (e.g. [Team.userIds],
///   [Tournament.teamIds]). This prevents duplicate copies and makes updates
///   O(1) — only the owning list needs to change. Look up cross-references
///   using the typed accessor methods (e.g. [getTeamById], [getPlayerById]).
class AppState {
  final List<Player> players;
  final List<Team> teams;
  final List<Game> games;
  final List<Group> groups;

  const AppState({
    this.players = const [],
    this.teams = const [],
    this.games = const [],
    this.groups = const [],
  });

  AppState copyWith({
    List<Player>? players,
    List<Team>? teams,
    List<Game>? games,
    List<Group>? groups,
  }) {
    return AppState(
      players: players ?? this.players,
      teams: teams ?? this.teams,
      games: games ?? this.games,
      groups: groups ?? this.groups,
    );
  }

  // Player lookups
  Player? getPlayerById(String playerId) {
    try {
      return players.firstWhere((p) => p.id == playerId);
    } catch (e) {
      return null;
    }
  }

  // Team lookups
  Team? getTeamById(String teamId) {
    try {
      return teams.firstWhere((t) => t.id == teamId);
    } catch (e) {
      return null;
    }
  }

  List<Team> getTeamsByIds(List<String> teamIds) {
    return teams.where((t) => teamIds.contains(t.id)).toList();
  }

  List<Player> getPlayersForTeam(String teamId) {
    final team = getTeamById(teamId);
    if (team == null) return [];
    return players.where((p) => team.userIds.contains(p.id)).toList();
  }

  // Game lookups
  Game? getGameById(String gameId) {
    try {
      return games.firstWhere((g) => g.id == gameId);
    } catch (e) {
      return null;
    }
  }

  List<Game> getTournamentGames(String tournamentId) {
    return games.where((g) => g.tournamentId == tournamentId).toList();
  }

  List<Game> getQuickGames() {
    return games.where((g) => g.source == GameSource.quickLocal).toList();
  }

  List<Game> getTeamGames(String teamId) {
    return games.where((g) => g.isTeamInvolved(teamId)).toList();
  }

  // Group lookups
  Group? getGroupById(String groupId) {
    try {
      return groups.firstWhere((c) => c.id == groupId);
    } catch (e) {
      return null;
    }
  }

  List<Group> getGroupsByIds(List<String> groupIds) {
    return groups.where((c) => groupIds.contains(c.id)).toList();
  }

  List<Group> getPlayerGroups(String playerId) {
    return groups.where((c) => c.playerIds.contains(playerId)).toList();
  }

  List<Group> getTeamGroups(String teamId) {
    return groups.where((c) => c.teamIds.contains(teamId)).toList();
  }

  // State mutation helpers — players
  AppState addPlayer(Player player) {
    return copyWith(players: [...players, player]);
  }

  AppState updatePlayer(Player player) {
    return copyWith(
      players: players.map((p) => p.id == player.id ? player : p).toList(),
    );
  }

  AppState removePlayer(String playerId) {
    return copyWith(players: players.where((p) => p.id != playerId).toList());
  }

  // State mutation helpers — teams
  AppState addTeam(Team team) {
    return copyWith(teams: [...teams, team]);
  }

  AppState updateTeam(Team team) {
    return copyWith(
      teams: teams.map((t) => t.id == team.id ? team : t).toList(),
    );
  }

  AppState removeTeam(String teamId) {
    return copyWith(teams: teams.where((t) => t.id != teamId).toList());
  }

  // State mutation helpers — games
  AppState addGame(Game game) {
    return copyWith(games: [...games, game]);
  }

  AppState updateGame(Game game) {
    return copyWith(
      games: games.map((g) => g.id == game.id ? game : g).toList(),
    );
  }

  AppState removeGame(String gameId) {
    return copyWith(games: games.where((g) => g.id != gameId).toList());
  }

  // State mutation helpers — groups
  AppState addGroup(Group group) {
    return copyWith(groups: [...groups, group]);
  }

  AppState updateGroup(Group group) {
    return copyWith(
      groups: groups.map((c) => c.id == group.id ? group : c).toList(),
    );
  }

  AppState removeGroup(String groupId) {
    return copyWith(groups: groups.where((c) => c.id != groupId).toList());
  }

  static String generateId() {
    return const Uuid().v4();
  }
}
