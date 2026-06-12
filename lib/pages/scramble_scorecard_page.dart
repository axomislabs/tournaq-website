import 'package:flutter/material.dart';
import '../app/app_colors.dart';
import '../models/scramble_tournament.dart';
import '../pages/gameplay_history_page.dart';
import '../services/scramble_service.dart';
import '../services/scramble_storage_service.dart';
import '../widgets/scramble_timer_widget.dart';
import '../widgets/sheet_helpers.dart';
import '../widgets/tournaq_app_bar.dart';
import '../widgets/player_pill.dart';

// ── Local color aliases — mirrors score_page.dart convention ─────────────────
const _kGold = AppColors.goldDark;
const _kGoldLight = AppColors.goldCream;
const _kOlive = AppColors.olive;
const _kOliveLight = AppColors.oliveLight;
const _kGoldCardBg = AppColors.goldCardBg;
const _kGoldCardLeading = AppColors.goldCardLeading;
const _kOliveCardBg = AppColors.oliveCardBg;
const _kOliveCardLeading = AppColors.oliveCardLeading;

// ── Score event — identical concept to score_page._ScoreEvent ────────────────

class _ScrambleScoreEvent {
  final bool isSideAScore;
  final int prevServingIndex; // captured BEFORE any rotation
  final bool serviceChanged;

  const _ScrambleScoreEvent({
    required this.isSideAScore,
    required this.prevServingIndex,
    required this.serviceChanged,
  });
}

// ── Page ──────────────────────────────────────────────────────────────────────

/// Scramble per-game scorecard.
///
/// Serving algorithm (identical to QuickGame):
///   _activeIndex cycles 0..2N-1 where N = playersPerTeam.
///   _activeIndex % 2 == 0  →  Side A is serving.
///   _activeIndex ~/ 2      →  which player on the serving team is active.
///   Service rotates when the non-serving side scores, same as QuickGame.
class ScrambleScorecardPage extends StatefulWidget {
  final ScrambleTournament tournament;
  final ScrambleGame game;
  final ScrambleRound round;
  final void Function(ScrambleTournament) onChanged;

  const ScrambleScorecardPage({
    super.key,
    required this.tournament,
    required this.game,
    required this.round,
    required this.onChanged,
  });

  @override
  State<ScrambleScorecardPage> createState() => _ScrambleScorecardPageState();
}

class _ScrambleScorecardPageState extends State<ScrambleScorecardPage> {
  late ScrambleTournament _t;
  late ScrambleGame _game;
  late ScrambleRound _round;

  // ── Scores ────────────────────────────────────────────────────────────────
  // Always stored as sideA / sideB regardless of display swap.
  int _scoreA = 0;
  int _scoreB = 0;

  // Display swap — flips left/right without touching stored scores (QuickGame _isSwapped).
  bool _isSwapped = false;

  // ── Serving (QuickGame-identical algorithm) ───────────────────────────────
  // 0..2N-1 where N = playersPerTeam
  //   even index  → Side A serving,  player index = activeIndex ~/ 2
  //   odd  index  → Side B serving,  player index = activeIndex ~/ 2
  int _activeIndex = 0;

  // ── Undo stack (same concept as score_page._scoreEvents) ─────────────────
  final List<_ScrambleScoreEvent> _scoreEvents = [];

  // ── Match state ───────────────────────────────────────────────────────────
  bool _matchCompleted = false;

  // ── Timer ─────────────────────────────────────────────────────────────────
  final _matchTimerKey = GlobalKey<ScrambleTimerWidgetState>();

  // ── Computed helpers ──────────────────────────────────────────────────────
  int get _n => _t.playersPerTeam;
  bool get _isSideAServing => _activeIndex % 2 == 0;
  int get _activePlayerOnTeam => _activeIndex ~/ 2;

  int get _leftScore => _isSwapped ? _scoreB : _scoreA;
  int get _rightScore => _isSwapped ? _scoreA : _scoreB;

  @override
  void initState() {
    super.initState();
    _t = widget.tournament;
    _game = widget.game;
    _round = widget.round;
    _scoreA = _game.sideAScore;
    _scoreB = _game.sideBScore;
    _matchCompleted = _game.isCompleted;
  }

  // ── Persistence ───────────────────────────────────────────────────────────

  void _persist(ScrambleTournament updated) {
    setState(() => _t = updated);
    ScrambleStorageService.save(updated);
    widget.onChanged(updated);
  }

  // ── Score actions (QuickGame pattern) ────────────────────────────────────

