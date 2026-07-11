import 'package:flutter/material.dart';
import '../app/app_colors.dart';
import '../l10n/app_localizations.dart';
import '../models/scramble_king_tournament.dart';
import '../models/group.dart';
import '../models/player.dart';
import '../services/scramble_king_storage_service.dart';
import '../widgets/tournament_history_card.dart';
import '../widgets/tournaq_app_bar.dart';
import 'scramble_king_overview_page.dart';
import 'scramble_king_setup_page.dart';

class ScrambleKingHubPage extends StatefulWidget {
  final List<Player> existingPlayers;
  final List<Group> existingGroups;
  final Player Function(String name) onCreatePlayer;

  const ScrambleKingHubPage({
    super.key,
    required this.existingPlayers,
    required this.existingGroups,
    required this.onCreatePlayer,
  });

  @override
  State<ScrambleKingHubPage> createState() => _ScrambleKingHubPageState();
}

class _ScrambleKingHubPageState extends State<ScrambleKingHubPage> {
  List<ScrambleKingTournament> _tournaments = [];

  @override
  void initState() {
    super.initState();
    _loadTournaments();
  }

  void _loadTournaments() {
    setState(() => _tournaments = ScrambleKingStorageService.loadAll());
  }

  void _persist(ScrambleKingTournament t) {
    ScrambleKingStorageService.save(t);
    setState(() {
      final idx = _tournaments.indexWhere((e) => e.id == t.id);
      if (idx >= 0) {
        _tournaments = List.from(_tournaments)..[idx] = t;
      } else {
        _tournaments = [t, ..._tournaments];
      }
    });
  }

  void _openSetup() {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ScrambleKingSetupPage(
        existingPlayers: widget.existingPlayers,
        existingGroups: widget.existingGroups,
        onCreated: _persist,
        onCreatePlayer: widget.onCreatePlayer,
      ),
    ));
  }

  void _openOverview(ScrambleKingTournament t) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ScrambleKingOverviewPage(
        tournament: t,
        existingPlayers: widget.existingPlayers,
        existingGroups: widget.existingGroups,
        onChanged: _persist,
        onCreatePlayer: widget.onCreatePlayer,
      ),
    ));
  }

  Future<void> _deleteOne(ScrambleKingTournament t) async {
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
              child: Text(l10n.btnCancel)),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(l10n.btnDelete),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      await ScrambleKingStorageService.delete(t.id);
      setState(() => _tournaments.removeWhere((e) => e.id == t.id));
    }
  }

  Future<void> _deleteAll() async {
    if (_tournaments.isEmpty) return;
    final l10n = AppLocalizations.of(context)!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(l10n.doghouseDeleteAllTitle,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        content: Text(
          l10n.doghouseDeleteAllBody(_tournaments.length),
          style: const TextStyle(fontSize: 14, color: Colors.black54),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(l10n.btnCancel)),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(l10n.btnDeleteAll),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      for (final t in _tournaments) {
        await ScrambleKingStorageService.delete(t.id);
      }
      setState(() => _tournaments.clear());
    }
  }

  String _statusLabel(AppLocalizations l10n, ScrambleKingTournament t) =>
      switch (t.status) {
        ScrambleKingTournamentStatus.completed => l10n.statusCompleted,
        ScrambleKingTournamentStatus.inProgress => l10n.statusInProgress,
        ScrambleKingTournamentStatus.setup => l10n.statusSetup,
      };

  String _dateLabel(AppLocalizations l10n, ScrambleKingTournament t) {
    final d = t.createdAt;
    final now = DateTime.now();
    final diff = DateTime(now.year, now.month, now.day)
        .difference(DateTime(d.year, d.month, d.day))
        .inDays;
    if (diff == 0) return l10n.dateToday;
    if (diff == 1) return l10n.dateYesterday;
    if (diff < 7) return l10n.dateDaysAgo(diff);
    return '${d.day}/${d.month}/${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: TournaQAppBar(title: l10n.modeScrambleKingName),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: _buildStartCard(l10n),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 20)),
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
                      l10n.doghouseTournamentHistory(_tournaments.length),
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w800),
                    ),
                  ),
                  if (_tournaments.isNotEmpty)
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
          if (_tournaments.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.military_tech_rounded,
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
                    final t = _tournaments[i];
                    return TournamentHistoryCard(
                      name: t.name,
                      typeLabel: l10n.modeScrambleKingName,
                      typeColor: AppColors.gold,
                      typeIcon: Icons.military_tech_rounded,
                      dateLabel: _dateLabel(l10n, t),
                      statusLabel: _statusLabel(l10n, t),
                      isActive: t.status != ScrambleKingTournamentStatus.completed,
                      stats: [
                        l10n.doghouseStatsPlayers(t.playerCount),
                        l10n.scrambleKingStatsRounds(t.completedRounds, t.roundCount),
                      ],
                      onTap: () => _openOverview(t),
                      onDeleteTap: () => _deleteOne(t),
                    );
                  },
                  childCount: _tournaments.length,
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
          Row(
            children: [
              const Icon(Icons.military_tech_rounded,
                  color: Colors.white, size: 22),
              const SizedBox(width: 8),
              Text(
                l10n.modeScrambleKingName,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            l10n.modeScrambleKingDesc,
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
