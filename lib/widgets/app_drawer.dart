import 'package:flutter/material.dart';
import '../state/app_state.dart';
import '../pages/users_page.dart';
import '../pages/teams_page.dart';
import '../pages/tournaments_page.dart';
import '../pages/games_page.dart';
import '../pages/clubs_page.dart';
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
                  iconBgColor: const Color(0xFFFFF3CC),
                  onTap: () =>
                      Navigator.of(context).popUntil((r) => r.isFirst),
                ),
                _buildNavItem(
                  context,
                  icon: Icons.sports_basketball_rounded,
                  label: 'Games',
                  iconBgColor: const Color(0xFFFFF3CC),
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
                _buildNavItem(
                  context,
                  icon: Icons.emoji_events_rounded,
                  label: 'Tournaments',
                  iconBgColor: const Color(0xFFFFF3CC),
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => TournamentsPage(
                        appState: appState,
                        onAppStateChanged: onAppStateChanged,
                      ),
                    ));
                  },
                ),
                _buildNavItem(
                  context,
                  icon: Icons.group_rounded,
                  label: 'Teams',
                  iconBgColor: const Color(0xFFFFF3CC),
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => TeamsPage(
                        appState: appState,
                        onAppStateChanged: onAppStateChanged,
                      ),
                    ));
                  },
                ),
                _buildNavItem(
                  context,
                  icon: Icons.person_rounded,
                  label: 'Players',
                  iconBgColor: const Color(0xFFFFF3CC),
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => UsersPage(
                        appState: appState,
                        onAppStateChanged: onAppStateChanged,
                      ),
                    ));
                  },
                ),
                _buildNavItem(
                  context,
                  icon: Icons.shield_rounded,
                  label: 'Clubs',
                  iconBgColor: const Color(0xFFFFF3CC),
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => ClubsPage(
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
      color: const Color(0xFFD9A520),
      padding: EdgeInsets.fromLTRB(22, topPadding + 28, 22, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              color: Color(0xFFFFE57F),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.emoji_events_rounded,
              color: Colors.black87,
              size: 34,
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Tournamaster',
            style: TextStyle(
              color: Colors.black,
              fontSize: 32,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.3,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Manage your Tournaments',
            style: TextStyle(
              color: Colors.black.withValues(alpha: 0.55),
              fontSize: 16,
              fontWeight: FontWeight.w400,
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
