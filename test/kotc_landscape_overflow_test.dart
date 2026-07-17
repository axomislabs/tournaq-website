// Regression test for the King of the Court landscape scorecard overflow fix.
// Pumps the real scoreboard page at a short landscape height, drives it to an
// active on-court game (the exact state where the score counter previously
// collapsed to zero height), and asserts no RenderFlex overflow / exception
// occurs.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:tournaq/app/app_theme.dart';
import 'package:tournaq/l10n/app_localizations.dart';
import 'package:tournaq/models/king_of_the_court_tournament.dart';
import 'package:tournaq/pages/king_of_the_court_scoreboard_page.dart';
import 'package:tournaq/services/king_of_the_court_storage_service.dart';

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

KingOfTheCourtTournament _tournament({
  KotcAssignmentMode mode = KotcAssignmentMode.manual,
}) {
  final players = List.generate(
    4,
    (i) => KotcPlayer(
      id: 'p$i',
      name: 'Player $i',
      source: KotcPlayerSource.created,
    ),
  );
  return KingOfTheCourtTournament(
    id: 'kotc-test',
    name: 'Landscape Test',
    totalTime: const Duration(minutes: 30),
    playersPerTeam: 2,
    assignmentMode: mode,
    status: KotcTournamentStatus.inProgress,
    players: players,
    games: const [],
    createdAt: DateTime(2024, 1, 1),
  );
}

void main() {
  setUpAll(() async {
    final tempDir =
        await Directory.systemTemp.createTemp('kotc_landscape_test');
    Hive.init(tempDir.path);
    await KingOfTheCourtStorageService.init();
  });

  testGoldens('active scoring tile renders with no overflow in a short landscape height',
      (tester) async {
    final tournament = _tournament();
    await tester.pumpWidgetBuilder(
      KingOfTheCourtScoreboardPage(
        tournament: tournament,
        existingPlayers: const [],
        onChanged: (_) {},
      ),
      wrapper: _wrap,
      // A tight landscape phone height (iPhone SE-class), the shortest
      // realistic case reported for the overflow/invisible-counter bug.
      surfaceSize: const Size(667, 320),
    );
    await tester.pumpAndSettle();

    // Manual-mode selection tile: pick 2 of the 4 pool players, then start.
    await tester.tap(find.text('Player 0'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Player 1'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.play_arrow_rounded));
    await tester.pumpAndSettle();

    // No RenderFlex overflow or other exception during layout/paint.
    expect(tester.takeException(), isNull);

    // The score counter must actually occupy visible space, not collapse
    // to a zero-height Expanded.
    final counterFinder = find.text('0').first;
    expect(counterFinder, findsWidgets);
    final size = tester.getSize(counterFinder);
    expect(size.height, greaterThan(0));
    expect(size.width, greaterThan(0));
  });

  testGoldens(
      'active scoring tile renders with no overflow in automatedAllPlay (admin tile stacked below)',
      (tester) async {
    final tournament = _tournament(mode: KotcAssignmentMode.automatedAllPlay);
    await tester.pumpWidgetBuilder(
      KingOfTheCourtScoreboardPage(
        tournament: tournament,
        existingPlayers: const [],
        onChanged: (_) {},
      ),
      wrapper: _wrap,
      surfaceSize: const Size(667, 320),
    );
    await tester.pumpAndSettle();

    // Automated suggestion tile: accept the suggested challenger team.
    await tester.tap(find.byIcon(Icons.play_arrow_rounded));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);

    final counterFinder = find.text('0').first;
    expect(counterFinder, findsWidgets);
    final size = tester.getSize(counterFinder);
    expect(size.height, greaterThan(0));
    expect(size.width, greaterThan(0));
  });

  testGoldens(
      'Up Next + Challengers tiles (stacked, half-height each) render with no overflow at an even tighter height',
      (tester) async {
    // This is the height that originally exposed a separate overflow in
    // _buildUpNextTile/_buildChallengersTile — they get roughly half the
    // vertical room the active scoring tile does (stacked in one column),
    // so they hit the overflow ceiling before the active tile does.
    final tournament = _tournament(mode: KotcAssignmentMode.automatedAllPlay);
    await tester.pumpWidgetBuilder(
      KingOfTheCourtScoreboardPage(
        tournament: tournament,
        existingPlayers: const [],
        onChanged: (_) {},
      ),
      wrapper: _wrap,
      surfaceSize: const Size(667, 260),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byIcon(Icons.play_arrow_rounded));
    await tester.tap(find.byIcon(Icons.play_arrow_rounded));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  testGoldens(
      'timer control row fits without overflow through not-started, running, and paused states at narrow landscape width',
      (tester) async {
    final tournament = _tournament();
    await tester.pumpWidgetBuilder(
      KingOfTheCourtScoreboardPage(
        tournament: tournament,
        existingPlayers: const [],
        onChanged: (_) {},
      ),
      wrapper: _wrap,
      surfaceSize: const Size(568, 320), // iPhone SE 1st-gen landscape width
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull); // not-started state

    // Start the timer (running state: Pause + Restart + 2 time buttons).
    await tester.tap(find.text('Restart'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    // Pause it (paused state: Resume + Restart + 2 time buttons — this is
    // the combination that used to overflow at narrow landscape widths).
    await tester.tap(find.text('Stop'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testGoldens(
      'active scoring tile counter stays readably large even at an Android-tight landscape height',
      (tester) async {
    final tournament = _tournament();
    await tester.pumpWidgetBuilder(
      KingOfTheCourtScoreboardPage(
        tournament: tournament,
        existingPlayers: const [],
        onChanged: (_) {},
      ),
      wrapper: _wrap,
      // Shorter than the iPhone SE case above — approximates an Android
      // device where system nav/status chrome eats more of the height.
      surfaceSize: const Size(667, 260),
    );
    await tester.pumpAndSettle();

    // The selection tile is scrollable at this height (by design, per the
    // earlier overflow fix), so scroll each target into view before tapping.
    await tester.ensureVisible(find.text('Player 0'));
    await tester.tap(find.text('Player 0'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Player 1'));
    await tester.tap(find.text('Player 1'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byIcon(Icons.play_arrow_rounded));
    await tester.tap(find.byIcon(Icons.play_arrow_rounded));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);

    // FittedBox scales its child at paint time — getSize() on the Text
    // child returns its unscaled intrinsic size, not the visible on-screen
    // size. The FittedBox's own box (sized by its Center/Expanded parent)
    // is what the number is actually fitted into, so that's the meaningful
    // proxy for how large the digit will actually appear.
    final fittedBoxFinder = find.ancestor(
      of: find.text('0').first,
      matching: find.byType(FittedBox),
    );
    final boxSize = tester.getSize(fittedBoxFinder);
    // ignore: avoid_print
    print('Counter FittedBox size at 260 height: $boxSize');
    // The counter sits between the +/- buttons now, so it shares their
    // guaranteed height instead of being squeezed into its own sliver —
    // it should read as a real, legible number, not a sliver of pixels.
    expect(boxSize.height, greaterThan(24));
  });
}
