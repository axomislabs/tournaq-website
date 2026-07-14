import 'package:flutter/material.dart';
import '../app/app_colors.dart';
import '../l10n/app_localizations.dart';
import '../models/group.dart';
import '../models/player.dart';
import '../models/player_status.dart';
import '../models/scramble_king_tournament.dart';
import '../services/local_storage_service.dart';
import '../services/scramble_king_service.dart';
import '../services/scramble_king_storage_service.dart';
import '../services/scramble_king_transfer_service.dart';
import '../widgets/bracket_background.dart';
import '../widgets/player_picker_sheet.dart';
import '../widgets/qr_export_sheet.dart';
import '../widgets/scramble_king_court_result_tile.dart';
import '../widgets/sheet_helpers.dart';
import '../widgets/tournament_player_row.dart';
import '../widgets/tournaq_app_bar.dart';
import 'qr_scan_page.dart';
import 'scramble_king_court_page.dart';
import 'scramble_king_stats_page.dart';

class ScrambleKingOverviewPage extends StatefulWidget {
  final ScrambleKingTournament tournament;
  final List<Player> existingPlayers;
  final List<Group> existingGroups;
  final void Function(ScrambleKingTournament) onChanged;
  final Player Function(String name) onCreatePlayer;
  final void Function(String playerId, String newName)? onUpdatePlayer;

  const ScrambleKingOverviewPage({
    super.key,
    required this.tournament,
    this.existingPlayers = const [],
    this.existingGroups = const [],
    required this.onChanged,
    required this.onCreatePlayer,
    this.onUpdatePlayer,
  });

  @override
  State<ScrambleKingOverviewPage> createState() =>
      _ScrambleKingOverviewPageState();
}

class _ScrambleKingOverviewPageState extends State<ScrambleKingOverviewPage> {
  late ScrambleKingTournament _t;
  final Set<String> _expandedRoundIds = {};
  // Tournament-wide "Teams" sheet filters — every team across every round,
  // filterable by round and by court; persisted here so they survive
  // between openings of the sheet.
  int? _teamsRoundFilter; // round number; null ⇒ all rounds
  int? _teamsCourtFilter; // court number; null ⇒ all courts

  // Players / Timeline / Teams now live in their own bottom sheets (opened
  // from the header pills) rather than always-expanded inline sections —
  // these let any mutation refresh the sheet in place while it's open, the
  // same pattern used in the regular Scramble mode's overview page.
  StateSetter? _playersSheetSetState;
  StateSetter? _timelineSheetSetState;
  StateSetter? _teamsSheetSetState;

  @override
  void initState() {
    super.initState();
    _t = widget.tournament;
    // Expand only the current/active round on open (first not-yet-finished
    // round, else the last round).
    final active = _t.rounds.cast<ScrambleKingRound?>().firstWhere(
      (r) => !r!.isCompleted,
      orElse: () => _t.rounds.isNotEmpty ? _t.rounds.last : null,
    );
    if (active != null) _expandedRoundIds.add(active.id);
  }

  void _update(ScrambleKingTournament updated) {
    setState(() => _t = updated);
    ScrambleKingStorageService.save(updated);
    widget.onChanged(updated);
    _playersSheetSetState?.call(() {});
    _timelineSheetSetState?.call(() {});
    _teamsSheetSetState?.call(() {});
  }

  Future<void> _openCourt(ScrambleKingRound round, int courtNumber) async {
    final updated = await Navigator.of(context).push<ScrambleKingTournament>(
      MaterialPageRoute(
        builder: (_) => ScrambleKingCourtPage(
          tournament: _t,
          roundId: round.id,
          courtNumber: courtNumber,
          onChanged: _update,
        ),
      ),
    );
    if (updated != null) _update(updated);
  }

  void _openStats() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ScrambleKingStatsPage(tournament: _t)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final completed = _t.completedRounds;
    final total = _t.roundCount;
    final progress = _t.progressFraction;

