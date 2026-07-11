// Deterministic team name generator for Social Scramble games.
// Names are drawn from three style pools and assigned based on
// a stable hash of the sorted player ID lists — same players always
// get the same name for a given game.

abstract final class ScrambleTeamNames {
  static const _names = [
    // Adjective + Animal
    'Steel Cobras',   'Bold Falcons',  'Swift Hawks',  'Iron Bears',
    'Wild Wolves',    'Stone Tigers',  'Dark Eagles',  'Sharp Ravens',
    'Free Foxes',     'Fierce Lions',  'Quick Lynx',   'Hard Stags',
    'Bare Bulls',     'Deep Sharks',   'Cold Owls',
    // Colour + Animal
    'Red Wolves',     'Blue Hawks',    'Gold Lions',   'Black Vipers',
    'Silver Eagles',  'Green Foxes',   'White Bears',  'Crimson Falcons',
    'Azure Cranes',   'Scarlet Cobras','Teal Dolphins', 'Amber Stags',
    'Bronze Bulls',   'Violet Ravens', 'Jade Serpents',
    // Element + Noun
    'Iron Tide',      'Storm Ridge',   'Thunder Peak', 'Frost Crest',
    'Ember Keep',     'Stone Gale',    'Blaze Drift',  'Shadow Cove',
    'Ash Reef',       'Dusk Forge',    'Gale Force',   'Rock Surge',
    'Flame Run',      'Salt Crest',    'Wind Drive',
  ];

  /// Returns a stable (nameA, nameB) pair for a game.
  /// Both names are guaranteed to be different.
  static (String, String) generate(
    List<String> sideAIds,
    List<String> sideBIds,
  ) {
    final idxA = _hash(sideAIds) % _names.length;
    var idxB   = _hash(sideBIds) % _names.length;
    if (idxB == idxA) idxB = (idxB + 1) % _names.length;
    return (_names[idxA], _names[idxB]);
  }

  /// Deterministic single-team name from a player-id list.
  static String forTeam(List<String> ids) => _names[_hash(ids) % _names.length];

  /// Assigns a distinct name to each team on a court. Names start from each
  /// team's deterministic [forTeam] pick and linear-probe on collision so no
  /// two teams in the same list share a name.
  static List<String> unique(List<List<String>> teams) {
    final used = <String>{};
    final result = <String>[];
    for (final ids in teams) {
      var idx = _hash(ids) % _names.length;
      var attempts = 0;
      while (used.contains(_names[idx]) && attempts < _names.length) {
        idx = (idx + 1) % _names.length;
        attempts++;
      }
      used.add(_names[idx]);
      result.add(_names[idx]);
    }
    return result;
  }

  static int _hash(List<String> ids) {
    final key = ([...ids]..sort()).join(',');
    var h = 5381;
    for (final c in key.codeUnits) {
      h = ((h << 5) + h + c) & 0x7fffffff;
    }
    return h;
  }
}
