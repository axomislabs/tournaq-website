import 'package:flutter_test/flutter_test.dart';
import 'package:tournaq/models/scramble_tournament.dart';
import 'package:tournaq/services/scramble_service.dart';

List<ScramblePlayer> _players(int n) => List.generate(
      n,
      (i) => ScramblePlayer(
        id: 'p$i',
        name: 'Player ${i + 1}',
        source: ScramblePlayerSource.random,
      ),
    );

ScrambleTournament _build({
  required int n,
  required int courtCount,
  int playersPerTeam = 2,
  int rounds = 50,
}) {
  return ScrambleService.buildTournament(
    name: 'Test',
    roundCount: rounds,
    matchDuration: const Duration(minutes: 1),
    breakDuration: Duration.zero,
    courtCount: courtCount,
    playersPerTeam: playersPerTeam,
    players: _players(n),
    startTime: DateTime(2026, 1, 1),
  );
}

/// Every player's realized teammate set and opponent set, derived directly
/// from the generated games (not from computeStats, which only counts
/// completed games).
(Map<String, Set<String>> teammates, Map<String, Set<String>> opponents)
    _realizedPairings(ScrambleTournament t) {
  final teammates = {for (final p in t.players) p.id: <String>{}};
  final opponents = {for (final p in t.players) p.id: <String>{}};

  for (final g in t.games) {
    for (final id in g.sideAPlayerIds) {
      teammates[id]!.addAll(g.sideAPlayerIds.where((x) => x != id));
      opponents[id]!.addAll(g.sideBPlayerIds);
    }
    for (final id in g.sideBPlayerIds) {
      teammates[id]!.addAll(g.sideBPlayerIds.where((x) => x != id));
      opponents[id]!.addAll(g.sideAPlayerIds);
    }
  }
  return (teammates, opponents);
}

/// Teammate encounter counts per player pair (with multiplicity, unlike
/// [_realizedPairings]'s sets) — needed to detect actual repeats, not just
/// coverage gaps.
Map<String, Map<String, int>> _teammateCounts(ScrambleTournament t) {
  final counts = <String, Map<String, int>>{
    for (final p in t.players) p.id: {},
  };
  for (final g in t.games) {
    for (final ids in [g.sideAPlayerIds, g.sideBPlayerIds]) {
      for (final id in ids) {
        for (final other in ids) {
          if (other == id) continue;
          counts[id]![other] = (counts[id]![other] ?? 0) + 1;
        }
      }
    }
  }
  return counts;
}

bool _hasAnyTeammateRepeat(ScrambleTournament t) =>
    _teammateCounts(t).values.any((m) => m.values.any((c) => c > 1));

