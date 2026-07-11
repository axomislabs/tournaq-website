import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tournaq/l10n/app_localizations.dart';
import 'package:tournaq/models/scramble_tournament.dart';
import 'package:tournaq/pages/scramble_scorecard_page.dart';
import 'package:tournaq/services/scramble_service.dart';

void main() {
  testWidgets(
      'match timer resumes from the elapsed-adjusted remaining on re-entry '
      '(portrait) instead of resetting to the full duration', (tester) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final base = ScrambleService.buildTournament(
      name: 'Resume',
      roundCount: 1,
      matchDuration: const Duration(minutes: 15),
      breakDuration: Duration.zero,
      courtCount: 1,
      playersPerTeam: 2,
      players: List.generate(
        4,
        (i) => ScramblePlayer(
            id: 'p$i', name: 'Player $i', source: ScramblePlayerSource.random),
      ),
      startTime: DateTime(2026, 1, 1, 10),
    );
    // Simulate returning to a match that was started 6 minutes ago.
    final started = base.games.first.copyWith(
      status: ScrambleGameStatus.inProgress,
      actualStartTime: DateTime.now().subtract(const Duration(minutes: 6)),
    );
    final t = base.updateGame(started);
    final game = t.games.firstWhere((g) => g.id == started.id);
    final round = t.getRound(game.roundId)!;

    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: ScrambleScorecardPage(
        tournament: t,
        game: game,
        round: round,
        onChanged: (_) {},
      ),
    ));
    await tester.pump(); // let the post-frame resume callback run

    // The full match length must NOT be shown — that was the bug.
    expect(find.text('15:00'), findsNothing);
    // ~9 minutes (15 − 6) should be displayed on the countdown.
    final resumed = find.byWidgetPredicate(
      (w) => w is Text && w.data != null && RegExp(r'^0[89]:\d\d$').hasMatch(w.data!),
      description: 'countdown near 09:00',
    );
    expect(resumed, findsWidgets);
  });
}
