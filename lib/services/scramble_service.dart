import 'dart:math';
import '../models/scramble_tournament.dart';

/// Core business logic for Timed Scramble tournaments.
///
/// Responsibilities:
///   - Schedule calculation (rounds, times)
///   - Mixing algorithm — minimise repeated teammates/opponents for any team size
///   - Sit-out rotation — players with fewest games play first
///   - Setup validation and improvement suggestions
///   - Individual player stats computation
///   - Schedule reflow after timer overruns
class ScrambleService {
  ScrambleService._();

  static int _gcd(int a, int b) => b == 0 ? a : _gcd(b, a % b);

  static final _rng = Random();
  static const _mixingAttempts = 300;

  static const _randomFirstNames = [
    'Alex', 'Sam', 'Jordan', 'Taylor', 'Morgan', 'Casey', 'Riley', 'Avery',
    'Quinn', 'Drew', 'Reese', 'Blake', 'Skyler', 'Peyton', 'Jamie', 'Rowan',
    'Finley', 'Emery', 'Sage', 'River',
  ];
  static const _randomLastNames = [
    'Smith', 'Jones', 'Williams', 'Brown', 'Davis', 'Miller', 'Wilson',
    'Moore', 'Taylor', 'Anderson', 'Thomas', 'Jackson', 'White', 'Harris',
    'Martin', 'Thompson', 'Garcia', 'Martinez', 'Robinson', 'Clark',
  ];

  // ── Schedule Builder ────────────────────────────────────────────────────────

  /// Build a complete [ScrambleTournament] from setup parameters.
  ///
  /// [playersPerTeam] determines game format: 2 → 2v2, 3 → 3v3.
  /// [courtCount] is the physical cap; actual active courts each round may be
  /// fewer if player count < courtCount × playersPerTeam × 2.
  static ScrambleTournament buildTournament({
    required String name,
    required Duration totalAvailableTime,
    required Duration matchDuration,
    required Duration breakDuration,
    required int courtCount,
    required int playersPerTeam,
    required List<ScramblePlayer> players,
    required DateTime startTime,
  }) {
    final roundDuration   = matchDuration + breakDuration;
    final playersPerCourt = playersPerTeam * 2;
    final n               = players.length;
    final activeCourtsMax = min(courtCount, n ~/ playersPerCourt);
    final activePlayers   = activeCourtsMax * playersPerCourt;

    final rawRounds = roundDuration.inSeconds > 0
        ? totalAvailableTime.inSeconds ~/ roundDuration.inSeconds
        : 0;

    // Snap to the largest multiple of the fair-unit that fits in available time.
    // Fair-unit = smallest R where every player has played equally often.
    int roundCount;
    if (activePlayers > 0 && activePlayers < n && rawRounds > 1) {
      final fairUnit = n ~/ _gcd(n, activePlayers);
      final snapped  = (rawRounds ~/ fairUnit) * fairUnit;
      roundCount = snapped > 0 ? snapped : rawRounds;
    } else {
      roundCount = rawRounds;
    }

    // Pair-encounter matrices for mixing optimisation.
    final teammateCount = List.generate(n, (_) => List.filled(n, 0));
    final opponentCount = List.generate(n, (_) => List.filled(n, 0));
    final playerIndex = {for (var i = 0; i < n; i++) players[i].id: i};

    // Games played per player — drives sit-out rotation.
    final gamesPlayed = List.filled(n, 0);

    final rounds = <ScrambleRound>[];
    final games = <ScrambleGame>[];

    for (var r = 0; r < roundCount; r++) {
      final roundId = ScrambleRound.generateId();
      final roundStart = startTime.add(roundDuration * r);

      rounds.add(ScrambleRound(
        id: roundId,
        roundNumber: r + 1,
        scheduledStartTime: roundStart,
        matchDuration: matchDuration,
        breakDuration: breakDuration,
      ));

      // Active courts this round — capped by physical court count AND by
      // how many complete courts the current player count can fill.
      final activeCourts = min(courtCount, n ~/ playersPerCourt);
      if (activeCourts == 0) continue;

      // Select active players: prioritise those who have played fewer games
      // so sit-outs are shared as evenly as possible.
      final sortedByGames = List<int>.generate(n, (i) => i)
        ..sort((a, b) => gamesPlayed[a].compareTo(gamesPlayed[b]));
      final activeIndices =
          sortedByGames.take(activeCourts * playersPerCourt).toSet();
      final sittingOutIndices =
          sortedByGames.skip(activeCourts * playersPerCourt).toSet();

      final activePlayers = players
          .where((p) => activeIndices.contains(playerIndex[p.id]))
          .toList();
      final sittingOutIds = players
          .where((p) => sittingOutIndices.contains(playerIndex[p.id]))
          .map((p) => p.id)
          .toList();

      final courtAssignments = _optimiseAssignments(
        activePlayers: activePlayers,
        activeCourts: activeCourts,
        playersPerTeam: playersPerTeam,
        teammateCount: teammateCount,
        opponentCount: opponentCount,
        playerIndex: playerIndex,
      );

      for (var c = 0; c < courtAssignments.length; c++) {
        final (sideA, sideB) = courtAssignments[c];
        games.add(ScrambleGame(
          id: ScrambleGame.generateId(),
          roundId: roundId,
          courtNumber: c + 1,
          sideAPlayerIds: sideA.map((p) => p.id).toList(),
          sideBPlayerIds: sideB.map((p) => p.id).toList(),
          // Sit-outs are attached to the first court's game for display;
          // all games in the round share the same sitting-out list.
          sittingOutPlayerIds: c == 0 ? sittingOutIds : const [],
        ));

        _updatePairMatrices(
          sideA: sideA,
          sideB: sideB,
          playerIndex: playerIndex,
          teammateCount: teammateCount,
          opponentCount: opponentCount,
          gamesPlayed: gamesPlayed,
        );
      }
    }

    return ScrambleTournament(
      id: ScrambleTournament.generateId(),
      name: name,
      totalAvailableTime: totalAvailableTime,
      matchDuration: matchDuration,
      breakDuration: breakDuration,
      courtCount: courtCount,
      playersPerTeam: playersPerTeam,
      startTime: startTime,
      status: ScrambleTournamentStatus.setup,
      players: players,
      rounds: rounds,
      games: games,
      createdAt: DateTime.now(),
    );
  }

