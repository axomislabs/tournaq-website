import 'package:flutter/material.dart';

import '../models/game.dart';
import '../state/app_state.dart';
import 'assign_dialog.dart';

class GameTile extends StatelessWidget {
  final Game game;
  final AppState appState;
  final VoidCallback? onScoreTap;
  final VoidCallback? onDeleteTap;

  const GameTile({
    super.key,
    required this.game,
    required this.appState,
    this.onScoreTap,
    this.onDeleteTap,
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
    final isQuick = game.source == GameSource.quickLocal;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        title: Row(
          children: [
            Expanded(child: Text('$team1Name vs $team2Name')),
            if (isQuick)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8E1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFB0BA78)),
                ),
                child: const Text(
                  'Quick',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFB08B1E),
                  ),
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(resultText),
            if (winnerText != null) Text(winnerText),
            Text('Round ${game.round} • ${game.status.name}'),
          ],
        ),
        onTap: onScoreTap,
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, size: 20),
          onSelected: (value) {
            switch (value) {
              case 'score':
                onScoreTap?.call();
              case 'delete':
                onDeleteTap?.call();
            }
          },
          itemBuilder: (_) => [
            actionMenuItem('score', Icons.score_rounded, 'Score Game'),
            if (onDeleteTap != null) ...[
              const PopupMenuDivider(),
              actionMenuItem('delete', Icons.delete_outline, 'Delete Game', destructive: true),
            ],
          ],
        ),
      ),
    );
  }
}
