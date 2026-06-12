import 'dart:math';
import 'package:uuid/uuid.dart';
import '../services/device_id_service.dart';

const _uuid = Uuid();

// ── Enums ─────────────────────────────────────────────────────────────────────

enum KoBracketStyle { singleElimination }

enum KoBracketGenerationMode { random, seeded }

/// How odd-numbered team counts are handled before the main bracket.
///   byes               → top seeds auto-advance (no match played)
///   playIn             → bottom seeds play off; winner earns bracket slot
///   playInWithRepechage → play-in, plus best-scoring loser gets a wildcard match
enum KoOddTeamStrategy { byes, playIn, playInWithRepechage }

enum KoBracketStatus { setup, inProgress, completed }

enum KoMatchStatus { scheduled, inProgress, completed, bye, walkover, playIn, repechage }

// ── Round format ───────────────────────────────────────────────────────────────

class KoRoundFormat {
  final int setsPerGame;
  final int pointsPerSet;

  const KoRoundFormat({required this.setsPerGame, required this.pointsPerSet});

  KoRoundFormat copyWith({int? setsPerGame, int? pointsPerSet}) => KoRoundFormat(
        setsPerGame: setsPerGame ?? this.setsPerGame,
        pointsPerSet: pointsPerSet ?? this.pointsPerSet,
      );

  Map<String, dynamic> toJson() => {
        'setsPerGame': setsPerGame,
        'pointsPerSet': pointsPerSet,
      };

  factory KoRoundFormat.fromJson(Map<String, dynamic> j) => KoRoundFormat(
        setsPerGame: j['setsPerGame'] as int? ?? 1,
        pointsPerSet: j['pointsPerSet'] as int? ?? 15,
      );

  String get label => setsPerGame == 1 ? '$pointsPerSet pts' : 'Bo$setsPerGame · $pointsPerSet pts';
}

// ── Player snapshot ────────────────────────────────────────────────────────────
// Snapshotted from AppState.Player at team creation time so the bracket is
// self-contained and rating changes don't retroactively reseed.

class KoPlayerSnapshot {
  final String appPlayerId;
  final String name;
  final int? skillRating;

  const KoPlayerSnapshot({
    required this.appPlayerId,
    required this.name,
    this.skillRating,
  });

  Map<String, dynamic> toJson() => {
        'appPlayerId': appPlayerId,
        'name': name,
        'skillRating': skillRating,
      };

  factory KoPlayerSnapshot.fromJson(Map<String, dynamic> j) => KoPlayerSnapshot(
        appPlayerId: j['appPlayerId'] as String,
        name: j['name'] as String,
        skillRating: j['skillRating'] as int?,
      );
}

// ── Team ──────────────────────────────────────────────────────────────────────

class KoTeam {
  final String id;
  final String name;
  final List<KoPlayerSnapshot> players;
  final bool isWithdrawn;
  final int? withdrawnAtRound;

  const KoTeam({
    required this.id,
    required this.name,
    required this.players,
    this.isWithdrawn = false,
    this.withdrawnAtRound,
  });

  /// Weighted team rating: players sorted descending, weights [0.6, 0.4] for 2
  /// players, [0.5, 0.3, 0.2] for 3, declining for more.
  /// Returns null if any player is unrated.
  double? get skillRating {
    if (players.isEmpty) return null;
    if (players.any((p) => p.skillRating == null)) return null;
    final sorted = [...players]..sort((a, b) => b.skillRating!.compareTo(a.skillRating!));
    final weights = _weights(sorted.length);
    double total = 0;
    for (var i = 0; i < sorted.length; i++) {
      total += sorted[i].skillRating! * weights[i];
    }
    return double.parse(total.toStringAsFixed(1));
  }

