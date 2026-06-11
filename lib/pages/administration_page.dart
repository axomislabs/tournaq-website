import 'package:flutter/material.dart';
import '../app/app_colors.dart';
import '../l10n/app_localizations.dart';
import '../state/app_state.dart';
import '../widgets/app_drawer.dart';
import '../widgets/tournaq_app_bar.dart';
import 'clubs_page.dart';
import 'teams_page.dart';
import 'users_page.dart';

class AdministrationPage extends StatelessWidget {
  final AppState appState;
  final Function(AppState) onAppStateChanged;

  const AdministrationPage({
    super.key,
    required this.appState,
    required this.onAppStateChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      drawer: AppDrawer(appState: appState, onAppStateChanged: onAppStateChanged),
      appBar: TournaQAppBar(title: l10n.navAdmin),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _AdminTile(
              icon: Icons.person_rounded,
              color: AppColors.gold,
              gradientEnd: AppColors.goldGradientEnd,
              name: l10n.navPlayers,
              description: 'Manage player profiles',
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => UsersPage(
                  appState: appState,
                  onAppStateChanged: onAppStateChanged,
                ),
              )),
            ),
            _AdminTile(
              icon: Icons.groups_rounded,
              color: AppColors.gold,
              gradientEnd: AppColors.goldGradientEnd,
              name: l10n.navTeams,
              description: 'Manage teams and rosters',
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => TeamsPage(
                  appState: appState,
                  onAppStateChanged: onAppStateChanged,
                ),
              )),
            ),
            _AdminTile(
              icon: Icons.shield_rounded,
              color: AppColors.gold,
              gradientEnd: AppColors.goldGradientEnd,
              name: l10n.navClubs,
              description: 'Manage clubs and affiliations',
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => ClubsPage(
                  appState: appState,
                  onAppStateChanged: onAppStateChanged,
                ),
              )),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color gradientEnd;
  final String name;
  final String description;
  final VoidCallback onTap;

  const _AdminTile({
    required this.icon,
    required this.color,
    required this.gradientEnd,
    required this.name,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color, gradientEnd],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.28),
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
            const Icon(Icons.chevron_right_rounded, color: Colors.white, size: 24),
          ],
        ),
      ),
    );
  }
}
