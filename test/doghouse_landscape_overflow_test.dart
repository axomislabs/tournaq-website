// Regression test for the Doghouse landscape scorecard overflow fix, mirroring
// test/kotc_landscape_overflow_test.dart (King of the Court had the same bugs;
// this file confirms the ported fix works identically for Doghouse). Pumps the
// real scoreboard page at short/narrow landscape sizes, drives it to an active
// on-court game, and asserts no RenderFlex overflow / exception occurs, plus
// that the score counter stays a legible size.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:tournaq/app/app_theme.dart';
import 'package:tournaq/l10n/app_localizations.dart';
import 'package:tournaq/models/doghouse_drill.dart';
import 'package:tournaq/pages/doghouse_scoreboard_page.dart';
import 'package:tournaq/services/doghouse_storage_service.dart';

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

DoghouseTournament _tournament({
  DoghouseAssignmentMode mode = DoghouseAssignmentMode.manual,
}) {
  final players = List.generate(
    4,
    (i) => DoghousePlayer(
      id: 'p$i',
      name: 'Player $i',
      source: DoghousePlayerSource.created,
    ),
  );
  return DoghouseTournament(
    id: 'doghouse-test',
    name: 'Landscape Test',
    totalTime: const Duration(minutes: 30),
    playersPerTeam: 2,
    assignmentMode: mode,
    status: DoghouseTournamentStatus.inProgress,
    players: players,
    games: const [],
    createdAt: DateTime(2024, 1, 1),
  );
}

void main() {
  setUpAll(() async {
    final tempDir =
        await Directory.systemTemp.createTemp('doghouse_landscape_test');
    Hive.init(tempDir.path);
    await DoghouseStorageService.init();
  });

  testGoldens('active scoring tile renders with no overflow in a short landscape height',
      (tester) async {
    final tournament = _tournament();
    await tester.pumpWidgetBuilder(
      DoghouseScoreboardPage(
        tournament: tournament,
        existingPlayers: const [],
        onChanged: (_) {},
      ),
      wrapper: _wrap,
      surfaceSize: const Size(667, 320),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Player 0'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Player 1'));
    await tester.pumpAndSettle();
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
      'active scoring tile renders with no overflow in automatedAllPlay (admin tile stacked below)',
      (tester) async {
    final tournament = _tournament(mode: DoghouseAssignmentMode.automatedAllPlay);
    await tester.pumpWidgetBuilder(
      DoghouseScoreboardPage(
        tournament: tournament,
        existingPlayers: const [],
        onChanged: (_) {},
      ),
      wrapper: _wrap,
      surfaceSize: const Size(667, 320),
    );
    await tester.pumpAndSettle();

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
    final tournament = _tournament(mode: DoghouseAssignmentMode.automatedAllPlay);
    await tester.pumpWidgetBuilder(
      DoghouseScoreboardPage(
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
      DoghouseScoreboardPage(
        tournament: tournament,
        existingPlayers: const [],
        onChanged: (_) {},
      ),
      wrapper: _wrap,
      surfaceSize: const Size(568, 320), // iPhone SE 1st-gen landscape width
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull); // not-started state

    await tester.tap(find.text('Restart'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull); // running state

    await tester.tap(find.text('Stop'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull); // paused state
  });

  testGoldens(
      'active scoring tile counter stays readably large even at an Android-tight landscape height',
      (tester) async {
    final tournament = _tournament();
    await tester.pumpWidgetBuilder(
      DoghouseScoreboardPage(
        tournament: tournament,
        existingPlayers: const [],
        onChanged: (_) {},
      ),
      wrapper: _wrap,
      surfaceSize: const Size(667, 260),
    );
    await tester.pumpAndSettle();

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

    final fittedBoxFinder = find.ancestor(
      of: find.text('0').first,
      matching: find.byType(FittedBox),
    );
    final boxSize = tester.getSize(fittedBoxFinder);
    // ignore: avoid_print
    print('Counter FittedBox size at 260 height: $boxSize');
    expect(boxSize.height, greaterThan(24));
  });
}
