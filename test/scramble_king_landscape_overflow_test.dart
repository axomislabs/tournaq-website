// Regression test for the Scramble King landscape scorecard overflow fix,
// mirroring test/kotc_landscape_overflow_test.dart and
// test/doghouse_landscape_overflow_test.dart (same bug class: the score
// counter squeezed above a separate +/- button row could shrink to
// near-invisible on short/Android landscape heights — fixed by placing the
// counter between the buttons instead). Scramble King's timer row was already
// correct (the reference implementation the other two modes were missing),
// and it has no player-selection tile (courts are pre-formed by the round
// scheduler), so this file only needs to cover the counter placement.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:tournaq/app/app_theme.dart';
import 'package:tournaq/l10n/app_localizations.dart';
import 'package:tournaq/models/scramble_king_tournament.dart';
import 'package:tournaq/pages/scramble_king_court_page.dart';
import 'package:tournaq/services/scramble_king_storage_service.dart';

WidgetWrapper get _wrap => materialAppWrapper(
      theme: AppTheme.buildTheme(),
      localizations: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      localeOverrides: AppLocalizations.supportedLocales,
    );

ScrambleKingTournament _tournamentWithActiveCourt() {
  final players = List.generate(
    4,
    (i) => ScrambleKingPlayer(
      id: 'p$i',
      name: 'Player $i',
      source: ScrambleKingPlayerSource.created,
    ),
  );
  final now = DateTime.now();
  final formation = ScrambleKingCourtFormation(
    courtNumber: 1,
    teamSlots: const [
      ScrambleKingTeamSlot(slotId: 'slotA', playerIds: ['p0', 'p1']),
      ScrambleKingTeamSlot(slotId: 'slotB', playerIds: ['p2', 'p3']),
    ],
    // Already started, so opening the page auto-resumes into live play and
    // (automated mode) auto-places the first team on court.
    actualStartTime: now,
  );
  final round = ScrambleKingRound(
    id: 'round1',
    roundNumber: 1,
    scheduledStartTime: now,
    matchDuration: const Duration(minutes: 10),
    breakDuration: const Duration(minutes: 2),
    actualStartTime: now,
    courts: [formation],
  );
  return ScrambleKingTournament(
    id: 'sk-test',
    name: 'Landscape Test',
    courtCount: 1,
    roundCount: 1,
    matchDuration: const Duration(minutes: 10),
    breakDuration: const Duration(minutes: 2),
    assignmentMode: ScrambleKingAssignmentMode.automated,
    startTime: now,
    players: players,
    rounds: [round],
    stints: const [],
    createdAt: now,
  );
}

void main() {
  setUpAll(() async {
    final tempDir =
        await Directory.systemTemp.createTemp('scramble_king_landscape_test');
    Hive.init(tempDir.path);
    await ScrambleKingStorageService.init();
  });

  Future<void> pumpActiveCourt(WidgetTester tester, Size surfaceSize) async {
    final tournament = _tournamentWithActiveCourt();
    await tester.pumpWidgetBuilder(
      ScrambleKingCourtPage(
        tournament: tournament,
        roundId: 'round1',
        courtNumber: 1,
        onChanged: (_) {},
      ),
      wrapper: _wrap,
      surfaceSize: surfaceSize,
    );
    await tester.pumpAndSettle();
  }

  testGoldens('active scoring tile renders with no overflow in a short landscape height',
      (tester) async {
    await pumpActiveCourt(tester, const Size(667, 320));

    expect(tester.takeException(), isNull);

    final counterFinder = find.text('0').first;
    expect(counterFinder, findsWidgets);
    final size = tester.getSize(counterFinder);
    expect(size.height, greaterThan(0));
    expect(size.width, greaterThan(0));
  });

  testGoldens(
      'active scoring tile counter stays readably large even at an Android-tight landscape height',
      (tester) async {
    await pumpActiveCourt(tester, const Size(667, 300));

    expect(tester.takeException(), isNull);

    final fittedBoxFinder = find.ancestor(
      of: find.text('0').first,
      matching: find.byType(FittedBox),
    );
    final boxSize = tester.getSize(fittedBoxFinder);
    // ignore: avoid_print
    print('Counter FittedBox size at 300 height: $boxSize');
    expect(boxSize.height, greaterThan(24));
  });

  testGoldens(
      'Up Next + Challengers tiles (stacked, half-height each) render with no overflow at an even tighter height',
      (tester) async {
    // This is the height that originally exposed the separate overflow in
    // _buildUpNextTile/_buildChallengersTile — they get roughly half the
    // vertical room the active scoring tile does (stacked in one column),
    // so they hit the overflow ceiling before the active tile does.
    await pumpActiveCourt(tester, const Size(667, 260));

    expect(tester.takeException(), isNull);
  });
}
