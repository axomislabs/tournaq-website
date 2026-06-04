import 'package:flutter/material.dart';
import '../app/app_colors.dart';
import '../l10n/app_localizations.dart';
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

  Widget _buildSubtitle(AppLocalizations l10n) {
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
      final statusLabel = game.isMatchComplete ? l10n.gameStatusCompleted : l10n.gameStatusInProgress;
      final winnerTeamId = game.effectiveWinnerTeamId;
      final winnerName = winnerTeamId != null
          ? appState.getTeamById(winnerTeamId)?.name
          : null;
      final winnerColor = winnerTeamId == game.team1Id ? AppColors.goldDark : AppColors.olive;
      rows.add(Row(
        children: [
          Flexible(child: Text(l10n.gameTileMatch(statusLabel), style: metaStyle)),
          if (winnerName != null) ...[
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                l10n.gameTileWinner(winnerName),
                style: metaStyle.copyWith(
                  color: winnerColor,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.end,
              ),
            ),
          ],
        ],
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
      ));
    } else {
      // Legacy GameResult path
      final score = game.result != null
          ? '${game.result!.score1} – ${game.result!.score2}'
          : l10n.gameStatusPending;
      rows.add(Text(score, style: const TextStyle(fontSize: 13)));
      final legacyWinner = game.result?.winnerTeamId != null
          ? appState.getTeamById(game.result!.winnerTeamId!)?.name
          : null;
      if (legacyWinner != null) {
        rows.add(Text(l10n.gameTileWinner(legacyWinner), style: metaStyle));
      }
    }

    return Padding(
      padding: const EdgeInsets.only(top: 2, bottom: 4),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: rows),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
                child: Text(
                  l10n.gameTileQuick,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.gold,
                  ),
                ),
              ),
          ],
        ),
        subtitle: _buildSubtitle(l10n),
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
            actionMenuItem('score', Icons.score_rounded, l10n.menuGameScorecard),
            if (onDeleteTap != null) ...[
              const PopupMenuDivider(),
              actionMenuItem('delete', Icons.delete_outline, l10n.btnDeleteGame, destructive: true),
            ],
          ],
        ),
      ),
    );
  }
}
