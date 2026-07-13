import 'package:flutter/material.dart';
import '../app/app_colors.dart';
import '../l10n/app_localizations.dart';
import '../models/scramble_tournament.dart';
import '../utils/scramble_names.dart';

/// Compact card showing one [ScrambleGame] in the overview list.
class ScrambleGameTile extends StatelessWidget {
  final ScrambleGame game;
  final ScrambleRound round;
  final ScrambleTournament tournament;
  final VoidCallback? onTap;

  /// Export this game to another device via QR (scheduled games only).
  final VoidCallback? onExport;

  /// Scan a completed result back onto this game (scheduled games only).
  final VoidCallback? onImportResult;

  /// Manually set the final score and complete this game without opening
  /// the scorecard (scheduled games only).
  final VoidCallback? onManualScore;

  const ScrambleGameTile({
    super.key,
    required this.game,
    required this.round,
    required this.tournament,
    this.onTap,
    this.onExport,
    this.onImportResult,
    this.onManualScore,
  });

  @override
  Widget build(BuildContext context) {
    // Export/import/manual-score actions exist for not-yet-started games.
    final showMenu = game.status == ScrambleGameStatus.scheduled &&
        (onExport != null || onImportResult != null || onManualScore != null);

    // Per-game status, trailing on the referee line — the round header shows
    // this too, but with multiple courts per round that's not enough to tell
    // which specific game is running/done at a glance. Same icon+colour
    // language as the round header, just one level more granular.
    final (statusIcon, statusColor) = switch (game.status) {
      ScrambleGameStatus.completed => (
          Icons.check_circle_rounded,
          AppColors.olive,
        ),
      ScrambleGameStatus.inProgress => (
          Icons.sports_volleyball_rounded,
          AppColors.gold,
        ),
      ScrambleGameStatus.scheduled => (Icons.schedule_rounded, Colors.black38),
    };

    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Court badge, with the export/import QR action stacked right
              // below it — the card is naturally taller than the 38px badge
              // (two team rows + a referee line), so this uses that leftover
              // space instead of squeezing the name/score rows.
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.oliveLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Court',
                            style: TextStyle(
                                fontSize: 7,
                                color: AppColors.olive,
                                fontWeight: FontWeight.w400)),
                        Text('${game.courtNumber}',
                            style: const TextStyle(
                                fontSize: 16,
                                color: AppColors.olive,
                                fontWeight: FontWeight.w400,
                                height: 1)),
                      ],
                    ),
                  ),
                  if (showMenu) ...[
                    const SizedBox(height: 6),
                    SizedBox(
                        width: 30, height: 30, child: _buildMenu(context)),
                  ],
                ],
              ),
              const SizedBox(width: 12),
              // Teams + score — full card width.
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _teamRow(context, game.sideAPlayerIds, game.sideAScore,
                        game.winningSide == 'A'),
                    const SizedBox(height: 2),
                    _teamRow(context, game.sideBPlayerIds, game.sideBScore,
                        game.winningSide == 'B'),
                    if (game.teamNameA != null && game.teamNameB != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        '${game.teamNameA} vs ${game.teamNameB}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.black45,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(Icons.gavel_rounded,
                            size: 9, color: Colors.blueGrey),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            game.arbitratorId != null
                                ? '${tournament.getPlayer(game.arbitratorId!)?.name ?? ''} refs'
                                : 'Assign ref manually',
                            style: const TextStyle(
                                fontSize: 10, color: Colors.blueGrey),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // Expanded above soaks up the slack so this always
                        // sits flush right, aligned under the score column.
                        const SizedBox(width: 4),
                        Icon(statusIcon, size: 14, color: statusColor),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenu(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return PopupMenuButton<String>(
      icon: const Icon(Icons.qr_code_rounded, size: 20, color: Colors.black45),
      padding: EdgeInsets.zero,
      tooltip: '',
      onSelected: (v) {
        if (v == 'export') onExport?.call();
        if (v == 'import') onImportResult?.call();
        if (v == 'score') onManualScore?.call();
      },
      itemBuilder: (ctx) => [
        if (onExport != null)
          PopupMenuItem(
            value: 'export',
            child: Row(
              children: [
                const Icon(Icons.qr_code_rounded,
                    size: 18, color: AppColors.olive),
                const SizedBox(width: 8),
                Text(l10n.scrambleExportGame),
              ],
            ),
          ),
        if (onImportResult != null)
          PopupMenuItem(
            value: 'import',
            child: Row(
              children: [
                const Icon(Icons.qr_code_scanner_rounded,
                    size: 18, color: AppColors.olive),
                const SizedBox(width: 8),
                Text(l10n.scrambleImportResult),
              ],
            ),
          ),
        if (onManualScore != null)
          PopupMenuItem(
            value: 'score',
            child: Row(
              children: [
                const Icon(Icons.edit_rounded,
                    size: 18, color: AppColors.olive),
                const SizedBox(width: 8),
                Text(l10n.scorecardManualScore),
              ],
            ),
          ),
      ],
    );
  }

  Widget _teamRow(
    BuildContext context,
    List<String> playerIds,
    int score,
    bool isWinner,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final spans = <InlineSpan>[];
    for (var i = 0; i < playerIds.length; i++) {
      if (i > 0) spans.add(const TextSpan(text: ' & '));
      final id = playerIds[i];
      final isPlaceholder = ScrambleGame.isPlaceholder(id);
      spans.add(TextSpan(
        text: scramblePlayerLabel(tournament, id, l10n),
        style: isPlaceholder
            ? const TextStyle(
                fontStyle: FontStyle.italic, color: Colors.black45)
            : null,
      ));
    }
    return Row(
      children: [
        if (isWinner)
          const Padding(
            padding: EdgeInsets.only(right: 4),
            child: Icon(Icons.emoji_events_rounded,
                size: 12, color: AppColors.goldDark),
          ),
        Expanded(
          child: Text.rich(
            TextSpan(
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: Colors.black87,
              ),
              children: spans,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Text(
          '$score',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w400,
            color: isWinner ? AppColors.goldDark : Colors.black38,
          ),
        ),
      ],
    );
  }
}
