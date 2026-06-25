import 'package:flutter/material.dart';
import '../app/app_colors.dart';
import '../l10n/app_localizations.dart';
import '../models/group.dart';
import '../models/ko_bracket_tournament.dart';
import '../models/player.dart';
import '../models/team.dart';
import '../services/ko_bracket_storage_service.dart';
import '../widgets/tournaq_app_bar.dart';
import '../widgets/scrollable_page.dart';
import '../widgets/sheet_helpers.dart';
import 'ko_bracket_match_page.dart';
import 'ko_bracket_setup_page.dart';

const _kGold     = AppColors.gold;
const _kGoldDark = AppColors.goldDark;
const _kGoldCream = AppColors.goldCream;
const _kOlive    = AppColors.olive;
const _kOliveLight = AppColors.oliveLight;

class KoBracketBracketPage extends StatefulWidget {
  final KoBracketTournament tournament;
  final void Function(KoBracketTournament) onChanged;
  final List<Player> existingPlayers;
  final List<Team> existingTeams;
  final List<Group> existingGroups;
  final Player Function(String name) onCreatePlayer;
  final String Function(String name, List<String> linkedPlayerIds) onCreateTeam;

  const KoBracketBracketPage({
    super.key,
    required this.tournament,
    required this.onChanged,
    required this.existingPlayers,
    required this.existingTeams,
    required this.existingGroups,
    required this.onCreatePlayer,
    required this.onCreateTeam,
  });

  @override
  State<KoBracketBracketPage> createState() => _KoBracketBracketPageState();
}

class _KoBracketBracketPageState extends State<KoBracketBracketPage> {
  late KoBracketTournament _tournament;
  bool _teamsExpanded    = false;
  bool _scheduleExpanded = true;

  @override
  void initState() {
    super.initState();
    _tournament = _syncTeamsFromHub(widget.tournament);
  }

  KoBracketTournament _syncTeamsFromHub(KoBracketTournament t) {
    var changed = false;
    final synced = t.teams.map((koTeam) {
      if (koTeam.hubTeamId == null) return koTeam;
      final hubTeam = widget.existingTeams
          .where((ht) => ht.id == koTeam.hubTeamId)
          .firstOrNull;
      if (hubTeam == null) return koTeam;

      final slots = koTeam.players.length;
      final newPlayers = <KoPlayerSnapshot>[];
      for (final uid in hubTeam.userIds) {
        if (newPlayers.length >= slots) break;
        final p = widget.existingPlayers
            .where((ep) => ep.id == uid)
            .firstOrNull;
        if (p != null) {
          newPlayers.add(KoPlayerSnapshot(
            appPlayerId: p.id,
            name: p.name,
            skillRating: p.skillRating,
          ));
        }
      }
      while (newPlayers.length < slots) {
        newPlayers.add(KoPlayerSnapshot(
          appPlayerId: '', name: 'Player ${newPlayers.length + 1}'));
      }

      final playersChanged = newPlayers.length != koTeam.players.length ||
          newPlayers.asMap().entries.any((e) {
            final old = koTeam.players[e.key];
            return e.value.appPlayerId != old.appPlayerId ||
                e.value.name != old.name ||
                e.value.skillRating != old.skillRating;
          });
      if (!playersChanged) return koTeam;
      changed = true;
      return koTeam.copyWith(players: newPlayers);
    }).toList();

    if (!changed) return t;
    final updated = t.copyWith(teams: synced);
    KoBracketStorageService.save(updated);
    return updated;
  }

  void _persist(KoBracketTournament updated) {
    KoBracketStorageService.save(updated);
    setState(() => _tournament = updated);
    widget.onChanged(updated);
  }

  // ── Round label ───────────────────────────────────────────────────────────

  String _roundLabel(int round) {
    if (round == 0) return 'Play-in';
    final stepsFromFinal = _tournament.mainRoundCount - round;
    return switch (stepsFromFinal) {
      0 => 'Final',
      1 => 'Semi-final',
      2 => 'Quarter-final',
      _ => 'Round $round',
    };
  }

  // ── Open match scoreboard ─────────────────────────────────────────────────

  void _openMatch(KoMatch match) {
    if (match.team1Id == null || match.team2Id == null) return;
    Navigator.of(context)
        .push(MaterialPageRoute(
          builder: (_) => KoBracketMatchPage(
            tournament: _tournament,
            matchId: match.id,
            onChanged: _persist,
          ),
        ))
        .then((_) {
      final saved = KoBracketStorageService.loadAll()
          .where((t) => t.id == _tournament.id)
          .firstOrNull;
      if (saved != null && mounted) setState(() => _tournament = saved);
    });
  }

