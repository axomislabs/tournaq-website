import 'package:flutter/material.dart';
import '../state/app_state.dart';
import '../pages/users_page.dart';
import '../pages/teams_page.dart';
import '../pages/tournaments_page.dart';
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
    return Drawer(
      child: ListView(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
            ),
            child: const Text(
              'Menu',
              style: TextStyle(color: Colors.white, fontSize: 24),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Home'),
            onTap: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
          ),
          ListTile(
            leading: const Icon(Icons.people),
            title: const Text('Users'),
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => UsersPage(
                    appState: appState,
                    onAppStateChanged: onAppStateChanged,
                  ),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.group),
            title: const Text('Teams'),
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => TeamsPage(
                    appState: appState,
                    onAppStateChanged: onAppStateChanged,
                  ),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.sports),
            title: const Text('Tournaments'),
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => TournamentsPage(
                    appState: appState,
                    onAppStateChanged: onAppStateChanged,
                  ),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.sports_basketball),
            title: const Text('Games'),
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => GamesPage(
                    appState: appState,
                    onAppStateChanged: onAppStateChanged,
                  ),
                ),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.local_offer),
            title: const Text('Promo & Ads'),
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => PromoAdsPage(
                    appState: appState,
                    onAppStateChanged: onAppStateChanged,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