  // ── Mixing Algorithm ────────────────────────────────────────────────────────

  /// Returns the best court assignment across [_mixingAttempts] random shuffles.
  ///
  /// For each shuffle, players are grouped into courts of [playersPerTeam × 2].
  /// Each court group is split into two equal sides, choosing the split that
  /// minimises repeated teammate (penalised ²) and opponent (penalised ×0.5)
  /// encounters.
  static List<(List<ScramblePlayer>, List<ScramblePlayer>)> _optimiseAssignments({
    required List<ScramblePlayer> activePlayers,
    required int activeCourts,
    required int playersPerTeam,
    required List<List<int>> teammateCount,
    required List<List<int>> opponentCount,
    required Map<String, int> playerIndex,
  }) {
    final playersPerCourt = playersPerTeam * 2;
    List<(List<ScramblePlayer>, List<ScramblePlayer>)>? best;
    var bestScore = double.infinity;

    for (var attempt = 0; attempt < _mixingAttempts; attempt++) {
      final shuffled = List<ScramblePlayer>.from(activePlayers)..shuffle(_rng);

      final candidate = <(List<ScramblePlayer>, List<ScramblePlayer>)>[];
      var candidateScore = 0.0;

      for (var c = 0; c < activeCourts; c++) {
        final court =
            shuffled.sublist(c * playersPerCourt, (c + 1) * playersPerCourt);
        final (split, splitScore) = _bestSplit(
          court: court,
          playersPerTeam: playersPerTeam,
          playerIndex: playerIndex,
          teammateCount: teammateCount,
          opponentCount: opponentCount,
        );
        candidate.add(split);
        candidateScore += splitScore;
      }

      if (candidateScore < bestScore) {
        bestScore = candidateScore;
        best = candidate;
        if (bestScore == 0) break; // perfect — no repeats
      }
    }

    return best!;
  }

