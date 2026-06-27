import 'package:flutter/material.dart';
import '../app/app_colors.dart';
import '../models/player_status.dart';
import '../models/scramble_tournament.dart';
import '../services/scramble_service.dart';
import '../widgets/scrollable_page.dart';
import '../widgets/tournaq_app_bar.dart';

/// Individual player rankings for a Timed Scramble tournament.
class ScrambleStatsPage extends StatelessWidget {
  final ScrambleTournament tournament;

  const ScrambleStatsPage({super.key, required this.tournament});

  @override
  Widget build(BuildContext context) {
    final stats = ScrambleService.computeStats(tournament);
    final completed = tournament.completedGames;
    final total = tournament.totalGames;

    return Scaffold(
      appBar: TournaQAppBar(title: 'Player Rankings'),
      body: ScrollablePage(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildProgressHeader(completed, total),
            const SizedBox(height: 20),
            if (stats.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text(
                    'No completed games yet.\nRankings will appear here as games finish.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.black45, fontSize: 14),
                  ),
                ),
              )
            else ...[
              Builder(builder: (ctx) {
                final portrait = MediaQuery.orientationOf(ctx) ==
                    Orientation.portrait;
                return Column(
                  children: [
                    _buildTableHeader(portrait),
                    ...stats.map((s) => _buildPlayerRow(s, stats.first, portrait)),
                  ],
                );
              }),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProgressHeader(int completed, int total) {
    final pct = total == 0 ? 0.0 : completed / total;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.oliveLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tournament.name,
            style: const TextStyle(
                fontWeight: FontWeight.w800, fontSize: 16),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: pct,
                    minHeight: 6,
                    backgroundColor: Colors.white,
                    valueColor:
                        const AlwaysStoppedAnimation(AppColors.olive),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '$completed/$total games',
                style: const TextStyle(
                    fontSize: 12, color: Colors.black54),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader(bool portrait) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.olive,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const SizedBox(width: 28, child: Text('#', style: _headerStyle)),
          const SizedBox(width: 8),
          const Expanded(child: Text('Player', style: _headerStyle)),
          const _StatHeader('RP'),
          const _StatHeader('W'),
          const _StatHeader('D'),
          const _StatHeader('L'),
          if (!portrait) const _StatHeader('Pts'),
          const _StatHeader('+/-'),
          if (!portrait) const _StatHeader('G'),
        ],
      ),
    );
  }

  Widget _buildPlayerRow(ScramblePlayerStats s, ScramblePlayerStats leader, bool portrait) {
    final isLeader = s.rank == 1;
    final rowBg = isLeader ? AppColors.goldCream : Colors.white;
    final rankColor = isLeader ? AppColors.goldDark : Colors.black45;

    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: rowBg,
        borderRadius: BorderRadius.circular(10),
        border: isLeader
            ? Border.all(color: AppColors.comingSoonBorder)
            : Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: isLeader
                ? const Icon(Icons.emoji_events_rounded,
                    size: 16, color: AppColors.goldDark)
                : Text(
                    '${s.rank}',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: rankColor),
                  ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    s.playerName,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isLeader ? FontWeight.w800 : FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (s.status != PlayerStatus.active) ...[
                  const SizedBox(width: 4),
                  _statusBadge(s.status),
                ],
              ],
            ),
          ),
          _statCell('${s.rankingPoints}',
              isLeader ? AppColors.goldDark : Colors.black87, true),
          _statCell('${s.wins}', AppColors.olive),
          _statCell('${s.draws}'),
          _statCell('${s.losses}', Colors.red.shade400),
          if (!portrait) _statCell('${s.totalPoints}'),
          _statCell(
            '${s.pointDifference >= 0 ? '+' : ''}${s.pointDifference}',
            s.pointDifference >= 0 ? AppColors.olive : Colors.red.shade400,
          ),
          if (!portrait) _statCell('${s.gamesPlayed}'),
        ],
      ),
    );
  }

  Widget _statusBadge(PlayerStatus status) {
    final (label, color) = switch (status) {
      PlayerStatus.ejected => ('OUT', Colors.red.shade400),
      PlayerStatus.swappedOut => ('SUB−', Colors.orange.shade600),
      PlayerStatus.swappedIn => ('SUB+', AppColors.olive),
      PlayerStatus.late => ('LATE', Colors.blue.shade400),
      PlayerStatus.active => ('', Colors.transparent),
    };
    if (label.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: 0.3)),
    );
  }

  Widget _statCell(String text,
      [Color color = Colors.black54, bool bold = false]) =>
      SizedBox(
        width: 36,
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            color: color,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      );

  static const _headerStyle = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    color: Colors.white,
    letterSpacing: 0.5,
  );
}

class _StatHeader extends StatelessWidget {
  final String label;
  const _StatHeader(this.label);

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 36,
        child: Text(label,
            textAlign: TextAlign.center,
            style: ScrambleStatsPage._headerStyle),
      );
}
