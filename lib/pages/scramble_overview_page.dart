import 'package:flutter/material.dart';
import '../app/app_colors.dart';
import '../models/player.dart';
import '../models/scramble_tournament.dart';
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
            tooltip: 'Player Rankings',
            onPressed: _openStats,
          ),
        ],
      ),
      body: ScrollablePage(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _sectionDivider('Overview', Icons.bar_chart_rounded),
            const SizedBox(height: 10),
            _buildHeader(completed, total, progress),
            const SizedBox(height: 20),
            _buildPlayersSection(),
            const SizedBox(height: 20),
            _sectionDivider('Schedule', Icons.event_note_rounded),
            const SizedBox(height: 10),
            ..._buildRoundSections(),
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

  Widget _buildHeader(int completed, int total, double progress) {
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
                      '$completed / $total games completed',
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 15),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${_t.roundCount} rounds  ·  '
                      '${_t.courtCount} court${_t.courtCount > 1 ? 's' : ''}  ·  '
                      '${_t.playerCount} players',
                      style: const TextStyle(
                          fontSize: 12, color: Colors.black54),
                    ),
                    if (estFinish != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        '${finished ? 'Finished' : 'Est. finish'}: '
                        '${ScrambleService.formatTime(estFinish)}',
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

  Widget _buildPlayersSection() {
    final isLive = _t.rounds.isNotEmpty &&
        _t.status != ScrambleTournamentStatus.completed;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sectionDivider(
          'Players (${_t.players.length})',
          Icons.group_rounded,
          collapsible: true,
          expanded: _playersExpanded,
          onToggle: () =>
              setState(() => _playersExpanded = !_playersExpanded),
        ),
        if (_playersExpanded) ...[
          const SizedBox(height: 10),
          if (isLive) ...[
            _buildAddPlayerButton(),
            const SizedBox(height: 8),
          ],
          _buildPlayerTable(isLive),
        ],
      ],
    );
  }

  Widget _buildAddPlayerButton() {
    return OutlinedButton.icon(
      onPressed: _showAddPlayerSheet,
      icon: const Icon(Icons.person_add_rounded, size: 16),
      label: const Text('Add Player',
          style: TextStyle(fontWeight: FontWeight.w600)),
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
    _showPlayerPickerSheet(
      title: 'Add Player',
      subtitle: 'Added players join as a late entry.',
      onPickName: (name) async {
        final ok = await _confirmReshuffle(
          'Add $name?',
          '$name will join as a late entry. Remaining pairings will be '
          'reshuffled — some players may end up with an unequal number of games.',
          confirmLabel: 'Add Player',
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
          status:    ScramblePlayerStatus.late,
        );
        _update(ScrambleService.rebuildRemainingRounds(
            _t, [..._t.players, newPlayer]));
        return true;
      },
      onPickExisting: (appUserId, name) async {
        final ok = await _confirmReshuffle(
          'Add $name?',
          '$name will join as a late entry. Remaining pairings will be '
          'reshuffled — some players may end up with an unequal number of games.',
          confirmLabel: 'Add Player',
        );
        if (ok != true) return false;
        final newPlayer = ScramblePlayer(
          id:        ScramblePlayer.generateId(),
          name:      name,
          source:    ScramblePlayerSource.existing,
          appUserId: appUserId,
          status:    ScramblePlayerStatus.late,
        );
        _update(ScrambleService.rebuildRemainingRounds(
            _t, [..._t.players, newPlayer]));
        return true;
      },
    );
  }

  // ── Swap sheet ────────────────────────────────────────────────────────────

  void _showSwapSheet(ScramblePlayer outgoing) {
    _showPlayerPickerSheet(
      title: 'Swap out ${outgoing.name}',
      subtitle: '${outgoing.name} will be removed from upcoming rounds.',
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
        outgoing.copyWith(status: ScramblePlayerStatus.swappedOut);
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
      status:    ScramblePlayerStatus.swappedIn,
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
                const Expanded(
                  child: Text('Edit Player',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
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
                  child: const Text('Save', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ]),
              const SizedBox(height: 16),
              const Text('Name',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black54)),
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
    final nameCtrl   = TextEditingController();
    final searchCtrl = TextEditingController();
    var createOpen   = true;
    var existingOpen = false;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) {
          final alreadyIn = _t.players
              .map((p) => p.appUserId)
              .whereType<String>()
              .toSet();
          final query       = searchCtrl.text.toLowerCase();
          final allExisting = LocalStorageService.loadAppState().players
              .where((p) => !alreadyIn.contains(p.id))
              .toList();
          final filtered   = query.isEmpty
              ? allExisting
              : allExisting
                  .where((p) =>
                      p.name.toLowerCase().contains(query))
                  .toList();

          Widget sectionHeader(
              String label, bool open, VoidCallback onToggle) {
            return InkWell(
              onTap: onToggle,
              borderRadius: BorderRadius.circular(6),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        label,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Icon(
                      open
                          ? Icons.expand_less_rounded
                          : Icons.expand_more_rounded,
                      size: 18,
                      color: Colors.black45,
                    ),
                  ],
                ),
              ),
            );
          }

          return TournaQSheet(
            body: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: const TextStyle(
                          fontSize: 12, color: Colors.black45)),
                  const SizedBox(height: 16),

                  // ── Create Player ────────────────────────────────────
                  sectionHeader(
                    'Create Player',
                    createOpen,
                    () => setSheet(() => createOpen = !createOpen),
                  ),
                  if (createOpen) ...[
                    const SizedBox(height: 8),
                    Row(children: [
                      Expanded(
                        child: TextField(
                          controller: nameCtrl,
                          autofocus: true,
                          textCapitalization: TextCapitalization.words,
                          decoration: InputDecoration(
                            hintText: 'Player name',
                            isDense: true,
                            border: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(10)),
                            contentPadding:
                                const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 12),
                          ),
                          onSubmitted: (v) async {
                            final name = v.trim();
                            if (name.isEmpty) return;
                            if (await onPickName(name) && ctx.mounted) {
                              Navigator.of(ctx).pop();
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () async {
                          final name = nameCtrl.text.trim();
                          if (name.isEmpty) return;
                          if (await onPickName(name) && ctx.mounted) {
                            Navigator.of(ctx).pop();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.olive,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 14),
                        ),
                        child: const Text('Add'),
                      ),
                    ]),
                    const SizedBox(height: 12),
                  ],

                  const Divider(height: 1),
                  const SizedBox(height: 4),

                  // ── Existing Players ─────────────────────────────────
                  sectionHeader(
                    'Add Existing Players (${allExisting.length})',
                    existingOpen,
                    () =>
                        setSheet(() => existingOpen = !existingOpen),
                  ),
                  if (existingOpen) ...[
                    const SizedBox(height: 6),
                    if (allExisting.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          'All existing players are already in this tournament.',
                          style: TextStyle(
                              fontSize: 13, color: Colors.black38),
                        ),
                      )
                    else ...[
                      TextField(
                        controller: searchCtrl,
                        onChanged: (_) => setSheet(() {}),
                        decoration: InputDecoration(
                          hintText: 'Search players…',
                          isDense: true,
                          prefixIcon: const Icon(Icons.search_rounded,
                              size: 18, color: Colors.black45),
                          border: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(10)),
                          contentPadding:
                              const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                        ),
                      ),
                      const SizedBox(height: 6),
                      if (filtered.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Text('No players match.',
                              style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.black38)),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics:
                              const NeverScrollableScrollPhysics(),
                          itemCount: filtered.length,
                          separatorBuilder: (_, _) =>
                              const Divider(height: 1),
                          itemBuilder: (_, i) {
                            final p = filtered[i];
                            return ListTile(
                              dense: true,
                              contentPadding:
                                  const EdgeInsets.symmetric(
                                      horizontal: 4),
                              leading: CircleAvatar(
                                radius: 14,
                                backgroundColor:
                                    AppColors.oliveLight,
                                child: Text(
                                  p.name.isNotEmpty
                                      ? p.name[0].toUpperCase()
                                      : '?',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.olive,
                                  ),
                                ),
                              ),
                              title: Text(p.name,
                                  style: const TextStyle(
                                      fontSize: 13)),
                              trailing: IconButton(
                                icon: const Icon(
                                    Icons.add_circle_outline_rounded,
                                    size: 20,
                                    color: AppColors.olive),
                                onPressed: () async {
                                  if (await onPickExisting(p.id, p.name) &&
                                      ctx.mounted) {
                                    Navigator.of(ctx).pop();
                                  }
                                },
                                padding: EdgeInsets.zero,
                                constraints:
                                    const BoxConstraints(),
                              ),
                            );
                          },
                        ),
                    ],
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Player table ──────────────────────────────────────────────────────────

  Widget _buildPlayerTable(bool isLive) {
    final stats     = ScrambleService.computeStats(_t);
    final statsById = {for (final s in stats) s.playerId: s};
    if (_t.players.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Text('No players added yet.',
            style: TextStyle(fontSize: 13, color: Colors.black38)),
      );
    }
    return Column(
      children: _t.players
          .map((p) => _buildPlayerRow(p, statsById[p.id], isLive))
          .toList(),
    );
  }

  Widget _buildPlayerRow(ScramblePlayer p, dynamic s, bool isLive) {
    final inactive = !p.isActive;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor:
                inactive ? Colors.grey.shade100 : AppColors.oliveLight,
            child: Text(
              p.name.isNotEmpty ? p.name[0].toUpperCase() : '?',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: inactive
                    ? Colors.grey.shade400
                    : AppColors.olive,
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
                        p.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color:
                              inactive ? Colors.grey.shade500 : null,
                          decoration: inactive
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                    ),
                    if (p.status != ScramblePlayerStatus.active) ...[
                      const SizedBox(width: 6),
                      _statusChip(p.status),
                    ],
                  ],
                ),
                if (s != null && !inactive)
                  Text(
                    '${s.gamesPlayed}g · ${s.totalPoints}pts',
                    style: const TextStyle(
                        fontSize: 10, color: Colors.black38),
                  ),
              ],
            ),
          ),
          if (!inactive) ...[
            _actionBtn(
              icon: Icons.edit_rounded,
              color: Colors.black38,
              tooltip: 'Edit',
              onTap: () => _showEditPlayerSheet(p),
            ),
            if (isLive) ...[
              _actionBtn(
                icon: Icons.person_off_rounded,
                color: Colors.red.shade400,
                tooltip: 'Eject',
                onTap: () => _confirmEject(p),
              ),
              _actionBtn(
                icon: Icons.swap_horiz_rounded,
                color: Colors.orange.shade700,
                tooltip: 'Swap',
                onTap: () => _showSwapSheet(p),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _actionBtn({
    required IconData icon,
    required Color color,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, size: 18, color: color),
        ),
      ),
    );
  }

  Widget _statusChip(ScramblePlayerStatus status) {
    final label = _playerStatusLabel(status);
    final color = _playerStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  String _playerStatusLabel(ScramblePlayerStatus s) => switch (s) {
        ScramblePlayerStatus.ejected    => 'ejected',
        ScramblePlayerStatus.swappedOut => 'swapped out',
        ScramblePlayerStatus.swappedIn  => 'sub in',
        ScramblePlayerStatus.late       => 'late',
        ScramblePlayerStatus.active     => '',
      };

  Color _playerStatusColor(ScramblePlayerStatus s) => switch (s) {
        ScramblePlayerStatus.ejected    => Colors.red.shade400,
        ScramblePlayerStatus.swappedOut => Colors.orange.shade600,
        ScramblePlayerStatus.swappedIn  => AppColors.olive,
        ScramblePlayerStatus.late       => Colors.blue.shade400,
        ScramblePlayerStatus.active     => Colors.transparent,
      };

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
              child: const Text('Cancel')),
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
    final ok = await _confirmReshuffle(
      'Eject ${player.name}?',
      '${player.name} will be removed from all upcoming rounds. '
      'Remaining pairings will be reshuffled — some players may end up '
      'with an unequal number of games. '
      'Completed games remain in the stats.',
      confirmLabel: 'Eject',
      confirmColor: Colors.red,
    );
    if (ok != true || !mounted) return;
    final ejected =
        player.copyWith(status: ScramblePlayerStatus.ejected);
    final newPlayers = _t.players
        .map((p) => p.id == player.id ? ejected : p)
        .toList();
    _update(ScrambleService.rebuildRemainingRounds(_t, newPlayers));
  }

  // ── Rounds / Schedule ─────────────────────────────────────────────────────

  List<Widget> _buildRoundSections() {
    return _t.rounds.map((round) {
      final games  = _t.getGamesForRound(round.id);
      final allDone = games.isNotEmpty && games.every((g) => g.isCompleted);

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _roundHeader(round, allDone, games),
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
      ScrambleRound round, bool allDone, List<ScrambleGame> games) {
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
            'Round ${round.roundNumber}',
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
          const Text(
            'actual',
            style: TextStyle(fontSize: 10, color: Colors.black38),
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
              '· Break until '
              '${ScrambleService.formatTime(round.scheduledBreakEndTime)}',
              style: const TextStyle(
                  fontSize: 11, color: Colors.black38),
            ),
          ],
        ],
      ],
    );
  }
}