void main() {
  group('ScrambleService.buildTournament pairing coverage', () {
    test('8 players, 1 court: every player eventually meets every other '
        'player as teammate or opponent', () {
      final t = _build(n: 8, courtCount: 1);
      final (teammates, opponents) = _realizedPairings(t);
      final allIds = t.players.map((p) => p.id).toSet();

      for (final p in t.players) {
        final met = {...teammates[p.id]!, ...opponents[p.id]!};
        final missing = allIds.difference({p.id}).difference(met);
        expect(
          missing,
          isEmpty,
          reason: '${p.name} never met: '
              '${missing.map((id) => t.getPlayer(id)?.name).join(", ")}',
        );
      }
    });

    test('7 players, 1 court: every player eventually partners with and '
        'opposes every other player', () {
      final t = _build(n: 7, courtCount: 1);
      final (teammates, opponents) = _realizedPairings(t);
      final allIds = t.players.map((p) => p.id).toSet();

      for (final p in t.players) {
        final missingTeammates =
            allIds.difference({p.id}).difference(teammates[p.id]!);
        final missingOpponents =
            allIds.difference({p.id}).difference(opponents[p.id]!);
        expect(
          missingTeammates,
          isEmpty,
          reason: '${p.name} never partnered with: '
              '${missingTeammates.map((id) => t.getPlayer(id)?.name).join(", ")}',
        );
        expect(
          missingOpponents,
          isEmpty,
          reason: '${p.name} never opposed: '
              '${missingOpponents.map((id) => t.getPlayer(id)?.name).join(", ")}',
        );
      }
    });

    test('12 players, 2 courts: every player eventually meets every other '
        'player', () {
      final t = _build(n: 12, courtCount: 2, rounds: 60);
      final (teammates, opponents) = _realizedPairings(t);
      final allIds = t.players.map((p) => p.id).toSet();

      for (final p in t.players) {
        final met = {...teammates[p.id]!, ...opponents[p.id]!};
        final missing = allIds.difference({p.id}).difference(met);
        expect(missing, isEmpty, reason: '${p.name} never met: $missing');
      }
    });

    test('sit-out partition is not a fixed alternation between two halves',
        () {
      final t = _build(n: 8, courtCount: 1, rounds: 12);
      final sortedRounds = t.rounds.toList()
        ..sort((a, b) => a.roundNumber.compareTo(b.roundNumber));

      final partitions = <String>[];
      for (final r in sortedRounds) {
        final games = t.getGamesForRound(r.id);
        final sittingOut = games.first.sittingOutPlayerIds.toList()..sort();
        partitions.add(sittingOut.join(','));
      }

      final distinctPartitions = partitions.toSet();
      expect(
        distinctPartitions.length,
        greaterThan(2),
        reason: 'Expected more than 2 distinct sitting-out groups across '
            '${partitions.length} rounds; got: $distinctPartitions',
      );
    });

    test('serve and arbitrator counts stay balanced', () {
      final t = _build(n: 8, courtCount: 1, rounds: 40);
      final serveCounts = {for (final p in t.players) p.id: 0};
      final arbCounts = {for (final p in t.players) p.id: 0};

      for (final g in t.games) {
        if (g.firstServerId != null) {
          serveCounts[g.firstServerId!] = serveCounts[g.firstServerId!]! + 1;
        }
        if (g.arbitratorId != null) {
          arbCounts[g.arbitratorId!] = arbCounts[g.arbitratorId!]! + 1;
        }
      }

      final serveSpread =
          serveCounts.values.reduce((a, b) => a > b ? a : b) -
              serveCounts.values.reduce((a, b) => a < b ? a : b);
      final arbSpread = arbCounts.values.reduce((a, b) => a > b ? a : b) -
          arbCounts.values.reduce((a, b) => a < b ? a : b);

      expect(serveSpread, lessThanOrEqualTo(2));
      expect(arbSpread, lessThanOrEqualTo(2));
    });
  });

  group('ScrambleService.validate repeat-avoidance math', () {
    List<ScrambleSuggestion> validateFor({
      required int playerCount,
      required int rounds,
      int courtCount = 1,
      int playersPerTeam = 2,
    }) {
      return ScrambleService.validate(
        roundCount: rounds,
        matchDuration: const Duration(minutes: 1),
        breakDuration: Duration.zero,
        courtCount: courtCount,
        playerCount: playerCount,
        playersPerTeam: playersPerTeam,
      );
    }

    test('7 players, 1 court, 50 rounds: warns that only 7 rounds keep '
        'every partnership unique (regression test for the reported '
        'back-to-back-repeat bug)', () {
      final suggestions = validateFor(playerCount: 7, rounds: 50);
      expect(
        suggestions.any((s) =>
            s.type == ScrambleSuggestionType.capRoundsForFreshPartners &&
            s.message.contains('Up to 7 rounds') &&
            s.message.contains('14 rounds')),
        isTrue,
        reason: 'Expected a cap warning mentioning 7 (safe cap) and 14 '
            '(coverage minimum); got: '
            '${suggestions.map((s) => s.message).join(" | ")}',
      );
    });

    test('7 players, 1 court, 7 rounds: only the informational coverage-'
        'shortfall note appears, no actionable cap warning', () {
      final suggestions = validateFor(playerCount: 7, rounds: 7);
      final capSuggestions = suggestions
          .where((s) => s.type == ScrambleSuggestionType.capRoundsForFreshPartners);
      expect(capSuggestions, isNotEmpty);
      expect(capSuggestions.every((s) => s.actionLabel == null), isTrue,
          reason: 'Expected only the informational (non-actionable) note '
              'once already within the safe cap; got: '
              '${capSuggestions.map((s) => s.message).join(" | ")}');
    });

    test('8 players, 1 court, 50 rounds: warns with the backed-off safe cap '
        '(8 rounds), not the unreachable raw ceiling (14)', () {
      final suggestions = validateFor(playerCount: 8, rounds: 50);
      expect(
        suggestions.any((s) =>
            s.type == ScrambleSuggestionType.capRoundsForFreshPartners &&
            s.message.contains('Up to 8 rounds')),
        isTrue,
        reason: 'Expected a cap warning mentioning 8 rounds; got: '
            '${suggestions.map((s) => s.message).join(" | ")}',
      );
    });

    test('suggestedRoundCount matches the stated cap exactly', () {
      final suggestions = validateFor(playerCount: 7, rounds: 50);
      final cap = suggestions.firstWhere(
          (s) => s.type == ScrambleSuggestionType.capRoundsForFreshPartners);
      expect(cap.suggestedRoundCount, 7);
    });

    test('capRoundsForFreshPartners suggestions are never blocking', () {
      for (final (n, courts) in [(7, 1), (8, 1), (12, 2), (20, 1)]) {
        final suggestions = validateFor(playerCount: n, rounds: 50, courtCount: courts);
        for (final s in suggestions.where(
            (s) => s.type == ScrambleSuggestionType.capRoundsForFreshPartners)) {
          expect(s.isBlocking, isFalse,
              reason: 'capRoundsForFreshPartners must stay advisory (n=$n)');
        }
      }
    });
  });

  group('ScrambleService.buildTournament zero-repeat guarantee at the '
      'recommended cap', () {
    test('7 players, 1 court, 7 rounds: no teammate ever repeats, across '
        'many independent builds — the direct regression guard for the '
        'reported bug', () {
      for (var i = 0; i < 30; i++) {
        final t = _build(n: 7, courtCount: 1, rounds: 7);
        expect(_hasAnyTeammateRepeat(t), isFalse,
            reason: 'Trial $i had a repeated teammate pair');
      }
    });

    test('12 players, 2 courts, 9 rounds (non-zero-slack multi-court): no '
        'teammate ever repeats, across many independent builds', () {
      for (var i = 0; i < 30; i++) {
        final t = _build(n: 12, courtCount: 2, rounds: 9);
        expect(_hasAnyTeammateRepeat(t), isFalse,
            reason: 'Trial $i had a repeated teammate pair');
      }
    });

    test('8 players, 1 court, 8 rounds (tight/zero-slack case): no repeats '
        'in the large majority of builds — not asserted as a hard 100% '
        'guarantee, since the safe cap is itself a reliability estimate, '
        'not a mathematical proof, for this hardest case', () {
      const trials = 20;
      var cleanRuns = 0;
      for (var i = 0; i < trials; i++) {
        final t = _build(n: 8, courtCount: 1, rounds: 8);
        if (!_hasAnyTeammateRepeat(t)) cleanRuns++;
      }
      expect(
        cleanRuns,
        greaterThanOrEqualTo((trials * 0.9).floor()),
        reason: 'Expected at least 90% of $trials runs with zero teammate '
            'repeats at the recommended safe cap; got $cleanRuns',
      );
    });
  });

  group('ScrambleService.rebuildRemainingRounds pairing coverage', () {
    test('coverage still reached after a mid-tournament rebuild', () {
      var t = _build(n: 8, courtCount: 1, rounds: 50);

      final firstRound =
          (t.rounds.toList()..sort((a, b) => a.roundNumber.compareTo(b.roundNumber)))
              .first;
      for (final g in t.getGamesForRound(firstRound.id)) {
        t = t.updateGame(g.copyWith(
          status: ScrambleGameStatus.completed,
          sideAScore: 21,
          sideBScore: 15,
        ));
      }

      final rebuilt = ScrambleService.rebuildRemainingRounds(t, t.players);
      final (teammates, opponents) = _realizedPairings(rebuilt);
      final allIds = rebuilt.players.map((p) => p.id).toSet();

      for (final p in rebuilt.players) {
        final met = {...teammates[p.id]!, ...opponents[p.id]!};
        final missing = allIds.difference({p.id}).difference(met);
        expect(missing, isEmpty, reason: '${p.name} never met: $missing');
      }
    });

    test('no teammate repeats after a rebuild when remaining rounds are '
        'within the safe cap', () {
      // 7 players, 1 court: safe cap is 7 rounds total.
      var t = _build(n: 7, courtCount: 1, rounds: 7);

      final firstRound =
          (t.rounds.toList()..sort((a, b) => a.roundNumber.compareTo(b.roundNumber)))
              .first;
      for (final g in t.getGamesForRound(firstRound.id)) {
        t = t.updateGame(g.copyWith(
          status: ScrambleGameStatus.completed,
          sideAScore: 21,
          sideBScore: 15,
        ));
      }

      final rebuilt = ScrambleService.rebuildRemainingRounds(t, t.players);
      expect(_hasAnyTeammateRepeat(rebuilt), isFalse);
    });
  });

  group('ScrambleService.validate referee availability', () {
    List<ScrambleSuggestion> validateFor({
      required int playerCount,
      required int courtCount,
      int playersPerTeam = 2,
    }) {
      return ScrambleService.validate(
        roundCount: 5,
        matchDuration: const Duration(minutes: 1),
        breakDuration: Duration.zero,
        courtCount: courtCount,
        playerCount: playerCount,
        playersPerTeam: playersPerTeam,
      );
    }

    test('warns when every player is needed on court, leaving no one to '
        'referee (8 players, 2 courts, 2v2)', () {
      final suggestions =
          validateFor(playerCount: 8, courtCount: 2, playersPerTeam: 2);
      expect(
        suggestions
            .any((s) => s.type == ScrambleSuggestionType.noRefereeAvailable),
        isTrue,
      );
    });

    test('does not warn when enough players sit out each round to referee '
        '(10 players, 2 courts, 2v2)', () {
      final suggestions =
          validateFor(playerCount: 10, courtCount: 2, playersPerTeam: 2);
      expect(
        suggestions
            .any((s) => s.type == ScrambleSuggestionType.noRefereeAvailable),
        isFalse,
      );
    });

    test('noRefereeAvailable is never blocking', () {
      final suggestions =
          validateFor(playerCount: 8, courtCount: 2, playersPerTeam: 2);
      for (final s in suggestions
          .where((s) => s.type == ScrambleSuggestionType.noRefereeAvailable)) {
        expect(s.isBlocking, isFalse);
      }
    });
  });

  group('ScrambleService.lockedRoundCount', () {
    test('is 0 for a fresh tournament where nothing has started', () {
      final t = _build(n: 8, courtCount: 1, rounds: 5);
      expect(ScrambleService.lockedRoundCount(t), 0);
    });

    test('counts the completed round once round 1 is finished', () {
      var t = _build(n: 8, courtCount: 1, rounds: 5);
      final round1 = (t.rounds.toList()
            ..sort((a, b) => a.roundNumber.compareTo(b.roundNumber)))
          .first;
      for (final g in t.getGamesForRound(round1.id)) {
        t = t.updateGame(g.copyWith(
          status: ScrambleGameStatus.completed,
          sideAScore: 21,
          sideBScore: 15,
        ));
      }
      expect(ScrambleService.lockedRoundCount(t), 1);
    });
  });

  group('ScrambleService.recomputePendingStartTimes', () {
    test('is a no-op when nothing has started (already chained from '
        'startTime)', () {
      final t = _build(n: 8, courtCount: 1, rounds: 3);
      final recomputed = ScrambleService.recomputePendingStartTimes(t);
      final sorted = t.rounds.toList()
        ..sort((a, b) => a.roundNumber.compareTo(b.roundNumber));
      final recomputedSorted = recomputed.rounds.toList()
        ..sort((a, b) => a.roundNumber.compareTo(b.roundNumber));
      for (var i = 0; i < sorted.length; i++) {
        expect(recomputedSorted[i].scheduledStartTime,
            sorted[i].scheduledStartTime);
      }
    });

    test('chains pending rounds from the last locked round\'s actual end '
        'time', () {
      var t = _build(n: 8, courtCount: 1, rounds: 3);
      final sorted = t.rounds.toList()
        ..sort((a, b) => a.roundNumber.compareTo(b.roundNumber));
      final round1 = sorted[0];

      for (final g in t.getGamesForRound(round1.id)) {
        t = t.updateGame(g.copyWith(
          status: ScrambleGameStatus.completed,
          sideAScore: 21,
          sideBScore: 15,
        ));
      }
      // Round 1 ran 4 minutes over its scheduled end.
      final actualEnd = round1.scheduledStartTime
          .add(round1.matchDuration)
          .add(const Duration(minutes: 4));
      t = t.updateRound(round1.copyWith(actualEndTime: actualEnd));

      final recomputed = ScrambleService.recomputePendingStartTimes(t);
      final round2 =
          recomputed.rounds.firstWhere((r) => r.roundNumber == 2);
      final round3 =
          recomputed.rounds.firstWhere((r) => r.roundNumber == 3);

      expect(round2.scheduledStartTime, actualEnd.add(round1.breakDuration));
      expect(round3.scheduledStartTime,
          round2.scheduledStartTime.add(round2.matchDuration + round2.breakDuration));
    });
  });

  group('ScrambleService.applySettingsChange', () {
    test('reducing round count preserves completed rounds/games and drops '
        'the trailing scheduled tail', () {
      var t = _build(n: 8, courtCount: 1, rounds: 10);
      final round1 = (t.rounds.toList()
            ..sort((a, b) => a.roundNumber.compareTo(b.roundNumber)))
          .first;
      for (final g in t.getGamesForRound(round1.id)) {
        t = t.updateGame(g.copyWith(
          status: ScrambleGameStatus.completed,
          sideAScore: 21,
          sideBScore: 15,
        ));
      }

      final updated =
          ScrambleService.applySettingsChange(t, roundCount: 5);

      expect(updated.roundCount, 5);
      final keptRound1 =
          updated.rounds.firstWhere((r) => r.roundNumber == 1);
      expect(keptRound1.id, round1.id);
      final round1Games = updated.getGamesForRound(keptRound1.id);
      expect(round1Games, isNotEmpty);
      expect(round1Games.every((g) => g.isCompleted), isTrue);
      expect(round1Games.every((g) => g.sideAScore == 21), isTrue);
      expect(updated.rounds.any((r) => r.roundNumber > 5), isFalse);
    });

    test('increasing round count appends and populates the new rounds', () {
      final t = _build(n: 8, courtCount: 1, rounds: 5);

      final updated =
          ScrambleService.applySettingsChange(t, roundCount: 8);

      expect(updated.roundCount, 8);
      final roundNumbers =
          updated.rounds.map((r) => r.roundNumber).toList()..sort();
      expect(roundNumbers, [1, 2, 3, 4, 5, 6, 7, 8]);
      for (final r in updated.rounds) {
        expect(updated.getGamesForRound(r.id), isNotEmpty,
            reason: 'round ${r.roundNumber} should have been populated');
      }
    });

    test('changing court count only regenerates future games — the locked '
        'round is preserved verbatim', () {
      var t = _build(n: 12, courtCount: 1, rounds: 6);
      final round1 = (t.rounds.toList()
            ..sort((a, b) => a.roundNumber.compareTo(b.roundNumber)))
          .first;
      final originalRound1GameIds =
          t.getGamesForRound(round1.id).map((g) => g.id).toSet();
      for (final g in t.getGamesForRound(round1.id)) {
        t = t.updateGame(g.copyWith(
          status: ScrambleGameStatus.completed,
          sideAScore: 21,
          sideBScore: 15,
        ));
      }

      final updated =
          ScrambleService.applySettingsChange(t, courtCount: 2);

      expect(updated.courtCount, 2);
      // Locked round untouched: same game ids, still 1 court's worth.
      final round1GamesAfter = updated.getGamesForRound(round1.id);
      expect(round1GamesAfter.map((g) => g.id).toSet(),
          originalRound1GameIds);
      expect(round1GamesAfter.length, 1);
      // A future round regenerates at the new court count (12 players,
      // 2v2, 2 courts → 2 games).
      final round2 =
          updated.rounds.firstWhere((r) => r.roundNumber == 2);
      expect(updated.getGamesForRound(round2.id).length, 2);
    });

    test('changing mode (playersPerTeam) is ignored once a game has '
        'started', () {
      var t = _build(n: 8, courtCount: 1, rounds: 5);
      final round1 = (t.rounds.toList()
            ..sort((a, b) => a.roundNumber.compareTo(b.roundNumber)))
          .first;
      for (final g in t.getGamesForRound(round1.id)) {
        t = t.updateGame(g.copyWith(
          status: ScrambleGameStatus.completed,
          sideAScore: 21,
          sideBScore: 15,
        ));
      }

      final updated =
          ScrambleService.applySettingsChange(t, playersPerTeam: 3);

      expect(updated.playersPerTeam, 2,
          reason: 'mode must not change once round 1 has started');
    });

    test('changing mode (playersPerTeam) is applied when nothing has '
        'started yet', () {
      final t = _build(n: 12, courtCount: 1, rounds: 5);

      final updated =
          ScrambleService.applySettingsChange(t, playersPerTeam: 3);

      expect(updated.playersPerTeam, 3);
      expect(updated.games, isNotEmpty);
      expect(updated.games.first.sideAPlayerIds.length, 3);
      expect(updated.games.first.sideBPlayerIds.length, 3);
    });
  });

  group('ScrambleService.reorderRounds', () {
    List<ScrambleRound> sortedRounds(ScrambleTournament t) =>
        t.rounds.toList()
          ..sort((a, b) => a.roundNumber.compareTo(b.roundNumber));

    ScrambleTournament completeRound(ScrambleTournament t, String roundId) {
      for (final g in t.getGamesForRound(roundId)) {
        t = t.updateGame(g.copyWith(
          status: ScrambleGameStatus.completed,
          sideAScore: 21,
          sideBScore: 15,
        ));
      }
      return t;
    }

    test('moving an unstarted round earlier renumbers to contiguous play '
        'order, and its games travel with it', () {
      final t = _build(n: 8, courtCount: 1, rounds: 6);
      final rounds = sortedRounds(t);
      final movedRound = rounds[4]; // round 5
      final movedGameIds =
          t.getGamesForRound(movedRound.id).map((g) => g.id).toSet();

      // Move round 5 (index 4) to the top (index 0).
      final r = ScrambleService.reorderRounds(t, oldIndex: 4, newIndex: 0);

      // Round numbers are contiguous 1..N.
      final nums = r.rounds.map((x) => x.roundNumber).toList()..sort();
      expect(nums, [1, 2, 3, 4, 5, 6]);

      // The moved round is now round 1 and keeps its identity + games.
      final now = r.rounds.firstWhere((x) => x.id == movedRound.id);
      expect(now.roundNumber, 1);
      expect(r.getGamesForRound(movedRound.id).map((g) => g.id).toSet(),
          movedGameIds);

      // No games gained/lost; every roundId still exists.
      expect(r.games.length, t.games.length);
      expect(r.games.map((g) => g.roundId).toSet(),
          t.games.map((g) => g.roundId).toSet());
    });

    test('scheduled start times stay strictly increasing by round number', () {
      final t = _build(n: 8, courtCount: 1, rounds: 6);
      final r = ScrambleService.reorderRounds(t, oldIndex: 5, newIndex: 1);
      final rounds = sortedRounds(r);
      for (var i = 1; i < rounds.length; i++) {
        expect(rounds[i].scheduledStartTime
            .isAfter(rounds[i - 1].scheduledStartTime), isTrue);
      }
    });

    test('a locked round never moves; an unstarted round dropped above it '
        'clamps to the first unstarted slot', () {
      var t = _build(n: 8, courtCount: 1, rounds: 6);
      final round1Id = sortedRounds(t).first.id;
      t = completeRound(t, round1Id); // round 1 locked

      // Try to drag round 5 (index 4) to the very top (index 0, in the
      // locked region).
      final r = ScrambleService.reorderRounds(t, oldIndex: 4, newIndex: 0);

      // Locked round 1 is untouched and still first.
      final stillRound1 = r.rounds.firstWhere((x) => x.id == round1Id);
      expect(stillRound1.roundNumber, 1);
      // The dragged round landed just after it — as round 2.
      final movedRoundId = sortedRounds(t)[4].id;
      final moved = r.rounds.firstWhere((x) => x.id == movedRoundId);
      expect(moved.roundNumber, 2);
    });

    test('dragging a locked round is a no-op', () {
      var t = _build(n: 8, courtCount: 1, rounds: 6);
      t = completeRound(t, sortedRounds(t).first.id);

      final before = sortedRounds(t).map((r) => r.id).toList();
      final r = ScrambleService.reorderRounds(t, oldIndex: 0, newIndex: 3);
      final after = sortedRounds(r).map((x) => x.id).toList();

      expect(after, before);
    });

    test('reordering does not introduce a teammate repeat beyond what '
        'already existed', () {
      // 7 players, 1 court, within the safe cap → no repeats to begin with.
      final t = _build(n: 7, courtCount: 1, rounds: 7);
      expect(_hasAnyTeammateRepeat(t), isFalse);
      final r = ScrambleService.reorderRounds(t, oldIndex: 6, newIndex: 0);
      expect(_hasAnyTeammateRepeat(r), isFalse);
    });
  });
}
