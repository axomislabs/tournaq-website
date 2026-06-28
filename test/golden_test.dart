// Run to generate/update reference images:
//   flutter test test/golden_test.dart --update-goldens
//
// Run to compare against existing reference images:
//   flutter test test/golden_test.dart
//
// Output PNGs land in test/goldens/

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:tournaq/app/app_theme.dart';
import 'package:tournaq/l10n/app_localizations.dart';
import 'package:tournaq/models/doghouse_drill.dart';
import 'package:tournaq/models/game.dart';
import 'package:tournaq/models/game_set.dart';
import 'package:tournaq/models/group.dart';
import 'package:tournaq/models/king_of_the_court_tournament.dart';
import 'package:tournaq/models/ko_bracket_tournament.dart';
import 'package:tournaq/models/player.dart';
import 'package:tournaq/models/player_status.dart';
import 'package:tournaq/models/scramble_tournament.dart';
import 'package:tournaq/models/team.dart';
import 'package:tournaq/pages/administration_page.dart';
import 'package:tournaq/pages/coming_soon_page.dart';
import 'package:tournaq/pages/doghouse_history_page.dart';
import 'package:tournaq/pages/doghouse_scoreboard_page.dart';
import 'package:tournaq/pages/gameplay_history_page.dart';
import 'package:tournaq/pages/games_page.dart';
import 'package:tournaq/pages/group_detail_page.dart';
import 'package:tournaq/pages/groups_page.dart';
import 'package:tournaq/pages/king_of_the_court_history_page.dart';
import 'package:tournaq/pages/ko_bracket_bracket_page.dart';
import 'package:tournaq/pages/ko_bracket_match_page.dart';
import 'package:tournaq/pages/ko_bracket_setup_page.dart';
import 'package:tournaq/pages/landing_page.dart';
import 'package:tournaq/pages/scramble_overview_page.dart';
import 'package:tournaq/pages/scramble_scorecard_page.dart';
import 'package:tournaq/pages/scramble_setup_page.dart';
import 'package:tournaq/pages/scramble_stats_page.dart';
import 'package:tournaq/pages/settings_page.dart';
import 'package:tournaq/pages/team_detail_page.dart';
import 'package:tournaq/pages/teams_page.dart';
import 'package:tournaq/pages/tournament_history_page.dart';
import 'package:tournaq/pages/tournaments_page.dart';
import 'package:tournaq/pages/user_detail_page.dart';
import 'package:tournaq/pages/users_page.dart';
import 'package:tournaq/state/app_state.dart';
import 'package:tournaq/widgets/create_group_sheet.dart';
import 'package:tournaq/widgets/create_player_sheet.dart';
import 'package:tournaq/widgets/create_team_sheet.dart';
import 'package:tournaq/widgets/filter_bar.dart';
import 'package:tournaq/widgets/game_tile.dart';
import 'package:tournaq/widgets/group_picker_sheet.dart';
import 'package:tournaq/widgets/ko_team_editor_sheet.dart';
import 'package:tournaq/widgets/player_picker_sheet.dart';
import 'package:tournaq/widgets/player_pill.dart';
import 'package:tournaq/widgets/quick_start_sheet.dart';
import 'package:tournaq/widgets/scramble_game_tile.dart';
import 'package:tournaq/widgets/scramble_suggestion_card.dart';
import 'package:tournaq/widgets/scramble_timer_widget.dart';
import 'package:tournaq/widgets/team_lineup_editor_sheet.dart';
import 'package:tournaq/widgets/tournament_history_card.dart';
import 'package:tournaq/widgets/tournament_player_row.dart';
import 'package:tournaq/widgets/tournaq_app_bar.dart';

// ── Mock data ─────────────────────────────────────────────────────────────────

final _players = [
  Player(id: 'p1', name: 'Alice Martin'),
  Player(id: 'p2', name: 'Bob Chen'),
  Player(id: 'p3', name: 'Charlie Davis'),
  Player(id: 'p4', name: 'Diana Lee'),
];

final _teams = [
  Team(id: 't1', name: 'Wave Crushers', userIds: ['p1', 'p2']),
  Team(id: 't2', name: 'Sand Storm', userIds: ['p3', 'p4']),
];

final _groups = [
  Group(
    id: 'g1',
    name: 'Beach Club',
    teamIds: ['t1', 't2'],
    playerIds: ['p1', 'p2', 'p3', 'p4'],
  ),
];

final _games = [
  Game(
    id: 'game1',
    team1Id: 't1',
    team2Id: 't2',
    team1Name: 'Wave Crushers',
    team2Name: 'Sand Storm',
    round: 1,
    status: GameStatus.completed,
    source: GameSource.quickLocal,
    matchFormat: MatchFormat.oneSet,
    sets: [
      GameSet(id: 'set1', setNumber: 1, score1: 21, score2: 15, isCompleted: true),
    ],
    matchWinnerTeamId: 't1',
  ),
];

final _appState = AppState(
  players: _players,
  teams: _teams,
  games: _games,
  groups: _groups,
);

// Scramble tournament mock data
final _now = DateTime(2026, 6, 1, 10, 0);

