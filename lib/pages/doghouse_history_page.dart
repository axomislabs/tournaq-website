import 'package:flutter/material.dart';
import '../app/app_colors.dart';
import '../l10n/app_localizations.dart';
import '../models/doghouse_drill.dart';
import '../widgets/tournaq_app_bar.dart';

const _kGold      = AppColors.goldDark;
const _kGoldLight = AppColors.goldCream;
const _kGoldCardBg = AppColors.goldCardBg;
const _kOlive      = AppColors.olive;
const _kOliveLight = AppColors.oliveLight;

class DoghouseHistoryPage extends StatelessWidget {
  final DoghouseTournament tournament;

  const DoghouseHistoryPage({super.key, required this.tournament});

  @override
  Widget build(BuildContext context) {
    final games = tournament.games.reversed.toList();

    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: TournaQAppBar(
          title: l10n.doghouseTitle, subtitle: l10n.doghouseGameHistory),
      body: Column(
        children: [
          _buildSummaryBar(l10n),
          const Divider(height: 1),
          Expanded(
            child: games.isEmpty
                ? _buildEmpty(l10n)
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                    itemCount: games.length,
                    itemBuilder: (_, i) =>
                        _buildGameCard(l10n, games[i], games.length - i),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryBar(AppLocalizations l10n) {
    return Container(
      color: Colors.grey.shade50,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(children: [
        _chip(Icons.pets_rounded, tournament.name, _kOliveLight, _kOlive),
        const SizedBox(width: 8),
        _chip(Icons.sports_rounded,
            l10n.doghouseStatsGames(tournament.gameCount),
            _kGoldLight, _kGold),
        const SizedBox(width: 8),
        _chip(Icons.celebration_rounded,
            l10n.doghouseStatsEscapes(tournament.totalEscapes),
            Colors.grey.shade100, Colors.black54),
      ]),
    );
  }

  Widget _buildGameCard(AppLocalizations l10n, DoghouseGame game, int number) {
    final escaped  = game.gamesWon > 0;
    final duration = game.endTime?.difference(game.startTime);
    final durStr   = duration != null
        ? '${duration.inMinutes}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}'
        : null;

    final gamePlayers = game.playerIds
        .map((id) => tournament.players.firstWhere(
              (p) => p.id == id,
              orElse: () => DoghousePlayer(
                  id: id, name: '?', source: DoghousePlayerSource.random),
            ))
        .toList();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: escaped ? _kGoldCardBg : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: escaped
              ? _kGold.withValues(alpha: 0.5)
              : Colors.grey.shade200,
          width: escaped ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Game number badge
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: escaped ? _kGold : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  '$number',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: escaped ? Colors.white : Colors.black45,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Player names + duration
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: gamePlayers
                        .map((p) => Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: escaped
                                        ? _kGold.withValues(alpha: 0.12)
                                        : Colors.grey.shade100,
                                    borderRadius:
                                        BorderRadius.circular(12),
                                  ),
                                  child: Text(p.name,
                                      style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: escaped
                                              ? _kGold
                                              : Colors.black87)),
                                ),
                                if (p.isLate) ...[
                                  const SizedBox(width: 3),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 4, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.shade100,
                                      borderRadius:
                                          BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      l10n.labelLate,
                                      style: TextStyle(
                                        fontSize: 8,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.orange.shade700,
                                        letterSpacing: 0.4,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ))
                        .toList(),
                  ),
                  if (durStr != null) ...[
                    const SizedBox(height: 4),
                    Row(children: [
                      Icon(Icons.timer_rounded,
                          size: 11, color: Colors.black38),
                      const SizedBox(width: 3),
                      Text(durStr,
                          style: const TextStyle(
                              fontSize: 11, color: Colors.black38)),
                    ]),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),

            // Side-outs + result badge
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${game.points}',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    height: 1.0,
                    color: escaped ? _kGold : Colors.black87,
                  ),
                ),
                Text(
                  l10n.statPts,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: escaped ? _kGold : Colors.black38,
                  ),
                ),
                const SizedBox(height: 4),
                if (escaped)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: _kGold,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.celebration_rounded,
                            size: 10, color: Colors.white),
                        const SizedBox(width: 2),
                        Text(l10n.doghouseEscaped,
                            style: const TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: Colors.white)),
                      ],
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.sentiment_very_dissatisfied_rounded,
                            size: 10, color: Colors.red.shade500),
                        const SizedBox(width: 2),
                        Text(l10n.doghouseNGamesLost(game.gamesLost),
                            style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: Colors.red.shade500)),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty(AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.history_rounded,
              size: 52, color: Colors.grey.shade300),
          const SizedBox(height: 14),
          Text(l10n.doghouseNoGamesYet,
              style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black45,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(l10n.doghouseNoGamesYetBody,
              style: const TextStyle(fontSize: 13, color: Colors.black38)),
        ],
      ),
    );
  }

  Widget _chip(IconData icon, String label, Color bg, Color fg) =>
      Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
            color: bg, borderRadius: BorderRadius.circular(20)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 11, color: fg),
          const SizedBox(width: 3),
          Text(label,
              style: TextStyle(
                  fontSize: 11,
                  color: fg,
                  fontWeight: FontWeight.w600)),
        ]),
      );
}
