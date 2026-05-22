import 'dart:math';

import 'package:flutter/material.dart';
import '../services/app_data_service.dart';
import '../state/app_state.dart';
import '../widgets/app_drawer.dart';
import '../widgets/create_player_sheet.dart';
import '../widgets/scrollable_page.dart';
import 'user_detail_page.dart';

class UsersPage extends StatefulWidget {
  final AppState appState;
  final Function(AppState) onAppStateChanged;
  const UsersPage({super.key, required this.appState, required this.onAppStateChanged});
  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  late AppState _localState;
  final _rng = Random();

  static const _firstNames = ['Alex','Charlie','Jordan','Taylor','Morgan','Casey','Jamie','Avery','Riley','Rowan','Skyler','Quinn','Parker','Drew','Reese'];
  static const _lastNames = ['Harper','Brooks','Cole','Reed','Blake','Carter','Lane','Hayes','Hart','West','Fox','Gray','Shaw','Mason','Finn'];

  @override
  void initState() { super.initState(); _localState = widget.appState; }

  void _updateState(AppState s) {
    setState(() => _localState = s);
    widget.onAppStateChanged(s);
  }

  String _randomName() =>
    '${_firstNames[_rng.nextInt(_firstNames.length)]} ${_lastNames[_rng.nextInt(_lastNames.length)]}';

  void _generateRandom(int count) {
    var s = _localState;
    for (var i = 0; i < count; i++) { s = AppDataService.createUser(s, name: _randomName()); }
    _updateState(s);
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Generated $count random players.')));
  }

  Future<void> _showCreateSheet() async {
    final result = await showModalBottomSheet<AppState>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CreatePlayerSheet(appState: _localState),
    );
    if (result != null && mounted) _updateState(result);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: AppDrawer(appState: _localState, onAppStateChanged: _updateState),
      appBar: AppBar(title: const Text('Players'), backgroundColor: Theme.of(context).colorScheme.inversePrimary),
      body: ScrollablePage(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          ElevatedButton.icon(
            onPressed: _showCreateSheet,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Create Player', style: TextStyle(fontWeight: FontWeight.w700)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD9A520),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => _generateRandom(10),
            icon: const Icon(Icons.shuffle_rounded),
            label: const Text('Generate 10 Random Players'),
            style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          ),
          const SizedBox(height: 24),
          Text('Players (${_localState.users.length})', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          if (_localState.users.isEmpty)
            const Center(child: Padding(
              padding: EdgeInsets.all(24),
              child: Text('No players yet.', style: TextStyle(color: Colors.black45)),
            ))
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _localState.users.length,
              itemBuilder: (context, index) {
                final user = _localState.users[index];
                return ListTile(
                  title: Text(user.name),
                  subtitle: Text('${user.teamIds.length} team(s)'),
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => UserDetailPage(appState: _localState, onAppStateChanged: _updateState, userId: user.id),
                  )),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => _updateState(AppDataService.deleteUser(_localState, user.id)),
                  ),
                );
              },
            ),
        ]),
      ),
    );
  }
}