  // ── Withdraw ──────────────────────────────────────────────────────────────

  Future<void> _withdrawTeam(KoTeam selected) async {
    final l10n = AppLocalizations.of(context)!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(l10n.bracketWithdrawTitle,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        content: Text(
          l10n.bracketWithdrawBody(selected.name),
          style: const TextStyle(fontSize: 13, color: Colors.black54),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.btnCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(l10n.bracketWithdrawBtn),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    final currentMatch = _tournament.matches.firstWhere(
      (m) =>
          !m.isComplete &&
          (m.team1Id == selected.id || m.team2Id == selected.id),
      orElse: () => const KoMatch(id: '', round: 0, matchIndex: 0),
    );
    final withdrawRound =
        currentMatch.id.isEmpty ? null : currentMatch.round;

    var updated = _tournament.updateTeam(
      selected.copyWith(
          isWithdrawn: true, withdrawnAtRound: withdrawRound),
    );

    for (final m in updated.matches) {
      if (m.isComplete) continue;
      if (m.team1Id != selected.id && m.team2Id != selected.id) continue;
      final winnerId =
          m.team1Id == selected.id ? m.team2Id : m.team1Id;
      var resolved = m.copyWith(
        winnerId: winnerId,
        withdrawnTeamId: selected.id,
        status: KoMatchStatus.walkover,
        completedAt: DateTime.now(),
      );
      updated = updated.updateMatch(resolved);
      if (winnerId != null) {
        final propagated = m.round == 0
            ? KoBracketGenerator.propagatePlayInWinner(
                updated.matches, resolved.id)
            : KoBracketGenerator.propagateWinner(
                updated.matches, resolved.id);
        updated = updated.copyWith(matches: propagated);
      }
    }

    if (updated.allMatchesComplete) {
      updated = updated.copyWith(status: KoBracketStatus.completed);
    }
    _persist(updated);
  }

  // ── Swap team ─────────────────────────────────────────────────────────────

  void _swapTeam(KoTeam team) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _SwapPickerSheet(
        replacing: team,
        existingTeams: widget.existingTeams,
        takenHubTeamIds: _tournament.teams
            .where((t) => t.hubTeamId != null)
            .map((t) => t.hubTeamId!)
            .toSet(),
        playersPerSide: _tournament.teams.isNotEmpty
            ? _tournament.teams.first.players.length
            : 2,
        existingPlayers: widget.existingPlayers,
        onSwap: (newTeam) {
          // Give the incoming team a fresh KoTeam id so it doesn't clash.
          final incoming = KoTeam(
            id: KoTeam.generateId(),
            name: newTeam.name,
            players: newTeam.players,
            hubTeamId: newTeam.hubTeamId,
          );
          _persist(_tournament.swapTeam(team.id, incoming));
        },
      ),
    );
  }

  // ── Edit team ─────────────────────────────────────────────────────────────

