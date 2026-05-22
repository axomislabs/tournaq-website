import '../models/app_user.dart';
import '../models/club.dart';
import '../models/team.dart';
import '../models/tournament.dart';
import '../models/tournament_mode.dart';
import '../models/game.dart';
import '../models/game_result.dart';
import '../services/tournament_logic_service.dart';
import '../state/app_state.dart';

class AppDataService {
  // USER OPERATIONS
  static AppState createUser(
    AppState state, {
    required String name,
    String? email,
    String? role,
  }) {
    final user = AppUser(
      id: AppState.generateId(),
      name: name,
      email: email,
      role: role,
    );
    return state.addUser(user);
  }

  static AppState deleteUser(AppState state, String userId) {
    var updatedState = state.removeUser(userId);
    // Remove player from all clubs
    for (final club in state.clubs) {
      if (club.playerIds.contains(userId)) {
        updatedState = updatedState.updateClub(club.removePlayerId(userId));
      }
    }
    return updatedState;
  }

  static AppState updateUser(AppState state, AppUser user) {
    return state.updateUser(user);
  }

  // TEAM OPERATIONS
  static AppState createTeam(
    AppState state, {
    required String name,
    required TeamScope scope,
  }) {
    final team = Team(id: AppState.generateId(), name: name, scope: scope);
    return state.addTeam(team);
  }

  static AppState deleteTeam(AppState state, String teamId) {
    var updatedState = state;
    // Remove team from all users
    for (final user in state.users) {
      if (user.teamIds.contains(teamId)) {
        updatedState = updatedState.updateUser(user.removeTeamId(teamId));
      }
    }
    // Remove team from all tournaments
    for (final tournament in state.tournaments) {
      if (tournament.teamIds.contains(teamId)) {
        updatedState = updatedState.updateTournament(
          tournament.removeTeamId(teamId),
        );
      }
    }
    // Remove team from all clubs
    for (final club in state.clubs) {
      if (club.teamIds.contains(teamId)) {
        updatedState = updatedState.updateClub(club.removeTeamId(teamId));
      }
    }
    return updatedState.removeTeam(teamId);
  }

  static AppState updateTeam(AppState state, Team team) {
    return state.updateTeam(team);
  }

  // TEAM-USER ASSIGNMENTS
  static AppState assignUserToTeam(
    AppState state, {
    required String userId,
    required String teamId,
  }) {
    final user = state.getUserById(userId);
    final team = state.getTeamById(teamId);

    if (user == null || team == null) return state;

    var updatedState = state.updateUser(user.addTeamId(teamId));
    updatedState = updatedState.updateTeam(team.addUserId(userId));
    return updatedState;
  }

  static AppState removeUserFromTeam(
    AppState state, {
    required String userId,
    required String teamId,
  }) {
    final user = state.getUserById(userId);
    final team = state.getTeamById(teamId);

    if (user == null || team == null) return state;

    var updatedState = state.updateUser(user.removeTeamId(teamId));
    updatedState = updatedState.updateTeam(team.removeUserId(userId));
    return updatedState;
  }

  // TOURNAMENT OPERATIONS
  static AppState createTournament(
    AppState state, {
    required String name,
    required TournamentMode mode,
  }) {
    final tournament = Tournament(
      id: AppState.generateId(),
      name: name,
      mode: mode,
    );
    return state.addTournament(tournament);
  }

  static AppState deleteTournament(AppState state, String tournamentId) {
    var updatedState = state;
    // Remove tournament from all teams
    for (final team in state.teams) {
      if (team.tournamentIds.contains(tournamentId)) {
        updatedState = updatedState.updateTeam(
          team.removeTournamentId(tournamentId),
        );
      }
    }
    // Delete all games in tournament
    final tournamentGames = state.getTournamentGames(tournamentId);
    for (final game in tournamentGames) {
      updatedState = updatedState.removeGame(game.id);
    }
    // Remove tournament from all clubs
    for (final club in state.clubs) {
      if (club.tournamentIds.contains(tournamentId)) {
        updatedState = updatedState.updateClub(
          club.removeTournamentId(tournamentId),
        );
      }
    }
    return updatedState.removeTournament(tournamentId);
  }

  static AppState updateTournament(AppState state, Tournament tournament) {
    return state.updateTournament(tournament);
  }

  // TEAM-TOURNAMENT ASSIGNMENTS
  static AppState assignTeamToTournament(
    AppState state, {
    required String teamId,
    required String tournamentId,
  }) {
    final team = state.getTeamById(teamId);
    final tournament = state.getTournamentById(tournamentId);

    if (team == null || tournament == null) return state;

    var updatedState = state.updateTeam(team.addTournamentId(tournamentId));
    updatedState = updatedState.updateTournament(tournament.addTeamId(teamId));
    return updatedState;
  }

