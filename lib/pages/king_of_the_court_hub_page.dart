import 'package:flutter/material.dart';
import '../app/app_colors.dart';
import '../models/king_of_the_court_tournament.dart';
import '../models/player.dart';
import '../services/king_of_the_court_storage_service.dart';
import '../widgets/tournament_history_card.dart';
import '../widgets/tournaq_app_bar.dart';
import 'king_of_the_court_scoreboard_page.dart';
import 'king_of_the_court_setup_page.dart';

class KingOfTheCourtHubPage extends StatefulWidget {
  final List<Player> existingPlayers;

  const KingOfTheCourtHubPage({
    super.key,
    required this.existingPlayers,
  });

  @override
  State<KingOfTheCourtHubPage> createState() => _KingOfTheCourtHubPageState();
}

class _KingOfTheCourtHubPageState extends State<KingOfTheCourtHubPage> {
  List<KingOfTheCourtTournament> _tournaments = [];

  @override
  void initState() {
    super.initState();
    _loadTournaments();
  }

  void _loadTournaments() {
    setState(() => _tournaments = KingOfTheCourtStorageService.loadAll());
  }

  void _persist(KingOfTheCourtTournament s) {
    KingOfTheCourtStorageService.save(s);
    setState(() {
      final idx = _tournaments.indexWhere((e) => e.id == s.id);
      if (idx >= 0) {
        _tournaments = List.from(_tournaments)..[idx] = s;
      } else {
        _tournaments = [s, ..._tournaments];
      }
    });
  }

  void _openSetup() {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => KingOfTheCourtSetupPage(
        existingPlayers: widget.existingPlayers,
        onCreated: _persist,
      ),
    ));
  }

  void _openScoreboard(KingOfTheCourtTournament s) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => KingOfTheCourtScoreboardPage(
        tournament: s,
        existingPlayers: widget.existingPlayers,
        onChanged:  _persist,
      ),
    ));
  }

  Future<void> _deleteOne(KingOfTheCourtTournament s) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Tournament?',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        content: Text(
          'This will permanently delete "${s.name}" and all its data.',
          style: const TextStyle(fontSize: 14, color: Colors.black54),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      await KingOfTheCourtStorageService.delete(s.id);
      setState(() => _tournaments.removeWhere((e) => e.id == s.id));
    }
  }

  Future<void> _deleteAll() async {
    if (_tournaments.isEmpty) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete All Tournaments?',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        content: Text(
          'This will permanently delete all ${_tournaments.length} tournament${_tournaments.length > 1 ? 's' : ''}.',
          style: const TextStyle(fontSize: 14, color: Colors.black54),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      for (final s in _tournaments) {
        await KingOfTheCourtStorageService.delete(s.id);
      }
      setState(() => _tournaments.clear());
    }
  }

  static String _statusLabel(KingOfTheCourtTournament s) => switch (s.status) {
        KotcTournamentStatus.completed  => 'Completed',
        KotcTournamentStatus.inProgress => 'In Progress',
        KotcTournamentStatus.setup      => 'Setup',
      };

  static String _dateLabel(KingOfTheCourtTournament s) {
    final d    = s.createdAt;
    final now  = DateTime.now();
    final diff = DateTime(now.year, now.month, now.day)
        .difference(DateTime(d.year, d.month, d.day))
        .inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    if (diff < 7)  return '$diff days ago';
    return '${d.day}/${d.month}/${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const TournaQAppBar(title: 'King of the Court'),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: _buildStartCard(),
          ),
          const SizedBox(height: 20),
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
          Expanded(
            child: _tournaments.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.workspace_premium_rounded,
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
                      final s = _tournaments[i];
                      return TournamentHistoryCard(
                        name:        s.name,
                        typeLabel:   'King of the Court',
                        typeColor:   AppColors.gold,
                        typeIcon:    Icons.workspace_premium_rounded,
                        dateLabel:   _dateLabel(s),
                        statusLabel: _statusLabel(s),
                        isActive:    s.status != KotcTournamentStatus.completed,
                        stats: [
                          '${s.playerCount} players',
                          '${s.gameCount} games',
                          '${s.totalPoints} pts scored',
                        ],
                        onTap:       () => _openScoreboard(s),
                        onDeleteTap: () => _deleteOne(s),
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
              Icon(Icons.workspace_premium_rounded,
                  color: Colors.white, size: 22),
              SizedBox(width: 8),
              Text(
                'King of the Court',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            'Winners stay, challengers rotate',
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
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}
