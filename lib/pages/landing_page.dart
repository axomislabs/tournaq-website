import 'package:flutter/material.dart';
import '../app/app_colors.dart';
import '../l10n/app_localizations.dart';
import '../state/app_state.dart';
import '../widgets/language_menu_button.dart';
import '../widgets/primary_action_card.dart';
import '../widgets/scrollable_page.dart';
import '../widgets/tournaq_app_bar.dart';
import 'administration_page.dart';
import 'coming_soon_page.dart';
import 'more_page.dart';
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
      appBar: TournaQAppBar(
        title: l10n.navHome,
        actions: const [LanguageMenuButton()],
      ),
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
          PrimaryActionCard(
            title: l10n.navTournaments,
            subtitle: l10n.landingTournamentsSubtitle,
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
          const SizedBox(height: 12),
          PrimaryActionCard(
            title: l10n.navAdmin,
            subtitle: l10n.landingAdminSubtitle,
            icon: Icons.admin_panel_settings_rounded,
            gradientColors: const [AppColors.gold, AppColors.goldGradientEnd],
            shadowColor: AppColors.gold,
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => AdministrationPage(
                appState: _localState,
                onAppStateChanged: _updateState,
              ),
            )),
          ),
          const SizedBox(height: 12),
          PrimaryActionCard(
            title: l10n.navMore,
            subtitle: l10n.landingMoreSubtitle,
            icon: Icons.more_horiz_rounded,
            gradientColors: const [AppColors.gold, AppColors.goldGradientEnd],
            shadowColor: AppColors.gold,
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => MorePage(
                appState: _localState,
                onAppStateChanged: _updateState,
              ),
            )),
          ),
        ],
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
            title: l10n.landingMoreTournamentTitle,
            subtitle: l10n.landingMoreTournamentSub,
            icon: Icons.emoji_events_rounded,
            description: l10n.landingMoreTournamentSub,
          ),
          const SizedBox(height: 10),
          _buildAnnouncementCard(
            context,
            title: l10n.landingDeviceScalabilityTitle,
            subtitle: l10n.landingDeviceScalabilitySub,
            icon: Icons.devices_rounded,
            description: l10n.landingDeviceScalabilitySub,
          ),
          const SizedBox(height: 10),
          _buildAnnouncementCard(
            context,
            title: l10n.landingScorecardSharingTitle,
            subtitle: l10n.landingScorecardSharingSub,
            icon: Icons.share_rounded,
            description: l10n.landingScorecardSharingSub,
          ),
          const SizedBox(height: 10),
          _buildAnnouncementCard(
            context,
            title: l10n.landingLiveTournamentTitle,
            subtitle: l10n.landingLiveTournamentSub,
            icon: Icons.live_tv_rounded,
            description: l10n.landingLiveTournamentSub,
          ),
          const SizedBox(height: 10),
          _buildAnnouncementCard(
            context,
            title: l10n.landingAdvancedAdminTitle,
            subtitle: l10n.landingAdvancedAdminSub,
            icon: Icons.admin_panel_settings_rounded,
            description: l10n.landingAdvancedAdminSub,
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
  }) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => ComingSoonPage(
          title: title,
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
