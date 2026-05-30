import 'package:flutter/material.dart';
import '../app/app_assets.dart';
import '../app/app_colors.dart';
import '../state/app_state.dart';
import '../pages/contact_page.dart';
import '../pages/games_page.dart';
import '../pages/promo_ads_page.dart';

class AppDrawer extends StatelessWidget {
  final AppState appState;
  final void Function(AppState) onAppStateChanged;

  const AppDrawer({
    super.key,
    required this.appState,
    required this.onAppStateChanged,
  });

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Drawer(
      backgroundColor: Colors.white,
      elevation: 16,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          _buildHeader(topPadding),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 12),
              children: [
                _buildNavItem(
                  context,
                  icon: Icons.home_rounded,
                  label: 'Home',
                  iconBgColor: AppColors.goldCream,
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).popUntil((r) => r.isFirst);
                  },
                ),
                _buildNavItem(
                  context,
                  icon: Icons.sports_basketball_rounded,
                  label: 'Quick Start Game',
                  iconBgColor: AppColors.goldCream,
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => GamesPage(
                        appState: appState,
                        onAppStateChanged: onAppStateChanged,
                      ),
                    ));
                  },
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Divider(height: 1, color: AppColors.divider),
                ),
                _buildNavItem(
                  context,
                  icon: Icons.local_offer_rounded,
                  label: 'Sponsoring & Promo',
                  iconBgColor: AppColors.surfaceGray,
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => PromoAdsPage(
                        appState: appState,
                        onAppStateChanged: onAppStateChanged,
                      ),
                    ));
                  },
                ),
                _buildNavItem(
                  context,
                  icon: Icons.contact_support_rounded,
                  label: 'Contact & About',
                  iconBgColor: AppColors.oliveLight,
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => ContactPage(
                        appState: appState,
                        onAppStateChanged: onAppStateChanged,
                      ),
                    ));
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(double topPadding) {
    return Container(
      width: double.infinity,
      color: AppColors.oliveMedium,
      child: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              AppAssets.background,
              fit: BoxFit.cover,
              opacity: const AlwaysStoppedAnimation(0.10),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(24, topPadding + 32, 24, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Image.asset(
                  AppAssets.logoRectangle,
                  width: double.infinity,
                  fit: BoxFit.fitWidth,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Scoring, Games and Tournament Management',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.goldLight,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color iconBgColor,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(color: iconBgColor, shape: BoxShape.circle),
          child: Icon(icon, color: Colors.black87, size: 20),
        ),
        title: Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
            letterSpacing: 0.1,
          ),
        ),
        trailing: const Icon(
          Icons.chevron_right_rounded,
          color: Color(0xFFBBBBBB),
          size: 22,
        ),
        onTap: onTap,
      ),
    );
  }
}