  void _editTeam(KoTeam team) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => KoTeamEditorSheet(
        team: team,
        existingPlayers: widget.existingPlayers,
        existingTeams: widget.existingTeams,
        existingGroups: widget.existingGroups,
        generationMode: _tournament.generationMode,
        onCreatePlayer: widget.onCreatePlayer,
        onCreateTeam: widget.onCreateTeam,
        onSave: (updated) => _persist(_tournament.updateTeam(updated)),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: TournaQAppBar(title: 'Single Elimination', subtitle: _tournament.name),
      body: ScrollablePage(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Overview ─────────────────────────────────────────────────
            _sectionDivider(l10n.overviewSectionOverview, Icons.bar_chart_rounded),
            const SizedBox(height: 10),
            _buildOverviewCard(),
            const SizedBox(height: 20),

            // ── Time overview ─────────────────────────────────────────────
            _sectionDivider(
              l10n.labelTime,
              Icons.schedule_rounded,
              collapsible: true,
              expanded: _scheduleExpanded,
              onToggle: () => setState(() => _scheduleExpanded = !_scheduleExpanded),
            ),
            if (_scheduleExpanded) ...[
              const SizedBox(height: 10),
              _buildTimeOverviewCard(),
              const SizedBox(height: 20),
            ],

            // ── Teams ────────────────────────────────────────────────────
            _buildTeamsSection(),
            const SizedBox(height: 20),

            // ── Schedule ─────────────────────────────────────────────────
            _sectionDivider(l10n.overviewSectionSchedule, Icons.event_note_rounded),
            const SizedBox(height: 10),
            ..._buildScheduleSections(),
          ],
        ),
      ),
    );
  }

  // ── Section divider ───────────────────────────────────────────────────────

  Widget _sectionDivider(
    String label,
    IconData icon, {
    bool collapsible = false,
    bool expanded = false,
    VoidCallback? onToggle,
    Widget? trailing,
  }) {
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
                expanded
                    ? Icons.expand_less_rounded
                    : Icons.expand_more_rounded,
                size: 16,
                color: Colors.black38,
              ),
            ],
            if (trailing != null) ...[
              const SizedBox(width: 4),
              trailing,
            ],
          ],
        ),
      ),
    );
  }

  // ── Overview card ─────────────────────────────────────────────────────────

  Widget _buildOverviewCard() {
    final completed =
        _tournament.matches.where((m) => m.isComplete).length;
    final total = _tournament.matches.length;
    final progress = total == 0 ? 0.0 : completed / total;
    final isComplete =
        _tournament.status == KoBracketStatus.completed;
    final start = _tournament.estimatedStart;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _kOliveLight,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$completed / $total matches completed',
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 15),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            _chip(Icons.groups_rounded,
                                '${_tournament.teamCount} teams',
                                _kOliveLight, _kOlive),
                            _chip(Icons.crop_square_rounded,
                                '${_tournament.courtCount} court${_tournament.courtCount > 1 ? 's' : ''}',
                                _kOliveLight, _kOlive),
                            _chip(Icons.timer_rounded,
                                '${_tournament.minutesPerGame} min',
                                Colors.grey.shade100, Colors.black45),
                            _chip(Icons.info_outline_rounded,
                                _tournament.earlyRoundFormat.label,
                                Colors.grey.shade100, Colors.black45),
                            if (start != null)
                              _chip(Icons.schedule_rounded,
                                  'Starts ${_fmtT(start)}',
                                  _kGoldCream, _kGoldDark),
                          ],
                        ),
                      ],
                    ),
                  ),
                  _buildProgressRing(progress),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  backgroundColor: Colors.white,
                  valueColor:
                      const AlwaysStoppedAnimation(_kOlive),
                ),
              ),
            ],
          ),
        ),
        if (isComplete) ...[
          const SizedBox(height: 12),
          _buildWinnerBanner(),
        ],
      ],
    );
  }

  // ── Time overview ─────────────────────────────────────────────────────────

  static String _formatStartLabel(DateTime dt) {
    final weekday = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][dt.weekday - 1];
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$weekday ${dt.day}/${dt.month} $h:$m';
  }

  static String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes % 60;
    if (h == 0) return '${m}min';
    if (m == 0) return '${h}h';
    return '${h}h ${m}min';
  }

  void _pickRoundFormat(int round) {
    final isFinal = round >= _tournament.mainRoundCount - _tournament.finalRoundsCount + 1;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final fmt = isFinal ? _tournament.finalRoundFormat : _tournament.earlyRoundFormat;

          void pick(KoRoundFormat updated) {
            var t = _tournament.copyWith(
              earlyRoundFormat: isFinal ? null : updated,
              finalRoundFormat: isFinal ? updated : null,
            );
            t = KoBracketScheduler.assignTimes(t);
            _persist(t);
            setSheetState(() {});
          }

          Widget chipRow(List<int> options, int selected, void Function(int) onPick) {
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: options.map((v) {
                final sel = v == selected;
                return GestureDetector(
                  onTap: () => onPick(v),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 120),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: sel ? _kGold : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: sel ? _kGoldDark : Colors.grey.shade300,
                        width: sel ? 1.5 : 1,
                      ),
                    ),
                    child: Text('$v',
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: sel ? Colors.white : Colors.black54)),
                  ),
                );
              }).toList(),
            );
          }

          return TournaQSheet(
            body: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isFinal
                        ? AppLocalizations.of(context)!.bracketFinalRoundsFormat
                        : AppLocalizations.of(context)!.bracketEarlyRoundsFormat,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isFinal
                        ? AppLocalizations.of(context)!.bracketFinalRoundsAppliesTo(_tournament.finalRoundsCount)
                        : AppLocalizations.of(context)!.bracketEarlyRoundsAppliesTo,
                    style: const TextStyle(fontSize: 12, color: Colors.black45),
                  ),
                  const SizedBox(height: 20),
                  Text(AppLocalizations.of(context)!.setupSetsPerGame,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black54)),
                  const SizedBox(height: 8),
                  chipRow([1, 3, 5], fmt.setsPerGame,
                      (v) => pick(fmt.copyWith(setsPerGame: v))),
                  const SizedBox(height: 16),
                  Text(AppLocalizations.of(context)!.setupPointsPerSet,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black54)),
                  const SizedBox(height: 8),
                  chipRow([11, 15, 21], fmt.pointsPerSet,
                      (v) => pick(fmt.copyWith(pointsPerSet: v))),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _pickBreak(int round) {
    final isFinal = round >= _tournament.mainRoundCount - _tournament.finalRoundsCount + 1;
    final current = isFinal ? _tournament.finalBreakMinutes : _tournament.earlyBreakMinutes;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TournaQSheet(
        body: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isFinal
                    ? AppLocalizations.of(context)!.bracketBreakFinalRounds
                    : AppLocalizations.of(context)!.bracketBreakEarlyRounds,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [0, 5, 10, 15, 20, 30, 45, 60].map((v) {
                  final selected = v == current;
                  return GestureDetector(
                    onTap: () {
                      Navigator.of(context).pop();
                      var updated = _tournament.copyWith(
                        earlyBreakMinutes: isFinal ? null : v,
                        finalBreakMinutes: isFinal ? v : null,
                      );
                      updated = KoBracketScheduler.assignTimes(updated);
                      _persist(updated);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: selected ? _kGold : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: selected ? _kGoldDark : Colors.grey.shade300,
                          width: selected ? 1.5 : 1,
                        ),
                      ),
                      child: Text(
                        v == 0
                            ? AppLocalizations.of(context)!.bracketNoBreak
                            : AppLocalizations.of(context)!.labelMinutes(v),
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: selected ? Colors.white : Colors.black54,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _editStartTime() async {
    final current = _tournament.estimatedStart ?? DateTime.now();

    final date = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(current),
    );
    if (time == null || !mounted) return;

    final newStart = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    var updated = _tournament.copyWith(estimatedStart: newStart);
    updated = KoBracketScheduler.assignTimes(updated);
    _persist(updated);
  }

  Widget _buildTimeOverviewCard() {
    final start = _tournament.estimatedStart;

    if (start == null) {
      return GestureDetector(
        onTap: _editStartTime,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _kGoldCream,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.goldBadgeBorder),
          ),
          child: Row(children: [
            const Icon(Icons.schedule_rounded, size: 13, color: _kGoldDark),
            const SizedBox(width: 6),
            Expanded(
              child: Text(AppLocalizations.of(context)!.bracketNoStartTime,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _kGoldDark)),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.edit_rounded, size: 10, color: _kGoldDark),
          ]),
        ),
      );
    }

    final roundList = _tournament.allRounds
        .where((r) => _tournament.matchesForRound(r).isNotEmpty)
        .toList();
    final rows = <Widget>[];

    for (var i = 0; i < roundList.length; i++) {
      final round   = roundList[i];
      final matches = _tournament.matchesForRound(round);
      final isLast  = i == roundList.length - 1;

      DateTime? earliest, latest;
      for (final m in matches) {
        if (m.scheduledStartTime != null &&
            (earliest == null || m.scheduledStartTime!.isBefore(earliest))) {
          earliest = m.scheduledStartTime;
        }
        if (m.scheduledEndTime != null &&
            (latest == null || m.scheduledEndTime!.isAfter(latest))) {
          latest = m.scheduledEndTime;
        }
      }

      final fmt      = _tournament.formatForRound(round);
      final fmtLabel = '${fmt.setsPerGame}×${fmt.pointsPerSet}';
      final breakMins = isLast ? 0 : _tournament.breakAfterRound(round);

      rows.add(Padding(
        padding: EdgeInsets.only(bottom: isLast ? 0 : 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Col 1: round name + format chip ──────────────────
            GestureDetector(
              onTap: () => _pickRoundFormat(round),
              child: SizedBox(
                width: 96,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_roundLabel(round),
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87)),
                    const SizedBox(height: 3),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.goldBadgeBorder),
                      ),
                      child: Text(fmtLabel,
                          style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: _kGoldDark)),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            // ── Col 2: match count + break ────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${matches.length} match${matches.length == 1 ? '' : 'es'}',
                    style: const TextStyle(fontSize: 11, color: Colors.black45),
                  ),
                  if (!isLast) ...[
                    const SizedBox(height: 3),
                    GestureDetector(
                      onTap: () => _pickBreak(round),
                      child: Row(children: [
                        Icon(
                          breakMins > 0
                              ? Icons.coffee_rounded
                              : Icons.add_circle_outline_rounded,
                          size: 11,
                          color: breakMins > 0 ? _kOlive : Colors.black26,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          breakMins > 0 ? '$breakMins min break' : 'Add break',
                          style: TextStyle(
                              fontSize: 11,
                              color: breakMins > 0 ? _kOlive : Colors.black38),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.edit_rounded,
                            size: 9, color: Colors.black26),
                      ]),
                    ),
                  ],
                ],
              ),
            ),
            // ── Col 3: time range ─────────────────────────────────
            if (earliest != null && latest != null)
              Text('${_fmtT(earliest)} – ${_fmtT(latest)}',
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _kGoldDark)),
          ],
        ),
      ));
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _kGoldCream,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.goldBadgeBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.schedule_rounded, size: 13, color: _kGoldDark),
            const SizedBox(width: 6),
            Text(AppLocalizations.of(context)!.overviewSectionSchedule,
                style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w700, color: _kGoldDark)),
            const Spacer(),
            Text(_formatDuration(_tournament.estimatedDuration),
                style: const TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w600, color: _kGoldDark)),
          ]),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: _editStartTime,
            child: Row(children: [
              const Icon(Icons.play_circle_outline_rounded, size: 12, color: _kGoldDark),
              const SizedBox(width: 4),
              Text(AppLocalizations.of(context)!.bracketStartsLabel(_formatStartLabel(start)),
                  style: const TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w600, color: _kGoldDark)),
              const SizedBox(width: 4),
              const Icon(Icons.edit_rounded, size: 10, color: _kGoldDark),
            ]),
          ),
          if (rows.isNotEmpty) ...[
            const SizedBox(height: 10),
            const Divider(height: 1, color: AppColors.goldBadgeBorder),
            const SizedBox(height: 8),
            ...rows,
          ],
        ],
      ),
    );
  }

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
            valueColor: const AlwaysStoppedAnimation(_kOlive),
          ),
          Text(
            '${(progress * 100).round()}%',
            style: const TextStyle(
                fontSize: 11, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Widget _chip(IconData icon, String label, Color bg, Color fg) =>
      Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 11, color: fg),
          const SizedBox(width: 3),
          Text(label,
              style: TextStyle(
                  fontSize: 11,
                  color: fg,
                  fontWeight: FontWeight.w600)),
        ]),
      );

  // ── Winner banner ─────────────────────────────────────────────────────────

  Widget _buildWinnerBanner() {
    final finalMatch = _tournament.matches
        .where((m) =>
            m.round == _tournament.mainRoundCount && m.isComplete)
        .firstOrNull;
    final winnerId = finalMatch?.winnerId;
    final winner =
        winnerId != null ? _tournament.teamById(winnerId) : null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_kGold, _kGoldDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _kGold.withValues(alpha: 0.35),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(children: [
        const Icon(Icons.emoji_events_rounded,
            color: Colors.white, size: 32),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppLocalizations.of(context)!.bracketTournamentWinner,
                style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
            Text(
              winner?.name ?? 'TBD',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ]),
    );
  }

  // ── Teams section ─────────────────────────────────────────────────────────

  Widget _buildTeamsSection() {
    final isLive =
        _tournament.status != KoBracketStatus.completed;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sectionDivider(
          AppLocalizations.of(context)!.bracketSectionTeams(_tournament.teamCount),
          Icons.groups_rounded,
          collapsible: true,
          expanded: _teamsExpanded,
          onToggle: () =>
              setState(() => _teamsExpanded = !_teamsExpanded),
        ),
        if (_teamsExpanded) ...[
          const SizedBox(height: 10),
          ..._tournament.teams
              .map((t) => _buildTeamRow(t, isLive)),
        ],
      ],
    );
  }

  Widget _buildTeamRow(KoTeam team, bool isLive) {
    final isWithdrawn = team.isWithdrawn;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor:
                isWithdrawn ? Colors.grey.shade100 : _kOliveLight,
            child: Text(
              team.name.isNotEmpty ? team.name[0].toUpperCase() : '?',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: isWithdrawn
                    ? Colors.grey.shade400
                    : _kOlive,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        team.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isWithdrawn
                              ? Colors.grey.shade500
                              : null,
                          decoration: isWithdrawn
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                    ),
                    if (isWithdrawn) ...[
                      const SizedBox(width: 6),
                      _teamStatusChip('withdrawn'),
                    ],
                  ],
                ),
                if (team.players.isNotEmpty)
                  Text(
                    team.players.map((p) => p.name).join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 10, color: Colors.black38),
                  ),
              ],
            ),
          ),
          if (!isWithdrawn) ...[
            Tooltip(
              message: 'Edit Players',
              child: InkWell(
                onTap: () => _editTeam(team),
                borderRadius: BorderRadius.circular(8),
                child: const Padding(
                  padding: EdgeInsets.all(6),
                  child: Icon(Icons.edit_rounded, size: 16, color: Colors.black38),
                ),
              ),
            ),
            Tooltip(
              message: AppLocalizations.of(context)!.bracketSwapTeamTitle,
              child: InkWell(
                onTap: () => _swapTeam(team),
                borderRadius: BorderRadius.circular(8),
                child: const Padding(
                  padding: EdgeInsets.all(6),
                  child: Icon(Icons.swap_horiz_rounded, size: 18, color: Colors.black38),
                ),
              ),
            ),
            if (isLive)
              Tooltip(
                message: AppLocalizations.of(context)!.bracketWithdrawBtn,
                child: InkWell(
                  onTap: () => _withdrawTeam(team),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Icon(Icons.person_remove_rounded,
                        size: 18, color: Colors.red.shade400),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _teamStatusChip(String label) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            color: Colors.red.shade400,
            letterSpacing: 0.3,
          ),
        ),
      );

  // ── Schedule sections ─────────────────────────────────────────────────────

  List<Widget> _buildScheduleSections() {
    final rounds = _tournament.allRounds;
    return rounds.map((round) {
      final matches = _tournament.matchesForRound(round);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _roundHeader(round, matches),
          const SizedBox(height: 8),
          ...matches.map((m) => _matchCard(m, round)),
          const SizedBox(height: 20),
        ],
      );
    }).toList();
  }

  // ── Round header ──────────────────────────────────────────────────────────

  static String _fmtT(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  Widget _roundHeader(int round, List<KoMatch> matches) {
    final done    = matches.where((m) => m.isComplete).length;
    final total   = matches.length;
    final allDone = done == total && total > 0;
    final isCurrentRound = done < total &&
        (round == 0 ||
            _tournament
                .matchesForRound(round - 1)
                .every((m) => m.isComplete));

    DateTime? earliest, latest;
    for (final m in matches) {
      if (m.scheduledStartTime != null) {
        if (earliest == null ||
            m.scheduledStartTime!.isBefore(earliest)) {
          earliest = m.scheduledStartTime;
        }
      }
      if (m.scheduledEndTime != null) {
        if (latest == null || m.scheduledEndTime!.isAfter(latest)) {
          latest = m.scheduledEndTime;
        }
      }
    }

    return Row(
      children: [
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: allDone
                ? _kOlive
                : isCurrentRound
                    ? _kGoldCream
                    : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            _roundLabel(round),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: allDone
                  ? Colors.white
                  : isCurrentRound
                      ? _kGoldDark
                      : Colors.black45,
            ),
          ),
        ),
        const SizedBox(width: 8),
        if (earliest != null && latest != null)
          Text(
            '${_fmtT(earliest)} – ${_fmtT(latest)}',
            style: const TextStyle(fontSize: 12, color: Colors.black45),
          ),
        const Spacer(),
        _formatBadge(_tournament.formatForRound(round)),
      ],
    );
  }

  Widget _formatBadge(KoRoundFormat fmt) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Text(
          fmt.label,
          style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Colors.black45),
        ),
      );

  // ── Match card ─────────────────────────────────────────────────────────────

  Widget _matchCard(KoMatch match, int round) {
    final team1      = match.team1Id != null
        ? _tournament.teamById(match.team1Id!)
        : null;
    final team2      = match.team2Id != null
        ? _tournament.teamById(match.team2Id!)
        : null;
    final isBye      = match.status == KoMatchStatus.bye;
    final isWalkover = match.status == KoMatchStatus.walkover;
    final isComplete = match.isComplete;
    final canTap     = !isBye &&
        !isWalkover &&
        (isComplete || (team1 != null && team2 != null));

    final statusColor = switch (match.status) {
      KoMatchStatus.completed  => _kOlive,
      KoMatchStatus.inProgress => _kGold,
      KoMatchStatus.walkover   => Colors.orange,
      KoMatchStatus.bye        => Colors.grey,
      _                        => Colors.black38,
    };

    Color? schedDotColor;
    String? schedLabel;
    if (match.scheduledStartTime != null) {
      if (isComplete) {
        if (match.completedAt != null && match.scheduledEndTime != null) {
          final overMins = match.completedAt!
              .difference(match.scheduledEndTime!)
              .inMinutes;
          if (overMins > 0) {
            schedDotColor = Colors.orange.shade700;
            schedLabel = '+${overMins}m over';
          } else {
            schedDotColor = _kOlive;
            schedLabel = 'on time';
          }
        }
      } else if (!isBye && !isWalkover) {
        final now = DateTime.now();
        if (match.scheduledEndTime != null && now.isAfter(match.scheduledEndTime!)) {
          schedDotColor = Colors.red.shade600;
          schedLabel = 'overdue';
        } else if (now.isAfter(match.scheduledStartTime!)) {
          schedDotColor = Colors.amber.shade700;
          schedLabel = 'due';
        } else {
          schedDotColor = Colors.green.shade600;
          schedLabel = 'upcoming';
        }
      }
    }

    final statusIcon = switch (match.status) {
      KoMatchStatus.completed  => Icons.check_circle_rounded,
      KoMatchStatus.inProgress => Icons.sports_volleyball_rounded,
      KoMatchStatus.walkover   => Icons.person_off_rounded,
      KoMatchStatus.bye        => Icons.do_not_disturb_alt_rounded,
      _                        => Icons.schedule_rounded,
    };

    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      elevation: 0,
      color: match.status == KoMatchStatus.inProgress
          ? _kGoldCream
          : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: match.status == KoMatchStatus.inProgress
              ? _kGold.withValues(alpha: 0.5)
              : Colors.grey.shade200,
          width:
              match.status == KoMatchStatus.inProgress ? 1.5 : 1.0,
        ),
      ),
      child: InkWell(
        onTap: canTap ? () => _openMatch(match) : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: 14, vertical: 10),
          child: Row(
            children: [
              // Court badge
              if (match.courtAssignment != null) ...[
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: _kOliveLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(AppLocalizations.of(context)!.matchCourtLabel(match.courtAssignment!).split(' ').first,
                          style: const TextStyle(
                              fontSize: 7,
                              color: _kOlive,
                              fontWeight: FontWeight.w400)),
                      Text('${match.courtAssignment}',
                          style: const TextStyle(
                              fontSize: 16,
                              color: _kOlive,
                              fontWeight: FontWeight.w400,
                              height: 1)),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
              ],
              // Teams + time
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isBye ||
                        isWalkover ||
                        match.status == KoMatchStatus.repechage ||
                        match.status == KoMatchStatus.playIn)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: _statusTag(match.status),
                      ),
                    _teamRow(
                      team1?.name ?? 'TBD',
                      _teamScore(match, isTeam1: true),
                      match.winnerId == match.team1Id && isComplete,
                      team1?.isWithdrawn ?? false,
                      team1 == null,
                    ),
                    const SizedBox(height: 2),
                    _teamRow(
                      team2?.name ?? 'TBD',
                      _teamScore(match, isTeam1: false),
                      match.winnerId == match.team2Id && isComplete,
                      team2?.isWithdrawn ?? false,
                      team2 == null,
                    ),
                    if (match.scheduledStartTime != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (schedDotColor != null) ...[
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: schedDotColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 4),
                          ],
                          Text(
                            match.scheduledEndTime != null
                                ? '${_fmtT(match.scheduledStartTime!)} – ${_fmtT(match.scheduledEndTime!)}'
                                : _fmtT(match.scheduledStartTime!),
                            style: const TextStyle(
                                fontSize: 11, color: Colors.black38),
                          ),
                          if (schedLabel != null) ...[
                            const SizedBox(width: 4),
                            Text(
                              schedLabel,
                              style: TextStyle(
                                  fontSize: 10, color: schedDotColor),
                            ),
                          ],
                        ],
                      ),
                    ],
                    if (!isBye && !isWalkover) ...[
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          const Icon(Icons.gavel_rounded,
                              size: 9, color: Colors.blueGrey),
                          const SizedBox(width: 2),
                          Flexible(
                            child: Text(
                              match.refereeTeamId != null
                                  ? '${_tournament.teamById(match.refereeTeamId!)?.name ?? ''} refs'
                                  : 'Assign ref manually',
                              style: const TextStyle(
                                  fontSize: 10, color: Colors.blueGrey),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              // Status icon
              const SizedBox(width: 8),
              Icon(statusIcon, size: 18, color: statusColor),
            ],
          ),
        ),
      ),
    );
  }

  Widget _teamRow(
      String name, String? score, bool isWinner, bool isWithdrawn, bool isTbd) {
    return Row(
      children: [
        if (isWinner)
          const Padding(
            padding: EdgeInsets.only(right: 4),
            child: Icon(Icons.emoji_events_rounded,
                size: 12, color: _kGoldDark),
          ),
        Expanded(
          child: Text(
            name,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: isTbd
                  ? Colors.black26
                  : isWithdrawn
                      ? Colors.grey
                      : Colors.black87,
              decoration:
                  isWithdrawn ? TextDecoration.lineThrough : null,
            ),
          ),
        ),
        if (score != null)
          Text(
            score,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w400,
              color: isWinner ? _kGoldDark : Colors.black38,
            ),
          ),
      ],
    );
  }

  String? _teamScore(KoMatch match, {required bool isTeam1}) {
    if (!match.isComplete || match.sets.isEmpty) return null;
    final fmt = _tournament.formatForRound(match.round);
    if (fmt.setsPerGame == 1) {
      final s = match.sets.first;
      return isTeam1 ? '${s.score1}' : '${s.score2}';
    }
    final won = match.sets
        .where((s) => s.isCompleted &&
            (isTeam1 ? s.score1 > s.score2 : s.score2 > s.score1))
        .length;
    return '$won';
  }

  Widget _statusTag(KoMatchStatus status) {
    final (label, color) = switch (status) {
      KoMatchStatus.bye       => ('BYE', Colors.grey),
      KoMatchStatus.walkover  => ('W/O', Colors.orange),
      KoMatchStatus.playIn    => ('PLAY-IN', _kGold),
      KoMatchStatus.repechage => ('REPECHAGE', Colors.deepOrange),
      _                       => ('', Colors.transparent),
    };
    if (label.isEmpty) return const SizedBox.shrink();
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: color)),
    );
  }
}

