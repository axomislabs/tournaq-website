import 'dart:math';
import '../models/scramble_tournament.dart';
import 'scramble_team_names.dart';

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
  // Beyond this player count the optimiser switches to statistical mode:
  // court groupings are too numerous to sample meaningfully, so fewer
  // attempts are used and repeats are naturally rare at scale.
  static const _exhaustivePlayerLimit = 32;

  // Whole-tournament attempts made when searching for a zero-teammate-repeat
  // schedule (only used when the requested round count is within the safe
  // no-repeat threshold — see [_repeatThresholds]). A single scheduling pass
  // only reaches zero repeats a fraction of the time, since sit-out rotation
  // has no look-ahead and can back itself into a corner a few rounds in;
  // retrying the whole build with fresh randomness reliably finds one.
  static const _zeroRepeatSearchAttempts = 24;

  // The theoretical round count at which repeats become mathematically
  // forced (see [_repeatThresholds]) assumes a perfectly efficient schedule —
  // reaching it in practice would require the randomized search to stumble
  // onto a near-perfect combinatorial design, which it reliably does not.
  // Empirically calibrated (see scramble_service_test.dart): backing the
  // recommended cap off to this percentage of the raw ceiling is reliably
  // achievable across a wide range of player/court/format combinations,
  // whereas the raw ceiling itself often is not — this applies broadly, not
  // just to exact-fit ("zero-slack") configurations.
  static const _repeatSafetyPercent = 65;

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

  /// Coverage/repeat round-count thresholds shared by [validate] and
  /// [buildTournament].
  ///
  /// [coverageTargetRounds] is the unpadded theoretical minimum for every
  /// player to partner with every other at least once.
  /// [maxNoRepeatRounds] is the round count (snapped to [fairUnit]) at/below
  /// which zero teammate repeats should be reliably achievable — backed off
  /// from the raw mathematical ceiling by [_repeatSafetyPercent], since
  /// hitting that ceiling exactly would require the randomized search to
  /// stumble onto a near-perfect combinatorial design.
  static ({int coverageTargetRounds, int maxNoRepeatRounds}) _repeatThresholds({
    required int playerCount,
    required int playersActive,
    required int playersPerTeam,
    required int fairUnit,
  }) {
    final coverageNumerator   = playerCount * (playerCount - 1);
    final coverageDenominator = playersActive * (playersPerTeam - 1);

    final minCoverageRoundsRaw =
        (coverageNumerator + coverageDenominator - 1) ~/ coverageDenominator;
    final maxNoRepeatRaw = coverageNumerator ~/ coverageDenominator;

    final coverageTargetRounds =
        ((minCoverageRoundsRaw + fairUnit - 1) ~/ fairUnit) * fairUnit;

    // Apply the safety percentage in units of whole fair-unit cycles, not
    // raw rounds — applying it to the raw value first can floor-divide away
    // to 0 whenever fairUnit is a large fraction of maxNoRepeatRaw (e.g. only
    // 1 natural cycle fits at all), even though that single natural cycle is
    // itself typically still safe. Never recommend fewer than 1 cycle when at
    // least 1 fits under the raw ceiling.
    final naturalMultiples = maxNoRepeatRaw ~/ fairUnit;
    final safeMultiples = (maxNoRepeatRaw * _repeatSafetyPercent) ~/ 100 ~/ fairUnit;
    final multiples = naturalMultiples > 0 ? max(1, safeMultiples) : 0;
    final maxNoRepeatRounds = multiples * fairUnit;

    return (
      coverageTargetRounds: coverageTargetRounds,
      maxNoRepeatRounds: maxNoRepeatRounds,
    );
  }

  static ScrambleTournament buildTournament({
    required String name,
    required int roundCount,
    required Duration matchDuration,
    required Duration breakDuration,
    required int courtCount,
    required int playersPerTeam,
    required List<ScramblePlayer> players,
    required DateTime startTime,
    bool paceAlertsEnabled = false,
  }) {
    final roundDuration   = matchDuration + breakDuration;
    final playersPerCourt = playersPerTeam * 2;
    final n               = players.length;
    final activeCourtsMax = min(courtCount, n ~/ playersPerCourt);
    final activePlayers   = activeCourtsMax * playersPerCourt;

    // fairUnit still feeds the coverage/repeat math in _repeatThresholds — it
    // no longer caps roundCount itself, which is now used exactly as given.
    final fairUnit = (activePlayers > 0 && activePlayers < n)
        ? n ~/ _gcd(n, activePlayers)
        : 1;

    // When the round count is within the safe no-repeat threshold, search
    // across several whole-tournament attempts for a zero-teammate-repeat
    // schedule (a single attempt isn't reliable enough — see
    // [_zeroRepeatSearchAttempts]). Beyond that threshold repeats are
    // mathematically forced regardless of schedule quality, so a single pass
    // is used as before.
    final attemptsAllowed = (playersPerTeam > 1 && activePlayers > 0)
        ? () {
            final t = _repeatThresholds(
              playerCount: n,
              playersActive: activePlayers,
              playersPerTeam: playersPerTeam,
              fairUnit: fairUnit,
            );
            return roundCount > 0 && roundCount <= t.maxNoRepeatRounds
                ? _zeroRepeatSearchAttempts
                : 1;
          }()
        : 1;

    (List<ScrambleRound>, List<ScrambleGame>, int)? best;
    for (var attempt = 0; attempt < attemptsAllowed; attempt++) {
      final result = _buildScheduleAttempt(
        roundCount: roundCount,
        courtCount: courtCount,
        playersPerTeam: playersPerTeam,
        playersPerCourt: playersPerCourt,
        players: players,
        startTime: startTime,
        matchDuration: matchDuration,
        breakDuration: breakDuration,
        roundDuration: roundDuration,
      );
      if (best == null || result.$3 < best.$3) {
        best = result;
        if (best.$3 == 0) break; // perfect — no teammate repeats anywhere
      }
    }

    final (rounds, games, _) = best!;

    return ScrambleTournament(
      id: ScrambleTournament.generateId(),
      name: name,
      totalAvailableTime: roundDuration * roundCount,
      matchDuration: matchDuration,
      breakDuration: breakDuration,
      courtCount: courtCount,
      playersPerTeam: playersPerTeam,
      paceAlertsEnabled: paceAlertsEnabled,
      startTime: startTime,
      players: players,
      rounds: rounds,
      games: games,
      createdAt: DateTime.now(),
    );
  }

  /// Builds one candidate schedule attempt: [roundCount] rounds of games for
  /// [players], plus the resulting [teammateExcess] — the sum, over every
  /// pair of players, of how many times beyond their first they ended up as
  /// teammates. Zero means no teammate ever repeated. Opponent repeats are
  /// deliberately not counted — only teammate uniqueness is prioritised.
  static (List<ScrambleRound>, List<ScrambleGame>, int) _buildScheduleAttempt({
    required int roundCount,
    required int courtCount,
    required int playersPerTeam,
    required int playersPerCourt,
    required List<ScramblePlayer> players,
    required DateTime startTime,
    required Duration matchDuration,
    required Duration breakDuration,
    required Duration roundDuration,
  }) {
    final n = players.length;

    // Pair-encounter matrices for mixing optimisation.
    final teammateCount = List.generate(n, (_) => List.filled(n, 0));
    final opponentCount = List.generate(n, (_) => List.filled(n, 0));
    final playerIndex = {for (var i = 0; i < n; i++) players[i].id: i};

    // Games played per player — drives sit-out rotation.
    final gamesPlayed = List.filled(n, 0);
    // Serve count per player — drives first-server assignment.
    final serveCount = List.filled(n, 0);
    // Arb count per player — drives fair arbitrator assignment.
    final arbCount = List.filled(n, 0);

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
      final (activeIndices, sittingOutIndices) = _selectActiveIndices(
        n: n,
        gamesPlayed: gamesPlayed,
        activeCourts: activeCourts,
        playersPerCourt: playersPerCourt,
      );

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
        totalPlayers: n,
      );

      // Arb queue for this round: sitting-out players sorted by fewest arbs.
      // One arb is popped per court; if exhausted the court gets null (manual).
      final arbQueue = sittingOutIndices.toList()
        ..sort((a, b) => arbCount[a].compareTo(arbCount[b]));

      for (var c = 0; c < courtAssignments.length; c++) {
        final (sideA, sideB) = courtAssignments[c];

        // Greedy first-server: pick the on-court player with the fewest serves.
        // Ties broken by position in the combined list (stable, bias-free).
        final onCourt = [...sideA, ...sideB];
        final server = onCourt.reduce((a, b) {
          final ca = serveCount[playerIndex[a.id]!];
          final cb = serveCount[playerIndex[b.id]!];
          return ca <= cb ? a : b;
        });
        serveCount[playerIndex[server.id]!]++;

        // Greedy arbitrator: draw from sitting-out queue; null when pool empty.
        String? arbitratorId;
        if (arbQueue.isNotEmpty) {
          final arbIdx = arbQueue.removeAt(0);
          arbitratorId = players[arbIdx].id;
          arbCount[arbIdx]++;
        }

        final sideAIds = sideA.map((p) => p.id).toList();
        final sideBIds = sideB.map((p) => p.id).toList();
        final (nameA, nameB) = ScrambleTeamNames.generate(sideAIds, sideBIds);
        games.add(ScrambleGame(
          id: ScrambleGame.generateId(),
          roundId: roundId,
          courtNumber: c + 1,
          sideAPlayerIds: sideAIds,
          sideBPlayerIds: sideBIds,
          // Sit-outs are attached to the first court's game for display;
          // all games in the round share the same sitting-out list.
          sittingOutPlayerIds: c == 0 ? sittingOutIds : const [],
          firstServerId: server.id,
          arbitratorId: arbitratorId,
          teamNameA: nameA,
          teamNameB: nameB,
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

    var teammateExcess = 0;
    for (var i = 0; i < n; i++) {
      for (var j = i + 1; j < n; j++) {
        final c = teammateCount[i][j];
        if (c > 1) teammateExcess += c - 1;
      }
    }

    return (rounds, games, teammateExcess);
  }

  /// Selects which player indices are active this round vs. sitting out.
  ///
  /// Prioritises fewest games played, same as a plain sort by [gamesPlayed]
  /// would — but shuffles first so that ties (very common, since players
  /// frequently have equal games played) don't always resolve to the same
  /// fixed index order. Without this, a stable/deterministic sort applied to
  /// an all-tied list reproduces the exact same active/sitting-out partition
  /// every time the group re-ties, permanently locking two subsets of
  /// players out of ever sharing a round together.
  static (Set<int> active, Set<int> sittingOut) _selectActiveIndices({
    required int n,
    required List<int> gamesPlayed,
    required int activeCourts,
    required int playersPerCourt,
  }) {
    final order = List<int>.generate(n, (i) => i)..shuffle(_rng);
    order.sort((a, b) => gamesPlayed[a].compareTo(gamesPlayed[b]));
    final cut = activeCourts * playersPerCourt;
    return (order.take(cut).toSet(), order.skip(cut).toSet());
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
    required int totalPlayers,
  }) {
    final playersPerCourt = playersPerTeam * 2;
    final attempts = totalPlayers <= _exhaustivePlayerLimit
        ? _mixingAttempts
        : 30; // statistical mode — repeats are rare at scale anyway
    List<(List<ScramblePlayer>, List<ScramblePlayer>)>? best;
    var bestScore = double.infinity;

    for (var attempt = 0; attempt < attempts; attempt++) {
      final shuffled = List<ScramblePlayer>.from(activePlayers)..shuffle(_rng);
      final courts = _formCourts(
        shuffled: shuffled,
        activeCourts: activeCourts,
        playersPerCourt: playersPerCourt,
        playerIndex: playerIndex,
        teammateCount: teammateCount,
        opponentCount: opponentCount,
      );

      final candidate = <(List<ScramblePlayer>, List<ScramblePlayer>)>[];
      var candidateScore = 0.0;

      for (var c = 0; c < activeCourts; c++) {
        final court = courts[c];
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

  /// Partitions [shuffled] into [activeCourts] groups of [playersPerCourt].
  ///
  /// Unlike a plain consecutive slice of the shuffle, each court is filled
  /// greedily: after seeding with the next unplaced (shuffled) player, the
  /// remaining seats are filled with whichever unplaced players have the
  /// least prior teammate/opponent exposure to those already placed on that
  /// court. This actively steers court *membership* itself toward fresh
  /// pairings — a plain slice only ever gets that "for free" by luck, and
  /// leaves it to [_bestSplit] to optimise within a group it had no say in
  /// forming. Ties fall back to shuffle order, keeping attempt-to-attempt
  /// diversity across the caller's search loop.
  static List<List<ScramblePlayer>> _formCourts({
    required List<ScramblePlayer> shuffled,
    required int activeCourts,
    required int playersPerCourt,
    required Map<String, int> playerIndex,
    required List<List<int>> teammateCount,
    required List<List<int>> opponentCount,
  }) {
    final remaining = List<ScramblePlayer>.from(shuffled);
    final courts = <List<ScramblePlayer>>[];

    for (var c = 0; c < activeCourts; c++) {
      final court = <ScramblePlayer>[remaining.removeAt(0)];

      while (court.length < playersPerCourt) {
        ScramblePlayer? bestCandidate;
        var bestExposure = -1;

        for (final candidate in remaining) {
          final b = playerIndex[candidate.id]!;
          var exposure = 0;
          for (final placed in court) {
            final a = playerIndex[placed.id]!;
            exposure += teammateCount[a][b] + opponentCount[a][b];
          }
          if (bestCandidate == null || exposure < bestExposure) {
            bestCandidate = candidate;
            bestExposure = exposure;
          }
        }

        court.add(bestCandidate!);
        remaining.remove(bestCandidate);
      }

      courts.add(court);
    }

    return courts;
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
  /// Repeated opponents are penalised count²×0.5 (discourages repeats too,
  /// just less aggressively than teammates — but still superlinearly, so a
  /// second/third repeat against the same opponent isn't treated as nearly
  /// free the way a flat per-repeat cost would).
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
        final c = opponentCount[a][b];
        score += c * c.toDouble() * 0.5;
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
    required int roundCount,
    required Duration matchDuration,
    required Duration breakDuration,
    required int courtCount,
    required int playerCount,
    required int playersPerTeam,
  }) {
    final suggestions     = <ScrambleSuggestion>[];
    final roundDuration   = matchDuration + breakDuration;
    final playersPerCourt = playersPerTeam * 2;

    if (roundCount <= 0) {
      // Defensive only — the Rounds field is clamped to a minimum of 1 in
      // the UI, so this should be unreachable in practice.
      suggestions.add(const ScrambleSuggestion(
        type: ScrambleSuggestionType.tooFewRounds,
        message: 'At least 1 round is needed to build a schedule.',
        isBlocking: true,
      ));
      return suggestions;
    }

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

    if (playerCount > _exhaustivePlayerLimit) {
      suggestions.add(ScrambleSuggestion(
        type: ScrambleSuggestionType.largeGroup,
        message: 'With $playerCount players the mixing becomes statistical — '
            'everyone-against-everyone is no longer guaranteed, but equal '
            'play time still is. This works well for large events.',
      ));
    }

    // Fair-unit: smallest round count where every player has played equally.
    // When nobody sits out, every round count is already fair (unit = 1).
    // Only feeds the coverage/repeat math below — it no longer caps
    // roundCount itself, which is used exactly as given.
    final fairUnit = sittingOut > 0
        ? playerCount ~/ _gcd(playerCount, playersActive)
        : 1;

    // Repeat-avoidance & coverage checks. Both only apply when N > 1 (there
    // are teammates to consider). Avoiding any teammate repeat is prioritised
    // over full coverage — when a player/court combination can't have both,
    // the schedule stays within the no-repeat threshold even if that means
    // some players won't meet every other player.
    if (playersPerTeam > 1) {
      final t = _repeatThresholds(
        playerCount: playerCount,
        playersActive: playersActive,
        playersPerTeam: playersPerTeam,
        fairUnit: fairUnit,
      );

      if (roundCount > t.maxNoRepeatRounds) {
        final coverageNote = t.maxNoRepeatRounds < t.coverageTargetRounds
            ? ' Full coverage (everyone partners with everyone) would take '
                '${t.coverageTargetRounds} rounds, but then some players '
                'would repeat partners.'
            : '';
        suggestions.add(ScrambleSuggestion(
          type: ScrambleSuggestionType.capRoundsForFreshPartners,
          message: 'With $roundCount rounds, some partnerships will repeat. '
              'Up to ${t.maxNoRepeatRounds} rounds keeps every partnership '
              'unique.$coverageNote',
          actionLabel: t.maxNoRepeatRounds > 0
              ? 'Cap at ${t.maxNoRepeatRounds} rounds'
              : null,
          suggestedRoundCount:
              t.maxNoRepeatRounds > 0 ? t.maxNoRepeatRounds : null,
        ));
      } else if (t.maxNoRepeatRounds < t.coverageTargetRounds) {
        suggestions.add(ScrambleSuggestion(
          type: ScrambleSuggestionType.capRoundsForFreshPartners,
          message: 'This setup keeps every partnership unique for all '
              '$roundCount rounds. Full coverage (everyone partners with '
              'everyone) isn\'t possible without repeats for this '
              'player/court combination — it would need '
              '${t.coverageTargetRounds} rounds.',
        ));
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

    // Referees are drawn only from players sitting out that round. If fewer
    // players sit out than there are active courts, some courts won't get a
    // dedicated referee (arbitratorId stays null — scored manually).
    if (sittingOut < activeCourts) {
      suggestions.add(ScrambleSuggestion(
        type: ScrambleSuggestionType.noRefereeAvailable,
        message: 'With $playerCount players filling $activeCourts court'
            '${activeCourts == 1 ? '' : 's'} in ${playersPerTeam}v$playersPerTeam, '
            'only $sittingOut player${sittingOut == 1 ? '' : 's'} sit out each round — '
            '${activeCourts - sittingOut} court${activeCourts - sittingOut == 1 ? '' : 's'} '
            'won\'t have a dedicated referee and will need scores entered manually.',
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
        status: player.status,
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
          status: s.status,
          totalPoints: s.totalPoints + aScore,
          pointsAgainst: s.pointsAgainst + bScore,
          gamesPlayed: s.gamesPlayed + 1,
          wins: s.wins + (winner == 'A' ? 1 : 0),
          losses: s.losses + (winner == 'B' ? 1 : 0),
          draws: s.draws + (winner == null ? 1 : 0),
          uniqueTeammateIds: {
            ...s.uniqueTeammateIds,
            ...aIds.where((x) => x != id && !ScrambleGame.isPlaceholder(x))
          },
          uniqueOpponentIds: {
            ...s.uniqueOpponentIds,
            ...bIds.where((x) => !ScrambleGame.isPlaceholder(x))
          },
        );
      }

      for (final id in bIds) {
        final s = statsMap[id];
        if (s == null) continue;
        statsMap[id] = ScramblePlayerStats(
          playerId: s.playerId,
          playerName: s.playerName,
          status: s.status,
          totalPoints: s.totalPoints + bScore,
          pointsAgainst: s.pointsAgainst + aScore,
          gamesPlayed: s.gamesPlayed + 1,
          wins: s.wins + (winner == 'B' ? 1 : 0),
          losses: s.losses + (winner == 'A' ? 1 : 0),
          draws: s.draws + (winner == null ? 1 : 0),
          uniqueTeammateIds: {
            ...s.uniqueTeammateIds,
            ...bIds.where((x) => x != id && !ScrambleGame.isPlaceholder(x))
          },
          uniqueOpponentIds: {
            ...s.uniqueOpponentIds,
            ...aIds.where((x) => !ScrambleGame.isPlaceholder(x))
          },
        );
      }
    }

    final sorted = statsMap.values.toList()
      ..sort((a, b) {
        final byRp = b.rankingPoints.compareTo(a.rankingPoints);
        if (byRp != 0) return byRp;
        return b.pointDifference.compareTo(a.pointDifference);
      });

    for (var i = 0; i < sorted.length; i++) {
      sorted[i].rank = i + 1;
    }

    return sorted;
  }

  // ── Mid-Tournament Rebuild ────────────────────────────────────────────────

  /// Number of rounds, from round 1, that already have at least one started
  /// or completed game — i.e. rounds that [applySettingsChange] cannot remove
  /// and that block a [playersPerTeam] (mode) change. Used by the edit UI to
  /// bound the rounds stepper and to decide whether the mode chip is locked.
  static int lockedRoundCount(ScrambleTournament tournament) =>
      _rebuildFrontier(tournament) - 1;

  /// The first round number whose games are ALL still `scheduled` — i.e. the
  /// earliest point from which the schedule can safely be regenerated without
  /// touching a started/completed game. A round with no games yet (e.g. one
  /// just appended by [applySettingsChange]) counts as fully scheduled too,
  /// since `List.every` on an empty list is vacuously true — so newly added
  /// rounds are always rebuildable.
  ///
  /// Returns `rounds.length + 1` when every round has at least one
  /// non-scheduled game (nothing is safely rebuildable).
  static int _rebuildFrontier(ScrambleTournament tournament) {
    final sortedRounds = tournament.rounds.toList()
      ..sort((a, b) => a.roundNumber.compareTo(b.roundNumber));
    for (final round in sortedRounds) {
      final games = tournament.getGamesForRound(round.id);
      if (games.every((g) => g.status == ScrambleGameStatus.scheduled)) {
        return round.roundNumber;
      }
    }
    return sortedRounds.length + 1;
  }

  /// Regenerates all unstarted rounds after a player roster change (eject,
  /// swap, or late addition). Completed and in-progress games are preserved
  /// verbatim; pair-encounter history is reconstructed from those games so the
  /// mixing algorithm continues to avoid repeated pairings.
  ///
  /// [newPlayers] is the full updated player list (including ejected/swapped-out
  /// entries — inactive players are filtered internally).
  static ScrambleTournament rebuildRemainingRounds(
    ScrambleTournament tournament,
    List<ScramblePlayer> newPlayers,
  ) {
    final activePlayers = newPlayers.where((p) => p.isActive).toList();
    final n = activePlayers.length;
    final playersPerCourt = tournament.playersPerTeam * 2;

    final sortedRounds = tournament.rounds.toList()
      ..sort((a, b) => a.roundNumber.compareTo(b.roundNumber));

    final rebuildFromNumber = _rebuildFrontier(tournament);

    if (rebuildFromNumber > sortedRounds.length) {
      return tournament.copyWith(players: newPlayers);
    }

    final futureRoundIds = sortedRounds
        .where((r) => r.roundNumber >= rebuildFromNumber)
        .map((r) => r.id)
        .toSet();

    final pastGames = tournament.games
        .where((g) => !futureRoundIds.contains(g.roundId))
        .toList();
    final futureRounds = sortedRounds
        .where((r) => r.roundNumber >= rebuildFromNumber)
        .toList();

    final playerIndex = {
      for (var i = 0; i < n; i++) activePlayers[i].id: i
    };

    final baseTeammateCount = List.generate(n, (_) => List.filled(n, 0));
    final baseOpponentCount = List.generate(n, (_) => List.filled(n, 0));
    final baseGamesPlayed = List.filled(n, 0);
    final baseServeCount = List.filled(n, 0);
    final baseArbCount = List.filled(n, 0);

    // Seed matrices from completed/in-progress history, restricted to active players.
    for (final game in pastGames) {
      final sideA = game.sideAPlayerIds
          .where(playerIndex.containsKey)
          .map((id) => activePlayers[playerIndex[id]!])
          .toList();
      final sideB = game.sideBPlayerIds
          .where(playerIndex.containsKey)
          .map((id) => activePlayers[playerIndex[id]!])
          .toList();

      if (sideA.isNotEmpty && sideB.isNotEmpty) {
        _updatePairMatrices(
          sideA: sideA,
          sideB: sideB,
          playerIndex: playerIndex,
          teammateCount: baseTeammateCount,
          opponentCount: baseOpponentCount,
          gamesPlayed: baseGamesPlayed,
        );
      }
      if (game.firstServerId != null &&
          playerIndex.containsKey(game.firstServerId)) {
        baseServeCount[playerIndex[game.firstServerId]!]++;
      }
      if (game.arbitratorId != null &&
          playerIndex.containsKey(game.arbitratorId)) {
        baseArbCount[playerIndex[game.arbitratorId]!]++;
      }
    }

    // Decide, same as buildTournament, whether the remaining schedule is
    // within the safe no-repeat threshold — if so, search across several
    // whole-rebuild attempts for a zero-teammate-repeat result.
    final activeCourts = min(tournament.courtCount, n ~/ playersPerCourt);
    final playersActivePerRound = activeCourts * playersPerCourt;
    final totalRoundCount = sortedRounds.length;
    final fairUnit = (playersActivePerRound > 0 && playersActivePerRound < n)
        ? n ~/ _gcd(n, playersActivePerRound)
        : 1;
    final attemptsAllowed =
        (tournament.playersPerTeam > 1 && playersActivePerRound > 0)
            ? () {
                final t = _repeatThresholds(
                  playerCount: n,
                  playersActive: playersActivePerRound,
                  playersPerTeam: tournament.playersPerTeam,
                  fairUnit: fairUnit,
                );
                return totalRoundCount > 0 &&
                        totalRoundCount <= t.maxNoRepeatRounds
                    ? _zeroRepeatSearchAttempts
                    : 1;
              }()
            : 1;

    (List<ScrambleGame>, int)? best;
    for (var attempt = 0; attempt < attemptsAllowed; attempt++) {
      final result = _rebuildScheduleAttempt(
        futureRounds: futureRounds,
        courtCount: tournament.courtCount,
        playersPerTeam: tournament.playersPerTeam,
        playersPerCourt: playersPerCourt,
        activePlayers: activePlayers,
        playerIndex: playerIndex,
        seedTeammateCount: baseTeammateCount,
        seedOpponentCount: baseOpponentCount,
        seedGamesPlayed: baseGamesPlayed,
        seedServeCount: baseServeCount,
        seedArbCount: baseArbCount,
      );
      if (best == null || result.$2 < best.$2) {
        best = result;
        if (best.$2 == 0) break;
      }
    }

    final (newGames, _) = best!;

    return tournament.copyWith(
      players: newPlayers,
      games: [...pastGames, ...newGames],
    );
  }

  // ── Eject: placeholder seats ────────────────────────────────────────────────

  /// Swaps [playerId] out of [game]'s seats (and, if they were it, the
  /// scheduled first server) for the anonymous [ScrambleGame.placeholderId].
  /// A real person fills the seat on the court; the app just stops tracking
  /// who they were.
  static ScrambleGame _placeholderSeat(ScrambleGame game, String playerId) =>
      game.copyWith(
        sideAPlayerIds: game.sideAPlayerIds
            .map((id) => id == playerId ? ScrambleGame.placeholderId : id)
            .toList(),
        sideBPlayerIds: game.sideBPlayerIds
            .map((id) => id == playerId ? ScrambleGame.placeholderId : id)
            .toList(),
        firstServerId: game.firstServerId == playerId
            ? ScrambleGame.placeholderId
            : null,
      );

  /// Eject option 1: placeholders only the games [rebuildRemainingRounds]
  /// can't reach — those in a round at or before the rebuild frontier (see
  /// [_rebuildFrontier]) that still have [playerId] in a still-`scheduled`
  /// game, typically because another court in that same round has already
  /// started. Every fully-unstarted round from the frontier onward is then
  /// reshuffled exactly as [rebuildRemainingRounds] already does.
  static ScrambleTournament placeholderAndReshuffle(
    ScrambleTournament tournament,
    String playerId,
    List<ScramblePlayer> newPlayers,
  ) {
    final frontier = _rebuildFrontier(tournament);
    final roundNumberById = {
      for (final r in tournament.rounds) r.id: r.roundNumber,
    };
    final patchedGames = tournament.games.map((g) {
      final roundNumber = roundNumberById[g.roundId];
      if (roundNumber == null || roundNumber >= frontier) return g;
      if (g.status != ScrambleGameStatus.scheduled) return g;
      if (!g.sideAPlayerIds.contains(playerId) &&
          !g.sideBPlayerIds.contains(playerId)) {
        return g;
      }
      return _placeholderSeat(g, playerId);
    }).toList();
    return rebuildRemainingRounds(
      tournament.copyWith(games: patchedGames),
      newPlayers,
    );
  }

  /// Eject option 2: placeholders [playerId]'s seat in every remaining
  /// `scheduled` game they're in, current and future alike, without
  /// reshuffling anything else — everyone else's pairings and schedule stay
  /// exactly as originally announced.
  static ScrambleTournament placeholderThroughout(
    ScrambleTournament tournament,
    String playerId,
    List<ScramblePlayer> newPlayers,
  ) {
    final patchedGames = tournament.games.map((g) {
      if (g.status != ScrambleGameStatus.scheduled) return g;
      if (!g.sideAPlayerIds.contains(playerId) &&
          !g.sideBPlayerIds.contains(playerId)) {
        return g;
      }
      return _placeholderSeat(g, playerId);
    }).toList();
    return tournament.copyWith(players: newPlayers, games: patchedGames);
  }

  /// Builds one candidate rebuild attempt for [futureRounds], starting from
  /// the given seed matrices (copied, never mutated) reconstructed from
  /// completed history. Returns the new games plus the resulting
  /// [teammateExcess] (see [_buildScheduleAttempt]).
  static (List<ScrambleGame>, int) _rebuildScheduleAttempt({
    required List<ScrambleRound> futureRounds,
    required int courtCount,
    required int playersPerTeam,
    required int playersPerCourt,
    required List<ScramblePlayer> activePlayers,
    required Map<String, int> playerIndex,
    required List<List<int>> seedTeammateCount,
    required List<List<int>> seedOpponentCount,
    required List<int> seedGamesPlayed,
    required List<int> seedServeCount,
    required List<int> seedArbCount,
  }) {
    final n = activePlayers.length;
    final teammateCount = seedTeammateCount.map(List<int>.from).toList();
    final opponentCount = seedOpponentCount.map(List<int>.from).toList();
    final gamesPlayed = List<int>.from(seedGamesPlayed);
    final serveCount = List<int>.from(seedServeCount);
    final arbCount = List<int>.from(seedArbCount);

    final newGames = <ScrambleGame>[];

    for (final round in futureRounds) {
      final activeCourts = min(courtCount, n ~/ playersPerCourt);
      if (activeCourts == 0) continue;

      final (activeIndices, sittingOutIndices) = _selectActiveIndices(
        n: n,
        gamesPlayed: gamesPlayed,
        activeCourts: activeCourts,
        playersPerCourt: playersPerCourt,
      );

      final roundActivePlayers = activePlayers
          .where((p) => activeIndices.contains(playerIndex[p.id]))
          .toList();
      final sittingOutIds = activePlayers
          .where((p) => sittingOutIndices.contains(playerIndex[p.id]))
          .map((p) => p.id)
          .toList();

      final courtAssignments = _optimiseAssignments(
        activePlayers: roundActivePlayers,
        activeCourts: activeCourts,
        playersPerTeam: playersPerTeam,
        teammateCount: teammateCount,
        opponentCount: opponentCount,
        playerIndex: playerIndex,
        totalPlayers: n,
      );

      final arbQueue = sittingOutIndices.toList()
        ..sort((a, b) => arbCount[a].compareTo(arbCount[b]));

      for (var c = 0; c < courtAssignments.length; c++) {
        final (sideA, sideB) = courtAssignments[c];

        final onCourt = [...sideA, ...sideB];
        final server = onCourt.reduce((a, b) {
          final ca = serveCount[playerIndex[a.id]!];
          final cb = serveCount[playerIndex[b.id]!];
          return ca <= cb ? a : b;
        });
        serveCount[playerIndex[server.id]!]++;

        String? arbitratorId;
        if (arbQueue.isNotEmpty) {
          final arbIdx = arbQueue.removeAt(0);
          arbitratorId = activePlayers[arbIdx].id;
          arbCount[arbIdx]++;
        }

        final sideAIds2 = sideA.map((p) => p.id).toList();
        final sideBIds2 = sideB.map((p) => p.id).toList();
        final (nameA2, nameB2) = ScrambleTeamNames.generate(sideAIds2, sideBIds2);
        newGames.add(ScrambleGame(
          id: ScrambleGame.generateId(),
          roundId: round.id,
          courtNumber: c + 1,
          sideAPlayerIds: sideAIds2,
          sideBPlayerIds: sideBIds2,
          sittingOutPlayerIds: c == 0 ? sittingOutIds : const [],
          firstServerId: server.id,
          arbitratorId: arbitratorId,
          teamNameA: nameA2,
          teamNameB: nameB2,
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

    var teammateExcess = 0;
    for (var i = 0; i < n; i++) {
      for (var j = i + 1; j < n; j++) {
        final c = teammateCount[i][j];
        if (c > 1) teammateExcess += c - 1;
      }
    }

    return (newGames, teammateExcess);
  }

  /// Recomputes `scheduledStartTime` for every round at/after the rebuild
  /// frontier (see [_rebuildFrontier]), chaining forward from either the last
  /// locked round's end (its `actualEndTime` if it has one, otherwise its own
  /// scheduled end) or [ScrambleTournament.startTime] when no round has
  /// started yet. Rounds before the frontier are left completely untouched —
  /// this never moves a round that has already started or completed.
  static ScrambleTournament recomputePendingStartTimes(
    ScrambleTournament tournament,
  ) {
    final sortedRounds = tournament.rounds.toList()
      ..sort((a, b) => a.roundNumber.compareTo(b.roundNumber));
    final frontier = _rebuildFrontier(tournament);

    var next = tournament.startTime;
    final updated = <ScrambleRound>[];
    for (final r in sortedRounds) {
      if (r.roundNumber < frontier) {
        final end = r.actualEndTime != null
            ? r.actualEndTime!.add(r.breakDuration)
            : r.scheduledStartTime.add(r.matchDuration + r.breakDuration);
        if (end.isAfter(next)) next = end;
        updated.add(r);
        continue;
      }
      updated.add(r.copyWith(scheduledStartTime: next));
      next = next.add(r.matchDuration + r.breakDuration);
    }

    return tournament.copyWith(rounds: updated);
  }

  /// Applies a change to round count, court count, and/or mode
  /// ([playersPerTeam]) to an existing tournament. Only the still-`scheduled`
  /// tail (from [_rebuildFrontier] onward) is regenerated — completed and
  /// in-progress rounds/games are preserved untouched, and pairing history is
  /// re-seeded from them so mixing keeps avoiding prior pairings.
  ///
  /// The calling UI is expected to have already confirmed feasibility (via
  /// [validate]) and to disable the mode edit once any game has started, but
  /// both are enforced here too, defensively:
  ///  - [playersPerTeam] is only applied while NO round is locked yet
  ///    (silently ignored otherwise, rather than corrupting an in-progress
  ///    game's side size).
  ///  - [roundCount] is clamped to never drop below the number of already
  ///    locked rounds — you cannot remove a round that's already underway.
  static ScrambleTournament applySettingsChange(
    ScrambleTournament t, {
    int? roundCount,
    int? courtCount,
    int? playersPerTeam,
  }) {
    final frontier = _rebuildFrontier(t);
    final lockedRoundCount = frontier - 1;

    final newPlayersPerTeam = (playersPerTeam != null && lockedRoundCount == 0)
        ? playersPerTeam
        : t.playersPerTeam;
    final newRoundCount = roundCount == null
        ? t.roundCount
        : max(roundCount, lockedRoundCount);

    var rounds = t.rounds.toList()
      ..sort((a, b) => a.roundNumber.compareTo(b.roundNumber));
    var games = t.games.toList();

    if (newRoundCount < rounds.length) {
      // Only ever drops the trailing, still-scheduled tail — guaranteed by
      // the newRoundCount >= lockedRoundCount clamp above.
      final keepIds = rounds.sublist(0, newRoundCount).map((r) => r.id).toSet();
      rounds = rounds.where((r) => keepIds.contains(r.id)).toList();
      games = games.where((g) => keepIds.contains(g.roundId)).toList();
    } else if (newRoundCount > rounds.length) {
      // Append empty rounds; rebuildRemainingRounds (below) populates them —
      // a round with no games is vacuously "fully scheduled" (see
      // _rebuildFrontier), so it's always included in the regenerated tail.
      final lastNumber = rounds.isEmpty ? 0 : rounds.last.roundNumber;
      final toAdd = newRoundCount - rounds.length; // cache — rounds grows below
      for (var i = 1; i <= toAdd; i++) {
        rounds.add(ScrambleRound(
          id: ScrambleRound.generateId(),
          roundNumber: lastNumber + i,
          scheduledStartTime: t.startTime, // placeholder, recomputed below
          matchDuration: t.matchDuration,
          breakDuration: t.breakDuration,
        ));
      }
    }

    var updated = t.copyWith(
      rounds: rounds,
      games: games,
      courtCount: courtCount ?? t.courtCount,
      playersPerTeam: newPlayersPerTeam,
    );

    updated = recomputePendingStartTimes(updated);

    final roundDuration = updated.matchDuration + updated.breakDuration;
    updated =
        updated.copyWith(totalAvailableTime: roundDuration * updated.roundCount);

    return rebuildRemainingRounds(updated, updated.players);
  }

  /// Moves an unstarted round to a new position in the schedule, renumbering
  /// every round to its new play order and recomputing pending start times.
  ///
  /// [oldIndex]/[newIndex] index into the rounds sorted ascending by
  /// `roundNumber`, following [ReorderableListView.onReorder] conventions.
  /// Only the still-unstarted tail can move — a locked round never moves, and
  /// an unstarted round dropped above the locked block clamps to the first
  /// unstarted slot instead of jumping ahead of played rounds.
  ///
  /// Games travel with their round (they reference `roundId`, not
  /// `roundNumber`), so pairings are preserved and nothing is regenerated —
  /// resequencing can't create a new teammate repeat, since teammate counts
  /// are symmetric across the whole schedule.
  static ScrambleTournament reorderRounds(
    ScrambleTournament t, {
    required int oldIndex,
    required int newIndex,
  }) {
    final rounds = t.rounds.toList()
      ..sort((a, b) => a.roundNumber.compareTo(b.roundNumber));
    final locked = lockedRoundCount(t);

    if (oldIndex < locked || oldIndex >= rounds.length) return t;

    // Standard ReorderableListView index adjustment, then keep the drop inside
    // the unstarted tail.
    var target = newIndex > oldIndex ? newIndex - 1 : newIndex;
    target = target.clamp(locked, rounds.length - 1);
    if (target == oldIndex) return t;

    final moved = rounds.removeAt(oldIndex);
    rounds.insert(target, moved);

    final renumbered = <ScrambleRound>[
      for (var i = 0; i < rounds.length; i++)
        rounds[i].copyWith(roundNumber: i + 1),
    ];

    return recomputePendingStartTimes(t.copyWith(rounds: renumbered));
  }

  // ── Schedule Reflow ───────────────────────────────────────────────────────

  /// After marking a game completed, stamps [round]'s `actualEndTime` once
  /// every game in it is done, and reflows all pending round times (via
  /// [reflowAllPending]) if the round finished ahead of its scheduled end.
  /// A round that finished late is left alone — an overdue round already
  /// shows a warning, and the admin adjusts the schedule manually rather
  /// than have it silently compress the rest of the day.
  ///
  /// No-ops if [round]'s games aren't all completed yet.
  static ScrambleTournament reflowIfRoundComplete(
    ScrambleTournament tournament,
    ScrambleRound round,
  ) {
    final roundGames = tournament.getGamesForRound(round.id);
    if (!roundGames.every((g) => g.isCompleted)) return tournament;

    final now = DateTime.now();
    final actualEnd = roundGames
        .map((g) => g.actualEndTime ?? now)
        .reduce((a, b) => a.isAfter(b) ? a : b);

    // Use the round from `tournament` (not the caller's [round]) to preserve
    // any scheduledStartTime already adjusted by a previous reflow.
    final liveRound = tournament.getRound(round.id) ?? round;
    final updated =
        tournament.updateRound(liveRound.copyWith(actualEndTime: actualEnd));

    if (actualEnd.isBefore(liveRound.scheduledMatchEndTime)) {
      return reflowAllPending(updated);
    }
    return updated;
  }

  /// Shifts all pending round start times globally based on the latest actual
  /// end time across ALL completed rounds (not just the one that just finished).
  ///
  /// This handles out-of-order completions: if Round 4 finishes while Round 3
  /// is still pending, Round 3 gets rescheduled after Round 4's end, and any
  /// subsequent pending rounds are chained from there.
  ///
  /// Pending rounds already scheduled later than the chain are not moved back.
  static ScrambleTournament reflowAllPending(ScrambleTournament tournament) {
    final sortedRounds = tournament.rounds.toList()
      ..sort((a, b) => a.roundNumber.compareTo(b.roundNumber));

    // Latest actual finish (including break) across all completed rounds.
    DateTime? baseline;
    for (final r in sortedRounds) {
      if (r.actualEndTime == null) continue;
      final withBreak = r.actualEndTime!.add(r.breakDuration);
      if (baseline == null || withBreak.isAfter(baseline)) baseline = withBreak;
    }
    if (baseline == null) return tournament;

    final updated = List<ScrambleRound>.from(sortedRounds);
    var next = baseline;
    var changed = false;

    for (var i = 0; i < updated.length; i++) {
      final r = updated[i];
      if (r.actualEndTime != null) {
        // Completed anchor: ensure chain never falls behind this round's actual break end.
        final actualBreakEnd = r.actualEndTime!.add(r.breakDuration);
        if (actualBreakEnd.isAfter(next)) next = actualBreakEnd;
        continue;
      }

      if (next != r.scheduledStartTime) {
        updated[i] = r.copyWith(scheduledStartTime: next);
        changed = true;
      }
      next = updated[i].scheduledStartTime.add(r.matchDuration + r.breakDuration);
    }

    return changed ? tournament.copyWith(rounds: updated) : tournament;
  }

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
