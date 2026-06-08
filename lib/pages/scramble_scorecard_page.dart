import 'package:flutter/material.dart';
import '../app/app_colors.dart';
import '../models/scramble_tournament.dart';
import '../services/scramble_service.dart';
import '../services/scramble_storage_service.dart';
import '../widgets/scramble_timer_widget.dart';
import '../widgets/tournaq_app_bar.dart';

/// Per-game scoring screen for a Timed Scramble game.
///
/// Shows team rosters, live score controls, a match countdown timer,
/// and a break countdown timer. Timer overruns reflow the rest of the schedule.
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

  int _scoreA = 0;
  int _scoreB = 0;
  bool _matchCompleted = false;
  bool _showBreakTimer = false;

  final GlobalKey<ScrambleTimerWidgetState> _matchTimerKey = GlobalKey();
  final GlobalKey<ScrambleTimerWidgetState> _breakTimerKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _t = widget.tournament;
    _game = widget.game;
    _round = widget.round;
    _scoreA = _game.sideAScore;
    _scoreB = _game.sideBScore;
    _matchCompleted = _game.isCompleted;
    _showBreakTimer = _game.isCompleted;
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  List<String> _names(List<String> ids) =>
      ids.map((id) => _t.getPlayer(id)?.name ?? id).toList();

  void _persist(ScrambleTournament updated) {
    setState(() => _t = updated);
    ScrambleStorageService.save(updated);
    widget.onChanged(updated);
  }

  // ── Score actions ────────────────────────────────────────────────────────────

  void _addScore(bool isA) {
    if (_matchCompleted) return;
    setState(() {
      if (isA) { _scoreA++; } else { _scoreB++; }
    });
  }

  void _removeScore(bool isA) {
    if (_matchCompleted) return;
    setState(() {
      if (isA) { if (_scoreA > 0) { _scoreA--; } }
      else { if (_scoreB > 0) { _scoreB--; } }
    });
  }

  // ── Game completion ──────────────────────────────────────────────────────────

  void _completeGame() {
    final now = DateTime.now();
    final started = _game.actualStartTime ?? now;

    // Calculate how much the match deviated from scheduled duration.
    final actualDuration = now.difference(started);
    final delta = actualDuration - _round.matchDuration;

    final updatedGame = _game.copyWith(
      sideAScore: _scoreA,
      sideBScore: _scoreB,
      status: ScrambleGameStatus.completed,
      actualStartTime: started,
      actualEndTime: now,
    );

    var updated = _t.updateGame(updatedGame);

    // Reflow subsequent rounds if the match ran over/under by more than 30s.
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
      _showBreakTimer = true;
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
      _showBreakTimer = false;
    });
    _persist(_t.updateGame(updatedGame));
  }

  void _onMatchTimerFinished() {
    if (!_matchCompleted) _completeGame();
  }

  void _startMatch() {
    final now = DateTime.now();
    final updatedGame = _game.copyWith(
      status: ScrambleGameStatus.inProgress,
      actualStartTime: now,
    );
    setState(() => _game = updatedGame);
    _persist(_t.updateGame(updatedGame));
    _matchTimerKey.currentState?.start();
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final sideANames = _names(_game.sideAPlayerIds);
    final sideBNames = _names(_game.sideBPlayerIds);
    final sittingOut = _game.sittingOutPlayerIds
        .map((id) => _t.getPlayer(id)?.name ?? id)
        .toList();

    return Scaffold(
      appBar: TournaQAppBar(
        title:
            'Round ${_round.roundNumber}  ·  Court ${_game.courtNumber}',
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildRoundInfo(),
              const SizedBox(height: 16),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildTeamPanel(
                      names: sideANames,
                      score: _scoreA,
                      isWinner: _matchCompleted && _scoreA > _scoreB,
                      isA: true,
                    ),
                    const SizedBox(width: 10),
                    _buildTeamPanel(
                      names: sideBNames,
                      score: _scoreB,
                      isWinner: _matchCompleted && _scoreB > _scoreA,
                      isA: false,
                    ),
                  ],
                ),
              ),
              if (sittingOut.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Sitting out: ${sittingOut.join(', ')}',
                  style: const TextStyle(fontSize: 11, color: Colors.black38),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 16),
              _buildTimerSection(),
              const SizedBox(height: 12),
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoundInfo() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _chip(Icons.schedule_rounded,
            ScrambleService.formatTime(_round.scheduledStartTime),
            AppColors.goldCream, AppColors.goldDark),
        const SizedBox(width: 8),
        _chip(Icons.timer_rounded,
            ScrambleService.formatDuration(_round.matchDuration),
            AppColors.oliveLight, AppColors.olive),
        if (_round.breakDuration > Duration.zero) ...[
          const SizedBox(width: 8),
          _chip(Icons.coffee_rounded,
              ScrambleService.formatDuration(_round.breakDuration),
              Colors.grey.shade100, Colors.black45),
        ],
      ],
    );
  }

  Widget _chip(IconData icon, String label, Color bg, Color fg) =>
      Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
            color: bg, borderRadius: BorderRadius.circular(20)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: fg),
            const SizedBox(width: 4),
            Text(label,
                style: TextStyle(
                    fontSize: 12,
                    color: fg,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      );

  Widget _buildTeamPanel({
    required List<String> names,
    required int score,
    required bool isWinner,
    required bool isA,
  }) {
    final teamColor = isA ? AppColors.goldDark : AppColors.olive;
    final teamBg = isA ? AppColors.goldCream : AppColors.oliveLight;
    final label = isA ? 'Side A' : 'Side B';

    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isWinner
              ? (isA ? AppColors.goldCardLeading : AppColors.oliveCardLeading)
              : teamBg,
          borderRadius: BorderRadius.circular(16),
          border: isWinner
              ? Border.all(color: teamColor, width: 2)
              : null,
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isWinner)
                  const Padding(
                    padding: EdgeInsets.only(right: 4),
                    child: Icon(Icons.emoji_events_rounded,
                        size: 14, color: AppColors.goldDark),
                  ),
                Text(label,
                    style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        color: teamColor)),
              ],
            ),
            const SizedBox(height: 6),
            ...names.map((n) => Text(n,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 12, color: Colors.black87),
                maxLines: 1,
                overflow: TextOverflow.ellipsis)),
            const Spacer(),
            Text(
              '$score',
              style: TextStyle(
                fontSize: 64,
                fontWeight: FontWeight.w900,
                color: teamColor,
                height: 1,
              ),
            ),
            const Spacer(),
            if (!_matchCompleted) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _scoreBtn(
                      Icons.remove_rounded,
                      () => _removeScore(isA),
                      Colors.black26),
                  const SizedBox(width: 8),
                  _scoreBtn(
                      Icons.add_rounded,
                      () => _addScore(isA),
                      teamColor),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _scoreBtn(IconData icon, VoidCallback onTap, Color color) =>
      Material(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Icon(icon, size: 22, color: color),
          ),
        ),
      );

  Widget _buildTimerSection() {
    if (_showBreakTimer) {
      return Column(
        children: [
          const Text('BREAK',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.black38,
                  letterSpacing: 1)),
          const SizedBox(height: 4),
          ScrambleTimerWidget(
            key: _breakTimerKey,
            initial: _round.breakDuration,
            mode: ScrambleTimerMode.countdown,
            autoStart: true,
          ),
        ],
      );
    }

    return Column(
      children: [
        const Text('MATCH TIMER',
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Colors.black38,
                letterSpacing: 1)),
        const SizedBox(height: 4),
        ScrambleTimerWidget(
          key: _matchTimerKey,
          initial: _round.matchDuration,
          mode: ScrambleTimerMode.countdown,
          autoStart: false,
          onFinished: _onMatchTimerFinished,
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    if (_matchCompleted) {
      return Column(
        children: [
          OutlinedButton.icon(
            onPressed: _undoCompletion,
            icon: const Icon(Icons.undo_rounded, size: 18),
            label: const Text('Undo Completion'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.black54,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: () => Navigator.of(context).pop(_t),
            icon: const Icon(Icons.arrow_back_rounded, size: 18),
            label: const Text('Back to Schedule'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.olive,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      );
    }

    final isStarted = _game.status == ScrambleGameStatus.inProgress;

    return Column(
      children: [
        if (!isStarted)
          ElevatedButton.icon(
            onPressed: _startMatch,
            icon: const Icon(Icons.play_arrow_rounded, size: 20),
            label: const Text('Start Match',
                style: TextStyle(fontWeight: FontWeight.w700)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.olive,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        if (isStarted) ...[
          ElevatedButton.icon(
            onPressed: _completeGame,
            icon: const Icon(Icons.emoji_events_rounded, size: 18),
            label: const Text('Complete Game',
                style: TextStyle(fontWeight: FontWeight.w700)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.olive,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => Navigator.of(context).pop(_t),
            icon: const Icon(Icons.save_rounded, size: 18),
            label: const Text('Save & Return'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ],
    );
  }
}
