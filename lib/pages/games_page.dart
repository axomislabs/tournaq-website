import 'package:flutter/material.dart';
import '../models/game.dart';
import '../state/app_state.dart';
import '../widgets/app_drawer.dart';
import '../widgets/scrollable_page.dart';
import '../widgets/game_tile.dart';
import '../widgets/quick_start_sheet.dart';
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

  Future<void> _showQuickStart() async {
    final result =
        await showModalBottomSheet<({AppState state, String gameId})>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => QuickStartSheet(appState: _localState),
    );

    if (result == null || !mounted) return;

    _updateState(result.state);

    if (!mounted) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ScorePage(
          appState: result.state,
          onAppStateChanged: _updateState,
          gameId: result.gameId,
        ),
      ),
    );
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
            _buildQuickStartCard(),
            const SizedBox(height: 28),
            _buildGameBrowser(),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStartCard() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFD9A520), Color(0xFFE8C840)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD9A520).withValues(alpha: 0.35),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.flash_on_rounded, color: Colors.white, size: 22),
              SizedBox(width: 8),
              Text(
                'Quick Start',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Jump into a game instantly — no tournament needed.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _showQuickStart,
            icon: const Icon(Icons.play_arrow_rounded),
            label: const Text(
              'Quick Start Game',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFFD9A520),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameBrowser() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.sports_score_rounded, size: 20, color: Color(0xFFD9A520)),
            SizedBox(width: 8),
            Text(
              'Game Browser',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
          ],
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
                (t) => DropdownMenuItem(value: t.id, child: Text(t.name)),
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
          '${_filteredGames.length} ${_filteredGames.length == 1 ? 'game' : 'games'}',
          style: const TextStyle(
            fontSize: 13,
            color: Colors.black45,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        if (_filteredGames.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Column(
                children: [
                  Icon(
                    Icons.sports_score_rounded,
                    size: 48,
                    color: Colors.black26,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'No games yet',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: Colors.black45,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Use Quick Start above or create a tournament.',
                    style: TextStyle(color: Colors.black38, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
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
    );
  }
}
