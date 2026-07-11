import 'package:flutter_test/flutter_test.dart';
import 'package:tournaq/models/scramble_tournament.dart';
import 'package:tournaq/services/scramble_service.dart';
import 'package:tournaq/services/scramble_transfer_service.dart';

ScrambleTournament _build() => ScrambleService.buildTournament(
      name: 'Beach Bash',
      roundCount: 1,
      matchDuration: const Duration(minutes: 12),
      breakDuration: const Duration(minutes: 2),
      courtCount: 2,
      playersPerTeam: 2,
      players: List.generate(
        8,
        (i) => ScramblePlayer(
          id: 'p$i',
          name: 'Player ${i + 1}',
          source: ScramblePlayerSource.random,
        ),
      ),
      startTime: DateTime(2026, 7, 8, 10),
    );

void main() {
  test('game export round-trips into an importable scorecard', () {
    final t = _build();
    final game = t.games.first;
    final round = t.getRound(game.roundId)!;

    final encoded = ScrambleTransferService.encodeGameExport(t, game, round);
    final imported = ScrambleTransferService.decodeGameExport(encoded);

    // The three ids needed to return the result to the host are preserved.
    expect(imported.parentTournamentId, t.id);
    expect(imported.id, game.id);
    expect(imported.game.id, game.id);
    expect(imported.game.roundId, game.roundId);
    expect(imported.round.id, round.id);

    expect(imported.tournamentName, 'Beach Bash');
    expect(imported.game.courtNumber, game.courtNumber);
    expect(imported.game.sittingOutPlayerIds, isEmpty);
    expect(imported.round.matchDuration, round.matchDuration);
    expect(imported.tournament.playersPerTeam, t.playersPerTeam);

    // Player identities travel as names; every referenced player resolves.
    List<String> namesOf(ScrambleTournament src, List<String> ids) =>
        ids.map((id) => src.getPlayer(id)!.name).toList();
    expect(namesOf(imported.tournament, imported.game.sideAPlayerIds),
        namesOf(t, game.sideAPlayerIds));
    expect(namesOf(imported.tournament, imported.game.sideBPlayerIds),
        namesOf(t, game.sideBPlayerIds));

    // First server maps to the same player by name.
    if (game.firstServerId != null) {
      expect(imported.game.firstServerId, isNotNull);
      expect(imported.tournament.getPlayer(imported.game.firstServerId!)!.name,
          t.getPlayer(game.firstServerId!)!.name);
    }
    if (game.arbitratorId != null) {
      expect(imported.tournament.getPlayer(imported.game.arbitratorId!)!.name,
          t.getPlayer(game.arbitratorId!)!.name);
    }

    // Pace alerts are off by default — the schedule/pace payload is omitted.
    expect(imported.tournament.paceAlertsEnabled, isFalse);
  });

  test('game export carries schedule + pace when pace alerts are on', () {
    final base = _build();
    final t = base.copyWith(paceAlertsEnabled: true);
    final game = t.games.first;
    final round = t.getRound(game.roundId)!;

    final encoded = ScrambleTransferService.encodeGameExport(t, game, round);
    final imported = ScrambleTransferService.decodeGameExport(encoded);

    expect(imported.tournament.paceAlertsEnabled, isTrue);
    expect(imported.round.scheduledStartTime, round.scheduledStartTime);
    expect(imported.round.breakDuration, round.breakDuration);
  });

  test('result export round-trips', () {
    final t = _build();
    final game = t.games.first;
    final completed = game.copyWith(
      sideAScore: 21,
      sideBScore: 18,
      status: ScrambleGameStatus.completed,
      actualStartTime: DateTime(2026, 7, 8, 10, 0),
      actualEndTime: DateTime(2026, 7, 8, 10, 12),
    );

    final encoded = ScrambleTransferService.encodeResult(t.id, completed);
    final result = ScrambleTransferService.decodeResult(encoded);

    expect(result.parentTournamentId, t.id);
    expect(result.gameId, game.id);
    expect(result.roundId, game.roundId);
    expect(result.sideAScore, 21);
    expect(result.sideBScore, 18);
    expect(result.actualStartTime, DateTime(2026, 7, 8, 10, 0));
    expect(result.actualEndTime, DateTime(2026, 7, 8, 10, 12));
  });

  test('decoding rejects the wrong payload type', () {
    final t = _build();
    final game = t.games.first;
    final round = t.getRound(game.roundId)!;

    final resultCode = ScrambleTransferService.encodeResult(t.id, game);
    expect(() => ScrambleTransferService.decodeGameExport(resultCode),
        throwsA(isA<TransferException>()));

    final gameCode = ScrambleTransferService.encodeGameExport(t, game, round);
    expect(() => ScrambleTransferService.decodeResult(gameCode),
        throwsA(isA<TransferException>()));
  });

  test('decoding rejects garbage input', () {
    expect(() => ScrambleTransferService.decodeGameExport('not-a-qr-code'),
        throwsA(isA<TransferException>()));
  });
}
