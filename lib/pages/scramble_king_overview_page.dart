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
import '../widgets/player_picker_sheet.dart';
import '../widgets/scramble_king_court_result_tile.dart';
import '../widgets/sheet_helpers.dart';
import '../widgets/tournament_player_row.dart';
import '../widgets/tournaq_app_bar.dart';
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
  State<ScrambleKingOverviewPage> createState() => _ScrambleKingOverviewPageState();
}

class _ScrambleKingOverviewPageState extends State<ScrambleKingOverviewPage> {
  late ScrambleKingTournament _t;
  bool _playersExpanded = false;
  bool _timelineExpanded = false;
  final Set<String> _expandedRoundIds = {};
  // Tournament-wide "Teams" section (between Players and Schedule) —
  // collapsed by default (each round's own court tiles already show every
  // team's name + players); expands to a filterable list of every team
  // across every round.
  bool _teamsExpanded = false;
  int? _teamsRoundFilter; // round number; null ⇒ all rounds
  int? _teamsCourtFilter; // court number; null ⇒ all courts

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
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ScrambleKingStatsPage(tournament: _t),
    ));
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
            icon: const Icon(Icons.leaderboard_rounded, color: AppColors.goldLight),
            tooltip: l10n.tooltipRankings,
            onPressed: _openStats,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          _sectionDivider(l10n.overviewSectionOverview, Icons.bar_chart_rounded),
          const SizedBox(height: 10),
          _buildHeader(l10n, completed, total, progress),
          const SizedBox(height: 20),
          _buildTimelineSection(l10n),
          const SizedBox(height: 20),
          _buildPlayersSection(l10n),
          const SizedBox(height: 20),
          _buildTeamsSection(l10n),
          const SizedBox(height: 20),
          _sectionDivider(l10n.overviewSectionSchedule, Icons.event_note_rounded),
          const SizedBox(height: 10),
          ..._buildRoundSections(l10n),
        ],
      ),
    );
  }

  // ── Section divider ───────────────────────────────────────────────────────

  Widget _sectionDivider(String label, IconData icon,
      {bool collapsible = false, bool expanded = false, VoidCallback? onToggle}) {
    return InkWell(
      onTap: onToggle,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
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
            if (collapsible) ...[
              const SizedBox(width: 4),
              Icon(
                expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                size: 16,
                color: Colors.black38,
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── Overview header ───────────────────────────────────────────────────────

  Widget _buildHeader(AppLocalizations l10n, int completed, int total, double progress) {
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
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
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

  String _assignmentModeLabel(AppLocalizations l10n) => switch (_t.assignmentMode) {
        ScrambleKingAssignmentMode.manual => l10n.doghouseAssignmentManual,
        ScrambleKingAssignmentMode.automated => l10n.doghouseAssignmentAutomated,
        ScrambleKingAssignmentMode.automatedAllPlay => l10n.setupFormatAutoAllplay,
      };

  String _oddPlayerModeLabel(AppLocalizations l10n) =>
      _t.oddPlayerMode == ScrambleKingOddPlayerMode.jumper
          ? l10n.scrambleKingOddPlayerJumperLabel
          : l10n.scrambleKingOddPlayerPlaceholderLabel;

  /// Every tournament-level setting as a pill: editable ones (rounds,
  /// courts, strike, assignment, odd-player) open the shared edit sheet;
  /// read-only ones (players, team size, estimated finish) are informational
  /// — players and team size already have their own dedicated editing UI
  /// elsewhere, and estimated finish is a derived value, not a raw setting.
  Widget _buildInfoPills(AppLocalizations l10n) {
    final lastRound = _t.rounds.isNotEmpty ? _t.rounds.last : null;
    final estFinish = lastRound?.actualEndTime ?? lastRound?.scheduledBreakEndTime;
    final finished = _t.completedRounds == _t.roundCount && _t.roundCount > 0;

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        _infoPill(Icons.repeat_rounded, l10n.scrambleKingRoundsPill(_t.roundCount),
            onTap: _showFormatEditSheet),
        _infoPill(Icons.sports_volleyball_rounded, l10n.scrambleKingCourtsPill(_t.courtCount),
            onTap: _showFormatEditSheet),
        _infoPill(Icons.group_rounded, l10n.scrambleKingPlayersPill(_t.playerCount)),
        _infoPill(Icons.grid_view_rounded, '2v2'),
        if (estFinish != null)
          _infoPill(
              Icons.flag_outlined,
              finished ? l10n.overviewFinished(_fmtTime(estFinish)) : l10n.overviewEstFinish(_fmtTime(estFinish))),
        if (_t.strikePoints > 0)
          _infoPill(Icons.bolt_rounded, l10n.kotcStrikePoints(_t.strikePoints),
              onTap: _showFormatEditSheet),
        _infoPill(Icons.tune_rounded, _assignmentModeLabel(l10n), onTap: _showFormatEditSheet),
        if (_hasFloater)
          _infoPill(Icons.swap_horiz_rounded, _oddPlayerModeLabel(l10n),
              onTap: _showFormatEditSheet),
      ],
    );
  }

  Widget _infoPill(IconData icon, String label, {VoidCallback? onTap}) => Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(icon, size: 13, color: AppColors.olive),
              const SizedBox(width: 4),
              Text(label,
                  style: const TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.olive)),
              if (onTap != null) ...[
                const SizedBox(width: 4),
                const Icon(Icons.edit_rounded, size: 11, color: Colors.black38),
              ],
            ]),
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
          Text('${(progress * 100).round()}%',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
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

  Widget _buildTimelineSection(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sectionDivider(
          l10n.overviewSectionTimeline,
          Icons.schedule_rounded,
          collapsible: true,
          expanded: _timelineExpanded,
          onToggle: () => setState(() => _timelineExpanded = !_timelineExpanded),
        ),
        if (_timelineExpanded) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.goldCream,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildStartAndEndRow(),
                const SizedBox(height: 8),
                const Divider(height: 1, thickness: 0.5, color: AppColors.goldDark),
                const SizedBox(height: 4),
                ..._buildTimelineRows(),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStartAndEndRow() {
    if (_t.rounds.isEmpty) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context)!;

    final allDone = _t.rounds.every((r) => r.actualEndTime != null);
    final DateTime predictedEnd;
    if (allDone) {
      predictedEnd =
          _t.rounds.map((r) => r.actualEndTime!).reduce((a, b) => a.isAfter(b) ? a : b);
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
                  Row(children: [
                    const Icon(Icons.play_circle_outline_rounded, size: 13, color: Colors.black38),
                    const SizedBox(width: 5),
                    Text(l10n.timelineStart(_fmtTime(_t.startTime)),
                        style: const TextStyle(fontSize: 12, color: Colors.black54)),
                  ]),
                  const SizedBox(height: 2),
                  Row(children: [
                    Icon(
                      allDone ? Icons.check_circle_outline_rounded : Icons.flag_outlined,
                      size: 13,
                      color: allDone ? AppColors.olive : Colors.black38,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      endText,
                      style: TextStyle(
                        fontSize: 12,
                        color: allDone ? AppColors.olive : Colors.black54,
                        fontWeight: allDone ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ]),
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
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
                    Text(timeLabel, style: const TextStyle(fontSize: 12, color: Colors.black54)),
                    if (breakTime != null)
                      Text(l10n.timelineBreakUntil(breakTime),
                          style: const TextStyle(fontSize: 11, color: Colors.black38)),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_t.paceAlertsEnabled) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: allDone ? 1.0 : 0.12),
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
                  const Icon(Icons.edit_rounded, size: 13, color: Colors.black26),
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
    int matchMinutes = (firstPending ?? _t.rounds.first).matchDuration.inMinutes;
    int breakMinutes = (firstPending ?? _t.rounds.first).breakDuration.inMinutes;
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
              padding:
                  EdgeInsets.fromLTRB(20, 8, 20, MediaQuery.of(ctx).viewInsets.bottom + 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(children: [
                    Expanded(
                      child: Text(l10n.timelineScheduleTitle,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                    ),
                    TextButton(
                      onPressed: () {
                        _applyOverallEdit(startTime, matchMinutes, breakMinutes, paceAlertsEnabled);
                        Navigator.of(ctx).pop();
                      },
                      style: TextButton.styleFrom(foregroundColor: AppColors.gold),
                      child:
                          Text(l10n.btnSave, style: const TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ]),
                  const SizedBox(height: 20),
                  Text(l10n.timelineTournamentStart,
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black54)),
                  const SizedBox(height: 6),
                  _buildTimeTile(startTime.format(ctx), () async {
                    final picked = await showTimePicker(context: ctx, initialTime: startTime);
                    if (picked != null) setSheet(() => startTime = picked);
                  }),
                  const SizedBox(height: 16),
                  Text(l10n.timelineGameDuration,
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black54)),
                  const SizedBox(height: 6),
                  _buildMinutePicker(
                      value: matchMinutes, min: 1, onChanged: (v) => setSheet(() => matchMinutes = v)),
                  const SizedBox(height: 16),
                  Text(l10n.timelineBreakDurationPending,
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black54)),
                  const SizedBox(height: 6),
                  _buildMinutePicker(
                      value: breakMinutes, min: 0, onChanged: (v) => setSheet(() => breakMinutes = v)),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: paceAlertsEnabled,
                    onChanged: (v) => setSheet(() => paceAlertsEnabled = v),
                    activeThumbColor: AppColors.gold,
                    title: Text(l10n.timelinePaceAlertsTitle,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    subtitle: Text(l10n.timelinePaceAlertsSubtitle,
                        style: const TextStyle(fontSize: 12, color: Colors.black54)),
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
      TimeOfDay newTime, int matchMinutes, int breakMinutes, bool paceAlertsEnabled) {
    final old = _t.startTime;
    final newStart = DateTime(old.year, old.month, old.day, newTime.hour, newTime.minute);

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

    _update(_t.copyWith(
        startTime: newStart, rounds: rounds, paceAlertsEnabled: paceAlertsEnabled));
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
              padding:
                  EdgeInsets.fromLTRB(20, 8, 20, MediaQuery.of(ctx).viewInsets.bottom + 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(children: [
                    Expanded(
                      child: Text(l10n.scrambleKingEditFormatTitle,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                    ),
                    TextButton(
                      onPressed: () {
                        var updated = _t;
                        if (courts != _t.courtCount) {
                          final activeCount = _t.players.where((p) => p.isActive).length;
                          if (ScrambleKingService.decideCourtSizes(activeCount, courts).isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content: Text(l10n.scrambleKingInvalidCourtCount)));
                            return;
                          }
                          updated = ScrambleKingService.rebuildRemainingRounds(
                              updated.copyWith(courtCount: courts), updated.players);
                        }
                        if (rounds != _t.roundCount) {
                          updated = ScrambleKingService.setRoundCount(updated, rounds);
                        }
                        updated = updated.copyWith(
                          assignmentMode: assignment,
                          oddPlayerMode: oddPlayer,
                          strikePoints: strike,
                        );
                        _update(updated);
                        Navigator.of(ctx).pop();
                      },
                      style: TextButton.styleFrom(foregroundColor: AppColors.gold),
                      child:
                          Text(l10n.btnSave, style: const TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ]),
                  const SizedBox(height: 20),
                  Text(l10n.scrambleKingRoundsPillLabel,
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black54)),
                  const SizedBox(height: 6),
                  _buildCountStepper(
                      value: rounds,
                      min: minRounds,
                      onChanged: (v) => setSheet(() => rounds = v)),
                  const SizedBox(height: 16),
                  Text(l10n.scrambleKingCourtsPillLabel,
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black54)),
                  const SizedBox(height: 6),
                  _buildCountStepper(
                      value: courts, min: 1, max: 8, onChanged: (v) => setSheet(() => courts = v)),
                  const SizedBox(height: 16),
                  Text(l10n.kotcSetupStrikeLabel,
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black54)),
                  const SizedBox(height: 6),
                  _buildCountStepper(
                      value: strike, min: 0, onChanged: (v) => setSheet(() => strike = v)),
                  const SizedBox(height: 16),
                  Text(l10n.kotcSetupAssignmentLabel,
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black54)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<ScrambleKingAssignmentMode>(
                    initialValue: assignment,
                    isDense: true,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
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
                    Text(l10n.scrambleKingOddPlayerLabel,
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black54)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<ScrambleKingOddPlayerMode>(
                      initialValue: oddPlayer,
                      isDense: true,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      items: [
                        DropdownMenuItem(
                          value: ScrambleKingOddPlayerMode.placeholder,
                          child: Text(l10n.scrambleKingOddPlayerPlaceholderLabel),
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
              padding:
                  EdgeInsets.fromLTRB(20, 8, 20, MediaQuery.of(ctx).viewInsets.bottom + 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(children: [
                    Expanded(
                      child: Text(l10n.scrambleKingRoundLabel(round.roundNumber),
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                    ),
                    TextButton(
                      onPressed: () {
                        final d = round.scheduledStartTime;
                        final newStart =
                            DateTime(d.year, d.month, d.day, startTime.hour, startTime.minute);
                        final updatedRound = round.copyWith(
                          scheduledStartTime: newStart,
                          matchDuration: Duration(minutes: matchMinutes),
                          breakDuration: Duration(minutes: breakMinutes),
                        );
                        final rounds = List<ScrambleKingRound>.from(_t.rounds);
                        final idx = rounds.indexWhere((r) => r.id == round.id);
                        rounds[idx] = updatedRound;
                        var cursor = updatedRound.scheduledBreakEndTime;
                        for (var i = idx + 1; i < rounds.length; i++) {
                          if (rounds[i].isCompleted) {
                            final r = rounds[i];
                            final afterBreak = r.actualEndTime!.add(r.breakDuration);
                            if (afterBreak.isAfter(cursor)) cursor = afterBreak;
                            continue;
                          }
                          rounds[i] = rounds[i].copyWith(scheduledStartTime: cursor);
                          cursor = cursor.add(rounds[i].matchDuration + rounds[i].breakDuration);
                        }
                        _update(_t.copyWith(rounds: rounds));
                        Navigator.of(ctx).pop();
                      },
                      style: TextButton.styleFrom(foregroundColor: AppColors.gold),
                      child:
                          Text(l10n.btnSave, style: const TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ]),
                  const SizedBox(height: 20),
                  Text(l10n.timelineEditStartTime,
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black54)),
                  const SizedBox(height: 6),
                  _buildTimeTile(startTime.format(ctx), () async {
                    final picked = await showTimePicker(context: ctx, initialTime: startTime);
                    if (picked != null) setSheet(() => startTime = picked);
                  }),
                  const SizedBox(height: 16),
                  Text(l10n.timelineMatchDuration,
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black54)),
                  const SizedBox(height: 6),
                  _buildMinutePicker(
                      value: matchMinutes, min: 1, onChanged: (v) => setSheet(() => matchMinutes = v)),
                  const SizedBox(height: 16),
                  Text(l10n.timelineBreakAfterRound,
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black54)),
                  const SizedBox(height: 6),
                  _buildMinutePicker(
                      value: breakMinutes, min: 0, onChanged: (v) => setSheet(() => breakMinutes = v)),
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
            const Icon(Icons.access_time_rounded, size: 16, color: Colors.black38),
            const SizedBox(width: 10),
            Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
            const Spacer(),
            const Icon(Icons.chevron_right_rounded, size: 18, color: Colors.black38),
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
            child: Text(label,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
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
            child: Text('$value',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          ),
          IconButton(
            icon: const Icon(Icons.add_rounded, size: 20),
            onPressed: (max == null || value < max) ? () => onChanged(value + 1) : null,
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
    final sorted = _t.rounds.toList()..sort((a, b) => a.roundNumber.compareTo(b.roundNumber));
    for (var i = 0; i < sorted.length; i++) {
      final round = sorted[i];
      final untouched = _t.getStintsForRound(round.id).isEmpty &&
          round.courts.every((c) => c.actualStartTime == null);
      if (untouched) return i;
    }
    return sorted.length;
  }

  // ── Players section ───────────────────────────────────────────────────────

  Widget _buildPlayersSection(AppLocalizations l10n) {
    final isLive = _t.status != ScrambleKingTournamentStatus.completed && _t.rounds.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sectionDivider(
          l10n.overviewSectionPlayers(_t.players.length),
          Icons.group_rounded,
          collapsible: true,
          expanded: _playersExpanded,
          onToggle: () => setState(() => _playersExpanded = !_playersExpanded),
        ),
        if (_playersExpanded) ...[
          const SizedBox(height: 10),
          if (isLive) ...[
            _buildAddPlayerButton(l10n),
            const SizedBox(height: 8),
          ],
          _buildPlayerTable(l10n, isLive),
        ],
      ],
    );
  }

  Widget _buildAddPlayerButton(AppLocalizations l10n) {
    return OutlinedButton.icon(
      onPressed: _showAddPlayerSheet,
      icon: const Icon(Icons.person_add_rounded, size: 16),
      label: Text(l10n.menuAddPlayer, style: const TextStyle(fontWeight: FontWeight.w600)),
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
        _update(ScrambleKingService.rebuildRemainingRounds(_t, [..._t.players, newPlayer]));
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
        _update(ScrambleKingService.rebuildRemainingRounds(_t, [..._t.players, newPlayer]));
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
      source:
          globalPlayer != null ? ScrambleKingPlayerSource.existing : ScrambleKingPlayerSource.created,
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
              Row(children: [
                Expanded(
                  child: Text(AppLocalizations.of(context)!.overviewEditPlayer,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                ),
                TextButton(
                  onPressed: () {
                    final name = nameCtrl.text.trim();
                    if (name.isEmpty) return;
                    _update(_t.copyWith(
                      players:
                          _t.players.map((p) => p.id == player.id ? p.copyWith(name: name) : p).toList(),
                    ));
                    if (player.appUserId != null) {
                      widget.onUpdatePlayer?.call(player.appUserId!, name);
                    }
                    Navigator.of(ctx).pop();
                  },
                  style: TextButton.styleFrom(foregroundColor: AppColors.gold),
                  child: Text(AppLocalizations.of(context)!.btnSave,
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                ),
              ]),
              const SizedBox(height: 16),
              Text(AppLocalizations.of(context)!.labelName,
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black54)),
              const SizedBox(height: 6),
              TextField(
                controller: nameCtrl,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
    required Future<bool> Function(String appUserId, String name) onPickExisting,
  }) {
    final alreadyIn = _t.players.map((p) => p.appUserId).whereType<String>().toSet();
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
        child: Text(l10n.doghouseSetupNoPlayers,
            style: const TextStyle(fontSize: 13, color: Colors.black38)),
      );
    }
    return Column(
      children: _t.players.map((p) {
        final s = statsById[p.id];
        return TournamentPlayerRow(
          name: p.name,
          status: p.status,
          statsLine: (s != null && p.isActive) ? '${s.roundsPlayed}r · ${s.totalPoints}pts' : null,
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
        title: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        content:
            Text(body, style: const TextStyle(fontSize: 14, color: Colors.black54, height: 1.5)),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(AppLocalizations.of(context)!.btnCancel)),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: confirmColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(confirmLabel, style: const TextStyle(fontWeight: FontWeight.w600)),
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
    final newPlayers = _t.players.map((p) => p.id == player.id ? ejected : p).toList();
    _update(ScrambleKingService.rebuildRemainingRounds(_t, newPlayers));
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
  /// every round, filterable by round and by court.
  Widget _buildTeamsSection(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sectionDivider(
          l10n.scrambleKingTeamsLabel,
          Icons.groups_rounded,
          collapsible: true,
          expanded: _teamsExpanded,
          onToggle: () => setState(() => _teamsExpanded = !_teamsExpanded),
        ),
        if (_teamsExpanded) ...[
          const SizedBox(height: 8),
          if (_t.rounds.length > 1) ...[
            Wrap(spacing: 6, runSpacing: 6, children: [
              _teamsFilterChip(l10n.scrambleKingTeamsFilterAll, _teamsRoundFilter == null,
                  () => setState(() => _teamsRoundFilter = null)),
              for (final round in _t.rounds)
                _teamsFilterChip(
                    l10n.scrambleKingRoundLabel(round.roundNumber),
                    _teamsRoundFilter == round.roundNumber,
                    () => setState(() => _teamsRoundFilter = round.roundNumber)),
            ]),
            const SizedBox(height: 8),
          ],
          if (_allCourtNumbers().length > 1) ...[
            Wrap(spacing: 6, runSpacing: 6, children: [
              _teamsFilterChip(l10n.scrambleKingTeamsFilterAll, _teamsCourtFilter == null,
                  () => setState(() => _teamsCourtFilter = null)),
              for (final courtNumber in _allCourtNumbers().toList()..sort())
                _teamsFilterChip(
                    l10n.scrambleKingCourtPageTitle(courtNumber),
                    _teamsCourtFilter == courtNumber,
                    () => setState(() => _teamsCourtFilter = courtNumber)),
            ]),
            const SizedBox(height: 8),
          ],
          _buildFilteredTeamsList(l10n),
        ],
      ],
    );
  }

  Widget _teamsFilterChip(String label, bool selected, VoidCallback onTap) => Material(
        color: selected ? AppColors.olive : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            child: Text(label,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: selected ? Colors.white : Colors.black54)),
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
        if (_teamsCourtFilter != null && court.courtNumber != _teamsCourtFilter) continue;
        final courtLabel = l10n.scrambleKingCourtPageTitle(court.courtNumber);
        for (final slot in court.teamSlots) {
          rows.add(_teamRow(
            slot.teamName ?? slot.playerIds.map(nameFor).join(' & '),
            slot.playerIds.map(nameFor).join(' & '),
            courtLabel: courtLabel,
          ));
        }
        if (court.floaterSlot != null) {
          final f = court.floaterSlot!;
          rows.add(_teamRow(
            f.teamName ?? nameFor(f.playerId),
            '${nameFor(f.playerId)} · $oddPartnerLabel',
            courtLabel: courtLabel,
          ));
        }
      }
      if (rows.isEmpty) continue;
      if (showRoundHeaders) {
        sections.add(Padding(
          padding: const EdgeInsets.only(top: 6, bottom: 2),
          child: Text(l10n.scrambleKingRoundLabel(round.roundNumber),
              style: const TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w700, color: Colors.black45)),
        ));
      }
      sections.addAll(rows);
    }

    if (sections.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(l10n.scrambleKingTeamsEmpty,
            style: const TextStyle(fontSize: 13, color: Colors.black38)),
      );
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: sections);
  }

  Widget _teamRow(String teamName, String players, {String? courtLabel}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          children: [
            Container(
              width: 6,
              height: 6,
              margin: const EdgeInsets.only(right: 8),
              decoration: const BoxDecoration(color: AppColors.goldDark, shape: BoxShape.circle),
            ),
            Text(teamName,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.goldDark)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(players,
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                  overflow: TextOverflow.ellipsis),
            ),
            if (courtLabel != null) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                    color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
                child: Text(courtLabel,
                    style: const TextStyle(
                        fontSize: 10, fontWeight: FontWeight.w600, color: Colors.black45)),
              ),
            ],
          ],
        ),
      );

  Widget _roundHeader(AppLocalizations l10n, ScrambleKingRound round, bool expanded) {
    final allDone = round.isCompleted;
    final actualEnd = round.actualEndTime;
    final showActual = allDone && actualEnd != null;

    return InkWell(
      onTap: () => setState(() {
        if (!_expandedRoundIds.remove(round.id)) _expandedRoundIds.add(round.id);
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
            if (showActual) ...[
              Text(_fmtTime(actualEnd), style: const TextStyle(fontSize: 12, color: Colors.black45)),
              const SizedBox(width: 4),
              Text(l10n.overviewActual, style: const TextStyle(fontSize: 10, color: Colors.black38)),
            ] else ...[
              Flexible(
                child: Text(
                  '${_fmtTime(round.scheduledStartTime)} – ${_fmtTime(round.scheduledMatchEndTime)}',
                  style: const TextStyle(fontSize: 12, color: Colors.black45),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
            const Spacer(),
            Icon(expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                size: 18, color: Colors.black38),
          ],
        ),
      ),
    );
  }
}
