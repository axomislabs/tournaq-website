import 'package:flutter/material.dart';
import '../app/app_colors.dart';
import '../l10n/app_localizations.dart';
import '../models/group.dart';
import '../models/ko_bracket_tournament.dart';
import '../models/player.dart';
import '../models/player_status.dart';
import '../models/team.dart';
import '../scoring/ko_bracket_adapter.dart';
import '../services/ko_bracket_storage_service.dart';
import '../services/ko_bracket_transfer_service.dart';
import '../widgets/ko_team_editor_sheet.dart';
import '../widgets/qr_export_sheet.dart';
import '../widgets/tournament_player_row.dart';
import '../widgets/tournaq_app_bar.dart';
import '../widgets/scrollable_page.dart';
import '../widgets/sheet_helpers.dart';
import 'ko_bracket_match_page.dart';
import 'qr_scan_page.dart';

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
  final void Function(String id, String name, int? skillRating)? onUpdatePlayer;

  const KoBracketBracketPage({
    super.key,
    required this.tournament,
    required this.onChanged,
    required this.existingPlayers,
    required this.existingTeams,
    required this.existingGroups,
    required this.onCreatePlayer,
    required this.onCreateTeam,
    this.onUpdatePlayer,
  });

  @override
  State<KoBracketBracketPage> createState() => _KoBracketBracketPageState();
}

class _KoBracketBracketPageState extends State<KoBracketBracketPage> {
  late KoBracketTournament _tournament;

  // Rounds collapsed to just their header (keyed by round number). All expanded
  // by default — mirrors the Social Scramble schedule.
  final Set<int> _collapsedRoundIds = {};

  // Registered while the Schedule Preview / Teams bottom sheets are open, so
  // in-place mutations from nested dialogs (edit/swap/withdraw a team, edit the
  // schedule) redraw the open sheet with fresh data. Cleared from the sheet's
  // own dispose(), synchronous with unmount.
  VoidCallback? _scheduleSheetRefresh;
  VoidCallback? _teamsSheetRefresh;

  @override
  void initState() {
    super.initState();
    _tournament = _syncTeamsFromHub(widget.tournament);
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
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
    _scheduleSheetRefresh?.call();
    _teamsSheetRefresh?.call();
  }

  // ── Round label ───────────────────────────────────────────────────────────

