import 'package:flutter/material.dart';
import '../app/app_colors.dart';
import '../l10n/app_localizations.dart';
import '../models/doghouse_drill.dart';
import '../models/player.dart';
import '../services/doghouse_storage_service.dart';
import '../widgets/tournament_history_card.dart';
import '../widgets/tournaq_app_bar.dart';
import 'doghouse_scoreboard_page.dart';
import 'doghouse_setup_page.dart';

class DoghouseHubPage extends StatefulWidget {
  final List<Player> existingPlayers;

  const DoghouseHubPage({
    super.key,
    required this.existingPlayers,
  });

  @override
  State<DoghouseHubPage> createState() => _DoghouseHubPageState();
}

class _DoghouseHubPageState extends State<DoghouseHubPage> {
  List<DoghouseTournament> _tournaments = [];

  @override
  void initState() {
    super.initState();
    _loadTournaments();
  }

  void _loadTournaments() {
    setState(() => _tournaments = DoghouseStorageService.loadAll());
  }

  void _persist(DoghouseTournament t) {
    DoghouseStorageService.save(t);
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
      builder: (_) => DoghouseSetupPage(
        existingPlayers: widget.existingPlayers,
        onCreated: _persist,
      ),
    ));
  }

  void _openScoreboard(DoghouseTournament t) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => DoghouseScoreboardPage(
        tournament: t,
        existingPlayers: widget.existingPlayers,
        onChanged:  _persist,
      ),
    ));
  }

  Future<void> _deleteOne(DoghouseTournament t) async {
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
      await DoghouseStorageService.delete(t.id);
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
        await DoghouseStorageService.delete(t.id);
      }
      setState(() => _tournaments.clear());
    }
  }

  String _statusLabel(AppLocalizations l10n, DoghouseTournament t) =>
      switch (t.status) {
        DoghouseTournamentStatus.completed  => l10n.statusCompleted,
        DoghouseTournamentStatus.inProgress => l10n.statusInProgress,
        DoghouseTournamentStatus.setup      => l10n.statusSetup,
      };

  String _dateLabel(AppLocalizations l10n, DoghouseTournament t) {
    final dt   = t.createdAt;
    final now  = DateTime.now();
    final diff = DateTime(now.year, now.month, now.day)
        .difference(DateTime(dt.year, dt.month, dt.day))
        .inDays;
    if (diff == 0) return l10n.dateToday;
    if (diff == 1) return l10n.dateYesterday;
    if (diff < 7)  return l10n.dateDaysAgo(diff);
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: TournaQAppBar(title: l10n.doghouseTitle),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: _buildStartCard(l10n),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Icon(Icons.history_rounded,
                    size: 20, color: AppColors.oliveMedium),
                const SizedBox(width: 8),
                Text(
                  l10n.doghouseTournamentHistory(_tournaments.length),
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w800),
                ),
                const Spacer(),
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
          const SizedBox(height: 8),
          Expanded(
            child: _tournaments.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.pets_rounded,
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
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                    itemCount: _tournaments.length,
                    itemBuilder: (_, i) {
                      final t = _tournaments[i];
                      return TournamentHistoryCard(
                        name:        t.name,
                        typeLabel:   l10n.doghouseTitle,
                        typeColor:   AppColors.gold,
                        typeIcon:    Icons.pets_rounded,
                        dateLabel:   _dateLabel(l10n, t),
                        statusLabel: _statusLabel(l10n, t),
                        isActive:    t.status != DoghouseTournamentStatus.completed,
                        stats: [
                          l10n.doghouseStatsPlayers(t.playerCount),
                          l10n.doghouseStatsGames(t.gameCount),
                          l10n.doghouseStatsEscapes(t.totalEscapes),
                        ],
                        onTap:       () => _openScoreboard(t),
                        onDeleteTap: () => _deleteOne(t),
                      );
                    },
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
              const Icon(Icons.pets_rounded, color: Colors.white, size: 22),
              const SizedBox(width: 8),
              Text(
                l10n.doghouseTitle,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800),
              ),
            ],
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