  /// [isLeft] refers to the display side, respecting [_isSwapped].
  void _addScore({required bool isLeft}) {
    if (_matchCompleted) return;

    // Resolve to logical side (same as score_page scoringIsTeam1 logic)
    final scoringIsA = isLeft ? !_isSwapped : _isSwapped;
    final prevIndex = _activeIndex;
    final changedService = scoringIsA != _isSideAServing;

    setState(() {
      if (scoringIsA) {
        _scoreA++;
      } else {
        _scoreB++;
      }
      if (changedService) {
        _activeIndex = (_activeIndex + 1) % (_n * 2);
      }
      _scoreEvents.add(
        _ScrambleScoreEvent(
          isSideAScore: scoringIsA,
          prevServingIndex: prevIndex,
          serviceChanged: changedService,
        ),
      );
    });
  }

  void _removeScore({required bool isLeft}) {
    if (_matchCompleted) return;

    final removeIsA = isLeft ? !_isSwapped : _isSwapped;
    int eventIndex = -1;
    for (var i = _scoreEvents.length - 1; i >= 0; i--) {
      if (_scoreEvents[i].isSideAScore == removeIsA) {
        eventIndex = i;
        break;
      }
    }
    if (eventIndex < 0) return;

    final event = _scoreEvents[eventIndex];
    setState(() {
      if (removeIsA) {
        if (_scoreA > 0) _scoreA--;
      } else {
        if (_scoreB > 0) _scoreB--;
      }
      if (event.serviceChanged) _activeIndex = event.prevServingIndex;
      _scoreEvents.removeAt(eventIndex);
    });
  }

  void _rotateActivePlayer() {
    setState(() => _activeIndex = (_activeIndex + 1) % (_n * 2));
  }

  void _swap() => setState(() => _isSwapped = !_isSwapped);

  // ── Game completion ───────────────────────────────────────────────────────

  void _completeGame() {
    final now = DateTime.now();
    final started = _game.actualStartTime ?? now;
    final delta = now.difference(started) - _round.matchDuration;

    final updatedGame = _game.copyWith(
      sideAScore: _scoreA,
      sideBScore: _scoreB,
      status: ScrambleGameStatus.completed,
      actualStartTime: started,
      actualEndTime: now,
    );

    var updated = _t.updateGame(updatedGame);

    if (delta.abs().inSeconds > 30) {
      updated = ScrambleService.reflowSchedule(
        updated,
        fromRoundNumber: _round.roundNumber + 1,
        delta: delta,
      );
    }

    setState(() {
      _game = updatedGame;
      _matchCompleted = true;
    });
    _matchTimerKey.currentState?.pause();
    _persist(updated);
  }

  void _undoCompletion() {
    final updatedGame = _game.copyWith(
      sideAScore: _scoreA,
      sideBScore: _scoreB,
      status: ScrambleGameStatus.scheduled,
      actualStartTime: null,
      actualEndTime: null,
    );
    setState(() {
      _game = updatedGame;
      _matchCompleted = false;
    });
    _persist(_t.updateGame(updatedGame));
  }

  void _startMatch() {
    final updatedGame = _game.copyWith(
      status: ScrambleGameStatus.inProgress,
      actualStartTime: DateTime.now(),
    );
    setState(() => _game = updatedGame);
    _persist(_t.updateGame(updatedGame));
    _matchTimerKey.currentState?.start();
  }

  /// Start/Restart — always records current time, resets timer to full
  /// match duration, and starts. Works whether the game is scheduled or
  /// already in progress. Not available when completed.
  void _startOrRestart() {
    if (_matchCompleted) return;
    final updatedGame = _game.copyWith(
      status: ScrambleGameStatus.inProgress,
      actualStartTime: DateTime.now(),
    );
    setState(() => _game = updatedGame);
    _persist(_t.updateGame(updatedGame));
    // restart() resets remaining to widget.initial (= _round.matchDuration)
    // and sets state to idle; start() then begins the countdown.
    _matchTimerKey.currentState?.restart();
    _matchTimerKey.currentState?.start();
  }

  // ── Time's-up dialog ──────────────────────────────────────────────────────