    return Scaffold(
      appBar: TournaQAppBar(
        title: l10n.modeScrambleKingName,
        subtitle: _t.name,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.leaderboard_rounded,
              color: AppColors.goldLight,
            ),
            tooltip: l10n.tooltipRankings,
            onPressed: _openStats,
          ),
        ],
      ),
      body: BracketBackground(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            _sectionDivider(
              l10n.overviewSectionOverview,
              Icons.bar_chart_rounded,
            ),
            const SizedBox(height: 10),
            _buildHeader(l10n, completed, total, progress),
            const SizedBox(height: 20),
            _sectionDivider(
              l10n.overviewSectionSchedule,
              Icons.event_note_rounded,
            ),
            const SizedBox(height: 10),
            ..._buildRoundSections(l10n),
          ],
        ),
      ),
    );
  }

  // ── Section divider ───────────────────────────────────────────────────────

  Widget _sectionDivider(String label, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(icon, size: 14, color: AppColors.oliveMedium),
          const SizedBox(width: 6),
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.oliveMedium,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(width: 8),
          const Expanded(child: Divider(height: 1)),
        ],
      ),
    );
  }

  // ── Overview header ───────────────────────────────────────────────────────

  Widget _buildHeader(
    AppLocalizations l10n,
    int completed,
    int total,
    double progress,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.oliveLight,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.scrambleKingRoundsProgress(completed, total),
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
              _buildProgressRing(progress),
            ],
          ),
          const SizedBox(height: 10),
          _buildInfoPills(l10n),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: Colors.white,
              valueColor: const AlwaysStoppedAnimation(AppColors.olive),
            ),
          ),
        ],
      ),
    );
  }

  bool get _hasFloater =>
      _t.rounds.any((r) => r.courts.any((c) => c.floaterSlot != null));

  String _assignmentModeLabel(
    AppLocalizations l10n,
  ) => switch (_t.assignmentMode) {
    ScrambleKingAssignmentMode.manual => l10n.doghouseAssignmentManual,
    ScrambleKingAssignmentMode.automated => l10n.doghouseAssignmentAutomated,
    ScrambleKingAssignmentMode.automatedAllPlay => l10n.setupFormatAutoAllplay,
  };

  String _oddPlayerModeLabel(AppLocalizations l10n) =>
      _t.oddPlayerMode == ScrambleKingOddPlayerMode.jumper
      ? l10n.scrambleKingOddPlayerJumperLabel
      : l10n.scrambleKingOddPlayerPlaceholderLabel;

  /// Every tournament-level setting or section as a pill: rounds/courts/
  /// strike/assignment/odd-player open the shared edit sheet; players,
  /// teams and estimated finish each open their own dedicated sheet (the
  /// content that used to be always-expanded inline sections). Only team
  /// size stays informational-only for now — full configurable team size is
  /// a separate, larger project.
  Widget _buildInfoPills(AppLocalizations l10n) {
    final lastRound = _t.rounds.isNotEmpty ? _t.rounds.last : null;
    final estFinish =
        lastRound?.actualEndTime ?? lastRound?.scheduledBreakEndTime;
    final finished = _t.completedRounds == _t.roundCount && _t.roundCount > 0;

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        _infoPill(
          Icons.repeat_rounded,
          l10n.scrambleKingRoundsPill(_t.roundCount),
          onTap: _showFormatEditSheet,
        ),
        _infoPill(
          Icons.sports_volleyball_rounded,
          l10n.scrambleKingCourtsPill(_t.courtCount),
          onTap: _showFormatEditSheet,
        ),
        _infoPill(
          Icons.group_rounded,
          l10n.scrambleKingPlayersPill(_t.playerCount),
          onTap: _showPlayersSheet,
        ),
        _infoPill(
          Icons.groups_rounded,
          l10n.scrambleKingTeamsLabel,
          onTap: _showTeamsSheet,
        ),
        _infoPill(Icons.grid_view_rounded, '2v2'),
        if (estFinish != null)
          _infoPill(
            Icons.flag_outlined,
            finished
                ? l10n.overviewFinished(_fmtTime(estFinish))
                : l10n.overviewEstFinish(_fmtTime(estFinish)),
            onTap: _showTimelineSheet,
          ),
        if (_t.strikePoints > 0)
          _infoPill(
            Icons.bolt_rounded,
            l10n.kotcStrikePoints(_t.strikePoints),
            onTap: _showFormatEditSheet,
          ),
        _infoPill(
          Icons.tune_rounded,
          _assignmentModeLabel(l10n),
          onTap: _showFormatEditSheet,
        ),
        if (_hasFloater)
          _infoPill(
            Icons.swap_horiz_rounded,
            _oddPlayerModeLabel(l10n),
            onTap: _showFormatEditSheet,
          ),
      ],
    );
  }

  Widget _infoPill(IconData icon, String label, {VoidCallback? onTap}) =>
      Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 13, color: AppColors.olive),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.olive,
                  ),
                ),
                if (onTap != null) ...[
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.edit_rounded,
                    size: 11,
                    color: Colors.black38,
                  ),
                ],
              ],
            ),
          ),
        ),
      );

  Widget _buildProgressRing(double progress) {
    return SizedBox(
      width: 52,
      height: 52,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: progress,
            strokeWidth: 5,
            backgroundColor: Colors.white,
            valueColor: const AlwaysStoppedAnimation(AppColors.olive),
          ),
          Text(
            '${(progress * 100).round()}%',
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  static String _fmtTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  // ── Timeline section ──────────────────────────────────────────────────────

  /// Opened from the header's "Est. finish" pill. Shows the tournament
  /// start/predicted-end row (tap to edit) plus the per-round timeline —
  /// mirrors the regular Scramble mode's schedule preview sheet.
  void _showTimelineSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) {
          _timelineSheetSetState = setSheet;
          final l10n = AppLocalizations.of(context)!;
          return TournaQSheet(
            body: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                20,
                8,
                20,
                MediaQuery.of(ctx).viewInsets.bottom + 32,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l10n.overviewSectionTimeline,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.goldCream,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildStartAndEndRow(),
                        const SizedBox(height: 8),
                        const Divider(
                          height: 1,
                          thickness: 0.5,
                          color: AppColors.goldDark,
                        ),
                        const SizedBox(height: 4),
                        ..._buildTimelineRows(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    ).whenComplete(() => _timelineSheetSetState = null);
  }

  Widget _buildStartAndEndRow() {
    if (_t.rounds.isEmpty) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context)!;

    final allDone = _t.rounds.every((r) => r.actualEndTime != null);
    final DateTime predictedEnd;
    if (allDone) {
      predictedEnd = _t.rounds
          .map((r) => r.actualEndTime!)
          .reduce((a, b) => a.isAfter(b) ? a : b);
    } else {
      predictedEnd = _t.rounds.last.scheduledBreakEndTime;
    }
    final endText = allDone
        ? l10n.overviewFinished(_fmtTime(predictedEnd))
        : l10n.timelinePredictedEnd(_fmtTime(predictedEnd));

    return InkWell(
      onTap: _showOverallEditSheet,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.play_circle_outline_rounded,
                        size: 13,
                        color: Colors.black38,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        l10n.timelineStart(_fmtTime(_t.startTime)),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(
                        allDone
                            ? Icons.check_circle_outline_rounded
                            : Icons.flag_outlined,
                        size: 13,
                        color: allDone ? AppColors.olive : Colors.black38,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        endText,
                        style: TextStyle(
                          fontSize: 12,
                          color: allDone ? AppColors.olive : Colors.black54,
                          fontWeight: allDone
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.edit_rounded, size: 14, color: AppColors.olive),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildTimelineRows() {
    final l10n = AppLocalizations.of(context)!;
    final now = DateTime.now();
    return _t.rounds.map((round) {
      final allDone = round.isCompleted;
      final isOverdue = !allDone && now.isAfter(round.scheduledMatchEndTime);
      final hasStarted = now.isAfter(round.scheduledStartTime);

      final Color statusColor;
      if (allDone) {
        statusColor = AppColors.olive;
      } else if (isOverdue) {
        statusColor = Colors.red.shade400;
      } else if (hasStarted) {
        statusColor = AppColors.gold;
      } else {
        statusColor = Colors.black26;
      }

      final timeLabel =
          '${_fmtTime(round.scheduledStartTime)} – ${_fmtTime(round.scheduledMatchEndTime)}';
      final breakTime = round.breakDuration > Duration.zero
          ? _fmtTime(round.scheduledBreakEndTime)
          : null;

      return InkWell(
        onTap: () => _showRoundEditSheet(round),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
          child: Row(
            children: [
              SizedBox(
                width: 66,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: allDone ? AppColors.olive : AppColors.goldCream,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    l10n.scrambleKingRoundLabel(round.roundNumber),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: allDone ? Colors.white : AppColors.goldDark,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      timeLabel,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                    if (breakTime != null)
                      Text(
                        l10n.timelineBreakUntil(breakTime),
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.black38,
                        ),
                      ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_t.paceAlertsEnabled) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(
                          alpha: allDone ? 1.0 : 0.12,
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        allDone
                            ? l10n.statusCompleted
                            : isOverdue
                            ? l10n.statusOverdue
                            : hasStarted
                            ? l10n.statusDue
                            : l10n.statusUpcoming,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: allDone ? Colors.white : statusColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                  ],
                  const Icon(
                    Icons.edit_rounded,
                    size: 13,
                    color: Colors.black26,
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }).toList();
  }

  // ── Timeline editing ──────────────────────────────────────────────────────

  void _showOverallEditSheet() {
    TimeOfDay startTime = TimeOfDay.fromDateTime(_t.startTime);
    final firstPending = _t.rounds.cast<ScrambleKingRound?>().firstWhere(
      (r) => !r!.isCompleted,
      orElse: () => null,
    );
    int matchMinutes =
        (firstPending ?? _t.rounds.first).matchDuration.inMinutes;
    int breakMinutes =
        (firstPending ?? _t.rounds.first).breakDuration.inMinutes;
    bool paceAlertsEnabled = _t.paceAlertsEnabled;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) {
          final l10n = AppLocalizations.of(context)!;
          return TournaQSheet(
            body: Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                8,
                20,
                MediaQuery.of(ctx).viewInsets.bottom + 32,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          l10n.timelineScheduleTitle,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          _applyOverallEdit(
                            startTime,
                            matchMinutes,
                            breakMinutes,
                            paceAlertsEnabled,
                          );
                          Navigator.of(ctx).pop();
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.gold,
                        ),
                        child: Text(
                          l10n.btnSave,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    l10n.timelineTournamentStart,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 6),
                  _buildTimeTile(startTime.format(ctx), () async {
                    final picked = await showTimePicker(
                      context: ctx,
                      initialTime: startTime,
                    );
                    if (picked != null) setSheet(() => startTime = picked);
                  }),
                  const SizedBox(height: 16),
                  Text(
                    l10n.timelineGameDuration,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 6),
                  _buildMinutePicker(
                    value: matchMinutes,
                    min: 1,
                    onChanged: (v) => setSheet(() => matchMinutes = v),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.timelineBreakDurationPending,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 6),
                  _buildMinutePicker(
                    value: breakMinutes,
                    min: 0,
                    onChanged: (v) => setSheet(() => breakMinutes = v),
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: paceAlertsEnabled,
                    onChanged: (v) => setSheet(() => paceAlertsEnabled = v),
                    activeThumbColor: AppColors.gold,
                    title: Text(
                      l10n.timelinePaceAlertsTitle,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      l10n.timelinePaceAlertsSubtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _applyOverallEdit(
    TimeOfDay newTime,
    int matchMinutes,
    int breakMinutes,
    bool paceAlertsEnabled,
  ) {
    final old = _t.startTime;
    final newStart = DateTime(
      old.year,
      old.month,
      old.day,
      newTime.hour,
      newTime.minute,
    );

    var rounds = List<ScrambleKingRound>.from(_t.rounds);
    var cursor = newStart;

    for (var i = 0; i < rounds.length; i++) {
      if (rounds[i].isCompleted) {
        final r = rounds[i];
        final afterBreak = r.actualEndTime!.add(r.breakDuration);
        if (afterBreak.isAfter(cursor)) cursor = afterBreak;
        continue;
      }
      rounds[i] = rounds[i].copyWith(
        scheduledStartTime: cursor,
        matchDuration: Duration(minutes: matchMinutes),
        breakDuration: Duration(minutes: breakMinutes),
      );
      cursor = cursor.add(Duration(minutes: matchMinutes + breakMinutes));
    }

    _update(
      _t.copyWith(
        startTime: newStart,
        rounds: rounds,
        paceAlertsEnabled: paceAlertsEnabled,
      ),
    );
  }

  // ── Format editing (assignment mode + odd-player handling) ─────────────────

  void _showFormatEditSheet() {
    var assignment = _t.assignmentMode;
    var oddPlayer = _t.oddPlayerMode;
    var rounds = _t.roundCount;
    var courts = _t.courtCount;
    var strike = _t.strikePoints;
    final minRounds = _minRoundCount();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) {
          final l10n = AppLocalizations.of(context)!;
          return TournaQSheet(
            body: Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                8,
                20,
                MediaQuery.of(ctx).viewInsets.bottom + 32,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          l10n.scrambleKingEditFormatTitle,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          var updated = _t;
                          if (courts != _t.courtCount) {
                            final activeCount = _t.players
                                .where((p) => p.isActive)
                                .length;
                            if (ScrambleKingService.decideCourtSizes(
                              activeCount,
                              courts,
                            ).isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    l10n.scrambleKingInvalidCourtCount,
                                  ),
                                ),
                              );
                              return;
                            }
                            updated =
                                ScrambleKingService.rebuildRemainingRounds(
                                  updated.copyWith(courtCount: courts),
                                  updated.players,
                                );
                          }
                          if (rounds != _t.roundCount) {
                            updated = ScrambleKingService.setRoundCount(
                              updated,
                              rounds,
                            );
                          }
                          updated = updated.copyWith(
                            assignmentMode: assignment,
                            oddPlayerMode: oddPlayer,
                            strikePoints: strike,
                          );
                          _update(updated);
                          Navigator.of(ctx).pop();
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.gold,
                        ),
                        child: Text(
                          l10n.btnSave,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    l10n.scrambleKingRoundsPillLabel,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 6),
                  _buildCountStepper(
                    value: rounds,
                    min: minRounds,
                    onChanged: (v) => setSheet(() => rounds = v),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.scrambleKingCourtsPillLabel,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 6),
                  _buildCountStepper(
                    value: courts,
                    min: 1,
                    max: 8,
                    onChanged: (v) => setSheet(() => courts = v),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.kotcSetupStrikeLabel,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 6),
                  _buildCountStepper(
                    value: strike,
                    min: 0,
                    onChanged: (v) => setSheet(() => strike = v),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.kotcSetupAssignmentLabel,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<ScrambleKingAssignmentMode>(
                    initialValue: assignment,
                    isDense: true,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    items: [
                      DropdownMenuItem(
                        value: ScrambleKingAssignmentMode.manual,
                        child: Text(l10n.doghouseAssignmentManual),
                      ),
                      DropdownMenuItem(
                        value: ScrambleKingAssignmentMode.automated,
                        child: Text(l10n.doghouseAssignmentAutomated),
                      ),
                      DropdownMenuItem(
                        value: ScrambleKingAssignmentMode.automatedAllPlay,
                        child: Text(l10n.setupFormatAutoAllplay),
                      ),
                    ],
                    onChanged: (v) {
                      if (v != null) setSheet(() => assignment = v);
                    },
                  ),
                  if (_hasFloater) ...[
                    const SizedBox(height: 16),
                    Text(
                      l10n.scrambleKingOddPlayerLabel,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<ScrambleKingOddPlayerMode>(
                      initialValue: oddPlayer,
                      isDense: true,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.fromLTRB(
                          12,
                          10,
                          4,
                          10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      items: [
                        DropdownMenuItem(
                          value: ScrambleKingOddPlayerMode.placeholder,
                          child: Text(
                            l10n.scrambleKingOddPlayerPlaceholderLabel,
                          ),
                        ),
                        DropdownMenuItem(
                          value: ScrambleKingOddPlayerMode.jumper,
                          child: Text(l10n.scrambleKingOddPlayerJumperLabel),
                        ),
                      ],
                      onChanged: (v) {
                        if (v != null) setSheet(() => oddPlayer = v);
                      },
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showRoundEditSheet(ScrambleKingRound round) {
    TimeOfDay startTime = TimeOfDay.fromDateTime(round.scheduledStartTime);
    int matchMinutes = round.matchDuration.inMinutes;
    int breakMinutes = round.breakDuration.inMinutes;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) {
          final l10n = AppLocalizations.of(context)!;
          return TournaQSheet(
            body: Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                8,
                20,
                MediaQuery.of(ctx).viewInsets.bottom + 32,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          l10n.scrambleKingRoundLabel(round.roundNumber),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          final d = round.scheduledStartTime;
                          final newStart = DateTime(
                            d.year,
                            d.month,
                            d.day,
                            startTime.hour,
                            startTime.minute,
                          );
                          final updatedRound = round.copyWith(
                            scheduledStartTime: newStart,
                            matchDuration: Duration(minutes: matchMinutes),
                            breakDuration: Duration(minutes: breakMinutes),
                          );
                          final rounds = List<ScrambleKingRound>.from(
                            _t.rounds,
                          );
                          final idx = rounds.indexWhere(
                            (r) => r.id == round.id,
                          );
                          rounds[idx] = updatedRound;
                          var cursor = updatedRound.scheduledBreakEndTime;
                          for (var i = idx + 1; i < rounds.length; i++) {
                            if (rounds[i].isCompleted) {
                              final r = rounds[i];
                              final afterBreak = r.actualEndTime!.add(
                                r.breakDuration,
                              );
                              if (afterBreak.isAfter(cursor)) {
                                cursor = afterBreak;
                              }
                              continue;
                            }
                            rounds[i] = rounds[i].copyWith(
                              scheduledStartTime: cursor,
                            );
                            cursor = cursor.add(
                              rounds[i].matchDuration + rounds[i].breakDuration,
                            );
                          }
                          _update(_t.copyWith(rounds: rounds));
                          Navigator.of(ctx).pop();
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.gold,
                        ),
                        child: Text(
                          l10n.btnSave,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    l10n.timelineEditStartTime,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 6),
                  _buildTimeTile(startTime.format(ctx), () async {
                    final picked = await showTimePicker(
                      context: ctx,
                      initialTime: startTime,
                    );
                    if (picked != null) setSheet(() => startTime = picked);
                  }),
                  const SizedBox(height: 16),
                  Text(
                    l10n.timelineMatchDuration,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 6),
                  _buildMinutePicker(
                    value: matchMinutes,
                    min: 1,
                    onChanged: (v) => setSheet(() => matchMinutes = v),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.timelineBreakAfterRound,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 6),
                  _buildMinutePicker(
                    value: breakMinutes,
                    min: 0,
                    onChanged: (v) => setSheet(() => breakMinutes = v),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTimeTile(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.access_time_rounded,
              size: 16,
              color: Colors.black38,
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
            ),
            const Spacer(),
            const Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: Colors.black38,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMinutePicker({
    required int value,
    required int min,
    required void Function(int) onChanged,
  }) {
    final label = value == 1 ? '1 min' : '$value min';
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.remove_rounded, size: 20),
            onPressed: value > min ? () => onChanged(value - 1) : null,
          ),
          Expanded(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add_rounded, size: 20),
            onPressed: () => onChanged(value + 1),
          ),
        ],
      ),
    );
  }

  /// A bare-number stepper (no unit suffix) — used for rounds/courts/strike
  /// point counts, as opposed to `_buildMinutePicker`'s "N min" duration.
  Widget _buildCountStepper({
    required int value,
    required int min,
    int? max,
    required void Function(int) onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.remove_rounded, size: 20),
            onPressed: value > min ? () => onChanged(value - 1) : null,
          ),
          Expanded(
            child: Text(
              '$value',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add_rounded, size: 20),
            onPressed: (max == null || value < max)
                ? () => onChanged(value + 1)
                : null,
          ),
        ],
      ),
    );
  }

  /// The lowest round count that can be applied without dropping a round
  /// that already has stints or a started court — mirrors
  /// `ScrambleKingService.setRoundCount`'s own clamp exactly, so the stepper
  /// never lets the coach request a value that would silently get raised.
  int _minRoundCount() {
    final sorted = _t.rounds.toList()
      ..sort((a, b) => a.roundNumber.compareTo(b.roundNumber));
    for (var i = 0; i < sorted.length; i++) {
      final round = sorted[i];
      final untouched =
          _t.getStintsForRound(round.id).isEmpty &&
          round.courts.every((c) => c.actualStartTime == null);
      if (untouched) return i;
    }
    return sorted.length;
  }

  // ── Players section ───────────────────────────────────────────────────────

  /// Opened from the header's "Players" pill — mirrors the regular Scramble
  /// mode's players sheet.
  void _showPlayersSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) {
          _playersSheetSetState = setSheet;
          final l10n = AppLocalizations.of(context)!;
          final isLive =
              _t.status != ScrambleKingTournamentStatus.completed &&
              _t.rounds.isNotEmpty;
          return TournaQSheet(
            body: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                20,
                8,
                20,
                MediaQuery.of(ctx).viewInsets.bottom + 32,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l10n.overviewSectionPlayers(_t.players.length),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (isLive) ...[
                    _buildAddPlayerButton(l10n),
                    const SizedBox(height: 8),
                  ],
                  _buildPlayerTable(l10n, isLive),
                ],
              ),
            ),
          );
        },
      ),
    ).whenComplete(() => _playersSheetSetState = null);
  }

  Widget _buildAddPlayerButton(AppLocalizations l10n) {
    return OutlinedButton.icon(
      onPressed: _showAddPlayerSheet,
      icon: const Icon(Icons.person_add_rounded, size: 16),
      label: Text(
        l10n.menuAddPlayer,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.olive,
        side: BorderSide(color: AppColors.olive.withValues(alpha: 0.4)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      ),
    );
  }

  void _showAddPlayerSheet() {
    final l10n = AppLocalizations.of(context)!;
    _showPlayerPickerSheet(
      title: l10n.menuAddPlayer,
      subtitle: l10n.overviewAddPlayerSubtitle,
      onPickName: (name) async {
        final ok = await _confirmReshuffle(
          l10n.overviewAddConfirm(name),
          l10n.overviewAddLateBody(name),
          confirmLabel: l10n.menuAddPlayer,
        );
        if (ok != true) return false;
        final globalPlayer = widget.onCreatePlayer(name);
        final newPlayer = ScrambleKingPlayer(
          id: ScrambleKingPlayer.generateId(),
          name: name,
          source: ScrambleKingPlayerSource.existing,
          appUserId: globalPlayer.id,
          status: PlayerStatus.late,
        );
        _update(
          ScrambleKingService.rebuildRemainingRounds(_t, [
            ..._t.players,
            newPlayer,
          ]),
        );
        return true;
      },
      onPickExisting: (appUserId, name) async {
        final ok = await _confirmReshuffle(
          l10n.overviewAddConfirm(name),
          l10n.overviewAddLateBody(name),
          confirmLabel: l10n.menuAddPlayer,
        );
        if (ok != true) return false;
        final newPlayer = ScrambleKingPlayer(
          id: ScrambleKingPlayer.generateId(),
          name: name,
          source: ScrambleKingPlayerSource.existing,
          appUserId: appUserId,
          status: PlayerStatus.late,
        );
        _update(
          ScrambleKingService.rebuildRemainingRounds(_t, [
            ..._t.players,
            newPlayer,
          ]),
        );
        return true;
      },
    );
  }

  void _showSwapSheet(ScrambleKingPlayer outgoing) {
    final l10n = AppLocalizations.of(context)!;
    _showPlayerPickerSheet(
      title: l10n.overviewSwapTitle(outgoing.name),
      subtitle: l10n.overviewSwapSubtitle(outgoing.name),
      onPickName: (name) async {
        _applySwap(outgoing: outgoing, name: name);
        return true;
      },
      onPickExisting: (appUserId, name) async {
        _applySwap(outgoing: outgoing, name: name, appUserId: appUserId);
        return true;
      },
    );
  }

  void _applySwap({
    required ScrambleKingPlayer outgoing,
    required String name,
    String? appUserId,
  }) {
    final swappedOut = outgoing.copyWith(status: PlayerStatus.swappedOut);
    final globalPlayer = appUserId != null ? null : widget.onCreatePlayer(name);
    final swappedIn = ScrambleKingPlayer(
      id: ScrambleKingPlayer.generateId(),
      name: name,
      source: globalPlayer != null
          ? ScrambleKingPlayerSource.existing
          : ScrambleKingPlayerSource.created,
      appUserId: globalPlayer?.id ?? appUserId,
      status: PlayerStatus.swappedIn,
    );
    final newPlayers = [
      ..._t.players.map((p) => p.id == outgoing.id ? swappedOut : p),
      swappedIn,
    ];
    _update(ScrambleKingService.rebuildRemainingRounds(_t, newPlayers));
  }

  void _showEditPlayerSheet(ScrambleKingPlayer player) {
    final nameCtrl = TextEditingController(text: player.name);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => TournaQSheet(
        body: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      AppLocalizations.of(context)!.overviewEditPlayer,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      final name = nameCtrl.text.trim();
                      if (name.isEmpty) return;
                      _update(
                        _t.copyWith(
                          players: _t.players
                              .map(
                                (p) => p.id == player.id
                                    ? p.copyWith(name: name)
                                    : p,
                              )
                              .toList(),
                        ),
                      );
                      if (player.appUserId != null) {
                        widget.onUpdatePlayer?.call(player.appUserId!, name);
                      }
                      Navigator.of(ctx).pop();
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.gold,
                    ),
                    child: Text(
                      AppLocalizations.of(context)!.btnSave,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                AppLocalizations.of(context)!.labelName,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: nameCtrl,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPlayerPickerSheet({
    required String title,
    required String subtitle,
    required Future<bool> Function(String name) onPickName,
    required Future<bool> Function(String appUserId, String name)
    onPickExisting,
  }) {
    final alreadyIn = _t.players
        .map((p) => p.appUserId)
        .whereType<String>()
        .toSet();
    final appState = LocalStorageService.loadAppState();
    final allExisting = appState.players;
    final allGroups = appState.groups;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PlayerPickerSheet(
        title: title,
        subtitle: subtitle,
        existingPlayers: allExisting,
        existingGroups: allGroups,
        alreadyInIds: alreadyIn,
        nameHint: AppLocalizations.of(context)!.setupPlayerNameHint,
        onCreateByName: onPickName,
        onAddExisting: onPickExisting,
      ),
    );
  }

  Widget _buildPlayerTable(AppLocalizations l10n, bool isLive) {
    final stats = ScrambleKingService.computeStats(_t);
    final statsById = {for (final s in stats) s.playerId: s};
    if (_t.players.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          l10n.doghouseSetupNoPlayers,
          style: const TextStyle(fontSize: 13, color: Colors.black38),
        ),
      );
    }
    return Column(
      children: _t.players.map((p) {
        final s = statsById[p.id];
        return TournamentPlayerRow(
          name: p.name,
          status: p.status,
          statsLine: (s != null && p.isActive)
              ? '${s.roundsPlayed}r · ${s.totalPoints}pts'
              : null,
          onEdit: () => _showEditPlayerSheet(p),
          onEject: isLive ? () => _confirmEject(p) : null,
          onSwap: isLive ? () => _showSwapSheet(p) : null,
          showDisabledActions: false,
        );
      }).toList(),
    );
  }

  Future<bool?> _confirmReshuffle(
    String title,
    String body, {
    required String confirmLabel,
    Color confirmColor = AppColors.olive,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        content: Text(
          body,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.black54,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(AppLocalizations.of(context)!.btnCancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: confirmColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              confirmLabel,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmEject(ScrambleKingPlayer player) async {
    final l10n = AppLocalizations.of(context)!;
    final ok = await _confirmReshuffle(
      l10n.overviewEjectTitle(player.name),
      l10n.overviewEjectBody(player.name),
      confirmLabel: l10n.overviewEjectBtn,
      confirmColor: Colors.red,
    );
    if (ok != true || !mounted) return;
    final ejected = player.copyWith(status: PlayerStatus.ejected);
    final newPlayers = _t.players
        .map((p) => p.id == player.id ? ejected : p)
        .toList();
    _update(ScrambleKingService.rebuildRemainingRounds(_t, newPlayers));
  }

  // ── QR export / import / manual result ─────────────────────────────────────

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  String _courtContext(
    AppLocalizations l10n,
    ScrambleKingCourtFormation formation,
  ) {
    String nameFor(String id) => _t.getPlayer(id)?.name ?? '?';
    final teams = <String>[
      for (final s in formation.teamSlots)
        s.teamName ?? s.playerIds.map(nameFor).join(' & '),
      if (formation.floaterSlot != null)
        formation.floaterSlot!.teamName ??
            nameFor(formation.floaterSlot!.playerId),
    ];
    return '${l10n.scrambleKingCourtPageTitle(formation.courtNumber)} · ${teams.join(' · ')}';
  }

  void _exportCourt(
    ScrambleKingRound round,
    ScrambleKingCourtFormation formation,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final data = ScrambleKingTransferService.encodeCourtExport(
      _t,
      round,
      formation,
    );
    showQrExportSheet(
      context,
      title: l10n.scrambleKingExportCourt,
      subtitle: _courtContext(l10n, formation),
      data: data,
    );
  }

  Future<void> _importResult(
    ScrambleKingRound round,
    ScrambleKingCourtFormation formation,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final raw = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => QrScanPage(hint: l10n.scrambleScanResultHint),
      ),
    );
    if (raw == null || !mounted) return;

    ScrambleKingResultUpdate res;
    try {
      res = ScrambleKingTransferService.decodeResult(raw);
    } catch (_) {
      _showSnack(l10n.scrambleScanNotResult);
      return;
    }
    if (res.parentTournamentId.isNotEmpty && res.parentTournamentId != _t.id) {
      _showSnack(l10n.scrambleResultMismatch);
      return;
    }
    if (res.roundId != round.id || res.courtNumber != formation.courtNumber) {
      _showSnack(l10n.scrambleResultMismatch);
      return;
    }
    _update(
      _applyCourtResult(
        round,
        formation,
        res.teamResults,
        res.actualStartTime,
        res.actualEndTime,
      ),
    );
    _showSnack(l10n.scrambleResultImported);
  }

  /// Applies a per-team result to [formation] positionally (teamSlots order,
  /// floater last), marks the court completed, and reflows the schedule if the
  /// round is now finished.
  ScrambleKingTournament _applyCourtResult(
    ScrambleKingRound round,
    ScrambleKingCourtFormation formation,
    List<({int points, int gamesWon})> results,
    DateTime? start,
    DateTime? end,
  ) {
    final slotOrder = <String>[
      ...formation.teamSlots.map((s) => s.slotId),
      if (formation.floaterSlot != null) formation.floaterSlot!.slotId,
    ];
    final pts = <String, int>{};
    final gw = <String, int>{};
    for (var i = 0; i < results.length && i < slotOrder.length; i++) {
      pts[slotOrder[i]] = results[i].points;
      gw[slotOrder[i]] = results[i].gamesWon;
    }
    final now = DateTime.now();
    final updatedFormation = formation.copyWith(
      manualTeamPoints: pts,
      manualGamesWon: gw,
      actualStartTime: start ?? formation.actualStartTime ?? now,
      actualEndTime: end ?? now,
    );
    final updated = _t.updateRound(round.updateCourt(updatedFormation));
    return _reflowIfRoundComplete(updated, round.id);
  }

  ScrambleKingTournament _reflowIfRoundComplete(
    ScrambleKingTournament t,
    String roundId,
  ) {
    final round = t.getRound(roundId)!;
    if (!round.courts.every((c) => c.isCompleted)) return t;
    final now = DateTime.now();
    final actualEnd = round.courts
        .map((c) => c.actualEndTime ?? now)
        .reduce((a, b) => a.isAfter(b) ? a : b);
    t = t.updateRound(round.copyWith(actualEndTime: actualEnd));
    if (actualEnd.isBefore(round.scheduledMatchEndTime)) {
      return ScrambleKingService.reflowAllPending(t);
    }
    return t;
  }

  Future<void> _showSetCourtResultDialog(
    ScrambleKingRound round,
    ScrambleKingCourtFormation formation,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    String nameFor(String id) => _t.getPlayer(id)?.name ?? '?';
    final slots = <({String slotId, String label, String players})>[
      for (final s in formation.teamSlots)
        (
          slotId: s.slotId,
          label: s.teamName ?? s.playerIds.map(nameFor).join(' & '),
          players: s.playerIds.map(nameFor).join(' & '),
        ),
      if (formation.floaterSlot != null)
        (
          slotId: formation.floaterSlot!.slotId,
          label:
              formation.floaterSlot!.teamName ??
              nameFor(formation.floaterSlot!.playerId),
          players: nameFor(formation.floaterSlot!.playerId),
        ),
    ];
    final winCtrls = {
      for (final s in slots) s.slotId: TextEditingController(text: '0'),
    };
    final ptsCtrls = {
      for (final s in slots) s.slotId: TextEditingController(text: '0'),
    };

    Widget numCell(TextEditingController c) => SizedBox(
      width: 54,
      child: TextField(
        controller: c,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(vertical: 8),
        ),
      ),
    );
    Widget headerCell(String label) => SizedBox(
      width: 54,
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: Colors.black45,
        ),
      ),
    );

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          l10n.scrambleKingSetResultTitle,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.scrambleKingSetResultDescription,
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.black54,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  const Expanded(child: SizedBox()),
                  headerCell(l10n.scrambleKingGamesWonLabel),
                  const SizedBox(width: 8),
                  headerCell(l10n.scrambleKingPointsLabel),
                ],
              ),
              const SizedBox(height: 6),
              for (final s in slots)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              s.label,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              s.players,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.black45,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      numCell(winCtrls[s.slotId]!),
                      const SizedBox(width: 8),
                      numCell(ptsCtrls[s.slotId]!),
                    ],
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.btnCancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.btnSave),
          ),
        ],
      ),
    );

    if (ok == true && mounted) {
      final results = [
        for (final s in slots)
          (
            points: int.tryParse(ptsCtrls[s.slotId]!.text) ?? 0,
            gamesWon: int.tryParse(winCtrls[s.slotId]!.text) ?? 0,
          ),
      ];
      _update(_applyCourtResult(round, formation, results, null, null));
    }
    Future.delayed(const Duration(milliseconds: 300), () {
      for (final c in [...winCtrls.values, ...ptsCtrls.values]) {
        c.dispose();
      }
    });
  }

  // ── Rounds / Schedule ─────────────────────────────────────────────────────

  List<Widget> _buildRoundSections(AppLocalizations l10n) {
    return _t.rounds.map((round) {
      final expanded = _expandedRoundIds.contains(round.id);
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _roundHeader(l10n, round, expanded),
            if (expanded) ...[
              const SizedBox(height: 10),
              for (final court in round.courts)
                ScrambleKingCourtResultTile(
                  tournament: _t,
                  round: round,
                  formation: court,
                  onTap: () => _openCourt(round, court.courtNumber),
                  onExport: () => _exportCourt(round, court),
                  onImportResult: () => _importResult(round, court),
                  onManualScore: () => _showSetCourtResultDialog(round, court),
                ),
            ],
          ],
        ),
      );
    }).toList();
  }

  // ── Teams section (tournament-wide) ───────────────────────────────────────

  Set<int> _allCourtNumbers() =>
      _t.rounds.expand((r) => r.courts.map((c) => c.courtNumber)).toSet();

  /// Collapsible, tournament-wide "Teams" section (between Players and
  /// Schedule). Collapsed by default — each round's own court tiles already
  /// show every team's name + players — and expands to every team across
  /// every round, filterable by round and by court. Opened from the header's
  /// "Teams" pill.
  void _showTeamsSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) {
          _teamsSheetSetState = setSheet;
          final l10n = AppLocalizations.of(context)!;
          return TournaQSheet(
            body: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                20,
                8,
                20,
                MediaQuery.of(ctx).viewInsets.bottom + 32,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l10n.scrambleKingTeamsLabel,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_t.rounds.length > 1) ...[
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _teamsFilterChip(
                          l10n.scrambleKingTeamsFilterAll,
                          _teamsRoundFilter == null,
                          () => setSheet(() => _teamsRoundFilter = null),
                        ),
                        for (final round in _t.rounds)
                          _teamsFilterChip(
                            l10n.scrambleKingRoundLabel(round.roundNumber),
                            _teamsRoundFilter == round.roundNumber,
                            () => setSheet(
                              () => _teamsRoundFilter = round.roundNumber,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                  if (_allCourtNumbers().length > 1) ...[
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _teamsFilterChip(
                          l10n.scrambleKingTeamsFilterAll,
                          _teamsCourtFilter == null,
                          () => setSheet(() => _teamsCourtFilter = null),
                        ),
                        for (final courtNumber
                            in _allCourtNumbers().toList()..sort())
                          _teamsFilterChip(
                            l10n.scrambleKingCourtPageTitle(courtNumber),
                            _teamsCourtFilter == courtNumber,
                            () =>
                                setSheet(() => _teamsCourtFilter = courtNumber),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                  _buildFilteredTeamsList(l10n),
                ],
              ),
            ),
          );
        },
      ),
    ).whenComplete(() => _teamsSheetSetState = null);
  }

  Widget _teamsFilterChip(String label, bool selected, VoidCallback onTap) =>
      Material(
        color: selected ? AppColors.olive : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: selected ? Colors.white : Colors.black54,
              ),
            ),
          ),
        ),
      );

  /// Every team across every round, filtered by `_teamsRoundFilter`/
  /// `_teamsCourtFilter`. Rounds get a small sub-header whenever more than
  /// one is being shown at once; each row always carries its court number,
  /// since courts from different rounds can be mixed together here.
  Widget _buildFilteredTeamsList(AppLocalizations l10n) {
    String nameFor(String id) => _t.getPlayer(id)?.name ?? '?';
    final oddPartnerLabel = _t.oddPlayerMode == ScrambleKingOddPlayerMode.jumper
        ? l10n.scrambleKingOddPlayerJumperLabel
        : l10n.scrambleKingOddPlayerPlaceholderLabel;

    final rounds = _teamsRoundFilter == null
        ? _t.rounds
        : _t.rounds.where((r) => r.roundNumber == _teamsRoundFilter).toList();
    final showRoundHeaders = rounds.length > 1;

    final sections = <Widget>[];
    for (final round in rounds) {
      final rows = <Widget>[];
      for (final court in round.courts) {
        if (_teamsCourtFilter != null &&
            court.courtNumber != _teamsCourtFilter) {
          continue;
        }
        final courtLabel = l10n.scrambleKingCourtPageTitle(court.courtNumber);
        for (final slot in court.teamSlots) {
          rows.add(
            _teamRow(
              slot.teamName ?? slot.playerIds.map(nameFor).join(' & '),
              slot.playerIds.map(nameFor).join(' & '),
              courtLabel: courtLabel,
            ),
          );
        }
        if (court.floaterSlot != null) {
          final f = court.floaterSlot!;
          rows.add(
            _teamRow(
              f.teamName ?? nameFor(f.playerId),
              '${nameFor(f.playerId)} · $oddPartnerLabel',
              courtLabel: courtLabel,
            ),
          );
        }
      }
      if (rows.isEmpty) continue;
      if (showRoundHeaders) {
        sections.add(
          Padding(
            padding: const EdgeInsets.only(top: 6, bottom: 2),
            child: Text(
              l10n.scrambleKingRoundLabel(round.roundNumber),
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Colors.black45,
              ),
            ),
          ),
        );
      }
      sections.addAll(rows);
    }

    if (sections.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          l10n.scrambleKingTeamsEmpty,
          style: const TextStyle(fontSize: 13, color: Colors.black38),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: sections,
    );
  }

  Widget _teamRow(String teamName, String players, {String? courtLabel}) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          children: [
            Container(
              width: 6,
              height: 6,
              margin: const EdgeInsets.only(right: 8),
              decoration: const BoxDecoration(
                color: AppColors.goldDark,
                shape: BoxShape.circle,
              ),
            ),
            Text(
              teamName,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.goldDark,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                players,
                style: const TextStyle(fontSize: 12, color: Colors.black54),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (courtLabel != null) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  courtLabel,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.black45,
                  ),
                ),
              ),
            ],
          ],
        ),
      );

  Widget _roundHeader(
    AppLocalizations l10n,
    ScrambleKingRound round,
    bool expanded,
  ) {
    final allDone = round.isCompleted;
    final actualEnd = round.actualEndTime;
    final showActual = allDone && actualEnd != null;

    // Earliest court start, so completed rounds can show a full "start – end".
    final actualStart = showActual
        ? round.courts
              .map((c) => c.actualStartTime)
              .whereType<DateTime>()
              .fold<DateTime?>(
                null,
                (a, b) => a == null || b.isBefore(a) ? b : a,
              )
        : null;

    // Round-level status icon: same three-state language as the court tiles,
    // promoted to the header so the live round is obvious at a glance.
    final anyInProgress = round.courts.any(
      (c) => c.actualStartTime != null && !c.isCompleted,
    );
    final IconData statusIcon;
    final Color statusColor;
    if (allDone) {
      statusIcon = Icons.check_circle_rounded;
      statusColor = AppColors.olive;
    } else if (anyInProgress) {
      statusIcon = Icons.sports_volleyball_rounded;
      statusColor = AppColors.gold;
    } else {
      statusIcon = Icons.schedule_rounded;
      statusColor = Colors.black38;
    }

    // Pace status now lives on the header (was a per-court dot on the tiles).
    Color? paceColor;
    String? paceLabel;
    if (!allDone && _t.paceAlertsEnabled) {
      final now = DateTime.now();
      if (now.isAfter(round.scheduledMatchEndTime)) {
        paceColor = Colors.red.shade600;
        paceLabel = l10n.statusOverdue;
      } else if (now.isAfter(round.scheduledStartTime)) {
        paceColor = Colors.amber.shade700;
        paceLabel = l10n.statusDue;
      } else {
        paceColor = Colors.green.shade600;
        paceLabel = l10n.statusUpcoming;
      }
    }

    return InkWell(
      onTap: () => setState(() {
        if (!_expandedRoundIds.remove(round.id)) {
          _expandedRoundIds.add(round.id);
        }
      }),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: allDone ? AppColors.olive : AppColors.goldCream,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                l10n.scrambleKingRoundLabel(round.roundNumber),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: allDone ? Colors.white : AppColors.goldDark,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Row(
                children: [
                  if (showActual) ...[
                    Flexible(
                      child: Text(
                        actualStart != null
                            ? '${_fmtTime(actualStart)} – ${_fmtTime(actualEnd)}'
                            : _fmtTime(actualEnd),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black45,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      l10n.overviewActual,
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.black38,
                      ),
                    ),
                  ] else ...[
                    Flexible(
                      child: Text(
                        '${_fmtTime(round.scheduledStartTime)} – ${_fmtTime(round.scheduledMatchEndTime)}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black45,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (round.breakDuration > Duration.zero) ...[
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          l10n.overviewBreakUntil(
                            _fmtTime(round.scheduledBreakEndTime),
                          ),
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.black38,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ),
            const SizedBox(width: 6),
            Icon(statusIcon, size: 18, color: statusColor),
            if (paceLabel != null) ...[
              const SizedBox(width: 6),
              _paceChip(paceColor!, paceLabel),
            ],
            const SizedBox(width: 4),
            Icon(
              expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
              size: 18,
              color: Colors.black38,
            ),
          ],
        ),
      ),
    );
  }

  /// Small pace-status pill (overdue / due / upcoming) shown on the round
  /// header. Colour-coded: red = overdue, amber = due, green = upcoming.
  Widget _paceChip(Color color, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
