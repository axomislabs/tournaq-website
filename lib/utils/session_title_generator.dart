import 'dart:math';

/// The game modes that have a themed pool of suggested session titles.
enum SessionTitleTheme { scramble, kingOfCourt, doghouse, koBracket, scrambleKing }

/// Central source of truth for the randomly-suggested tournament/session title
/// shown in each mode's setup form (the pre-filled name field and its shuffle
/// button). Each mode keeps its own flavour; the pools live here so they are no
/// longer copy-pasted across five setup pages.
abstract final class SessionTitleGenerator {
  static final _rng = Random();

  static const _scramble = [
    'Wild Scramble', 'Lazy Shuffle', 'Happy Chaos', 'Sneaky Mixer',
    'Tropical Frenzy', 'Sunset Blitz', 'Neon Scramble', 'Blazing Mix-Up',
    'Groovy Shakedown', 'Friendly Rumble', 'Casual Bash', 'Electric Fiesta',
    'Cheeky Shuffle', 'Breezy Scramble', 'Absolute Chaos', 'Epic Mixer',
    'Sneaky Frenzy', 'Disco Scramble', 'Friday Shuffle', 'Sunday Blitz',
    'Funky Freeforall', 'Rowdy Mix-Up', 'Salty Shuffle', 'Sunny Scramble',
    'Wobbly Rumble', 'Turbo Shakedown', 'Midnight Mixer', 'Beachside Bash',
    'Chaos Carnival', 'Scramble Circus', 'Loose Cannon', 'Rally Roulette',
    'Shuffle Party', 'Frantic Fiesta', 'Chill Scramble', 'Mayhem Mixer',
    'Sandy Shakedown', 'Wonky Shuffle',
  ];

  static const _kingOfCourt = [
    'Golden Throne', 'Royal Rumble', 'Crown Battle', 'Court Kings',
    'Champion Chase', 'Iron Throne', 'Neon Kingdom', 'Blazing Crown',
    'Friday Kingdom', 'Sunset Royale', 'Electric Court', 'Wild Reign',
    'Epic Throne', 'Sneaky King', 'Absolute Royale', 'Groovy Kingdom',
    'Tropical Crown', 'Casual Reign', 'Sunday Kingdom', 'Cheeky King',
    'Court Conquest', 'Throne Rush', 'Crown Clash', 'Regal Rumble',
    'Kingpin Court', 'Monarch Mayhem', 'Sovereign Showdown', 'Court Coronation',
    'Reign Supreme', 'Dynasty Duel', 'Ruler Royale', 'Highness Hustle',
    'Emperor Court', 'Crown Chaser', 'Throne Takeover', 'Court Royalty',
    'Majesty Match', 'Kingdom Clash',
  ];

  static const _doghouse = [
    'Escape Session', 'Doghouse Dash', 'Side Out', 'Break Out', 'Hustle Hour',
    'Serving Time', 'Back Yard', 'Grind Session', 'Serve Battle', 'Net Breaker',
    'Rally Rumble', 'Beach Grind', 'Sand Session', 'Court Battle', 'Block Party',
    'Spike Session', 'Sand Storm', 'Power Serve', 'Hard Court', 'Game Day',
    'Jailbreak Rally', 'Kennel Clash', 'Bark Battle', 'Pound Party',
    'Escape Room', 'Chain Breaker', 'Underdog Hour', 'Scrap Session',
    'Dig Dungeon', 'Basement Battle', 'Redemption Rally', 'Doghouse Derby',
    'Last Stand', 'Grit Session', 'Comeback Court', 'Hustle Hard',
    'No Mercy Match', 'Rally Redemption',
  ];

  static const _koBracket = [
    'Golden Bracket', 'Iron Fist', 'Thunder Cup', 'Steel Cage', 'Crown Classic',
    'Champion Cup', 'Elite Eight', 'Final Fury', 'Blazing Bracket',
    'Sunset Showdown', 'Neon Knockout', 'Wild Card', 'Friday Fight',
    'Epic Bracket', 'Sneaky Semifinal', 'Sudden Death', 'Bracket Blitz',
    'Knockout Kings', 'Do or Die', 'Last Team Standing', 'Grand Slam',
    'Title Fight', 'Bracket Buster', 'Clash of Courts', 'Winner Takes All',
    'Final Four', 'Playoff Push', 'Elimination Station', 'Champion Chase',
    'Bracket Brawl', 'Prime Time Playoff', 'Cup Run', 'Podium Push',
    'Knockout Night', 'Trophy Hunt', 'Decider Duel', 'Bracket Bash',
    'Showdown Series',
  ];

  static const _scrambleKing = [
    'Scramble Crown', 'Royal Mixer', 'Court Kings', 'Shuffle Throne',
    'Golden Rally', 'Wild Reign', 'Sunday Scramble', 'Electric Kingdom',
    'Friday Rumble', 'Neon Court', 'Crown Scramble', 'Mixer Monarch',
    'Royale Shuffle', 'Throne Scramble', 'Regal Rally', 'Kingdom Mixer',
    'Scramble Royale', 'Court Crown', 'Shuffle Sovereign', 'Reign of Chaos',
    'Majesty Mixer', 'Crowned Scramble', 'Royal Shakedown', 'Kingpin Scramble',
    'Throne Shuffle', 'Dynasty Mixer', 'Sovereign Scramble', 'Court Coronation',
    'Ruler Rumble', 'Emperor Mixer',
  ];

  static List<String> _poolFor(SessionTitleTheme theme) => switch (theme) {
        SessionTitleTheme.scramble => _scramble,
        SessionTitleTheme.kingOfCourt => _kingOfCourt,
        SessionTitleTheme.doghouse => _doghouse,
        SessionTitleTheme.koBracket => _koBracket,
        SessionTitleTheme.scrambleKing => _scrambleKing,
      };

  /// A random suggested session title for the given [theme].
  static String random(SessionTitleTheme theme) {
    final pool = _poolFor(theme);
    return pool[_rng.nextInt(pool.length)];
  }
}
