import 'dart:math';

abstract final class TeamNameGenerator {
  static final _random = Random();

  static const _names = [
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
  ];

  static String randomName({String? excluding}) {
    final pool = excluding == null
        ? _names
        : _names.where((n) => n != excluding).toList();
    return pool[_random.nextInt(pool.length)];
  }
}
