enum TournamentModeType {
  singleGame,
  league,
  singleElimination,
  doubleElimination,
  swiss,
  kingOfTheCourt,
  randomizer,
  manual,
  hybrid,
}

class TournamentMode {
  final TournamentModeType type;
  final String displayName;

  const TournamentMode({
    required this.type,
    required this.displayName,
  });

  static TournamentMode fromType(TournamentModeType type) {
    return TournamentMode(
      type: type,
      displayName: _getDisplayName(type),
    );
  }

  static String _getDisplayName(TournamentModeType type) {
    switch (type) {
      case TournamentModeType.singleGame:
        return 'Single Games';
      case TournamentModeType.league:
        return 'League';
      case TournamentModeType.singleElimination:
        return 'Single Elimination';
      case TournamentModeType.doubleElimination:
        return 'Double Elimination';
      case TournamentModeType.swiss:
        return 'Swiss';
      case TournamentModeType.kingOfTheCourt:
        return 'King of the Court';
      case TournamentModeType.randomizer:
        return 'Randomizer';
      case TournamentModeType.manual:
        return 'Manual Tournament';
      case TournamentModeType.hybrid:
        return 'Hybrid Modes';
    }
  }
}