  static AppState removeTeamFromTournament(
    AppState state, {
    required String teamId,
    required String tournamentId,
  }) {
    final team = state.getTeamById(teamId);
    final tournament = state.getTournamentById(tournamentId);

    if (team == null || tournament == null) return state;

    var updatedState = state.updateTeam(team.removeTournamentId(tournamentId));
    updatedState = updatedState.updateTournament(
      tournament.removeTeamId(teamId),
    );
    return updatedState;
  }

  // GAME OPERATIONS
  static AppState createGame(
    AppState state, {
    required String tournamentId,
    required String team1Id,
    required String team2Id,
    required int round,
  }) {
    final game = Game(
      id: AppState.generateId(),
      tournamentId: tournamentId,
      team1Id: team1Id,
      team2Id: team2Id,
      round: round,
    );

    var updatedState = state.addGame(game);
    final tournament = state.getTournamentById(tournamentId);
    if (tournament != null) {
      updatedState = updatedState.updateTournament(
        tournament.addGameId(game.id),
      );
    }
    return updatedState;
  }

  static AppState generateGamesForTournament(
    AppState state,
    Tournament tournament,
  ) {
    if (tournament.gameIds.isNotEmpty) return state;

    final pairings = TournamentLogicService.generatePairings(state, tournament);
    var updatedState = state;
    var round = 1;

    for (final pairing in pairings) {
      updatedState = createGame(
        updatedState,
        tournamentId: tournament.id,
        team1Id: pairing.team1Id,
        team2Id: pairing.team2Id,
        round: round,
      );
      round++;
    }

    return updatedState;
  }

  static AppState updateGameResult(
    AppState state, {
    required String gameId,
    required int score1,
    required int score2,
    required int targetPoints,
    String? winnerTeamId,
  }) {
    final game = state.getGameById(gameId);
    if (game == null) return state;

    final result = GameResult(
      score1: score1,
      score2: score2,
      targetPoints: targetPoints,
      winnerTeamId: winnerTeamId,
    );

    final updatedGame = game.copyWith(
      result: result,
      status: GameStatus.completed,
    );

    return state.updateGame(updatedGame);
  }

  static AppState deleteGame(AppState state, String gameId) {
    final game = state.getGameById(gameId);
    if (game == null) return state;

    var updatedState = state.removeGame(gameId);
    final tournament = game.tournamentId != null
        ? state.getTournamentById(game.tournamentId!)
        : null;
    if (tournament != null) {
      updatedState = updatedState.updateTournament(
        tournament.removeGameId(gameId),
      );
    }
    return updatedState;
  }

  static AppState createQuickGame(
    AppState state, {
    required String team1Id,
    required String team2Id,
  }) {
    final game = Game(
      id: AppState.generateId(),
      team1Id: team1Id,
      team2Id: team2Id,
      round: 1,
      source: GameSource.quickLocal,
      isLocalOnly: true,
    );
    return state.addGame(game);
  }

  // CLUB OPERATIONS
  static AppState createClub(AppState state, {required String name}) {
    final club = Club(id: AppState.generateId(), name: name);
    return state.addClub(club);
  }

  static AppState updateClub(AppState state, Club club) {
    return state.updateClub(club);
  }

  static AppState deleteClub(AppState state, String clubId) {
    return state.removeClub(clubId);
  }

  // CLUB-PLAYER ASSIGNMENTS
  static AppState assignPlayerToClub(
    AppState state, {
    required String playerId,
    required String clubId,
  }) {
    final club = state.getClubById(clubId);
    if (club == null || state.getUserById(playerId) == null) return state;
    return state.updateClub(club.addPlayerId(playerId));
  }

  static AppState removePlayerFromClub(
    AppState state, {
    required String playerId,
    required String clubId,
  }) {
    final club = state.getClubById(clubId);
    if (club == null) return state;
    return state.updateClub(club.removePlayerId(playerId));
  }

  // CLUB-TEAM ASSIGNMENTS
  static AppState assignTeamToClub(
    AppState state, {
    required String teamId,
    required String clubId,
  }) {
    final club = state.getClubById(clubId);
    if (club == null || state.getTeamById(teamId) == null) return state;
    return state.updateClub(club.addTeamId(teamId));
  }

  static AppState removeTeamFromClub(
    AppState state, {
    required String teamId,
    required String clubId,
  }) {
    final club = state.getClubById(clubId);
    if (club == null) return state;
    return state.updateClub(club.removeTeamId(teamId));
  }

  // CLUB-TOURNAMENT ASSIGNMENTS
  static AppState assignTournamentToClub(
    AppState state, {
    required String tournamentId,
    required String clubId,
  }) {
    final club = state.getClubById(clubId);
    if (club == null || state.getTournamentById(tournamentId) == null) {
      return state;
    }
    return state.updateClub(club.addTournamentId(tournamentId));
  }

  static AppState removeTournamentFromClub(
    AppState state, {
    required String tournamentId,
    required String clubId,
  }) {
    final club = state.getClubById(clubId);
    if (club == null) return state;
    return state.updateClub(club.removeTournamentId(tournamentId));
  }
}
