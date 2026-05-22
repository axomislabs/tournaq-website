import 'package:flutter/material.dart';

import '../models/game.dart';
import '../models/tournament.dart';
import '../models/tournament_mode.dart';
import '../models/team.dart';
import '../services/app_data_service.dart';
import '../services/tournament_logic_service.dart';
import '../state/app_state.dart';
import '../widgets/app_drawer.dart';
import '../widgets/assign_dialog.dart';
import '../widgets/game_tile.dart';
import '../widgets/hybrid_mode_setup_page.dart';
import '../widgets/scrollable_page.dart';
import '../widgets/single_games_dialog.dart';
import 'club_detail_page.dart';
import 'score_page.dart';
import 'team_detail_page.dart';

class TournamentDetailPage extends StatefulWidget {
  final AppState appState;
  final Function(AppState) onAppStateChanged;
  final String tournamentId;

  const TournamentDetailPage({
    super.key,
    required this.appState,
    required this.onAppStateChanged,
    required this.tournamentId,
  });

  @override
  State<TournamentDetailPage> createState() => _TournamentDetailPageState();
}

class _TournamentDetailPageState extends State<TournamentDetailPage> {
  late AppState _localState;

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

  Tournament? get _tournament =>
      _localState.getTournamentById(widget.tournamentId);

  List<Team> get _teams {
    final tournament = _tournament;
    if (tournament == null) return [];
    return _localState.getTeamsByIds(tournament.teamIds);
  }

  List<Game> get _games {
    final tournament = _tournament;
    if (tournament == null) return [];
    return _localState.getTournamentGames(tournament.id);
  }

  Future<void> _showAssignTeamDialog() async {
    final tournament = _tournament;
    if (tournament == null) return;
    final items = _localState.teams
        .where((t) => !tournament.teamIds.contains(t.id))
        .map((t) => (id: t.id, name: t.name))
        .toList();
    final selected = await showAssignDialog(
      context: context, title: 'Assign Team', items: items,
      emptyMessage: 'All teams are already in this tournament.',
    );
    if (selected != null && mounted) {
      _updateState(AppDataService.assignTeamToTournament(_localState, teamId: selected, tournamentId: widget.tournamentId));
    }
  }

  Future<void> _assignClub() async {
    final items = _localState.clubs
        .where((c) => !c.tournamentIds.contains(widget.tournamentId))
        .map((c) => (id: c.id, name: c.name))
        .toList();
    final selected = await showAssignDialog(
      context: context, title: 'Assign to Club', items: items,
      emptyMessage: 'Tournament is already in all clubs.',
    );
    if (selected != null && mounted) {
      _updateState(AppDataService.assignTournamentToClub(_localState, tournamentId: widget.tournamentId, clubId: selected));
    }
  }