  static List<double> _weights(int count) {
    switch (count) {
      case 1:
        return [1.0];
      case 2:
        return [0.6, 0.4];
      case 3:
        return [0.5, 0.3, 0.2];
      case 4:
        return [0.4, 0.3, 0.2, 0.1];
      default:
        // For 5+: top gets 0.35, rest split evenly
        final rest = (0.65 / (count - 1));
        return [0.35, ...List.filled(count - 1, rest)];
    }
  }

  KoTeam copyWith({
    String? name,
    List<KoPlayerSnapshot>? players,
    bool? isWithdrawn,
    int? withdrawnAtRound,
  }) =>
      KoTeam(
        id: id,
        name: name ?? this.name,
        players: players ?? this.players,
        isWithdrawn: isWithdrawn ?? this.isWithdrawn,
        withdrawnAtRound: withdrawnAtRound ?? this.withdrawnAtRound,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'players': players.map((p) => p.toJson()).toList(),
        'isWithdrawn': isWithdrawn,
        'withdrawnAtRound': withdrawnAtRound,
      };

  factory KoTeam.fromJson(Map<String, dynamic> j) => KoTeam(
        id: j['id'] as String,
        name: j['name'] as String,
        players: (j['players'] as List? ?? [])
            .map((e) => KoPlayerSnapshot.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
        isWithdrawn: j['isWithdrawn'] as bool? ?? false,
        withdrawnAtRound: j['withdrawnAtRound'] as int?,
      );

  static String generateId() => _uuid.v4();
}

// ── Set ───────────────────────────────────────────────────────────────────────

class KoSet {
  final int score1;
  final int score2;
  final bool isCompleted;

  const KoSet({required this.score1, required this.score2, this.isCompleted = false});

  KoSet copyWith({int? score1, int? score2, bool? isCompleted}) => KoSet(
        score1: score1 ?? this.score1,
        score2: score2 ?? this.score2,
        isCompleted: isCompleted ?? this.isCompleted,
      );

  Map<String, dynamic> toJson() => {
        'score1': score1,
        'score2': score2,
        'isCompleted': isCompleted,
      };

  factory KoSet.fromJson(Map<String, dynamic> j) => KoSet(
        score1: j['score1'] as int? ?? 0,
        score2: j['score2'] as int? ?? 0,
        isCompleted: j['isCompleted'] as bool? ?? false,
      );
}

// ── Match ─────────────────────────────────────────────────────────────────────

class KoMatch {
  final String id;

  /// 0 = play-in / repechage round, 1 = first main bracket round, etc.
  final int round;

  /// 0-based position within the round.
  final int matchIndex;

  final String? team1Id;
  final String? team2Id;
  final String? winnerId;
  final String? withdrawnTeamId;
  final List<KoSet> sets;
  final KoMatchStatus status;
  final int? courtAssignment;
  final DateTime? startedAt;
  final DateTime? completedAt;

  const KoMatch({
    required this.id,
    required this.round,
    required this.matchIndex,
    this.team1Id,
    this.team2Id,
    this.winnerId,
    this.withdrawnTeamId,
    this.sets = const [],
    this.status = KoMatchStatus.scheduled,
    this.courtAssignment,
    this.startedAt,
    this.completedAt,
  });

  bool get isComplete =>
      status == KoMatchStatus.completed ||
      status == KoMatchStatus.bye ||
      status == KoMatchStatus.walkover;

  int get team1Sets => sets.where((s) => s.isCompleted && s.score1 > s.score2).length;
  int get team2Sets => sets.where((s) => s.isCompleted && s.score2 > s.score1).length;

  /// Total points scored by team1 across all completed sets.
  int get team1TotalPoints => sets.fold(0, (sum, s) => sum + s.score1);

  /// Total points scored by team2 across all completed sets.
  int get team2TotalPoints => sets.fold(0, (sum, s) => sum + s.score2);

