import 'dart:math';

/// Central source of truth for random and deterministic team names across
/// every game mode (Quick Game, Social Scramble, Scramble King, Single
/// Elimination).
///
/// The name space is a single indexable pool of:
///   1. curated funny + cool names (shown first when picking distinct names), and
///   2. an adjective x noun combinatorial overflow for scale.
///
/// Combined capacity is well over a thousand names, so tournaments with 32 /
/// 64 / 128 teams never run out of distinct names.
///
/// Two access styles share the same pool:
///   - Random  — [randomName] / [uniqueNames] for modes that pick names on the
///     fly (Quick Game, KO auto-fill, the KO team editor's shuffle button).
///   - Deterministic — [forPlayers] / [pairForPlayers] / [uniqueForTeams] hash
///     a team's sorted player ids, so the same players always get the same
///     name across schedule recomputes (Social Scramble & Scramble King).
abstract final class TeamNameGenerator {
  static final _random = Random();

  // Curated funny + cool names. Shown first by [uniqueNames] so typical-sized
  // tournaments get characterful names before falling back to combos.
  static const _curated = [
    // — Puns & jokes —
    'Sets on the Beach', 'Setter Call Saul', 'Notorious D.I.G.', 'Ace Ventura',
    'Sandy Cheeks', 'Digs and Wishes', 'Bump It Up', 'Blocktopus',
    'Sultans of Set', 'Spike Girls', 'Ace of Base', 'Block and Roll',
    'Net Gains', 'The Blockness Monster', 'Setisfaction', 'Serves You Right',
    'Blockbusters', 'Kiss My Ace', 'Beach Please', 'Setback',
    'Spike Lee', 'The Dig Lebowski', 'Free Ballers', 'Sons of Beaches',
    'Court Jesters', 'Servivors', 'Hit Happens', 'Setting Ducks',
    'Six Pack Attack', 'Spiketacular', 'Sand Wizards', 'Volley Llamas',
    'Bump Set Psych', 'Setter Late Than Never', 'Ace in the Hole',
    // — Cool / sporty (beach-volleyball flavoured) —
    'Wave Crushers', 'Sand Storm', 'Net Force', 'Spike Kings', 'Dig Squad',
    'Beach Blitz', 'Solar Smash', 'Tide Turners', 'Thunder Hawks', 'Storm Eagles',
    'Iron Setters', 'Golden Spikers', 'Desert Dunes', 'Shadow Servers', 'Sky Spikers',
    'Rush Hour', 'Titan Crew', 'Blue Waves', 'Fire Servers', 'Ice Blockers',
    'Wild Aces', 'Power Blockers', 'Net Ninjas', 'Fast Diggers', 'Beach Rockets',
    'Sand Sharks', 'Sunset Spikers', 'Storm Chasers', 'Blaze Crew', 'Swift Setters',
    'Coastal Force', 'Dune Riders', 'Neon Spikers', 'Volt Squad', 'Razor Edge',
    'Peak Performers', 'Slam Dunes', 'Shoreline Smash', 'High Flyers', 'Ground Zero',
    'Iron Fist', 'Overdrive', 'Top Spin', 'Block Party', 'Court Crushers',
    'Sand Vipers', 'Ace Hunters', 'Shock Wave', 'Heat Seekers', 'Phantom Spikers',
    // — Adjective + animal / colour + animal / element + noun —
    'Steel Cobras', 'Bold Falcons', 'Swift Hawks', 'Iron Bears',
    'Wild Wolves', 'Stone Tigers', 'Dark Eagles', 'Sharp Ravens',
    'Free Foxes', 'Fierce Lions', 'Quick Lynx', 'Hard Stags',
    'Bare Bulls', 'Deep Sharks', 'Cold Owls',
    'Red Wolves', 'Blue Hawks', 'Gold Lions', 'Black Vipers',
    'Silver Eagles', 'Green Foxes', 'White Bears', 'Crimson Falcons',
    'Azure Cranes', 'Scarlet Cobras', 'Teal Dolphins', 'Amber Stags',
    'Bronze Bulls', 'Violet Ravens', 'Jade Serpents',
    'Iron Tide', 'Storm Ridge', 'Thunder Peak', 'Frost Crest',
    'Ember Keep', 'Stone Gale', 'Blaze Drift', 'Shadow Cove',
    'Ash Reef', 'Dusk Forge', 'Gale Force', 'Rock Surge',
    'Flame Run', 'Salt Crest', 'Wind Drive',
  ];

