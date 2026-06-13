import 'package:flutter/material.dart';
import '../app/app_colors.dart';
import '../models/ko_bracket_tournament.dart';
import '../services/ko_bracket_storage_service.dart';
import '../widgets/tournaq_app_bar.dart';
import '../widgets/scrollable_page.dart';
import 'ko_bracket_match_page.dart';

const _kGold = AppColors.gold;
const _kGoldDark = AppColors.goldDark;
const _kGoldCream = AppColors.goldCream;
const _kOlive = AppColors.olive;
const _kOliveLight = AppColors.oliveLight;

class KoBracketBracketPage extends StatefulWidget {
  final KoBracketTournament tournament;
  final void Function(KoBracketTournament) onChanged;

  const KoBracketBracketPage({
    super.key,
    required this.tournament,
    required this.onChanged,
  });

  @override
  State<KoBracketBracketPage> createState() => _KoBracketBracketPageState();
}

class _KoBracketBracketPageState extends State<KoBracketBracketPage> {
  late KoBracketTournament _tournament;

  @override
  void initState() {
    super.initState();
    _tournament = widget.tournament;
  }

  void _persist(KoBracketTournament updated) {
    KoBracketStorageService.save(updated);
    setState(() => _tournament = updated);
    widget.onChanged(updated);
  }

  // ── Round label ───────────────────────────────────────────────────────────

  String _roundLabel(int round) {
    if (round == 0) return 'Play-in';
    final totalRounds = _tournament.mainRoundCount;
    final stepsFromFinal = totalRounds - round;
    return switch (stepsFromFinal) {
      0 => 'Final',
      1 => 'Semi-final',
      2 => 'Quarter-final',
      _ => 'Round $round',
    };
  }

  // ── Withdraw dialog ───────────────────────────────────────────────────────

  Future<void> _showWithdrawDialog() async {
    final activeTeams = _tournament.teams.where((t) => !t.isWithdrawn).toList();
    if (activeTeams.isEmpty) return;

    final selected = await showDialog<KoTeam>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Withdraw Team',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Select the team to withdraw (injury / forfeit). Their pending matches will be resolved as walkovers.',
              style: TextStyle(fontSize: 13, color: Colors.black54),
            ),
            const SizedBox(height: 12),
            ...activeTeams.map((t) => ListTile(
                  dense: true,
                  title: Text(t.name),
                  onTap: () => Navigator.of(ctx).pop(t),
                )),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (selected == null || !mounted) return;

    // Find the current round for this team.
    final currentMatch = _tournament.matches.firstWhere(
      (m) =>
          !m.isComplete &&
          (m.team1Id == selected.id || m.team2Id == selected.id),
      orElse: () => const KoMatch(id: '', round: 0, matchIndex: 0),
    );
    final withdrawRound = currentMatch.id.isEmpty ? null : currentMatch.round;

    var updated = _tournament.updateTeam(
      selected.copyWith(isWithdrawn: true, withdrawnAtRound: withdrawRound),
    );

    // Resolve all pending matches involving this team as walkovers.
    for (final m in updated.matches) {
      if (m.isComplete) continue;
      if (m.team1Id != selected.id && m.team2Id != selected.id) continue;

      final winnerId = m.team1Id == selected.id ? m.team2Id : m.team1Id;
      var resolved = m.copyWith(
        winnerId: winnerId,
        withdrawnTeamId: selected.id,
        status: KoMatchStatus.walkover,
        completedAt: DateTime.now(),
      );
      updated = updated.updateMatch(resolved);
      if (winnerId != null) {
        final propagated = m.round == 0
            ? KoBracketGenerator.propagatePlayInWinner(updated.matches, resolved.id)
            : KoBracketGenerator.propagateWinner(updated.matches, resolved.id);
        updated = updated.copyWith(matches: propagated);
      }
    }

    if (updated.allMatchesComplete) {
      updated = updated.copyWith(status: KoBracketStatus.completed);
    }