  KoMatch copyWith({
    String? team1Id,
    String? team2Id,
    String? winnerId,
    String? withdrawnTeamId,
    List<KoSet>? sets,
    KoMatchStatus? status,
    int? courtAssignment,
    DateTime? startedAt,
    DateTime? completedAt,
  }) =>
      KoMatch(
        id: id,
        round: round,
        matchIndex: matchIndex,
        team1Id: team1Id ?? this.team1Id,
        team2Id: team2Id ?? this.team2Id,
        winnerId: winnerId ?? this.winnerId,
        withdrawnTeamId: withdrawnTeamId ?? this.withdrawnTeamId,
        sets: sets ?? this.sets,
        status: status ?? this.status,
        courtAssignment: courtAssignment ?? this.courtAssignment,
        startedAt: startedAt ?? this.startedAt,
        completedAt: completedAt ?? this.completedAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'round': round,
        'matchIndex': matchIndex,
        'team1Id': team1Id,
        'team2Id': team2Id,
        'winnerId': winnerId,
        'withdrawnTeamId': withdrawnTeamId,
        'sets': sets.map((s) => s.toJson()).toList(),
        'status': status.name,
        'courtAssignment': courtAssignment,
        'startedAt': startedAt?.toIso8601String(),
        'completedAt': completedAt?.toIso8601String(),
      };

  factory KoMatch.fromJson(Map<String, dynamic> j) => KoMatch(
        id: j['id'] as String,
        round: j['round'] as int,
        matchIndex: j['matchIndex'] as int,
        team1Id: j['team1Id'] as String?,
        team2Id: j['team2Id'] as String?,
        winnerId: j['winnerId'] as String?,
        withdrawnTeamId: j['withdrawnTeamId'] as String?,
        sets: (j['sets'] as List? ?? [])
            .map((e) => KoSet.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
        status: KoMatchStatus.values.byName(
            (j['status'] as String?) ?? KoMatchStatus.scheduled.name),
        courtAssignment: j['courtAssignment'] as int?,
        startedAt: j['startedAt'] != null ? DateTime.parse(j['startedAt'] as String) : null,
        completedAt:
            j['completedAt'] != null ? DateTime.parse(j['completedAt'] as String) : null,
      );

  static String generateId() => _uuid.v4();
}

// ── Tournament ────────────────────────────────────────────────────────────────

class KoBracketTournament {
  final String id;
  final String name;
  final KoBracketStyle style;
  final KoBracketGenerationMode generationMode;
  final KoOddTeamStrategy oddTeamStrategy;
  final int playersPerSide;
  final int courtCount;
  final int minutesPerGame;
  final KoRoundFormat earlyRoundFormat;
  final KoRoundFormat finalRoundFormat;

  /// Last N rounds (counting from the final) that use [finalRoundFormat].
  final int finalRoundsCount;
  final DateTime? estimatedStart;
  final List<KoTeam> teams;
  final List<KoMatch> matches;
  final KoBracketStatus status;
  final DateTime createdAt;
  final String deviceId;

  KoBracketTournament({
    required this.id,
    required this.name,
    this.style = KoBracketStyle.singleElimination,
    this.generationMode = KoBracketGenerationMode.random,
    this.oddTeamStrategy = KoOddTeamStrategy.byes,
    this.playersPerSide = 2,
    this.courtCount = 1,
    this.minutesPerGame = 30,
    required this.earlyRoundFormat,
    required this.finalRoundFormat,
    this.finalRoundsCount = 2,
    this.estimatedStart,
    this.teams = const [],
    this.matches = const [],
    this.status = KoBracketStatus.setup,
    DateTime? createdAt,
    String? deviceId,
  })  : createdAt = createdAt ?? DateTime.now(),
        deviceId = deviceId ?? DeviceIdService.currentDeviceId;

  // ── Derived ──────────────────────────────────────────────────────────────

  int get teamCount => teams.length;

  /// Total rounds in the main bracket (excludes round 0 play-in).
  int get mainRoundCount => teams.isEmpty ? 0 : (log(bracketSize) / log(2)).ceil();