  /// Evaluates all valid even splits of [court] into two sides of [playersPerTeam]
  /// and returns the lowest-scoring split.
  ///
  /// For 2v2 (4 players): 3 unique splits.
  /// For 3v3 (6 players): C(6,3)/2 = 10 unique splits.
  static ((List<ScramblePlayer>, List<ScramblePlayer>), double) _bestSplit({
    required List<ScramblePlayer> court,
    required int playersPerTeam,
    required Map<String, int> playerIndex,
    required List<List<int>> teammateCount,
    required List<List<int>> opponentCount,
  }) {
    final splits =
        _generateSplits(court, playersPerTeam);

    (List<ScramblePlayer>, List<ScramblePlayer>)? bestSplit;
    var bestScore = double.infinity;

    for (final s in splits) {
      final score = _scoreCourtAssignment(
        sideA: s.$1,
        sideB: s.$2,
        playerIndex: playerIndex,
        teammateCount: teammateCount,
        opponentCount: opponentCount,
      );
      if (score < bestScore) {
        bestScore = score;
        bestSplit = s;
      }
    }

    return (bestSplit!, bestScore);
  }

  /// Generate all unique ways to split [players] into two groups of [teamSize].
  ///
  /// Fixes the first player to side A to avoid mirror duplicates.
  static List<(List<ScramblePlayer>, List<ScramblePlayer>)> _generateSplits(
    List<ScramblePlayer> players,
    int teamSize,
  ) {
    final result = <(List<ScramblePlayer>, List<ScramblePlayer>)>[];
    final n = players.length; // should equal teamSize * 2
    final others = players.sublist(1); // fix players[0] to side A

    void combine(List<int> chosen, int start) {
      if (chosen.length == teamSize - 1) {
        final sideA = [players[0], ...chosen.map((i) => others[i])];
        final sideB =
            others.whereIndexed((i, _) => !chosen.contains(i)).toList();
        result.add((sideA, sideB));
        return;
      }
      for (var i = start; i < others.length; i++) {
        combine([...chosen, i], i + 1);
      }
    }

    if (n == teamSize * 2 && teamSize > 0) combine([], 0);
    return result;
  }

  /// Scores a single court assignment.
  ///
  /// Repeated teammates are penalised count² (strongly discourages repeats).
  /// Repeated opponents are penalised count×0.5 (mildly discourages repeats).
  static double _scoreCourtAssignment({
    required List<ScramblePlayer> sideA,
    required List<ScramblePlayer> sideB,
    required Map<String, int> playerIndex,
    required List<List<int>> teammateCount,
    required List<List<int>> opponentCount,
  }) {
    double score = 0;

    void penaliseTeammates(List<ScramblePlayer> team) {
      for (var i = 0; i < team.length; i++) {
        for (var j = i + 1; j < team.length; j++) {
          final a = playerIndex[team[i].id]!;
          final b = playerIndex[team[j].id]!;
          final c = teammateCount[a][b];
          score += c * c.toDouble();
        }
      }
    }

    penaliseTeammates(sideA);
    penaliseTeammates(sideB);

    for (final pa in sideA) {
      for (final pb in sideB) {
        final a = playerIndex[pa.id]!;
        final b = playerIndex[pb.id]!;
        score += opponentCount[a][b] * 0.5;
      }
    }

    return score;
  }

