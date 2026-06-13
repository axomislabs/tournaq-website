import 'package:uuid/uuid.dart';
import '../models/player.dart';
import '../models/club.dart';
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
///   - [tournaments] and [clubs] are in-memory only in v1. They are rebuilt
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
  final List<Club> clubs;

  const AppState({
    this.players = const [],
    this.teams = const [],
    this.games = const [],
    this.clubs = const [],
  });

  AppState copyWith({
    List<Player>? players,
    List<Team>? teams,
    List<Game>? games,
    List<Club>? clubs,
  }) {
    return AppState(
      players: players ?? this.players,
      teams: teams ?? this.teams,
      games: games ?? this.games,
      clubs: clubs ?? this.clubs,
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

  // Club lookups
  Club? getClubById(String clubId) {
    try {
      return clubs.firstWhere((c) => c.id == clubId);
    } catch (e) {
      return null;
    }
  }

  List<Club> getClubsByIds(List<String> clubIds) {
    return clubs.where((c) => clubIds.contains(c.id)).toList();
  }

  List<Club> getPlayerClubs(String playerId) {
    return clubs.where((c) => c.playerIds.contains(playerId)).toList();
  }

  List<Club> getTeamClubs(String teamId) {
    return clubs.where((c) => c.teamIds.contains(teamId)).toList();
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

  // State mutation helpers — clubs
  AppState addClub(Club club) {
    return copyWith(clubs: [...clubs, club]);
  }

  AppState updateClub(Club club) {
    return copyWith(
      clubs: clubs.map((c) => c.id == club.id ? club : c).toList(),
    );
  }

  AppState removeClub(String clubId) {
    return copyWith(clubs: clubs.where((c) => c.id != clubId).toList());
  }

  static String generateId() {
    return const Uuid().v4();
  }
}
