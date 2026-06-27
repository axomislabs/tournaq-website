import 'package:flutter/material.dart';
import '../app/app_colors.dart';
import '../l10n/app_localizations.dart';
import '../models/player.dart';
import '../models/player_status.dart';
import '../models/scramble_tournament.dart';
import '../widgets/player_picker_sheet.dart';
import '../widgets/tournament_player_row.dart';
import '../services/local_storage_service.dart';
import '../services/scramble_service.dart';
import '../services/scramble_storage_service.dart';
import '../widgets/scramble_game_tile.dart';
import '../widgets/scrollable_page.dart';
import '../widgets/sheet_helpers.dart';
import '../widgets/tournaq_app_bar.dart';
import 'scramble_scorecard_page.dart';
import 'scramble_stats_page.dart';

class ScrambleOverviewPage extends StatefulWidget {
  final ScrambleTournament tournament;
  final void Function(ScrambleTournament) onChanged;
  final Player Function(String name)? onCreatePlayer;
  final void Function(String playerId, String newName)? onUpdatePlayer;

  const ScrambleOverviewPage({
    super.key,
    required this.tournament,
    required this.onChanged,
    this.onCreatePlayer,
    this.onUpdatePlayer,
  });

  @override
  State<ScrambleOverviewPage> createState() => _ScrambleOverviewPageState();
}

class _ScrambleOverviewPageState extends State<ScrambleOverviewPage> {
  late ScrambleTournament _t;
  bool _playersExpanded = false;

  @override
  void initState() {
    super.initState();
    _t = widget.tournament;
  }

  void _update(ScrambleTournament updated) {
    setState(() => _t = updated);
    ScrambleStorageService.save(updated);
    widget.onChanged(updated);
  }

  Future<void> _openScorecard(ScrambleGame game) async {
    final round = _t.getRound(game.roundId);
    if (round == null) return;
    final updated = await Navigator.of(context).push<ScrambleTournament>(
      MaterialPageRoute(
        builder: (_) => ScrambleScorecardPage(
          tournament: _t,
          game: game,
          round: round,
          onChanged: _update,
        ),
      ),
    );
    if (updated != null) _update(updated);
  }

