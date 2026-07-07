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
}
