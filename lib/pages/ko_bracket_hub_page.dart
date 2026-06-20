import 'package:flutter/material.dart';
import '../app/app_colors.dart';
import '../models/ko_bracket_tournament.dart';
import '../models/player.dart';
import '../models/team.dart';
import '../services/ko_bracket_storage_service.dart';
import '../widgets/tournament_history_card.dart';
import '../widgets/tournaq_app_bar.dart';
import 'ko_bracket_bracket_page.dart';
import 'ko_bracket_setup_page.dart';

class KoBracketHubPage extends StatefulWidget {
  final List<Player> existingPlayers;
  final List<Team> existingTeams;
  final Player Function(String name) onCreatePlayer;
  final String Function(String name, List<String> linkedPlayerIds) onCreateTeam;

  const KoBracketHubPage({
    super.key,
    required this.existingPlayers,
    required this.existingTeams,
    required this.onCreatePlayer,
    required this.onCreateTeam,
  });

  @override
  State<KoBracketHubPage> createState() => _KoBracketHubPageState();
}

class _KoBracketHubPageState extends State<KoBracketHubPage> {
  List<KoBracketTournament> _tournaments = [];

  @override
  void initState() {
    super.initState();
    _loadTournaments();
  }

  void _loadTournaments() {
    final all = KoBracketStorageService.loadAll();
    all.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    setState(() => _tournaments = all);
  }

  void _persist(KoBracketTournament t) {
    KoBracketStorageService.save(t);
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
      builder: (_) => KoBracketSetupPage(
        existingPlayers: widget.existingPlayers,
        existingTeams: widget.existingTeams,
        onCreatePlayer: widget.onCreatePlayer,
        onCreateTeam: widget.onCreateTeam,
        onCreated: _persist,
      ),
    )).then((_) => _loadTournaments());
  }

  void _openTournament(KoBracketTournament t) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => KoBracketBracketPage(
        tournament: t,
        onChanged: _persist,
        existingPlayers: widget.existingPlayers,
        existingTeams: widget.existingTeams,
        onCreatePlayer: widget.onCreatePlayer,
        onCreateTeam: widget.onCreateTeam,
      ),
    )).then((_) => _loadTournaments());
  }

  Future<void> _deleteOne(KoBracketTournament t) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Tournament?',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        content: Text(
          'This will permanently delete "${t.name}" and all its data.',
          style: const TextStyle(fontSize: 14, color: Colors.black54),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      await KoBracketStorageService.delete(t.id);
      setState(() => _tournaments.removeWhere((e) => e.id == t.id));
    }
  }

  Future<void> _deleteAll() async {
    if (_tournaments.isEmpty) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete All Tournaments?',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        content: Text(
          'This will permanently delete all ${_tournaments.length} '
          'Single Elimination tournament${_tournaments.length > 1 ? 's' : ''}.',
          style: const TextStyle(fontSize: 14, color: Colors.black54),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      for (final t in _tournaments) {
        await KoBracketStorageService.delete(t.id);
      }
      setState(() => _tournaments.clear());
    }
  }

  // ── Label helpers ─────────────────────────────────────────────────────────

  static String _statusLabel(KoBracketTournament t) => switch (t.status) {
        KoBracketStatus.completed  => 'Completed',
        KoBracketStatus.inProgress => 'In Progress',
        KoBracketStatus.setup      => 'Setup',
      };

  static String _dateLabel(KoBracketTournament t) {
    final d    = t.createdAt;
    final now  = DateTime.now();
    final diff = DateTime(now.year, now.month, now.day)
        .difference(DateTime(d.year, d.month, d.day))
        .inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    if (diff < 7)  return '$diff days ago';
    return '${d.day}/${d.month}/${d.year}';
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const TournaQAppBar(title: 'Single Elimination'),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Start card ───────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: _buildStartCard(),
          ),
          const SizedBox(height: 20),

          // ── History header ───────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Icon(Icons.history_rounded,
                    size: 20, color: AppColors.oliveMedium),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Tournament History (${_tournaments.length})',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                ),
                if (_tournaments.isNotEmpty)
                  TextButton.icon(
                    onPressed: _deleteAll,
                    icon: const Icon(Icons.delete_outline, size: 16),
                    label: const Text('Delete All',
                        style: TextStyle(fontSize: 12)),
                    style: TextButton.styleFrom(
                        foregroundColor: Colors.red.shade400),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // ── Tournament list ──────────────────────────────────────────
          Expanded(
            child: _tournaments.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.account_tree_rounded,
                            size: 48, color: Colors.grey.shade300),
                        const SizedBox(height: 12),
                        const Text('No tournaments yet.',
                            style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                                color: Colors.black45)),
                        const SizedBox(height: 4),
                        const Text('Tap New Tournament to get started.',
                            style: TextStyle(
                                color: Colors.black38, fontSize: 13)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                    itemCount: _tournaments.length,
                    itemBuilder: (_, i) {
                      final t = _tournaments[i];
                      final completed =
                          t.matches.where((m) => m.isComplete).length;
                      final total = t.matches.length;

                      // Winner name for completed tournaments
                      String? winnerName;
                      if (t.status == KoBracketStatus.completed) {
                        final finalMatch = t.matches
                            .where((m) =>
                                m.round == t.mainRoundCount &&
                                m.isComplete)
                            .firstOrNull;
                        if (finalMatch?.winnerId != null) {
                          winnerName =
                              t.teamById(finalMatch!.winnerId!)?.name;
                        }
                      }

                      return TournamentHistoryCard(
                        name:        t.name,
                        typeLabel:   'Single Elimination',
                        typeColor:   AppColors.gold,
                        typeIcon:    Icons.account_tree_rounded,
                        dateLabel:   _dateLabel(t),
                        statusLabel: _statusLabel(t),
                        isActive:
                            t.status != KoBracketStatus.completed,
                        stats: [
                          '${t.teamCount} teams',
                          '${t.courtCount} court${t.courtCount == 1 ? '' : 's'}',
                          '$completed / $total matches',
                          if (winnerName != null) '🏆 $winnerName',
                        ],
                        onTap:       () => _openTournament(t),
                        onDeleteTap: () => _deleteOne(t),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStartCard() {
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
              Icon(Icons.account_tree_rounded,
                  color: Colors.white, size: 22),
              SizedBox(width: 8),
              Text(
                'Single Elimination',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            'Classic KO bracket — one loss and you\'re out',
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.90),
                fontSize: 13,
                fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _openSetup,
            icon: const Icon(Icons.add_rounded),
            label: const Text('New Tournament',
                style: TextStyle(fontWeight: FontWeight.w700)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.gold,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}