// ── Swap picker sheet ─────────────────────────────────────────────────────────

class _SwapPickerSheet extends StatefulWidget {
  final KoTeam replacing;
  final List<Team> existingTeams;
  final Set<String> takenHubTeamIds;
  final int playersPerSide;
  final List<Player> existingPlayers;
  final void Function(KoTeam) onSwap;

  const _SwapPickerSheet({
    required this.replacing,
    required this.existingTeams,
    required this.takenHubTeamIds,
    required this.playersPerSide,
    required this.existingPlayers,
    required this.onSwap,
  });

  @override
  State<_SwapPickerSheet> createState() => _SwapPickerSheetState();
}

class _SwapPickerSheetState extends State<_SwapPickerSheet> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  KoTeam _buildKoTeam(Team hubTeam) {
    final slots = widget.playersPerSide;
    final players = <KoPlayerSnapshot>[];
    for (final uid in hubTeam.userIds) {
      if (players.length >= slots) break;
      final p = widget.existingPlayers.where((ep) => ep.id == uid).firstOrNull;
      if (p != null) {
        players.add(KoPlayerSnapshot(
          appPlayerId: p.id,
          name: p.name,
          skillRating: p.skillRating,
        ));
      }
    }
    while (players.length < slots) {
      players.add(KoPlayerSnapshot(appPlayerId: '', name: 'Player ${players.length + 1}'));
    }
    return KoTeam(
      id: KoTeam.generateId(),
      name: hubTeam.name,
      players: players,
      hubTeamId: hubTeam.id,
    );
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchCtrl.text.toLowerCase();
    final available = widget.existingTeams
        .where((t) => !widget.takenHubTeamIds.contains(t.id))
        .where((t) => query.isEmpty || t.name.toLowerCase().contains(query))
        .toList();

