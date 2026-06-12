import 'package:flutter/material.dart';
import '../app/app_colors.dart';
import '../services/king_of_the_court_storage_service.dart';
import '../services/scramble_storage_service.dart';
import '../state/app_state.dart';
import '../widgets/app_drawer.dart';
import '../widgets/tournaq_app_bar.dart';
import 'coming_soon_page.dart';
import 'king_of_the_court_hub_page.dart';
import 'scramble_hub_page.dart';
import 'tournament_history_page.dart';

class TournamentsPage extends StatefulWidget {
  final AppState appState;
  final Function(AppState) onAppStateChanged;

  const TournamentsPage({
    super.key,
    required this.appState,
    required this.onAppStateChanged,
  });

  @override
  State<TournamentsPage> createState() => _TournamentsPageState();
}

class _TournamentsPageState extends State<TournamentsPage> {
  late AppState _localState;
  int _scrambleCount = 0;
  int _kotcCount = 0;

  @override
  void initState() {
    super.initState();
    _localState = widget.appState;
    _scrambleCount = ScrambleStorageService.loadAll().length;
    _kotcCount = KingOfTheCourtStorageService.loadAll().length;
  }

  void _updateState(AppState s) {
    setState(() => _localState = s);
    widget.onAppStateChanged(s);
  }

  void _refreshCounts() {
    setState(() {
      _scrambleCount = ScrambleStorageService.loadAll().length;
      _kotcCount = KingOfTheCourtStorageService.loadAll().length;
    });
  }

  void _openScrambleHub() {
    Navigator.of(context)
        .push(MaterialPageRoute(
          builder: (_) => ScrambleHubPage(
            appState: _localState,
            onAppStateChanged: _updateState,
          ),
        ))
        .then((_) => _refreshCounts());
  }

  void _openKotcHub() {
    Navigator.of(context)
        .push(MaterialPageRoute(
          builder: (_) => KingOfTheCourtHubPage(
            appState: _localState,
            onAppStateChanged: _updateState,
          ),
        ))
        .then((_) => _refreshCounts());
  }