  /// Bracket size (next power of 2 ≥ teamCount for byes; prev power of 2 for play-in).
  int get bracketSize {
    if (teams.isEmpty) return 0;
    final n = teams.length;
    if (oddTeamStrategy == KoOddTeamStrategy.byes) {
      return _nextPow2(n);
    } else {
      return _prevPow2(n);
    }
  }

  /// Number of play-in matches (0 for byes strategy).
  int get playInMatchCount {
    if (oddTeamStrategy == KoOddTeamStrategy.byes) return 0;
    return teams.length - _prevPow2(teams.length);
  }

  KoRoundFormat formatForRound(int round) {
    final lastMainRound = mainRoundCount;
    if (round >= lastMainRound - finalRoundsCount + 1) return finalRoundFormat;
    return earlyRoundFormat;
  }

  /// Estimated total duration based on round structure and court count.
  Duration get estimatedDuration {
    if (teams.isEmpty) return Duration.zero;
    var totalMinutes = 0;
    final rCount = mainRoundCount;
    for (var r = 1; r <= rCount; r++) {
      final matchesInRound = bracketSize ~/ pow(2, r).toInt();
      final parallelSlots = (matchesInRound / courtCount).ceil();
      totalMinutes += parallelSlots * minutesPerGame;
    }
    if (playInMatchCount > 0) {
      totalMinutes += (playInMatchCount / courtCount).ceil() * minutesPerGame;
    }
    return Duration(minutes: totalMinutes);
  }

  DateTime? get estimatedEnd => estimatedStart?.add(estimatedDuration);

  // ── Bracket helpers ───────────────────────────────────────────────────────

  KoTeam? teamById(String id) {
    try {
      return teams.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }

  List<KoMatch> matchesForRound(int round) =>
      matches.where((m) => m.round == round).toList()
        ..sort((a, b) => a.matchIndex.compareTo(b.matchIndex));

  List<int> get allRounds {
    final rounds = matches.map((m) => m.round).toSet().toList()..sort();
    return rounds;
  }

  bool get allMatchesComplete => matches.isNotEmpty && matches.every((m) => m.isComplete);

  KoMatch? get currentMatch {
    // First in-progress match, then first scheduled match.
    try {
      return matches.firstWhere((m) => m.status == KoMatchStatus.inProgress);
    } catch (_) {}
    try {
      return matches.firstWhere(
          (m) => m.status == KoMatchStatus.scheduled && m.team1Id != null && m.team2Id != null);
    } catch (_) {
      return null;
    }
  }

  // ── Mutators ──────────────────────────────────────────────────────────────

  KoBracketTournament copyWith({
    String? name,
    KoBracketStyle? style,
    KoBracketGenerationMode? generationMode,
    KoOddTeamStrategy? oddTeamStrategy,
    int? playersPerSide,
    int? courtCount,
    int? minutesPerGame,
    KoRoundFormat? earlyRoundFormat,
    KoRoundFormat? finalRoundFormat,
    int? finalRoundsCount,
    DateTime? estimatedStart,
    List<KoTeam>? teams,
    List<KoMatch>? matches,
    KoBracketStatus? status,
  }) =>
      KoBracketTournament(
        id: id,
        name: name ?? this.name,
        style: style ?? this.style,
        generationMode: generationMode ?? this.generationMode,
        oddTeamStrategy: oddTeamStrategy ?? this.oddTeamStrategy,
        playersPerSide: playersPerSide ?? this.playersPerSide,
        courtCount: courtCount ?? this.courtCount,
        minutesPerGame: minutesPerGame ?? this.minutesPerGame,
        earlyRoundFormat: earlyRoundFormat ?? this.earlyRoundFormat,
        finalRoundFormat: finalRoundFormat ?? this.finalRoundFormat,
        finalRoundsCount: finalRoundsCount ?? this.finalRoundsCount,
        estimatedStart: estimatedStart ?? this.estimatedStart,
        teams: teams ?? this.teams,
        matches: matches ?? this.matches,
        status: status ?? this.status,
        createdAt: createdAt,
        deviceId: deviceId,
      );

  KoBracketTournament updateMatch(KoMatch updated) {
    return copyWith(
      matches: matches.map((m) => m.id == updated.id ? updated : m).toList(),
    );
  }

  KoBracketTournament updateTeam(KoTeam updated) {
    return copyWith(
      teams: teams.map((t) => t.id == updated.id ? updated : t).toList(),
    );
  }

  // ── Serialisation ─────────────────────────────────────────────────────────

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'style': style.name,
        'generationMode': generationMode.name,
        'oddTeamStrategy': oddTeamStrategy.name,
        'playersPerSide': playersPerSide,
        'courtCount': courtCount,
        'minutesPerGame': minutesPerGame,
        'earlyRoundFormat': earlyRoundFormat.toJson(),
        'finalRoundFormat': finalRoundFormat.toJson(),
        'finalRoundsCount': finalRoundsCount,
        'estimatedStart': estimatedStart?.toIso8601String(),
        'teams': teams.map((t) => t.toJson()).toList(),
        'matches': matches.map((m) => m.toJson()).toList(),
        'status': status.name,
        'createdAt': createdAt.toIso8601String(),
        'deviceId': deviceId,
      };

