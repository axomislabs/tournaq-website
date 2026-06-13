# TournaQ — Architecture & Codebase Health Report
**Date:** 13 June 2026  
**Branch:** `introduce-tournaments`  
**Author:** Martin Adam (via Claude Code session)

---

## 1. Background — What This Session Covered

This report documents a multi-session architecture review and refactoring sprint. The conversation started as a runtime safety audit, evolved into a data-architecture discussion, and ended with three concrete improvements applied to the codebase. The fourth improvement — a state management library — was deliberately deferred and is documented here for future discussion.

---

## 2. Runtime Safety Fixes Applied

### 2.1 TextEditingController Leaks (Critical — Fixed)

**Problem:** Four `TextEditingController` instances were created inside async methods and never disposed. When a dialog or bottom sheet closed, the controller remained alive in memory with its internal listeners attached.

**Files fixed:**
- `lib/pages/scramble_scorecard_page.dart` — `_editPlayerName()` and `_showManualScoreDialog()`
- `lib/pages/doghouse_scoreboard_page.dart` — `_showLatePlayersSheet()`
- `lib/pages/king_of_the_court_scoreboard_page.dart` — `_showLatePlayersSheet()`

**Pattern applied:**

```dart
// Async methods (ScrambleScorecardPage)
final ctrl = TextEditingController();
try {
  final result = await showModalBottomSheet(...);
  // use result
} finally {
  ctrl.dispose();
}

// Sync methods (Doghouse / KOTC)
showModalBottomSheet(...).whenComplete(() {
  nameCtrl.dispose();
  searchCtrl.dispose();
});
```

**Impact:** None visible to user. Prevents background memory and listener accumulation over a long session.

---

## 3. Architecture — Current Data Model

### 3.1 Two Distinct Storage Systems

TournaQ has two separate persistence layers that coexist:

| System | Entities | Storage | Pattern |
|---|---|---|---|
| **AppState** | Players, Teams, Games, Clubs | Hive (`games_v1`, `teams_v1`, `players_v1`, `clubs_v1`) | Normalized — entities reference each other by ID |
| **Tournament formats** | Scramble, KOTC, Doghouse, KO Bracket | Hive (separate boxes per format) | Embedded document — full tournament saved as one JSON blob |

These systems are largely independent. AppState is loaded once at startup and flows through the widget tree via constructor parameters. The four tournament formats manage their own Hive boxes through dedicated storage services (`ScrambleStorageService`, etc.).

The only coupling point: hub pages and setup pages for tournament formats receive a `List<Player>` from AppState so users can add existing roster players to a session.

### 3.2 Multi-Device Readiness

The external recommendation received during this session advised normalizing embedded tournament data to prepare for multi-device use. After reviewing the codebase, this advice was found to be partially misaligned:

- **Embedded documents are not a barrier to multi-device sync.** Firestore (the natural Flutter backend) works natively with document-oriented data. Each tournament as a Hive document maps cleanly to a Firestore document.
- **The actual preparation for multi-device is the Repository pattern**, which `local_storage_service.dart` already documents explicitly: *"Introduce a Repository interface (e.g. GameRepository) above this class before Firebase migration."*
- **KOTC and Doghouse have a unique timer-state problem.** Both store `remainingSeconds` (a live countdown) directly in the tournament document. Two devices running simultaneously would diverge. This is a conflict resolution problem, not a data shape problem — it requires a server-authoritative clock or designated host device regardless of how data is normalized.
- **KO Bracket is the most multi-device ready** of all four formats. It already uses internal ID references (matches store `team1Id`/`team2Id`), and `KoPlayerSnapshot` is a deliberate point-in-time snapshot so bracket seeding can't be retroactively altered.

**Conclusion:** No normalization work needed before adding a backend. The repository abstraction layer is the right preparatory step.

---

## 4. Improvements Applied This Session

### 4.1 Legacy Tournament Code Removed

**What it was:** The original app had a "Classic Tournament" concept — `Tournament`, `TournamentMode`, `TournamentLogicService` — that had been superseded by the four dedicated tournament formats (Scramble, KOTC, Doghouse, KO Bracket). The legacy code was still present but entirely inactive: `AppState.tournaments` was always empty, no UI path created classic tournaments, and `TournamentDetailPage` was unreachable in practice.