final _scramblePlayers = [
  ScramblePlayer(id: 'sp1', name: 'Alice', source: ScramblePlayerSource.existing, appUserId: 'p1'),
  ScramblePlayer(id: 'sp2', name: 'Bob', source: ScramblePlayerSource.existing, appUserId: 'p2'),
  ScramblePlayer(id: 'sp3', name: 'Charlie', source: ScramblePlayerSource.existing, appUserId: 'p3'),
  ScramblePlayer(id: 'sp4', name: 'Diana', source: ScramblePlayerSource.existing, appUserId: 'p4'),
];

final _scrambleRound = ScrambleRound(
  id: 'r1',
  roundNumber: 1,
  scheduledStartTime: _now,
  matchDuration: const Duration(minutes: 12),
  breakDuration: const Duration(minutes: 3),
  actualStartTime: _now,
);

final _scrambleGame = ScrambleGame(
  id: 'sg1',
  roundId: 'r1',
  courtNumber: 1,
  sideAPlayerIds: ['sp1', 'sp2'],
  sideBPlayerIds: ['sp3', 'sp4'],
  sideAScore: 7,
  sideBScore: 5,
  status: ScrambleGameStatus.inProgress,
);

final _scrambleTournament = ScrambleTournament(
  id: 'st1',
  name: 'Beach Scramble',
  totalAvailableTime: const Duration(hours: 2),
  matchDuration: const Duration(minutes: 12),
  breakDuration: const Duration(minutes: 3),
  courtCount: 1,
  playersPerTeam: 2,
  startTime: _now,
  status: ScrambleTournamentStatus.inProgress,
  players: _scramblePlayers,
  rounds: [_scrambleRound],
  games: [_scrambleGame],
  createdAt: _now,
);

// King of the Court mock data
final _kotcPlayers = [
  KotcPlayer(id: 'kp1', name: 'Alice', source: KotcPlayerSource.existing, appUserId: 'p1'),
  KotcPlayer(id: 'kp2', name: 'Bob', source: KotcPlayerSource.existing, appUserId: 'p2'),
  KotcPlayer(id: 'kp3', name: 'Charlie', source: KotcPlayerSource.existing),
  KotcPlayer(id: 'kp4', name: 'Diana', source: KotcPlayerSource.existing),
];

final _kotcGames = [
  KotcGame(
    id: 'kg1',
    playerIds: ['kp1', 'kp2'],
    points: 15,
    gamesWon: 2,
    startTime: _now,
    endTime: _now.add(const Duration(minutes: 10)),
  ),
];

final _kotcTournament = KingOfTheCourtTournament(
  id: 'kotc1',
  name: 'King of the Court',
  totalTime: const Duration(hours: 1),
  playersPerTeam: 2,
  courtCount: 1,
  status: KotcTournamentStatus.inProgress,
  players: _kotcPlayers,
  games: _kotcGames,
  createdAt: _now,
);

// Doghouse mock data
final _doghousePlayers = [
  DoghousePlayer(id: 'dp1', name: 'Alice', source: DoghousePlayerSource.existing, appUserId: 'p1'),
  DoghousePlayer(id: 'dp2', name: 'Bob', source: DoghousePlayerSource.existing, appUserId: 'p2'),
  DoghousePlayer(id: 'dp3', name: 'Charlie', source: DoghousePlayerSource.existing),
  DoghousePlayer(id: 'dp4', name: 'Diana', source: DoghousePlayerSource.existing),
];

final _doghouseTournament = DoghouseTournament(
  id: 'dh1',
  name: 'Doghouse Drill',
  totalTime: const Duration(hours: 1),
  playersPerTeam: 2,
  escapePoints: 3,
  lossLimit: 3,
  status: DoghouseTournamentStatus.inProgress,
  players: _doghousePlayers,
  games: [],
  createdAt: _now,
);

// KO bracket mock data
final _koTeams = [
  KoTeam(
    id: 'kt1',
    name: 'Wave Crushers',
    hubTeamId: 't1',
    players: [
      KoPlayerSnapshot(appPlayerId: 'p1', name: 'Alice Martin', skillRating: 7),
      KoPlayerSnapshot(appPlayerId: 'p2', name: 'Bob Chen', skillRating: 5),
    ],
  ),
  KoTeam(
    id: 'kt2',
    name: 'Sand Storm',
    hubTeamId: 't2',
    players: [
      KoPlayerSnapshot(appPlayerId: 'p3', name: 'Charlie Davis', skillRating: 6),
      KoPlayerSnapshot(appPlayerId: 'p4', name: 'Diana Lee', skillRating: 4),
    ],
  ),
];

final _koMatch = KoMatch(
  id: 'm1',
  round: 1,
  matchIndex: 0,
  team1Id: 'kt1',
  team2Id: 'kt2',
  sets: [KoSet(score1: 5, score2: 3)],
  status: KoMatchStatus.inProgress,
);

final _koTournament = KoBracketTournament(
  id: 'kob1',
  name: 'Beach Open',
  playersPerSide: 2,
  courtCount: 1,
  defaultFormat: const KoRoundFormat(setsPerGame: 1, pointsPerSet: 21),
  teams: _koTeams,
  matches: [_koMatch],
  status: KoBracketStatus.inProgress,
  createdAt: _now,
);

