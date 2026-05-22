import 'dart:math';

import 'package:flutter/material.dart';
import '../services/app_data_service.dart';
import '../state/app_state.dart';
import '../widgets/app_drawer.dart';
import '../widgets/scrollable_page.dart';
import '../widgets/user_input_section.dart';
import 'user_detail_page.dart';

class UsersPage extends StatefulWidget {
  final AppState appState;
  final Function(AppState) onAppStateChanged;

  const UsersPage({
    super.key,
    required this.appState,
    required this.onAppStateChanged,
  });

  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  late AppState _localState;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _localState = widget.appState;
  }

  void _updateState(AppState newState) {
    setState(() {
      _localState = newState;
    });
    widget.onAppStateChanged(newState);
  }

  String _randomUserName() {
    const firstNames = [
      'Alex',
      'Charlie',
      'Jordan',
      'Taylor',
      'Morgan',
      'Casey',
      'Jamie',
      'Avery',
      'Riley',
      'Rowan',
      'Skyler',
      'Quinn',
      'Parker',
      'Drew',
      'Reese',
    ];
    const lastNames = [
      'Harper',
      'Brooks',
      'Cole',
      'Reed',
      'Blake',
      'Carter',
      'Lane',
      'Hayes',
      'Hart',
      'West',
      'Fox',
      'Gray',
      'Shaw',
      'Mason',
      'Finn',
    ];
    final first = firstNames[_random.nextInt(firstNames.length)];
    final last = lastNames[_random.nextInt(lastNames.length)];
    return '$first $last';
  }

  void _generateRandomUsers(int count) {
    var newState = _localState;
    for (var i = 0; i < count; i++) {
      newState = AppDataService.createUser(newState, name: _randomUserName());
    }
    _updateState(newState);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Generated $count random players.')));
  }

  void _addUser(String name, String? teamId) {
    if (name.isEmpty) return;

    var newState = AppDataService.createUser(_localState, name: name);

    final createdUser = newState.users.last;
    if (teamId != null) {
      newState = AppDataService.assignUserToTeam(
        newState,
        userId: createdUser.id,
        teamId: teamId,
      );
    }

    _updateState(newState);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: AppDrawer(appState: _localState, onAppStateChanged: _updateState),
      appBar: AppBar(
        title: const Text('Players'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: ScrollablePage(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            UserInputSection(teams: _localState.teams, onUserCreated: _addUser),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => _generateRandomUsers(10),
              child: const Text('Generate 10 Random Players'),
            ),
            const SizedBox(height: 24),
            Text(
              'Players (${_localState.users.length})',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (_localState.users.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('No players yet.'),
                ),
              )
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
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => UserDetailPage(
                            appState: _localState,
                            onAppStateChanged: _updateState,
                            userId: user.id,
                          ),
                        ),
                      );
                    },
                    trailing: IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () {
                        final newState = AppDataService.deleteUser(
                          _localState,
                          user.id,
                        );
                        _updateState(newState);
                      },
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