  void _openHistory({TournamentFilter filter = TournamentFilter.all}) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => TournamentHistoryPage(
        appState: _localState,
        onAppStateChanged: _updateState,
        initialFilter: filter,
      ),
    ));
  }

  void _openComingSoon(String title, String description) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) =>
          ComingSoonPage(title: title, shortDescription: description),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: AppDrawer(
          appState: _localState, onAppStateChanged: _updateState),
      appBar: const TournaQAppBar(title: 'Tournaments'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Single Competitions & Socials ──────────────────────────
            _sectionHeader('Single Competitions & Socials', Icons.people_rounded),
            const SizedBox(height: 12),
            Column(children: [
              _TypeTile(
                icon:        Icons.shuffle_rounded,
                color:       AppColors.gold,
                gradientEnd: AppColors.goldGradientEnd,
                name:        'Social Scramble',
                description: 'Timed round-robin mixer',
                count:       _scrambleCount,
                onTap:       _openScrambleHub,
              ),
              _TypeTile(
                icon:        Icons.workspace_premium_rounded,
                color:       AppColors.gold,
                gradientEnd: AppColors.goldGradientEnd,
                name:        'King of the Court',
                description: 'Winners stay, challengers rotate',
                count:       _kotcCount,
                onTap:       _openKotcHub,
              ),
              _TypeTile(
                icon:        Icons.pets_rounded,
                color:       const Color(0xFF795548),
                gradientEnd: const Color(0xFF4E342E),
                name:        'Doghouse',
                description: 'Losers bracket consolation',
                comingSoon:  true,
                onTap: () => _openComingSoon(
                    'Doghouse',
                    'A consolation bracket where eliminated '
                    'players keep competing for pride.'),
              ),
            ]),

            // ── Team Competitions ──────────────────────────────────────
            const SizedBox(height: 24),
            _sectionHeader('Team Competitions', Icons.groups_rounded),
            const SizedBox(height: 12),
            Column(children: [
              _TypeTile(
                icon:        Icons.table_chart_rounded,
                color:       AppColors.olive,
                gradientEnd: AppColors.oliveMedium,
                name:        'League',
                description: 'Points-based standings',
                comingSoon:  true,
                onTap: () => _openComingSoon(
                    'League / Round Robin',
                    'Track standings across a full round-robin '
                    'season with points, wins, and goal difference.'),
              ),
              _TypeTile(
                icon:        Icons.account_tree_rounded,
                color:       const Color(0xFF5C6BC0),
                gradientEnd: const Color(0xFF3949AB),
                name:        'Single Elimination',
                description: 'Classic knockout bracket',
                comingSoon:  true,
                onTap: () => _openComingSoon(
                    'Single Elimination',
                    'Classic knockout bracket — one loss and '
                    'you\'re out.'),
              ),
              _TypeTile(
                icon:        Icons.device_hub_rounded,
                color:       AppColors.tertiary,
                gradientEnd: const Color(0xFF6D4C2E),
                name:        'Double Elimination',
                description: 'Two-chance bracket',
                comingSoon:  true,
                onTap: () => _openComingSoon(
                    'Double Elimination',
                    'Winners and losers brackets — you need two '
                    'losses to be eliminated.'),
              ),
              _TypeTile(
                icon:        Icons.stacked_bar_chart_rounded,
                color:       const Color(0xFF00897B),
                gradientEnd: const Color(0xFF00695C),
                name:        'Group + SE',
                description: 'Group stage · Single Elimination',
                comingSoon:  true,
                onTap: () => _openComingSoon(
                    'Group + Single Elimination',
                    'Teams advance from a group stage into a '
                    'single-elimination knockout bracket.'),
              ),
              _TypeTile(
                icon:        Icons.stacked_line_chart_rounded,
                color:       const Color(0xFF6D4C41),
                gradientEnd: const Color(0xFF4E342E),
                name:        'Group + DE',
                description: 'Group stage · Double Elimination',
                comingSoon:  true,
                onTap: () => _openComingSoon(
                    'Group + Double Elimination',
                    'Teams advance from a group stage into a '
                    'double-elimination bracket.'),
              ),
              _TypeTile(
                icon:        Icons.swap_vert_rounded,
                color:       const Color(0xFF00897B),
                gradientEnd: const Color(0xFF00695C),
                name:        'Swiss System',
                description: 'Paired rounds by score',
                comingSoon:  true,
                onTap: () => _openComingSoon(
                    'Swiss System',
                    'Players are paired each round based on their '
                    'current score — no eliminations, full schedule.'),
              ),
            ]),

            // ── History shortcut ───────────────────────────────────────
            const SizedBox(height: 28),
            _sectionHeader('History', Icons.history_rounded),
            const SizedBox(height: 12),
            _HistoryShortcutTile(
              label:   'All Tournaments',
              count:   _scrambleCount + _kotcCount,
              onTap:   _openHistory,
            ),
            const SizedBox(height: 6),
            _HistoryShortcutTile(
              label:     'Social Scramble',
              count:     _scrambleCount,
              typeColor: AppColors.gold,
              typeIcon:  Icons.shuffle_rounded,
              onTap: () => _openHistory(filter: TournamentFilter.scramble),
            ),
            const SizedBox(height: 6),
            _HistoryShortcutTile(
              label:     'King of the Court',
              count:     _kotcCount,
              typeColor: AppColors.gold,
              typeIcon:  Icons.workspace_premium_rounded,
              onTap: () => _openHistory(filter: TournamentFilter.kingOfTheCourt),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title, IconData icon) => Row(
        children: [
          Icon(icon, size: 15, color: AppColors.olive),
          const SizedBox(width: 6),
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.olive,
              letterSpacing: 0.4,
            ),
          ),
        ],
      );
}

// ── Type tile ─────────────────────────────────────────────────────────────────

class _TypeTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color gradientEnd;
  final String name;
  final String description;
  final int count;
  final bool comingSoon;
  final VoidCallback onTap;

  const _TypeTile({
    required this.icon,
    required this.color,
    required this.gradientEnd,
    required this.name,
    required this.description,
    required this.onTap,
    this.count = 0,
    this.comingSoon = false,
  });

  @override
  Widget build(BuildContext context) {
    final gradientColors = comingSoon
        ? [Colors.grey.shade400, Colors.grey.shade600]
        : [color, gradientEnd];
    final shadowColor = comingSoon ? Colors.grey : color;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: shadowColor.withValues(alpha: 0.28),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.1,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    description,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.80),
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (comingSoon)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.20),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Soon',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              )
            else if (count > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.20),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$count',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              )
            else
              const Icon(Icons.chevron_right_rounded,
                  color: Colors.white, size: 24),
          ],
        ),
      ),
    );
  }
}

// ── History shortcut tile ─────────────────────────────────────────────────────

class _HistoryShortcutTile extends StatelessWidget {
  final String label;
  final int count;
  final Color? typeColor;
  final IconData? typeIcon;
  final VoidCallback onTap;

  const _HistoryShortcutTile({
    required this.label,
    required this.count,
    required this.onTap,
    this.typeColor,
    this.typeIcon,
  });

  @override
  Widget build(BuildContext context) {
    final color = typeColor ?? AppColors.olive;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade200),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(typeIcon ?? Icons.history_rounded, size: 18, color: color),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (count > 0)
              Text(
                '$count',
                style: TextStyle(
                    fontSize: 13,
                    color: color,
                    fontWeight: FontWeight.w700),
              ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right_rounded,
                size: 18, color: Colors.black26),
          ],
        ),
      ),
    );
  }
}