    return TournaQSheet(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppLocalizations.of(context)!.bracketSwapTeamTitle,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text(
                  AppLocalizations.of(context)!.bracketSwapTeamSubtitle(widget.replacing.name),
                  style: const TextStyle(fontSize: 12, color: Colors.black45),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _searchCtrl,
                  autofocus: true,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: AppLocalizations.of(context)!.bracketSearchTeams,
                    prefixIcon: const Icon(Icons.search_rounded, size: 18, color: Colors.black45),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: available.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        widget.existingTeams.isEmpty
                            ? AppLocalizations.of(context)!.bracketNoTeamsInHub
                            : AppLocalizations.of(context)!.bracketAllTeamsInTournament,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 13, color: Colors.black38),
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                    itemCount: available.length,
                    itemBuilder: (_, i) {
                      final t = available[i];
                      final pc = t.userIds.length;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: BorderSide(color: Colors.grey.shade200)),
                        elevation: 0,
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: _kGoldCream,
                            child: Text(
                              t.name.isNotEmpty ? t.name[0].toUpperCase() : '?',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: _kGoldDark,
                                  fontSize: 14),
                            ),
                          ),
                          title: Text(t.name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 14)),
                          subtitle: pc > 0
                              ? Text('$pc player${pc == 1 ? '' : 's'}',
                                  style: const TextStyle(fontSize: 12))
                              : null,
                          trailing: const Icon(Icons.swap_horiz_rounded,
                              color: _kGold, size: 20),
                          onTap: () {
                            widget.onSwap(_buildKoTeam(t));
                            Navigator.of(context).pop();
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