  String _roundLabel(int round) {
    final l10n = AppLocalizations.of(context)!;
    if (round == 0) return l10n.setupOddTeamsPlayIn;
    final stepsFromFinal = _tournament.mainRoundCount - round;
    return switch (stepsFromFinal) {
      0 => l10n.bracketRoundFinal,
      1 => l10n.bracketRoundSemi,
      2 => l10n.bracketRoundQuarter,
      _ => l10n.bracketRoundNumbered(round),
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
          isWithdrawn: true,
          withdrawnAtRound: withdrawRound,
          status: PlayerStatus.ejected),
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
        onUpdatePlayer: widget.onUpdatePlayer,
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
      appBar: TournaQAppBar(
        title: 'Single Elimination',
        subtitle: _tournament.name,
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner_rounded,
                color: AppColors.goldLight),
            tooltip: l10n.scrambleImportResult,
            onPressed: _importResult,
          ),
        ],
      ),
      body: ScrollablePage(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Overview ─────────────────────────────────────────────────
            // Teams and the schedule timeline live behind the header pills
            // (tap the Teams / Est.-end chips), mirroring Social Scramble.
            _sectionDivider(l10n.overviewSectionOverview, Icons.bar_chart_rounded),
            const SizedBox(height: 10),
            _buildOverviewCard(),
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
    final l10n = AppLocalizations.of(context)!;
    final completed =
        _tournament.matches.where((m) => m.isComplete).length;
    final total = _tournament.matches.length;
    final progress = total == 0 ? 0.0 : completed / total;
    final isComplete =
        _tournament.status == KoBracketStatus.completed;

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
                            // Tappable → opens the Teams sheet (edit/swap/withdraw).
                            _chip(Icons.groups_rounded,
                                l10n.statsTeams(_tournament.teamCount),
                                onTap: _showTeamsSheet),
                            // Display-only (editing these reshuffles the bracket).
                            _chip(Icons.crop_square_rounded,
                                l10n.statsCourts(_tournament.courtCount)),
                            _chip(Icons.people_rounded,
                                '${_tournament.playersPerSide}v${_tournament.playersPerSide}'),
                            // Generation mode + odd-team strategy — editable until
                            // the bracket has started, then locked.
                            _chip(
                              _tournament.generationMode ==
                                      KoBracketGenerationMode.seeded
                                  ? Icons.leaderboard_rounded
                                  : Icons.shuffle_rounded,
                              _tournament.generationMode ==
                                      KoBracketGenerationMode.seeded
                                  ? l10n.setupSeedingSeeded
                                  : l10n.setupSeedingRandom,
                              onTap: _canEditGeneration
                                  ? _showGenerationSheet
                                  : null,
                              locked: !_canEditGeneration,
                            ),
                            _chip(
                              switch (_tournament.oddTeamStrategy) {
                                KoOddTeamStrategy.byes =>
                                  Icons.skip_next_rounded,
                                KoOddTeamStrategy.playIn =>
                                  Icons.play_arrow_rounded,
                                KoOddTeamStrategy.playInWithRepechage =>
                                  Icons.replay_rounded,
                              },
                              switch (_tournament.oddTeamStrategy) {
                                KoOddTeamStrategy.byes => l10n.setupOddTeamsByes,
                                KoOddTeamStrategy.playIn =>
                                  l10n.setupOddTeamsPlayIn,
                                KoOddTeamStrategy.playInWithRepechage =>
                                  l10n.bracketPlayInPlus,
                              },
                              onTap: _canEditGeneration
                                  ? _showGenerationSheet
                                  : null,
                              locked: !_canEditGeneration,
                            ),
                            // Tappable → opens the Schedule Preview sheet.
                            _chip(Icons.flag_rounded,
                                _tournament.estimatedEnd != null
                                    ? l10n.bracketEndsAt(
                                        _fmtT(_tournament.estimatedEnd!))
                                    : l10n.bracketSetSchedule,
                                onTap: _showSchedulePreviewSheet),
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

  static String _formatStartDate(DateTime dt) {
    final weekday = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][dt.weekday - 1];
    return '$weekday ${dt.day}/${dt.month}';
  }

  static String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes % 60;
    if (h == 0) return '${m}min';
    if (m == 0) return '${h}h';
    return '${h}h ${m}min';
  }

  void _pickRoundFormat(int round, String roundLabel) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final fmt = _tournament.roundFormats[round] ?? _tournament.defaultFormat;
          final l10n = AppLocalizations.of(context)!;

          void pick(KoRoundFormat updated) {
            var t = _tournament.copyWith(
              roundFormats: {..._tournament.roundFormats, round: updated},
            );
            t = KoBracketScheduler.assignTimes(t);
            _persist(t);
            setSheetState(() {});
          }

          return TournaQSheet(
            body: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(roundLabel,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 20),
                  // All three settings share the Quick Game dropdown look.
                  _configDropdown(
                    label: l10n.setupSetsPerGame,
                    valueText: '${fmt.setsPerGame}',
                    itemBuilder: (_) => [
                      for (final v in const [1, 3, 5])
                        PopupMenuItem<int>(value: v, child: Text('$v')),
                    ],
                    onSelected: (v) => pick(fmt.copyWith(setsPerGame: v)),
                  ),
                  const SizedBox(height: 12),
                  _configDropdown(
                    label: l10n.bracketTargetScore,
                    valueText: '${fmt.pointsPerSet}',
                    itemBuilder: (_) => [
                      for (final v in const [11, 15, 21])
                        PopupMenuItem<int>(value: v, child: Text('$v')),
                      PopupMenuItem<int>(
                          value: _kCustomSentinel,
                          child: Text(l10n.optionCustom)),
                    ],
                    onSelected: (v) async {
                      if (v == _kCustomSentinel) {
                        await _showCustomValueDialog(
                          title: l10n.bracketTargetScore,
                          initial: fmt.pointsPerSet,
                          minValue: 1,
                          onConfirm: (value) =>
                              pick(fmt.copyWith(pointsPerSet: value)),
                        );
                      } else {
                        pick(fmt.copyWith(pointsPerSet: v));
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  _configDropdown(
                    label: l10n.bracketSideChange,
                    valueText: fmt.sideChangeInterval == null
                        ? l10n.bracketSideChangeOff
                        : '${fmt.sideChangeInterval}',
                    itemBuilder: (_) => [
                      PopupMenuItem<int>(
                          value: 0, child: Text(l10n.bracketSideChangeOff)),
                      for (final v in const [5, 7])
                        PopupMenuItem<int>(value: v, child: Text('$v')),
                      PopupMenuItem<int>(
                          value: _kCustomSentinel,
                          child: Text(l10n.optionCustom)),
                    ],
                    onSelected: (v) async {
                      if (v == _kCustomSentinel) {
                        await _showCustomValueDialog(
                          title: l10n.bracketSideChange,
                          initial: fmt.sideChangeInterval ?? 5,
                          minValue: 1,
                          onConfirm: (value) =>
                              pick(fmt.copyWith(sideChangeInterval: value)),
                        );
                      } else if (v == 0) {
                        pick(fmt.copyWith(clearSideChangeInterval: true));
                      } else {
                        pick(fmt.copyWith(sideChangeInterval: v));
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: fmt.notifyOnTargetReached,
                    activeThumbColor: _kGold,
                    title: Text(l10n.bracketNotifyTarget,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600)),
                    subtitle: Text(l10n.bracketNotifyTargetDesc,
                        style: const TextStyle(
                            fontSize: 12, color: Colors.black54)),
                    onChanged: (v) =>
                        pick(fmt.copyWith(notifyOnTargetReached: v)),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  static const int _kCustomSentinel = -1;

  /// A labeled dropdown box (label on top, value below) opened as a popup menu —
  /// the same look and feel as the Quick Game scoreboard's target/side-swap
  /// dropdowns. [enabled] false renders it greyed and non-interactive.
  Widget _configDropdown({
    required String label,
    required String valueText,
    required List<PopupMenuEntry<int>> Function(BuildContext) itemBuilder,
    required void Function(int) onSelected,
    bool enabled = true,
  }) {
    return PopupMenuButton<int>(
      enabled: enabled,
      itemBuilder: itemBuilder,
      onSelected: onSelected,
      padding: EdgeInsets.zero,
      position: PopupMenuPosition.under,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(
              color: enabled
                  ? _kGold.withValues(alpha: 0.4)
                  : Colors.grey.shade300),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(label,
                      style: const TextStyle(
                          fontSize: 11,
                          color: Colors.black54,
                          fontWeight: FontWeight.w600)),
                  Text(valueText,
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: enabled ? _kGoldDark : Colors.grey)),
                ],
              ),
            ),
            Icon(Icons.arrow_drop_down,
                color: enabled ? _kGoldDark : Colors.grey),
          ],
        ),
      ),
    );
  }

  /// Manual-entry dialog for a "Custom…" dropdown option (target score / side
  /// change), mirroring the Quick Game scoreboard.
  Future<void> _showCustomValueDialog({
    required String title,
    required int initial,
    required int minValue,
    required ValueChanged<int> onConfirm,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final ctrl = TextEditingController(text: '$initial');
    try {
      final ok = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: Colors.white,
          title: Text(title,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          content: TextField(
            controller: ctrl,
            autofocus: true,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(l10n.btnCancel),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: _kOlive, foregroundColor: Colors.white),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(l10n.btnSave),
            ),
          ],
        ),
      );
      if (ok == true) {
        final value = int.tryParse(ctrl.text) ?? initial;
        onConfirm(value < minValue ? minValue : value);
      }
    } finally {
      Future.delayed(const Duration(milliseconds: 300), ctrl.dispose);
    }
  }

  void _pickBreak(int round, String roundLabel) {
    final current = _tournament.roundBreaks[round] ?? 0;

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
                AppLocalizations.of(context)!.bracketBreakAfter(roundLabel),
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
                        roundBreaks: {..._tournament.roundBreaks, round: v},
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

  Future<void> _editStartDate() async {
    final current = _tournament.estimatedStart ?? DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;
    final newStart = DateTime(date.year, date.month, date.day,
        current.hour, current.minute);
    var updated = _tournament.copyWith(estimatedStart: newStart);
    updated = KoBracketScheduler.assignTimes(updated);
    _persist(updated);
  }

  Future<void> _editStartTimeOnly() async {
    final current = _tournament.estimatedStart ?? DateTime.now();
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(current),
    );
    if (time == null || !mounted) return;
    final newStart = DateTime(current.year, current.month, current.day,
        time.hour, time.minute);
    var updated = _tournament.copyWith(estimatedStart: newStart);
    updated = KoBracketScheduler.assignTimes(updated);
    _persist(updated);
  }

  // ── Bracket generation (editable until the first match starts) ────────────

  bool get _canEditGeneration =>
      !_tournament.matches.any((m) => m.isComplete || m.startedAt != null);

  void _applyGeneration(
      KoBracketGenerationMode mode, KoOddTeamStrategy strategy) {
    if (mode == _tournament.generationMode &&
        strategy == _tournament.oddTeamStrategy) {
      return;
    }
    var t =
        _tournament.copyWith(generationMode: mode, oddTeamStrategy: strategy);
    t = t.copyWith(matches: KoBracketGenerator.generate(t));
    t = KoBracketScheduler.assignTimes(t);
    _persist(t);
  }

  void _showGenerationSheet() {
    var mode = _tournament.generationMode;
    var strategy = _tournament.oddTeamStrategy;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) {
          final l10n = AppLocalizations.of(context)!;
          return TournaQSheet(
            body: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                  20, 8, 20, MediaQuery.of(ctx).viewInsets.bottom + 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(children: [
                    Expanded(
                      child: Text(l10n.bracketGenerationTitle,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w800)),
                    ),
                    TextButton(
                      onPressed: () {
                        _applyGeneration(mode, strategy);
                        Navigator.of(ctx).pop();
                      },
                      style: TextButton.styleFrom(foregroundColor: _kGold),
                      child: Text(l10n.btnSave,
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ]),
                  const SizedBox(height: 16),
                  Text(l10n.bracketSeeding,
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.black54)),
                  const SizedBox(height: 8),
                  _genOption(
                    icon: Icons.shuffle_rounded,
                    title: l10n.setupSeedingRandom,
                    subtitle: l10n.bracketSeedingRandomDesc,
                    selected: mode == KoBracketGenerationMode.random,
                    onTap: () =>
                        setSheet(() => mode = KoBracketGenerationMode.random),
                  ),
                  _genOption(
                    icon: Icons.leaderboard_rounded,
                    title: l10n.setupSeedingSeeded,
                    subtitle: l10n.bracketSeedingSeededDesc,
                    selected: mode == KoBracketGenerationMode.seeded,
                    enabled: false, // visible but not selectable (yet)
                    onTap: () {},
                  ),
                  const SizedBox(height: 16),
                  Text(l10n.bracketOddTeamsSection,
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.black54)),
                  const SizedBox(height: 8),
                  _genOption(
                    icon: Icons.skip_next_rounded,
                    title: l10n.setupOddTeamsByes,
                    subtitle: l10n.bracketOddByesDesc,
                    selected: strategy == KoOddTeamStrategy.byes,
                    onTap: () =>
                        setSheet(() => strategy = KoOddTeamStrategy.byes),
                  ),
                  _genOption(
                    icon: Icons.play_arrow_rounded,
                    title: l10n.setupOddTeamsPlayIn,
                    subtitle: l10n.bracketOddPlayInDesc,
                    selected: strategy == KoOddTeamStrategy.playIn,
                    onTap: () =>
                        setSheet(() => strategy = KoOddTeamStrategy.playIn),
                  ),
                  _genOption(
                    icon: Icons.replay_rounded,
                    title: l10n.bracketPlayInPlus,
                    subtitle: l10n.bracketOddPlayInPlusDesc,
                    selected:
                        strategy == KoOddTeamStrategy.playInWithRepechage,
                    enabled: false, // visible but not selectable (yet)
                    onTap: () {},
                  ),
                  const SizedBox(height: 10),
                  Text(
                    l10n.bracketRegenNote,
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _genOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool selected,
    required VoidCallback onTap,
    bool enabled = true,
  }) {
    // Disabled options stay visible (greyed, non-tappable) so the roadmap is
    // clear — e.g. Seeded and Play-in+ aren't selectable yet.
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Opacity(
        opacity: enabled ? 1.0 : 0.45,
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: selected ? _kGoldCream : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected ? _kGold : Colors.black12,
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Row(children: [
              Icon(icon,
                  size: 18, color: selected ? _kGoldDark : Colors.black45),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: selected ? _kGoldDark : Colors.black87)),
                    Text(subtitle,
                        style: const TextStyle(
                            fontSize: 11, color: Colors.black45)),
                  ],
                ),
              ),
              if (selected && enabled)
                const Icon(Icons.check_circle_rounded,
                    size: 18, color: _kGold),
              if (!enabled)
                const Icon(Icons.lock_rounded, size: 15, color: Colors.black38),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _buildTimeOverviewCard() {
    final start = _tournament.estimatedStart;

    if (start == null) {
      return GestureDetector(
        onTap: _editStartDate,
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
              onTap: () => _pickRoundFormat(round, _roundLabel(round)),
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
                      onTap: () => _pickBreak(round, _roundLabel(round)),
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
                          breakMins > 0
                              ? AppLocalizations.of(context)!
                                  .bracketRoundBreak(breakMins)
                              : AppLocalizations.of(context)!.bracketAddBreak,
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
            Text(AppLocalizations.of(context)!.overviewSectionTimeline,
                style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w700, color: _kGoldDark)),
            const Spacer(),
            Text(_formatDuration(_tournament.estimatedDuration),
                style: const TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w600, color: _kGoldDark)),
          ]),
          const SizedBox(height: 6),
          Row(children: [
            const Icon(Icons.play_circle_outline_rounded, size: 12, color: _kGoldDark),
            const SizedBox(width: 4),
            GestureDetector(
              onTap: _editStartDate,
              child: Row(children: [
                Text(_formatStartDate(start),
                    style: const TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w600, color: _kGoldDark)),
                const SizedBox(width: 2),
                const Icon(Icons.edit_rounded, size: 9, color: _kGoldDark),
              ]),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _editStartTimeOnly,
              child: Row(children: [
                Text(_fmtT(start),
                    style: const TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w600, color: _kGoldDark)),
                const SizedBox(width: 2),
                const Icon(Icons.edit_rounded, size: 9, color: _kGoldDark),
              ]),
            ),
          ]),
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

  /// Opt-in pace alerts — sits directly beneath the schedule preview (matching
  /// Social Scramble / Scramble King). When on, each round header shows an
  /// upcoming / due / overdue / completed status label from the scheduled times.
  Widget _buildPaceAlertsToggle() {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: _kGoldCream,
        borderRadius: BorderRadius.circular(14),
      ),
      child: SwitchListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 8),
        value: _tournament.paceAlertsEnabled,
        activeThumbColor: _kGold,
        onChanged: (v) => _persist(_tournament.copyWith(paceAlertsEnabled: v)),
        title: Text(l10n.timelinePaceAlertsTitle,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        subtitle: Text(l10n.timelinePaceAlertsSubtitle,
            style: const TextStyle(fontSize: 12, color: Colors.black54)),
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

  /// White pill matching the Social Scramble overview chips. Shows an edit
  /// pencil when [onTap] is set, or a lock glyph when [locked] (an otherwise
  /// editable setting frozen because the tournament has started).
  Widget _chip(IconData icon, String label,
      {VoidCallback? onTap, bool locked = false}) {
    final chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black12),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 12, color: AppColors.oliveMedium),
        const SizedBox(width: 4),
        Text(label,
            style: const TextStyle(
                fontSize: 11, color: Colors.black87, fontWeight: FontWeight.w600)),
        if (locked) ...[
          const SizedBox(width: 3),
          const Icon(Icons.lock_rounded, size: 10, color: Colors.black38),
        ] else if (onTap != null) ...[
          const SizedBox(width: 3),
          const Icon(Icons.edit_rounded, size: 10, color: Colors.black38),
        ],
      ]),
    );
    if (onTap == null) return chip;
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: chip,
    );
  }

  // ── Schedule Preview sheet ────────────────────────────────────────────────

  /// Opened from the header's "Ends" pill. Hosts the timeline that used to be
  /// a mid-page collapsible section: start date/time, estimated duration, and
  /// the per-round format/break/time rows (all still tap-to-edit).
  void _showSchedulePreviewSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _RefreshableSheet(
        onMount: (refresh) => _scheduleSheetRefresh = refresh,
        onUnmount: () => _scheduleSheetRefresh = null,
        builder: (ctx) {
          final l10n = AppLocalizations.of(context)!;
          return TournaQSheet(
            body: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                  20, 8, 20, MediaQuery.of(ctx).viewInsets.bottom + 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(l10n.overviewSectionTimeline,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 16),
                  _buildTimeOverviewCard(),
                  const SizedBox(height: 12),
                  _buildPaceAlertsToggle(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Teams sheet ───────────────────────────────────────────────────────────

  /// Opened from the header's "Teams" pill. Hosts the team roster with the
  /// edit / swap / withdraw actions that used to be a mid-page section.
  void _showTeamsSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _RefreshableSheet(
        onMount: (refresh) => _teamsSheetRefresh = refresh,
        onUnmount: () => _teamsSheetRefresh = null,
        builder: (ctx) {
          final l10n = AppLocalizations.of(context)!;
          final isLive = _tournament.status != KoBracketStatus.completed;
          return TournaQSheet(
            body: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                  20, 8, 20, MediaQuery.of(ctx).viewInsets.bottom + 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(l10n.bracketSectionTeams(_tournament.teamCount),
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  ..._tournament.teams.map((t) => _buildTeamRow(t, isLive)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Winner banner ─────────────────────────────────────────────────────────

  Widget _buildWinnerBanner() {
    final l10n = AppLocalizations.of(context)!;

    // Use the actual highest main-bracket round from the match data — more
    // robust than mainRoundCount when team count changes after generation.
    final maxRound = _tournament.allRounds.where((r) => r > 0).lastOrNull;
    if (maxRound == null) return const SizedBox.shrink();

    final finalMatch = _tournament.matches
        .where((m) => m.round == maxRound && m.isComplete)
        .firstOrNull;
    if (finalMatch == null) return const SizedBox.shrink();

    final winnerId = finalMatch.winnerId;
    final loserId =
        finalMatch.team1Id == winnerId ? finalMatch.team2Id : finalMatch.team1Id;

    final winner = winnerId != null ? _tournament.teamById(winnerId) : null;
    final runnerUp = loserId != null ? _tournament.teamById(loserId) : null;

    // Semi-final losers share 3rd place.
    final thirdPlaceTeams = <KoTeam>[];
    if (maxRound > 1) {
      for (final semi in _tournament.matches
          .where((m) => m.round == maxRound - 1 && m.isComplete)) {
        final semiLoserId =
            semi.team1Id == semi.winnerId ? semi.team2Id : semi.team1Id;
        final loser =
            semiLoserId != null ? _tournament.teamById(semiLoserId) : null;
        if (loser != null) thirdPlaceTeams.add(loser);
      }
    }

    Widget placeRow(String medal, String label, String name) => Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(medal, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                          fontWeight: FontWeight.w600)),
                  Text(name,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ],
        );

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          placeRow('🥇', l10n.bracketTournamentWinner, winner?.name ?? l10n.bracketTbd),
          if (runnerUp != null) ...[
            const Divider(color: Colors.white24, height: 20),
            placeRow('🥈', l10n.bracketRunnerUp, runnerUp.name),
          ],
          if (thirdPlaceTeams.isNotEmpty) ...[
            const Divider(color: Colors.white24, height: 20),
            placeRow('🥉', l10n.bracketThirdPlace,
                thirdPlaceTeams.map((t) => t.name).join(' · ')),
          ],
        ],
      ),
    );
  }

  // ── Team row (rendered inside the Teams sheet) ────────────────────────────

  Widget _buildTeamRow(KoTeam team, bool isLive) {
    final inactive = !team.isActive;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: inactive ? Colors.grey.shade100 : _kOliveLight,
            child: Text(
              team.name.isNotEmpty ? team.name[0].toUpperCase() : '?',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: inactive ? Colors.grey.shade400 : _kOlive,
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
                          color: inactive ? Colors.grey.shade500 : null,
                          decoration: inactive ? TextDecoration.lineThrough : null,
                        ),
                      ),
                    ),
                    if (team.status != PlayerStatus.active) ...[
                      const SizedBox(width: 6),
                      PlayerStatusChip(team.status),
                    ],
                  ],
                ),
                if (team.players.isNotEmpty)
                  Text(
                    team.players.map((p) => p.name).join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 10, color: Colors.black38),
                  ),
              ],
            ),
          ),
          if (team.isActive) ...[
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


  // ── Schedule sections ─────────────────────────────────────────────────────

  List<Widget> _buildScheduleSections() {
    final rounds = _tournament.allRounds;
    return rounds.map((round) {
      final matches = _tournament.matchesForRound(round);
      final collapsed = _collapsedRoundIds.contains(round);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _roundHeader(round, matches, collapsed),
          if (!collapsed) ...[
            const SizedBox(height: 8),
            ...matches.map((m) => _matchCard(m, round)),
          ],
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

  Widget _roundHeader(int round, List<KoMatch> matches, bool collapsed) {
    final done    = matches.where((m) => m.isComplete).length;
    final total   = matches.length;
    final allDone = done == total && total > 0;
    final anyInProgress =
        matches.any((m) => m.status == KoMatchStatus.inProgress);

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

    final isLastRound = round == _tournament.allRounds.last;
    final breakMins = isLastRound ? 0 : _tournament.breakAfterRound(round);

    // Round-level status icon — same visual language as the per-match card icon.
    final (statusIcon, statusColor) = allDone
        ? (Icons.check_circle_rounded, _kOlive)
        : anyInProgress
            ? (Icons.sports_volleyball_rounded, _kGold)
            : (Icons.schedule_rounded, Colors.black38);

    final l10n = AppLocalizations.of(context)!;
    final timeRange = (earliest != null && latest != null)
        ? '${_fmtT(earliest)} – ${_fmtT(latest)}'
        : null;
    final breakLabel = breakMins > 0 ? l10n.bracketRoundBreak(breakMins) : null;

    // Pace-alert status (opt-in) — same labels as the Social Scramble timeline.
    final now = DateTime.now();
    final isOverdue = !allDone && latest != null && now.isAfter(latest);
    final hasStarted = earliest != null && now.isAfter(earliest);
    final (paceLabel, paceColor) = allDone
        ? (l10n.statusCompleted, _kOlive)
        : isOverdue
            ? (l10n.statusOverdue, Colors.red.shade400)
            : hasStarted
                ? (l10n.statusDue, _kGold)
                : (l10n.statusUpcoming, Colors.black26);
    final showPace = _tournament.paceAlertsEnabled;

    return InkWell(
      onTap: () => setState(() {
        collapsed
            ? _collapsedRoundIds.remove(round)
            : _collapsedRoundIds.add(round);
      }),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          children: [
            // Round pill — uniform gold for pending rounds, olive once complete
            // (no separate grey "future round" state, which read as confusing).
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: allDone ? _kOlive : _kGoldCream,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _roundLabel(round),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: allDone ? Colors.white : _kGoldDark,
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Time range on top, break beneath it (where a break is expected).
            // The sets/points format badge now lives on each match card
            // instead, so it no longer competes with this row for width.
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (timeRange != null)
                    Text(timeRange,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 12, color: Colors.black45)),
                  if (breakLabel != null) ...[
                    const SizedBox(height: 2),
                    Text(breakLabel,
                        style: const TextStyle(
                            fontSize: 11, color: Colors.black38)),
                  ],
                ],
              ),
            ),
            // Pace-alert status pill on the right of the round line (matching
            // the Social Scramble timeline).
            if (showPace) ...[
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: paceColor.withValues(alpha: allDone ? 1.0 : 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(paceLabel,
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: allDone ? Colors.white : paceColor)),
              ),
              const SizedBox(width: 6),
            ],
            Icon(statusIcon, size: 16, color: statusColor),
            const SizedBox(width: 4),
            Icon(
              collapsed
                  ? Icons.expand_more_rounded
                  : Icons.expand_less_rounded,
              size: 16,
              color: Colors.black38,
            ),
          ],
        ),
      ),
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

  // ── Match QR / manual-score menu ──────────────────────────────────────────

  Widget _buildMatchMenu(KoMatch match, int round) {
    final l10n = AppLocalizations.of(context)!;
    return PopupMenuButton<String>(
      icon: const Icon(Icons.qr_code_rounded, size: 20, color: Colors.black45),
      padding: EdgeInsets.zero,
      tooltip: '',
      onSelected: (v) {
        if (v == 'export') _exportMatch(match);
        if (v == 'import') _importResult();
        if (v == 'score') _showManualScoreDialog(match, round);
      },
      itemBuilder: (ctx) => [
        PopupMenuItem(
          value: 'export',
          child: Row(children: [
            const Icon(Icons.qr_code_rounded, size: 18, color: _kOlive),
            const SizedBox(width: 8),
            Text(l10n.scrambleExportGame),
          ]),
        ),
        PopupMenuItem(
          value: 'import',
          child: Row(children: [
            const Icon(Icons.qr_code_scanner_rounded, size: 18, color: _kOlive),
            const SizedBox(width: 8),
            Text(l10n.scrambleImportResult),
          ]),
        ),
        PopupMenuItem(
          value: 'score',
          child: Row(children: [
            const Icon(Icons.edit_rounded, size: 18, color: _kOlive),
            const SizedBox(width: 8),
            Text(l10n.scorecardManualScore),
          ]),
        ),
      ],
    );
  }

  void _exportMatch(KoMatch match) {
    final l10n = AppLocalizations.of(context)!;
    final team1 =
        match.team1Id != null ? _tournament.teamById(match.team1Id!) : null;
    final team2 =
        match.team2Id != null ? _tournament.teamById(match.team2Id!) : null;
    // Real bracket position, carried so the referee's imported scorecard shows
    // the true round instead of the mini-tournament's "Final · Match 1".
    final positionLabel =
        '${_roundLabel(match.round)} · ${l10n.bracketMatchNumber(match.matchIndex + 1)}';
    final data = KoBracketTransferService.encodeMatchExport(_tournament, match,
        positionLabel: positionLabel);
    showQrExportSheet(
      context,
      title: l10n.scrambleExportGame,
      subtitle: '${_roundLabel(match.round)} · '
          '${team1?.name ?? l10n.bracketTbd} vs ${team2?.name ?? l10n.bracketTbd}',
      data: data,
    );
  }

  Future<void> _importResult() async {
    final l10n = AppLocalizations.of(context)!;
    final raw = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => QrScanPage(hint: l10n.scrambleScanResultHint),
      ),
    );
    if (raw == null || !mounted) return;

    KoResultUpdate result;
    try {
      result = KoBracketTransferService.decodeResult(raw);
    } catch (_) {
      _showSnack(l10n.scrambleScanNotResult);
      return;
    }
    if (result.parentTournamentId.isNotEmpty &&
        result.parentTournamentId != _tournament.id) {
      _showSnack(l10n.scrambleResultMismatch);
      return;
    }
    final target = _tournament.matches.cast<KoMatch?>().firstWhere(
          (m) => m?.id == result.matchId,
          orElse: () => null,
        );
    if (target == null) {
      _showSnack(l10n.scrambleResultMismatch);
      return;
    }
    if (target.isComplete) {
      _showSnack(l10n.scrambleResultAlreadyRecorded);
      return;
    }
    final winnerId =
        result.winnerSide == 1 ? target.team2Id : target.team1Id;
    final updatedMatch = target.copyWith(
      sets: result.sets,
      winnerId: winnerId,
      status: KoMatchStatus.completed,
      startedAt: result.startedAt ?? target.startedAt,
      completedAt: result.completedAt ?? DateTime.now(),
      clearLiveScores: true,
    );
    _persist(KoBracketAdapter.applyMatchResult(
      _tournament,
      updatedMatch,
      propagateWinner: true,
    ));
    _showSnack(l10n.scrambleResultImported);
  }

  /// Manually enter a full set-by-set result for a not-yet-started match and
  /// complete it, without opening the scoreboard. Opened from the card's QR
  /// menu — the KO analogue of Social Scramble's manual-score dialog.
  Future<void> _showManualScoreDialog(KoMatch match, int round) async {
    final l10n = AppLocalizations.of(context)!;
    final fmt = _tournament.formatForRound(round);
    final team1 =
        match.team1Id != null ? _tournament.teamById(match.team1Id!) : null;
    final team2 =
        match.team2Id != null ? _tournament.teamById(match.team2Id!) : null;
    final ctrls1 = List.generate(fmt.setsPerGame, (_) => TextEditingController());
    final ctrls2 = List.generate(fmt.setsPerGame, (_) => TextEditingController());

    ({List<KoSet> sets, int w1, int w2}) tally() {
      final sets = <KoSet>[];
      var w1 = 0, w2 = 0;
      for (var i = 0; i < fmt.setsPerGame; i++) {
        final s1 = int.tryParse(ctrls1[i].text) ?? 0;
        final s2 = int.tryParse(ctrls2[i].text) ?? 0;
        if (s1 == 0 && s2 == 0) continue;
        sets.add(KoSet(score1: s1, score2: s2, isCompleted: true));
        if (s1 > s2) {
          w1++;
        } else if (s2 > s1) {
          w2++;
        }
      }
      return (sets: sets, w1: w1, w2: w2);
    }

    try {
      final confirmed = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => StatefulBuilder(
          builder: (ctx, setDialog) {
            final t = tally();
            final canSave = t.sets.isNotEmpty && t.w1 != t.w2;
            return AlertDialog(
              shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                    child: const Icon(Icons.edit_rounded,
                        color: _kOlive, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(l10n.scorecardManualScore,
                        style: const TextStyle(
                            fontSize: 17, fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 4),
                    Text(
                      l10n.scorecardManualScoreDescription,
                      style: const TextStyle(
                          fontSize: 13, color: Colors.black54, height: 1.5),
                    ),
                    const SizedBox(height: 8),
                    Row(children: [
                      Expanded(
                        child: Text(team1?.name ?? l10n.bracketTbd,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: _kGoldDark)),
                      ),
                      const SizedBox(width: 56),
                      Expanded(
                        child: Text(team2?.name ?? l10n.bracketTbd,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: _kOlive)),
                      ),
                    ]),
                    const SizedBox(height: 8),
                    for (var i = 0; i < fmt.setsPerGame; i++) ...[
                      _manualSetRow(i, ctrls1[i], ctrls2[i],
                          fmt.setsPerGame > 1 ? l10n.bracketManualSet(i + 1) : null,
                          () => setDialog(() {})),
                      const SizedBox(height: 8),
                    ],
                  ],
                ),
              ),
              actions: [
                Row(children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text(l10n.btnCancel),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _kOlive,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey.shade300,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed:
                          canSave ? () => Navigator.of(ctx).pop(true) : null,
                      child: Text(l10n.scorecardCompleteGame,
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                ]),
              ],
            );
          },
        ),
      );
      if (confirmed != true || !mounted) return;

      final t = tally();
      final winnerId = t.w1 > t.w2 ? match.team1Id : match.team2Id;
      final now = DateTime.now();
      final updatedMatch = match.copyWith(
        sets: t.sets,
        winnerId: winnerId,
        status: KoMatchStatus.completed,
        startedAt: match.startedAt ?? now,
        completedAt: now,
        clearLiveScores: true,
      );
      _persist(KoBracketAdapter.applyMatchResult(
        _tournament,
        updatedMatch,
        propagateWinner: true,
      ));
      _showSnack(l10n.overviewScoreSaved);
    } finally {
      // Delay disposal until the dialog's exit animation completes — pop()
      // resolves the Future immediately but the builder still references these.
      Future.delayed(const Duration(milliseconds: 300), () {
        for (final c in ctrls1) {
          c.dispose();
        }
        for (final c in ctrls2) {
          c.dispose();
        }
      });
    }
  }

  Widget _manualSetRow(int index, TextEditingController c1,
      TextEditingController c2, String? label, VoidCallback onChanged) {
    Widget field(TextEditingController c, Color color) => SizedBox(
          width: 56,
          child: TextField(
            controller: c,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            onChanged: (_) => onChanged(),
            decoration: InputDecoration(
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8)),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: color),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              isDense: true,
            ),
          ),
        );
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (label != null)
          SizedBox(
            width: 48,
            child: Text(label,
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.black45)),
          ),
        field(c1, _kGoldDark),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 10),
          child: Text('–', style: TextStyle(fontSize: 16, color: Colors.black38)),
        ),
        field(c2, _kOlive),
      ],
    );
  }

  // ── Match card ─────────────────────────────────────────────────────────────

  Widget _matchCard(KoMatch match, int round) {
    final l10n = AppLocalizations.of(context)!;
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

    // QR / manual-score menu — for any not-yet-started, playable match with
    // both opponents known (mirrors the Social Scramble game tile). Play-in and
    // repechage matches count too: they're preliminary matches that flip to
    // inProgress once started, so before that they still need the export menu.
    final showMenu = (match.status == KoMatchStatus.scheduled ||
            match.status == KoMatchStatus.playIn ||
            match.status == KoMatchStatus.repechage) &&
        match.startedAt == null &&
        team1 != null &&
        team2 != null;

    final statusColor = switch (match.status) {
      KoMatchStatus.completed  => _kOlive,
      KoMatchStatus.inProgress => _kGold,
      KoMatchStatus.walkover   => Colors.orange,
      KoMatchStatus.bye        => Colors.grey,
      _                        => Colors.black38,
    };
    final statusIcon = switch (match.status) {
      KoMatchStatus.completed  => Icons.check_circle_rounded,
      KoMatchStatus.inProgress => Icons.sports_volleyball_rounded,
      KoMatchStatus.walkover   => Icons.person_off_rounded,
      KoMatchStatus.bye        => Icons.do_not_disturb_alt_rounded,
      _                        => Icons.schedule_rounded,
    };

    // Left rail: court badge with the QR / manual-score menu centred beneath it
    // (the time is gone — it lives on the round header now).
    final hasCourt = match.courtAssignment != null;
    final leftItems = <Widget>[
      if (hasCourt)
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
              Text(
                  AppLocalizations.of(context)!
                      .matchCourtLabel(match.courtAssignment!)
                      .split(' ')
                      .first,
                  style: const TextStyle(
                      fontSize: 7, color: _kOlive, fontWeight: FontWeight.w400)),
              Text('${match.courtAssignment}',
                  style: const TextStyle(
                      fontSize: 16,
                      color: _kOlive,
                      fontWeight: FontWeight.w400,
                      height: 1)),
            ],
          ),
        ),
      if (showMenu) ...[
        if (hasCourt) const SizedBox(height: 6),
        SizedBox(width: 30, height: 30, child: _buildMatchMenu(match, round)),
      ],
    ];

    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      elevation: 0,
      color: Colors.white,
      // Match the Social Scramble game tile: the card stays white regardless of
      // status — the gold-ball status icon is the sole "in progress" cue, rather
      // than tinting the whole card gold.
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: canTap ? () => _openMatch(match) : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: 14, vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (leftItems.isNotEmpty) ...[
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: leftItems,
                ),
                const SizedBox(width: 12),
              ],
              // Teams (team name emphasized, players beneath).
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
                      team1,
                      _teamScore(match, isTeam1: true),
                      match.winnerId == match.team1Id && isComplete,
                      setPoints: _teamSetPoints(match, isTeam1: true),
                    ),
                    if (!isBye) ...[
                      const SizedBox(height: 4),
                      _teamRow(
                        team2,
                        _teamScore(match, isTeam1: false),
                        match.winnerId == match.team2Id && isComplete,
                        setPoints: _teamSetPoints(match, isTeam1: false),
                      ),
                    ],
                    if (!isBye && !isWalkover) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.gavel_rounded,
                              size: 9, color: Colors.blueGrey),
                          const SizedBox(width: 2),
                          Expanded(
                            child: Text(
                              match.refereeTeamId != null
                                  ? l10n.bracketRefs(_tournament
                                          .teamById(match.refereeTeamId!)
                                          ?.name ??
                                      '')
                                  : l10n.matchAssignRefereeManually,
                              style: const TextStyle(
                                  fontSize: 10, color: Colors.blueGrey),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          // Expanded above soaks up the slack so the format
                          // badge always sits flush right on the same line.
                          const SizedBox(width: 6),
                          _formatBadge(_tournament.formatForRound(round)),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              // Status icon — upper-right. Sized to match the Social Scramble
              // game tile (14) rather than the larger 18 used before.
              const SizedBox(width: 8),
              Icon(statusIcon, size: 14, color: statusColor),
            ],
          ),
        ),
      ),
    );
  }

  /// One side of a match card: team name emphasized, player names beneath —
  /// the inverse emphasis of the Social Scramble tile, per design.
  Widget _teamRow(KoTeam? team, String? score, bool isWinner,
      {String? setPoints}) {
    final l10n = AppLocalizations.of(context)!;
    final isTbd = team == null;
    final isWithdrawn = team?.isWithdrawn ?? false;
    final players = team?.players.map((p) => p.name).join(' · ') ?? '';
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isWinner)
          const Padding(
            padding: EdgeInsets.only(right: 4, top: 1),
            child: Icon(Icons.emoji_events_rounded,
                size: 12, color: _kGoldDark),
          ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                team?.name ?? l10n.bracketTbd,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isTbd
                      ? Colors.black26
                      : isWithdrawn
                          ? Colors.grey
                          : Colors.black87,
                  decoration:
                      isWithdrawn ? TextDecoration.lineThrough : null,
                ),
              ),
              if (players.isNotEmpty)
                Text(
                  players,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 10, color: Colors.black38),
                ),
            ],
          ),
        ),
        if (setPoints != null)
          Padding(
            padding: const EdgeInsets.only(left: 6, top: 3),
            child: Text(
              setPoints,
              style: const TextStyle(
                fontSize: 11,
                color: Colors.black38,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ),
        if (score != null)
          Padding(
            padding: const EdgeInsets.only(left: 6, top: 1),
            child: Text(
              score,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: isWinner ? _kGoldDark : Colors.black38,
              ),
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

  /// This team's points in each completed set, space-separated (e.g. "21 19 15"),
  /// shown inline beside the sets-won total for multi-set formats so the points
  /// per set are visible without a second line. Null for single-set formats
  /// (whose point score already IS the main number) or incomplete matches.
  String? _teamSetPoints(KoMatch match, {required bool isTeam1}) {
    if (!match.isComplete || match.sets.isEmpty) return null;
    final fmt = _tournament.formatForRound(match.round);
    if (fmt.setsPerGame == 1) return null;
    final completed = match.sets.where((s) => s.isCompleted);
    if (completed.isEmpty) return null;
    return completed
        .map((s) => isTeam1 ? '${s.score1}' : '${s.score2}')
        .join(' ');
  }

  Widget _statusTag(KoMatchStatus status) {
    final l10n = AppLocalizations.of(context)!;
    final (label, color) = switch (status) {
      KoMatchStatus.bye       => (l10n.bracketTagBye, Colors.grey),
      KoMatchStatus.walkover  => (l10n.bracketTagWalkover, Colors.orange),
      KoMatchStatus.playIn    => (l10n.bracketTagPlayIn, _kGold),
      KoMatchStatus.repechage => (l10n.bracketTagRepechage, Colors.deepOrange),
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

// ── Refreshable bottom sheet ───────────────────────────────────────────────────

/// A modal-sheet wrapper that hands the page a `refresh` callback while mounted,
/// so in-place mutations made from nested dialogs (edit/swap/withdraw a team,
/// edit the schedule) can redraw the open sheet instead of going stale. The
/// callback is registered on mount and cleared on dispose (synchronous with
/// unmount), so it never fires against a defunct element.
class _RefreshableSheet extends StatefulWidget {
  final void Function(VoidCallback refresh) onMount;
  final VoidCallback onUnmount;
  final WidgetBuilder builder;

  const _RefreshableSheet({
    required this.onMount,
    required this.onUnmount,
    required this.builder,
  });

  @override
  State<_RefreshableSheet> createState() => _RefreshableSheetState();
}

class _RefreshableSheetState extends State<_RefreshableSheet> {
  @override
  void initState() {
    super.initState();
    widget.onMount(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    widget.onUnmount();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context);
}
