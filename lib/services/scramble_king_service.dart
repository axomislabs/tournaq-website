import 'dart:math';
import '../models/scramble_king_tournament.dart';
import '../models/scramble_tournament.dart' show ScrambleSuggestion, ScrambleSuggestionType;
import 'scramble_service.dart';
import '../utils/team_name_generator.dart';

/// Core business logic for Scramble King tournaments.
///
/// Mirrors [ScrambleService]'s shape closely: [buildTournament] pre-generates
/// every round upfront (court/team formation + real scheduled times) exactly
/// like [ScrambleService.buildTournament] does for Social Scramble, so the
/// same Schedule Preview / Timeline UI patterns apply unchanged.
///
/// Responsibilities:
///   - Per-round court/team formation (fairness-optimised, reusing the same
///     shuffle-and-greedy technique as ScrambleService's mixing engine)
///   - Odd-player "floater" selection and temp-partner resolution
///   - Live queue fairness ranking for automated assignment modes
///   - Round/court result computation and manual-score override handling
///   - Cross-round individual player stats
///   - Schedule reflow after a round finishes early/late ([reflowAllPending])
class ScrambleKingService {
  ScrambleKingService._();

  /// Team size is fixed at 2 (doubles only) — not configurable for this mode.
  static const teamSize = 2;

  /// A non-floater court needs at least 2 full teams (4 players) for the
  /// win-stays queue mechanic to function at all.
  static const minNonFloaterCourtSize = 4;

  /// A floater court needs at least 2 full teams *plus* the floater (5
  /// players) — with only 1 team + floater there is no second team to
  /// challenge, so the "court" mechanic is degenerate.
  static const minFloaterCourtSize = 5;

  static final _rng = Random();
  static const _mixingAttempts = 200;
  static const _pairingAttempts = 200;
  static const _exhaustivePlayerLimit = 32;

  // ── Player generation ────────────────────────────────────────────────────
  // Delegates to ScrambleService's shared name generator rather than
  // duplicating the pool.

  static ScrambleKingPlayer randomPlayer() {
    final p = ScrambleService.randomPlayer();
    return ScrambleKingPlayer(
      id: ScrambleKingPlayer.generateId(),
      name: p.name,
      source: ScrambleKingPlayerSource.random,
    );
  }

  /// Generates [count] random players with distinct names. Pass the names of
  /// players already in the roster as [existing] so the new batch avoids them.
  static List<ScrambleKingPlayer> generateRandomPlayers(
    int count, {
    Set<String>? existing,
  }) =>
      ScrambleService.generateRandomPlayers(count, existing: existing)
          .map((p) => ScrambleKingPlayer(
                id: ScrambleKingPlayer.generateId(),
                name: p.name,
                source: ScrambleKingPlayerSource.random,
              ))
          .toList();

  // ── Tournament builder (all rounds generated upfront) ───────────────────

  static ScrambleKingTournament buildTournament({
    required String name,
    required int roundCount,
    required Duration matchDuration,
    required Duration breakDuration,
    required int courtCount,
    required int strikePoints,
    required ScrambleKingAssignmentMode assignmentMode,
    required ScrambleKingOddPlayerMode oddPlayerMode,
    required List<ScrambleKingPlayer> players,
    required DateTime startTime,
    bool paceAlertsEnabled = false,
  }) {
    final activePlayers = players.where((p) => p.isActive).toList();
    final matrices = _Matrices(activePlayers);
    final roundDuration = matchDuration + breakDuration;

    final rounds = <ScrambleKingRound>[];
    for (var r = 0; r < roundCount; r++) {
      final courts = _buildCourtsForRound(
        activePlayers: activePlayers,
        courtCount: courtCount,
        matrices: matrices,
      );
      rounds.add(ScrambleKingRound(
        id: ScrambleKingRound.generateId(),
        roundNumber: r + 1,
        scheduledStartTime: startTime.add(roundDuration * r),
        matchDuration: matchDuration,
        breakDuration: breakDuration,
        courts: courts,
      ));
    }

    return ScrambleKingTournament(
      id: ScrambleKingTournament.generateId(),
      name: name,
      courtCount: courtCount,
      roundCount: roundCount,
      matchDuration: matchDuration,
      breakDuration: breakDuration,
      strikePoints: strikePoints,
      assignmentMode: assignmentMode,
      oddPlayerMode: oddPlayerMode,
      paceAlertsEnabled: paceAlertsEnabled,
      startTime: startTime,
      players: players,
      rounds: rounds,
      stints: const [],
      createdAt: DateTime.now(),
    );
  }

