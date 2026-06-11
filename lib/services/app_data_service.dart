import '../models/player.dart';
import '../models/club.dart';
import '../models/game_set.dart';
import '../models/game_team_lineup.dart';
import '../models/team.dart';
import '../models/tournament.dart';
import '../models/tournament_mode.dart';
import '../models/game.dart';
import '../models/game_result.dart';
import '../services/tournament_logic_service.dart';
import '../state/app_state.dart';

/// Central application service layer for all entity mutations.
///
/// Every operation follows the same pattern:
///   1. Receive the current [AppState] and any required parameters.
///   2. Create or update the relevant model objects.
///   3. Return a new [AppState] reflecting the change.
///
/// Nothing in this class persists to storage — that is the caller's
/// responsibility. Pages call [LocalStorageService.saveAppState] (or granular
/// save methods) after receiving the updated state.
///
/// Design rationale — static methods on a single service class:
///   TournaQ v1 uses a static service model rather than injected repositories.
///   This is intentional: it avoids dependency injection overhead for a
///   single-user local app, keeps pages thin, and makes the data flow easy
///   to follow. The trade-off is reduced testability compared to injected
///   fakes — acceptable for v1's scope.
///
/// Separation of concerns:
///   - Scoring operations (set completion, score updates) live here.
///   - Pairing and standings logic is delegated to [TournamentLogicService].
///   - UI has no business logic — it calls this service and receives state.
///
/// Future: Before Firebase migration, extract entity-specific methods into
///   dedicated service classes (GameService, TeamService, TournamentService)
///   each backed by a Repository interface. [AppDataService] can remain as a
///   facade that delegates to those services.
class AppDataService {
  // USER OPERATIONS
  static AppState createUser(
    AppState state, {
    required String name,
    String? email,
    String? role,
  }) {
    final user = Player(
      id: AppState.generateId(),
      name: name,
      email: email,
      role: role,
    );
    return state.addPlayer(user);
  }

  static AppState deleteUser(AppState state, String userId) {
    var updatedState = state.removePlayer(userId);
    // Remove player from all clubs
    for (final club in state.clubs) {
      if (club.playerIds.contains(userId)) {
        updatedState = updatedState.updateClub(club.removePlayerId(userId));
      }
    }
    return updatedState;
  }