  Future<void> _onMatchTimerFinished() async {
    if (_matchCompleted || !mounted) return;
    _matchTimerKey.currentState?.pause();

    final adjust = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Colors.white,
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
        contentPadding: const EdgeInsets.fromLTRB(24, 14, 24, 0),
        actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _kGoldLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.timer_off_rounded,
                color: _kGold,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Time is up',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        content: const Text(
          'Was the last point still ongoing when the timer ended?',
          style: TextStyle(fontSize: 14, color: Colors.black87, height: 1.5),
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _kOlive,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text(
                'Adjust final score',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text(
                'Complete game',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );

    if (!mounted) return;
    if (adjust == false) {
      _completeGame();
    }
    // adjust == true → user stays on scorecard to fix score, then taps Complete Game
  }

  // ── Game options sheet (QuickGame pattern) ────────────────────────────────

  void _showGameOptions() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetCtx) {
        void closeAndRun(VoidCallback action) {
          Navigator.of(sheetCtx).pop();
          action();
        }

        return TournaQSheet(
          body: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Game Options',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                _optionTile(
                  sheetCtx,
                  icon: Icons.swap_horiz_rounded,
                  iconBg: _matchCompleted ? Colors.grey.shade100 : _kGoldLight,
                  iconColor: _matchCompleted ? Colors.grey : _kGold,
                  label: 'Swap Sides',
                  subtitle: 'Switch left and right display',
                  enabled: !_matchCompleted,
                  onTap: () => closeAndRun(_swap),
                ),
                _optionTile(
                  sheetCtx,
                  icon: Icons.rotate_right_rounded,
                  iconBg: _kOliveLight,
                  iconColor: _kOlive,
                  label: 'Change Serve',
                  subtitle: 'Advance to next server',
                  enabled: true,
                  onTap: () => closeAndRun(_rotateActivePlayer),
                ),
                _optionTile(
                  sheetCtx,
                  icon: Icons.history_rounded,
                  iconBg: _kGoldLight,
                  iconColor: _kGold,
                  label: 'Match History',
                  subtitle: 'Point-by-point scoring timeline',
                  enabled: true,
                  onTap: () {
                    Navigator.of(sheetCtx).pop();
                    _openHistory();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _optionTile(
    BuildContext sheetCtx, {
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String label,
    required String subtitle,
    required bool enabled,
    required VoidCallback onTap,
  }) => ListTile(
    contentPadding: const EdgeInsets.symmetric(horizontal: 8),
    leading: Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
      child: Icon(icon, color: iconColor, size: 20),
    ),
    title: Text(
      label,
      style: TextStyle(
        fontWeight: FontWeight.w600,
        color: enabled ? Colors.black87 : Colors.grey,
      ),
    ),
    subtitle: Text(
      subtitle,
      style: const TextStyle(fontSize: 12, color: Colors.black45),
    ),
    onTap: enabled ? onTap : null,
  );

  // ── History ───────────────────────────────────────────────────────────────

  void _openHistory() {
    final sideANames = _game.sideAPlayerIds
        .map((id) => _t.getPlayer(id)?.name ?? id)
        .toList();
    final sideBNames = _game.sideBPlayerIds
        .map((id) => _t.getPlayer(id)?.name ?? id)
        .toList();

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => GameplayHistoryPage(
          team1Name: sideANames.join(' & '),
          team2Name: sideBNames.join(' & '),
          team1Players: sideANames,
          team2Players: sideBNames,
          entries: _buildHistoryEntries(),
        ),
      ),
    );
  }

  /// Builds GameHistoryEntry list — same formula as score_page._buildHistoryEntries.
  List<GameHistoryEntry> _buildHistoryEntries() {
    var aScore = 0;
    var bScore = 0;
    return _scoreEvents.map((e) {
      if (e.isSideAScore) {
        aScore++;
      } else {
        bScore++;
      }
      return GameHistoryEntry(
        isTeam1Score: e.isSideAScore,
        team1Score: aScore,
        team2Score: bScore,
        setIndex: 0,
        targetPoints: 0,
        // Same formula as QuickGame: prevService % 2 == 0 → team1 serving
        isTeam1Serving: e.prevServingIndex % 2 == 0,
        servingPlayerIndex: e.prevServingIndex ~/ 2,
        serviceChanged: e.serviceChanged,
      );
    }).toList();
  }

  // ── Player name editing ───────────────────────────────────────────────────

