import 'package:flutter/material.dart';
import '../state/app_state.dart';
import '../widgets/app_drawer.dart';
import '../widgets/quick_start_sheet.dart';
import '../widgets/scrollable_page.dart';
import '../widgets/tournaq_app_bar.dart';
import 'games_page.dart';
import 'scorecard_splash_page.dart';

class LandingPage extends StatefulWidget {
  final AppState appState;
  final Function(AppState) onAppStateChanged;

  const LandingPage({
    super.key,
    required this.appState,
    required this.onAppStateChanged,
  });

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  late AppState _localState;

  @override
  void initState() {
    super.initState();
    _localState = widget.appState;
  }

  void _updateState(AppState newState) {
    setState(() => _localState = newState);
    widget.onAppStateChanged(newState);
  }

  Future<void> _handleQuickGame(BuildContext context) async {
    final result = await showModalBottomSheet<({AppState state, String gameId})>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => QuickStartSheet(appState: _localState),
    );
    if (result == null || !context.mounted) return;
    _updateState(result.state);
    if (!context.mounted) return;
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ScorecardSplashPage(
        appState: result.state,
        onAppStateChanged: _updateState,
        gameId: result.gameId,
        onSaveAndReturn: () {
          // Stack is LandingPage → ScorePage. Pop ScorePage, then push GamesPage
          // so "Save & Return to Games" always lands on GamesPage, not Home.
          Navigator.of(context).pop();
          if (!context.mounted) return;
          Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => GamesPage(
              appState: _localState,
              onAppStateChanged: _updateState,
            ),
          ));
        },
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: AppDrawer(
        appState: _localState,
        onAppStateChanged: _updateState,
      ),
      appBar: const TournaQAppBar(title: 'Home'),
      body: ScrollablePage(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildActionCards(context),
            _buildUpcomingSection(context),
            const SizedBox(height: 36),
          ],
        ),
      ),
    );
  }

  // ── Action Cards ──────────────────────────────────────────────────────────

  Widget _buildActionCards(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
      child: Column(
        children: [
          _buildPrimaryCard(
            title: 'Quick Start Game',
            subtitle: 'Beach Volleyball Match',
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
                appState: _localState,
                onAppStateChanged: _updateState,
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
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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

  // ── Bottom: Coming Soon Section ───────────────────────────────────────────

  Widget _buildUpcomingSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Coming Soon',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Colors.black87,
              letterSpacing: 0.1,
            ),
          ),
          const SizedBox(height: 12),
          _buildAnnouncementCard(
            title: 'Tournament Management',
            subtitle: 'Create and manage tournaments with multiple formats.',
            icon: Icons.emoji_events_rounded,
          ),
          const SizedBox(height: 10),
          _buildAnnouncementCard(
            title: 'Player, Team & Club Administration',
            subtitle: 'Organize players, teams and clubs.',
            icon: Icons.group_rounded,
          ),
          const SizedBox(height: 10),
          _buildAnnouncementCard(
            title: 'Cloud Services',
            subtitle: 'Cloud synchronization and connected features.',
            icon: Icons.cloud_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildAnnouncementCard({
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.grey.shade200),
      ),
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
                    style: const TextStyle(fontSize: 12, color: Colors.black45),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8E1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFB0BA78)),
              ),
              child: const Text(
                'Coming Soon',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF6E7640),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