  static AppState updatePlayer(AppState state, Player user) {
    return state.updatePlayer(user);
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
    for (final user in state.players) {
      if (user.teamIds.contains(teamId)) {
        updatedState = updatedState.updatePlayer(user.removeTeamId(teamId));
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

  /// Creates a team and automatically adds two default placeholder players.
  static AppState createTeamWithPlayers(
    AppState state, {
    required String name,
    required TeamScope scope,
  }) {
    final teamId = AppState.generateId();
    final p1Id = AppState.generateId();
    final p2Id = AppState.generateId();

    final p1 = Player(id: p1Id, name: 'Player 1 $name', teamIds: [teamId]);
    final p2 = Player(id: p2Id, name: 'Player 2 $name', teamIds: [teamId]);
    final team = Team(id: teamId, name: name, scope: scope, userIds: [p1Id, p2Id]);

    return state.addPlayer(p1).addPlayer(p2).addTeam(team);
  }

  // TEAM-USER ASSIGNMENTS
  static AppState assignUserToTeam(
    AppState state, {
    required String userId,
    required String teamId,
  }) {
    final user = state.getPlayerById(userId);
    final team = state.getTeamById(teamId);

    if (user == null || team == null) return state;

    var updatedState = state.updatePlayer(user.addTeamId(teamId));
    updatedState = updatedState.updateTeam(team.addUserId(userId));
    return updatedState;
  }

  static AppState removeUserFromTeam(
    AppState state, {
    required String userId,
    required String teamId,
  }) {
    final user = state.getPlayerById(userId);
    final team = state.getTeamById(teamId);

    if (user == null || team == null) return state;

    var updatedState = state.updatePlayer(user.removeTeamId(teamId));
    updatedState = updatedState.updateTeam(team.removeUserId(userId));
    return updatedState;
  }

  /// Updates or creates two named players on a team, keeping AppState.users consistent.
  static AppState updateTeamPlayers(
    AppState state, {
    required String teamId,
    required String player1Name,
    required String player2Name,
  }) {
    final team = state.getTeamById(teamId);
    if (team == null) return state;

    var updatedState = state;
    final names = [player1Name, player2Name];
    final newUserIds = <String>[];

    for (int i = 0; i < 2; i++) {
      if (i < team.userIds.length) {
        final userId = team.userIds[i];
        final user = state.getPlayerById(userId);
        if (user != null) {
          updatedState = updatedState.updatePlayer(user.copyWith(name: names[i]));
          newUserIds.add(userId);
        } else {
          final newUser = Player(id: AppState.generateId(), name: names[i], teamIds: [teamId]);
          updatedState = updatedState.addPlayer(newUser);
          newUserIds.add(newUser.id);
        }
      } else {
        final newUser = Player(id: AppState.generateId(), name: names[i], teamIds: [teamId]);
        updatedState = updatedState.addPlayer(newUser);
        newUserIds.add(newUser.id);
      }
    }

    if (newUserIds.length != team.userIds.length ||
        !newUserIds.every((id) => team.userIds.contains(id))) {
      updatedState = updatedState.updateTeam(team.copyWith(userIds: newUserIds));
    }

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
    MatchFormat matchFormat = MatchFormat.oneSet,
  }) {
    final initialSet = GameSet(
      id: AppState.generateId(),
      setNumber: 1,
    );
    final game = Game(
      id: AppState.generateId(),
      tournamentId: tournamentId,
      team1Id: team1Id,
      team2Id: team2Id,
      round: round,
      matchFormat: matchFormat,
      sets: [initialSet],
      status: GameStatus.inProgress,
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

  static AppState createQuickGame(
    AppState state, {
    required String team1Id,
    required String team2Id,
    MatchFormat matchFormat = MatchFormat.oneSet,
  }) {
    final initialSet = GameSet(
      id: AppState.generateId(),
      setNumber: 1,
    );
    final game = Game(
      id: AppState.generateId(),
      team1Id: team1Id,
      team2Id: team2Id,
      round: 1,
      source: GameSource.quickLocal,
      isLocalOnly: true,
      matchFormat: matchFormat,
      sets: [initialSet],
      status: GameStatus.inProgress,
    );
    return state.addGame(game);
  }

  // SET OPERATIONS

  /// Returns the active GameSet for a game, or null if the game doesn't exist.
  static GameSet? getCurrentSet(AppState state, String gameId) {
    return state.getGameById(gameId)?.currentSet;
  }

  /// Updates score1/score2 on the current set without completing it.
  static AppState updateCurrentSetScore(
    AppState state, {
    required String gameId,
    required int score1,
    required int score2,
  }) {
    final game = state.getGameById(gameId);
    if (game == null || game.currentSet == null) return state;
    if (game.status == GameStatus.completed || game.currentSet!.isCompleted) return state;

    final updatedSet = game.currentSet!.copyWith(score1: score1, score2: score2);
    final updatedSets = List<GameSet>.from(game.sets);
    updatedSets[game.currentSetIndex] = updatedSet;

    return state.updateGame(game.copyWith(
      sets: updatedSets,
      status: GameStatus.inProgress,
    ));
  }

  /// Marks the current set as completed with final scores, then resolves match outcome.
  static AppState completeCurrentSet(
    AppState state, {
    required String gameId,
    required int score1,
    required int score2,
    required int targetPoints,
    String? winnerTeamId,
  }) {
    final game = state.getGameById(gameId);
    if (game == null || game.currentSet == null) return state;

    final winner = winnerTeamId ??
        (score1 > score2
            ? game.team1Id
            : score2 > score1
                ? game.team2Id
                : null);

    final completedSet = game.currentSet!.copyWith(
      score1: score1,
      score2: score2,
      targetPoints: targetPoints,
      winnerTeamId: winner,
      isCompleted: true,
      completedAt: DateTime.now(),
    );

    final updatedSets = List<GameSet>.from(game.sets);
    updatedSets[game.currentSetIndex] = completedSet;

    // Resolve match outcome on the updated game
    return _resolveMatchOutcome(state, game.copyWith(sets: updatedSets));
  }

  /// Advances to the next set. Adds a new GameSet if it doesn't exist yet.
  static AppState moveToNextSet(AppState state, String gameId) {
    final game = state.getGameById(gameId);
    if (game == null || game.isMatchComplete) return state;

    final nextIndex = game.currentSetIndex + 1;
    if (nextIndex >= game.maxSets) return state;

    var sets = List<GameSet>.from(game.sets);
    while (sets.length <= nextIndex) {
      sets.add(GameSet(
        id: AppState.generateId(),
        setNumber: sets.length + 1,
        targetPoints: game.currentSet?.targetPoints ?? 15,
      ));
    }

    return state.updateGame(game.copyWith(
      sets: sets,
      currentSetIndex: nextIndex,
      status: GameStatus.inProgress,
    ));
  }

  /// Upserts a team lineup for a game (replaces existing entry for that teamId).
  static AppState updateGameLineup(
    AppState state,
    String gameId,
    GameTeamLineup lineup,
  ) {
    final game = state.getGameById(gameId);
    if (game == null) return state;

    final updatedLineups = [
      ...game.lineups.where((l) => l.teamId != lineup.teamId),
      lineup,
    ];
    return state.updateGame(game.copyWith(lineups: updatedLineups));
  }

  /// Replaces a specific GameSet within a game by id.
  static AppState updateGameSet(
    AppState state,
    String gameId,
    GameSet updatedSet,
  ) {
    final game = state.getGameById(gameId);
    if (game == null) return state;

    final sets =
        game.sets.map((s) => s.id == updatedSet.id ? updatedSet : s).toList();
    return state.updateGame(game.copyWith(sets: sets));
  }

  /// Returns the winning team id based on current sets, or null if undecided.
  static String? calculateMatchWinner(AppState state, String gameId) {
    final game = state.getGameById(gameId);
    if (game == null) return null;
    if (game.team1SetsWon >= game.setsToWin) return game.team1Id;
    if (game.team2SetsWon >= game.setsToWin) return game.team2Id;
    return null;
  }

  // BACKWARDS COMPATIBILITY — use completeCurrentSet for new code
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

    // If the game has sets, delegate to completeCurrentSet
    if (game.sets.isNotEmpty) {
      return completeCurrentSet(
        state,
        gameId: gameId,
        score1: score1,
        score2: score2,
        targetPoints: targetPoints,
        winnerTeamId: winnerTeamId,
      );
    }

    // Legacy path for games without sets
    final result = GameResult(
      score1: score1,
      score2: score2,
      targetPoints: targetPoints,
      winnerTeamId: winnerTeamId,
    );
    return state.updateGame(game.copyWith(
      result: result,
      status: GameStatus.completed,
    ));
  }

  /// Completes a specific set by index without auto-completing the game.
  static AppState completeSet(
    AppState state, {
    required String gameId,
    required int setIndex,
    required int score1,
    required int score2,
    required int targetPoints,
    String? winnerTeamId,
  }) {
    final game = state.getGameById(gameId);
    if (game == null || setIndex >= game.sets.length) return state;
    if (game.status == GameStatus.completed) return state;

    final set = game.sets[setIndex];
    final winner = winnerTeamId ??
        (score1 > score2
            ? game.team1Id
            : score2 > score1
                ? game.team2Id
                : null);

    final completedSet = GameSet(
      id: set.id,
      setNumber: set.setNumber,
      score1: score1,
      score2: score2,
      targetPoints: targetPoints,
      winnerTeamId: winner,
      isCompleted: true,
      completedAt: DateTime.now(),
    );

    final updatedSets = List<GameSet>.from(game.sets);
    updatedSets[setIndex] = completedSet;

    return state.updateGame(game.copyWith(
      sets: updatedSets,
      status: GameStatus.inProgress,
    ));
  }

  /// Undoes completion of a specific set by index.
  static AppState undoSetCompletion(
    AppState state, {
    required String gameId,
    required int setIndex,
  }) {
    final game = state.getGameById(gameId);
    if (game == null || setIndex >= game.sets.length) return state;

    final set = game.sets[setIndex];
    final resetSet = GameSet(
      id: set.id,
      setNumber: set.setNumber,
      score1: set.score1,
      score2: set.score2,
      targetPoints: set.targetPoints,
      winnerTeamId: null,
      isCompleted: false,
      completedAt: null,
    );

    final updatedSets = List<GameSet>.from(game.sets);
    updatedSets[setIndex] = resetSet;

    final winner = _getMatchWinnerFromSets(game.copyWith(sets: updatedSets));

    final finalGame = Game(
      id: game.id,
      tournamentId: game.tournamentId,
      team1Id: game.team1Id,
      team2Id: game.team2Id,
      round: game.round,
      status: winner != null ? GameStatus.completed : GameStatus.inProgress,
      result: game.result,
      source: game.source,
      isLocalOnly: game.isLocalOnly,
      matchFormat: game.matchFormat,
      sets: updatedSets,
      currentSetIndex: game.currentSetIndex,
      matchWinnerTeamId: winner,
      lineups: game.lineups,
      hasShownScorecardIntro: game.hasShownScorecardIntro,
    );

    return state.updateGame(finalGame);
  }

  /// Changes the active set to setIndex, creating intermediate sets lazily.
  static AppState setActiveSet(AppState state, String gameId, int setIndex) {
    final game = state.getGameById(gameId);
    if (game == null || setIndex < 0 || setIndex >= game.maxSets) return state;

    var sets = List<GameSet>.from(game.sets);
    while (sets.length <= setIndex) {
      sets.add(GameSet(
        id: AppState.generateId(),
        setNumber: sets.length + 1,
        targetPoints: game.currentSet?.targetPoints ?? 15,
      ));
    }

    return state.updateGame(game.copyWith(
      sets: sets,
      currentSetIndex: setIndex,
      status: game.status == GameStatus.scheduled
          ? GameStatus.inProgress
          : game.status,
    ));
  }

  /// Marks the game as completed based on current sets.
  static AppState completeGame(AppState state, String gameId) {
    final game = state.getGameById(gameId);
    if (game == null || game.status == GameStatus.completed) return state;

    final winner = _getMatchWinnerFromSets(game);

    final finalGame = Game(
      id: game.id,
      tournamentId: game.tournamentId,
      team1Id: game.team1Id,
      team2Id: game.team2Id,
      round: game.round,
      status: GameStatus.completed,
      result: game.result,
      source: game.source,
      isLocalOnly: game.isLocalOnly,
      matchFormat: game.matchFormat,
      sets: game.sets,
      currentSetIndex: game.currentSetIndex,
      matchWinnerTeamId: winner,
      lineups: game.lineups,
      hasShownScorecardIntro: game.hasShownScorecardIntro,
    );

    return state.updateGame(finalGame);
  }

  /// Reverts a completed game back to in-progress, clearing the match winner.
  /// Resets the last completed set (for all formats) so isMatchComplete becomes false.
  static AppState undoGameCompletion(AppState state, String gameId) {
    final game = state.getGameById(gameId);
    if (game == null) return state;

    var sets = List<GameSet>.from(game.sets);

    // Find the last completed set and reopen it so sets-based isMatchComplete clears.
    int lastCompletedIndex = -1;
    for (int i = sets.length - 1; i >= 0; i--) {
      if (sets[i].isCompleted) {
        lastCompletedIndex = i;
        break;
      }
    }

    if (lastCompletedIndex >= 0) {
      final s = sets[lastCompletedIndex];
      sets[lastCompletedIndex] = GameSet(
        id: s.id,
        setNumber: s.setNumber,
        score1: s.score1,
        score2: s.score2,
        targetPoints: s.targetPoints,
        winnerTeamId: null,
        isCompleted: false,
        completedAt: null,
      );
    }

    final activeSetIndex = lastCompletedIndex >= 0 ? lastCompletedIndex : game.currentSetIndex;

    final resetGame = Game(
      id: game.id,
      tournamentId: game.tournamentId,
      team1Id: game.team1Id,
      team2Id: game.team2Id,
      round: game.round,
      status: GameStatus.inProgress,
      result: game.result,
      source: game.source,
      isLocalOnly: game.isLocalOnly,
      matchFormat: game.matchFormat,
      sets: sets,
      currentSetIndex: activeSetIndex,
      matchWinnerTeamId: null,
      lineups: game.lineups,
      hasShownScorecardIntro: game.hasShownScorecardIntro,
    );

    return state.updateGame(resetGame);
  }

  /// Returns the winning team id based on completed sets, or null if undecided.
  static String? calculateMatchWinnerFromSets(AppState state, String gameId) {
    final game = state.getGameById(gameId);
    if (game == null) return null;
    return _getMatchWinnerFromSets(game);
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
    if (club == null || state.getPlayerById(playerId) == null) return state;
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

  // PRIVATE HELPERS

  static AppState clearLocalHistoryData(AppState state) {
    return const AppState();
  }

  static String? _getMatchWinnerFromSets(Game game) {
    if (game.team1SetsWon >= game.setsToWin) return game.team1Id;
    if (game.team2SetsWon >= game.setsToWin) return game.team2Id;
    return null;
  }

  static AppState _resolveMatchOutcome(AppState state, Game game) {
    String? matchWinner;
    GameStatus status = game.status;

    if (game.team1SetsWon >= game.setsToWin) {
      matchWinner = game.team1Id;
      status = GameStatus.completed;
    } else if (game.team2SetsWon >= game.setsToWin) {
      matchWinner = game.team2Id;
      status = GameStatus.completed;
    } else if (game.sets.every((s) => s.isCompleted)) {
      // All sets played but no winner reached setsToWin (e.g. custom format draw)
      status = GameStatus.completed;
    }

    return state.updateGame(game.copyWith(
      matchWinnerTeamId: matchWinner ?? game.matchWinnerTeamId,
      status: status,
    ));
  }
}