  Future<void> _editPlayerName(ScramblePlayer player) async {
    if (_matchCompleted) return;
    final ctrl = TextEditingController(text: player.name);
    final saved = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Rename Player',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(
                player.source == ScramblePlayerSource.existing
                    ? 'Updates tournament display only.'
                    : 'Updates name in stats and schedule.',
                style: const TextStyle(fontSize: 12, color: Colors.black45),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: ctrl,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  hintText: 'Player name',
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(ctrl.text.trim()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kOlive,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Save',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (saved == null || saved.isEmpty || !mounted) return;
    final updatedPlayers = _t.players.map((p) {
      return p.id == player.id ? p.copyWith(name: saved) : p;
    }).toList();
    _persist(_t.copyWith(players: updatedPlayers));
  }

  // ── Upcoming games helper ────────────────────────────────────────────────

  /// Returns the next scheduled games after the current one, across all rounds.
  List<({ScrambleGame game, ScrambleRound round})> _upcomingGames({
    int limit = 4,
  }) {
    final result = <({ScrambleGame game, ScrambleRound round})>[];
    for (final round in _t.rounds) {
      for (final game in _t.getGamesForRound(round.id)) {
        if (game.id == _game.id) continue;
        if (game.isCompleted) continue;
        final roundObj = _t.getRound(game.roundId);
        if (roundObj == null) continue;
        // Only show games in current or future rounds
        if (roundObj.roundNumber < _round.roundNumber) continue;
        result.add((game: game, round: roundObj));
        if (result.length >= limit) return result;
      }
    }
    return result;
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final sideAPlayers = _game.sideAPlayerIds
        .map((id) => _t.getPlayer(id))
        .whereType<ScramblePlayer>()
        .toList();
    final sideBPlayers = _game.sideBPlayerIds
        .map((id) => _t.getPlayer(id))
        .whereType<ScramblePlayer>()
        .toList();
    final sittingOut = _game.sittingOutPlayerIds
        .map((id) => _t.getPlayer(id)?.name ?? id)
        .toList();

    // Left/right display assignments (swap does not touch stored data).
    final leftPlayers = _isSwapped ? sideBPlayers : sideAPlayers;
    final rightPlayers = _isSwapped ? sideAPlayers : sideBPlayers;
    final leftIsA = !_isSwapped;
    final scoreLocked = _matchCompleted;

    final optionsButton = IconButton(
      icon: const Icon(Icons.tune_rounded, size: 20, color: _kOlive),
      tooltip: 'Game Options',
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
      visualDensity: VisualDensity.compact,
      onPressed: _showGameOptions,
    );

    return Scaffold(
      appBar: TournaQAppBar(title: 'Social Scramble', subtitle: 'Scoreboard'),
      body: SafeArea(
        child: OrientationBuilder(
          builder: (context, orientation) {
            final isLandscape = orientation == Orientation.landscape;

            // ── Landscape ────────────────────────────────────────────────────
            // Shows: timer + controls, score cards (with pills inside), lock banner.
            // Hides: Match Controls, Upcoming Games, sit-outs, info chips.
            if (isLandscape) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Timer display + options button
                    Row(
                      children: [
                        const Icon(
                          Icons.timer_rounded,
                          size: 13,
                          color: _kOlive,
                        ),
                        const SizedBox(width: 4),
                        ScrambleTimerWidget(
                          key: _matchTimerKey,
                          initial: _round.matchDuration,
                          mode: ScrambleTimerMode.countdown,
                          autoStart: false,
                          compact: true,
                          onFinished: _onMatchTimerFinished,
                        ),
                        if (!_matchCompleted) ...[
                          const SizedBox(width: 8),
                          _refBtn(
                            Icons.pause_rounded,
                            'Stop',
                            () => _matchTimerKey.currentState?.pause(),
                          ),
                          const SizedBox(width: 4),
                          _refBtn(
                            Icons.replay_rounded,
                            'Start / Restart',
                            _startOrRestart,
                          ),
                          const SizedBox(width: 4),
                          _refTextBtn(
                            '+30s',
                            () => _matchTimerKey.currentState?.addTime(
                              const Duration(seconds: 30),
                            ),
                          ),
                          const SizedBox(width: 4),
                          _refTextBtn(
                            '−30s',
                            () => _matchTimerKey.currentState?.addTime(
                              const Duration(seconds: -30),
                            ),
                          ),
                        ],
                        const Spacer(),
                        optionsButton,
                      ],
                    ),
                    if (_matchCompleted) ...[
                      const SizedBox(height: 4),
                      _buildLockBanner(),
                    ],
                    const SizedBox(height: 4),
                    // Score cards with pills inside — side by side
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: _buildScoreCard(
                              players: leftPlayers,
                              score: _leftScore,
                              isLeading: _leftScore > _rightScore,
                              isA: leftIsA,
                              onIncrement: scoreLocked
                                  ? null
                                  : () => _addScore(isLeft: true),
                              onDecrement: scoreLocked
                                  ? null
                                  : () => _removeScore(isLeft: true),
                              landscape: true,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildScoreCard(
                              players: rightPlayers,
                              score: _rightScore,
                              isLeading: _rightScore > _leftScore,
                              isA: !leftIsA,
                              onIncrement: scoreLocked
                                  ? null
                                  : () => _addScore(isLeft: false),
                              onDecrement: scoreLocked
                                  ? null
                                  : () => _removeScore(isLeft: false),
                              landscape: true,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }

            // ── Portrait ─────────────────────────────────────────────────────
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. GAMEPLAY CONTROLS
                  _sectionHeader(
                    'Gameplay Controls',
                    Icons.sports_volleyball_rounded,
                    trailing: optionsButton,
                  ),
                  const SizedBox(height: 10),
                  _buildGameplayTimerRow(),
                  const SizedBox(height: 10),
                  if (_matchCompleted) ...[
                    _buildLockBanner(),
                    const SizedBox(height: 8),
                  ],
                  // Score cards side by side — pills stacked inside each card.
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: _buildScoreCard(
                            players: leftPlayers,
                            score: _leftScore,
                            isLeading: _leftScore > _rightScore,
                            isA: leftIsA,
                            stackedPills: true,
                            onIncrement: scoreLocked
                                ? null
                                : () => _addScore(isLeft: true),
                            onDecrement: scoreLocked
                                ? null
                                : () => _removeScore(isLeft: true),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildScoreCard(
                            players: rightPlayers,
                            score: _rightScore,
                            isLeading: _rightScore > _leftScore,
                            isA: !leftIsA,
                            stackedPills: true,
                            onIncrement: scoreLocked
                                ? null
                                : () => _addScore(isLeft: false),
                            onDecrement: scoreLocked
                                ? null
                                : () => _removeScore(isLeft: false),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 2. MATCH CONTROLS (sit-outs at the bottom)
                  _sectionHeader('Match Controls', Icons.emoji_events_rounded),
                  const SizedBox(height: 10),
                  _buildMatchActions(sittingOut: sittingOut),
                  const SizedBox(height: 24),

                  // 3. UPCOMING GAMES
                  _sectionHeader('Upcoming Games', Icons.schedule_rounded),
                  const SizedBox(height: 10),
                  _buildUpcomingGames(),
                  const SizedBox(height: 8),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  /// Pill row used inside score cards.
  Widget _buildPlayerPills(
    List<ScramblePlayer> players,
    bool isA,
    bool disabled, {
    bool stacked = false,
    double fontSize = 10,
  }) {
    if (players.isEmpty) return const SizedBox.shrink();
    final activeColor = isA ? _kGold : _kOlive;

    final pills = players.asMap().entries.map((e) {
      final isServing = (_isSideAServing == isA) && (_activePlayerOnTeam == e.key);
      return PlayerPill(
        name: e.value.name,
        isServing: isServing,
        activeColor: activeColor,
        fontSize: fontSize,
        onTap: disabled ? null : () => _editPlayerName(e.value),
      );
    }).toList();

    if (stacked) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: pills
            .expand((p) => [p, const SizedBox(height: 4)])
            .take(pills.length * 2 - 1)
            .toList(),
      );
    }
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      alignment: WrapAlignment.center,
      children: pills,
    );
  }

  // ── Gameplay timer row ────────────────────────────────────────────────────

  Widget _buildGameplayTimerRow() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.timer_rounded, size: 14, color: _kOlive),
              const SizedBox(width: 6),
              const Text(
                'MATCH TIMER',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: _kOlive,
                  letterSpacing: 0.6,
                ),
              ),
              const Spacer(),
              ScrambleTimerWidget(
                key: _matchTimerKey,
                initial: _round.matchDuration,
                mode: ScrambleTimerMode.countdown,
                autoStart: false,
                compact: true,
                onFinished: _onMatchTimerFinished,
              ),
            ],
          ),
          if (!_matchCompleted) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              alignment: WrapAlignment.center,
              children: [
                _refBtn(
                  Icons.pause_rounded,
                  'Stop',
                  () => _matchTimerKey.currentState?.pause(),
                ),
                _refBtn(
                  Icons.replay_rounded,
                  'Start / Restart',
                  _startOrRestart,
                ),
                _refTextBtn(
                  '+30s',
                  () => _matchTimerKey.currentState?.addTime(
                    const Duration(seconds: 30),
                  ),
                ),
                _refTextBtn(
                  '−30s',
                  () => _matchTimerKey.currentState?.addTime(
                    const Duration(seconds: -30),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _refBtn(
    IconData icon,
    String label,
    VoidCallback onTap, {
    bool primary = false,
  }) => OutlinedButton.icon(
    onPressed: onTap,
    icon: Icon(icon, size: 14),
    label: Text(label, style: const TextStyle(fontSize: 12)),
    style: OutlinedButton.styleFrom(
      foregroundColor: primary ? Colors.white : _kOlive,
      backgroundColor: primary ? _kOlive : null,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      side: BorderSide(color: primary ? _kOlive : Colors.grey.shade300),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      minimumSize: Size.zero,
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    ),
  );

  Widget _refTextBtn(String label, VoidCallback onTap) => OutlinedButton(
    onPressed: onTap,
    style: OutlinedButton.styleFrom(
      foregroundColor: _kOlive,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      side: BorderSide(color: Colors.grey.shade300),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      minimumSize: Size.zero,
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    ),
    child: Text(label, style: const TextStyle(fontSize: 12)),
  );

  // ── Round info chips (used only outside landscape now) ────────────────────

  Widget _chip(IconData icon, String label, Color bg, Color fg) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 11, color: fg),
        const SizedBox(width: 3),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: fg,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );

  // ── Lock banner ───────────────────────────────────────────────────────────

  Widget _buildLockBanner() {
    final winner = _game.winningSide;
    final winnerNames = winner == 'A'
        ? _game.sideAPlayerIds
              .map((id) => _t.getPlayer(id)?.name ?? id)
              .join(' & ')
        : winner == 'B'
        ? _game.sideBPlayerIds
              .map((id) => _t.getPlayer(id)?.name ?? id)
              .join(' & ')
        : null;
    final winnerColor = winner == 'A' ? _kGold : _kOlive;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.lock_rounded, size: 16, color: Colors.black54),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Game completed — undo to edit scores',
              style: TextStyle(
                fontSize: 12,
                color: Colors.black54,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 8),
          if (winnerNames != null)
            Text(
              'Winner: $winnerNames',
              style: TextStyle(
                fontSize: 12,
                color: winnerColor,
                fontWeight: FontWeight.w700,
              ),
            )
          else
            const Text(
              'No winner determined',
              style: TextStyle(
                fontSize: 12,
                color: Colors.black38,
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
    );
  }

  // ── Sitting out row ───────────────────────────────────────────────────────

  Widget _buildSittingOutRow(List<String> names) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: Colors.grey.shade100,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(
      children: [
        const Icon(Icons.chair_rounded, size: 13, color: Colors.black38),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            'Sitting out: ${names.join(', ')}',
            style: const TextStyle(fontSize: 12, color: Colors.black45),
          ),
        ),
      ],
    ),
  );

