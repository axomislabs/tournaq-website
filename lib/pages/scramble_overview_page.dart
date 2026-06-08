import 'package:flutter/material.dart';
import '../app/app_colors.dart';
import '../models/scramble_tournament.dart';
import '../services/scramble_service.dart';
import '../services/scramble_storage_service.dart';
import '../widgets/scramble_game_tile.dart';
import '../widgets/scrollable_page.dart';
import '../widgets/tournaq_app_bar.dart';
import 'scramble_scorecard_page.dart';
import 'scramble_stats_page.dart';

/// Shows the full schedule of a Timed Scramble tournament:
/// rounds, court assignments, times, player participation, and progress.
class ScrambleOverviewPage extends StatefulWidget {
  final ScrambleTournament tournament;
  final void Function(ScrambleTournament) onChanged;

  const ScrambleOverviewPage({
    super.key,
    required this.tournament,
    required this.onChanged,
  });

  @override
  State<ScrambleOverviewPage> createState() => _ScrambleOverviewPageState();
}

class _ScrambleOverviewPageState extends State<ScrambleOverviewPage> {
  late ScrambleTournament _t;

  @override
  void initState() {
    super.initState();
    _t = widget.tournament;
  }

  void _update(ScrambleTournament updated) {
    setState(() => _t = updated);
    ScrambleStorageService.save(updated);
    widget.onChanged(updated);
  }

  Future<void> _openScorecard(ScrambleGame game) async {
    final round = _t.getRound(game.roundId);
    if (round == null) return;
    final updated = await Navigator.of(context).push<ScrambleTournament>(
      MaterialPageRoute(
        builder: (_) => ScrambleScorecardPage(
          tournament: _t,
          game: game,
          round: round,
          onChanged: _update,
        ),
      ),
    );
    if (updated != null) _update(updated);
  }

  void _openStats() {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ScrambleStatsPage(tournament: _t),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final completed = _t.completedGames;
    final total = _t.totalGames;
    final progress = _t.progressFraction;

    return Scaffold(
      appBar: TournaQAppBar(
        title: _t.name,
        actions: [
          IconButton(
            icon: const Icon(Icons.leaderboard_rounded,
                color: AppColors.goldLight),
            tooltip: 'Player Rankings',
            onPressed: _openStats,
          ),
        ],
      ),
      body: ScrollablePage(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(completed, total, progress),
            const SizedBox(height: 20),
            _buildPlayerGrid(),
            const SizedBox(height: 20),
            ..._buildRoundSections(),
          ],
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────

  Widget _buildHeader(int completed, int total, double progress) {
    final estFinish = _t.rounds.isNotEmpty
        ? _t.rounds.last.scheduledBreakEndTime
        : null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.oliveLight,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$completed / $total games completed',
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 15),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${_t.roundCount} rounds  ·  '
                      '${_t.courtCount} court${_t.courtCount > 1 ? 's' : ''}  ·  '
                      '${_t.playerCount} players',
                      style: const TextStyle(
                          fontSize: 12, color: Colors.black54),
                    ),
                    if (estFinish != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Est. finish: ${ScrambleService.formatTime(estFinish)}',
                        style: const TextStyle(
                            fontSize: 12, color: Colors.black54),
                      ),
                    ],
                  ],
                ),
              ),
              _buildProgressRing(progress),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: Colors.white,
              valueColor:
                  const AlwaysStoppedAnimation(AppColors.olive),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressRing(double progress) {
    return SizedBox(
      width: 52,
      height: 52,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: progress,
            strokeWidth: 5,
            backgroundColor: Colors.white,
            valueColor:
                const AlwaysStoppedAnimation(AppColors.olive),
          ),
          Text(
            '${(progress * 100).round()}%',
            style: const TextStyle(
                fontSize: 11, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  // ── Player Grid ──────────────────────────────────────────────────────────

  Widget _buildPlayerGrid() {
    final stats = ScrambleService.computeStats(_t);
    final statsById = {for (final s in stats) s.playerId: s};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Players',
            style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: Colors.black54)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: _t.players.map((p) {
            final s = statsById[p.id];
            return Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 10,
                    backgroundColor: AppColors.olive,
                    child: Text(
                      p.name.isNotEmpty ? p.name[0] : '?',
                      style: const TextStyle(
                          fontSize: 9,
                          color: Colors.white,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p.name,
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600)),
                      if (s != null)
                        Text(
                          '${s.gamesPlayed}g · ${s.totalPoints}pts',
                          style: const TextStyle(
                              fontSize: 10, color: Colors.black38),
                        ),
                    ],
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ── Rounds ────────────────────────────────────────────────────────────────

  List<Widget> _buildRoundSections() {
    return _t.rounds.map((round) {
      final games = _t.getGamesForRound(round.id);
      final allDone = games.isNotEmpty && games.every((g) => g.isCompleted);

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _roundHeader(round, allDone),
          const SizedBox(height: 6),
          ...games.map((g) => ScrambleGameTile(
                game: g,
                round: round,
                tournament: _t,
                onTap: () => _openScorecard(g),
              )),
          // Sitting-out players (attached to first game of the round).
          if (games.isNotEmpty &&
              games.first.sittingOutPlayerIds.isNotEmpty) ...[
            const SizedBox(height: 2),
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 4),
              child: Text(
                'Sitting out: ${games.first.sittingOutPlayerIds.map((id) => _t.getPlayer(id)?.name ?? id).join(', ')}',
                style: const TextStyle(fontSize: 11, color: Colors.black38),
              ),
            ),
          ],
          const SizedBox(height: 16),
        ],
      );
    }).toList();
  }

  Widget _roundHeader(ScrambleRound round, bool allDone) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: allDone ? AppColors.olive : AppColors.goldCream,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            'Round ${round.roundNumber}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: allDone ? Colors.white : AppColors.goldDark,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '${ScrambleService.formatTime(round.scheduledStartTime)} – '
          '${ScrambleService.formatTime(round.scheduledMatchEndTime)}',
          style: const TextStyle(fontSize: 12, color: Colors.black45),
        ),
        if (round.breakDuration > Duration.zero) ...[
          const SizedBox(width: 4),
          Text(
            '· Break until ${ScrambleService.formatTime(round.scheduledBreakEndTime)}',
            style: const TextStyle(fontSize: 11, color: Colors.black38),
          ),
        ],
      ],
    );
  }
}