  static void _updatePairMatrices({
    required List<ScramblePlayer> sideA,
    required List<ScramblePlayer> sideB,
    required Map<String, int> playerIndex,
    required List<List<int>> teammateCount,
    required List<List<int>> opponentCount,
    required List<int> gamesPlayed,
  }) {
    void addTeammates(List<ScramblePlayer> team) {
      for (var i = 0; i < team.length; i++) {
        final ia = playerIndex[team[i].id]!;
        gamesPlayed[ia]++;
        for (var j = i + 1; j < team.length; j++) {
          final ib = playerIndex[team[j].id]!;
          teammateCount[ia][ib]++;
          teammateCount[ib][ia]++;
        }
      }
    }

    addTeammates(sideA);
    addTeammates(sideB);

    for (final pa in sideA) {
      for (final pb in sideB) {
        final ia = playerIndex[pa.id]!;
        final ib = playerIndex[pb.id]!;
        opponentCount[ia][ib]++;
        opponentCount[ib][ia]++;
      }
    }
  }

  // ── Validation & Suggestions ──────────────────────────────────────────────

  static List<ScrambleSuggestion> validate({
    required Duration totalAvailableTime,
    required Duration matchDuration,
    required Duration breakDuration,
    required int courtCount,
    required int playerCount,
    required int playersPerTeam,
  }) {
    final suggestions     = <ScrambleSuggestion>[];
    final roundDuration   = matchDuration + breakDuration;
    final playersPerCourt = playersPerTeam * 2;

    if (roundDuration.inSeconds <= 0) {
      suggestions.add(const ScrambleSuggestion(
        type: ScrambleSuggestionType.adjustMatchDuration,
        message: 'Match and break duration must be greater than zero.',
      ));
      return suggestions;
    }

    final activeCourts  = min(courtCount, playerCount ~/ playersPerCourt);
    final playersActive = activeCourts * playersPerCourt;
    final sittingOut    = playerCount - playersActive;

    if (activeCourts == 0) {
      suggestions.add(ScrambleSuggestion(
        type: ScrambleSuggestionType.adjustPlayerCount,
        message: 'At least $playersPerCourt players are needed for one '
            '${playersPerTeam}v$playersPerTeam court. '
            'Add more players or switch to a smaller format.',
      ));
      return suggestions;
    }

    // Fair-unit: smallest round count where every player has played equally.
    // When nobody sits out, every round count is already fair (unit = 1).
    final fairUnit = sittingOut > 0
        ? playerCount ~/ _gcd(playerCount, playersActive)
        : 1;

    final rawRounds  = totalAvailableTime.inSeconds ~/ roundDuration.inSeconds;
    final roundCount = (rawRounds ~/ fairUnit) * fairUnit;

    if (roundCount == 0) {
      // Available time is either shorter than one round, or shorter than the
      // minimum fair-unit of rounds — suggest how much extra time is needed.
      final neededSecs = fairUnit * roundDuration.inSeconds;
      final shortfall  = Duration(seconds: neededSecs - totalAvailableTime.inSeconds);
      final neededStr  = _fmtDuration(Duration(seconds: neededSecs));
      suggestions.add(ScrambleSuggestion(
        type: ScrambleSuggestionType.increaseTotalTime,
        message: sittingOut > 0
            ? 'Not every player can play the same amount of games with this '
              'setup. The minimum is $fairUnit rounds ($neededStr). '
              'Set available time to $neededStr — or adjust match/break duration.'
            : 'Available time is too short for even one round '
              '(${_fmtDuration(roundDuration)} per round). '
              'Increase available time — or adjust match/break duration.',
        actionLabel: '+${_fmtDuration(shortfall)}',
        isBlocking: true,
      ));
      return suggestions;
    }

    // Coverage & repeated-teammate checks.
    // Both only apply when N > 1 (there are teammates to consider).
    if (playersPerTeam > 1) {
      // ── Coverage ────────────────────────────────────────────────────────────
      // Minimum rounds for every player to partner with every other at least once
      // = ceil((P-1) / (N-1)), rounded up to the next fair-unit multiple.
      final minCoverage  = ((playerCount - 1) / (playersPerTeam - 1)).ceil();
      final targetRounds = ((minCoverage + fairUnit - 1) ~/ fairUnit) * fairUnit;

      // ── Repeated teammates ───────────────────────────────────────────────────
      // A player partners with N-1 teammates per game.
      // Over R rounds each player plays gamesPerPlayer = R × activePlayers / P games.
      // Repeats start when gamesPerPlayer × (N-1) > P-1
      //   → R > P×(P-1) / (activePlayers×(N-1))
      final maxNoRepeatRaw   = (playerCount * (playerCount - 1)) ~/
          (playersActive * (playersPerTeam - 1));
      // Snap down to the largest fair-unit multiple that avoids repeats.
      final maxNoRepeatRounds = (maxNoRepeatRaw ~/ fairUnit) * fairUnit;

      if (roundCount < targetRounds) {
        final extraRounds  = targetRounds - roundCount;
        final extraSecs    = extraRounds * roundDuration.inSeconds;
        final targetSecs   = targetRounds * roundDuration.inSeconds;
        final targetTimeStr = _fmtDuration(Duration(seconds: targetSecs));
        suggestions.add(ScrambleSuggestion(
          type: ScrambleSuggestionType.increaseTotalTime,
          message: 'With $roundCount rounds, not every player will partner with '
              'each other ($targetRounds rounds needed). Set available time to '
              '$targetTimeStr — or adjust match/break duration.',
          actionLabel: '+${_fmtDuration(Duration(seconds: extraSecs))}',
        ));
      } else if (roundCount > maxNoRepeatRaw) {
        // Repeats are happening — tell the user the threshold.
        if (maxNoRepeatRounds > 0) {
          final maxTimeSecs   = maxNoRepeatRounds * roundDuration.inSeconds;
          final maxTimeStr    = _fmtDuration(Duration(seconds: maxTimeSecs));
          suggestions.add(ScrambleSuggestion(
            type: ScrambleSuggestionType.repeatedTeammates,
            message: 'With $roundCount rounds, players will partner with each '
                'other more than once (repeats from round ${maxNoRepeatRaw + 1}). '
                'To keep all partnerships unique: $maxTimeStr available time '
                '($maxNoRepeatRounds rounds) — or adjust match/break duration.',
          ));
        } else {
          // Even the minimum fair cycle exceeds the no-repeat threshold.
          suggestions.add(ScrambleSuggestion(
            type: ScrambleSuggestionType.repeatedTeammates,
            message: 'With this setup, repeated partners cannot be avoided — '
                'the minimum fair schedule ($fairUnit rounds) already exceeds '
                'the no-repeat threshold. Adjust match/break duration to reduce '
                'the number of games per player.',
          ));
        }
      }
    }

    if (activeCourts < courtCount) {
      suggestions.add(ScrambleSuggestion(
        type: ScrambleSuggestionType.adjustCourtCount,
        message: 'Only $activeCourts of $courtCount courts can be filled '
            'with $playerCount players in ${playersPerTeam}v$playersPerTeam. '
            'Reduce courts to $activeCourts or add more players.',
      ));
    }

    if (breakDuration.inMinutes > matchDuration.inMinutes) {
      suggestions.add(ScrambleSuggestion(
        type: ScrambleSuggestionType.reduceBreakDuration,
        message: 'Break duration (${_fmtDuration(breakDuration)}) is longer '
            'than match duration (${_fmtDuration(matchDuration)}). '
            'Consider reducing breaks to allow more rounds.',
      ));
    }

    return suggestions;
  }

