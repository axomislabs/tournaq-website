import 'package:flutter/material.dart';
import '../app/app_colors.dart';
import '../l10n/app_localizations.dart';
import '../models/group.dart';
import '../models/scramble_tournament.dart';
import '../models/player.dart';
import '../services/scramble_storage_service.dart';
import '../widgets/tournament_history_card.dart';
import '../widgets/tournaq_app_bar.dart';
import 'scramble_overview_page.dart';
import 'scramble_setup_page.dart';

class ScrambleHubPage extends StatefulWidget {
  final List<Player> existingPlayers;
  final List<Group> existingGroups;
  final Player Function(String name) onCreatePlayer;
  final void Function(String playerId, String newName)? onUpdatePlayer;

  const ScrambleHubPage({
    super.key,
    required this.existingPlayers,
    required this.existingGroups,
    required this.onCreatePlayer,
    this.onUpdatePlayer,
  });

  @override
  State<ScrambleHubPage> createState() => _ScrambleHubPageState();
}

class _ScrambleHubPageState extends State<ScrambleHubPage> {
  List<ScrambleTournament> _scrambles = [];

  @override
  void initState() {
    super.initState();
    _loadScrambles();
  }

  void _loadScrambles() {
    final all = ScrambleStorageService.loadAll();
    all.sort((a, b) => b.startTime.compareTo(a.startTime));
    setState(() => _scrambles = all);
  }

  void _persist(ScrambleTournament t) {
    ScrambleStorageService.save(t);
    setState(() {
      final idx = _scrambles.indexWhere((s) => s.id == t.id);
      if (idx >= 0) {
        _scrambles = List.from(_scrambles)..[idx] = t;
      } else {
        _scrambles = [t, ..._scrambles];
      }
    });
  }

  void _openSetup() {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ScrambleSetupPage(
        existingPlayers: widget.existingPlayers,
        existingGroups: widget.existingGroups,
        onCreated: _persist,
        onCreatePlayer: widget.onCreatePlayer,
      ),
    ));
  }

  void _openOverview(ScrambleTournament t) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ScrambleOverviewPage(
        tournament:     t,
        onChanged:      _persist,
        onCreatePlayer: widget.onCreatePlayer,
        onUpdatePlayer: widget.onUpdatePlayer,
      ),
    ));
  }

  Future<void> _deleteOne(ScrambleTournament t) async {
    final l10n = AppLocalizations.of(context)!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(l10n.doghouseDeleteTournamentTitle,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        content: Text(
          l10n.doghouseDeleteTournamentBody(t.name),
          style: const TextStyle(fontSize: 14, color: Colors.black54),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.btnCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(l10n.btnDelete),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      await ScrambleStorageService.delete(t.id);
      setState(() => _scrambles.removeWhere((s) => s.id == t.id));
    }
  }

  Future<void> _deleteAll() async {
    if (_scrambles.isEmpty) return;
    final l10n = AppLocalizations.of(context)!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(l10n.doghouseDeleteAllTitle,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        content: Text(
          l10n.doghouseDeleteAllBody(_scrambles.length),
          style: const TextStyle(fontSize: 14, color: Colors.black54),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.btnCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(l10n.btnDeleteAll),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      for (final t in _scrambles) {
        await ScrambleStorageService.delete(t.id);
      }
      setState(() => _scrambles.clear());
    }
  }

  // ── Card adapter ──────────────────────────────────────────────────────────

  String _statusLabel(AppLocalizations l10n, ScrambleTournament t) =>
      switch (t.status) {
        ScrambleTournamentStatus.completed  => l10n.statusCompleted,
        ScrambleTournamentStatus.inProgress => l10n.statusInProgress,
        ScrambleTournamentStatus.setup      => l10n.statusSetup,
      };

  String _dateLabel(AppLocalizations l10n, ScrambleTournament t) {
    final d    = t.startTime;
    final now  = DateTime.now();
    final diff = DateTime(now.year, now.month, now.day)
        .difference(DateTime(d.year, d.month, d.day))
        .inDays;
    if (diff == 0) return l10n.dateToday;
    if (diff == 1) return l10n.dateYesterday;
    if (diff < 7)  return l10n.dateDaysAgo(diff);
    return '${d.day}/${d.month}/${d.year}';
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: const TournaQAppBar(title: 'Social Scrambles'),
      body: CustomScrollView(
        slivers: [
          // ── Start card ───────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: _buildStartCard(l10n),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 20)),

          // ── History header ───────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Icon(Icons.history_rounded,
                      size: 20, color: AppColors.oliveMedium),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.doghouseTournamentHistory(_scrambles.length),
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w800),
                    ),
                  ),
                  if (_scrambles.isNotEmpty)
                    TextButton.icon(
                      onPressed: _deleteAll,
                      icon: const Icon(Icons.delete_outline, size: 16),
                      label: Text(l10n.btnDeleteAll,
                          style: const TextStyle(fontSize: 12)),
                      style: TextButton.styleFrom(
                          foregroundColor: Colors.red.shade400),
                    ),
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 8)),

          // ── Tournament list ──────────────────────────────────────────
          if (_scrambles.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.shuffle_rounded,
                        size: 48, color: Colors.grey.shade300),
                    const SizedBox(height: 12),
                    Text(l10n.doghouseNoTournamentsYet,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: Colors.black45)),
                    const SizedBox(height: 4),
                    Text(l10n.doghouseNoTournamentsHint,
                        style: const TextStyle(
                            color: Colors.black38, fontSize: 13)),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) {
                    final t = _scrambles[i];
                    return TournamentHistoryCard(
                      name:        t.name,
                      typeLabel:   'Social Scrambles',
                      typeColor:   AppColors.gold,
                      typeIcon:    Icons.shuffle_rounded,
                      dateLabel:   _dateLabel(l10n, t),
                      statusLabel: _statusLabel(l10n, t),
                      isActive:
                          t.status != ScrambleTournamentStatus.completed,
                      stats: [
                        l10n.doghouseStatsPlayers(t.playerCount),
                        l10n.statsRounds(t.roundCount),
                        l10n.statsGamesOf(t.completedGames, t.totalGames),
                      ],
                      onTap:       () => _openOverview(t),
                      onDeleteTap: () => _deleteOne(t),
                    );
                  },
                  childCount: _scrambles.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStartCard(AppLocalizations l10n) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.gold, AppColors.goldGradientEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.gold.withValues(alpha: 0.28),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.shuffle_rounded, color: Colors.white, size: 22),
              SizedBox(width: 8),
              Text(
                'Social Scrambles',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            l10n.modeSocialScramblesDesc,
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.90),
                fontSize: 13,
                fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _openSetup,
            icon: const Icon(Icons.add_rounded),
            label: Text(l10n.doghouseNewTournament,
                style: const TextStyle(fontWeight: FontWeight.w700)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.gold,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}
