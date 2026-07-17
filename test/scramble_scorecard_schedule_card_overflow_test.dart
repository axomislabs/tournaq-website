// Regression test for a horizontal overflow in ScrambleScorecardPage's
// compact (landscape, pace-alerts-only) schedule card: the "SCHEDULE" /
// "Planned start" / "Planned end" label rows had no Expanded/ellipsis
// fallback, so a narrow flex:2 column (shared with two flex:5 score cards)
// could overflow by a couple of pixels. Fixed by wrapping each label in
// Expanded with overflow: TextOverflow.ellipsis.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:tournaq/app/app_theme.dart';
import 'package:tournaq/l10n/app_localizations.dart';
import 'package:tournaq/models/scramble_tournament.dart';
import 'package:tournaq/pages/scramble_scorecard_page.dart';
import 'package:tournaq/services/scramble_storage_service.dart';

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

(ScrambleTournament, ScrambleGame, ScrambleRound) _fixture() {
  final now = DateTime.now();
  final players = List.generate(
    4,
    (i) => ScramblePlayer(
      id: 'p$i',
      name: 'Player $i',
      source: ScramblePlayerSource.created,
    ),
  );
  final round = ScrambleRound(
    id: 'round1',
    roundNumber: 1,
    scheduledStartTime: now,
    matchDuration: const Duration(minutes: 10),
    breakDuration: const Duration(minutes: 2),
  );
  final game = ScrambleGame(
    id: 'game1',
    roundId: 'round1',
    courtNumber: 1,
    sideAPlayerIds: const ['p0', 'p1'],
    sideBPlayerIds: const ['p2', 'p3'],
    status: ScrambleGameStatus.scheduled,
  );
  final tournament = ScrambleTournament(
    id: 'sc-test',
    name: 'Schedule Card Test',
    totalAvailableTime: const Duration(hours: 1),
    matchDuration: const Duration(minutes: 10),
    breakDuration: const Duration(minutes: 2),
    courtCount: 1,
    paceAlertsEnabled: true,
    startTime: now,
    players: players,
    rounds: [round],
    games: [game],
    createdAt: now,
  );
  return (tournament, game, round);
}

void main() {
  setUpAll(() async {
    final tempDir = await Directory.systemTemp
        .createTemp('scramble_scorecard_schedule_card_test');
    Hive.init(tempDir.path);
    await ScrambleStorageService.init();
  });

  testGoldens(
      'compact schedule card (narrow flex:2 column) renders with no overflow',
      (tester) async {
    final (tournament, game, round) = _fixture();
    await tester.pumpWidgetBuilder(
      ScrambleScorecardPage(
        tournament: tournament,
        game: game,
        round: round,
        onChanged: (_) {},
      ),
      wrapper: _wrap,
      // Narrow enough that the flex:2 schedule column lands around the
      // ~96px width that originally overflowed by 2.6 pixels.
      surfaceSize: const Size(616, 320),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  testGoldens(
      'compact schedule card renders with no overflow at an even narrower width',
      (tester) async {
    final (tournament, game, round) = _fixture();
    await tester.pumpWidgetBuilder(
      ScrambleScorecardPage(
        tournament: tournament,
        game: game,
        round: round,
        onChanged: (_) {},
      ),
      wrapper: _wrap,
      surfaceSize: const Size(568, 320),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