  void _openStats() {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ScrambleStatsPage(tournament: _t),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final l10n      = AppLocalizations.of(context)!;
    final completed = _t.completedGames;
    final total     = _t.totalGames;
    final progress  = _t.progressFraction;

    return Scaffold(
      appBar: TournaQAppBar(
        title: 'Social Scramble',
        subtitle: _t.name,
        actions: [
          IconButton(
            icon: const Icon(Icons.leaderboard_rounded,
                color: AppColors.goldLight),
            tooltip: l10n.tooltipRankings,
            onPressed: _openStats,
          ),
        ],
      ),
      body: ScrollablePage(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _sectionDivider(l10n.overviewSectionOverview, Icons.bar_chart_rounded),
            const SizedBox(height: 10),
            _buildHeader(l10n, completed, total, progress),
            const SizedBox(height: 20),
            _buildPlayersSection(l10n),
            const SizedBox(height: 20),
            _sectionDivider(l10n.overviewSectionSchedule, Icons.event_note_rounded),
            const SizedBox(height: 10),
            ..._buildRoundSections(l10n),
          ],
        ),
      ),
    );
  }

  // ── Section divider ───────────────────────────────────────────────────────

  Widget _sectionDivider(String label, IconData icon,
      {bool collapsible = false, bool expanded = false,
      VoidCallback? onToggle}) {
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
          ],
        ),
      ),
    );
  }

  // ── Overview header ───────────────────────────────────────────────────────

  Widget _buildHeader(AppLocalizations l10n, int completed, int total, double progress) {
    final lastRound = _t.rounds.isNotEmpty ? _t.rounds.last : null;
    final estFinish =
        lastRound?.actualEndTime ?? lastRound?.scheduledBreakEndTime;
    final finished = lastRound?.actualEndTime != null &&
        _t.games.isNotEmpty &&
        _t.games.every((g) => g.isCompleted);

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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.overviewGamesCompleted(completed, total),
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 15),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.overviewStatsSummary(
                          _t.roundCount, _t.courtCount, _t.playerCount),
                      style: const TextStyle(
                          fontSize: 12, color: Colors.black54),
                    ),
                    if (estFinish != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        finished
                            ? l10n.overviewFinished(
                                ScrambleService.formatTime(estFinish))
                            : l10n.overviewEstFinish(
                                ScrambleService.formatTime(estFinish)),
                        style: const TextStyle(
                            fontSize: 12, color: Colors.black54),
                      ),
                    ],
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
                  const AlwaysStoppedAnimation(AppColors.olive),
            ),
          ),
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
            valueColor:
                const AlwaysStoppedAnimation(AppColors.olive),
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

  // ── Players section ───────────────────────────────────────────────────────

  Widget _buildPlayersSection(AppLocalizations l10n) {
    final isLive = _t.rounds.isNotEmpty &&
        _t.status != ScrambleTournamentStatus.completed;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sectionDivider(
          l10n.overviewSectionPlayers(_t.players.length),
          Icons.group_rounded,
          collapsible: true,
          expanded: _playersExpanded,
          onToggle: () =>
              setState(() => _playersExpanded = !_playersExpanded),
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
      label: Text(l10n.menuAddPlayer,
          style: const TextStyle(fontWeight: FontWeight.w600)),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.olive,
        side: BorderSide(color: AppColors.olive.withValues(alpha: 0.4)),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10)),
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      ),
    );
  }

  // ── Add Player sheet ──────────────────────────────────────────────────────

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
        final globalPlayer = widget.onCreatePlayer?.call(name);
        final newPlayer = ScramblePlayer(
          id:        ScramblePlayer.generateId(),
          name:      name,
          source:    globalPlayer != null
              ? ScramblePlayerSource.existing
              : ScramblePlayerSource.created,
          appUserId: globalPlayer?.id,
          status:    PlayerStatus.late,
        );
        _update(ScrambleService.rebuildRemainingRounds(
            _t, [..._t.players, newPlayer]));
        return true;
      },
      onPickExisting: (appUserId, name) async {
        final ok = await _confirmReshuffle(
          l10n.overviewAddConfirm(name),
          l10n.overviewAddLateBody(name),
          confirmLabel: l10n.menuAddPlayer,
        );
        if (ok != true) return false;
        final newPlayer = ScramblePlayer(
          id:        ScramblePlayer.generateId(),
          name:      name,
          source:    ScramblePlayerSource.existing,
          appUserId: appUserId,
          status:    PlayerStatus.late,
        );
        _update(ScrambleService.rebuildRemainingRounds(
            _t, [..._t.players, newPlayer]));
        return true;
      },
    );
  }

  // ── Swap sheet ────────────────────────────────────────────────────────────

  void _showSwapSheet(ScramblePlayer outgoing) {
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
    required ScramblePlayer outgoing,
    required String name,
    String? appUserId,
  }) {
    final swappedOut =
        outgoing.copyWith(status: PlayerStatus.swappedOut);
    final globalPlayer = appUserId != null
        ? null  // id already known; appUserId is the link
        : widget.onCreatePlayer?.call(name);
    final swappedIn = ScramblePlayer(
      id:        ScramblePlayer.generateId(),
      name:      name,
      source:    globalPlayer != null
          ? ScramblePlayerSource.existing
          : ScramblePlayerSource.created,
      appUserId: globalPlayer?.id ?? appUserId,
      status:    PlayerStatus.swappedIn,
    );
    final newPlayers = [
      ..._t.players.map((p) => p.id == outgoing.id ? swappedOut : p),
      swappedIn,
    ];
    _update(ScrambleService.rebuildRemainingRounds(_t, newPlayers));
  }

  // ── Edit player sheet ─────────────────────────────────────────────────────

  void _showEditPlayerSheet(ScramblePlayer player) {
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
                      players: _t.players
                          .map((p) => p.id == player.id ? p.copyWith(name: name) : p)
                          .toList(),
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
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black54)),
              const SizedBox(height: 6),
              TextField(
                controller: nameCtrl,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                onSubmitted: (_) {
                  final name = nameCtrl.text.trim();
                  if (name.isEmpty) return;
                  _update(_t.copyWith(
                    players: _t.players
                        .map((p) => p.id == player.id ? p.copyWith(name: name) : p)
                        .toList(),
                  ));
                  if (player.appUserId != null) {
                    widget.onUpdatePlayer?.call(player.appUserId!, name);
                  }
                  Navigator.of(ctx).pop();
                },
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

  // ── Generic player picker sheet ───────────────────────────────────────────

  void _showPlayerPickerSheet({
    required String title,
    required String subtitle,
    required Future<bool> Function(String name) onPickName,
    required Future<bool> Function(String appUserId, String name) onPickExisting,
  }) {
    final alreadyIn  = _t.players
        .map((p) => p.appUserId)
        .whereType<String>()
        .toSet();
    final appState    = LocalStorageService.loadAppState();
    final allExisting = appState.players;
    final allGroups   = appState.groups;

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

  // ── Player table ──────────────────────────────────────────────────────────

  Widget _buildPlayerTable(AppLocalizations l10n, bool isLive) {
    final stats     = ScrambleService.computeStats(_t);
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
          statsLine: (s != null && p.isActive)
              ? '${s.gamesPlayed}g · ${s.totalPoints}pts'
              : null,
          onEdit: () => _showEditPlayerSheet(p),
          onEject: isLive ? () => _confirmEject(p) : null,
          onSwap: isLive ? () => _showSwapSheet(p) : null,
          showDisabledActions: false,
        );
      }).toList(),
    );
  }

  // ── Eject ─────────────────────────────────────────────────────────────────

  Future<bool?> _confirmReshuffle(
    String title,
    String body, {
    required String confirmLabel,
    Color confirmColor = AppColors.olive,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title,
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.w700)),
        content: Text(body,
            style: const TextStyle(
                fontSize: 14, color: Colors.black54, height: 1.5)),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(AppLocalizations.of(context)!.btnCancel)),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: confirmColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(confirmLabel,
                style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  void _confirmEject(ScramblePlayer player) async {
    final l10n = AppLocalizations.of(context)!;
    final ok = await _confirmReshuffle(
      l10n.overviewEjectTitle(player.name),
      l10n.overviewEjectBody(player.name),
      confirmLabel: l10n.overviewEjectBtn,
      confirmColor: Colors.red,
    );
    if (ok != true || !mounted) return;
    final ejected =
        player.copyWith(status: PlayerStatus.ejected);
    final newPlayers = _t.players
        .map((p) => p.id == player.id ? ejected : p)
        .toList();
    _update(ScrambleService.rebuildRemainingRounds(_t, newPlayers));
  }

  // ── Rounds / Schedule ─────────────────────────────────────────────────────

  List<Widget> _buildRoundSections(AppLocalizations l10n) {
    return _t.rounds.map((round) {
      final games  = _t.getGamesForRound(round.id);
      final allDone = games.isNotEmpty && games.every((g) => g.isCompleted);

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _roundHeader(l10n, round, allDone, games),
          const SizedBox(height: 6),
          ...games.map((g) => ScrambleGameTile(
                game:       g,
                round:      round,
                tournament: _t,
                onTap:      () => _openScorecard(g),
              )),
          const SizedBox(height: 16),
        ],
      );
    }).toList();
  }

  Widget _roundHeader(
      AppLocalizations l10n, ScrambleRound round, bool allDone, List<ScrambleGame> games) {
    final DateTime? actualStart = allDone
        ? games
            .where((g) => g.actualStartTime != null)
            .map((g) => g.actualStartTime!)
            .fold<DateTime?>(
                null, (a, b) => a == null || b.isBefore(a) ? b : a)
        : null;
    final actualEnd  = round.actualEndTime;
    final showActual = allDone && actualEnd != null;

    return Row(
      children: [
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: allDone ? AppColors.olive : AppColors.goldCream,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            l10n.overviewRound(round.roundNumber),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color:
                  allDone ? Colors.white : AppColors.goldDark,
            ),
          ),
        ),
        const SizedBox(width: 8),
        if (showActual) ...[
          Text(
            actualStart != null
                ? '${ScrambleService.formatTime(actualStart)} – '
                    '${ScrambleService.formatTime(actualEnd)}'
                : ScrambleService.formatTime(actualEnd),
            style: const TextStyle(
                fontSize: 12, color: Colors.black45),
          ),
          const SizedBox(width: 4),
          Text(
            l10n.overviewActual,
            style: const TextStyle(fontSize: 10, color: Colors.black38),
          ),
        ] else ...[
          Text(
            '${ScrambleService.formatTime(round.scheduledStartTime)} – '
            '${ScrambleService.formatTime(round.scheduledMatchEndTime)}',
            style: const TextStyle(
                fontSize: 12, color: Colors.black45),
          ),
          if (round.breakDuration > Duration.zero) ...[
            const SizedBox(width: 4),
            Text(
              l10n.overviewBreakUntil(
                  ScrambleService.formatTime(round.scheduledBreakEndTime)),
              style: const TextStyle(
                  fontSize: 11, color: Colors.black38),
            ),
          ],
        ],
      ],
    );
  }
}
