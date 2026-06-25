import 'package:flutter/material.dart';
import '../app/app_colors.dart';
import '../app/app_links.dart';
import '../l10n/app_localizations.dart';
import '../state/app_state.dart';
import '../utils/url_utils.dart';
import '../widgets/tournaq_app_bar.dart';
import 'groups_page.dart';
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

  void _showInfo(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
        actionsPadding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        title: const Text('Administration',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
        content: const SingleChildScrollView(
          child: Text(
            'Manage players, teams, and groups to efficiently set up your games and tournaments.',
            style: TextStyle(fontSize: 14, color: Colors.black54, height: 1.6),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => openExternalUrl(ctx, AppLinks.featureUserAdministration),
            child: const Text('Learn more'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Got it',
                style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: TournaQAppBar(
        title: l10n.navAdmin,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline_rounded),
            tooltip: 'About Administration',
            onPressed: () => _showInfo(context),
          ),
        ],
      ),
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
              description: 'Manage groups and affiliations',
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => GroupsPage(
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
