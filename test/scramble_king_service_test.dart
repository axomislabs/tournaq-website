import 'package:flutter_test/flutter_test.dart';
import 'package:tournaq/models/player_status.dart';
import 'package:tournaq/models/scramble_king_tournament.dart';
import 'package:tournaq/services/scramble_king_service.dart';

List<ScrambleKingPlayer> _players(int n) => List.generate(
      n,
      (i) => ScrambleKingPlayer(
        id: 'p$i',
        name: 'Player ${i + 1}',
        source: ScrambleKingPlayerSource.random,
      ),
    );

ScrambleKingTournament _build({
  required int n,
  required int courtCount,
  int rounds = 6,
}) {
  return ScrambleKingService.buildTournament(
    name: 'Test',
    roundCount: rounds,
    matchDuration: const Duration(minutes: 10),
    breakDuration: const Duration(minutes: 1),
    courtCount: courtCount,
    strikePoints: 0,
    assignmentMode: ScrambleKingAssignmentMode.manual,
    oddPlayerMode: ScrambleKingOddPlayerMode.placeholder,
    players: _players(n),
    startTime: DateTime(2026, 1, 1, 9, 0),
  );
}

void main() {
  group('decideCourtSizes', () {
    test('even player count never produces a floater', () {
      for (final n in [8, 12, 16, 20, 24, 32]) {
        for (final courts in [1, 2, 3, 4]) {
          final sizes = ScrambleKingService.decideCourtSizes(n, courts);
          if (sizes.isEmpty) continue;
          expect(sizes.every((s) => s.isEven), isTrue,
              reason: 'n=$n courts=$courts sizes=$sizes');
          expect(sizes.fold<int>(0, (a, b) => a + b), n);
        }
      }
    });

    test('odd player count produces exactly one floater court', () {
      for (final n in [9, 13, 17, 21, 25, 33]) {
        for (final courts in [1, 2, 3, 4]) {
          final sizes = ScrambleKingService.decideCourtSizes(n, courts);
          if (sizes.isEmpty) continue;
          final oddCount = sizes.where((s) => s.isOdd).length;
          expect(oddCount, 1, reason: 'n=$n courts=$courts sizes=$sizes');
          expect(sizes.fold<int>(0, (a, b) => a + b), n);
        }
      }
    });

    test('respects minimum court sizes', () {
      for (final n in [3, 4, 5, 6, 7, 8, 9, 17]) {
        for (final courts in [1, 2, 3, 8]) {
          final sizes = ScrambleKingService.decideCourtSizes(n, courts);
          for (final s in sizes) {
            final min = s.isOdd
                ? ScrambleKingService.minFloaterCourtSize
                : ScrambleKingService.minNonFloaterCourtSize;
            expect(s >= min, isTrue, reason: 'n=$n courts=$courts sizes=$sizes');
          }
        }
      }
    });

    test('too few players yields no courts', () {
      expect(ScrambleKingService.decideCourtSizes(3, 4), isEmpty);
      expect(ScrambleKingService.decideCourtSizes(0, 4), isEmpty);
    });
  });

  group('buildTournament', () {
    test('pre-generates every round upfront with correctly spaced start times', () {
      final t = _build(n: 16, courtCount: 2, rounds: 6);
      expect(t.rounds.length, 6);
      for (var i = 0; i < t.rounds.length; i++) {
        expect(t.rounds[i].roundNumber, i + 1);
        final expectedStart =
            t.startTime.add((t.matchDuration + t.breakDuration) * i);
        expect(t.rounds[i].scheduledStartTime, expectedStart);
      }
    });

    test('every active player is assigned to exactly one court/slot per round', () {
      final t = _build(n: 17, courtCount: 2, rounds: 1);
      final round = t.rounds.single;
      final assigned = <String>{};
      for (final court in round.courts) {
        for (final slot in court.teamSlots) {
          assigned.addAll(slot.playerIds);
        }
        if (court.floaterSlot != null) assigned.add(court.floaterSlot!.playerId);
      }
      expect(assigned.length, 17);
      expect(assigned, t.players.map((p) => p.id).toSet());
    });

    test('team slots always have exactly 2 players', () {
      final t = _build(n: 21, courtCount: 2, rounds: 1);
      for (final court in t.rounds.single.courts) {
        for (final slot in court.teamSlots) {
          expect(slot.playerIds.length, 2);
        }
      }
    });

    test('exactly one court has a floater for an odd total', () {
      final t = _build(n: 19, courtCount: 2, rounds: 1);
      final floaterCourts = t.rounds.single.courts.where((c) => c.floaterSlot != null);
      expect(floaterCourts.length, 1);
    });

    test('every team slot gets a non-null, per-court-unique team name', () {
      final t = _build(n: 24, courtCount: 3, rounds: 4);
      for (final round in t.rounds) {
        for (final court in round.courts) {
          final names = court.teamSlots.map((s) => s.teamName).toList();
          expect(names.every((n) => n != null && n.isNotEmpty), isTrue);
          expect(names.toSet().length, names.length,
              reason: 'names not unique within court: $names');
        }
      }
    });

    test('no repeated fixed pairing within a small round count', () {
      final t = _build(n: 16, courtCount: 2, rounds: 3);
      final seenPairs = <String>{};
      var repeats = 0;
      for (final round in t.rounds) {
        for (final court in round.courts) {
          for (final slot in court.teamSlots) {
            final key = (slot.playerIds..sort()).join('-');
            if (!seenPairs.add(key)) repeats++;
          }
        }
      }
      expect(repeats, 0);
    });

    test('floater duty spreads across players over many rounds', () {
      final t = _build(n: 17, courtCount: 2, rounds: 30);
      final floaterCounts = <String, int>{for (final p in t.players) p.id: 0};
      for (final round in t.rounds) {
        for (final court in round.courts) {
          if (court.floaterSlot != null) {
            floaterCounts[court.floaterSlot!.playerId] =
                (floaterCounts[court.floaterSlot!.playerId] ?? 0) + 1;
          }
        }
      }
      final counts = floaterCounts.values.toList();
      final maxCount = counts.reduce((a, b) => a > b ? a : b);
      final minCount = counts.reduce((a, b) => a < b ? a : b);
      expect(maxCount - minCount, lessThanOrEqualTo(3));
    });
  });

  group('rebuildRemainingRounds', () {
    test('preserves rounds that already have stints or started courts', () {
      final t = _build(n: 16, courtCount: 2, rounds: 4);
      final round0 = t.rounds[0];
      final startedCourt = round0.courts.first.copyWith(actualStartTime: DateTime(2026, 1, 1, 9, 0));
      final touchedRound = round0.updateCourt(startedCourt);
      final withStart = t.updateRound(touchedRound);

      // Eject one player, replace with a new one.
      final ejected = withStart.players.first.copyWith(status: PlayerStatus.ejected);
      final newPlayer = ScrambleKingPlayer(
        id: 'new1',
        name: 'New Player',
        source: ScrambleKingPlayerSource.created,
      );
      final newPlayers = [
        ...withStart.players.map((p) => p.id == ejected.id ? ejected : p),
        newPlayer,
      ];

      final rebuilt = ScrambleKingService.rebuildRemainingRounds(withStart, newPlayers);

      // Round 0 (touched) is untouched.
      expect(rebuilt.rounds[0].courts, touchedRound.courts);
      // Later rounds no longer contain the ejected player.
      for (final round in rebuilt.rounds.skip(1)) {
        for (final court in round.courts) {
          final ids = [
            for (final s in court.teamSlots) ...s.playerIds,
            if (court.floaterSlot != null) court.floaterSlot!.playerId,
          ];
          expect(ids.contains(ejected.id), isFalse);
        }
      }
    });

    test('does nothing when every round is already touched', () {
      final t = _build(n: 16, courtCount: 2, rounds: 2);
      var updated = t;
      for (final round in t.rounds) {
        final startedCourt =
            round.courts.first.copyWith(actualStartTime: DateTime(2026, 1, 1, 9, 0));
        updated = updated.updateRound(round.updateCourt(startedCourt));
      }
      final rebuilt = ScrambleKingService.rebuildRemainingRounds(updated, updated.players);
      expect(rebuilt.rounds, updated.rounds);
    });
  });

  group('setRoundCount', () {
    test('appends new rounds scheduled back-to-back after the last round', () {
      final t = _build(n: 16, courtCount: 2, rounds: 2);
      final updated = ScrambleKingService.setRoundCount(t, 4);

      expect(updated.roundCount, 4);
      expect(updated.rounds.length, 4);
      expect(updated.rounds[0], t.rounds[0]);
      expect(updated.rounds[1], t.rounds[1]);
      for (var i = 2; i < 4; i++) {
        expect(updated.rounds[i].roundNumber, i + 1);
        final expectedStart = updated.rounds[i - 1].scheduledBreakEndTime;
        expect(updated.rounds[i].scheduledStartTime, expectedStart);
      }
    });

    test('appended rounds cover every active player exactly once', () {
      final t = _build(n: 17, courtCount: 2, rounds: 1);
      final updated = ScrambleKingService.setRoundCount(t, 2);
      final appended = updated.rounds.last;
      final assigned = <String>{};
      for (final court in appended.courts) {
        for (final slot in court.teamSlots) {
          assigned.addAll(slot.playerIds);
        }
        if (court.floaterSlot != null) assigned.add(court.floaterSlot!.playerId);
      }
      expect(assigned, t.players.map((p) => p.id).toSet());
    });

    test('truncates trailing untouched rounds', () {
      final t = _build(n: 16, courtCount: 2, rounds: 4);
      final updated = ScrambleKingService.setRoundCount(t, 2);

      expect(updated.roundCount, 2);
      expect(updated.rounds.length, 2);
      expect(updated.rounds, [t.rounds[0], t.rounds[1]]);
    });

    test('never drops a round that already has a started court', () {
      final t = _build(n: 16, courtCount: 2, rounds: 4);
      // Rounds play out in order: 0 and 1 already started, 2 just started.
      var withStart = t;
      for (var i = 0; i < 3; i++) {
        final startedCourt = withStart.rounds[i].courts.first
            .copyWith(actualStartTime: DateTime(2026, 1, 1, 9, i * 20));
        withStart = withStart.updateRound(withStart.rounds[i].updateCourt(startedCourt));
      }

      // Ask for fewer rounds than the started one's index would allow.
      final updated = ScrambleKingService.setRoundCount(withStart, 1);

      expect(updated.roundCount, 3);
      expect(updated.rounds.length, 3);
      expect(updated.rounds[2].courts, withStart.rounds[2].courts);
    });

    test('never drops a round that already has stints', () {
      final t = _build(n: 16, courtCount: 2, rounds: 3);
      // Round 0 already started; round 1 has a recorded stint.
      final round0 = t.rounds[0];
      final startedCourt0 =
          round0.courts.first.copyWith(actualStartTime: DateTime(2026, 1, 1, 9, 0));
      final withStart = t.updateRound(round0.updateCourt(startedCourt0));

      final round1 = withStart.rounds[1];
      final court = round1.courts.first;
      final stint = ScrambleKingStint(
        id: 'st1',
        roundId: round1.id,
        courtNumber: court.courtNumber,
        turnSlotId: court.teamSlots.first.slotId,
        creditSlotId: court.teamSlots.first.slotId,
        playerIds: court.teamSlots.first.playerIds,
        points: 5,
        startTime: DateTime(2026, 1, 1, 9, 10),
      );
      final withStint = withStart.addStint(stint);

      final updated = ScrambleKingService.setRoundCount(withStint, 1);

      expect(updated.roundCount, 2);
      expect(updated.rounds.length, 2);
    });

    test('appended rounds are seeded from existing fairness matrices (no immediate repeat pairing)',
        () {
      final t = _build(n: 8, courtCount: 1, rounds: 1);
      final updated = ScrambleKingService.setRoundCount(t, 2);

      final firstPairs = t.rounds.single.courts
          .expand((c) => c.teamSlots)
          .map((s) => (s.playerIds..sort()).join('-'))
          .toSet();
      final secondPairs = updated.rounds.last.courts
          .expand((c) => c.teamSlots)
          .map((s) => (s.playerIds..sort()).join('-'))
          .toSet();
      expect(firstPairs.intersection(secondPairs), isEmpty);
    });
  });

  group('rankQueue', () {
    test('prefers the slot that has not faced the on-court slot recently', () {
      final stints = [
        ScrambleKingStint(
          id: 's1',
          roundId: 'r1',
          courtNumber: 1,
          turnSlotId: 'A',
          creditSlotId: 'A',
          playerIds: const ['p0', 'p1'],
          startTime: DateTime(2026, 1, 1, 10, 0),
        ),
        ScrambleKingStint(
          id: 's2',
          roundId: 'r1',
          courtNumber: 1,
          turnSlotId: 'B',
          creditSlotId: 'B',
          playerIds: const ['p2', 'p3'],
          startTime: DateTime(2026, 1, 1, 10, 5),
        ),
      ];
      // B just faced A (adjacency A-B = 1). C has never played (max wait).
      final ranked = ScrambleKingService.rankQueue(
        queueSlotIds: ['B', 'C'],
        onCourtSlotId: 'A',
        courtStints: stints,
      );
      expect(ranked.first, 'C');
    });
  });

  group('floater temp-partner selection', () {
    final teamA = ScrambleKingTeamSlot(slotId: 'A', playerIds: const ['p0', 'p1']);
    final teamB = ScrambleKingTeamSlot(slotId: 'B', playerIds: const ['p2', 'p3']);

    test('jumper always picks the least-played candidate', () {
      final stints = [
        ScrambleKingStint(
          id: 's1',
          roundId: 'r1',
          courtNumber: 1,
          turnSlotId: 'A',
          creditSlotId: 'A',
          playerIds: const ['p0', 'p1'],
          startTime: DateTime(2026, 1, 1),
        ),
      ];
      // p0 and p1 have played once; p2 and p3 have played zero times.
      for (var i = 0; i < 10; i++) {
        final pick = ScrambleKingService.pickJumperPartner(
          otherQueuedTeams: [teamA, teamB],
          courtStints: stints,
        );
        expect(['p2', 'p3'].contains(pick!.playerId), isTrue);
      }
    });
  });

  group('scoring attribution', () {
    test('a floater stint credits the odd player\'s own team, never the borrowed partner\'s team',
        () {
      final t = _build(n: 5, courtCount: 1, rounds: 1); // forces exactly one floater court
      final round = t.rounds.single;
      final court = round.courts.single;
      expect(court.floaterSlot, isNotNull);

      final teamSlot = court.teamSlots.first;
      final borrowedPlayerId = teamSlot.playerIds.first;
      final floaterId = court.floaterSlot!.playerId;

      final stint = ScrambleKingStint(
        id: 'st1',
        roundId: round.id,
        courtNumber: court.courtNumber,
        turnSlotId: court.floaterSlot!.slotId,
        creditSlotId: court.floaterSlot!.slotId, // the odd player's own team
        playerIds: [floaterId, borrowedPlayerId],
        isFloaterStint: true,
        standInPlayerId: floaterId,
        points: 7,
        startTime: DateTime(2026, 1, 1),
        endTime: DateTime(2026, 1, 1, 0, 5),
      );

      final tournament = t.addStint(stint);

      final result = ScrambleKingService.computeCourtRoundResult(
          tournament, round.id, court.courtNumber);
      final floaterResult =
          result.teamResults.firstWhere((r) => r.slotId == court.floaterSlot!.slotId);
      expect(floaterResult.autoPoints, 7);
      final borrowedTeamResult =
          result.teamResults.firstWhere((r) => r.slotId == teamSlot.slotId);
      expect(borrowedTeamResult.autoPoints, 0);

      final stats = ScrambleKingService.computeStats(tournament);
      final floaterStats = stats.firstWhere((s) => s.playerId == floaterId);
      expect(floaterStats.totalPoints, 7);

      // The borrowed player (and their real partner) are unaffected — the
      // points went to the odd player's own team, not theirs.
      final borrowedStats = stats.firstWhere((s) => s.playerId == borrowedPlayerId);
      expect(borrowedStats.totalPoints, 0);
      final partnerStats = stats.firstWhere((s) => s.playerId == teamSlot.playerIds.last);
      expect(partnerStats.totalPoints, 0);
    });

    test('the odd player\'s team gets its own fun team name, like every other team', () {
      final t = _build(n: 5, courtCount: 1, rounds: 1);
      final court = t.rounds.single.courts.single;
      expect(court.floaterSlot, isNotNull);
      expect(court.floaterSlot!.teamName, isNotNull);
      expect(court.floaterSlot!.teamName, isNotEmpty);
      // Unique among this court's team names.
      final allNames = [
        ...court.teamSlots.map((s) => s.teamName),
        court.floaterSlot!.teamName,
      ];
      expect(allNames.toSet().length, allNames.length);
    });

    test('manual override takes precedence over auto-computed points', () {
      final t = _build(n: 4, courtCount: 1, rounds: 1);
      final round = t.rounds.single;
      final court = round.courts.single;
      final slotA = court.teamSlots[0];

      final stint = ScrambleKingStint(
        id: 'st1',
        roundId: round.id,
        courtNumber: court.courtNumber,
        turnSlotId: slotA.slotId,
        creditSlotId: slotA.slotId,
        playerIds: slotA.playerIds,
        points: 5,
        startTime: DateTime(2026, 1, 1),
      );

      final overriddenCourt = court.copyWith(manualTeamPoints: {slotA.slotId: 99});
      final overriddenRound = round.updateCourt(overriddenCourt);
      final tournament = t.updateRound(overriddenRound).addStint(stint);

      final result = ScrambleKingService.computeCourtRoundResult(
          tournament, round.id, court.courtNumber);
      final teamResult =
          result.teamResults.firstWhere((r) => r.slotId == slotA.slotId);
      expect(teamResult.autoPoints, 5);
      expect(teamResult.points, 99);
      expect(teamResult.isManualOverride, isTrue);
    });

    test('gamesPlayed counts the number of stints credited to a team this round', () {
      final t = _build(n: 4, courtCount: 1, rounds: 1);
      final round = t.rounds.single;
      final court = round.courts.single;
      final slotA = court.teamSlots[0];
      final slotB = court.teamSlots[1];

      var tournament = t;
      // slotA plays two separate stints (e.g. rotated back on after a
      // teammate's turn), slotB plays exactly one.
      for (var i = 0; i < 2; i++) {
        tournament = tournament.addStint(ScrambleKingStint(
          id: 'a$i',
          roundId: round.id,
          courtNumber: court.courtNumber,
          turnSlotId: slotA.slotId,
          creditSlotId: slotA.slotId,
          playerIds: slotA.playerIds,
          points: 3,
          startTime: DateTime(2026, 1, 1),
        ));
      }
      tournament = tournament.addStint(ScrambleKingStint(
        id: 'b0',
        roundId: round.id,
        courtNumber: court.courtNumber,
        turnSlotId: slotB.slotId,
        creditSlotId: slotB.slotId,
        playerIds: slotB.playerIds,
        points: 4,
        startTime: DateTime(2026, 1, 1),
      ));

      final result = ScrambleKingService.computeCourtRoundResult(
          tournament, round.id, court.courtNumber);
      final resultA = result.teamResults.firstWhere((r) => r.slotId == slotA.slotId);
      final resultB = result.teamResults.firstWhere((r) => r.slotId == slotB.slotId);
      expect(resultA.gamesPlayed, 2);
      expect(resultB.gamesPlayed, 1);
    });
  });

  group('games won ranking', () {
    test('computeCourtRoundResult ranks fewer points but more games won above more points but fewer wins', () {
      final t = _build(n: 4, courtCount: 1, rounds: 1);
      final round = t.rounds.single;
      final court = round.courts.single;
      final slotA = court.teamSlots[0];
      final slotB = court.teamSlots[1];

      final winningStint = ScrambleKingStint(
        id: 'st1',
        roundId: round.id,
        courtNumber: court.courtNumber,
        turnSlotId: slotA.slotId,
        creditSlotId: slotA.slotId,
        playerIds: slotA.playerIds,
        points: 5,
        gamesWon: 1,
        startTime: DateTime(2026, 1, 1),
        endReason: ScrambleKingStintEndReason.strike,
      );
      final higherScoringStint = ScrambleKingStint(
        id: 'st2',
        roundId: round.id,
        courtNumber: court.courtNumber,
        turnSlotId: slotB.slotId,
        creditSlotId: slotB.slotId,
        playerIds: slotB.playerIds,
        points: 20,
        gamesWon: 0,
        startTime: DateTime(2026, 1, 1),
        endReason: ScrambleKingStintEndReason.manual,
      );

      final tournament = t.addStint(winningStint).addStint(higherScoringStint);
      final result = ScrambleKingService.computeCourtRoundResult(
          tournament, round.id, court.courtNumber);

      final resultA = result.teamResults.firstWhere((r) => r.slotId == slotA.slotId);
      final resultB = result.teamResults.firstWhere((r) => r.slotId == slotB.slotId);
      expect(resultA.gamesWon, 1);
      expect(resultB.points, 20);
      expect(resultA.rank, 1,
          reason: 'fewer points but a game won should outrank more points with no wins');
      expect(resultB.rank, 2);
    });

    test('a manual override of just gamesWon leaves points alone and is flagged as an override', () {
      final t = _build(n: 4, courtCount: 1, rounds: 1);
      final round = t.rounds.single;
      final court = round.courts.single;
      final slotA = court.teamSlots[0];

      final stint = ScrambleKingStint(
        id: 'st1',
        roundId: round.id,
        courtNumber: court.courtNumber,
        turnSlotId: slotA.slotId,
        creditSlotId: slotA.slotId,
        playerIds: slotA.playerIds,
        points: 5,
        startTime: DateTime(2026, 1, 1),
      );

      final overriddenCourt = court.copyWith(manualGamesWon: {slotA.slotId: 3});
      final overriddenRound = round.updateCourt(overriddenCourt);
      final tournament = t.updateRound(overriddenRound).addStint(stint);

      final result = ScrambleKingService.computeCourtRoundResult(
          tournament, round.id, court.courtNumber);
      final teamResult = result.teamResults.firstWhere((r) => r.slotId == slotA.slotId);
      expect(teamResult.autoGamesWon, 0);
      expect(teamResult.gamesWon, 3);
      expect(teamResult.points, 5, reason: 'points should be untouched by the games-won override');
      expect(teamResult.isManualOverride, isTrue);
    });

    test('computeStats applies the same games-won-then-points tiebreak across rounds', () {
      // 8 players / 2 courts so a team fully disjoint from the round-1
      // winners can always be found in round 2, regardless of how the
      // fairness algorithm reshuffles pairings between rounds.
      final t = _build(n: 8, courtCount: 2, rounds: 2);
      final r1 = t.rounds[0];
      final c1 = r1.courts.first;
      final slotA = c1.teamSlots[0];

      final r2 = t.rounds[1];
      final highScoringSlot = r2.courts
          .expand((c) => c.teamSlots)
          .firstWhere((s) => s.playerIds.toSet().intersection(slotA.playerIds.toSet()).isEmpty);
      final highScoringCourt =
          r2.courts.firstWhere((c) => c.teamSlots.any((s) => s.slotId == highScoringSlot.slotId));

      var tournament = t;
      tournament = tournament.addStint(ScrambleKingStint(
        id: 'st1',
        roundId: r1.id,
        courtNumber: c1.courtNumber,
        turnSlotId: slotA.slotId,
        creditSlotId: slotA.slotId,
        playerIds: slotA.playerIds,
        points: 3,
        gamesWon: 1,
        startTime: DateTime(2026, 1, 1),
        endReason: ScrambleKingStintEndReason.strike,
      ));
      tournament = tournament.addStint(ScrambleKingStint(
        id: 'st2',
        roundId: r2.id,
        courtNumber: highScoringCourt.courtNumber,
        turnSlotId: highScoringSlot.slotId,
        creditSlotId: highScoringSlot.slotId,
        playerIds: highScoringSlot.playerIds,
        points: 50,
        gamesWon: 0,
        startTime: DateTime(2026, 1, 2),
        endReason: ScrambleKingStintEndReason.manual,
      ));

      final stats = ScrambleKingService.computeStats(tournament);
      final statsA = stats.firstWhere((s) => s.playerId == slotA.playerIds.first);
      final statsB = stats.firstWhere((s) => s.playerId == highScoringSlot.playerIds.first);
      expect(statsA.totalGamesWon, 1);
      expect(statsB.totalGamesWon, 0);
      expect(statsB.totalPoints, 50);
      expect(statsA.rank < statsB.rank, isTrue,
          reason: 'a single game won should outrank a much higher point total with no wins');
    });
  });
}
