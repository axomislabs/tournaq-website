import 'dart:math';

import 'package:flutter/material.dart';
import '../models/team.dart';
import '../services/app_data_service.dart';
import '../state/app_state.dart';
import '../widgets/app_drawer.dart';
import '../widgets/team_input_section.dart';
import 'team_detail_page.dart';

class TeamsPage extends StatefulWidget {
  final AppState appState;
  final Function(AppState) onAppStateChanged;

  const TeamsPage({
    super.key,
    required this.appState,
    required this.onAppStateChanged,
  });

  @override
  State<TeamsPage> createState() => _TeamsPageState();
}

class _TeamsPageState extends State<TeamsPage> {
  late AppState _localState;
  final Random _random = Random();
  late final ScrollController _scrollController;
  String _scrollStatus = 'idle';
  String _pointerStatus = 'none';

  @override
  void initState() {
    super.initState();
    _localState = widget.appState;
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _updateState(AppState newState) {
    setState(() {
      _localState = newState;
    });
    widget.onAppStateChanged(newState);
  }

  void _updateScrollStatus(ScrollNotification notification) {
    setState(() {
      _scrollStatus =
          '${notification.runtimeType.toString()} @ '
          '${notification.metrics.pixels.toStringAsFixed(1)}';
    });
  }

  void _updatePointerStatus(String event, PointerEvent pointer) {
    setState(() {
      _pointerStatus =
          '$event @ '
          '(${pointer.localPosition.dx.toStringAsFixed(0)}, '
          '${pointer.localPosition.dy.toStringAsFixed(0)})';
    });
  }

  String _randomTeamName() {
    const prefixes = [
      'Falcon',
      'Phoenix',
      'Lion',
      'Tiger',
      'Eagle',
      'Storm',
      'Dragon',
      'Viper',
      'Thunder',
      'Raven',
      'Comet',
      'Shadow',
      'Blaze',
      'Orbit',
      'Nova',
    ];
    const suffixes = [
      'Squad',
      'Team',
      'Crew',
      'Force',
      'Unit',
      'Gang',
      'Pack',
      'Alliance',
      'Legion',
      'Group',
      'Collective',
      'Clan',
      'Horde',
      'Dynasty',
      'Crew',
    ];
    final prefix = prefixes[_random.nextInt(prefixes.length)];
    final suffix = suffixes[_random.nextInt(suffixes.length)];
    return '$prefix $suffix';
  }

  void _generateRandomTeams(int count) {
    var newState = _localState;
    for (var i = 0; i < count; i++) {
      newState = AppDataService.createTeam(
        newState,
        name: _randomTeamName(),
        scope: TeamScope.temporary,
      );
    }
    _updateState(newState);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Generated $count random teams.')));
  }

  Future<void> _showAssignUserDialog(Team team) async {
    final availableUsers = _localState.users
        .where((user) => !user.teamIds.contains(team.id))
        .toList();

    if (availableUsers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All users are already assigned to this team.'),
        ),
      );
      return;
    }

    String? selectedUserId = availableUsers.first.id;
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Assign Player'),
          content: DropdownButtonFormField<String>(
            initialValue: selectedUserId,
            items: availableUsers
                .map(
                  (user) =>
                      DropdownMenuItem(value: user.id, child: Text(user.name)),
                )
                .toList(),
            onChanged: (value) {
              selectedUserId = value;
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (selectedUserId != null) {
                  final newState = AppDataService.assignUserToTeam(
                    _localState,
                    userId: selectedUserId!,
                    teamId: team.id,
                  );
                  _updateState(newState);
                }
                Navigator.of(context).pop();
              },
              child: const Text('Assign'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showAssignTournamentDialog(Team team) async {
    final availableTournaments = _localState.tournaments
        .where((tournament) => !tournament.teamIds.contains(team.id))
        .toList();

    if (availableTournaments.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All tournaments already contain this team.'),
        ),
      );
      return;
    }

    String? selectedTournamentId = availableTournaments.first.id;
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Assign Tournament'),
          content: DropdownButtonFormField<String>(
            initialValue: selectedTournamentId,
            items: availableTournaments
                .map(
                  (tournament) => DropdownMenuItem(
                    value: tournament.id,
                    child: Text(tournament.name),
                  ),
                )
                .toList(),
            onChanged: (value) {
              selectedTournamentId = value;
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (selectedTournamentId != null) {
                  final newState = AppDataService.assignTeamToTournament(
                    _localState,
                    teamId: team.id,
                    tournamentId: selectedTournamentId!,
                  );
                  _updateState(newState);
                }
                Navigator.of(context).pop();
              },
              child: const Text('Assign'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: AppDrawer(appState: _localState, onAppStateChanged: _updateState),
      appBar: AppBar(
        title: const Text('Teams'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SafeArea(
        child: NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            _updateScrollStatus(notification);
            debugPrint(
              'TeamsPage scroll notified: ${notification.runtimeType}, '
              'pixels=${notification.metrics.pixels}, '
              'max=${notification.metrics.maxScrollExtent}, '
              'min=${notification.metrics.minScrollExtent}',
            );
            return false;
          },
          child: Listener(
            onPointerDown: (event) => _updatePointerStatus('down', event),
            onPointerMove: (event) => _updatePointerStatus('move', event),
            onPointerUp: (event) => _updatePointerStatus('up', event),
            child: CustomScrollView(
              controller: _scrollController,
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      TeamInputSection(
                        onTeamCreated: (teamName) {
                          final newState = AppDataService.createTeam(
                            _localState,
                            name: teamName,
                            scope: TeamScope.temporary,
                          );
                          _updateState(newState);
                        },
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: () => _generateRandomTeams(10),
                        child: const Text('Generate 10 Random Teams'),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Teams (${_localState.teams.length})',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Scroll status: $_scrollStatus',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Pointer status: $_pointerStatus',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 12),
                    ]),
                  ),
                ),
                if (_localState.teams.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      child: const Align(
                        alignment: Alignment.topLeft,
                        child: Text('No teams yet. Create one above!'),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final team = _localState.teams[index];
                        final teamUsers = _localState.getUsersForTeam(team.id);
                        final teamTournaments = _localState.getTeamTournaments(
                          team.id,
                        );
                        return ListTile(
                          title: Text(team.name),
                          subtitle: Text(
                            '${teamUsers.length} member(s) • ${teamTournaments.length} tournament(s)',
                          ),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => TeamDetailPage(
                                  appState: _localState,
                                  onAppStateChanged: _updateState,
                                  teamId: team.id,
                                ),
                              ),
                            );
                          },
                          trailing: PopupMenuButton<String>(
                            onSelected: (value) async {
                              if (value == 'assignUser') {
                                await _showAssignUserDialog(team);
                              } else if (value == 'assignTournament') {
                                await _showAssignTournamentDialog(team);
                              } else if (value == 'delete') {
                                final newState = AppDataService.deleteTeam(
                                  _localState,
                                  team.id,
                                );
                                _updateState(newState);
                              }
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'assignUser',
                                child: Text('Assign Player'),
                              ),
                              const PopupMenuItem(
                                value: 'assignTournament',
                                child: Text('Assign Tournament'),
                              ),
                              const PopupMenuDivider(),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Text('Delete Team'),
                              ),
                            ],
                          ),
                        );
                      }, childCount: _localState.teams.length),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
