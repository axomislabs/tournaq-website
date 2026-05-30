import 'package:flutter/material.dart';
import '../app/app_colors.dart';

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

  static const _dot = TextSpan(
    text: '● ',
    style: TextStyle(color: AppColors.inverseSurface, fontWeight: FontWeight.w700, fontSize: 12),
  );

  Widget _buildSubtitle() {
    final rows = <Widget>[];
    const metaStyle = TextStyle(fontSize: 12, color: Colors.black54);

    if (game.sets.isNotEmpty) {
      for (int i = 0; i < game.maxSets; i++) {
        if (i < game.sets.length) {
          final s = game.sets[i];
          final hasScore = s.score1 > 0 || s.score2 > 0 || s.isCompleted;
          final scoreStr = hasScore ? '${s.score1}–${s.score2}' : '–';
          rows.add(Text.rich(TextSpan(children: [
            if (s.isCompleted) _dot,
            TextSpan(text: 'Set ${s.setNumber}: $scoreStr'),
          ]), style: const TextStyle(fontSize: 13)));
        } else {
          rows.add(Text('Set ${i + 1}: –', style: const TextStyle(fontSize: 13)));
        }
      }
      // Match status
      if (game.matchWinnerTeamId != null) {
        final wName = appState.getTeamById(game.matchWinnerTeamId!)?.name ?? 'Unknown';
        rows.add(Text('Winner: $wName', style: metaStyle));
      }
      final statusLabel = game.isMatchComplete ? 'Completed' : 'In Progress';
      rows.add(Text('Match: $statusLabel', style: metaStyle));
    } else {
      // Legacy GameResult path
      final score = game.result != null
          ? '${game.result!.score1} – ${game.result!.score2}'
          : 'Pending';
      rows.add(Text(score, style: const TextStyle(fontSize: 13)));
      if (game.result?.winnerTeamId != null) {
        final wName = appState.getTeamById(game.result!.winnerTeamId!)?.name ?? 'Unknown';
        rows.add(Text('Winner: $wName', style: metaStyle));
      }
    }

    return Padding(
      padding: const EdgeInsets.only(top: 2, bottom: 4),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: rows),
    );
  }

  @override
  Widget build(BuildContext context) {
    final team1Name = appState.getTeamById(game.team1Id)?.name ?? 'Unknown';
    final team2Name = appState.getTeamById(game.team2Id)?.name ?? 'Unknown';
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
                  color: AppColors.goldCream,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.comingSoonBorder),
                ),
                child: const Text(
                  'Quick',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.gold,
                  ),
                ),
              ),
          ],
        ),
        subtitle: _buildSubtitle(),
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
            actionMenuItem('score', Icons.score_rounded, 'Game Scorecard'),
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