// ── Wrapper ───────────────────────────────────────────────────────────────────
// Use the real app theme + all localization delegates so screenshots match
// exactly what users see.

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

// iPhone 14 Pro width, tall enough to show a full sheet without scrolling.
const _sz = Size(390, 720);
// Full page size
const _pageSz = Size(390, 844);

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  // ── QuickStartSheet ────────────────────────────────────────────────────────

  group('QuickStartSheet', () {
    testGoldens('format_step', (tester) async {
      await tester.pumpWidgetBuilder(
        QuickStartSheet(appState: _appState),
        wrapper: _wrap,
        surfaceSize: _sz,
      );
      await screenMatchesGolden(tester, 'quick_start__format_step');
    });

    testGoldens('team_step', (tester) async {
      await tester.pumpWidgetBuilder(
        QuickStartSheet(appState: _appState),
        wrapper: _wrap,
        surfaceSize: _sz,
      );
      // Advance to team picker by selecting "1 Set" format
      await tester.tap(find.byIcon(Icons.filter_1_rounded));
      await tester.pumpAndSettle();
      await screenMatchesGolden(tester, 'quick_start__team_step');
    });

    testGoldens('team_step_empty_hub', (tester) async {
      await tester.pumpWidgetBuilder(
        QuickStartSheet(appState: const AppState()),
        wrapper: _wrap,
        surfaceSize: _sz,
      );
      await tester.tap(find.byIcon(Icons.filter_1_rounded));
      await tester.pumpAndSettle();
      await screenMatchesGolden(tester, 'quick_start__team_step_empty_hub');
    });
  });

  // ── KoTeamEditorSheet ──────────────────────────────────────────────────────

  group('KoTeamEditorSheet', () {
    // hubTeamId: 'stub' → initState reads widget.team.name instead of
    // calling TeamNameGenerator.randomName(), keeping screenshots deterministic.

    const _emptyTeam = KoTeam(
      id: 'test',
      name: 'Beach Blitz',
      hubTeamId: 'stub',
      players: [
        KoPlayerSnapshot(appPlayerId: '', name: 'Player 1'),
        KoPlayerSnapshot(appPlayerId: '', name: 'Player 2'),
      ],
    );

    const _filledTeam = KoTeam(
      id: 'test',
      name: 'Wave Crushers',
      hubTeamId: 'stub',
      players: [
        KoPlayerSnapshot(appPlayerId: 'p1', name: 'Alice Martin', skillRating: 7),
        KoPlayerSnapshot(appPlayerId: 'p2', name: 'Bob Chen', skillRating: 5),
      ],
    );

    // For choice mode we need hubTeamId == null so the choice screen shows.
    // The random name generated in initState is never displayed in choice mode.
    const _choiceTeam = KoTeam(
      id: 'test',
      name: 'Any Name',
      players: [
        KoPlayerSnapshot(appPlayerId: '', name: 'Player 1'),
        KoPlayerSnapshot(appPlayerId: '', name: 'Player 2'),
      ],
    );

    KoTeamEditorSheet _sheet(KoTeam team, {bool startInCreateMode = false}) =>
        KoTeamEditorSheet(
          team: team,
          existingPlayers: _players,
          existingTeams: _teams,
          existingGroups: _groups,
          generationMode: KoBracketGenerationMode.random,
          startInCreateMode: startInCreateMode,
          onCreatePlayer: (name) => Player(id: 'new', name: name),
          onCreateTeam: (name, ids) => 'new-id',
          onSave: (_) {},
        );

    testGoldens('choice_mode', (tester) async {
      await tester.pumpWidgetBuilder(
        _sheet(_choiceTeam),
        wrapper: _wrap,
        surfaceSize: _sz,
      );
      await screenMatchesGolden(tester, 'ko_team_editor__choice_mode');
    });

    testGoldens('create_mode_empty', (tester) async {
      await tester.pumpWidgetBuilder(
        _sheet(_emptyTeam, startInCreateMode: true),
        wrapper: _wrap,
        surfaceSize: _sz,
      );
      await screenMatchesGolden(tester, 'ko_team_editor__create_mode_empty');
    });

    testGoldens('create_mode_filled', (tester) async {
      await tester.pumpWidgetBuilder(
        _sheet(_filledTeam, startInCreateMode: true),
        wrapper: _wrap,
        surfaceSize: _sz,
      );
      await screenMatchesGolden(tester, 'ko_team_editor__create_mode_filled');
    });
  });

  // ── KoSlotPickerSheet ──────────────────────────────────────────────────────

  group('KoSlotPickerSheet', () {
    KoSlotPickerSheet _sheet(KoPlayerSnapshot current) => KoSlotPickerSheet(
          slotIndex: 0,
          currentPlayer: current,
          existingPlayers: _players,
          existingGroups: _groups,
          onCreatePlayer: (name) => Player(id: 'new', name: name),
          onPick: (_) {},
          onClear: () {},
        );

    testGoldens('empty_slot', (tester) async {
      await tester.pumpWidgetBuilder(
        _sheet(const KoPlayerSnapshot(appPlayerId: '', name: 'Player 1')),
        wrapper: _wrap,
        surfaceSize: _sz,
      );
      await screenMatchesGolden(tester, 'ko_slot_picker__empty_slot');
    });

    testGoldens('linked_slot', (tester) async {
      await tester.pumpWidgetBuilder(
        _sheet(const KoPlayerSnapshot(
          appPlayerId: 'p1',
          name: 'Alice Martin',
          skillRating: 7,
        )),
        wrapper: _wrap,
        surfaceSize: _sz,
      );
      await screenMatchesGolden(tester, 'ko_slot_picker__linked_slot');
    });
  });

  // ── Pages — simple StatelessWidget / no external service calls ─────────────

  group('ComingSoonPage', () {
    testGoldens('default', (tester) async {
      await tester.pumpWidgetBuilder(
        const ComingSoonPage(
          title: 'League Mode',
          shortDescription: 'Track standings across multiple weeks.',
        ),
        wrapper: _wrap,
        surfaceSize: _pageSz,
      );
      await screenMatchesGolden(tester, 'coming_soon__default');
    });
  });

  group('AdministrationPage', () {
    testGoldens('default', (tester) async {
      await tester.pumpWidgetBuilder(
        AdministrationPage(
          appState: _appState,
          onAppStateChanged: (_) {},
        ),
        wrapper: _wrap,
        surfaceSize: _pageSz,
      );
      await screenMatchesGolden(tester, 'administration__default');
    });
  });

  group('LandingPage', () {
    testGoldens('default', (tester) async {
      await tester.pumpWidgetBuilder(
        LandingPage(
          appState: _appState,
          onAppStateChanged: (_) {},
        ),
        wrapper: _wrap,
        surfaceSize: _pageSz,
      );
      await tester.pumpAndSettle();
      await screenMatchesGolden(tester, 'landing__default');
    });
  });

  // SettingsPage calls LocaleService.loadLocale() in build(), which accesses
  // a Hive box that is not initialized in tests. Skipped to avoid HiveError.
  // group('SettingsPage', () { ... });

  group('GamesPage', () {
    testGoldens('with_games', (tester) async {
      await tester.pumpWidgetBuilder(
        GamesPage(
          appState: _appState,
          onAppStateChanged: (_) {},
        ),
        wrapper: _wrap,
        surfaceSize: _pageSz,
      );
      await screenMatchesGolden(tester, 'games__with_games');
    });

    testGoldens('empty', (tester) async {
      await tester.pumpWidgetBuilder(
        GamesPage(
          appState: const AppState(),
          onAppStateChanged: (_) {},
        ),
        wrapper: _wrap,
        surfaceSize: _pageSz,
      );
      await screenMatchesGolden(tester, 'games__empty');
    });
  });

  group('GroupsPage', () {
    testGoldens('with_groups', (tester) async {
      await tester.pumpWidgetBuilder(
        GroupsPage(
          appState: _appState,
          onAppStateChanged: (_) {},
        ),
        wrapper: _wrap,
        surfaceSize: _pageSz,
      );
      await screenMatchesGolden(tester, 'groups__with_groups');
    });

    testGoldens('empty', (tester) async {
      await tester.pumpWidgetBuilder(
        GroupsPage(
          appState: const AppState(),
          onAppStateChanged: (_) {},
        ),
        wrapper: _wrap,
        surfaceSize: _pageSz,
      );
      await screenMatchesGolden(tester, 'groups__empty');
    });
  });

  group('GroupDetailPage', () {
    testGoldens('with_group', (tester) async {
      await tester.pumpWidgetBuilder(
        GroupDetailPage(
          appState: _appState,
          onAppStateChanged: (_) {},
          groupId: 'g1',
        ),
        wrapper: _wrap,
        surfaceSize: _pageSz,
      );
      await screenMatchesGolden(tester, 'group_detail__with_group');
    });
  });

  group('TeamsPage', () {
    testGoldens('with_teams', (tester) async {
      await tester.pumpWidgetBuilder(
        TeamsPage(
          appState: _appState,
          onAppStateChanged: (_) {},
        ),
        wrapper: _wrap,
        surfaceSize: _pageSz,
      );
      await screenMatchesGolden(tester, 'teams__with_teams');
    });

    testGoldens('empty', (tester) async {
      await tester.pumpWidgetBuilder(
        TeamsPage(
          appState: const AppState(),
          onAppStateChanged: (_) {},
        ),
        wrapper: _wrap,
        surfaceSize: _pageSz,
      );
      await screenMatchesGolden(tester, 'teams__empty');
    });
  });

  group('TeamDetailPage', () {
    testGoldens('with_team', (tester) async {
      await tester.pumpWidgetBuilder(
        TeamDetailPage(
          appState: _appState,
          onAppStateChanged: (_) {},
          teamId: 't1',
        ),
        wrapper: _wrap,
        surfaceSize: _pageSz,
      );
      await screenMatchesGolden(tester, 'team_detail__with_team');
    });
  });

  group('UsersPage', () {
    testGoldens('with_players', (tester) async {
      await tester.pumpWidgetBuilder(
        UsersPage(
          appState: _appState,
          onAppStateChanged: (_) {},
        ),
        wrapper: _wrap,
        surfaceSize: _pageSz,
      );
      await screenMatchesGolden(tester, 'users__with_players');
    });

    testGoldens('empty', (tester) async {
      await tester.pumpWidgetBuilder(
        UsersPage(
          appState: const AppState(),
          onAppStateChanged: (_) {},
        ),
        wrapper: _wrap,
        surfaceSize: _pageSz,
      );
      await screenMatchesGolden(tester, 'users__empty');
    });
  });

  group('UserDetailPage', () {
    testGoldens('with_player', (tester) async {
      await tester.pumpWidgetBuilder(
        UserDetailPage(
          appState: _appState,
          onAppStateChanged: (_) {},
          userId: 'p1',
        ),
        wrapper: _wrap,
        surfaceSize: _pageSz,
      );
      await screenMatchesGolden(tester, 'user_detail__with_player');
    });
  });

  group('GameplayHistoryPage', () {
    testGoldens('with_entries', (tester) async {
      await tester.pumpWidgetBuilder(
        GameplayHistoryPage(
          team1Name: 'Wave Crushers',
          team2Name: 'Sand Storm',
          team1Players: ['Alice', 'Bob'],
          team2Players: ['Charlie', 'Diana'],
          entries: [
            const GameHistoryEntry(
              isTeam1Score: true,
              team1Score: 1,
              team2Score: 0,
              setIndex: 0,
              targetPoints: 21,
              isTeam1Serving: true,
              servingPlayerIndex: 0,
              serviceChanged: false,
            ),
            const GameHistoryEntry(
              isTeam1Score: false,
              team1Score: 1,
              team2Score: 1,
              setIndex: 0,
              targetPoints: 21,
              isTeam1Serving: false,
              servingPlayerIndex: 0,
              serviceChanged: true,
            ),
            const GameHistoryEntry(
              isTeam1Score: true,
              team1Score: 21,
              team2Score: 15,
              setIndex: 0,
              targetPoints: 21,
              isTeam1Serving: true,
              servingPlayerIndex: 1,
              serviceChanged: false,
            ),
          ],
        ),
        wrapper: _wrap,
        surfaceSize: _pageSz,
      );
      await screenMatchesGolden(tester, 'gameplay_history__with_entries');
    });

    testGoldens('empty', (tester) async {
      await tester.pumpWidgetBuilder(
        const GameplayHistoryPage(
          team1Name: 'Wave Crushers',
          team2Name: 'Sand Storm',
          team1Players: ['Alice', 'Bob'],
          team2Players: ['Charlie', 'Diana'],
          entries: [],
        ),
        wrapper: _wrap,
        surfaceSize: _pageSz,
      );
      await screenMatchesGolden(tester, 'gameplay_history__empty');
    });
  });

  // ── TournamentsPage — calls storage services in initState (Hive) ───────────
  // Hive is not initialized in tests so loadAll() returns [] — safe to render.
  group('TournamentsPage', () {
    testGoldens('default', (tester) async {
      await tester.pumpWidgetBuilder(
        TournamentsPage(
          appState: _appState,
          onAppStateChanged: (_) {},
        ),
        wrapper: _wrap,
        surfaceSize: _pageSz,
      );
      await tester.pumpAndSettle();
      await screenMatchesGolden(tester, 'tournaments__default');
    });
  });

  // TournamentHistoryPage — calls Hive storage in initState; returns [] safely.
  group('TournamentHistoryPage', () {
    testGoldens('empty', (tester) async {
      await tester.pumpWidgetBuilder(
        TournamentHistoryPage(
          existingPlayers: _players,
        ),
        wrapper: _wrap,
        surfaceSize: _pageSz,
      );
      await tester.pumpAndSettle();
      await screenMatchesGolden(tester, 'tournament_history__empty');
    });
  });

  // ── Scramble pages ─────────────────────────────────────────────────────────

  // ScrambleSetupPage — no external services in initState
  group('ScrambleSetupPage', () {
    testGoldens('default', (tester) async {
      await tester.pumpWidgetBuilder(
        ScrambleSetupPage(
          existingPlayers: _players,
          existingGroups: _groups,
          onCreated: (_) {},
          onCreatePlayer: (name) => Player(id: 'new', name: name),
        ),
        wrapper: _wrap,
        surfaceSize: _pageSz,
      );
      await tester.pumpAndSettle();
      await screenMatchesGolden(tester, 'scramble_setup__default');
    });
  });

  // ScrambleOverviewPage — calls storage in _update but not in initState
  group('ScrambleOverviewPage', () {
    testGoldens('in_progress', (tester) async {
      await tester.pumpWidgetBuilder(
        ScrambleOverviewPage(
          tournament: _scrambleTournament,
          onChanged: (_) {},
        ),
        wrapper: _wrap,
        surfaceSize: _pageSz,
      );
      await tester.pumpAndSettle();
      await screenMatchesGolden(tester, 'scramble_overview__in_progress');
    });
  });

  group('ScrambleStatsPage', () {
    testGoldens('default', (tester) async {
      await tester.pumpWidgetBuilder(
        ScrambleStatsPage(tournament: _scrambleTournament),
        wrapper: _wrap,
        surfaceSize: _pageSz,
      );
      await screenMatchesGolden(tester, 'scramble_stats__default');
    });
  });

  // ScrambleScorecardPage — stateful but no external service calls in initState
  group('ScrambleScorecardPage', () {
    testGoldens('in_progress', (tester) async {
      await tester.pumpWidgetBuilder(
        ScrambleScorecardPage(
          tournament: _scrambleTournament,
          game: _scrambleGame,
          round: _scrambleRound,
          onChanged: (_) {},
        ),
        wrapper: _wrap,
        surfaceSize: _pageSz,
      );
      await tester.pumpAndSettle();
      await screenMatchesGolden(tester, 'scramble_scorecard__in_progress');
    });
  });

  // ── Doghouse pages ─────────────────────────────────────────────────────────

  group('DoghouseHistoryPage', () {
    testGoldens('empty', (tester) async {
      await tester.pumpWidgetBuilder(
        DoghouseHistoryPage(tournament: _doghouseTournament),
        wrapper: _wrap,
        surfaceSize: _pageSz,
      );
      await screenMatchesGolden(tester, 'doghouse_history__empty');
    });
  });

  // DoghouseScoreboardPage — stateful, no Hive in initState
  group('DoghouseScoreboardPage', () {
    testGoldens('in_progress', (tester) async {
      await tester.pumpWidgetBuilder(
        DoghouseScoreboardPage(
          tournament: _doghouseTournament,
          existingPlayers: _players,
          existingGroups: _groups,
          onChanged: (_) {},
        ),
        wrapper: _wrap,
        surfaceSize: _pageSz,
      );
      await tester.pumpAndSettle();
      await screenMatchesGolden(tester, 'doghouse_scoreboard__in_progress');
    });
  });

  // ── King of the Court pages ────────────────────────────────────────────────

  group('KingOfTheCourtHistoryPage', () {
    testGoldens('with_games', (tester) async {
      await tester.pumpWidgetBuilder(
        KingOfTheCourtHistoryPage(tournament: _kotcTournament),
        wrapper: _wrap,
        surfaceSize: _pageSz,
      );
      await screenMatchesGolden(tester, 'kotc_history__with_games');
    });
  });

  // ── KO Bracket pages ───────────────────────────────────────────────────────

  // KoBracketSetupPage — no Hive calls in initState
  group('KoBracketSetupPage', () {
    testGoldens('default', (tester) async {
      await tester.pumpWidgetBuilder(
        KoBracketSetupPage(
          existingPlayers: _players,
          existingTeams: _teams,
          existingGroups: _groups,
          onCreatePlayer: (name) => Player(id: 'new', name: name),
          onCreateTeam: (name, ids) => 'new-id',
          onCreated: (_) {},
        ),
        wrapper: _wrap,
        surfaceSize: _pageSz,
      );
      await tester.pumpAndSettle();
      await screenMatchesGolden(tester, 'ko_bracket_setup__default');
    });
  });

  // KoBracketBracketPage — calls KoBracketStorageService.loadAll() in initState
  // (Hive not initialized → returns []) so safe to render.
  group('KoBracketBracketPage', () {
    testGoldens('with_tournament', (tester) async {
      await tester.pumpWidgetBuilder(
        KoBracketBracketPage(
          tournament: _koTournament,
          onChanged: (_) {},
          existingPlayers: _players,
          existingTeams: _teams,
          existingGroups: _groups,
          onCreatePlayer: (name) => Player(id: 'new', name: name),
          onCreateTeam: (name, ids) => 'new-id',
        ),
        wrapper: _wrap,
        surfaceSize: _pageSz,
      );
      await tester.pumpAndSettle();
      await screenMatchesGolden(tester, 'ko_bracket_bracket__with_tournament');
    });
  });

  // KoBracketMatchPage — requires a match ID that exists in the tournament
  group('KoBracketMatchPage', () {
    testGoldens('in_progress', (tester) async {
      await tester.pumpWidgetBuilder(
        KoBracketMatchPage(
          tournament: _koTournament,
          matchId: 'm1',
          onChanged: (_) {},
        ),
        wrapper: _wrap,
        surfaceSize: _pageSz,
      );
      await tester.pumpAndSettle();
      await screenMatchesGolden(tester, 'ko_bracket_match__in_progress');
    });
  });

  // ── Widgets ────────────────────────────────────────────────────────────────

  group('TournaQAppBar', () {
    testGoldens('title_only', (tester) async {
      await tester.pumpWidgetBuilder(
        const Scaffold(
          appBar: TournaQAppBar(title: 'TournaQ'),
          body: SizedBox.shrink(),
        ),
        wrapper: _wrap,
        surfaceSize: _pageSz,
      );
      await screenMatchesGolden(tester, 'tournaq_app_bar__title_only');
    });

    testGoldens('with_subtitle', (tester) async {
      await tester.pumpWidgetBuilder(
        const Scaffold(
          appBar: TournaQAppBar(title: 'Beach Open', subtitle: 'Bracket View'),
          body: SizedBox.shrink(),
        ),
        wrapper: _wrap,
        surfaceSize: _pageSz,
      );
      await screenMatchesGolden(tester, 'tournaq_app_bar__with_subtitle');
    });
  });

  group('GameTile', () {
    testGoldens('completed_game', (tester) async {
      await tester.pumpWidgetBuilder(
        GameTile(
          game: _games.first,
          appState: _appState,
          onScoreTap: () {},
          onDeleteTap: () {},
        ),
        wrapper: _wrap,
        surfaceSize: const Size(390, 200),
      );
      await screenMatchesGolden(tester, 'game_tile__completed_game');
    });
  });

  group('ScrambleGameTile', () {
    testGoldens('in_progress', (tester) async {
      await tester.pumpWidgetBuilder(
        ScrambleGameTile(
          game: _scrambleGame,
          round: _scrambleRound,
          tournament: _scrambleTournament,
        ),
        wrapper: _wrap,
        surfaceSize: const Size(390, 140),
      );
      await screenMatchesGolden(tester, 'scramble_game_tile__in_progress');
    });
  });

  group('ScrambleSuggestionCard', () {
    testGoldens('info', (tester) async {
      await tester.pumpWidgetBuilder(
        const ScrambleSuggestionCard(
          suggestion: ScrambleSuggestion(
            type: ScrambleSuggestionType.largeGroup,
            message: 'You have 8 players — consider adding a second court.',
            actionLabel: 'Fix',
          ),
        ),
        wrapper: _wrap,
        surfaceSize: const Size(390, 100),
      );
      await screenMatchesGolden(tester, 'scramble_suggestion_card__info');
    });

    testGoldens('blocking', (tester) async {
      await tester.pumpWidgetBuilder(
        const ScrambleSuggestionCard(
          suggestion: ScrambleSuggestion(
            type: ScrambleSuggestionType.adjustPlayerCount,
            message: 'Not enough players to fill one court.',
            isBlocking: true,
          ),
        ),
        wrapper: _wrap,
        surfaceSize: const Size(390, 100),
      );
      await screenMatchesGolden(tester, 'scramble_suggestion_card__blocking');
    });
  });

  group('ScrambleTimerWidget', () {
    testGoldens('countdown_idle', (tester) async {
      await tester.pumpWidgetBuilder(
        const ScrambleTimerWidget(
          initial: Duration(minutes: 12),
          mode: ScrambleTimerMode.countdown,
        ),
        wrapper: _wrap,
        surfaceSize: const Size(390, 200),
      );
      await screenMatchesGolden(tester, 'scramble_timer__countdown_idle');
    });

    testGoldens('compact', (tester) async {
      await tester.pumpWidgetBuilder(
        const ScrambleTimerWidget(
          initial: Duration(minutes: 3),
          mode: ScrambleTimerMode.countup,
          compact: true,
        ),
        wrapper: _wrap,
        surfaceSize: const Size(390, 80),
      );
      await screenMatchesGolden(tester, 'scramble_timer__compact');
    });
  });

  group('PlayerPill', () {
    testGoldens('serving', (tester) async {
      await tester.pumpWidgetBuilder(
        const PlayerPill(
          name: 'Alice Martin',
          isServing: true,
          activeColor: Colors.amber,
        ),
        wrapper: _wrap,
        surfaceSize: const Size(200, 50),
      );
      await screenMatchesGolden(tester, 'player_pill__serving');
    });

    testGoldens('not_serving', (tester) async {
      await tester.pumpWidgetBuilder(
        const PlayerPill(
          name: 'Bob Chen',
          isServing: false,
          activeColor: Colors.green,
        ),
        wrapper: _wrap,
        surfaceSize: const Size(200, 50),
      );
      await screenMatchesGolden(tester, 'player_pill__not_serving');
    });
  });

  group('TournamentHistoryCard', () {
    testGoldens('active', (tester) async {
      await tester.pumpWidgetBuilder(
        TournamentHistoryCard(
          name: 'Beach Scramble',
          typeLabel: 'Social Scramble',
          typeColor: Colors.amber,
          typeIcon: Icons.shuffle_rounded,
          dateLabel: 'Jun 1, 2026',
          statusLabel: 'In Progress',
          isActive: true,
          stats: ['4 players', '1 round', '2/4 games'],
          onTap: () {},
        ),
        wrapper: _wrap,
        surfaceSize: const Size(390, 140),
      );
      await screenMatchesGolden(tester, 'tournament_history_card__active');
    });

    testGoldens('completed', (tester) async {
      await tester.pumpWidgetBuilder(
        TournamentHistoryCard(
          name: 'Beach Open',
          typeLabel: 'KO Bracket',
          typeColor: Colors.blue,
          typeIcon: Icons.emoji_events_rounded,
          dateLabel: 'May 15, 2026',
          statusLabel: 'Completed',
          isActive: false,
          stats: ['4 teams', '3 rounds'],
          onTap: () {},
          onDeleteTap: () {},
        ),
        wrapper: _wrap,
        surfaceSize: const Size(390, 140),
      );
      await screenMatchesGolden(tester, 'tournament_history_card__completed');
    });
  });

  group('TournamentPlayerRow', () {
    testGoldens('active_on_court', (tester) async {
      await tester.pumpWidgetBuilder(
        const TournamentPlayerRow(
          name: 'Alice Martin',
          status: PlayerStatus.active,
          statsLine: '3g · 12pts',
          isOnCourt: true,
          showDisabledActions: true,
        ),
        wrapper: _wrap,
        surfaceSize: const Size(390, 70),
      );
      await screenMatchesGolden(tester, 'tournament_player_row__active_on_court');
    });

    testGoldens('ejected', (tester) async {
      await tester.pumpWidgetBuilder(
        const TournamentPlayerRow(
          name: 'Bob Chen',
          status: PlayerStatus.ejected,
          statsLine: '1g · 5pts',
        ),
        wrapper: _wrap,
        surfaceSize: const Size(390, 70),
      );
      await screenMatchesGolden(tester, 'tournament_player_row__ejected');
    });
  });

  group('FilterBar', () {
    testGoldens('empty', (tester) async {
      await tester.pumpWidgetBuilder(
        FilterBar(
          searchController: TextEditingController(),
          groups: [
            FilterGroup(
              label: 'Format',
              icon: Icons.sports_volleyball_rounded,
              items: const [
                (id: 'scramble', name: 'Social Scramble'),
                (id: 'kotc', name: 'King of the Court'),
              ],
              selectedIds: const {},
              onToggle: (_, __) {},
            ),
          ],
          onClearAll: () {},
        ),
        wrapper: _wrap,
        surfaceSize: const Size(390, 180),
      );
      await screenMatchesGolden(tester, 'filter_bar__empty');
    });

    testGoldens('with_selection', (tester) async {
      await tester.pumpWidgetBuilder(
        FilterBar(
          searchController: TextEditingController(text: 'beach'),
          groups: [
            FilterGroup(
              label: 'Format',
              icon: Icons.sports_volleyball_rounded,
              items: const [
                (id: 'scramble', name: 'Social Scramble'),
                (id: 'kotc', name: 'King of the Court'),
              ],
              selectedIds: const {'scramble'},
              onToggle: (_, __) {},
            ),
          ],
          onClearAll: () {},
        ),
        wrapper: _wrap,
        surfaceSize: const Size(390, 180),
      );
      await screenMatchesGolden(tester, 'filter_bar__with_selection');
    });
  });

  group('GroupPickerSheet', () {
    testGoldens('with_groups', (tester) async {
      await tester.pumpWidgetBuilder(
        GroupPickerSheet(
          groups: _groups,
          selectedId: null,
        ),
        wrapper: _wrap,
        surfaceSize: _sz,
      );
      await screenMatchesGolden(tester, 'group_picker_sheet__with_groups');
    });
  });

  group('PlayerPickerSheet', () {
    testGoldens('default', (tester) async {
      await tester.pumpWidgetBuilder(
        PlayerPickerSheet(
          title: 'Add Players',
          subtitle: 'Pick from your roster or create new',
          existingPlayers: _players,
          alreadyInIds: const {},
          nameHint: 'e.g. John Smith',
          onCreateByName: (name) async => true,
          onAddExisting: (id, name) async => false,
          existingGroups: _groups,
        ),
        wrapper: _wrap,
        surfaceSize: _sz,
      );
      await screenMatchesGolden(tester, 'player_picker_sheet__default');
    });
  });

  group('TeamLineupEditorSheet', () {
    testGoldens('default', (tester) async {
      await tester.pumpWidgetBuilder(
        TeamLineupEditorSheet(
          teamName: 'Wave Crushers',
          activeNames: ['Alice Martin', 'Bob Chen'],
          benchNames: [],
          onSave: (_, __) {},
        ),
        wrapper: _wrap,
        surfaceSize: _sz,
      );
      await screenMatchesGolden(tester, 'team_lineup_editor__default');
    });

    testGoldens('with_bench', (tester) async {
      await tester.pumpWidgetBuilder(
        TeamLineupEditorSheet(
          teamName: 'Sand Storm',
          activeNames: ['Charlie Davis', 'Diana Lee'],
          benchNames: ['Eve Wilson'],
          onSave: (_, __) {},
        ),
        wrapper: _wrap,
        surfaceSize: _sz,
      );
      await screenMatchesGolden(tester, 'team_lineup_editor__with_bench');
    });
  });

  group('CreatePlayerSheet', () {
    testGoldens('default', (tester) async {
      await tester.pumpWidgetBuilder(
        CreatePlayerSheet(appState: _appState),
        wrapper: _wrap,
        surfaceSize: _sz,
      );
      await screenMatchesGolden(tester, 'create_player_sheet__default');
    });
  });

  group('CreateTeamSheet', () {
    testGoldens('default', (tester) async {
      await tester.pumpWidgetBuilder(
        CreateTeamSheet(appState: _appState),
        wrapper: _wrap,
        surfaceSize: _sz,
      );
      await screenMatchesGolden(tester, 'create_team_sheet__default');
    });
  });

  group('CreateGroupSheet', () {
    testGoldens('default', (tester) async {
      await tester.pumpWidgetBuilder(
        CreateGroupSheet(appState: _appState),
        wrapper: _wrap,
        surfaceSize: _sz,
      );
      await screenMatchesGolden(tester, 'create_group_sheet__default');
    });
  });
}
