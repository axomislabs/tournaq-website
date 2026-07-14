import 'package:flutter_test/flutter_test.dart';
import 'package:tournaq/models/scramble_king_tournament.dart';
import 'package:tournaq/services/scramble_king_service.dart';
import 'package:tournaq/services/scramble_king_transfer_service.dart';

List<ScrambleKingPlayer> _players(int n) => List.generate(
      n,
      (i) => ScrambleKingPlayer(
        id: 'p$i',
        name: 'Player ${i + 1}',
        source: ScrambleKingPlayerSource.random,
      ),
    );

ScrambleKingTournament _build({int n = 8, int courtCount = 1}) =>
    ScrambleKingService.buildTournament(
      name: 'Neon Court',
      roundCount: 1,
      matchDuration: const Duration(minutes: 10),
      breakDuration: const Duration(minutes: 1),
      courtCount: courtCount,
      strikePoints: 5,
      assignmentMode: ScrambleKingAssignmentMode.automatedAllPlay,
      oddPlayerMode: ScrambleKingOddPlayerMode.jumper,
      players: _players(n),
      startTime: DateTime(2026, 7, 8, 10),
    );

List<String> _namesOf(ScrambleKingTournament src, List<String> ids) =>
    ids.map((id) => src.getPlayer(id)!.name).toList();

void main() {
  test('court export round-trips into an importable court', () {
    final t = _build(n: 9); // odd → one floater court
    final round = t.rounds.single;
    final formation = round.courts.first;

    final encoded = ScrambleKingTransferService.encodeCourtExport(t, round, formation);
    final imp = ScrambleKingTransferService.decodeCourtExport(encoded);

    // Routing ids + config preserved.
    expect(imp.parentTournamentId, t.id);
    expect(imp.round.id, round.id);
    expect(imp.formation.courtNumber, formation.courtNumber);
    expect(imp.tournamentName, 'Neon Court');
    expect(imp.tournament.strikePoints, t.strikePoints);
    expect(imp.tournament.assignmentMode, t.assignmentMode);
    expect(imp.tournament.oddPlayerMode, t.oddPlayerMode);
    expect(imp.round.matchDuration, round.matchDuration);
    expect(imp.round.breakDuration, round.breakDuration);

    // Mini tournament is one round / one court.
    expect(imp.tournament.rounds.length, 1);
    expect(imp.tournament.rounds.single.courts.length, 1);

    // Teams travel as names, in the same order, with the same fun names.
    expect(imp.formation.teamSlots.length, formation.teamSlots.length);
    for (var i = 0; i < formation.teamSlots.length; i++) {
      expect(_namesOf(imp.tournament, imp.formation.teamSlots[i].playerIds),
          _namesOf(t, formation.teamSlots[i].playerIds));
      expect(imp.formation.teamSlots[i].teamName, formation.teamSlots[i].teamName);
    }

    // The floater (odd player) round-trips too.
    expect(imp.formation.floaterSlot, isNotNull);
    expect(imp.tournament.getPlayer(imp.formation.floaterSlot!.playerId)!.name,
        t.getPlayer(formation.floaterSlot!.playerId)!.name);

    // Pace alerts off by default → schedule/pace payload omitted.
    expect(imp.tournament.paceAlertsEnabled, isFalse);
  });

  test('court export carries schedule + pace when pace alerts are on', () {
    final t = _build().copyWith(paceAlertsEnabled: true);
    final round = t.rounds.single;
    final formation = round.courts.first;

    final encoded = ScrambleKingTransferService.encodeCourtExport(t, round, formation);
    final imp = ScrambleKingTransferService.decodeCourtExport(encoded);

    expect(imp.tournament.paceAlertsEnabled, isTrue);
    expect(imp.round.scheduledStartTime, round.scheduledStartTime);
  });

  test('result export preserves per-team points/games-won, positionally', () {
    final t = _build(n: 8); // 4 teams, no floater
    final round = t.rounds.single;
    final formation = round.courts.first;
    final slotIds = formation.teamSlots.map((s) => s.slotId).toList();

    // Distinct manual results so order is unambiguous.
    final points = {slotIds[0]: 15, slotIds[1]: 8, slotIds[2]: 21, slotIds[3]: 11};
    final games = {slotIds[0]: 1, slotIds[1]: 0, slotIds[2]: 2, slotIds[3]: 1};
    final played = formation.copyWith(
      manualTeamPoints: points,
      manualGamesWon: games,
      actualStartTime: DateTime(2026, 7, 8, 10, 0),
      actualEndTime: DateTime(2026, 7, 8, 10, 10),
    );
    final playedT = t.updateRound(round.updateCourt(played));

    final encoded =
        ScrambleKingTransferService.encodeResult(t.id, playedT, round, played);
    final res = ScrambleKingTransferService.decodeResult(encoded);

    expect(res.parentTournamentId, t.id);
    expect(res.roundId, round.id);
    expect(res.courtNumber, formation.courtNumber);
    expect(res.teamResults.length, 4);
    // Entries are aligned to teamSlots order.
    for (var i = 0; i < 4; i++) {
      expect(res.teamResults[i].points, points[slotIds[i]]);
      expect(res.teamResults[i].gamesWon, games[slotIds[i]]);
    }
    expect(res.actualStartTime, DateTime(2026, 7, 8, 10, 0));
    expect(res.actualEndTime, DateTime(2026, 7, 8, 10, 10));
  });

  test('decoding rejects the wrong payload type', () {
    final t = _build();
    final round = t.rounds.single;
    final formation = round.courts.first;

    final courtCode =
        ScrambleKingTransferService.encodeCourtExport(t, round, formation);
    expect(() => ScrambleKingTransferService.decodeResult(courtCode),
        throwsA(isA<ScrambleKingTransferException>()));

    final resultCode =
        ScrambleKingTransferService.encodeResult(t.id, t, round, formation);
    expect(() => ScrambleKingTransferService.decodeCourtExport(resultCode),
        throwsA(isA<ScrambleKingTransferException>()));
  });

  test('decoding rejects garbage input', () {
    expect(() => ScrambleKingTransferService.decodeCourtExport('not-a-qr-code'),
        throwsA(isA<ScrambleKingTransferException>()));
  });
}
