// Interaction tests for the Doghouse/KOTC alignment work: Auto-All-Play
// admin rotation, Challenger-team eject/undo, mid-game editable Match
// Controls chips, and wall-clock timer persistence.
//
// Run: flutter test test/doghouse_alignment_test.dart

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:tournaq/app/app_theme.dart';
import 'package:tournaq/l10n/app_localizations.dart';
import 'package:tournaq/models/doghouse_drill.dart';
import 'package:tournaq/pages/doghouse_scoreboard_page.dart';
import 'package:tournaq/services/doghouse_storage_service.dart';
import 'package:tournaq/widgets/admin_rotation_tile.dart';
import 'package:tournaq/widgets/challenger_eject_column.dart';
import 'package:tournaq/widgets/scramble_timer_widget.dart';

final _now = DateTime(2026, 1, 1, 12);

const _portraitSize = Size(390, 844);

Widget _wrap(Widget child) => MaterialApp(
      theme: AppTheme.buildTheme(),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    );

DoghousePlayer _p(String id, String name) => DoghousePlayer(
      id: id,
      name: name,
      source: DoghousePlayerSource.existing,
    );

void main() {
  setUpAll(() async {
    final tempDir =
        await Directory.systemTemp.createTemp('doghouse_alignment_test');
    Hive.init(tempDir.path);
    await DoghouseStorageService.init();
  });

  // The Match Controls chips only render in the portrait body — the default
  // test surface is landscape-shaped, so every test needs a phone-shaped
  // surface to see them (mirrors golden_test.dart's `_pageSz`).
  Future<void> pumpPortrait(WidgetTester tester, Widget child) async {
    await tester.binding.setSurfaceSize(_portraitSize);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(_wrap(child));
  }

  group('Auto-All-Play admin rotation', () {
    testWidgets('excludes the admin from Dogs/Challengers/Up Next',
        (tester) async {
      final players = [
        _p('1', 'Alice'), _p('2', 'Bob'), _p('3', 'Charlie'),
        _p('4', 'Diana'), _p('5', 'Eve'), _p('6', 'Frank'), _p('7', 'Grace'),
      ];
      final t = DoghouseTournament(
        id: 'd1',
        name: 'Test Drill',
        totalTime: const Duration(hours: 1),
        playersPerTeam: 2,
        escapePoints: 3,
        lossLimit: 3,
        assignmentMode: DoghouseAssignmentMode.automatedAllPlay,
        status: DoghouseTournamentStatus.inProgress,
        players: players,
        games: const [],
        createdAt: _now,
      );

      await pumpPortrait(
          tester,
          DoghouseScoreboardPage(
            tournament: t,
            existingPlayers: const [],
            existingGroups: const [],
            onChanged: (_) {},
          ));
      await tester.pumpAndSettle();

      // Auto-All-Play wiring: the admin tile rendered with a name assigned.
      expect(find.byType(AdminRotationTile), findsOneWidget);
      final adminTile =
          tester.widget<AdminRotationTile>(find.byType(AdminRotationTile));
      expect(adminTile.adminName, isNotNull);
      final adminName = adminTile.adminName!;

      // The admin's name should appear exactly once — inside the admin tile
      // itself — and nowhere else (not as a player chip in the Dogs /
      // Challengers / Up Next queue slots). This is the _activePool
      // exclusion this port adds.
      expect(find.text(adminName), findsOneWidget,
          reason:
              'admin "$adminName" must be excluded from all queue slots, only shown in the admin tile');

      // Start the suggested team so the automated queue (with the
      // Challenger-eject column) renders.
      await tester.tap(find.widgetWithText(ElevatedButton, 'Enter Doghouse'));
      await tester.pumpAndSettle();

      expect(find.text(adminName), findsOneWidget,
          reason:
              'admin must still be excluded from the queue after a team is on court');
      expect(find.widgetWithText(ElevatedButton, 'Eject\nChallenger'),
          findsOneWidget);
    });
  });

  group('Challenger eject / undo', () {
    testWidgets('ejects the Challenger slot and undo restores it',
        (tester) async {
      final players = [
        _p('1', 'Alice'), _p('2', 'Bob'), _p('3', 'Charlie'),
        _p('4', 'Diana'), _p('5', 'Eve'), _p('6', 'Frank'),
      ];
      final t = DoghouseTournament(
        id: 'd2',
        name: 'Test Drill',
        totalTime: const Duration(hours: 1),
        playersPerTeam: 2,
        escapePoints: 3,
        lossLimit: 3,
        assignmentMode: DoghouseAssignmentMode.automated,
        status: DoghouseTournamentStatus.inProgress,
        players: players,
        games: const [],
        createdAt: _now,
      );

      await pumpPortrait(
          tester,
          DoghouseScoreboardPage(
            tournament: t,
            existingPlayers: const [],
            existingGroups: const [],
            onChanged: (_) {},
          ));
      await tester.pumpAndSettle();

      // Start the suggested team so the automated 3-slot queue (with the
      // Challenger-eject column) renders.
      await tester.tap(find.widgetWithText(ElevatedButton, 'Enter Doghouse'));
      await tester.pumpAndSettle();

      final ejectColumn = find.byType(ChallengerEjectColumn);
      expect(ejectColumn, findsOneWidget);
      final beforeEject = tester.widget<ChallengerEjectColumn>(ejectColumn);
      expect(beforeEject.canEject, isTrue);
      expect(beforeEject.canUndo, isFalse);

      await tester.tap(find.widgetWithText(ElevatedButton, 'Eject\nChallenger'));
      await tester.pumpAndSettle();

      final afterEject = tester
          .widget<ChallengerEjectColumn>(find.byType(ChallengerEjectColumn));
      expect(afterEject.canUndo, isTrue,
          reason: 'undo should become available immediately after an eject');

      await tester.tap(find.widgetWithText(OutlinedButton, 'Undo'));
      await tester.pumpAndSettle();

      final afterUndo = tester
          .widget<ChallengerEjectColumn>(find.byType(ChallengerEjectColumn));
      expect(afterUndo.canUndo, isFalse,
          reason: 'undo buffer should be consumed after restoring');
    });
  });

  group('Game lost / undo loss (no more auto-rotation)', () {
    testWidgets(
        'losing a rally does not rotate the Challenger team, and the '
        'Add Loss / Undo Loss buttons round-trip the counter',
        (tester) async {
      final players = [
        _p('1', 'Alice'), _p('2', 'Bob'), _p('3', 'Charlie'),
        _p('4', 'Diana'), _p('5', 'Eve'), _p('6', 'Frank'),
      ];
      final t = DoghouseTournament(
        id: 'd8',
        name: 'Test Drill',
        totalTime: const Duration(hours: 1),
        playersPerTeam: 2,
        escapePoints: 5,
        lossLimit: 3,
        assignmentMode: DoghouseAssignmentMode.automated,
        status: DoghouseTournamentStatus.inProgress,
        players: players,
        games: const [],
        createdAt: _now,
      );

      await pumpPortrait(
          tester,
          DoghouseScoreboardPage(
            tournament: t,
            existingPlayers: const [],
            existingGroups: const [],
            onChanged: (_) {},
          ));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ElevatedButton, 'Enter Doghouse'));
      await tester.pumpAndSettle();

      // "Doghouse" (not "In Doghouse") badge on the active tile. (The app
      // bar/title also legitimately says "Doghouse", so just assert the old
      // two-word label is gone and the new one-word label is present.)
      expect(find.text('Doghouse'), findsWidgets);
      expect(find.text('In Doghouse'), findsNothing);

      Set<String?> challengerNames() {
        final card = find.ancestor(
            of: find.text('Challengers'), matching: find.byType(Card));
        return tester
            .widgetList<Text>(
                find.descendant(of: card, matching: find.byType(Text)))
            .map((w) => w.data)
            .where((s) => s != 'Challengers')
            .toSet();
      }

      // The "X / lossLimit" counter renders in two places (the narrow Add
      // Loss button and a small badge on the active scoring tile) — assert
      // presence/absence rather than an exact count.
      expect(find.text('0 / 3'), findsWidgets);
      final before = challengerNames();
      expect(before, hasLength(2));

      // Lose a rally, below the loss limit — must NOT touch the Challenger
      // slot anymore (that auto-rotation was removed).
      await tester.tap(find.text('Game\nLost'));
      await tester.pumpAndSettle();

      expect(find.text('1 / 3'), findsWidgets);
      expect(find.text('0 / 3'), findsNothing);
      expect(challengerNames(), before,
          reason: 'the Challenger team must stay fixed across a rally loss '
              'that does not reach the loss limit');

      // Undo Loss brings the counter back down.
      await tester.tap(find.widgetWithText(OutlinedButton, 'Undo\nLoss'));
      await tester.pumpAndSettle();

      expect(find.text('0 / 3'), findsWidgets);
      expect(find.text('1 / 3'), findsNothing);
    });
  });

  group('Editable Match Controls chips', () {
    testWidgets('escape points chip round-trips through its sheet',
        (tester) async {
      final players = [_p('1', 'Alice'), _p('2', 'Bob')];
      final t = DoghouseTournament(
        id: 'd3',
        name: 'Test Drill',
        totalTime: const Duration(hours: 1),
        playersPerTeam: 2,
        escapePoints: 3,
        lossLimit: 3,
        assignmentMode: DoghouseAssignmentMode.manual,
        status: DoghouseTournamentStatus.inProgress,
        players: players,
        games: const [],
        createdAt: _now,
      );

      DoghouseTournament? updated;
      await pumpPortrait(
          tester,
          DoghouseScoreboardPage(
            tournament: t,
            existingPlayers: const [],
            existingGroups: const [],
            onChanged: (v) => updated = v,
          ));
      await tester.pumpAndSettle();

      expect(find.text('3 pt escape'), findsOneWidget);
      await tester.tap(find.text('3 pt escape'));
      await tester.pumpAndSettle();

      // Stepper sheet: tap "+" once, then Save.
      await tester.tap(find.byIcon(Icons.add_rounded));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(updated, isNotNull);
      expect(updated!.escapePoints, 4);
      expect(find.text('4 pt escape'), findsOneWidget);
    });

    testWidgets('loss limit chip round-trips through its sheet',
        (tester) async {
      final players = [_p('1', 'Alice'), _p('2', 'Bob')];
      final t = DoghouseTournament(
        id: 'd4',
        name: 'Test Drill',
        totalTime: const Duration(hours: 1),
        playersPerTeam: 2,
        escapePoints: 3,
        lossLimit: 3,
        assignmentMode: DoghouseAssignmentMode.manual,
        status: DoghouseTournamentStatus.inProgress,
        players: players,
        games: const [],
        createdAt: _now,
      );

      DoghouseTournament? updated;
      await pumpPortrait(
          tester,
          DoghouseScoreboardPage(
            tournament: t,
            existingPlayers: const [],
            existingGroups: const [],
            onChanged: (v) => updated = v,
          ));
      await tester.pumpAndSettle();

      expect(find.text('3 loss limit'), findsOneWidget);
      await tester.tap(find.text('3 loss limit'));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.remove_rounded));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(updated, isNotNull);
      expect(updated!.lossLimit, 2);
      expect(find.text('2 loss limit'), findsOneWidget);
    });

    testWidgets('assignment mode chip opens the mode sheet', (tester) async {
      final players = [_p('1', 'Alice'), _p('2', 'Bob')];
      final t = DoghouseTournament(
        id: 'd5',
        name: 'Test Drill',
        totalTime: const Duration(hours: 1),
        playersPerTeam: 2,
        assignmentMode: DoghouseAssignmentMode.manual,
        status: DoghouseTournamentStatus.inProgress,
        players: players,
        games: const [],
        createdAt: _now,
      );

      await pumpPortrait(
          tester,
          DoghouseScoreboardPage(
            tournament: t,
            existingPlayers: const [],
            existingGroups: const [],
            onChanged: (_) {},
          ));
      await tester.pumpAndSettle();

      expect(find.text('Manual'), findsOneWidget);
      await tester.tap(find.text('Manual'));
      await tester.pumpAndSettle();

      // Sheet opened with the assignment dropdown showing all 3 modes.
      expect(find.byType(DropdownButtonFormField<DoghouseAssignmentMode>),
          findsOneWidget);
    });
  });

  group('Session timer wall-clock persistence', () {
    testWidgets(
        'restores elapsed wall-clock time instead of the stale snapshot',
        (tester) async {
      final players = [_p('1', 'Alice'), _p('2', 'Bob')];
      // Anchored 100s ago with 500s remaining at that point -> live
      // remaining should be ~400s, NOT the stale 500s snapshot. This is
      // exactly the "timer doesn't continue after leaving the scorecard"
      // bug this port fixes.
      final anchor = DateTime.now().subtract(const Duration(seconds: 100));
      final t = DoghouseTournament(
        id: 'd6',
        name: 'Test Drill',
        totalTime: const Duration(hours: 1),
        playersPerTeam: 2,
        assignmentMode: DoghouseAssignmentMode.manual,
        status: DoghouseTournamentStatus.inProgress,
        players: players,
        games: const [],
        createdAt: _now,
        remainingSeconds: 500,
        timerAnchor: anchor,
      );

      DoghouseTournament? updated;
      await pumpPortrait(
          tester,
          DoghouseScoreboardPage(
            tournament: t,
            existingPlayers: const [],
            existingGroups: const [],
            onChanged: (v) => updated = v,
          ));
      // NOT pumpAndSettle(): the timer is now running (autoStart: true) with
      // a real Timer.periodic ticking every second, which would keep
      // scheduling frames forever and never "settle". A couple of bounded
      // pumps are enough to flush the postFrameCallback restoreTimer()
      // schedules.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      final timerState = tester
          .state<ScrambleTimerWidgetState>(find.byType(ScrambleTimerWidget));
      // Live remaining must reflect elapsed wall-clock time (~400s), with
      // slack only for test execution overhead — never the stale 500s.
      expect(timerState.remaining.inSeconds, lessThan(410));
      expect(timerState.remaining.inSeconds, greaterThan(390));
      expect(timerState.timerState, ScrambleTimerState.running);

      // restoreTimer() re-anchors and persists via a post-frame callback.
      expect(updated, isNotNull);
      expect(updated!.remainingSeconds, lessThan(410));
      expect(updated!.timerAnchor, isNotNull);

      // Unmount so the widget's internal Timer.periodic is cancelled in
      // dispose() — otherwise the test framework flags a leaked timer.
      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('a completed tournament does not restore the timer',
        (tester) async {
      final players = [_p('1', 'Alice'), _p('2', 'Bob')];
      final anchor = DateTime.now().subtract(const Duration(seconds: 100));
      final t = DoghouseTournament(
        id: 'd7',
        name: 'Test Drill',
        totalTime: const Duration(hours: 1),
        playersPerTeam: 2,
        assignmentMode: DoghouseAssignmentMode.manual,
        status: DoghouseTournamentStatus.completed,
        players: players,
        games: const [],
        createdAt: _now,
        remainingSeconds: 500,
        timerAnchor: anchor,
      );

      await pumpPortrait(
          tester,
          DoghouseScoreboardPage(
            tournament: t,
            existingPlayers: const [],
            existingGroups: const [],
            onChanged: (_) {},
          ));
      await tester.pumpAndSettle();

      final timerState = tester
          .state<ScrambleTimerWidgetState>(find.byType(ScrambleTimerWidget));
      expect(timerState.remaining.inSeconds, 500);
      expect(timerState.timerState, isNot(ScrambleTimerState.running));
    });
  });
}