**Why it mattered:** The dead code required any reader to investigate whether `tournaments` was used before concluding it was always empty. `AppState` had tournament mutation helpers, a Hive box, and lookup methods that all silently did nothing. Several pages (clubs, teams, users) rendered empty tournament filter lists on every build.

**Files deleted:**
- `lib/models/tournament.dart`
- `lib/models/tournament_mode.dart`
- `lib/pages/tournament_detail_page.dart`
- `lib/services/tournament_logic_service.dart`
- `lib/widgets/hybrid_mode_setup_page.dart`
- `lib/widgets/single_games_dialog.dart` *(referenced deleted Tournament, never imported anywhere)*

**Files cleaned up (tournament references removed):**
- `lib/state/app_state.dart` — removed `tournaments` list, all tournament lookups and mutation helpers
- `lib/services/local_storage_service.dart` — removed `tournaments_v1` Hive box
- `lib/services/app_data_service.dart` — removed all tournament CRUD operations, team–tournament and club–tournament assignment methods, the tournament cleanup loop in `deleteTeam`, and `generateGamesForTournament`
- `lib/pages/teams_page.dart`, `users_page.dart`, `clubs_page.dart` — removed tournament filter chips and filter logic
- `lib/pages/club_detail_page.dart`, `team_detail_page.dart` — removed tournament sections from detail views and action buttons
- `lib/widgets/create_team_sheet.dart`, `create_club_sheet.dart` — removed tournament assignment chip sections

**Impact on users:** None. No user-visible feature was removed — the classic tournament flow had no active entry point.

---

### 4.2 Granular Hive Saves

**What it was:** Every `AppState` change — including scoring a single point in a quick game, or renaming a player — triggered `saveAppState()`, which cleared and rewrote all four Hive boxes in full.

**Why it mattered:** This is safe and correct for current data volumes, but it means a score tap writes every player, every team, every game, and every club to disk on every change. As the app grows and the game history builds up, this becomes progressively slower.

**What changed:** `LocalStorageService` now has `saveChangedEntities(AppState prev, AppState next)`. It diffs the old and new state using object identity (`identical()`), writes only the entities that changed or were added, and deletes only the entities that were removed. This works correctly because `AppState.copyWith()` and its entity mutation helpers preserve existing object references for unchanged items — `identical()` returns false only when an entity is actually new or modified.

`main.dart` was updated to call `saveChangedEntities` instead of `saveAppState`:

```dart
void _updateAppState(AppState newState) {
  final prev = _appState;
  setState(() => _appState = newState);
  LocalStorageService.saveChangedEntities(prev, newState); // fire-and-forget
}
```

`saveAppState` is kept in `LocalStorageService` for use by `clearHistoryData()` and potential future bulk operations.

**Impact on users:** None visible. Disk writes are now proportional to what actually changed rather than total data volume.

---

### 4.3 AppState Dependency Slimmed in Tournament Pages

**What it was:** All four tournament hub pages (`ScrambleHubPage`, `KingOfTheCourtHubPage`, `DoghouseHubPage`, `KoBracketHubPage`) accepted `AppState appState` and `Function(AppState) onAppStateChanged` as constructor parameters. These were inherited from `TournamentsPage` and threaded down through setup pages and scoreboard pages all the way to the point of use — which was always just `appState.players` to populate the "add existing player" sheet.

`onAppStateChanged` was never called anywhere in this chain. The tournament formats manage their own storage and never modify AppState.

**Why it mattered:** Passing the full `AppState` object where only `List<Player>` is needed creates implicit coupling. Any change to AppState's shape would require auditing these pages, even though they only ever touch the player list. It also obscures that these pages are fully independent of the AppState write path.

**What changed:** All pages in the tournament format chain now receive `List<Player> existingPlayers` instead of `AppState appState`. The `onAppStateChanged` callback was removed from all hub pages (it was never used). `KoBracketBracketPage` had the `AppState` parameter removed entirely — it was declared but never accessed.