  // ── Stats ─────────────────────────────────────────────────────────────────

  static List<ScramblePlayerStats> computeStats(ScrambleTournament t) {
    final statsMap = <String, ScramblePlayerStats>{};

    for (final player in t.players) {
      statsMap[player.id] = ScramblePlayerStats(
        playerId: player.id,
        playerName: player.name,
      );
    }

    for (final game in t.games) {
      if (!game.isCompleted) continue;

      final aIds = game.sideAPlayerIds;
      final bIds = game.sideBPlayerIds;
      final aScore = game.sideAScore;
      final bScore = game.sideBScore;
      final winner = game.winningSide;

      for (final id in aIds) {
        final s = statsMap[id];
        if (s == null) continue;
        statsMap[id] = ScramblePlayerStats(
          playerId: s.playerId,
          playerName: s.playerName,
          totalPoints: s.totalPoints + aScore,
          pointsAgainst: s.pointsAgainst + bScore,
          gamesPlayed: s.gamesPlayed + 1,
          wins: s.wins + (winner == 'A' ? 1 : 0),
          losses: s.losses + (winner == 'B' ? 1 : 0),
          draws: s.draws + (winner == null ? 1 : 0),
          uniqueTeammateIds: {
            ...s.uniqueTeammateIds,
            ...aIds.where((x) => x != id)
          },
          uniqueOpponentIds: {...s.uniqueOpponentIds, ...bIds},
        );
      }

      for (final id in bIds) {
        final s = statsMap[id];
        if (s == null) continue;
        statsMap[id] = ScramblePlayerStats(
          playerId: s.playerId,
          playerName: s.playerName,
          totalPoints: s.totalPoints + bScore,
          pointsAgainst: s.pointsAgainst + aScore,
          gamesPlayed: s.gamesPlayed + 1,
          wins: s.wins + (winner == 'B' ? 1 : 0),
          losses: s.losses + (winner == 'A' ? 1 : 0),
          draws: s.draws + (winner == null ? 1 : 0),
          uniqueTeammateIds: {
            ...s.uniqueTeammateIds,
            ...bIds.where((x) => x != id)
          },
          uniqueOpponentIds: {...s.uniqueOpponentIds, ...aIds},
        );
      }
    }

    final sorted = statsMap.values.toList()
      ..sort((a, b) {
        final byPoints = b.totalPoints.compareTo(a.totalPoints);
        if (byPoints != 0) return byPoints;
        final byWins = b.wins.compareTo(a.wins);
        if (byWins != 0) return byWins;
        return b.pointDifference.compareTo(a.pointDifference);
      });

    for (var i = 0; i < sorted.length; i++) {
      sorted[i].rank = i + 1;
    }

    return sorted;
  }

