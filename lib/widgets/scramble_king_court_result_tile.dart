import 'package:flutter/material.dart';
import '../app/app_colors.dart';
import '../l10n/app_localizations.dart';
import '../models/scramble_king_tournament.dart';
import '../services/scramble_king_service.dart';

/// Near-literal clone of [ScrambleGameTile] — same Card shape, court badge,
/// and status-icon logic — generalized to show a ranked list of N teams
/// instead of a fixed 2-sided score, plus a floater badge reusing the exact
/// "referee row" visual slot from ScrambleGameTile.
class ScrambleKingCourtResultTile extends StatelessWidget {
  final ScrambleKingTournament tournament;
  final ScrambleKingRound round;
  final ScrambleKingCourtFormation formation;
  final VoidCallback? onTap;

  const ScrambleKingCourtResultTile({
    super.key,
    required this.tournament,
    required this.round,
    required this.formation,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final result = ScrambleKingService.computeCourtRoundResult(
        tournament, round.id, formation.courtNumber);

    String nameFor(String id) => tournament.getPlayer(id)?.name ?? id;
    String? teamNameFor(String slotId) {
      if (slotId == formation.floaterSlot?.slotId) return formation.floaterSlot!.teamName;
      return formation.teamSlots
          .cast<ScrambleKingTeamSlot?>()
          .firstWhere((s) => s?.slotId == slotId, orElse: () => null)
          ?.teamName;
    }

    final statusColor = switch ((formation.isCompleted, round.isCompleted)) {
      (true, _) => AppColors.olive,
      (false, false) when formation.actualStartTime != null => AppColors.gold,
      _ => Colors.black38,
    };
    final statusIcon = switch ((formation.isCompleted, formation.actualStartTime != null)) {
      (true, _) => Icons.check_circle_rounded,
      (false, true) => Icons.sports_volleyball_rounded,
      (false, false) => Icons.schedule_rounded,
    };

    // Pace dot (only when enabled and this court hasn't finished), computed
    // from the round schedule — same treatment as ScrambleGameTile.
    Color? paceDotColor;
    String? paceLabel;
    if (tournament.paceAlertsEnabled && !formation.isCompleted) {
      final now = DateTime.now();
      if (now.isAfter(round.scheduledMatchEndTime)) {
        paceDotColor = Colors.red.shade600;
        paceLabel = l10n.statusOverdue;
      } else if (now.isAfter(round.scheduledStartTime)) {
        paceDotColor = Colors.amber.shade700;
        paceLabel = l10n.statusDue;
      } else {
        paceDotColor = Colors.green.shade600;
        paceLabel = l10n.statusUpcoming;
      }
    }

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
                    Text(l10n.scrambleKingCourtLabel,
                        style: const TextStyle(
                            fontSize: 7, color: AppColors.olive, fontWeight: FontWeight.w400)),
                    Text('${formation.courtNumber}',
                        style: const TextStyle(
                            fontSize: 16,
                            color: AppColors.olive,
                            fontWeight: FontWeight.w400,
                            height: 1)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Teams + scores
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final team in result.teamResults)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 3),
                        child: _teamRow(
                          teamNameFor(team.slotId) ?? team.playerIds.map(nameFor).join(' & '),
                          team.playerIds.map(nameFor).join(' & '),
                          team.points,
                          team.rank == 1,
                        ),
                      ),
                    if (paceDotColor != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(color: paceDotColor, shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 4),
                          Text(paceLabel ?? '',
                              style: TextStyle(fontSize: 10, color: paceDotColor)),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              Icon(statusIcon, size: 18, color: statusColor),
            ],
          ),
        ),
      ),
    );
  }

  Widget _teamRow(String teamName, String players, int score, bool isWinner) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (isWinner)
          const Padding(
            padding: EdgeInsets.only(right: 4, top: 1),
            child: Icon(Icons.emoji_events_rounded, size: 12, color: AppColors.goldDark),
          ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                teamName,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isWinner ? AppColors.goldDark : Colors.black87,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                players,
                style: const TextStyle(fontSize: 11, color: Colors.black45),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '$score',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isWinner ? AppColors.goldDark : Colors.black38,
          ),
        ),
      ],
    );
  }
}
