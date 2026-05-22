import 'package:flutter/material.dart';
import '../models/game.dart';
import '../state/app_state.dart';
import '../widgets/app_drawer.dart';
import '../widgets/scrollable_page.dart';
import '../widgets/game_tile.dart';
import 'score_page.dart';

class GamesPage extends StatefulWidget {
  final AppState appState;
  final Function(AppState) onAppStateChanged;

  const GamesPage({
    super.key,
    required this.appState,
    required this.onAppStateChanged,
  });

  @override
  State<GamesPage> createState() => _GamesPageState();
}

class _GamesPageState extends State<GamesPage> {
  late AppState _localState;
  String? _selectedTournamentId;

  @override
  void initState() {
    super.initState();
    _localState = widget.appState;
    _selectedTournamentId = null;
  }

  List<Game> get _filteredGames {
    if (_selectedTournamentId == null) return _localState.games;
    return _localState.getTournamentGames(_selectedTournamentId!);
  }

  void _updateState(AppState newState) {
    setState(() {
      _localState = newState;
    });
    widget.onAppStateChanged(newState);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: AppDrawer(appState: _localState, onAppStateChanged: _updateState),
      appBar: AppBar(
        title: const Text('Games'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: ScrollablePage(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Games',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (_localState.tournaments.isNotEmpty) ...[
              DropdownButtonFormField<String?>(
                initialValue: _selectedTournamentId,
                decoration: const InputDecoration(
                  labelText: 'Filter by tournament',
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('All Games'),
                  ),
                  ..._localState.tournaments.map(
                    (tournament) => DropdownMenuItem(
                      value: tournament.id,
                      child: Text(tournament.name),
                    ),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedTournamentId = value;
                  });
                },
              ),
              const SizedBox(height: 16),
            ],
            Text(
              'Games (${_filteredGames.length})',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (_filteredGames.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('No games yet. Create a tournament first!'),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _filteredGames.length,
                itemBuilder: (context, index) {
                  final game = _filteredGames[index];
                  return GameTile(
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
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
