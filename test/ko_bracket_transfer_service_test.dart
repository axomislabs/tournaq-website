import 'package:flutter_test/flutter_test.dart';
import 'package:tournaq/models/ko_bracket_tournament.dart';
import 'package:tournaq/scoring/ko_bracket_adapter.dart';
import 'package:tournaq/services/ko_bracket_transfer_service.dart';

KoBracketTournament _build() {
  const team1 = KoTeam(id: 'A', name: 'Alpha', players: [
    KoPlayerSnapshot(appPlayerId: 'a1', name: 'Ann'),
    KoPlayerSnapshot(appPlayerId: 'a2', name: 'Bo'),
  ]);
  const team2 = KoTeam(id: 'B', name: 'Bravo', players: [
    KoPlayerSnapshot(appPlayerId: 'b1', name: 'Cy'),
    KoPlayerSnapshot(appPlayerId: 'b2', name: 'Di'),
  ]);
  final match = KoMatch(
    id: 'm1',
    round: 1,
    matchIndex: 0,
    team1Id: 'A',
    team2Id: 'B',
    courtAssignment: 2,
    scheduledStartTime: DateTime(2026, 7, 8, 10),
  );
  return KoBracketTournament(
    id: 'host-1',
    name: 'Bracket Bash',
    playersPerSide: 2,
    courtCount: 1,
    defaultFormat: const KoRoundFormat(setsPerGame: 3, pointsPerSet: 21),
    roundFormats: const {1: KoRoundFormat(setsPerGame: 3, pointsPerSet: 21)},
    estimatedStart: DateTime(2026, 7, 8, 10),
    teams: [team1, team2],
    matches: [match],
    deviceId: 'test',
  );
}

void main() {
  test('match export round-trips into an importable one-match tournament', () {
    final t = _build();
    final match = t.matches.single;

    final encoded = KoBracketTransferService.encodeMatchExport(t, match);
    final imp = KoBracketTransferService.decodeMatchExport(encoded);

    // Routing ids + config preserved.
    expect(imp.parentTournamentId, t.id);
    expect(imp.match.id, match.id);
    expect(imp.tournamentName, 'Bracket Bash');
    expect(imp.tournament.matches.length, 1);
    expect(imp.match.courtAssignment, 2);

    final fmt = imp.tournament.formatForRound(imp.match.round);
    expect(fmt.setsPerGame, 3);
    expect(fmt.pointsPerSet, 21);

    // Teams travel as names, in order.
    final t1 = imp.tournament.teamById(imp.match.team1Id!)!;
    final t2 = imp.tournament.teamById(imp.match.team2Id!)!;
    expect(t1.name, 'Alpha');
    expect(t1.players.map((p) => p.name).toList(), ['Ann', 'Bo']);
    expect(t2.name, 'Bravo');
    expect(t2.players.map((p) => p.name).toList(), ['Cy', 'Di']);
  });

  test('result round-trips and merges back onto the host match (side 2 wins)',
      () {
    final t = _build();
    final match = t.matches.single;

    // Referee device scores the mini match: team2 takes it 2 sets to 1.
    final imp = KoBracketTransferService.decodeMatchExport(
        KoBracketTransferService.encodeMatchExport(t, match));
    final refMatch = imp.match.copyWith(
      sets: const [
        KoSet(score1: 21, score2: 15, isCompleted: true),
        KoSet(score1: 10, score2: 21, isCompleted: true),
        KoSet(score1: 18, score2: 21, isCompleted: true),
      ],
      winnerId: imp.match.team2Id,
      status: KoMatchStatus.completed,
    );

    final res = KoBracketTransferService.decodeResult(
        KoBracketTransferService.encodeResult(imp.parentTournamentId, refMatch));

    expect(res.parentTournamentId, t.id);
    expect(res.matchId, match.id);
    expect(res.winnerSide, 1); // team2 == second exported side
    expect(res.sets.length, 3);
    expect(res.sets.first.score1, 21);
    expect(res.sets.first.score2, 15);

    // Host merges the scanned result back.
    final winnerId = res.winnerSide == 1 ? match.team2Id : match.team1Id;
    expect(winnerId, 'B');
    final updated = KoBracketAdapter.applyMatchResult(
      t,
      match.copyWith(
        sets: res.sets,
        winnerId: winnerId,
        status: KoMatchStatus.completed,
      ),
      propagateWinner: true,
    );
    expect(updated.matches.single.winnerId, 'B');
    // Only match complete → tournament flips to completed.
    expect(updated.status, KoBracketStatus.completed);
  });

  test('decodeResult rejects a foreign QR type', () {
    expect(
      () => KoBracketTransferService.decodeResult('not-a-real-qr'),
      throwsA(isA<TransferException>()),
    );
  });
}