    _persist(updated);
  }

  // ── Open match scoreboard ─────────────────────────────────────────────────

  void _openMatch(KoMatch match) {
    if (match.team1Id == null || match.team2Id == null) return;
    Navigator.of(context)
        .push(MaterialPageRoute(
          builder: (_) => KoBracketMatchPage(
            tournament: _tournament,
            matchId: match.id,
            onChanged: _persist,
          ),
        ))
        .then((_) {
      // Refresh from storage in case the match page saved changes.
      final saved = KoBracketStorageService.loadAll()
          .where((t) => t.id == _tournament.id)
          .firstOrNull;
      if (saved != null && mounted) setState(() => _tournament = saved);
    });
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final rounds = _tournament.allRounds;
    final isComplete = _tournament.status == KoBracketStatus.completed;

    return Scaffold(
      appBar: TournaQAppBar(
        title: _tournament.name,
        subtitle: 'KO Bracket',
        actions: [
          if (!isComplete)
            IconButton(
              icon: const Icon(Icons.person_remove_rounded, size: 20),
              tooltip: 'Withdraw team',
              onPressed: _showWithdrawDialog,
            ),
        ],
      ),
      body: ScrollablePage(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Schedule chips ────────────────────────────────────────────
            _buildScheduleBar(),
            const SizedBox(height: 20),

            // ── Winner banner ─────────────────────────────────────────────
            if (isComplete) ...[
              _buildWinnerBanner(),
              const SizedBox(height: 20),
            ],

            // ── Rounds ────────────────────────────────────────────────────
            ...rounds.map((round) {
              final matches = _tournament.matchesForRound(round);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _roundHeader(round, matches),
                  const SizedBox(height: 8),
                  ...matches.map((m) => _matchCard(m, round)),
                  const SizedBox(height: 20),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  // ── Schedule bar ──────────────────────────────────────────────────────────

  Widget _buildScheduleBar() {
    final start = _tournament.estimatedStart;
    final end = _tournament.estimatedEnd;
    final duration = _tournament.estimatedDuration;

    String fmtDt(DateTime dt) {
      final h = dt.hour.toString().padLeft(2, '0');
      final m = dt.minute.toString().padLeft(2, '0');
      return '${dt.day}/${dt.month} $h:$m';
    }

    String fmtDur(Duration d) {
      final h = d.inHours;
      final m = d.inMinutes % 60;
      if (h == 0) return '${m}min';
      if (m == 0) return '${h}h';
      return '${h}h ${m}min';
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _chip(Icons.groups_rounded, '${_tournament.teamCount} teams'),
        _chip(Icons.sports_tennis_rounded, '${_tournament.courtCount} court(s)'),
        _chip(Icons.timer_outlined, fmtDur(duration)),
        if (start != null) _chip(Icons.play_circle_outline_rounded, fmtDt(start)),
        if (end != null) _chip(Icons.stop_circle_outlined, fmtDt(end)),
      ],
    );
  }

  Widget _chip(IconData icon, String label) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: _kGoldCream,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.goldBadgeBorder),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 13, color: _kGoldDark),
          const SizedBox(width: 5),
          Text(label,
              style: const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600, color: _kGoldDark)),
        ]),
      );

  // ── Winner banner ─────────────────────────────────────────────────────────

  Widget _buildWinnerBanner() {
    // Find the final match winner.
    final finalMatch = _tournament.matches
        .where((m) => m.round == _tournament.mainRoundCount && m.isComplete)
        .firstOrNull;
    final winnerId = finalMatch?.winnerId;
    final winner = winnerId != null ? _tournament.teamById(winnerId) : null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_kGold, _kGoldDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _kGold.withValues(alpha: 0.35),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(children: [
        const Icon(Icons.emoji_events_rounded, color: Colors.white, size: 32),
        const SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Tournament Winner',
              style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
          Text(
            winner?.name ?? 'TBD',
            style: const TextStyle(
                color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800),
          ),
        ]),
      ]),
    );
  }

  // ── Round header ──────────────────────────────────────────────────────────

  Widget _roundHeader(int round, List<KoMatch> matches) {
    final done = matches.where((m) => m.isComplete).length;
    final total = matches.length;
    final isCurrentRound = done < total &&
        (round == 0 ||
            _tournament
                .matchesForRound(round - 1)
                .every((m) => m.isComplete));

    return Row(children: [
      Icon(
        round == 0 ? Icons.play_arrow_rounded : Icons.account_tree_rounded,
        size: 15,
        color: isCurrentRound ? _kGold : _kOlive,
      ),
      const SizedBox(width: 6),
      Text(
        _roundLabel(round).toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: isCurrentRound ? _kGold : _kOlive,
          letterSpacing: 0.4,
        ),
      ),
      const SizedBox(width: 8),
      Text(
        '$done / $total',
        style: const TextStyle(fontSize: 12, color: Colors.black38),
      ),
      const Spacer(),
      _formatBadge(_tournament.formatForRound(round)),
    ]);
  }

  Widget _formatBadge(KoRoundFormat fmt) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Text(
          fmt.label,
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.black45),
        ),
      );

  // ── Match card ────────────────────────────────────────────────────────────

  Widget _matchCard(KoMatch match, int round) {
    final team1 = match.team1Id != null ? _tournament.teamById(match.team1Id!) : null;
    final team2 = match.team2Id != null ? _tournament.teamById(match.team2Id!) : null;
    final isBye = match.status == KoMatchStatus.bye;
    final isWalkover = match.status == KoMatchStatus.walkover;
    final isComplete = match.isComplete;
    final canTap = !isComplete && team1 != null && team2 != null;
    final isRepechage = match.status == KoMatchStatus.repechage;
    final isPlayIn = match.status == KoMatchStatus.playIn;

    Color borderColor = Colors.grey.shade200;
    Color bgColor = Colors.white;
    if (match.status == KoMatchStatus.inProgress) {
      borderColor = _kGold;
      bgColor = _kGoldCream;
    } else if (isComplete) {
      borderColor = _kOlive.withValues(alpha: 0.4);
      bgColor = _kOliveLight;
    }

    return GestureDetector(
      onTap: canTap ? () => _openMatch(match) : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: isComplete ? 1 : 1.5),
          boxShadow: canTap
              ? [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2))]
              : null,
        ),
        child: Column(
          children: [
            // Status tag row
            if (isBye || isWalkover || isRepechage || isPlayIn)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(children: [
                  _statusTag(match.status),
                ]),
              ),

            // Teams row
            Row(children: [
              Expanded(child: _teamSlot(team1, match.winnerId == match.team1Id, match)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  isComplete ? _scoreLabel(match) : 'vs',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: isComplete ? 15 : 13,
                    color: isComplete ? Colors.black87 : Colors.black38,
                  ),
                ),
              ),
              Expanded(child: _teamSlot(team2, match.winnerId == match.team2Id, match, alignRight: true)),
            ]),

            // Court + tap hint
            if (canTap) ...[
              const SizedBox(height: 8),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.touch_app_rounded, size: 12, color: _kGold.withValues(alpha: 0.7)),
                const SizedBox(width: 4),
                Text('Tap to score',
                    style: TextStyle(fontSize: 11, color: _kGold.withValues(alpha: 0.7))),
              ]),
            ],
          ],
        ),
      ),
    );
  }

  Widget _teamSlot(KoTeam? team, bool isWinner, KoMatch match, {bool alignRight = false}) {
    final isWithdrawn = team?.isWithdrawn ?? false;
    final textAlign = alignRight ? TextAlign.right : TextAlign.left;
    final crossAxis = alignRight ? CrossAxisAlignment.end : CrossAxisAlignment.start;

    if (team == null) {
      return Column(crossAxisAlignment: crossAxis, children: [
        Text('TBD',
            textAlign: textAlign,
            style: const TextStyle(fontSize: 14, color: Colors.black26, fontWeight: FontWeight.w600)),
      ]);
    }

    return Column(
      crossAxisAlignment: crossAxis,
      children: [
        Row(
          mainAxisAlignment: alignRight ? MainAxisAlignment.end : MainAxisAlignment.start,
          children: [
            if (isWinner && !alignRight) ...[
              const Icon(Icons.emoji_events_rounded, size: 14, color: _kGold),
              const SizedBox(width: 4),
            ],
            Flexible(
              child: Text(
                team.name,
                textAlign: textAlign,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: isWithdrawn
                      ? Colors.grey
                      : isWinner
                          ? _kGoldDark
                          : Colors.black87,
                  decoration: isWithdrawn ? TextDecoration.lineThrough : null,
                ),
              ),
            ),
            if (isWinner && alignRight) ...[
              const SizedBox(width: 4),
              const Icon(Icons.emoji_events_rounded, size: 14, color: _kGold),
            ],
            if (isWithdrawn) ...[
              const SizedBox(width: 4),
              const Icon(Icons.warning_amber_rounded, size: 13, color: Colors.orange),
            ],
          ],
        ),
        if (team.players.isNotEmpty)
          Text(
            team.players.map((p) => p.name).join(' · '),
            textAlign: textAlign,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11, color: Colors.black38),
          ),
      ],
    );
  }

  String _scoreLabel(KoMatch match) {
    if (match.sets.isEmpty) return '—';
    final t1 = match.team1Sets;
    final t2 = match.team2Sets;
    if (t1 + t2 == 1) {
      final s = match.sets.first;
      return '${s.score1}–${s.score2}';
    }
    return '$t1–$t2';
  }

  Widget _statusTag(KoMatchStatus status) {
    final (label, color) = switch (status) {
      KoMatchStatus.bye => ('BYE', Colors.grey),
      KoMatchStatus.walkover => ('W/O', Colors.orange),
      KoMatchStatus.playIn => ('PLAY-IN', _kGold),
      KoMatchStatus.repechage => ('REPECHAGE', Colors.deepOrange),
      _ => ('', Colors.transparent),
    };
    if (label.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(label,
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color)),
    );
  }
}
