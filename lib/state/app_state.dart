import 'package:uuid/uuid.dart';
import '../models/app_user.dart';
import '../models/team.dart';
import '../models/tournament.dart';
import '../models/game.dart';

class AppState {
  final List<AppUser> users;
  final List<Team> teams;
  final List<Tournament> tournaments;
  final List<Game> games;

  const AppState({
    this.users = const [],
    this.teams = const [],
    this.tournaments = const [],
    this.games = const [],
  });

  AppState copyWith({
    List<AppUser>? users,
    List<Team>? teams,
    List<Tournament>? tournaments,
    List<Game>? games,
  }) {
    return AppState(
      users: users ?? this.users,
      teams: teams ?? this.teams,
      tournaments: tournaments ?? this.tournaments,
      games: games ?? this.games,
    );
  }

  // User lookups
  AppUser? getUserById(String userId) {
    try {
      return users.firstWhere((u) => u.id == userId);
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

  List<AppUser> getUsersForTeam(String teamId) {
    final team = getTeamById(teamId);
    if (team == null) return [];
    return users.where((u) => team.userIds.contains(u.id)).toList();
  }

  // Tournament lookups
  Tournament? getTournamentById(String tournamentId) {
    try {
      return tournaments.firstWhere((t) => t.id == tournamentId);
    } catch (e) {
      return null;
    }
  }

  List<Tournament> getTeamTournaments(String teamId) {
    return tournaments.where((t) => t.teamIds.contains(teamId)).toList();
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

  List<Game> getTeamGames(String teamId) {
    return games.where((g) => g.isTeamInvolved(teamId)).toList();
  }

  // State mutation helpers
  AppState addUser(AppUser user) {
    return copyWith(users: [...users, user]);
  }

  AppState updateUser(AppUser user) {
    return copyWith(
      users: users.map((u) => u.id == user.id ? user : u).toList(),
    );
  }

  AppState removeUser(String userId) {
    return copyWith(users: users.where((u) => u.id != userId).toList());
  }

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

  AppState addTournament(Tournament tournament) {
    return copyWith(tournaments: [...tournaments, tournament]);
  }

  AppState updateTournament(Tournament tournament) {
    return copyWith(
      tournaments: tournaments
          .map((t) => t.id == tournament.id ? tournament : t)
          .toList(),
    );
  }

  AppState removeTournament(String tournamentId) {
    return copyWith(
      tournaments: tournaments.where((t) => t.id != tournamentId).toList(),
    );
  }

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

  static String generateId() {
    return const Uuid().v4();
  }
}
