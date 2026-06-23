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
                    const SizedBox(height: 4),
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
