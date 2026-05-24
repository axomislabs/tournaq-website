import 'package:flutter/material.dart';
import '../state/app_state.dart';
import '../widgets/app_drawer.dart';
import '../widgets/scrollable_page.dart';
import 'teams_page.dart';
import 'tournaments_page.dart';
import 'games_page.dart';

class LandingPage extends StatelessWidget {
  final AppState appState;
  final Function(AppState) onAppStateChanged;

  const LandingPage({
    super.key,
    required this.appState,
    required this.onAppStateChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: AppDrawer(
        appState: appState,
        onAppStateChanged: onAppStateChanged,
      ),
      appBar: AppBar(
        title: const Text('TournaQ'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: ScrollablePage(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHero(context),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildStatsCard(context),
                  const SizedBox(height: 24),
                  _buildQuickActionsSection(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHero(BuildContext context) {
    return Stack(
      children: [
        SizedBox(
          height: 220,
          width: double.infinity,
          child: Image.asset(
            'assets/tournaq_background.png',
            fit: BoxFit.cover,
          ),
        ),
        Container(
          height: 220,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFF6E7640).withValues(alpha: 0.80),
                const Color(0xFF4A5028).withValues(alpha: 0.92),
              ],
            ),
          ),
        ),
        Positioned.fill(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Image.asset(
                  'assets/tournaq_logo.png',
                  height: 44,
                  fit: BoxFit.contain,
                  alignment: Alignment.centerLeft,
                ),
                const SizedBox(height: 12),
                const Text(
                  'TournaQ',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                    height: 1.0,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Scoring, Games & Tournament Management',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.82),
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsCard(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: const Color(0xFF6E7640).withValues(alpha: 0.18)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem(
              label: 'Teams',
              value: appState.teams.length.toString(),
              icon: Icons.group_rounded,
            ),
            _buildDivider(),
            _buildStatItem(
              label: 'Tournaments',
              value: appState.tournaments.length.toString(),
              icon: Icons.emoji_events_rounded,
            ),
            _buildDivider(),
            _buildStatItem(
              label: 'Games',
              value: appState.games.length.toString(),
              icon: Icons.sports_basketball_rounded,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() => Container(
    height: 36,
    width: 1,
    color: const Color(0xFF6E7640).withValues(alpha: 0.15),
  );

  Widget _buildStatItem({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Column(
      children: [
        Icon(icon, size: 20, color: const Color(0xFF6E7640)),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: Color(0xFF6E7640),
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Colors.black45,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.black87),
        ),
        const SizedBox(height: 12),
        _buildActionButton(
          context,
          label: 'Manage Teams',
          icon: Icons.group_rounded,
          page: TeamsPage(appState: appState, onAppStateChanged: onAppStateChanged),
        ),
        const SizedBox(height: 10),
        _buildActionButton(
          context,
          label: 'View Tournaments',
          icon: Icons.emoji_events_rounded,
          page: TournamentsPage(appState: appState, onAppStateChanged: onAppStateChanged),
        ),
        const SizedBox(height: 10),
        _buildActionButton(
          context,
          label: 'View Games',
          icon: Icons.sports_basketball_rounded,
          page: GamesPage(appState: appState, onAppStateChanged: onAppStateChanged),
        ),
      ],
    );
  }

  Widget _buildActionButton(BuildContext context, {
    required String label,
    required IconData icon,
    required Widget page,
  }) {
    return OutlinedButton.icon(
      onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => page)),
      icon: Icon(icon, size: 18),
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF6E7640),
        side: const BorderSide(color: Color(0xFF6E7640), width: 1.5),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        alignment: Alignment.centerLeft,
      ),
    );
  }
}
