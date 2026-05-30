import 'package:flutter/material.dart';
import '../app/app_colors.dart';
import '../widgets/tournaq_app_bar.dart';

const _kGold = AppColors.goldDark;
const _kGoldCardBg = AppColors.goldCardBg;
const _kOlive = AppColors.olive;
const _kOliveCardBg = AppColors.oliveCardBg;

class GameHistoryEntry {
  final bool isTeam1Score;
  final int team1Score;
  final int team2Score;
  final int setIndex;
  final int targetPoints;
  final bool isTeam1Serving;
  final int servingPlayerIndex; // 0 or 1 within the serving team
  final bool serviceChanged;

  const GameHistoryEntry({
    required this.isTeam1Score,
    required this.team1Score,
    required this.team2Score,
    required this.setIndex,
    required this.targetPoints,
    required this.isTeam1Serving,
    required this.servingPlayerIndex,
    required this.serviceChanged,
  });
}

class GameplayHistoryPage extends StatelessWidget {
  final String team1Name;
  final String team2Name;
  final List<String> team1Players;
  final List<String> team2Players;
  final List<GameHistoryEntry> entries;

  const GameplayHistoryPage({
    super.key,
    required this.team1Name,
    required this.team2Name,
    required this.team1Players,
    required this.team2Players,
    required this.entries,
  });

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) return _buildEmpty(context);

    // Group entries by set
    final sets = <int, List<GameHistoryEntry>>{};
    for (final e in entries) {
      sets.putIfAbsent(e.setIndex, () => []).add(e);
    }
    final setIndices = sets.keys.toList()..sort();

    // Flatten into a widget list for efficient ListView
    final rows = <Widget>[];
    for (final si in setIndices) {
      final setEntries = sets[si]!;
      rows.add(_buildSetHeader(si, setEntries.last.targetPoints));
      rows.addAll(setEntries.map(_buildRow));
      rows.add(_buildSetFooter(setEntries.last));
    }
    rows.add(const SizedBox(height: 32));

    return Scaffold(
      appBar: const TournaQAppBar(title: 'Gameplay History'),
      body: Column(
        children: [
          _buildTeamHeader(),
          const Divider(height: 1),
          Expanded(
            child: ListView(children: rows),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Scaffold(
      appBar: const TournaQAppBar(title: 'Gameplay History'),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.history_rounded, size: 52, color: Colors.black26),
            const SizedBox(height: 14),
            const Text(
              'No scoring history yet',
              style: TextStyle(fontSize: 16, color: Colors.black45, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            const Text(
              'Start scoring to track gameplay.',
              style: TextStyle(fontSize: 13, color: Colors.black38),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamHeader() {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Container(
              color: _kGoldCardBg,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Text(
                team1Name,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          Container(width: 1, color: Colors.grey.shade300),
          Expanded(
            child: Container(
              color: _kOliveCardBg,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Text(
                team2Name,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSetHeader(int setIndex, int targetPoints) {
    return Container(
      color: Colors.grey.shade100,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const Expanded(child: Divider()),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              'Set ${setIndex + 1}  ·  to $targetPoints',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Colors.black45,
                letterSpacing: 0.6,
              ),
            ),
          ),
          const Expanded(child: Divider()),
        ],
      ),
    );
  }

  Widget _buildSetFooter(GameHistoryEntry last) {
    return Container(
      color: Colors.grey.shade50,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Text(
        'Final: ${last.team1Score} – ${last.team2Score}',
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.black45,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildRow(GameHistoryEntry entry) {
    final servingName = entry.isTeam1Serving
        ? (entry.servingPlayerIndex < team1Players.length
            ? team1Players[entry.servingPlayerIndex]
            : 'P${entry.servingPlayerIndex + 1}')
        : (entry.servingPlayerIndex < team2Players.length
            ? team2Players[entry.servingPlayerIndex]
            : 'P${entry.servingPlayerIndex + 1}');

    return IntrinsicHeight(
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Team 1 cell ──
            Expanded(
              child: Container(
                color: entry.isTeam1Score ? _kGoldCardBg : Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (entry.isTeam1Serving) ...[
                      const Icon(Icons.sports_volleyball_rounded, size: 11, color: _kGold),
                      const SizedBox(width: 3),
                      Flexible(
                        child: Text(
                          servingName,
                          style: const TextStyle(
                            fontSize: 9,
                            color: _kGold,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    if (entry.isTeam1Score)
                      Text(
                        '${entry.team1Score}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: _kGold,
                          height: 1.0,
                        ),
                      )
                    else
                      const SizedBox(width: 20),
                  ],
                ),
              ),
            ),
            // ── Divider ──
            Container(width: 1, color: Colors.grey.shade300),
            // ── Team 2 cell ──
            Expanded(
              child: Container(
                color: !entry.isTeam1Score ? _kOliveCardBg : Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                child: Row(
                  children: [
                    if (!entry.isTeam1Score)
                      Text(
                        '${entry.team2Score}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: _kOlive,
                          height: 1.0,
                        ),
                      )
                    else
                      const SizedBox(width: 20),
                    if (!entry.isTeam1Serving) ...[
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          servingName,
                          style: const TextStyle(
                            fontSize: 9,
                            color: _kOlive,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      const SizedBox(width: 3),
                      const Icon(Icons.sports_volleyball_rounded, size: 11, color: _kOlive),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
