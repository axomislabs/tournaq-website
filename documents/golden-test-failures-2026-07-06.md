# Pre-existing `flutter test` failures (found 2026-07-06)

## Context

While fixing the Social Scramble player-pairing bug (see the `_selectActiveIndices`/
`_formCourts` changes in `lib/services/scramble_service.dart`), `flutter test` was
run to check for regressions. Two files failed to even **compile**:

- `test/widget_test.dart` — imported `package:tournamaster/...`, a stale package
  name from before the project was renamed to `tournaq`.
- `test/golden_test.dart:155` — passed `status: ScrambleTournamentStatus.inProgress`
  to the `ScrambleTournament` constructor, but `status` is now a computed getter
  (derived from `games`), not a constructor parameter.

Both were fixed (trivial: corrected the import path; deleted the stale `status:`
argument, since the mock game already has `status: ScrambleGameStatus.inProgress`
which drives the computed tournament status anyway).

Once the suite could compile and run, **19 tests in `test/golden_test.dart` fail**.
These were confirmed **unrelated to the scramble fix** by running the suite via
`git stash` with and without the scramble changes — the exact same 19 test names
fail identically either way. They are pre-existing and were not investigated
further; this document is a snapshot to pick back up later.

Full suite command: `flutter test test/golden_test.dart`

---

## Category A — Golden image pixel-diff mismatches (11 tests)

The rendered widget no longer matches the reference PNG in `test/goldens/`.
Diff percentages/pixel counts as measured on this machine
(macOS / Darwin 25.5.0) — likely font-rendering or Flutter-SDK-version drift
between whenever these PNGs were captured and the current environment, though
each should be individually confirmed (some diffs, e.g. Scramble/KO bracket
pages at 12-22%, are large enough that a real layout regression can't be ruled
out without visually comparing to `test/failures/*_isolatedDiff.png` and
`*_testImage.png` after a run).

| Test | Golden file | Diff |
|---|---|---|
| `LandingPage default` | `goldens/landing__default.png` | 0.27%, 874px |
| `ScrambleSetupPage default` | `goldens/scramble_setup__default.png` | 12.27%, 40390px |
| `ScrambleOverviewPage in_progress` | `goldens/scramble_overview__in_progress.png` | 11.80%, 38857px |
| `ScrambleScorecardPage in_progress` | `goldens/scramble_scorecard__in_progress.png` | 22.19%, 73055px |
| `DoghouseScoreboardPage in_progress` | `goldens/doghouse_scoreboard__in_progress.png` | 1.77%, 5829px |
| `KoBracketSetupPage default` | `goldens/ko_bracket_setup__default.png` | 0.99%, 3257px |
| `KoBracketBracketPage with_tournament` | `goldens/ko_bracket_bracket__with_tournament.png` | 19.42%, 63935px |
| `KoBracketMatchPage in_progress` | `goldens/ko_bracket_match__in_progress.png` | 15.91%, 52360px |
| `CreatePlayerSheet default` | `goldens/create_player_sheet__default.png` | 0.24%, 679px |
| `CreateTeamSheet default` | `goldens/create_team_sheet__default.png` | 0.28%, 796px |
| `CreateGroupSheet default` | `goldens/create_group_sheet__default.png` | 0.45%, 1269px |

**Next steps to revisit:**
1. Run `flutter test test/golden_test.dart`, then inspect
   `test/failures/<name>_isolatedDiff.png` and `<name>_testImage.png` for the
   high-diff ones (Scramble*, KoBracket*) first — 12-22% is too large to
   dismiss as antialiasing without a look.
2. For the small ones (<1%, all the `Create*Sheet` and `LandingPage`), this is
   very likely just font hinting/antialiasing drift — regenerate via
   `flutter test --update-goldens test/golden_test.dart` after confirming
   visually there's no real regression.
3. Check whether golden tests are pinned to a specific Flutter SDK version in
   CI vs. what's installed locally — a version mismatch is the most common
   cause of this category.

---

## Category B — Layout overflow (1 test)

| Test | Error |
|---|---|
| `GamesPage with_games` | `RenderFlex overflowed by 5.6 pixels on the right` |

The offending widget is a `Row` at `lib/pages/games_page.dart:175`. This is a
genuine (if minor — 5.6px) layout bug: the Row's children don't fit the
available width at the golden test's surface size. Not related to the pairing
fix.

**Next step to revisit:** open `lib/pages/games_page.dart:175`, wrap the
overflowing child in `Expanded`/`Flexible` or reduce its content, per Flutter's
own suggested fix in the error output.

---

## Category C — `HiveError: Box not found` (7 tests)

| Test |
|---|
| `TeamsPage with_teams` |
| `TeamsPage empty` |
| `UsersPage with_players` |
| `UsersPage empty` |
| `UserDetailPage with_player` |
| `TournamentsPage default` |
| `TournamentHistoryPage empty` |

All fail identically:
```
HiveError: Box not found. Did you forget to call Hive.openBox()?
```
thrown while building a `DefaultTextStyle` deep in the widget tree — i.e. some
widget under these pages reads from a Hive box synchronously during build, and
the test environment never opens it.

This is a known, partially-handled issue in the test file itself — see the
comments already in `test/golden_test.dart`:
- Line ~476: `SettingsPage` group is fully commented out "to avoid HiveError"
  because it "calls a Hive box that is not initialized in tests."
- Line ~691 (`TournamentsPage`) and ~708 (`TournamentHistoryPage`): comments
  assert "Hive is not initialized in tests so loadAll() returns [] — safe to
  render," which **no longer holds** — these two now hit the same HiveError,
  meaning something changed in the storage-loading path so it throws instead
  of returning `[]` when the box isn't open.

**Next steps to revisit:**
1. Find whatever storage helper method now throws instead of returning `[]`
   when Hive isn't initialized (likely in
   `lib/services/local_storage_service.dart` or a teams/users-specific
   service) — the pre-existing comments suggest this used to fail soft.
2. Either open the required Hive box(es) in a `setUpAll`/`setUp` in
   `test/golden_test.dart` (check `test/flutter_test_config.dart` for existing
   test-wide setup), or restore the soft-fail behavior the comments describe,
   whichever matches intended production behavior.
3. `TeamsPage`/`UsersPage`/`UserDetailPage` were apparently already broken
   before the `TournamentsPage`/`TournamentHistoryPage` comments were even
   written (no exempting comment exists for them) — worth checking `git blame`
   on these groups to see if they ever passed, or have been broken since
   introduction.

---

## Summary

| Category | Count | Related to scramble fix? |
|---|---|---|
| A — pixel-diff mismatch | 11 | No (confirmed via git stash) |
| B — layout overflow | 1 | No |
| C — HiveError (Box not found) | 7 | No |
| **Total failing** | **19** | |

Two additional issues were fixed as part of this session (not counted above,
since they blocked the suite from compiling at all rather than failing a
specific test):
- `test/widget_test.dart`: stale `package:tournamaster` import → `package:tournaq`.
- `test/golden_test.dart:155`: removed obsolete `status:` constructor argument.
