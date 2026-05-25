import 'package:flutter/material.dart';
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
                  iconBgColor: const Color(0xFFFFF8E1),
                  onTap: () =>
                      Navigator.of(context).popUntil((r) => r.isFirst),
                ),
                _buildNavItem(
                  context,
                  icon: Icons.sports_basketball_rounded,
                  label: 'Quick Start Game',
                  iconBgColor: const Color(0xFFFFF8E1),
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
                  child: Divider(height: 1, color: Color(0xFFEEEEEE)),
                ),
                _buildNavItem(
                  context,
                  icon: Icons.local_offer_rounded,
                  label: 'Promo & Ads',
                  iconBgColor: const Color(0xFFF0F0F0),
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
                  iconBgColor: const Color(0xFFEEF2E6),
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
      color: const Color(0xFF6E7640),
      child: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/tournaq_background.png',
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
                  'assets/tournaq_logo.png',
                  width: 210,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Scoring, Games & Tournament Management',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFFF0D47A),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
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
