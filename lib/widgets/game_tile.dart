import 'package:flutter/material.dart';

import '../models/game.dart';
import '../state/app_state.dart';

class GameTile extends StatelessWidget {
  final Game game;
  final AppState appState;
  final VoidCallback? onScoreTap;

  const GameTile({
    super.key,
    required this.game,
    required this.appState,
    this.onScoreTap,
  });

  @override
  Widget build(BuildContext context) {
    final team1 = appState.getTeamById(game.team1Id);
    final team2 = appState.getTeamById(game.team2Id);
    final team1Name = team1?.name ?? 'Unknown';
    final team2Name = team2?.name ?? 'Unknown';
    final resultText = game.result != null
        ? '${game.result!.score1} - ${game.result!.score2}'
        : 'Pending';
    final winnerText = game.result?.winnerTeamId != null
        ? 'Winner: ${appState.getTeamById(game.result!.winnerTeamId!)?.name ?? 'Unknown'}'
        : null;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        title: Text('$team1Name vs $team2Name'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(resultText),
            if (winnerText != null) Text(winnerText),
            Text('Round ${game.round} • ${game.status.name}'),
          ],
        ),
        onTap: onScoreTap,
        trailing: IconButton(
          icon: const Icon(Icons.score),
          onPressed: onScoreTap,
          tooltip: 'Score this game',
        ),
      ),
    );
  }
}
