import 'package:flutter/material.dart';
import '../app/app_colors.dart';
import '../l10n/app_localizations.dart';
import '../state/app_state.dart';
import '../widgets/app_drawer.dart';
import '../widgets/scrollable_page.dart';
import '../widgets/tournaq_app_bar.dart';
import 'coming_soon_page.dart';
import 'games_page.dart';
import 'tournaments_page.dart';

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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      drawer: AppDrawer(
        appState: _localState,
        onAppStateChanged: _updateState,
      ),
      appBar: TournaQAppBar(title: l10n.navHome),
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
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
      child: Column(
        children: [
          _buildPrimaryCard(
            title: 'Games',
            subtitle: l10n.landingMatchHistorySubtitle,
            icon: Icons.sports_score_rounded,
            gradientColors: const [AppColors.gold, AppColors.goldGradientEnd],
            shadowColor: AppColors.gold,
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => GamesPage(
                appState: _localState,
                onAppStateChanged: _updateState,
              ),
            )),
          ),
          const SizedBox(height: 12),
          _buildPrimaryCard(
            title: 'Tournaments',
            subtitle: 'Manage tournaments & scrambles',
            icon: Icons.emoji_events_rounded,
            gradientColors: const [AppColors.gold, AppColors.goldGradientEnd],
            shadowColor: AppColors.gold,
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => TournamentsPage(
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
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.comingSoon,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Colors.black87,
              letterSpacing: 0.1,
            ),
          ),
          const SizedBox(height: 12),
          _buildAnnouncementCard(
            context,
            title: l10n.landingTournamentManagement,
            subtitle: l10n.landingTournamentManagementSub,
            icon: Icons.emoji_events_rounded,
            description: l10n.landingTournamentManagementDesc,
          ),
          const SizedBox(height: 10),
          _buildAnnouncementCard(
            context,
            title: l10n.landingCloudTitle,
            subtitle: l10n.landingCloudSub,
            icon: Icons.cloud_rounded,
            description: l10n.landingCloudDesc,
          ),
        ],
      ),
    );
  }

  Widget _buildAnnouncementCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required String description,
    String? pageTitle,
  }) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => ComingSoonPage(
          title: pageTitle ?? title,
          shortDescription: description,
        ),
      )),
      child: Card(
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
                color: AppColors.goldCream,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.oliveMedium, size: 22),
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
                color: AppColors.goldCream,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.comingSoonBorder),
              ),
              child: Text(
                AppLocalizations.of(context)!.comingSoon,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppColors.oliveMedium,
                ),
              ),
            ),
          ],
        ),
      ),
    ));
  }
}