  factory KoBracketTournament.fromJson(Map<String, dynamic> j) => KoBracketTournament(
        id: j['id'] as String,
        name: j['name'] as String,
        style: KoBracketStyle.values.byName(
            (j['style'] as String?) ?? KoBracketStyle.singleElimination.name),
        generationMode: KoBracketGenerationMode.values.byName(
            (j['generationMode'] as String?) ?? KoBracketGenerationMode.random.name),
        oddTeamStrategy: KoOddTeamStrategy.values.byName(
            (j['oddTeamStrategy'] as String?) ?? KoOddTeamStrategy.byes.name),
        playersPerSide: j['playersPerSide'] as int? ?? 2,
        courtCount: j['courtCount'] as int? ?? 1,
        minutesPerGame: j['minutesPerGame'] as int? ?? 30,
        earlyRoundFormat: KoRoundFormat.fromJson(
            Map<String, dynamic>.from(j['earlyRoundFormat'] as Map? ?? {})),
        finalRoundFormat: KoRoundFormat.fromJson(
            Map<String, dynamic>.from(j['finalRoundFormat'] as Map? ?? {})),
        finalRoundsCount: j['finalRoundsCount'] as int? ?? 2,
        estimatedStart: j['estimatedStart'] != null
            ? DateTime.parse(j['estimatedStart'] as String)
            : null,
        teams: (j['teams'] as List? ?? [])
            .map((e) => KoTeam.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
        matches: (j['matches'] as List? ?? [])
            .map((e) => KoMatch.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
        status: KoBracketStatus.values.byName(
            (j['status'] as String?) ?? KoBracketStatus.setup.name),
        createdAt: DateTime.parse(j['createdAt'] as String),
        deviceId: j['deviceId'] as String? ?? '',
      );

  static String generateId() => _uuid.v4();
}

// ── Bracket generation ────────────────────────────────────────────────────────

class KoBracketGenerator {
  static final _rng = Random();

  /// Generates the full match list for a tournament.
  /// Byes, play-in and repechage matches are resolved where possible.
  static List<KoMatch> generate(KoBracketTournament t) {
    final teams = List<KoTeam>.from(t.teams);
    if (teams.isEmpty) return [];

    switch (t.generationMode) {
      case KoBracketGenerationMode.seeded:
        // Sort descending by skillRating; unrated teams go to the bottom.
        teams.sort((a, b) {
          final ra = a.skillRating ?? -1;
          final rb = b.skillRating ?? -1;
          return rb.compareTo(ra);
        });
      case KoBracketGenerationMode.random:
        teams.shuffle(_rng);
    }

    switch (t.oddTeamStrategy) {
      case KoOddTeamStrategy.byes:
        return _generateWithByes(teams, t);
      case KoOddTeamStrategy.playIn:
        return _generateWithPlayIn(teams, t, repechage: false);
      case KoOddTeamStrategy.playInWithRepechage:
        return _generateWithPlayIn(teams, t, repechage: true);
    }
  }

  // ── Byes strategy ─────────────────────────────────────────────────────────

  static List<KoMatch> _generateWithByes(List<KoTeam> teams, KoBracketTournament t) {
    final n = teams.length;
    final size = _nextPow2(n);
    final rounds = (log(size) / log(2)).ceil();
    final matches = <KoMatch>[];

    // Round 1: pair teams with byes for the gaps.
    // Standard seeded placement: 1v(size), 2v(size-1), etc.
    // Slots 0..size-1 get teams by index; excess slots are bye.
    final slots = List<KoTeam?>.filled(size, null);
    for (var i = 0; i < n; i++) {
      slots[i] = teams[i];
    }

    // Interleave seeded placement: slot[0]=seed1, slot[size-1]=seed2, etc.
    final seeded = _interleaveSeeding(slots);

    for (var i = 0; i < size ~/ 2; i++) {
      final t1 = seeded[i * 2];
      final t2 = seeded[i * 2 + 1];
      final isBye = t2 == null;
      matches.add(KoMatch(
        id: KoMatch.generateId(),
        round: 1,
        matchIndex: i,
        team1Id: t1?.id,
        team2Id: t2?.id,
        winnerId: isBye ? t1?.id : null,
        status: isBye ? KoMatchStatus.bye : KoMatchStatus.scheduled,
      ));
    }

    // Subsequent rounds: TBD placeholders.
    for (var r = 2; r <= rounds; r++) {
      final matchCount = size ~/ pow(2, r).toInt();
      for (var i = 0; i < matchCount; i++) {
        matches.add(KoMatch(
          id: KoMatch.generateId(),
          round: r,
          matchIndex: i,
          status: KoMatchStatus.scheduled,
        ));
      }
    }

    // Propagate bye winners into round 2.
    return _propagateByes(matches);
  }

  // ── Play-in strategy ──────────────────────────────────────────────────────

  static List<KoMatch> _generateWithPlayIn(
    List<KoTeam> teams,
    KoBracketTournament t, {
    required bool repechage,
  }) {
    final n = teams.length;
    final bracketSize = _prevPow2(n);
    final playInCount = n - bracketSize;
    final directCount = bracketSize - playInCount;
    final rounds = (log(bracketSize) / log(2)).ceil();
    final matches = <KoMatch>[];

    // Round 0: play-in matches (bottom seeds).
    final directTeams = teams.sublist(0, directCount);
    final playInTeams = teams.sublist(directCount);

    for (var i = 0; i < playInCount; i++) {
      final t1 = playInTeams[i * 2];
      final t2 = playInTeams[i * 2 + 1];
      matches.add(KoMatch(
        id: KoMatch.generateId(),
        round: 0,
        matchIndex: i,
        team1Id: t1.id,
        team2Id: t2.id,
        status: KoMatchStatus.playIn,
      ));
    }

    // Optional repechage placeholder (resolved when play-in completes).
    if (repechage && playInCount > 1) {
      matches.add(KoMatch(
        id: KoMatch.generateId(),
        round: 0,
        matchIndex: playInCount,
        status: KoMatchStatus.repechage,
      ));
    }

    // Round 1: direct seeds fill top slots; play-in winners fill bottom slots.
    final seededSlots = _interleaveSeeding(
      List<KoTeam?>.from([...directTeams, ...List<KoTeam?>.filled(playInCount, null)]),
    );

    for (var i = 0; i < bracketSize ~/ 2; i++) {
      final t1 = seededSlots[i * 2];
      final t2 = seededSlots[i * 2 + 1];
      matches.add(KoMatch(
        id: KoMatch.generateId(),
        round: 1,
        matchIndex: i,
        team1Id: t1?.id,
        team2Id: t2?.id,
        status: KoMatchStatus.scheduled,
      ));
    }

    // Subsequent rounds.
    for (var r = 2; r <= rounds; r++) {
      final matchCount = bracketSize ~/ pow(2, r).toInt();
      for (var i = 0; i < matchCount; i++) {
        matches.add(KoMatch(
          id: KoMatch.generateId(),
          round: r,
          matchIndex: i,
          status: KoMatchStatus.scheduled,
        ));
      }
    }

    return matches;
  }

  // ── Winner propagation ────────────────────────────────────────────────────

  /// After completing a match, advance the winner to the next round slot and
  /// return the updated match list.
  static List<KoMatch> propagateWinner(List<KoMatch> matches, String completedMatchId) {
    final completed = matches.firstWhere((m) => m.id == completedMatchId);
    if (completed.winnerId == null) return matches;

    // Find the target match: round+1, matchIndex = completedMatch.matchIndex ~/ 2.
    final targetRound = completed.round + 1;
    final targetIndex = completed.matchIndex ~/ 2;
    final isTeam1Slot = completed.matchIndex % 2 == 0;

    final targetIdx = matches.indexWhere(
        (m) => m.round == targetRound && m.matchIndex == targetIndex);
    if (targetIdx < 0) return matches; // Final round — no next match.

    final target = matches[targetIdx];
    final updated = isTeam1Slot
        ? target.copyWith(team1Id: completed.winnerId)
        : target.copyWith(team2Id: completed.winnerId);

    return matches.map((m) => m.id == updated.id ? updated : m).toList();
  }

  /// After a play-in match completes, slot the winner into the correct round-1
  /// position (the first null slot among those reserved for play-in winners).
  static List<KoMatch> propagatePlayInWinner(
      List<KoMatch> matches, String completedMatchId) {
    final completed = matches.firstWhere((m) => m.id == completedMatchId);
    if (completed.round != 0 || completed.winnerId == null) return matches;
    if (completed.status == KoMatchStatus.repechage) {
      return propagateWinner(matches, completedMatchId);
    }

    // Find the first round-1 match with a null team slot reserved for play-in.
    final round1 = matches
        .where((m) => m.round == 1)
        .toList()
      ..sort((a, b) => a.matchIndex.compareTo(b.matchIndex));

    for (final m in round1) {
      if (m.team1Id == null) {
        final updated = m.copyWith(team1Id: completed.winnerId);
        return matches.map((x) => x.id == updated.id ? updated : x).toList();
      }
      if (m.team2Id == null) {
        final updated = m.copyWith(team2Id: completed.winnerId);
        return matches.map((x) => x.id == updated.id ? updated : x).toList();
      }
    }
    return matches;
  }

  // ── Private helpers ───────────────────────────────────────────────────────

  /// Interleaves seeding so the final is 1 vs 2, semis are 1v4 and 2v3, etc.
  static List<KoTeam?> _interleaveSeeding(List<KoTeam?> slots) {
    // Build the bracket order recursively.
    if (slots.length <= 2) return slots;
    final result = List<KoTeam?>.filled(slots.length, null);
    for (var i = 0; i < slots.length ~/ 2; i++) {
      result[i * 2] = slots[i];
      result[i * 2 + 1] = slots[slots.length - 1 - i];
    }
    return result;
  }

  static List<KoMatch> _propagateByes(List<KoMatch> matches) {
    var updated = List<KoMatch>.from(matches);
    for (final m in matches.where((m) => m.status == KoMatchStatus.bye)) {
      updated = propagateWinner(updated, m.id);
    }
    return updated;
  }
}

// ── Power-of-2 helpers ────────────────────────────────────────────────────────

int _nextPow2(int n) {
  if (n <= 1) return 1;
  var p = 1;
  while (p < n) { p <<= 1; }
  return p;
}

int _prevPow2(int n) {
  if (n <= 1) return 1;
  var p = 1;
  while (p * 2 <= n) { p <<= 1; }
  return p;
}