  // ── Schedule Reflow ───────────────────────────────────────────────────────

  static ScrambleTournament reflowSchedule(
    ScrambleTournament tournament, {
    required int fromRoundNumber,
    required Duration delta,
  }) {
    final updatedRounds = tournament.rounds.map((r) {
      if (r.roundNumber < fromRoundNumber) return r;
      return r.copyWith(
        scheduledStartTime: r.scheduledStartTime.add(delta),
      );
    }).toList();
    return tournament.copyWith(rounds: updatedRounds);
  }

  // ── Player Generation ─────────────────────────────────────────────────────

  static ScramblePlayer randomPlayer() {
    final first = _randomFirstNames[_rng.nextInt(_randomFirstNames.length)];
    final last = _randomLastNames[_rng.nextInt(_randomLastNames.length)];
    return ScramblePlayer(
      id: ScramblePlayer.generateId(),
      name: '$first $last',
      source: ScramblePlayerSource.random,
    );
  }

  static List<ScramblePlayer> generateRandomPlayers(int count) =>
      List.generate(count, (_) => randomPlayer());

  // ── Helpers ───────────────────────────────────────────────────────────────

  static String _fmtDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    if (h > 0) return '${h}h ${m}m';
    if (m > 0 && s > 0) return '${m}m ${s}s';
    if (m > 0) return '${m}m';
    return '${s}s';
  }

  static String formatDuration(Duration d) => _fmtDuration(d);

  static String formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

// Iterable extension used internally for split generation.
extension _IndexedWhere<T> on Iterable<T> {
  Iterable<T> whereIndexed(bool Function(int index, T element) test) sync* {
    var i = 0;
    for (final e in this) {
      if (test(i, e)) yield e;
      i++;
    }
  }
}