  /// Regenerates all unstarted rounds after a player roster change (eject,
  /// swap, or late addition) — mirrors [ScrambleService.rebuildRemainingRounds]
  /// exactly. Rounds that already have stints recorded, or whose courts have
  /// an `actualStartTime`, are preserved verbatim; only later rounds' team/
  /// court formations are regenerated (their scheduled times are kept as-is).
  static ScrambleKingTournament rebuildRemainingRounds(
    ScrambleKingTournament tournament,
    List<ScrambleKingPlayer> newPlayers,
  ) {
    final sortedRounds = tournament.rounds.toList()
      ..sort((a, b) => a.roundNumber.compareTo(b.roundNumber));

    var rebuildFromIndex = sortedRounds.length;
    for (var i = 0; i < sortedRounds.length; i++) {
      final round = sortedRounds[i];
      final untouched = tournament.getStintsForRound(round.id).isEmpty &&
          round.courts.every((c) => c.actualStartTime == null);
      if (untouched) {
        rebuildFromIndex = i;
        break;
      }
    }

    if (rebuildFromIndex >= sortedRounds.length) {
      return tournament.copyWith(players: newPlayers);
    }

    final pastRounds = sortedRounds.sublist(0, rebuildFromIndex);
    final futureRounds = sortedRounds.sublist(rebuildFromIndex);
    final activePlayers = newPlayers.where((p) => p.isActive).toList();

    final matrices = _Matrices(activePlayers);
    for (final round in pastRounds) {
      matrices.applyCourts(round.courts);
    }

    final rebuiltFuture = futureRounds.map((round) {
      final courts = _buildCourtsForRound(
        activePlayers: activePlayers,
        courtCount: tournament.courtCount,
        matrices: matrices,
      );
      return round.copyWith(courts: courts);
    }).toList();

    return tournament.copyWith(
      players: newPlayers,
      rounds: [...pastRounds, ...rebuiltFuture],
    );
  }

  /// Appends new rounds or drops trailing untouched rounds so the tournament
  /// has exactly [newCount] rounds — mid-tournament editing of the round
  /// count from the overview. Never drops a round that already has stints
  /// or a started court; [newCount] is silently clamped up to at least that
  /// many. Appended rounds reuse the tournament's configured match/break
  /// duration, are scheduled back-to-back after the last existing round,
  /// and are seeded from every existing round's fairness matrices (so
  /// pairing continuity carries over exactly like [rebuildRemainingRounds]).
  static ScrambleKingTournament setRoundCount(
    ScrambleKingTournament tournament,
    int newCount,
  ) {
    final sortedRounds = tournament.rounds.toList()
      ..sort((a, b) => a.roundNumber.compareTo(b.roundNumber));

    var touchedCount = sortedRounds.length;
    for (var i = 0; i < sortedRounds.length; i++) {
      final round = sortedRounds[i];
      final untouched = tournament.getStintsForRound(round.id).isEmpty &&
          round.courts.every((c) => c.actualStartTime == null);
      if (untouched) {
        touchedCount = i;
        break;
      }
    }
    final clampedCount = max(newCount, touchedCount);

    if (clampedCount <= sortedRounds.length) {
      return tournament.copyWith(
        roundCount: clampedCount,
        rounds: sortedRounds.sublist(0, clampedCount),
      );
    }

    final activePlayers = tournament.players.where((p) => p.isActive).toList();
    final matrices = _Matrices(activePlayers);
    for (final round in sortedRounds) {
      matrices.applyCourts(round.courts);
    }

    var cursor =
        sortedRounds.isNotEmpty ? sortedRounds.last.scheduledBreakEndTime : tournament.startTime;

    final newRounds = <ScrambleKingRound>[];
    for (var i = sortedRounds.length; i < clampedCount; i++) {
      final courts = _buildCourtsForRound(
        activePlayers: activePlayers,
        courtCount: tournament.courtCount,
        matrices: matrices,
      );
      newRounds.add(ScrambleKingRound(
        id: ScrambleKingRound.generateId(),
        roundNumber: i + 1,
        scheduledStartTime: cursor,
        matchDuration: tournament.matchDuration,
        breakDuration: tournament.breakDuration,
        courts: courts,
      ));
      cursor = cursor.add(tournament.matchDuration + tournament.breakDuration);
    }

    return tournament.copyWith(
      roundCount: clampedCount,
      rounds: [...sortedRounds, ...newRounds],
    );
  }

