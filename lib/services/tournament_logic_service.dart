import 'dart:math';

import '../models/tournament.dart';
import '../models/tournament_mode.dart';
import '../state/app_state.dart';

class TournamentLogicService {
  // Generate all pairings for a tournament based on its mode
  static List<({String team1Id, String team2Id})> generatePairings(
    AppState state,
    Tournament tournament,
  ) {
    switch (tournament.mode.type) {
      case TournamentModeType.league:
        return _generateRoundRobinPairings(tournament.teamIds);
      case TournamentModeType.singleElimination:
        return _generateSingleEliminationBracket(tournament.teamIds);
      case TournamentModeType.doubleElimination:
        return _generateDoubleEliminationBracket(tournament.teamIds);
      case TournamentModeType.swiss:
        return _generateSwissPairings(tournament.teamIds);
      case TournamentModeType.randomizer:
        return _generateRandomPairings(tournament.teamIds);
      case TournamentModeType.hybrid:
        return _generateHybridPairings(state, tournament);
      default:
        return [];
    }
  }

  // Round-robin: every team plays every other team once
  static List<({String team1Id, String team2Id})> _generateRoundRobinPairings(
    List<String> teamIds,
  ) {
    final pairs = <({String team1Id, String team2Id})>[];
    for (var i = 0; i < teamIds.length; i++) {
      for (var j = i + 1; j < teamIds.length; j++) {
        pairs.add((team1Id: teamIds[i], team2Id: teamIds[j]));
      }
    }
    return pairs;
  }

  // Single elimination bracket
  static List<({String team1Id, String team2Id})>
  _generateSingleEliminationBracket(List<String> teamIds) {
    // Simple pairing: teams in order
    final pairs = <({String team1Id, String team2Id})>[];
    for (var i = 0; i < teamIds.length - 1; i += 2) {
      pairs.add((team1Id: teamIds[i], team2Id: teamIds[i + 1]));
    }
    return pairs;
  }

  // Double elimination bracket
  static List<({String team1Id, String team2Id})>
  _generateDoubleEliminationBracket(List<String> teamIds) {
    // For now, same as single elimination. Real implementation would track winners/losers bracket
    return _generateSingleEliminationBracket(teamIds);
  }

  // Swiss system (simplified): random pairings each round
  static List<({String team1Id, String team2Id})> _generateSwissPairings(
    List<String> teamIds,
  ) {
    // Simplified: just return round-robin structure
    return _generateRoundRobinPairings(teamIds);
  }

  static List<({String team1Id, String team2Id})> _generateRandomPairings(
    List<String> teamIds,
  ) {
    final shuffled = [...teamIds]..shuffle(Random());
    final pairs = <({String team1Id, String team2Id})>[];
    for (var i = 0; i < shuffled.length - 1; i += 2) {
      pairs.add((team1Id: shuffled[i], team2Id: shuffled[i + 1]));
    }
    return pairs;
  }

  static List<({String team1Id, String team2Id})> _generateHybridPairings(
    AppState state,
    Tournament tournament,
  ) {
    if (tournament.hybridGroups.isEmpty) return [];

    final pairs = <({String team1Id, String team2Id})>[];
    for (final group in tournament.hybridGroups) {
      if (group.isEmpty) continue;

      final groupMode = group.first;
      final tempTournament = tournament.copyWith(
        mode: TournamentMode.fromType(groupMode),
      );

      pairs.addAll(generatePairings(state, tempTournament));
    }

    return pairs;
  }

  // Calculate tournament standings for league/round-robin
  static List<TournamentStanding> calculateStandings(
    AppState state,
    Tournament tournament,
  ) {
    final standings = <String, TournamentStanding>{};

    // Initialize standings for all teams
    for (final teamId in tournament.teamIds) {
      standings[teamId] = TournamentStanding(
        teamId: teamId,
        wins: 0,
        draws: 0,
        losses: 0,
        pointsFor: 0,
        pointsAgainst: 0,
      );
    }

    // Process all games
    final tournamentGames = state.getTournamentGames(tournament.id);
    for (final game in tournamentGames) {
      if (game.result == null) continue;

      final result = game.result!;
      final standing1 = standings[game.team1Id];
      final standing2 = standings[game.team2Id];

      if (standing1 == null || standing2 == null) continue;

      standing1.pointsFor += result.score1;
      standing1.pointsAgainst += result.score2;
      standing2.pointsFor += result.score2;
      standing2.pointsAgainst += result.score1;

      if (result.winnerTeamId == game.team1Id) {
        standing1.wins += 1;
        standing2.losses += 1;
      } else if (result.winnerTeamId == game.team2Id) {
        standing2.wins += 1;
        standing1.losses += 1;
      } else {
        standing1.draws += 1;
        standing2.draws += 1;
      }
    }

    // Sort by wins, then by point difference
    final sortedStandings = standings.values.toList();
    sortedStandings.sort((a, b) {
      final winDiff = b.wins.compareTo(a.wins);
      if (winDiff != 0) return winDiff;
      return b.pointDifference.compareTo(a.pointDifference);
    });

    return sortedStandings;
  }
}

class TournamentStanding {
  final String teamId;
  int wins;
  int draws;
  int losses;
  int pointsFor;
  int pointsAgainst;

  TournamentStanding({
    required this.teamId,
    required this.wins,
    required this.draws,
    required this.losses,
    required this.pointsFor,
    required this.pointsAgainst,
  });

  int get pointDifference => pointsFor - pointsAgainst;
  int get totalGames => wins + draws + losses;
  int get points => wins * 3 + draws;
}
