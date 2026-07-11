import 'package:flutter/material.dart';
import '../app/app_colors.dart';
import '../l10n/app_localizations.dart';
import '../models/scramble_tournament.dart';

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

  const ScrambleGameTile({
    super.key,
    required this.game,
    required this.round,
    required this.tournament,
    this.onTap,
    this.onExport,
    this.onImportResult,
  });

  @override
  Widget build(BuildContext context) {
    final teamA = game.sideAPlayerIds
        .map((id) => tournament.getPlayer(id)?.name ?? id)
        .join(' & ');
    final teamB = game.sideBPlayerIds
        .map((id) => tournament.getPlayer(id)?.name ?? id)
        .join(' & ');

    // Game status is shown on the round header now; the card only carries the
    // export/import action, which exists for not-yet-started games.
    final showMenu = game.status == ScrambleGameStatus.scheduled &&
        (onExport != null || onImportResult != null);

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
            children: [
              // Court badge
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
              const SizedBox(width: 12),
              // Teams + score
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _teamRow(teamA, game.sideAScore, game.winningSide == 'A'),
                    const SizedBox(height: 2),
                    _teamRow(teamB, game.sideBScore, game.winningSide == 'B'),
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
                    // Bottom line: referee only.
                    Row(
                      children: [
                        const Icon(Icons.gavel_rounded,
                            size: 9, color: Colors.blueGrey),
                        const SizedBox(width: 2),
                        Flexible(
                          child: Text(
                            game.arbitratorId != null
                                ? '${tournament.getPlayer(game.arbitratorId!)?.name ?? ''} refs'
                                : 'Assign ref manually',
                            style: const TextStyle(
                                fontSize: 10, color: Colors.blueGrey),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Export/import action on the card's right edge — a comfortable
              // tap target. The slot is always reserved (even when empty) so the
              // team/score rows keep an identical width on every card.
              const SizedBox(width: 4),
              SizedBox(
                width: 36,
                height: 36,
                child: showMenu ? _buildMenu(context) : null,
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
      icon: const Icon(Icons.more_vert, size: 20, color: Colors.black45),
      padding: EdgeInsets.zero,
      tooltip: '',
      onSelected: (v) {
        if (v == 'export') onExport?.call();
        if (v == 'import') onImportResult?.call();
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
      ],
    );
  }

  Widget _teamRow(String name, int score, bool isWinner) {
    return Row(
      children: [
        if (isWinner)
          const Padding(
            padding: EdgeInsets.only(right: 4),
            child: Icon(Icons.emoji_events_rounded,
                size: 12, color: AppColors.goldDark),
          ),
        Expanded(
          child: Text(
            name,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: Colors.black87,
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