  // ── Score card (pills inside — stacked in portrait, side by side in landscape)

  Widget _buildScoreCard({
    required List<ScramblePlayer> players,
    required int score,
    required bool isLeading,
    required bool isA,
    required VoidCallback? onIncrement,
    required VoidCallback? onDecrement,
    bool landscape = false,
    bool stackedPills = false,
  }) {
    final teamColor = isA ? _kGold : _kOlive;
    final cardBg = isA
        ? (isLeading ? _kGoldCardLeading : _kGoldCardBg)
        : (isLeading ? _kOliveCardLeading : _kOliveCardBg);
    final disabled = onIncrement == null;

    Widget cardContent;
    if (landscape) {
      // Landscape: proportional budget — name, pills, score, buttons all aligned.
      cardContent = LayoutBuilder(
        builder: (context, constraints) {
          final h = constraints.maxHeight;
          final nameH    = (h * 0.16).clamp(0.0, 24.0);
          final btnH     = (h * 0.36).clamp(0.0, 48.0);
          final iconSize = (btnH * 0.55).clamp(12.0, 24.0);
          final nameFontSize = (nameH * 0.75).clamp(10.0, 18.0);

          return SizedBox(
            height: h,
            child: Column(
              children: [
                SizedBox(
                  height: nameH,
                  child: Text(
                    isA ? 'Side A' : 'Side B',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: nameFontSize,
                      color: teamColor,
                    ),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                if (players.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  _buildPlayerPills(players, isA, disabled, fontSize: 13),
                  const SizedBox(height: 2),
                ],
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.contain,
                    child: Text(
                      '$score',
                      style: TextStyle(
                        fontSize: 120,
                        fontWeight: FontWeight.bold,
                        height: 1.0,
                        color: disabled ? Colors.black38 : Colors.black87,
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  height: btnH,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton.filled(
                        icon: const Icon(Icons.remove),
                        onPressed: onDecrement,
                        iconSize: iconSize,
                        style: IconButton.styleFrom(
                          backgroundColor:
                              disabled ? Colors.grey.shade300 : teamColor,
                          foregroundColor:
                              disabled ? Colors.grey : Colors.white,
                          fixedSize: Size(btnH, btnH),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                      IconButton.filled(
                        icon: const Icon(Icons.add),
                        onPressed: onIncrement,
                        iconSize: iconSize,
                        style: IconButton.styleFrom(
                          backgroundColor:
                              disabled ? Colors.grey.shade300 : teamColor,
                          foregroundColor:
                              disabled ? Colors.grey : Colors.white,
                          fixedSize: Size(btnH, btnH),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      );
    } else {
      // Portrait: full-width card, pills above score.
      cardContent = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            isA ? 'Side A' : 'Side B',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 13,
              color: teamColor,
            ),
          ),
          const SizedBox(height: 6),
          _buildPlayerPills(players, isA, disabled, stacked: stackedPills),
          const SizedBox(height: 4),
          Text(
            '$score',
            style: TextStyle(
              fontSize: 56,
              fontWeight: FontWeight.bold,
              height: 1.0,
              color: disabled ? Colors.black38 : Colors.black87,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton.filled(
                icon: const Icon(Icons.remove),
                onPressed: onDecrement,
                tooltip: 'Decrease',
                style: IconButton.styleFrom(
                  backgroundColor: disabled ? Colors.grey.shade300 : teamColor,
                  foregroundColor: disabled ? Colors.grey : Colors.white,
                ),
              ),
              IconButton.filled(
                icon: const Icon(Icons.add),
                onPressed: onIncrement,
                tooltip: 'Increase',
                style: IconButton.styleFrom(
                  backgroundColor: disabled ? Colors.grey.shade300 : teamColor,
                  foregroundColor: disabled ? Colors.grey : Colors.white,
                ),
              ),
            ],
          ),
        ],
      );
    }

    return Card(
      color: cardBg,
      elevation: isLeading ? 6 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: teamColor.withValues(alpha: isLeading ? 1.0 : 0.55),
          width: isLeading ? 2.5 : 1.5,
        ),
      ),
      child: Padding(
        padding: landscape
            ? const EdgeInsets.fromLTRB(10, 8, 10, 8)
            : const EdgeInsets.fromLTRB(10, 12, 10, 10),
        child: cardContent,
      ),
    );
  }

  // ── Match Actions (sit-outs at the bottom) ────────────────────────────────

  Widget _buildMatchActions({required List<String> sittingOut}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Info pills row
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            _chip(Icons.emoji_events_rounded, _t.name, _kOliveLight, _kOlive),
            _chip(
              Icons.tag_rounded,
              'Round ${_round.roundNumber}',
              _kGoldLight,
              _kGold,
            ),
            _chip(
              Icons.crop_square_rounded,
              'Court ${_game.courtNumber}',
              _kGoldLight,
              _kGold,
            ),
            _chip(
              Icons.schedule_rounded,
              ScrambleService.formatTime(_round.scheduledStartTime),
              Colors.grey.shade100,
              Colors.black45,
            ),
            _chip(
              Icons.timer_rounded,
              ScrambleService.formatDuration(_round.matchDuration),
              _kOliveLight,
              _kOlive,
            ),
            _chip(
              Icons.grid_view_rounded,
              '${_t.playersPerTeam}v${_t.playersPerTeam}',
              Colors.grey.shade100,
              Colors.black45,
            ),
            _chip(
              Icons.people_rounded,
              '${_t.playerCount} players',
              Colors.grey.shade100,
              Colors.black45,
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Primary action
        if (_matchCompleted)
          OutlinedButton.icon(
            onPressed: _undoCompletion,
            icon: const Icon(Icons.undo_rounded, size: 18),
            label: const Text('Undo Completion'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.black54,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          )
        else if (_game.status == ScrambleGameStatus.scheduled)
          ElevatedButton.icon(
            onPressed: _startMatch,
            icon: const Icon(Icons.play_arrow_rounded, size: 20),
            label: const Text(
              'Start Match',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _kOlive,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          )
        else
          ElevatedButton.icon(
            onPressed: _completeGame,
            icon: const Icon(Icons.emoji_events_rounded, size: 18),
            label: const Text(
              'Complete Game',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _kOlive,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        // Manually Set Score — only before completion
        if (!_matchCompleted) ...[
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _onManualScore,
            icon: const Icon(Icons.edit_rounded, size: 18),
            label: const Text('Manually Set Score'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.black54,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () => Navigator.of(context).pop(_t),
          icon: const Icon(Icons.arrow_back_rounded, size: 18),
          label: const Text('Back to Schedule'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        // Sit-outs at the very bottom of Match Actions
        if (sittingOut.isNotEmpty) ...[
          const SizedBox(height: 12),
          _buildSittingOutRow(sittingOut),
        ],
      ],
    );
  }

  // ── Manual score entry ────────────────────────────────────────────────────

  void _onManualScore() {
    if (_scoreA != 0 || _scoreB != 0) {
      _showManualScoreBlockedDialog();
    } else {
      _showManualScoreDialog();
    }
  }

  Future<void> _showManualScoreDialog() async {
    final sideALabel = _game.sideAPlayerIds
        .map((id) => _t.getPlayer(id)?.name ?? id)
        .join(' & ');
    final sideBLabel = _game.sideBPlayerIds
        .map((id) => _t.getPlayer(id)?.name ?? id)
        .join(' & ');
    final ctrlA = TextEditingController(text: '0');
    final ctrlB = TextEditingController(text: '0');

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Colors.white,
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
        contentPadding: const EdgeInsets.fromLTRB(24, 14, 24, 0),
        actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _kOliveLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.edit_rounded, color: _kOlive, size: 20),
            ),
            const SizedBox(width: 12),
            const Text(
              'Add Result Manually',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 4),
              const Text(
                'Use this when the game was played without live scoring. '
                'Enter the final score for both sides and complete the game.',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.black54,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              _scoreInputRow(sideALabel, ctrlA, _kGold),
              const SizedBox(height: 10),
              _scoreInputRow(sideBLabel, ctrlB, _kOlive),
            ],
          ),
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kOlive,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () {
                    final a = int.tryParse(ctrlA.text) ?? 0;
                    final b = int.tryParse(ctrlB.text) ?? 0;
                    Navigator.of(ctx).pop();
                    _completeWithManualScore(a, b);
                  },
                  child: const Text(
                    'Complete Game',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _scoreInputRow(
    String label,
    TextEditingController ctrl,
    Color color,
  ) => Row(
    children: [
      Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: Text(
          label,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      const SizedBox(width: 12),
      SizedBox(
        width: 64,
        child: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 10,
            ),
            isDense: true,
          ),
        ),
      ),
    ],
  );

  void _showManualScoreBlockedDialog() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Colors.white,
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
        contentPadding: const EdgeInsets.fromLTRB(24, 14, 24, 0),
        actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.block_rounded,
                color: Colors.black45,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Manual Score Not Available',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        content: const Text(
          'Manual score entry is only available before live scoring has '
          'started. This prevents accidentally overwriting points that '
          'were already tracked.',
          style: TextStyle(fontSize: 14, color: Colors.black87, height: 1.5),
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _kOlive,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text(
                'OK',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _completeWithManualScore(int scoreA, int scoreB) {
    final now = DateTime.now();
    final updatedGame = _game.copyWith(
      sideAScore: scoreA,
      sideBScore: scoreB,
      status: ScrambleGameStatus.completed,
      actualStartTime: now,
      actualEndTime: now,
    );
    setState(() {
      _scoreA = scoreA;
      _scoreB = scoreB;
      _game = updatedGame;
      _matchCompleted = true;
    });
    _persist(_t.updateGame(updatedGame));
  }

  // ── Upcoming Games section ────────────────────────────────────────────────

  Widget _buildUpcomingGames() {
    final upcoming = _upcomingGames();
    if (upcoming.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: const Text(
          'No upcoming games in this tournament.',
          style: TextStyle(fontSize: 13, color: Colors.black38),
          textAlign: TextAlign.center,
        ),
      );
    }

    return Column(
      children: upcoming.map((entry) {
        final g = entry.game;
        final r = entry.round;
        final sideANames = g.sideAPlayerIds
            .map((id) => _t.getPlayer(id)?.name ?? id)
            .join(' & ');
        final sideBNames = g.sideBPlayerIds
            .map((id) => _t.getPlayer(id)?.name ?? id)
            .join(' & ');

        return Container(
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _kOliveLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'R${r.roundNumber}',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: _kOlive,
                      ),
                    ),
                    Text(
                      'C${g.courtNumber}',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: _kOlive,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sideANames,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'vs $sideBNames',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Text(
                ScrambleService.formatTime(r.scheduledStartTime),
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.black45,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ── Section header (same as QuickGame _buildSectionHeader) ───────────────

  Widget _sectionHeader(String title, IconData icon, {Widget? trailing}) => Row(
    children: [
      Icon(icon, size: 15, color: _kOlive),
      const SizedBox(width: 6),
      Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: _kOlive,
          letterSpacing: 0.4,
        ),
      ),
      if (trailing != null) ...[const Spacer(), trailing],
    ],
  );
}
