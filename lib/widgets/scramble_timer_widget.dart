import 'dart:async';
import 'package:flutter/material.dart';
import '../app/app_colors.dart';

enum ScrambleTimerMode { countdown, countup }

enum ScrambleTimerState { idle, running, paused, finished }

/// A self-contained timer display + controls widget.
///
/// Supports countdown (match) and countup (break) modes.
/// Calls [onFinished] when a countdown reaches zero.
/// Calls [onTick] every second while running so the parent can react.
class ScrambleTimerWidget extends StatefulWidget {
  final Duration initial;
  final ScrambleTimerMode mode;
  final bool autoStart;
  final void Function(Duration elapsed)? onTick;
  final VoidCallback? onFinished;
  final bool compact;

  const ScrambleTimerWidget({
    super.key,
    required this.initial,
    this.mode = ScrambleTimerMode.countdown,
    this.autoStart = false,
    this.onTick,
    this.onFinished,
    this.compact = false,
  });

  @override
  State<ScrambleTimerWidget> createState() => ScrambleTimerWidgetState();
}

class ScrambleTimerWidgetState extends State<ScrambleTimerWidget> {
  late Duration _remaining;
  late Duration _elapsed;
  ScrambleTimerState _state = ScrambleTimerState.idle;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _remaining = widget.initial;
    _elapsed = Duration.zero;
    if (widget.autoStart) _start();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  // ── Public API ──────────────────────────────────────────────────────────────

  void start() => _start();
  void pause() => _pause();
  void resume() => _resume();
  void restart() => _restart();
  Duration get elapsed => _elapsed;
  ScrambleTimerState get timerState => _state;

  void addTime(Duration delta) {
    setState(() {
      if (widget.mode == ScrambleTimerMode.countdown) {
        _remaining = _remaining + delta;
        if (_remaining < Duration.zero) _remaining = Duration.zero;
      }
    });
  }

  void setRemaining(Duration d) {
    setState(() {
      _remaining = d < Duration.zero ? Duration.zero : d;
    });
  }

  // ── Internal ────────────────────────────────────────────────────────────────

  void _start() {
    if (_state == ScrambleTimerState.running) return;
    setState(() => _state = ScrambleTimerState.running);
    _ticker = Timer.periodic(const Duration(seconds: 1), _onTick);
  }

  void _pause() {
    if (_state != ScrambleTimerState.running) return;
    _ticker?.cancel();
    setState(() => _state = ScrambleTimerState.paused);
  }

  void _resume() {
    if (_state != ScrambleTimerState.paused) return;
    setState(() => _state = ScrambleTimerState.running);
    _ticker = Timer.periodic(const Duration(seconds: 1), _onTick);
  }

  void _restart() {
    _ticker?.cancel();
    setState(() {
      _remaining = widget.initial;
      _elapsed = Duration.zero;
      _state = ScrambleTimerState.idle;
    });
  }

  void _onTick(Timer _) {
    setState(() {
      _elapsed += const Duration(seconds: 1);
      if (widget.mode == ScrambleTimerMode.countdown) {
        _remaining -= const Duration(seconds: 1);
        if (_remaining <= Duration.zero) {
          _remaining = Duration.zero;
          _state = ScrambleTimerState.finished;
          _ticker?.cancel();
          widget.onFinished?.call();
        }
      }
    });
    widget.onTick?.call(_elapsed);
  }

  // ── UI ──────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final display = widget.mode == ScrambleTimerMode.countdown
        ? _remaining
        : _elapsed;
    final isUrgent = widget.mode == ScrambleTimerMode.countdown &&
        _remaining.inSeconds <= 60 &&
        _state == ScrambleTimerState.running;
    final isFinished = _state == ScrambleTimerState.finished;

    final displayColor = isFinished
        ? Colors.red
        : isUrgent
            ? Colors.orange
            : AppColors.oliveMedium;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildDisplay(display, displayColor),
        if (!widget.compact) ...[
          const SizedBox(height: 8),
          _buildControls(),
        ],
      ],
    );
  }

  Widget _buildDisplay(Duration d, Color color) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    final text = h > 0 ? '$h:$m:$s' : '$m:$s';
    final fontSize = widget.compact ? 28.0 : 52.0;

    return Text(
      text,
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.w800,
        color: color,
        fontFeatures: const [FontFeature.tabularFigures()],
        letterSpacing: 2,
      ),
    );
  }

  Widget _buildControls() {
    final isRunning = _state == ScrambleTimerState.running;
    final isPaused = _state == ScrambleTimerState.paused;
    final isIdle = _state == ScrambleTimerState.idle;
    final isFinished = _state == ScrambleTimerState.finished;

    return Wrap(
      spacing: 8,
      alignment: WrapAlignment.center,
      children: [
        if (isIdle || isFinished)
          _controlBtn(Icons.play_arrow_rounded, 'Start', _start,
              color: AppColors.olive),
        if (isRunning)
          _controlBtn(Icons.pause_rounded, 'Pause', _pause),
        if (isPaused)
          _controlBtn(Icons.play_arrow_rounded, 'Resume', _resume,
              color: AppColors.olive),
        if (!isIdle)
          _controlBtn(Icons.replay_rounded, 'Restart', _restart),
        if (isRunning || isPaused) ...[
          _controlBtn(Icons.add_rounded, '+1m',
              () => addTime(const Duration(minutes: 1))),
          _controlBtn(Icons.remove_rounded, '-1m',
              () => addTime(const Duration(minutes: -1))),
        ],
      ],
    );
  }

  Widget _controlBtn(
    IconData icon,
    String label,
    VoidCallback onTap, {
    Color? color,
  }) {
    return TextButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      style: TextButton.styleFrom(
        foregroundColor: color ?? Colors.black54,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      ),
    );
  }
}