  // ── Schedule reflow ───────────────────────────────────────────────────────
  // Copies of ScrambleService's two reflow functions, adapted to
  // ScrambleKingRound's field names.

  static ScrambleKingTournament reflowAllPending(ScrambleKingTournament tournament) {
    final sortedRounds = tournament.rounds.toList()
      ..sort((a, b) => a.roundNumber.compareTo(b.roundNumber));

    DateTime? baseline;
    for (final r in sortedRounds) {
      if (r.actualEndTime == null) continue;
      final withBreak = r.actualEndTime!.add(r.breakDuration);
      if (baseline == null || withBreak.isAfter(baseline)) baseline = withBreak;
    }
    if (baseline == null) return tournament;

    final updated = List<ScrambleKingRound>.from(sortedRounds);
    var next = baseline;
    var changed = false;

    for (var i = 0; i < updated.length; i++) {
      final r = updated[i];
      if (r.actualEndTime != null) {
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

  static ScrambleKingTournament reflowSchedule(
    ScrambleKingTournament tournament, {
    required int fromRoundNumber,
    required Duration delta,
  }) {
    final updatedRounds = tournament.rounds.map((r) {
      if (r.roundNumber < fromRoundNumber) return r;
      return r.copyWith(scheduledStartTime: r.scheduledStartTime.add(delta));
    }).toList();
    return tournament.copyWith(rounds: updatedRounds);
  }

  // ── Per-round court/team formation ───────────────────────────────────────

  static List<ScrambleKingCourtFormation> _buildCourtsForRound({
    required List<ScrambleKingPlayer> activePlayers,
    required int courtCount,
    required _Matrices matrices,
  }) {
    final sizes = decideCourtSizes(activePlayers.length, courtCount);
    if (sizes.isEmpty) return const [];

    final courtsPlayers = _assignCourts(
      activePlayers: activePlayers,
      sizes: sizes,
      matrices: matrices,
    );

    final courts = <ScrambleKingCourtFormation>[];
    for (var i = 0; i < courtsPlayers.length; i++) {
      final courtPlayers = courtsPlayers[i];
      final (:floater, :rest) = _extractFloater(courtPlayers, matrices);
      final rawSlots = _pairTeamsGreedy(
        players: rest,
        matrices: matrices,
      )..shuffle(_rng);
      // Fun, per-court-unique team names (reuses Social Scramble's word
      // pool) — the odd player gets one too, since they're a normal scoring
      // team like everyone else.
      final nameGroups = [
        ...rawSlots.map((s) => s.playerIds),
        if (floater != null) [floater.id],
      ];
      final names = TeamNameGenerator.uniqueForTeams(nameGroups);
      final teamSlots = [
        for (var t = 0; t < rawSlots.length; t++)
          ScrambleKingTeamSlot(
            slotId: rawSlots[t].slotId,
            playerIds: rawSlots[t].playerIds,
            teamName: names[t],
          ),
      ];
      final floaterSlot = floater != null
          ? ScrambleKingFloaterSlot(
              slotId: ScrambleKingFloaterSlot.generateId(),
              playerId: floater.id,
              teamName: names.last,
            )
          : null;
      courts.add(ScrambleKingCourtFormation(
        courtNumber: i + 1,
        teamSlots: teamSlots,
        floaterSlot: floaterSlot,
      ));
    }

    matrices.applyCourts(courts);
    return courts;
  }

  /// The initial on/off-court queue order for a freshly-formed court: fixed
  /// teams first (teamSlots[0] starts on court), the floater seeded last so
  /// they don't have to resolve a temp partner on the very first stint.
  static List<String> initialQueueOrder(ScrambleKingCourtFormation formation) => [
        ...formation.teamSlots.map((s) => s.slotId),
        if (formation.floaterSlot != null) formation.floaterSlot!.slotId,
      ];

  /// Decides how many players each active court gets this round, minimising
  /// the number of floater courts (0 if the player count is even, else
  /// exactly 1), while enforcing [minNonFloaterCourtSize]/[minFloaterCourtSize].
  static List<int> decideCourtSizes(int n, int maxCourts) {
    if (n < minNonFloaterCourtSize) return [];
    final upperBound = min(maxCourts, n ~/ minNonFloaterCourtSize);
    for (var courts = max(upperBound, 1); courts >= 1; courts--) {
      final sizes = _tryDistribute(n, courts);
      if (sizes != null) return sizes;
    }
    return [n];
  }

  static List<int>? _tryDistribute(int n, int courts) {
    if (courts <= 0) return null;
    final base = n ~/ courts;
    final remainder = n % courts;
    final sizes = List.filled(courts, base);
    for (var i = 0; i < remainder; i++) {
      sizes[i]++;
    }

    final oddIdx = [
      for (var i = 0; i < sizes.length; i++)
        if (sizes[i].isOdd) i
    ];
    while (oddIdx.length >= 2) {
      final a = oddIdx.removeLast();
      final b = oddIdx.removeLast();
      sizes[a] += 1;
      sizes[b] -= 1;
    }

    for (final size in sizes) {
      final isFloaterCourt = size.isOdd;
      final minSize = isFloaterCourt ? minFloaterCourtSize : minNonFloaterCourtSize;
      if (size < minSize) return null;
    }
    return sizes;
  }

  // ── Court assignment (which players share a court) ──────────────────────

  static List<List<ScrambleKingPlayer>> _assignCourts({
    required List<ScrambleKingPlayer> activePlayers,
    required List<int> sizes,
    required _Matrices matrices,
  }) {
    final attempts =
        activePlayers.length <= _exhaustivePlayerLimit ? _mixingAttempts : 30;
    List<List<ScrambleKingPlayer>>? best;
    var bestScore = double.infinity;

    for (var attempt = 0; attempt < attempts; attempt++) {
      final shuffled = List<ScrambleKingPlayer>.from(activePlayers)..shuffle(_rng);
      final courts = _formCourtsForRound(shuffled: shuffled, sizes: sizes, matrices: matrices);

      var score = 0.0;
      for (final court in courts) {
        for (var i = 0; i < court.length; i++) {
          for (var j = i + 1; j < court.length; j++) {
            final a = matrices.playerIndex[court[i].id]!;
            final b = matrices.playerIndex[court[j].id]!;
            final c = matrices.teammateCount[a][b] + matrices.courtmateCount[a][b];
            score += c * c.toDouble();
          }
        }
      }

      if (score < bestScore) {
        bestScore = score;
        best = courts;
        if (bestScore == 0) break;
      }
    }

    return best!;
  }

  static List<List<ScrambleKingPlayer>> _formCourtsForRound({
    required List<ScrambleKingPlayer> shuffled,
    required List<int> sizes,
    required _Matrices matrices,
  }) {
    final remaining = List<ScrambleKingPlayer>.from(shuffled);
    final courts = <List<ScrambleKingPlayer>>[];

    for (final size in sizes) {
      final court = <ScrambleKingPlayer>[remaining.removeAt(0)];

      while (court.length < size) {
        ScrambleKingPlayer? bestCandidate;
        var bestExposure = -1;

        for (final candidate in remaining) {
          final b = matrices.playerIndex[candidate.id]!;
          var exposure = 0;
          for (final placed in court) {
            final a = matrices.playerIndex[placed.id]!;
            exposure += matrices.teammateCount[a][b] + matrices.courtmateCount[a][b];
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

  // ── Floater extraction + team pairing within a court ─────────────────────

  static ({ScrambleKingPlayer? floater, List<ScrambleKingPlayer> rest})
      _extractFloater(List<ScrambleKingPlayer> courtPlayers, _Matrices matrices) {
    if (courtPlayers.length.isEven) {
      return (floater: null, rest: courtPlayers);
    }
    final shuffled = List<ScrambleKingPlayer>.from(courtPlayers)..shuffle(_rng);
    shuffled.sort((a, b) => matrices.floaterCount[matrices.playerIndex[a.id]!]
        .compareTo(matrices.floaterCount[matrices.playerIndex[b.id]!]));
    final floater = shuffled.first;
    final rest = courtPlayers.where((p) => p.id != floater.id).toList();
    return (floater: floater, rest: rest);
  }

  static List<ScrambleKingTeamSlot> _pairTeamsGreedy({
    required List<ScrambleKingPlayer> players,
    required _Matrices matrices,
  }) {
    final attempts = players.length <= _exhaustivePlayerLimit ? _pairingAttempts : 30;
    List<ScrambleKingTeamSlot>? best;
    var bestScore = double.infinity;

    for (var attempt = 0; attempt < attempts; attempt++) {
      final remaining = List<ScrambleKingPlayer>.from(players)..shuffle(_rng);
      final slots = <ScrambleKingTeamSlot>[];
      var score = 0.0;

      while (remaining.isNotEmpty) {
        final p1 = remaining.removeAt(0);
        ScrambleKingPlayer? bestPartner;
        var bestCount = -1;
        for (final candidate in remaining) {
          final c = matrices
              .teammateCount[matrices.playerIndex[p1.id]!][matrices.playerIndex[candidate.id]!];
          if (bestPartner == null || c < bestCount) {
            bestPartner = candidate;
            bestCount = c;
          }
        }
        remaining.remove(bestPartner);
        score += bestCount * bestCount.toDouble();
        slots.add(ScrambleKingTeamSlot(
          slotId: ScrambleKingTeamSlot.generateId(),
          playerIds: [p1.id, bestPartner!.id],
        ));
      }

      if (score < bestScore) {
        bestScore = score;
        best = slots;
        if (bestScore == 0) break;
      }
    }

    return best!;
  }

  // ── Live queue fairness ranking (automated modes) ────────────────────────

  /// Ranks [queueSlotIds] for who should enter the court next: fewest recent
  /// matchups against [onCourtSlotId] first, ties broken by longest wait
  /// since the slot last played. Same comparator shape as King of the
  /// Court's `_computeSuggestions`, but simpler since Scramble King's teams
  /// are fixed for the round — no combination generation is needed, just a
  /// sort over the already-enumerated queued slots.
  static List<String> rankQueue({
    required List<String> queueSlotIds,
    required String? onCourtSlotId,
    required List<ScrambleKingStint> courtStints,
  }) {
    final adjacency = _turnAdjacencyCounts(courtStints);
    final ranked = List<String>.from(queueSlotIds);
    ranked.sort((a, b) {
      final pa = _pairScore(a, onCourtSlotId, adjacency);
      final pb = _pairScore(b, onCourtSlotId, adjacency);
      if (pa != pb) return pa.compareTo(pb);
      final wa = _waitScore(a, courtStints);
      final wb = _waitScore(b, courtStints);
      return wb.compareTo(wa);
    });
    return ranked;
  }

  static Map<String, int> _turnAdjacencyCounts(List<ScrambleKingStint> courtStints) {
    final counts = <String, int>{};
    for (var i = 0; i < courtStints.length - 1; i++) {
      final a = courtStints[i].turnSlotId;
      final b = courtStints[i + 1].turnSlotId;
      final key = ([a, b]..sort()).join('|');
      counts[key] = (counts[key] ?? 0) + 1;
    }
    return counts;
  }

  static int _pairScore(
    String queuedSlotId,
    String? onCourtSlotId,
    Map<String, int> adjacency,
  ) {
    if (onCourtSlotId == null) return 0;
    final key = ([queuedSlotId, onCourtSlotId]..sort()).join('|');
    return adjacency[key] ?? 0;
  }

  static int _waitScore(String slotId, List<ScrambleKingStint> courtStints) {
    for (var i = courtStints.length - 1; i >= 0; i--) {
      if (courtStints[i].turnSlotId == slotId) {
        return courtStints.length - 1 - i;
      }
    }
    return courtStints.length; // never played yet this round — max wait
  }

  // ── Odd-player floater temp-partner resolution ───────────────────────────

  /// Jumper mode: the eligible candidate with the fewest stints played this
  /// round so far (fairness), ties broken by shuffle order.
  static ({String playerId, String teamSlotId})? pickJumperPartner({
    required List<ScrambleKingTeamSlot> otherQueuedTeams,
    required List<ScrambleKingStint> courtStints,
  }) {
    if (otherQueuedTeams.isEmpty) return null;
    final playedCount = <String, int>{};
    for (final s in courtStints) {
      for (final pid in s.playerIds) {
        playedCount[pid] = (playedCount[pid] ?? 0) + 1;
      }
    }
    final candidates = <({String playerId, String teamSlotId})>[
      for (final team in otherQueuedTeams)
        for (final pid in team.playerIds) (playerId: pid, teamSlotId: team.slotId),
    ]..shuffle(_rng);

    candidates.sort((a, b) =>
        (playedCount[a.playerId] ?? 0).compareTo(playedCount[b.playerId] ?? 0));
    return candidates.first;
  }

  // ── Round/court results ──────────────────────────────────────────────────

  /// Derives the ranked scorecard for one (round, court): each team's
  /// auto-computed points (summed from stints crediting that team) with any
  /// manual override applied, ranked highest-points first. The odd player's
  /// team (if any) is included exactly like any other team.
  static ScrambleKingCourtRoundResult computeCourtRoundResult(
    ScrambleKingTournament tournament,
    String roundId,
    int courtNumber,
  ) {
    final round = tournament.getRound(roundId)!;
    final formation = round.getCourt(courtNumber)!;
    final stints = tournament.getStintsForCourt(roundId, courtNumber);

    final slotIds = [
      ...formation.teamSlots.map((s) => s.slotId),
      if (formation.floaterSlot != null) formation.floaterSlot!.slotId,
    ];
    final slotPlayerIds = {
      for (final s in formation.teamSlots) s.slotId: s.playerIds,
      if (formation.floaterSlot != null)
        formation.floaterSlot!.slotId: [formation.floaterSlot!.playerId],
    };

    final autoPoints = <String, int>{for (final id in slotIds) id: 0};
    final autoGamesWon = <String, int>{for (final id in slotIds) id: 0};
    final gamesPlayed = <String, int>{for (final id in slotIds) id: 0};
    for (final stint in stints) {
      autoPoints[stint.creditSlotId] =
          (autoPoints[stint.creditSlotId] ?? 0) + stint.points;
      autoGamesWon[stint.creditSlotId] =
          (autoGamesWon[stint.creditSlotId] ?? 0) + stint.gamesWon;
      gamesPlayed[stint.creditSlotId] = (gamesPlayed[stint.creditSlotId] ?? 0) + 1;
    }

    final results = slotIds
        .map((id) => ScrambleKingTeamResult(
              slotId: id,
              playerIds: slotPlayerIds[id]!,
              autoPoints: autoPoints[id] ?? 0,
              manualPoints: formation.manualTeamPoints[id],
              autoGamesWon: autoGamesWon[id] ?? 0,
              manualGamesWon: formation.manualGamesWon[id],
              gamesPlayed: gamesPlayed[id] ?? 0,
            ))
        .toList()
      ..sort((a, b) {
        final g = b.gamesWon.compareTo(a.gamesWon);
        if (g != 0) return g;
        return b.points.compareTo(a.points);
      });

    for (var i = 0; i < results.length; i++) {
      results[i].rank = i + 1;
    }

    return ScrambleKingCourtRoundResult(
      courtNumber: courtNumber,
      teamResults: results,
    );
  }

  // ── Stats ─────────────────────────────────────────────────────────────────

  /// Cross-round individual ranking: every player is credited their team's
  /// round total for every round they had a team — including the odd
  /// player, whose team result row carries just their own id.
  static List<ScrambleKingPlayerStats> computeStats(ScrambleKingTournament t) {
    final statsMap = <String, ScrambleKingPlayerStats>{};
    for (final player in t.players) {
      statsMap[player.id] = ScrambleKingPlayerStats(
        playerId: player.id,
        playerName: player.name,
        status: player.status,
      );
    }

    for (final round in t.rounds) {
      for (final court in round.courts) {
        final result = computeCourtRoundResult(t, round.id, court.courtNumber);
        for (final teamResult in result.teamResults) {
          for (final pid in teamResult.playerIds) {
            final s = statsMap[pid];
            if (s == null) continue;
            statsMap[pid] = ScrambleKingPlayerStats(
              playerId: s.playerId,
              playerName: s.playerName,
              status: s.status,
              totalPoints: s.totalPoints + teamResult.points,
              totalGamesWon: s.totalGamesWon + teamResult.gamesWon,
              roundsPlayed: s.roundsPlayed + 1,
            );
          }
        }
      }
    }

    final sorted = statsMap.values.toList()
      ..sort((a, b) {
        final g = b.totalGamesWon.compareTo(a.totalGamesWon);
        if (g != 0) return g;
        return b.totalPoints.compareTo(a.totalPoints);
      });
    for (var i = 0; i < sorted.length; i++) {
      sorted[i].rank = i + 1;
    }
    return sorted;
  }

  // ── Validation & Suggestions ──────────────────────────────────────────────
  // Returns the *shared* ScrambleSuggestion type (from scramble_tournament.dart)
  // so the setup page can render warnings with the existing ScrambleSuggestionCard
  // widget, unmodified.

  static List<ScrambleSuggestion> validate({
    required int playerCount,
    required int courtCount,
    required int roundCount,
    required Duration matchDuration,
  }) {
    final suggestions = <ScrambleSuggestion>[];

    if (roundCount <= 0) {
      suggestions.add(const ScrambleSuggestion(
        type: ScrambleSuggestionType.tooFewRounds,
        message: 'At least 1 round is needed.',
        isBlocking: true,
      ));
    }
    if (matchDuration.inSeconds <= 0) {
      suggestions.add(const ScrambleSuggestion(
        type: ScrambleSuggestionType.adjustMatchDuration,
        message: 'Round duration must be greater than zero.',
        isBlocking: true,
      ));
    }
    if (playerCount < minNonFloaterCourtSize) {
      suggestions.add(ScrambleSuggestion(
        type: ScrambleSuggestionType.adjustPlayerCount,
        message: 'At least $minNonFloaterCourtSize players are needed for '
            'one court.',
        isBlocking: true,
      ));
      return suggestions;
    }

    final sizes = decideCourtSizes(playerCount, courtCount);
    if (sizes.isEmpty) {
      suggestions.add(const ScrambleSuggestion(
        type: ScrambleSuggestionType.adjustPlayerCount,
        message: "This player/court combination can't form a valid court. "
            'Add more players or reduce courts.',
        isBlocking: true,
      ));
      return suggestions;
    }

    if (sizes.length < courtCount) {
      suggestions.add(ScrambleSuggestion(
        type: ScrambleSuggestionType.adjustCourtCount,
        message: 'Only ${sizes.length} of $courtCount courts can be filled '
            'with $playerCount players. Reduce courts or add players.',
      ));
    }

    final hasMinimalFloaterCourt =
        sizes.any((s) => s.isOdd && s == minFloaterCourtSize);
    if (hasMinimalFloaterCourt) {
      suggestions.add(const ScrambleSuggestion(
        type: ScrambleSuggestionType.largeGroup,
        message: 'With this player count, the floater will always partner '
            'with the same team on the rounds they float. Add players for '
            'more variety.',
      ));
    }

    return suggestions;
  }
}

class _Matrices {
  final List<List<int>> teammateCount;
  final List<List<int>> courtmateCount;
  final List<int> floaterCount;
  final Map<String, int> playerIndex;

  _Matrices(List<ScrambleKingPlayer> activePlayers)
      : playerIndex = {
          for (var i = 0; i < activePlayers.length; i++) activePlayers[i].id: i
        },
        teammateCount =
            List.generate(activePlayers.length, (_) => List.filled(activePlayers.length, 0)),
        courtmateCount =
            List.generate(activePlayers.length, (_) => List.filled(activePlayers.length, 0)),
        floaterCount = List.filled(activePlayers.length, 0);

  void applyCourts(List<ScrambleKingCourtFormation> courts) {
    for (final court in courts) {
      final courtPlayerIds = <String>[
        for (final slot in court.teamSlots) ...slot.playerIds,
        if (court.floaterSlot != null) court.floaterSlot!.playerId,
      ];

      if (court.floaterSlot != null) {
        final fi = playerIndex[court.floaterSlot!.playerId];
        if (fi != null) floaterCount[fi]++;
      }

      for (final slot in court.teamSlots) {
        if (slot.playerIds.length != 2) continue;
        final a = playerIndex[slot.playerIds[0]];
        final b = playerIndex[slot.playerIds[1]];
        if (a == null || b == null) continue;
        teammateCount[a][b]++;
        teammateCount[b][a]++;
      }

      for (var i = 0; i < courtPlayerIds.length; i++) {
        for (var j = i + 1; j < courtPlayerIds.length; j++) {
          final a = playerIndex[courtPlayerIds[i]];
          final b = playerIndex[courtPlayerIds[j]];
          if (a == null || b == null) continue;
          final areTeammates = court.teamSlots.any((s) =>
              s.playerIds.contains(courtPlayerIds[i]) &&
              s.playerIds.contains(courtPlayerIds[j]));
          if (areTeammates) continue;
          courtmateCount[a][b]++;
          courtmateCount[b][a]++;
        }
      }
    }
  }
}