**Files updated:**
- Hub pages: `scramble_hub_page.dart`, `king_of_the_court_hub_page.dart`, `doghouse_hub_page.dart`, `ko_bracket_hub_page.dart`
- Setup pages: `scramble_setup_page.dart`, `king_of_the_court_setup_page.dart`, `doghouse_setup_page.dart`, `ko_bracket_setup_page.dart` (including the `_TeamEditorSheet` sub-widget)
- Scoreboard/bracket pages: `king_of_the_court_scoreboard_page.dart`, `doghouse_scoreboard_page.dart`, `ko_bracket_bracket_page.dart`
- History page: `tournament_history_page.dart`
- Call sites: `tournaments_page.dart`

**Impact on users:** None visible.

---

## 5. Open Item — State Management Library (Deferred)

### 5.1 What the Problem Is

AppState currently flows through the widget tree via constructor parameters and `onAppStateChanged` callbacks. Every page in the tree carries both:

```dart
final AppState appState;
final Function(AppState) onAppStateChanged;
```

When a deeply nested widget needs to trigger a state change, it calls `onAppStateChanged(newState)`, which bubbles up through every parent page until it reaches `_MyAppState` in `main.dart`. `main.dart` then calls `setState()`, which rebuilds the entire tree.

This is called **prop drilling** — the practice of passing data through multiple layers of widgets that don't use it themselves, only to hand it to a child.

### 5.2 Why It's Not a Problem Yet

For the current app size and navigation depth, prop drilling works. The callback chain is short enough to be readable. Refactoring it would be purely architectural — no user-visible benefit today.

### 5.3 When It Becomes a Problem

Prop drilling becomes painful when:
- You add screens that are 4+ navigation levels deep
- Multiple unrelated pages need to react to the same state change simultaneously (e.g., a live leaderboard visible from multiple routes)
- You want to support deep linking or restoration (the current tree rebuild approach doesn't restore state below the navigation stack)
- You add cross-tournament player stats (a "lifetime stats" view would need to read AppState from inside a tournament format page, which currently has no AppState access)

### 5.4 Recommended Approach — Riverpod

The most idiomatic modern Flutter state management solution is **Riverpod**. It would:
- Make `AppState` (or its constituent parts) available anywhere in the tree without threading it through constructors
- Replace `onAppStateChanged` callbacks with `ref.read(appStateProvider.notifier).update(...)`
- Allow widgets to subscribe only to the specific slice of state they need (e.g., only re-render when `players` changes, not when `games` changes)
- Work naturally with the existing `LocalStorageService.saveChangedEntities` approach

The `AppState` model itself would not need to change — only how it's distributed and updated.

### 5.5 What to Discuss Before Implementing

Before adopting Riverpod or any state management library, align on:

1. **Scope** — Are you refactoring the whole app at once, or migrating page by page? Page-by-page is safer but temporarily creates mixed patterns.
2. **Testing** — Riverpod providers are testable in isolation. If you plan to add unit tests, this is a strong argument for doing it now before the tree grows further.
3. **Backend timing** — If a Firebase backend is coming soon, doing the Riverpod migration and the Firebase migration together reduces the total disruption. The repository pattern (already referenced in `local_storage_service.dart`) slots naturally into Riverpod providers.
4. **Team familiarity** — Riverpod has a learning curve. If you are the sole developer, the investment is straightforward. If others join the codebase, training time matters.

### 5.6 Estimated Effort

A full Riverpod migration of the existing AppState + its call sites across all pages would be approximately **2–3 focused development sessions**. It is not an emergency — defer until one of these triggers applies:
- You start building cross-tournament features
- You hit a navigation or deep-link requirement
- You begin the Firebase integration

---

## 6. Summary

| Item | Status |
|---|---|
| TextEditingController leaks (4 instances) | ✅ Fixed |
| Legacy Tournament code removed | ✅ Done |
| Granular Hive saves | ✅ Done |
| AppState slim to `List<Player>` in tournament chain | ✅ Done |
| State management library (Riverpod) | ⏳ Deferred — see Section 5 |

The codebase is now leaner, the AppState dependency is explicit, and saves are proportional to actual changes. The remaining open item (Riverpod) is well-documented above and ready to pick up whenever the timing is right.
