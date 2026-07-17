import 'package:flutter/material.dart';
import '../app/app_colors.dart';
import '../l10n/app_localizations.dart';
import '../state/app_state.dart';
import '../widgets/primary_action_card.dart';
import '../widgets/scrollable_page.dart';
import '../widgets/tournaq_app_bar.dart';
import 'become_test_user_page.dart';
import 'contact_page.dart';
import 'promo_ads_page.dart';
import 'settings_page.dart';

/// Secondary "More" hub — consolidates the app-level destinations that
/// previously lived in the navigation drawer: Sponsoring & Promo,
/// Contact & About, and Settings. Reached from the "More" card on the
/// home ([LandingPage]); each destination uses the same [PrimaryActionCard]
/// as the home screen so the layout stays consistent throughout.
class MorePage extends StatefulWidget {
  final AppState appState;
  final void Function(AppState) onAppStateChanged;

  const MorePage({
    super.key,
    required this.appState,
    required this.onAppStateChanged,
  });

  @override
  State<MorePage> createState() => _MorePageState();
}

class _MorePageState extends State<MorePage> {
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
      appBar: TournaQAppBar(title: l10n.navMore),
      body: ScrollablePage(
        padding: const EdgeInsets.fromLTRB(20, 28, 20, 28),
        child: Column(
          children: [
            PrimaryActionCard(
              title: l10n.navSponsoring,
              subtitle: l10n.moreSponsoringSubtitle,
              icon: Icons.local_offer_rounded,
              gradientColors: const [AppColors.gold, AppColors.goldGradientEnd],
              shadowColor: AppColors.gold,
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => PromoAdsPage(
                  appState: _localState,
                  onAppStateChanged: _updateState,
                ),
              )),
            ),
            const SizedBox(height: 12),
            PrimaryActionCard(
              title: l10n.navContact,
              subtitle: l10n.moreContactSubtitle,
              icon: Icons.contact_support_rounded,
              gradientColors: const [AppColors.gold, AppColors.goldGradientEnd],
              shadowColor: AppColors.gold,
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => ContactPage(
                  appState: _localState,
                  onAppStateChanged: _updateState,
                ),
              )),
            ),
            const SizedBox(height: 12),
            PrimaryActionCard(
              title: l10n.navSettings,
              subtitle: l10n.moreSettingsSubtitle,
              icon: Icons.settings_rounded,
              gradientColors: const [AppColors.gold, AppColors.goldGradientEnd],
              shadowColor: AppColors.gold,
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => SettingsPage(
                  appState: _localState,
                  onAppStateChanged: _updateState,
                ),
              )),
            ),
            const SizedBox(height: 12),
            PrimaryActionCard(
              title: l10n.navBecomeTester,
              subtitle: l10n.moreBecomeTesterSubtitle,
              icon: Icons.science_rounded,
              gradientColors: const [AppColors.gold, AppColors.goldGradientEnd],
              shadowColor: AppColors.gold,
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const BecomeTestUserPage(),
              )),
            ),
          ],
        ),
      ),
    );
  }
}
