import 'package:flutter/material.dart';
import '../state/app_state.dart';
import '../widgets/app_drawer.dart';
import '../widgets/scrollable_page.dart';
import 'teams_page.dart';
import 'tournaments_page.dart';
import 'games_page.dart';

class LandingPage extends StatelessWidget {
  final AppState appState;
  final Function(AppState) onAppStateChanged;

  const LandingPage({
    super.key,
    required this.appState,
    required this.onAppStateChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: AppDrawer(
        appState: appState,
        onAppStateChanged: onAppStateChanged,
      ),
      appBar: AppBar(
        title: const Text('Tournamaster'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: ScrollablePage(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Welcome to Tournamaster',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              'Organize and manage tournaments with ease.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 24),
            _buildStatsCard(context),
            const SizedBox(height: 20),
            _buildQuickActionsSection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Statistics',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  label: 'Teams',
                  value: appState.teams.length.toString(),
                ),
                _buildStatItem(
                  label: 'Tournaments',
                  value: appState.tournaments.length.toString(),
                ),
                _buildStatItem(
                  label: 'Games',
                  value: appState.games.length.toString(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({required String label, required String value}) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildQuickActionsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => TeamsPage(
                  appState: appState,
                  onAppStateChanged: onAppStateChanged,
                ),
              ),
            );
          },
          child: const Text('Manage Teams'),
        ),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => TournamentsPage(
                  appState: appState,
                  onAppStateChanged: onAppStateChanged,
                ),
              ),
            );
          },
          child: const Text('View Tournaments'),
        ),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => GamesPage(
                  appState: appState,
                  onAppStateChanged: onAppStateChanged,
                ),
              ),
            );
          },
          child: const Text('View Games'),
        ),
      ],
    );
  }
}
