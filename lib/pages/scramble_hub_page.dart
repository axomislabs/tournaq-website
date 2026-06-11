import 'package:flutter/material.dart';
import '../app/app_colors.dart';
import '../models/scramble_tournament.dart';
import '../services/scramble_storage_service.dart';
import '../state/app_state.dart';
import '../widgets/tournament_history_card.dart';
import '../widgets/tournaq_app_bar.dart';
import 'scramble_overview_page.dart';
import 'scramble_setup_page.dart';

class ScrambleHubPage extends StatefulWidget {
  final AppState appState;
  final Function(AppState) onAppStateChanged;

  const ScrambleHubPage({
    super.key,
    required this.appState,
    required this.onAppStateChanged,
  });

  @override
  State<ScrambleHubPage> createState() => _ScrambleHubPageState();
}

class _ScrambleHubPageState extends State<ScrambleHubPage> {
  late AppState _appState;
  List<ScrambleTournament> _scrambles = [];

  @override
  void initState() {
    super.initState();
    _appState = widget.appState;
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
        appState: _appState,
        onCreated: _persist,
      ),
    ));
  }

  void _openOverview(ScrambleTournament t) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ScrambleOverviewPage(
        tournament: t,
        onChanged: _persist,
      ),
    ));
  }

  Future<void> _deleteOne(ScrambleTournament t) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
      await ScrambleStorageService.delete(t.id);
      setState(() => _scrambles.removeWhere((s) => s.id == t.id));
    }
  }

  Future<void> _deleteAll() async {
    if (_scrambles.isEmpty) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete All Tournaments?',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        content: Text(
          'This will permanently delete all ${_scrambles.length} Social Scramble tournament${_scrambles.length > 1 ? 's' : ''}.',
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
      for (final t in _scrambles) {
        await ScrambleStorageService.delete(t.id);
      }
      setState(() => _scrambles.clear());
    }
  }

  // ── Card adapter ──────────────────────────────────────────────────────────

  static String _statusLabel(ScrambleTournament t) => switch (t.status) {
        ScrambleTournamentStatus.completed  => 'Completed',
        ScrambleTournamentStatus.inProgress => 'In Progress',
        ScrambleTournamentStatus.setup      => 'Setup',
      };

  static String _dateLabel(ScrambleTournament t) {
    final d    = t.startTime;
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
      appBar: const TournaQAppBar(title: 'Social Scramble'),
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
                Text(
                  'Tournament History (${_scrambles.length})',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w800),
                ),
                const Spacer(),
                if (_scrambles.isNotEmpty)
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
            child: _scrambles.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.shuffle_rounded,
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
                    itemCount: _scrambles.length,
                    itemBuilder: (_, i) {
                      final t = _scrambles[i];
                      return TournamentHistoryCard(
                        name:        t.name,
                        typeLabel:   'Social Scramble',
                        typeColor:   AppColors.gold,
                        typeIcon:    Icons.shuffle_rounded,
                        dateLabel:   _dateLabel(t),
                        statusLabel: _statusLabel(t),
                        isActive:
                            t.status != ScrambleTournamentStatus.completed,
                        stats: [
                          '${t.playerCount} players',
                          '${t.roundCount} rounds',
                          '${t.completedGames}/${t.totalGames} games',
                        ],
                        onTap:       () => _openOverview(t),
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
              Icon(Icons.shuffle_rounded, color: Colors.white, size: 22),
              SizedBox(width: 8),
              Text(
                'Social Scramble',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            'Timed round-robin for any group size',
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