  void _generateGames() {
    final tournament = _tournament;
    if (tournament == null) return;
    if (tournament.teamIds.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add at least two teams before generating games.'),
        ),
      );
      return;
    }

    final newState = AppDataService.generateGamesForTournament(
      _localState,
      tournament,
    );
    _updateState(newState);
  }

  void _showSingleGamesDialog() {
    final tournament = _tournament;
    if (tournament == null) return;
    if (tournament.teamIds.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add at least two teams before creating games.'),
        ),
      );
      return;
    }

    showDialog<void>(
      context: context,
      builder: (context) => SingleGamesDialog(
        appState: _localState,
        tournament: tournament,
        onGameCreated: _updateState,
      ),
    );
  }

  Future<void> _showHybridModeSetup() async {
    final tournament = _tournament;
    if (tournament == null) return;

    final result = await Navigator.of(context).push<List<List<TournamentModeType>>>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => HybridModeSetupPage(
          modeTypes: TournamentModeType.values
              .where((mode) => mode != TournamentModeType.hybrid)
              .toList(),
          initialGroups: tournament.hybridGroups,
        ),
      ),
    );
    if (result != null && mounted) {
      _updateState(_localState.updateTournament(tournament.copyWith(hybridGroups: result)));
    }
  }

  void _resetGames() {
    final tournament = _tournament;
    if (tournament == null) return;

    showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Games'),
        content: const Text(
          'Are you sure you want to delete all games in this tournament?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Clear'),
          ),
        ],
      ),
    ).then((confirmed) {
      if (confirmed == true) {
        var newState = _localState;
        for (final gameId in tournament.gameIds) {
          newState = AppDataService.deleteGame(newState, gameId);
        }
        _updateState(newState);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final tournament = _tournament;
    if (tournament == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Tournament Details'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        ),
        body: const Center(child: Text('Tournament not found.')),
      );
    }

    final standings = tournament.mode.type == TournamentModeType.league
        ? TournamentLogicService.calculateStandings(_localState, tournament)
        : <TournamentStanding>[];

    return Scaffold(
      drawer: AppDrawer(appState: _localState, onAppStateChanged: _updateState),
      appBar: AppBar(
        title: Text(tournament.name),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: ScrollablePage(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              color: Theme.of(context).colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tournament.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('Mode: ${tournament.mode.displayName}'),
                    Text('Status: ${tournament.status.name}'),
                    Text('Teams: ${tournament.teamIds.length}'),
                    Text('Games: ${tournament.gameIds.length}'),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      children: [
                        ElevatedButton(
                          onPressed: _showAssignTeamDialog,
                          child: const Text('Assign Team'),
                        ),
                        ElevatedButton(
                          onPressed: _assignClub,
                          child: const Text('Assign to Club'),
                        ),
                        if (tournament.mode.type ==
                            TournamentModeType.singleGame)
                          ElevatedButton(
                            onPressed: _showSingleGamesDialog,
                            child: const Text('Create Game'),
                          )
                        else if (tournament.mode.type ==
                            TournamentModeType.hybrid) ...[
                          ElevatedButton(
                            onPressed: _showHybridModeSetup,
                            child: const Text('Configure Hybrid Groups'),
                          ),
                          ElevatedButton(
                            onPressed: tournament.hybridGroups.isNotEmpty
                                ? _generateGames
                                : null,
                            child: const Text('Generate Games'),
                          ),
                        ] else
                          ElevatedButton(
                            onPressed: tournament.gameIds.isEmpty
                                ? _generateGames
                                : null,
                            child: const Text('Generate Games'),
                          ),
                        if (tournament.gameIds.isNotEmpty)
                          ElevatedButton(
                            onPressed: _resetGames,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red[400],
                            ),
                            child: const Text('Clear Games'),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            if (tournament.mode.type == TournamentModeType.hybrid) ...[
              const Text(
                'Hybrid Groups',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              if (tournament.hybridGroups.isEmpty)
                const Text('No hybrid groups configured yet.')
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: List.generate(tournament.hybridGroups.length, (
                    groupIndex,
                  ) {
                    final group = tournament.hybridGroups[groupIndex];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Wrap(
                          spacing: 8,
                          children: group
                              .map((mode) => Chip(label: Text(mode.name)))
                              .toList(),
                        ),
                      ),
                    );
                  }),
                ),
              const SizedBox(height: 20),
            ],
            Text(
              'Teams (${_teams.length})',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (_teams.isEmpty)
              const Center(child: Text('No teams assigned yet.'))
            else
              Column(
                children: _teams
                    .map(
                      (team) => Card(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        child: ListTile(
                          title: Text(team.name),
                          subtitle: Text(
                            '${_localState.getUsersForTeam(team.id).length} member(s)',
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
                        ),
                      ),
                    )
                    .toList(),
              ),
            const SizedBox(height: 20),
            if (standings.isNotEmpty) ...[
              const Text(
                'League Standings',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Card(
                child: Column(
                  children: standings.map((standing) {
                    final team = _localState.getTeamById(standing.teamId);
                    return ListTile(
                      title: Text(team?.name ?? 'Unknown'),
                      subtitle: Text(
                        'W:${standing.wins} D:${standing.draws} L:${standing.losses} PF:${standing.pointsFor} PA:${standing.pointsAgainst}',
                      ),
                      onTap: team == null ? null : () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => TeamDetailPage(appState: _localState, onAppStateChanged: _updateState, teamId: team.id),
                      )),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 20),
            ],
            Text(
              'Games (${_games.length})',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (_games.isEmpty)
              const Center(child: Text('No games created yet.'))
            else
              Column(
                children: _games
                    .map(
                      (game) => GameTile(
                        game: game,
                        appState: _localState,
                        onScoreTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => ScorePage(
                                appState: _localState,
                                onAppStateChanged: _updateState,
                                gameId: game.id,
                              ),
                            ),
                          );
                        },
                      ),
                    )
                    .toList(),
              ),

            // Clubs section
            const SizedBox(height: 20),
            Builder(builder: (context) {
              final clubs = _localState.getTournamentClubs(widget.tournamentId);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Clubs (${clubs.length})', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  if (clubs.isEmpty)
                    const Center(child: Text('Not in any clubs yet.', style: TextStyle(color: Colors.black45)))
                  else
                    ...clubs.map((club) => Card(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: ListTile(
                        leading: const Icon(Icons.home_rounded),
                        title: Text(club.name),
                        subtitle: Text('${club.playerIds.length} player(s) • ${club.teamIds.length} team(s)'),
                        onTap: () => Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => ClubDetailPage(appState: _localState, onAppStateChanged: _updateState, clubId: club.id),
                        )),
                        trailing: IconButton(
                          icon: const Icon(Icons.remove_circle_outline),
                          onPressed: () => _updateState(AppDataService.removeTournamentFromClub(
                            _localState, tournamentId: widget.tournamentId, clubId: club.id,
                          )),
                        ),
                      ),
                    )),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }
}
