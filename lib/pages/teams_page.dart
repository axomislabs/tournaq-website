import 'dart:math';

import 'package:flutter/material.dart';
import '../models/team.dart';
import '../services/app_data_service.dart';
import '../state/app_state.dart';
import '../widgets/app_drawer.dart';
import '../widgets/create_team_sheet.dart';
import '../widgets/scrollable_page.dart';
import 'team_detail_page.dart';

class TeamsPage extends StatefulWidget {
  final AppState appState;
  final Function(AppState) onAppStateChanged;
  const TeamsPage({super.key, required this.appState, required this.onAppStateChanged});
  @override
  State<TeamsPage> createState() => _TeamsPageState();
}

class _TeamsPageState extends State<TeamsPage> {
  late AppState _localState;
  final _rng = Random();

  static const _prefixes = ['Falcon','Phoenix','Lion','Tiger','Eagle','Storm','Dragon','Viper','Thunder','Raven','Comet','Shadow','Blaze','Orbit','Nova'];
  static const _suffixes = ['Squad','Team','Crew','Force','Unit','Pack','Alliance','Legion','Clan','Dynasty'];

  @override
  void initState() { super.initState(); _localState = widget.appState; }

  void _updateState(AppState s) {
    setState(() => _localState = s);
    widget.onAppStateChanged(s);
  }

  String _randomName() =>
    '${_prefixes[_rng.nextInt(_prefixes.length)]} ${_suffixes[_rng.nextInt(_suffixes.length)]}';

  void _generateRandom(int count) {
    var s = _localState;
    for (var i = 0; i < count; i++) {
      s = AppDataService.createTeam(s, name: _randomName(), scope: TeamScope.temporary);
    }
    _updateState(s);
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Generated $count random teams.')));
  }

  Future<void> _showCreateSheet() async {
    final result = await showModalBottomSheet<AppState>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CreateTeamSheet(appState: _localState),
    );
    if (result != null && mounted) _updateState(result);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: AppDrawer(appState: _localState, onAppStateChanged: _updateState),
      appBar: AppBar(title: const Text('Teams'), backgroundColor: Theme.of(context).colorScheme.inversePrimary),
      body: ScrollablePage(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          ElevatedButton.icon(
            onPressed: _showCreateSheet,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Create Team', style: TextStyle(fontWeight: FontWeight.w700)),
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
            label: const Text('Generate 10 Random Teams'),
            style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          ),
          const SizedBox(height: 24),
          Text('Teams (${_localState.teams.length})', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          if (_localState.teams.isEmpty)
            const Center(child: Padding(
              padding: EdgeInsets.all(24),
              child: Text('No teams yet.', style: TextStyle(color: Colors.black45)),
            ))
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _localState.teams.length,
              itemBuilder: (context, index) {
                final team = _localState.teams[index];
                final memberCount = _localState.getUsersForTeam(team.id).length;
                final tournamentCount = _localState.getTeamTournaments(team.id).length;
                return ListTile(
                  title: Text(team.name),
                  subtitle: Text('$memberCount member(s) • $tournamentCount tournament(s)'),
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => TeamDetailPage(appState: _localState, onAppStateChanged: _updateState, teamId: team.id),
                  )),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'delete') _updateState(AppDataService.deleteTeam(_localState, team.id));
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(value: 'delete', child: Text('Delete Team')),
                    ],
                  ),
                );
              },
            ),
        ]),
      ),
    );
  }
}
