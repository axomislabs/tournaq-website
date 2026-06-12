import 'package:flutter/material.dart';
import '../app/app_colors.dart';
import '../models/ko_bracket_tournament.dart';
import '../services/ko_bracket_storage_service.dart';
import '../state/app_state.dart';
import '../widgets/tournaq_app_bar.dart';
import 'ko_bracket_bracket_page.dart';
import 'ko_bracket_setup_page.dart';

const _kGold = AppColors.gold;
const _kGoldDark = AppColors.goldDark;
const _kGoldCream = AppColors.goldCream;
const _kOlive = AppColors.olive;

class KoBracketHubPage extends StatefulWidget {
  final AppState appState;
  final Function(AppState) onAppStateChanged;

  const KoBracketHubPage({
    super.key,
    required this.appState,
    required this.onAppStateChanged,
  });

  @override
  State<KoBracketHubPage> createState() => _KoBracketHubPageState();
}

class _KoBracketHubPageState extends State<KoBracketHubPage> {
  late AppState _appState;
  List<KoBracketTournament> _tournaments = [];

  @override
  void initState() {
    super.initState();
    _appState = widget.appState;
    _loadTournaments();
  }

  void _loadTournaments() {
    setState(() => _tournaments = KoBracketStorageService.loadAll());
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
        appState: _appState,
        onCreated: _persist,
      ),
    )).then((_) => _loadTournaments());
  }

  void _openTournament(KoBracketTournament t) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => KoBracketBracketPage(
        tournament: t,
        appState: _appState,
        onChanged: _persist,
      ),
    )).then((_) => _loadTournaments());
  }

  Future<void> _deleteTournament(KoBracketTournament t) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Tournament?',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        content: Text(
          'This will permanently delete "${t.name}". This cannot be undone.',
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
    if (confirmed == true) {
      await KoBracketStorageService.delete(t.id);
      _loadTournaments();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const TournaQAppBar(
        title: 'Single Elimination',
        subtitle: 'KO Bracket',
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openSetup,
        backgroundColor: _kGold,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Tournament', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: _tournaments.isEmpty
          ? _buildEmpty()
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
              itemCount: _tournaments.length,
              itemBuilder: (_, i) => _buildCard(_tournaments[i]),
            ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: _kGoldCream,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.goldBadgeBorder, width: 2),
            ),
            child: const Icon(Icons.account_tree_rounded, size: 36, color: _kGold),
          ),
          const SizedBox(height: 20),
          const Text(
            'No tournaments yet',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tap the button below to create\nyour first KO bracket.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.black45),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(KoBracketTournament t) {
    final isComplete = t.status == KoBracketStatus.completed;
    final inProgress = t.status == KoBracketStatus.inProgress;
    final completedMatches = t.matches.where((m) => m.isComplete).length;
    final totalMatches = t.matches.length;

    // Winner from final match
    KoTeam? winner;
    if (isComplete) {
      final finalMatch = t.matches
          .where((m) => m.round == t.mainRoundCount && m.isComplete)
          .firstOrNull;
      if (finalMatch?.winnerId != null) {
        winner = t.teamById(finalMatch!.winnerId!);
      }
    }

    return GestureDetector(
      onTap: () => _openTournament(t),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isComplete
                ? [_kGold, _kGoldDark]
                : [Colors.white, Colors.grey.shade50],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isComplete ? _kGoldDark : Colors.grey.shade200,
            width: isComplete ? 0 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: (isComplete ? _kGold : Colors.black).withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Expanded(
                child: Text(
                  t.name,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: isComplete ? Colors.white : Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              _statusBadge(t.status),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => _deleteTournament(t),
                child: Icon(
                  Icons.delete_outline_rounded,
                  size: 18,
                  color: isComplete ? Colors.white70 : Colors.black26,
                ),
              ),
            ]),
            const SizedBox(height: 8),

            // Winner row
            if (isComplete && winner != null) ...[
              Row(children: [
                const Icon(Icons.emoji_events_rounded, size: 14, color: Colors.white),
                const SizedBox(width: 6),
                Text(
                  winner.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ]),
              const SizedBox(height: 8),
            ],

            // Info chips
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _infoChip(Icons.groups_rounded, '${t.teamCount} teams', isComplete),
                _infoChip(Icons.sports_tennis_rounded, '${t.courtCount} court(s)', isComplete),
                _infoChip(
                  Icons.bar_chart_rounded,
                  '$completedMatches / $totalMatches matches',
                  isComplete,
                ),
                if (inProgress)
                  _infoChip(Icons.play_arrow_rounded, 'In Progress', false, highlight: true),
                _infoChip(
                  t.generationMode == KoBracketGenerationMode.seeded
                      ? Icons.leaderboard_rounded
                      : Icons.shuffle_rounded,
                  t.generationMode == KoBracketGenerationMode.seeded ? 'Seeded' : 'Random',
                  isComplete,
                ),
              ],
            ),

            // Progress bar
            if (!isComplete && totalMatches > 0) ...[
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: completedMatches / totalMatches,
                  backgroundColor: Colors.grey.shade200,
                  color: _kGold,
                  minHeight: 4,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _statusBadge(KoBracketStatus status) {
    final text = switch (status) {
      KoBracketStatus.setup => 'Setup',
      KoBracketStatus.inProgress => 'Live',
      KoBracketStatus.completed => 'Done',
    };
    final bgColor = switch (status) {
      KoBracketStatus.setup => Colors.grey.shade200,
      KoBracketStatus.inProgress => _kGoldCream,
      KoBracketStatus.completed => Colors.white24,
    };
    final fgColor = switch (status) {
      KoBracketStatus.setup => Colors.black54,
      KoBracketStatus.inProgress => _kGoldDark,
      KoBracketStatus.completed => Colors.white,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(text,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: fgColor)),
    );
  }

  Widget _infoChip(IconData icon, String label, bool onGold, {bool highlight = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: onGold
            ? Colors.white.withValues(alpha: 0.2)
            : highlight
                ? _kGoldCream
                : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(6),
        border: highlight ? Border.all(color: AppColors.goldBadgeBorder) : null,
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 11, color: onGold ? Colors.white : highlight ? _kGoldDark : _kOlive),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: onGold ? Colors.white : highlight ? _kGoldDark : Colors.black54,
          ),
        ),
      ]),
    );
  }
}
