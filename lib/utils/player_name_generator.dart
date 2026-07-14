import 'dart:math';

/// Central source of truth for random placeholder player names, used when a
/// setup screen fills empty slots with demo players (Social Scramble, Scramble
/// King, King of the Court, Doghouse) and by the "suggest a name" button on the
/// Create Player sheet.
///
/// First and last name pools are intentionally international so generated
/// rosters feel varied. Combined capacity is well over a thousand full names,
/// and [uniqueNames] guards against duplicates within a fill batch.
abstract final class PlayerNameGenerator {
  static final _rng = Random();

  static const _firstNames = [
    'Alex', 'Sam', 'Jordan', 'Taylor', 'Morgan', 'Casey', 'Riley', 'Avery',
    'Quinn', 'Drew', 'Reese', 'Blake', 'Skyler', 'Jamie', 'Rowan', 'Charlie',
    'Parker', 'Sofia', 'Diego', 'Mateo', 'Lucia', 'Nina', 'Luca', 'Marco',
    'Elena', 'Kenji', 'Yuki', 'Hiro', 'Mei', 'Aiko', 'Amara', 'Kwame',
    'Zola', 'Chidi', 'Priya', 'Ravi', 'Anaya', 'Arjun', 'Omar', 'Zara',
    'Layla', 'Yusuf', 'Aisha', 'Nadia', 'Lars', 'Freya', 'Ingrid', 'Sven',
    'Katya', 'Dmitri',
  ];
  static const _lastNames = [
    'Smith', 'Jones', 'Brown', 'Miller', 'Wilson', 'Taylor', 'Anderson',
    'Thomas', 'Harris', 'Clark', 'Nguyen', 'Tran', 'Kim', 'Park', 'Chen',
    'Wang', 'Tanaka', 'Sato', 'Rossi', 'Costa', 'Silva', 'Santos', 'Garcia',
    'Martinez', 'Fernandez', 'Kowalski', 'Novak', 'Horvat', 'Yilmaz', 'Demir',
    'Haddad', 'Nasser', 'Okafor', 'Mensah', 'Diallo', 'Andersson', 'Larsen',
    'Virtanen', 'Ivanov', 'Petrov', 'Singh', 'Patel', 'Reddy', 'Mueller',
    'Schneider', 'Dubois', 'Laurent', 'Murphy', 'Walsh', 'Oconnor',
  ];

  /// A random full name in the form `'First Last'`.
  static String randomName() =>
      '${_firstNames[_rng.nextInt(_firstNames.length)]} '
      '${_lastNames[_rng.nextInt(_lastNames.length)]}';

  /// [count] full names, distinct from each other and from any names passed via
  /// [excluding]. Falls back to a numeric suffix only in the (very unlikely)
  /// event the combinatorial pool is exhausted.
  static List<String> uniqueNames(int count, {Set<String>? excluding}) {
    final used = <String>{...?excluding};
    final result = <String>[];
    if (count <= 0) return result;

    final capacity = _firstNames.length * _lastNames.length;
    var guard = 0;
    while (result.length < count && guard < capacity * 4) {
      final name = randomName();
      if (used.add(name)) result.add(name);
      guard++;
    }
    // Numeric fallback if random probing couldn't fill the batch.
    var suffix = 2;
    while (result.length < count) {
      final name = '${randomName()} $suffix';
      if (used.add(name)) result.add(name);
      suffix++;
    }
    return result;
  }
}
