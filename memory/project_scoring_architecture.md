---
name: project-scoring-architecture
description: Architectural decisions and product philosophy around the shared LiveScoringPage / ScoringAdapter pattern for gameplay controls across tournament modes
metadata:
  type: project
---

## LiveScoringPage + ScoringAdapter architecture

All tournament types (Quick Game, KO Bracket, League, Double Elimination, Swiss, etc.) will share a single `LiveScoringPage` driven by a `ScoringAdapter` interface. The adapter abstracts the persistence layer so the scoring UI (service rotation, side-change reminders, history, undo) is written once.

**Migration approach:** Extract `LiveScoringPage` from `score_page.dart` first. `score_page.dart` becomes a thin shell wrapping `QuickGameAdapter`. External API of `score_page.dart` stays unchanged — no UI regression.

## Adapter interface principle

Settings that differ between quick game and tournament modes use a **value getter + optional setter callback** pattern:
- Adapter always provides the current value (e.g. `int get targetPoints`)
- Optional callback (`void Function(int)?`) is non-null only when the setting is user-configurable
- `LiveScoringPage` hides the control when callback is null

## Product decision: mid-set target point changes (Quick Game)

**Decision:** Keep mid-set target point changes enabled in Quick Game. Do NOT restrict to pre-set only.

**Why:** Quick game is intentionally casual and player-friendly. Real players often decide mid-game they don't have enough time and want to lower the target. The flexibility is a feature, not a bug — quick game has no strict rules enforcement by design.

**Implication for adapter:** `QuickGameAdapter` provides a non-null `onTargetPointsChanged` callback. All tournament adapters return null — selector is hidden.

## Out of scope for now (revisit per tournament mode)

- **Time-cap logic:** KO bracket keeps its own timer. Each tournament mode will handle time differently. Introduce to adapter interface when working on specific modes.
- **Target points in tournaments:** Fixed at tournament settings level, not per-game. Adapter exposes value only.
- **Match format in tournaments:** Fixed at tournament creation. Adapter exposes value only.

## Settings: Quick Game vs Tournament split

| Setting | Quick Game | Tournament modes |
|---|---|---|
| Target points | Configurable mid-set (by design) | Fixed by tournament settings |
| Match format | Set at game creation | Fixed by tournament settings |
| Players per side | Set at game creation | Fixed by tournament settings |
| Time cap | Not present | Mode-specific (out of scope) |
