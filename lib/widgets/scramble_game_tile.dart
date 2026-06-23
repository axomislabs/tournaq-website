import 'package:flutter/material.dart';
import '../app/app_colors.dart';
import '../models/scramble_tournament.dart';

/// Compact card showing one [ScrambleGame] in the overview list.
class ScrambleGameTile extends StatelessWidget {
  final ScrambleGame game;
  final ScrambleRound round;
  final ScrambleTournament tournament;
  final VoidCallback? onTap;

  const ScrambleGameTile({
    super.key,
    required this.game,
    required this.round,
    required this.tournament,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final teamA = game.sideAPlayerIds
        .map((id) => tournament.getPlayer(id)?.name ?? id)
        .join(' & ');
    final teamB = game.sideBPlayerIds
        .map((id) => tournament.getPlayer(id)?.name ?? id)
        .join(' & ');

    final statusColor = switch (game.status) {
      ScrambleGameStatus.completed => AppColors.olive,
      ScrambleGameStatus.inProgress => AppColors.gold,
      ScrambleGameStatus.scheduled => Colors.black38,
    };

    final isComplete = game.status == ScrambleGameStatus.completed;
    final schedStart = round.scheduledStartTime;
    final schedEnd = round.scheduledMatchEndTime;
    Color? schedDotColor;
    String? schedLabel;
    if (!isComplete) {
      final now = DateTime.now();
      if (now.isAfter(schedEnd)) {
        schedDotColor = Colors.red.shade600;
        schedLabel = 'overdue';
      } else if (now.isAfter(schedStart)) {
        schedDotColor = Colors.amber.shade700;
        schedLabel = 'due';
      } else {
        schedDotColor = Colors.green.shade600;
        schedLabel = 'upcoming';
      }
    }

    final statusIcon = switch (game.status) {
      ScrambleGameStatus.completed => Icons.check_circle_rounded,
      ScrambleGameStatus.inProgress => Icons.sports_volleyball_rounded,
      ScrambleGameStatus.scheduled => Icons.schedule_rounded,
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
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (schedDotColor != null) ...[
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: schedDotColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                        ],
                        Text(
                          '${_fmtT(schedStart)} – ${_fmtT(schedEnd)}',
                          style: const TextStyle(
                              fontSize: 11, color: Colors.black38),
                        ),
                        if (schedLabel != null) ...[
                          const SizedBox(width: 4),
                          Text(
                            schedLabel,
                            style: TextStyle(
                                fontSize: 10, color: schedDotColor),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
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
              // Status icon
              Icon(statusIcon, size: 18, color: statusColor),
            ],
          ),
        ),
      ),
    );
  }

  static String _fmtT(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
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
