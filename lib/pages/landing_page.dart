import 'package:flutter/material.dart';
import '../state/app_state.dart';
import '../widgets/app_drawer.dart';
import '../widgets/quick_start_sheet.dart';
import '../widgets/scrollable_page.dart';
import '../widgets/tournaq_app_bar.dart';
import 'games_page.dart';
import 'score_page.dart';
import 'teams_page.dart';
import 'tournaments_page.dart';

class LandingPage extends StatelessWidget {
  final AppState appState;
  final Function(AppState) onAppStateChanged;

  const LandingPage({
    super.key,
    required this.appState,
    required this.onAppStateChanged,
  });

  Future<void> _handleQuickGame(BuildContext context) async {
    final result = await showModalBottomSheet<({AppState state, String gameId})>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => QuickStartSheet(appState: appState),
    );
    if (result == null || !context.mounted) return;
    onAppStateChanged(result.state);
    if (!context.mounted) return;
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ScorePage(
        appState: result.state,
        onAppStateChanged: onAppStateChanged,
        gameId: result.gameId,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: AppDrawer(
        appState: appState,
        onAppStateChanged: onAppStateChanged,
      ),
      appBar: const TournaQAppBar(title: 'Home'),
      body: ScrollablePage(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildBrand(),
            _buildActionCards(context),
            _buildUpcomingSection(context),
            const SizedBox(height: 36),
          ],
        ),
      ),
    );
  }

  // ── Top: Logo + Name + Subtitle ───────────────────────────────────────────

  Widget _buildBrand() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 36, 24, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Image.asset(
            'assets/tournaq_logo.png',
            width: 210,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 16),
          const Text(
            'Scoring, Games & Tournament Management',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFFB08B1E),
              fontWeight: FontWeight.w500,
              letterSpacing: 0.2,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  // ── Middle: Large Action Cards ────────────────────────────────────────────

  Widget _buildActionCards(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          _buildPrimaryCard(
            title: 'Quick Game',
            subtitle: 'Jump straight into a game',
            icon: Icons.flash_on_rounded,
            gradientColors: const [Color(0xFFB08B1E), Color(0xFFC9A030)],
            shadowColor: Color(0xFFB08B1E),
            onTap: () => _handleQuickGame(context),
          ),
          const SizedBox(height: 12),
          _buildPrimaryCard(
            title: 'Match History',
            subtitle: 'Browse and review past games',
            icon: Icons.sports_score_rounded,
            gradientColors: const [Color(0xFFB08B1E), Color(0xFFC9A030)],
            shadowColor: Color(0xFFB08B1E),
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => GamesPage(
                appState: appState,
                onAppStateChanged: onAppStateChanged,
              ),
            )),
          ),
        ],
      ),
    );
  }

  Widget _buildPrimaryCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Color> gradientColors,
    required Color shadowColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 26),
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
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.1,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.80),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.white, size: 24),
          ],
        ),
      ),
    );
  }

  // ── Bottom: Upcoming Section ──────────────────────────────────────────────

  Widget _buildUpcomingSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Upcoming',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Colors.black87,
              letterSpacing: 0.1,
            ),
          ),
          const SizedBox(height: 12),
          _buildFeatureCard(
            title: 'Tournament Management',
            subtitle: '${appState.tournaments.length} tournament(s) active',
            icon: Icons.emoji_events_rounded,
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => TournamentsPage(
                appState: appState,
                onAppStateChanged: onAppStateChanged,
              ),
            )),
          ),
          const SizedBox(height: 10),
          _buildFeatureCard(
            title: 'Teams & Players',
            subtitle:
                '${appState.teams.length} team(s) · ${appState.users.length} player(s)',
            icon: Icons.group_rounded,
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => TeamsPage(
                appState: appState,
                onAppStateChanged: onAppStateChanged,
              ),
            )),
          ),
          const SizedBox(height: 10),
          _buildFeatureCard(
            title: 'More Game Modes',
            subtitle: 'League, Knockout, Round Robin & more',
            icon: Icons.tune_rounded,
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => TournamentsPage(
                appState: appState,
                onAppStateChanged: onAppStateChanged,
              ),
            )),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFF8E1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: const Color(0xFF6E7640), size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black45,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFFBBBBBB),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
