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

  /// Hand this court off to a referee device via QR (not-yet-started courts).
  final VoidCallback? onExport;

  /// Scan a played result back onto this court (not-yet-started courts).
  final VoidCallback? onImportResult;

  /// Set the court's final result manually without playing it.
  final VoidCallback? onManualScore;

  const ScrambleKingCourtResultTile({
    super.key,
    required this.tournament,
    required this.round,
    required this.formation,
    this.onTap,
    this.onExport,
    this.onImportResult,
    this.onManualScore,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final result = ScrambleKingService.computeCourtRoundResult(
      tournament,
      round.id,
      formation.courtNumber,
    );

    String nameFor(String id) => tournament.getPlayer(id)?.name ?? id;
    String? teamNameFor(String slotId) {
      if (slotId == formation.floaterSlot?.slotId) {
        return formation.floaterSlot!.teamName;
      }
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
    final statusIcon = switch ((
      formation.isCompleted,
      formation.actualStartTime != null,
    )) {
      (true, _) => Icons.check_circle_rounded,
      (false, true) => Icons.sports_volleyball_rounded,
      (false, false) => Icons.schedule_rounded,
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
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Court badge at top; the QR menu (not-yet-started courts) is
                // centered in the free space beneath it, not crammed directly
                // under the badge.
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
                          Text(
                            l10n.scrambleKingCourtLabel,
                            style: const TextStyle(
                              fontSize: 7,
                              color: AppColors.olive,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          Text(
                            '${formation.courtNumber}',
                            style: const TextStyle(
                              fontSize: 16,
                              color: AppColors.olive,
                              fontWeight: FontWeight.w400,
                              height: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_showMenu)
                      Expanded(
                        child: Center(
                          child: SizedBox(
                            width: 30,
                            height: 30,
                            child: _buildMenu(context, l10n),
                          ),
                        ),
                      ),
                  ],
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
                            teamNameFor(team.slotId) ??
                                team.playerIds.map(nameFor).join(' & '),
                            team.playerIds.map(nameFor).join(' & '),
                            team.points,
                            // Only crown a winner once the court is finished —
                            // otherwise every not-yet-played court shows a
                            // trophy on whichever team happens to rank first.
                            team.rank == 1 && formation.isCompleted,
                          ),
                        ),
                      // Bottom line mirroring ScrambleGameTile's referee row:
                      // Scramble King has no fixed referee, so the closest analog
                      // — how the court is run (assignment mode) — fills the slot,
                      // with the status icon flush right.
                      Row(
                        children: [
                          const Icon(
                            Icons.tune_rounded,
                            size: 9,
                            color: Colors.blueGrey,
                          ),
                          const SizedBox(width: 2),
                          Expanded(
                            child: Text(
                              _assignmentModeLabel(l10n),
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.blueGrey,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
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
      ),
    );
  }

  /// The QR/manual action menu is available only before the court is played.
  bool get _showMenu =>
      formation.actualStartTime == null &&
      (onExport != null || onImportResult != null || onManualScore != null);

  Widget _buildMenu(BuildContext context, AppLocalizations l10n) {
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
                const Icon(
                  Icons.qr_code_rounded,
                  size: 18,
                  color: AppColors.olive,
                ),
                const SizedBox(width: 8),
                Text(l10n.scrambleKingExportCourt),
              ],
            ),
          ),
        if (onImportResult != null)
          PopupMenuItem(
            value: 'import',
            child: Row(
              children: [
                const Icon(
                  Icons.qr_code_scanner_rounded,
                  size: 18,
                  color: AppColors.olive,
                ),
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
                const Icon(
                  Icons.edit_rounded,
                  size: 18,
                  color: AppColors.olive,
                ),
                const SizedBox(width: 8),
                Text(l10n.scorecardManualScore),
              ],
            ),
          ),
      ],
    );
  }

  String _assignmentModeLabel(
    AppLocalizations l10n,
  ) => switch (tournament.assignmentMode) {
    ScrambleKingAssignmentMode.manual => l10n.doghouseAssignmentManual,
    ScrambleKingAssignmentMode.automated => l10n.doghouseAssignmentAutomated,
    ScrambleKingAssignmentMode.automatedAllPlay => l10n.setupFormatAutoAllplay,
  };

  /// One team's row. Player names lead (primary line), with the fun team name
  /// below in smaller type — the emphasis and exact font sizes mirror
  /// [ScrambleGameTile]: players at 13/w400/black87, team name at 11/w600/
  /// black45, score at 15/w400 (gold when this team leads).
  Widget _teamRow(String teamName, String players, int score, bool isWinner) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (isWinner)
          const Padding(
            padding: EdgeInsets.only(right: 4, top: 1),
            child: Icon(
              Icons.emoji_events_rounded,
              size: 12,
              color: AppColors.goldDark,
            ),
          ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                players,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: Colors.black87,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                teamName,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.black45,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
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
