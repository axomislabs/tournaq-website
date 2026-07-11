import 'package:flutter/material.dart';
import '../app/app_colors.dart';
import '../l10n/app_localizations.dart';
import '../models/scramble_king_tournament.dart';
import '../services/scramble_king_service.dart';
import '../widgets/scrollable_page.dart';
import '../widgets/tournaq_app_bar.dart';

/// Individual player rankings for a Scramble King tournament — a table with
/// the same look and feel as the court scorecard's ranking table
/// (Player / Rounds / 🏆Wins / Pts columns, goldCream first-place highlight).
class ScrambleKingStatsPage extends StatelessWidget {
  final ScrambleKingTournament tournament;

  const ScrambleKingStatsPage({super.key, required this.tournament});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final stats = ScrambleKingService.computeStats(tournament);
    const headerStyle =
        TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.black45);

    return Scaffold(
      appBar: TournaQAppBar(title: l10n.scrambleKingOverallRanking),
      body: ScrollablePage(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (stats.every((s) => s.roundsPlayed == 0))
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text(
                    l10n.scrambleKingNoResultsYet,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.black45, fontSize: 14),
                  ),
                ),
              )
            else ...[
              // Header row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: Row(children: [
                  const SizedBox(width: 28),
                  Expanded(child: Text(l10n.filterPlayer, style: headerStyle)),
                  SizedBox(
                    width: 52,
                    child: Text(l10n.scrambleKingStatRounds,
                        textAlign: TextAlign.center, style: headerStyle),
                  ),
                  SizedBox(
                    width: 52,
                    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const Icon(Icons.emoji_events_rounded, size: 11, color: Colors.black45),
                      const SizedBox(width: 2),
                      Flexible(
                        child: Text(l10n.kotcStatWins,
                            style: headerStyle, overflow: TextOverflow.ellipsis, maxLines: 1),
                      ),
                    ]),
                  ),
                  SizedBox(
                    width: 44,
                    child: Text(l10n.kotcStatPts, textAlign: TextAlign.right, style: headerStyle),
                  ),
                ]),
              ),
              for (final s in stats)
                Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: s.rank == 1 ? AppColors.goldCream : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: s.rank == 1
                            ? AppColors.gold.withValues(alpha: 0.4)
                            : Colors.grey.shade200),
                  ),
                  child: Row(children: [
                    SizedBox(
                      width: 28,
                      child: Text('${s.rank}',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: s.rank == 1 ? AppColors.goldDark : Colors.black45)),
                    ),
                    Expanded(
                      child: Text(s.playerName,
                          style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: s.rank == 1 ? AppColors.goldDark : Colors.black87)),
                    ),
                    SizedBox(
                      width: 52,
                      child: Text('${s.roundsPlayed}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w700, color: Colors.black54)),
                    ),
                    SizedBox(
                      width: 52,
                      child: Text('${s.totalGamesWon}',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: s.totalGamesWon > 0 ? AppColors.goldDark : Colors.black38)),
                    ),
                    SizedBox(
                      width: 44,
                      child: Text('${s.totalPoints}',
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w700, color: Colors.black87)),
                    ),
                  ]),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
