import 'package:flutter/material.dart';
import '../state/app_state.dart';
import '../widgets/app_drawer.dart';

class ClubsPage extends StatelessWidget {
  final AppState appState;
  final Function(AppState) onAppStateChanged;

  const ClubsPage({
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
        title: const Text('Clubs'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.shield_outlined, size: 64, color: Colors.black26),
            SizedBox(height: 16),
            Text(
              'Clubs',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 8),
            Text(
              'Coming soon',
              style: TextStyle(color: Colors.black45, fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }
}