  static const _adjectives = [
    'Thunder', 'Iron', 'Swift', 'Bold', 'Red', 'Blue', 'Gold', 'Silver',
    'Dark', 'Storm', 'Crimson', 'Blazing', 'Frozen', 'Shadow', 'Solar',
    'Mighty', 'Royal', 'Wild', 'Steel', 'Fire',
    'Sandy', 'Salty', 'Sunburnt', 'Rowdy', 'Sizzling', 'Turbo', 'Cosmic',
    'Rogue', 'Feral', 'Sneaky', 'Grumpy', 'Bouncy', 'Reckless', 'Radical',
    'Savage', 'Groovy', 'Funky', 'Electric', 'Atomic', 'Neon',
  ];
  static const _nouns = [
    'Hawks', 'Bears', 'Lions', 'Eagles', 'Wolves', 'Panthers', 'Sharks',
    'Tigers', 'Foxes', 'Dragons', 'Cobras', 'Ravens', 'Falcons', 'Jaguars',
    'Vipers', 'Stallions', 'Rhinos', 'Gladiators', 'Titans', 'Strikers',
    'Spikers', 'Diggers', 'Setters', 'Blockers', 'Aces', 'Servers', 'Bumpers',
    'Smashers', 'Crushers', 'Blazers', 'Rockets', 'Comets', 'Warriors',
    'Bandits', 'Rebels', 'Mavericks', 'Legends', 'Llamas', 'Otters', 'Narwhals',
  ];

  static int get _comboCount => _adjectives.length * _nouns.length;

  /// Total distinct names addressable by index (curated + combinatorial).
  static int get _capacity => _curated.length + _comboCount;

  /// Maps a stable index in `[0, _capacity)` to a name. Curated names occupy
  /// the low indices; the rest map onto adjective x noun combinations.
  static String _nameAt(int i) {
    if (i < _curated.length) return _curated[i];
    final k = i - _curated.length;
    return '${_adjectives[k ~/ _nouns.length]} ${_nouns[k % _nouns.length]}';
  }

  /// A random team name, optionally avoiding a single [excluding] value (used by
  /// the KO team editor's shuffle button so it never re-rolls the same name).
  static String randomName({String? excluding}) {
    String name;
    var attempts = 0;
    do {
      name = _nameAt(_random.nextInt(_capacity));
      attempts++;
    } while (name == excluding && attempts < 10);
    return name;
  }

  /// [count] distinct random names. Curated names come first (shuffled), then
  /// combinatorial overflow — guaranteeing no repeats for any count up to the
  /// pool [_capacity]. Any names already taken can be passed via [excluding].
  static List<String> uniqueNames(int count, {Set<String>? excluding}) {
    final used = <String>{...?excluding};
    final result = <String>[];
    if (count <= 0) return result;

    // 1) Curated pool first, shuffled for variety.
    final curatedOrder = List<int>.generate(_curated.length, (i) => i)
      ..shuffle(_random);
    for (final i in curatedOrder) {
      if (used.add(_curated[i])) result.add(_curated[i]);
      if (result.length >= count) return result;
    }
    // 2) Combinatorial overflow, shuffled — guarantees distinctness up to
    //    the full combo space.
    final comboOrder = List<int>.generate(_comboCount, (i) => i)
      ..shuffle(_random);
    for (final k in comboOrder) {
      final name = '${_adjectives[k ~/ _nouns.length]} ${_nouns[k % _nouns.length]}';
      if (used.add(name)) result.add(name);
      if (result.length >= count) return result;
    }
    // 3) Numbered fallback beyond total capacity (very large tournaments).
    var suffix = 2;
    while (result.length < count) {
      final name = '${_curated[result.length % _curated.length]} $suffix';
      if (used.add(name)) result.add(name);
      suffix++;
    }
    return result;
  }

  /// Deterministic single-team name from a player-id list — the same players
  /// always get the same name.
  static String forPlayers(List<String> ids) => _nameAt(_hash(ids) % _capacity);

  /// Deterministic `(nameA, nameB)` pair for a game, guaranteed to differ.
  static (String, String) pairForPlayers(
    List<String> sideAIds,
    List<String> sideBIds,
  ) {
    final nameA = forPlayers(sideAIds);
    var idxB = _hash(sideBIds) % _capacity;
    var nameB = _nameAt(idxB);
    var attempts = 0;
    while (nameB == nameA && attempts < _capacity) {
      idxB = (idxB + 1) % _capacity;
      nameB = _nameAt(idxB);
      attempts++;
    }
    return (nameA, nameB);
  }

  /// Assigns a distinct name to each team in [teams]. Each name starts from the
  /// team's deterministic [forPlayers] pick and linear-probes on collision, so
  /// no two teams in the same list share a name.
  static List<String> uniqueForTeams(List<List<String>> teams) {
    final used = <String>{};
    final result = <String>[];
    for (final ids in teams) {
      var idx = _hash(ids) % _capacity;
      var attempts = 0;
      while (used.contains(_nameAt(idx)) && attempts < _capacity) {
        idx = (idx + 1) % _capacity;
        attempts++;
      }
      final name = _nameAt(idx);
      used.add(name);
      result.add(name);
    }
    return result;
  }

  /// Stable DJB2-style hash of a sorted player-id list.
  static int _hash(List<String> ids) {
    final key = ([...ids]..sort()).join(',');
    var h = 5381;
    for (final c in key.codeUnits) {
      h = ((h << 5) + h + c) & 0x7fffffff;
    }
    return h;
  }
}
