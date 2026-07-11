import 'package:flutter/material.dart';
import 'scramble_timer_widget.dart';

/// Wall-clock-anchored session-timer persistence, shared by King of the
/// Court and Doghouse. Fixes the "timer doesn't continue after leaving and
/// returning to the scoreboard" bug: while running, the host's model stores
/// [sessionRemainingSecondsSnapshot] as of a wall-clock [sessionTimerAnchorSnapshot],
/// so live remaining = snapshot - (now - anchor), independent of whether
/// `Timer.periodic` kept ticking while the page was backgrounded/disposed.
///
/// Hosts must mix this in alongside `WidgetsBindingObserver` and explicitly
/// forward `didChangeAppLifecycleState` to [handleTimerLifecycleChange] —
/// mixin resolution order is not relied upon.
mixin SessionTimerPersistenceMixin<T extends StatefulWidget> on State<T> {
  // ── Host adapter (bridges to the host's own persisted model) ─────────────
  GlobalKey<ScrambleTimerWidgetState> get sessionTimerKey;
  Duration get sessionTotalDuration;
  int? get sessionRemainingSecondsSnapshot;
  DateTime? get sessionTimerAnchorSnapshot;
  bool get sessionIsCompleted;

  /// Persists a new remaining/anchor snapshot into the host's model and
  /// saves it. [clearTimerAnchor] takes precedence over [timerAnchor].
  void applySessionTimerSnapshot({
    int? remainingSeconds,
    DateTime? timerAnchor,
    bool clearTimerAnchor = false,
  });

  /// Fired whenever the running flag transitions, so the host can start/stop
  /// its own per-stint stopwatch in lockstep.
  void onSessionTimerRunningChanged(bool running);

  // ── Mixin-owned state, read by the host's build() ─────────────────────────
  Duration? _timerInitialRemaining;
  bool _timerRunning = false;

  /// Wall-clock-restored remaining used to seed the widget on (re)entry;
  /// null means "not restored" — fall back to the host's own snapshot.
  Duration? get timerInitialRemaining => _timerInitialRemaining;
  bool get timerRunning => _timerRunning;

  // ── Restore on (re)entry ───────────────────────────────────────────────────

  // While running, remaining is stored as of the anchor, so we subtract real
  // elapsed time — the timer keeps running across navigation, backgrounding
  // and cold restarts.
  void restoreTimer() {
    if (sessionIsCompleted || sessionTimerAnchorSnapshot == null) return;
    final anchored = Duration(
        seconds: sessionRemainingSecondsSnapshot ?? sessionTotalDuration.inSeconds);
    final remaining =
        anchored - DateTime.now().difference(sessionTimerAnchorSnapshot!);
    if (remaining > Duration.zero) {
      _timerInitialRemaining = remaining;
      _timerRunning = true;
      onSessionTimerRunningChanged(true);
      // Re-anchor so future reloads compute from now, not the stale anchor.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) persistTimerState();
      });
    } else {
      _timerInitialRemaining = Duration.zero;
      _timerRunning = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        applySessionTimerSnapshot(remainingSeconds: 0, clearTimerAnchor: true);
        sessionTimerKey.currentState?.markFinished();
      });
    }
  }

  // ── Persist ─────────────────────────────────────────────────────────────

  // Single source of timer persistence: snapshots the live remaining and, if
  // running, a fresh wall-clock anchor; otherwise clears the anchor.
  void persistTimerState() {
    final st = sessionTimerKey.currentState;
    final remaining = st?.remaining ??
        _timerInitialRemaining ??
        Duration(seconds: sessionRemainingSecondsSnapshot ?? sessionTotalDuration.inSeconds);
    final running = st?.timerState == ScrambleTimerState.running || _timerRunning;
    if (running) {
      applySessionTimerSnapshot(
          remainingSeconds: remaining.inSeconds, timerAnchor: DateTime.now());
    } else {
      applySessionTimerSnapshot(
          remainingSeconds: remaining.inSeconds, clearTimerAnchor: true);
    }
  }

  // ── App lifecycle ──────────────────────────────────────────────────────────

  void handleTimerLifecycleChange(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Re-sync the on-screen countdown after the OS suspended Timer.periodic
      // while backgrounded — recompute from the persisted wall-clock anchor.
      if (_timerRunning && sessionTimerAnchorSnapshot != null && !sessionIsCompleted) {
        final anchored = Duration(
            seconds: sessionRemainingSecondsSnapshot ?? sessionTotalDuration.inSeconds);
        final remaining =
            anchored - DateTime.now().difference(sessionTimerAnchorSnapshot!);
        if (remaining > Duration.zero) {
          sessionTimerKey.currentState?.setRemaining(remaining);
          persistTimerState();
        } else {
          sessionTimerKey.currentState?.markFinished();
          setState(() => _timerRunning = false);
          onSessionTimerRunningChanged(false);
          applySessionTimerSnapshot(remainingSeconds: 0, clearTimerAnchor: true);
        }
      }
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      persistTimerState();
    }
  }

  // ── Timer control ───────────────────────────────────────────────────────

  void startOrRestartTimer() {
    if (sessionIsCompleted) return;
    sessionTimerKey.currentState?.restart();
    sessionTimerKey.currentState?.start();
    setState(() => _timerRunning = true);
    onSessionTimerRunningChanged(true);
    persistTimerState();
  }

  void resumeTimer() {
    sessionTimerKey.currentState?.resume();
    setState(() => _timerRunning = true);
    onSessionTimerRunningChanged(true);
    persistTimerState();
  }

  void pauseTimer() {
    sessionTimerKey.currentState?.pause();
    setState(() => _timerRunning = false);
    onSessionTimerRunningChanged(false);
    persistTimerState();
  }

  void addSessionTime(Duration delta) {
    sessionTimerKey.currentState?.addTime(delta);
    persistTimerState();
  }

  /// For when the widget itself already reached zero (`onFinished` fired) —
  /// just flips the running flag without touching the widget again.
  void markSessionTimerStopped() {
    setState(() => _timerRunning = false);
    onSessionTimerRunningChanged(false);
  }

  /// For when host code starts the underlying widget directly (e.g. "start
  /// the session timer automatically when the first team is confirmed, if
  /// it hasn't been started yet") — flips the running flag without touching
  /// the widget itself.
  void noteTimerStartedExternally() {
    setState(() => _timerRunning = true);
    onSessionTimerRunningChanged(true);
  }
}
