import 'dart:async';
import 'dart:math' show Random, pi;
import 'package:flutter/material.dart';
import '../app/app_colors.dart';
import '../l10n/app_localizations.dart';
import '../models/ko_bracket_tournament.dart';
import '../scoring/ko_bracket_adapter.dart';
import '../services/ko_bracket_transfer_service.dart';
import '../widgets/player_pill.dart';
import '../widgets/qr_export_sheet.dart';
import '../widgets/sheet_helpers.dart';
import '../widgets/tournaq_app_bar.dart';
import 'gameplay_history_page.dart';

const _kGold = AppColors.gold;
const _kGoldDark = AppColors.goldDark;
const _kGoldCream = AppColors.goldCream;
const _kGoldCardBg = AppColors.goldCardBg;
const _kGoldCardLeading = AppColors.goldCardLeading;
const _kOlive = AppColors.olive;
const _kOliveLight = AppColors.oliveLight;
const _kOliveCardBg = AppColors.oliveCardBg;
const _kOliveCardLeading = AppColors.oliveCardLeading;

class _ScoreEvent {
  final bool isTeam1Score;
  final int setIndex;
  final int prevService;
  final bool changedService;

  const _ScoreEvent({
    required this.isTeam1Score,
    required this.setIndex,
    required this.prevService,
    required this.changedService,
  });
}

class KoBracketMatchPage extends StatefulWidget {
  final KoBracketTournament tournament;
  final String matchId;
  final void Function(KoBracketTournament) onChanged;

  /// True when scoring a match imported from another device's QR. Persistence
  /// then flows only through [onChanged] (never the main KO store), and the app
  /// bar offers an "export result" QR instead of the normal options.
  final bool isImported;

  /// The host tournament id to stamp into an exported result, so the origin
  /// device can match the scanned result back to its own match.
  final String? parentTournamentId;

  /// Bracket position from the host (e.g. "Quarter-final · Match 3"), shown on
  /// an imported scorecard instead of the mini-tournament's own position.
  final String? importedPositionLabel;

  const KoBracketMatchPage({
    super.key,
    required this.tournament,
    required this.matchId,
    required this.onChanged,
    this.isImported = false,
    this.parentTournamentId,
    this.importedPositionLabel,
  });

  @override
  State<KoBracketMatchPage> createState() => _KoBracketMatchPageState();
}

class _KoBracketMatchPageState extends State<KoBracketMatchPage> {
  late KoBracketAdapter _adapter;
  bool _scheduleExpanded = false;

  // ── Live scores (ephemeral display state) ─────────────────────────────────
  int _score1 = 0;
  int _score2 = 0;
  bool _isSwapped = false;
  double _dragDelta = 0; // accumulates horizontal drag to swap sides by gesture

  // ── Timer ─────────────────────────────────────────────────────────────────
  Timer? _timer;
  DateTime _now = DateTime.now();

  // ── Score events (service tracking + history) ─────────────────────────────
  int _activePlayerIndex = 0;
  final List<_ScoreEvent> _scoreEvents = [];

  // ── Adapter pass-through getters ──────────────────────────────────────────
  KoBracketTournament get _tournament => _adapter.tournament;
  KoMatch get _match => _adapter.match;
  KoRoundFormat get _fmt => _adapter.fmt;
  bool get _isMatchComplete => _adapter.isMatchComplete;
  int get _currentSetIndex => _adapter.currentSetIndex;
  bool get _currentSetDone => _adapter.isCurrentSetCompleted;

  @override
  void initState() {
    super.initState();
    _adapter = KoBracketAdapter(
      tournament: widget.tournament,
      matchId: widget.matchId,
      onChanged: widget.onChanged,
      saveToStore: !widget.isImported,
    );
    _score1 = _adapter.currentScore1;
    _score2 = _adapter.currentScore2;
    _now = DateTime.now();
    _startTimer();
    // Deferred to post-frame: assigning suggestions persists the match and
    // calls onChanged -> setState on the ancestor bracket page, which is illegal
    // while this page is being inflated during the frame build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _assignSuggestionsIfNeeded();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    final s1 = _isSwapped ? _score2 : _score1;
    final s2 = _isSwapped ? _score1 : _score2;
    _adapter.flushLiveScoreToStorage(s1, s2);
    super.dispose();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  KoTeam? get _team1 => _match.team1Id != null ? _tournament.teamById(_match.team1Id!) : null;
  KoTeam? get _team2 => _match.team2Id != null ? _tournament.teamById(_match.team2Id!) : null;

  KoTeam? get _leftTeam => _isSwapped ? _team2 : _team1;
  KoTeam? get _rightTeam => _isSwapped ? _team1 : _team2;
  int get _leftScore => _isSwapped ? _score2 : _score1;
  int get _rightScore => _isSwapped ? _score1 : _score2;
  bool get _isLeftLeading => _leftScore > _rightScore;
  bool get _isRightLeading => _rightScore > _leftScore;

  int get _team1SetsWon => _match.sets.where((s) => s.isCompleted && s.score1 > s.score2).length;
  int get _team2SetsWon => _match.sets.where((s) => s.isCompleted && s.score2 > s.score1).length;

  // ── Suggestions (serve + referee) ────────────────────────────────────────

  void _assignSuggestionsIfNeeded() {
    if (_match.startedAt != null || _isMatchComplete) return;
    var match = _match;
    bool changed = false;

    // Suggested server: random player from either team's roster.
    if (match.suggestedServingPlayerId == null &&
        _team1 != null && _team2 != null) {
      final allPlayers = [..._team1!.players, ..._team2!.players];
      if (allPlayers.isNotEmpty) {
        final player = allPlayers[Random().nextInt(allPlayers.length)];
        match = match.copyWith(suggestedServingPlayerId: player.appPlayerId);
        changed = true;
      }
    }

    // Suggested referee: a team eliminated in a previous round (loser of a
    // completed earlier match). All teams in the same round play simultaneously
    // so they cannot serve as referees.
    if (match.refereeTeamId == null) {
      final myTeamIds = {match.team1Id, match.team2Id};
      final teamsInCurrentRound = _tournament.matches
          .where((m) => m.round == match.round)
          .expand((m) => [m.team1Id, m.team2Id])
          .whereType<String>()
          .toSet();
      final refTeamId = _tournament.matches
          .where((m) => m.round < match.round && m.isComplete && m.winnerId != null)
          .map((m) => m.team1Id == m.winnerId ? m.team2Id : m.team1Id)
          .whereType<String>()
          .where((id) => !myTeamIds.contains(id) && !teamsInCurrentRound.contains(id))
          .firstOrNull;
      if (refTeamId != null) {
        match = match.copyWith(refereeTeamId: refTeamId);
        changed = true;
      }
    }

    if (changed) {
      _adapter.updateMatch((_) => match);
      setState(() {});
    }
  }

  // ── Scorecard export (host → referee, before the match starts) ────────────

  /// Shared QR subtitle: bracket position, court (when assigned) and the two
  /// teams — matches the context shown on the other match exports.
  String _matchContext(AppLocalizations l10n) {
    final teams = '${_team1?.name ?? 'TBD'} vs ${_team2?.name ?? 'TBD'}';
    final court = _match.courtAssignment != null
        ? ' · ${l10n.matchCourtLabel(_match.courtAssignment!)}'
        : '';
    return '$_bracketPositionLabel$court · $teams';
  }

  void _exportScorecard() {
    final l10n = AppLocalizations.of(context)!;
    final data = KoBracketTransferService.encodeMatchExport(
      _tournament,
      _match,
      positionLabel: _bracketPositionLabel,
    );
    showQrExportSheet(
      context,
      title: l10n.scrambleExportScorecard,
      subtitle: _matchContext(l10n),
      data: data,
    );
  }

  // ── Imported result export (referee → host) ───────────────────────────────

  void _exportResult() {
    final l10n = AppLocalizations.of(context)!;
    if (!_isMatchComplete) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(l10n.bracketFinishBeforeExport),
        duration: const Duration(seconds: 2),
      ));
      return;
    }
    final parentId = widget.parentTournamentId ?? _tournament.id;
    final data = KoBracketTransferService.encodeResult(parentId, _match);
    showQrExportSheet(
      context,
      title: l10n.scrambleExportResult,
      subtitle: _matchContext(l10n),
      data: data,
    );
  }

  // ── Export / edit menu ────────────────────────────────────────────────────

  /// Any points on the board — the live set or any recorded set.
  bool get _hasAnyPoints =>
      _score1 > 0 ||
      _score2 > 0 ||
      _match.sets.any((s) => s.score1 > 0 || s.score2 > 0);

  /// The match this one's winner advanced into (immediate downstream slot), or
  /// null at the final / before a winner exists. Round-0 play-ins feed a round-1
  /// slot found by winner membership; main rounds are deterministic.
  KoMatch? get _downstreamMatch {
    final winnerId = _match.winnerId;
    if (winnerId == null) return null;
    if (_match.round == 0) {
      for (final m in _tournament.matches.where((m) => m.round == 1)) {
        if (m.team1Id == winnerId || m.team2Id == winnerId) return m;
      }
      return null;
    }
    final targetRound = _match.round + 1;
    final targetIndex = _match.matchIndex ~/ 2;
    final idx = _tournament.matches.indexWhere(
        (m) => m.round == targetRound && m.matchIndex == targetIndex);
    return idx < 0 ? null : _tournament.matches[idx];
  }

  /// True once the downstream match is underway — started, scored or complete —
  /// so re-adjudicating this match must not change who advanced into it.
  bool get _downstreamLocked {
    final d = _downstreamMatch;
    if (d == null) return false;
    return d.startedAt != null ||
        d.isComplete ||
        d.sets.any((s) => s.score1 > 0 || s.score2 > 0);
  }

  /// The app-bar QR menu (export + edit score). Shown only while the board is
  /// still 0–0 (hand-off / manual entry) or once the match is complete (export
  /// result / fix the score). Hidden mid-match so an in-progress board can't be
  /// exported or silently overwritten. Null when there's nothing to offer.
  Widget? _buildExportEditMenu(AppLocalizations l10n) {
    if (_team1 == null || _team2 == null) return null;
    if (!(_isMatchComplete || !_hasAnyPoints)) return null;

    final canExportScorecard = !_isMatchComplete && !widget.isImported;
    PopupMenuItem<String> item(String value, IconData icon, String label) =>
        PopupMenuItem<String>(
          value: value,
          child: Row(children: [
            Icon(icon, size: 18, color: _kOlive),
            const SizedBox(width: 8),
            Text(label),
          ]),
        );

    return PopupMenuButton<String>(
      icon: const Icon(Icons.qr_code_rounded),
      tooltip: l10n.scrambleExportScorecard,
      onSelected: (v) {
        switch (v) {
          case 'export':
            _isMatchComplete ? _exportResult() : _exportScorecard();
          case 'edit':
            _onEditScore();
        }
      },
      itemBuilder: (ctx) => [
        if (_isMatchComplete)
          item('export', Icons.qr_code_rounded, l10n.scrambleExportResult)
        else if (canExportScorecard)
          item('export', Icons.qr_code_rounded, l10n.scrambleExportScorecard),
        item('edit', Icons.edit_rounded, l10n.scorecardManualScore),
      ],
    );
  }

  // ── Manual score entry / edit ─────────────────────────────────────────────

  void _onEditScore() {
    if (_hasAnyPoints) {
      _confirmOverrideThenEdit();
    } else {
      _showEditScoreDialog();
    }
  }

  Future<void> _confirmOverrideThenEdit() async {
    final l10n = AppLocalizations.of(context)!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Colors.white,
        title: Text(l10n.scorecardEditScoreOverrideTitle,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        content: Text(l10n.scorecardEditScoreOverrideBody,
            style: const TextStyle(
                fontSize: 14, color: Colors.black87, height: 1.5)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.btnCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.btnContinue,
                style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (ok == true && mounted) _showEditScoreDialog();
  }

  Future<void> _showWinnerLockedDialog() async {
    final l10n = AppLocalizations.of(context)!;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Colors.white,
        title: Row(children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10)),
            child: Icon(Icons.lock_outline_rounded,
                color: Colors.orange.shade800, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(l10n.scorecardEditWinnerLockedTitle,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ),
        ]),
        content: Text(l10n.scorecardEditWinnerLockedBody,
            style: const TextStyle(
                fontSize: 14, color: Colors.black87, height: 1.5)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.btnGotIt,
                style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Future<void> _showEditScoreDialog() async {
    final l10n = AppLocalizations.of(context)!;
    final fmt = _fmt;
    // Prefill with the existing set scores when editing a match that was played.
    final ctrls1 = List.generate(
        fmt.setsPerGame,
        (i) => TextEditingController(
            text: i < _match.sets.length ? '${_match.sets[i].score1}' : ''));
    final ctrls2 = List.generate(
        fmt.setsPerGame,
        (i) => TextEditingController(
            text: i < _match.sets.length ? '${_match.sets[i].score2}' : ''));

    List<KoSet> tally() {
      final sets = <KoSet>[];
      for (var i = 0; i < fmt.setsPerGame; i++) {
        final s1 = int.tryParse(ctrls1[i].text) ?? 0;
        final s2 = int.tryParse(ctrls2[i].text) ?? 0;
        if (s1 == 0 && s2 == 0) continue;
        sets.add(KoSet(score1: s1, score2: s2, isCompleted: true));
      }
      return sets;
    }

    try {
      final confirmed = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => StatefulBuilder(
          builder: (ctx, setDialog) {
            final sets = tally();
            final w1 = sets.where((s) => s.score1 > s.score2).length;
            final w2 = sets.where((s) => s.score2 > s.score1).length;
            final canSave = sets.isNotEmpty && w1 != w2;
            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              backgroundColor: Colors.white,
              title: Row(children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                      color: _kOliveLight,
                      borderRadius: BorderRadius.circular(10)),
                  child:
                      const Icon(Icons.edit_rounded, color: _kOlive, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(l10n.scorecardManualScore,
                      style: const TextStyle(
                          fontSize: 17, fontWeight: FontWeight.w700)),
                ),
              ]),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 4),
                    Text(l10n.scorecardManualScoreDescription,
                        style: const TextStyle(
                            fontSize: 13, color: Colors.black54, height: 1.5)),
                    const SizedBox(height: 12),
                    Row(children: [
                      Expanded(
                        child: Text(_team1?.name ?? 'TBD',
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: _kGoldDark)),
                      ),
                      const SizedBox(width: 56),
                      Expanded(
                        child: Text(_team2?.name ?? 'TBD',
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: _kOlive)),
                      ),
                    ]),
                    const SizedBox(height: 8),
                    for (var i = 0; i < fmt.setsPerGame; i++) ...[
                      _manualSetRow(
                          ctrls1[i],
                          ctrls2[i],
                          fmt.setsPerGame > 1 ? l10n.bracketManualSet(i + 1) : null,
                          () => setDialog(() {})),
                      const SizedBox(height: 8),
                    ],
                  ],
                ),
              ),
              actions: [
                Row(children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10))),
                      child: Text(l10n.btnCancel),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: _kOlive,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.grey.shade300,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10))),
                      onPressed:
                          canSave ? () => Navigator.of(ctx).pop(true) : null,
                      child: Text(l10n.scorecardCompleteGame,
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                ]),
              ],
            );
          },
        ),
      );
      if (confirmed != true || !mounted) return;
      final newSets = tally();
      // Don't let an edit flip the winner once the next match is already under
      // way — that would corrupt a started/played downstream game. Point-only
      // corrections that keep the same winner are still allowed.
      final newW1 = newSets.where((s) => s.score1 > s.score2).length;
      final newW2 = newSets.where((s) => s.score2 > s.score1).length;
      final newWinnerId = newW1 > newW2 ? _match.team1Id : _match.team2Id;
      if (_match.winnerId != null &&
          newWinnerId != _match.winnerId &&
          _downstreamLocked) {
        await _showWinnerLockedDialog();
        return;
      }
      _adapter.applyManualResult(newSets);
      setState(() {
        _score1 = _adapter.currentScore1;
        _score2 = _adapter.currentScore2;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(l10n.overviewScoreSaved),
        duration: const Duration(seconds: 2),
      ));
    } finally {
      // Delay disposal until the dialog's exit animation completes.
      Future.delayed(const Duration(milliseconds: 300), () {
        for (final c in ctrls1) {
          c.dispose();
        }
        for (final c in ctrls2) {
          c.dispose();
        }
      });
    }
  }

  Widget _manualSetRow(TextEditingController c1, TextEditingController c2,
      String? label, VoidCallback onChanged) {
    Widget field(TextEditingController c, Color color) => SizedBox(
          width: 56,
          child: TextField(
            controller: c,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            onChanged: (_) => onChanged(),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            style: TextStyle(fontWeight: FontWeight.w700, color: color),
          ),
        );
    return Column(children: [
      if (label != null) ...[
        Text(label,
            style: const TextStyle(
                fontSize: 11,
                color: Colors.black45,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
      ],
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        field(c1, _kGoldDark),
        const SizedBox(width: 16),
        const Text('–', style: TextStyle(fontSize: 16, color: Colors.black26)),
        const SizedBox(width: 16),
        field(c2, _kOlive),
      ]),
    ]);
  }

  // ── Timer ─────────────────────────────────────────────────────────────────

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (!mounted) return;
      setState(() => _now = DateTime.now());
    });
  }

  // ── Service helpers ───────────────────────────────────────────────────────

  bool get _isTeam1Serving => _activePlayerIndex % 2 == 0;
  int  get _activePlayerOnSide => _activePlayerIndex ~/ 2;

  bool _shouldShowSideChangeReminder() {
    if (_currentSetDone) return false;
    final interval = _fmt.sideChangeInterval;
    if (interval == null || interval <= 0) return false;
    final total = _score1 + _score2;
    if (total == 0) return false;
    return total % interval == 0;
  }

  /// A set is won at [pointsPerSet] with a two-point margin.
  bool _isSetWon(int s1, int s2) {
    final hi = s1 > s2 ? s1 : s2;
    final lo = s1 > s2 ? s2 : s1;
    return hi >= _fmt.pointsPerSet && (hi - lo) >= 2;
  }

  Future<void> _showSideChangeDialog() async {
    final l10n = AppLocalizations.of(context)!;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Colors.white,
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
        contentPadding: const EdgeInsets.fromLTRB(24, 14, 24, 0),
        actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        title: Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: _kGoldCream, borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.swap_horiz_rounded, color: _kGoldDark, size: 20),
          ),
          const SizedBox(width: 12),
          Text(l10n.sideChangeTitle,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
        ]),
        content: Text(
          l10n.sideChangeBodyWithScore(_score1 + _score2),
          style: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.5),
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _kOlive,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(l10n.sideChangeContinue,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
    if (mounted) setState(() => _isSwapped = !_isSwapped);
  }

  // ── Side swap (button + gesture) ──────────────────────────────────────────

  void _swapSides() => setState(() => _isSwapped = !_isSwapped);

  void _handleHorizontalDragUpdate(DragUpdateDetails details) {
    _dragDelta += details.delta.dx;
  }

  void _handleHorizontalDragEnd(DragEndDetails details) {
    const threshold = 50.0; // pixels — a deliberate horizontal swipe swaps sides
    if (_dragDelta.abs() > threshold) _swapSides();
    _dragDelta = 0;
  }

  // ── Scoring ───────────────────────────────────────────────────────────────

  void _addScore({required bool isLeft}) {
    if (_isMatchComplete || _currentSetDone) return;
    final isTeam1 = isLeft ? !_isSwapped : _isSwapped;
    final prevService = _activePlayerIndex;
    final changedService = isTeam1 != _isTeam1Serving;
    final perSide = _tournament.playersPerSide;
    final wonBefore = _isSetWon(_score1, _score2);
    setState(() {
      if (isTeam1) {
        _score1++;
      } else {
        _score2++;
      }
      if (changedService) {
        _activePlayerIndex = (_activePlayerIndex + 1) % (2 * perSide);
      }
      _scoreEvents.add(_ScoreEvent(
        isTeam1Score: isTeam1,
        setIndex: _currentSetIndex,
        prevService: prevService,
        changedService: changedService,
      ));
    });
    if (_fmt.notifyOnTargetReached &&
        _isSetWon(_score1, _score2) &&
        !wonBefore) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showTargetReachedDialog();
      });
    } else if (_shouldShowSideChangeReminder()) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showSideChangeDialog();
      });
    }
  }

  /// Notify-only prompt when a side reaches the target score. Offers to
  /// complete the set/game now, or keep playing (the game can still be finished
  /// later from the scorecard's own complete button).
  Future<void> _showTargetReachedDialog() async {
    final l10n = AppLocalizations.of(context)!;
    final isTeam1Winner = _score1 > _score2;
    final winnerName = (isTeam1Winner ? _team1?.name : _team2?.name) ?? '';
    final setNumber = _currentSetIndex + 1;
    final isOneSet = _fmt.setsPerGame == 1;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Colors.white,
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
        contentPadding: const EdgeInsets.fromLTRB(24, 14, 24, 0),
        actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        title: Row(children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
                color: _kGoldCream, borderRadius: BorderRadius.circular(10)),
            child:
                const Icon(Icons.emoji_events_rounded, color: _kGoldDark, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(l10n.targetReachedTitle,
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          ),
        ]),
        content: Text(
          l10n.targetReachedBody(winnerName, setNumber),
          style: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.5),
        ),
        actions: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kOlive,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    _completeSet();
                  },
                  child: Text(isOneSet ? l10n.completeGame : l10n.completeSet,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: Text(l10n.targetReachedKeepPlaying),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _removeScore({required bool isLeft}) {
    if (_isMatchComplete || _currentSetDone) return;
    final removeTeam1 = isLeft ? !_isSwapped : _isSwapped;
    final currentSet = _currentSetIndex;
    int eventIndex = -1;
    for (var i = _scoreEvents.length - 1; i >= 0; i--) {
      if (_scoreEvents[i].isTeam1Score == removeTeam1 && _scoreEvents[i].setIndex == currentSet) {
        eventIndex = i;
        break;
      }
    }
    setState(() {
      if (removeTeam1) {
        _score1 = (_score1 - 1).clamp(0, 999);
      } else {
        _score2 = (_score2 - 1).clamp(0, 999);
      }
      if (eventIndex >= 0) {
        final event = _scoreEvents[eventIndex];
        if (event.changedService) _activePlayerIndex = event.prevService;
        _scoreEvents.removeAt(eventIndex);
      }
    });
  }

  // ── Navigation ────────────────────────────────────────────────────────────

  void _saveAndBack() {
    if (!_currentSetDone && !_isMatchComplete) {
      final s1 = _isSwapped ? _score2 : _score1;
      final s2 = _isSwapped ? _score1 : _score2;
      _adapter.onLiveScoreChanged(s1, s2);
    }
    if (mounted) Navigator.of(context).pop();
  }

  // ── Set & match completion ────────────────────────────────────────────────

  void _completeSet() {
    if (_isMatchComplete || _currentSetDone) return;
    final s1 = _isSwapped ? _score2 : _score1;
    final s2 = _isSwapped ? _score1 : _score2;
    if (s1 == s2) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(AppLocalizations.of(context)!.matchScoresTiedSet),
        duration: const Duration(seconds: 2),
      ));
      return;
    }
    _adapter.onSetCompleted(s1, s2);
    if (_adapter.isMatchComplete) _timer?.cancel();
    setState(() {
      _score1 = _adapter.currentScore1;
      _score2 = _adapter.currentScore2;
      _activePlayerIndex = 0;
    });
  }

  void _switchToSet(int i) {
    if (i == _adapter.currentSetIndex) return;
    if (i > _match.sets.length) return;
    final s1 = _isSwapped ? _score2 : _score1;
    final s2 = _isSwapped ? _score1 : _score2;
    _adapter.onSetActivated(i, s1, s2);
    setState(() {
      _score1 = _adapter.currentScore1;
      _score2 = _adapter.currentScore2;
      _activePlayerIndex = 0;
    });
  }

  void _undoSetCompletion() {
    _adapter.onSetUndone(_adapter.currentSetIndex);
    setState(() {
      _score1 = _adapter.currentScore1;
      _score2 = _adapter.currentScore2;
      _activePlayerIndex = 0;
    });
  }

  void _completeMatch() {
    if (_isMatchComplete) return;
    final s1 = _isSwapped ? _score2 : _score1;
    final s2 = _isSwapped ? _score1 : _score2;
    if (!_currentSetDone && (s1 > 0 || s2 > 0) && s1 == s2) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(AppLocalizations.of(context)!.matchScoresTiedMatch),
        duration: const Duration(seconds: 2),
      ));
      return;
    }
    // Pre-validate that sets won won't be tied after including current scores.
    var checkSets = _match.sets;
    if (!_currentSetDone && (s1 > 0 || s2 > 0)) {
      checkSets = [...checkSets, KoSet(score1: s1, score2: s2, isCompleted: true)];
    }
    final t1 = checkSets.where((s) => s.isCompleted && s.score1 > s.score2).length;
    final t2 = checkSets.where((s) => s.isCompleted && s.score2 > s.score1).length;
    if (t1 == t2) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(AppLocalizations.of(context)!.matchSetsTied),
        duration: const Duration(seconds: 2),
      ));
      return;
    }
    _adapter.onMatchCompleted(s1, s2);
    _timer?.cancel();
    setState(() {
      _score1 = _adapter.currentScore1;
      _score2 = _adapter.currentScore2;
      _activePlayerIndex = 0;
    });
  }

  void _undoMatchCompletion() {
    _adapter.onMatchCompletionUndone();
    setState(() {
      _score1 = _adapter.currentScore1;
      _score2 = _adapter.currentScore2;
      _activePlayerIndex = 0;
    });
    _startTimer();
  }

  // ── History ───────────────────────────────────────────────────────────────

  List<GameHistoryEntry> _buildHistoryEntries() {
    final entries = <GameHistoryEntry>[];
    final setScores = <int, List<int>>{};
    for (final event in _scoreEvents) {
      final scores = setScores.putIfAbsent(event.setIndex, () => [0, 0]);
      if (event.isTeam1Score) {
        scores[0]++;
      } else {
        scores[1]++;
      }
      entries.add(GameHistoryEntry(
        isTeam1Score: event.isTeam1Score,
        team1Score: scores[0],
        team2Score: scores[1],
        setIndex: event.setIndex,
        targetPoints: _fmt.pointsPerSet,
        isTeam1Serving: event.prevService % 2 == 0,
        servingPlayerIndex: event.prevService ~/ 2,
        serviceChanged: event.changedService,
      ));
    }
    return entries;
  }

  void _showHistory() {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => GameplayHistoryPage(
        team1Name: _team1?.name ?? 'TBD',
        team2Name: _team2?.name ?? 'TBD',
        team1Players: _team1?.players.map((p) => p.name).toList() ?? [],
        team2Players: _team2?.players.map((p) => p.name).toList() ?? [],
        entries: _buildHistoryEntries(),
      ),
    ));
  }

  // ── Context chips ─────────────────────────────────────────────────────────

  String get _bracketPositionLabel {
    if (widget.importedPositionLabel != null) return widget.importedPositionLabel!;
    final total = _tournament.mainRoundCount;
    final stepsFromFinal = total - _match.round;
    final roundName = switch (stepsFromFinal) {
      0 => 'Final',
      1 => 'Semi-final',
      2 => 'Quarter-final',
      _ => 'Round ${_match.round}',
    };
    if (_match.status == KoMatchStatus.playIn) return 'Play-in · Match ${_match.matchIndex + 1}';
    if (_match.status == KoMatchStatus.repechage) return 'Repechage';
    return '$roundName · Match ${_match.matchIndex + 1}';
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final scoreLocked = _isMatchComplete || _currentSetDone || _match.startedAt == null;

    final l10n = AppLocalizations.of(context)!;

    final optionsButton = IconButton(
      icon: const Icon(Icons.tune_rounded, size: 20, color: _kOlive),
      tooltip: l10n.matchOptions,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
      visualDensity: VisualDensity.compact,
      onPressed: _showOptions,
    );

    // QR menu (export + edit score). Icons inherit the app bar's goldLight
    // foreground so they stay visible on the olive bar. Only shown while 0–0
    // or once complete; hidden mid-match. Match options live in the Gameplay
    // Controls section, so there's no duplicate options button up here.
    final exportEditMenu = _buildExportEditMenu(l10n);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _saveAndBack();
      },
      child: Scaffold(
      appBar: TournaQAppBar(
        title: 'Single Elimination',
        subtitle:
            widget.isImported ? l10n.scrambleImportedScorecard : l10n.matchScorecard,
        actions: [
          ?exportEditMenu,
        ],
      ),
      body: SafeArea(
        // Horizontal drag anywhere on the scoreboard swaps the two sides —
        // in addition to the swap button.
        child: GestureDetector(
          onHorizontalDragUpdate: _handleHorizontalDragUpdate,
          onHorizontalDragEnd: _handleHorizontalDragEnd,
          child: OrientationBuilder(
          builder: (context, orientation) {
            final isLandscape = orientation == Orientation.landscape;

            // ── Landscape ──────────────────────────────────────────────────
            // Top: set overview + options (like QuickGame).
            // Below: [compact schedule | score 1 | score 2].
            if (isLandscape) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Sets + options
                    Row(children: [
                      Expanded(child: _buildSetOverview()),
                      const SizedBox(width: 8),
                      optionsButton,
                    ]),
                    if (_isMatchComplete) ...[
                      const SizedBox(height: 4),
                      _buildLockBanner(
                        l10n.matchComplete,
                        winnerName: _match.winnerId != null
                            ? _tournament.teamById(_match.winnerId!)?.name
                            : null,
                      ),
                    ] else if (_currentSetDone) ...[
                      const SizedBox(height: 4),
                      _buildLockBanner(l10n.matchSetCompleteBanner),
                    ],
                    // Serves-first banner is intentionally omitted in landscape:
                    // it consumed the vertical room the schedule card needs and
                    // overflowed. Social Scramble likewise doesn't show it here.
                    const SizedBox(height: 4),
                    // Schedule + score cards
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Compact schedule — keep as narrow as possible
                          if (_tournament.paceAlertsEnabled) ...[
                            Expanded(
                              flex: 2,
                              child: _buildScheduleCard(compact: true),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Expanded(
                            flex: 5,
                            child: _buildScoreCard(
                              team: _leftTeam,
                              score: _leftScore,
                              isLeading: _isLeftLeading,
                              isTeam1: !_isSwapped,
                              onIncrement: scoreLocked ? null : () => _addScore(isLeft: true),
                              onDecrement: scoreLocked ? null : () => _removeScore(isLeft: true),
                              landscape: true,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 5,
                            child: _buildScoreCard(
                              team: _rightTeam,
                              score: _rightScore,
                              isLeading: _isRightLeading,
                              isTeam1: _isSwapped,
                              onIncrement: scoreLocked ? null : () => _addScore(isLeft: false),
                              onDecrement: scoreLocked ? null : () => _removeScore(isLeft: false),
                              landscape: true,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }

            // ── Portrait ───────────────────────────────────────────────────
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Text(
                      '${_team1?.name ?? 'TBD'} vs ${_team2?.name ?? 'TBD'}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // ── Gameplay Controls ───────────────────────────────────
                  _sectionHeader(
                    'Gameplay Controls',
                    Icons.sports_volleyball_rounded,
                    trailing: optionsButton,
                  ),
                  if (_tournament.paceAlertsEnabled) ...[
                    const SizedBox(height: 10),
                    _buildScheduleCard(),
                  ],
                  const SizedBox(height: 10),
                  _buildSetOverview(),

                  // ── Banners ─────────────────────────────────────────────
                  const SizedBox(height: 10),
                  if (_match.startedAt == null && !_isMatchComplete)
                    _buildServesFirstBanner(),
                  if (_isMatchComplete)
                    _buildLockBanner(
                      l10n.matchComplete,
                      winnerName: _match.winnerId != null
                          ? _tournament.teamById(_match.winnerId!)?.name
                          : null,
                    )
                  else if (_currentSetDone)
                    _buildLockBanner(l10n.matchSetCompleteBanner),

                  // ── Score cards ─────────────────────────────────────────
                  const SizedBox(height: 10),
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: _buildScoreCard(
                            team: _leftTeam,
                            score: _leftScore,
                            isLeading: _isLeftLeading,
                            isTeam1: !_isSwapped,
                            onIncrement: scoreLocked ? null : () => _addScore(isLeft: true),
                            onDecrement: scoreLocked ? null : () => _removeScore(isLeft: true),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildScoreCard(
                            team: _rightTeam,
                            score: _rightScore,
                            isLeading: _isRightLeading,
                            isTeam1: _isSwapped,
                            onIncrement: scoreLocked ? null : () => _addScore(isLeft: false),
                            onDecrement: scoreLocked ? null : () => _removeScore(isLeft: false),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Match Controls ──────────────────────────────────────
                  _sectionHeader('Match Controls', Icons.emoji_events_rounded),
                  const SizedBox(height: 10),
                  _buildMatchActions(),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        ),
        ),
      ),
    ), // Scaffold
    ); // PopScope
  }

  // ── Section header ────────────────────────────────────────────────────────

  Widget _sectionHeader(String title, IconData icon, {Widget? trailing}) => Row(
        children: [
          Icon(icon, size: 15, color: _kOlive),
          const SizedBox(width: 6),
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: _kOlive,
              letterSpacing: 0.4,
            ),
          ),
          if (trailing != null) ...[const Spacer(), trailing],
        ],
      );

  // ── Options sheet ─────────────────────────────────────────────────────────

  void _showOptions() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetCtx) => TournaQSheet(
        body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(AppLocalizations.of(context)!.matchOptions,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              _optionTile(
                sheetCtx,
                icon: Icons.swap_horiz_rounded,
                iconBg: _isMatchComplete ? Colors.grey.shade100 : _kGoldCream,
                iconColor: _isMatchComplete ? Colors.grey : _kGoldDark,
                label: AppLocalizations.of(context)!.scorecardSwapSides,
                subtitle: AppLocalizations.of(context)!.scorecardSwapSidesSubtitle,
                enabled: !_isMatchComplete,
                onTap: () {
                  Navigator.of(sheetCtx).pop();
                  setState(() => _isSwapped = !_isSwapped);
                },
              ),
              _optionTile(
                sheetCtx,
                icon: Icons.rotate_right_rounded,
                iconBg: _kOliveLight,
                iconColor: _kOlive,
                label: AppLocalizations.of(context)!.changeService,
                subtitle: AppLocalizations.of(context)!.changeServiceSubtitle,
                enabled: true,
                onTap: () {
                  Navigator.of(sheetCtx).pop();
                  setState(() {
                    final perSide = _tournament.playersPerSide;
                    _activePlayerIndex = (_activePlayerIndex + 1) % (2 * perSide);
                  });
                },
              ),
              _optionTile(
                sheetCtx,
                icon: Icons.history_rounded,
                iconBg: _kGoldCream,
                iconColor: _kGoldDark,
                label: AppLocalizations.of(context)!.pageGameplayHistory,
                subtitle: AppLocalizations.of(context)!.matchViewHistory,
                enabled: true,
                onTap: () {
                  Navigator.of(sheetCtx).pop();
                  _showHistory();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _optionTile(
    BuildContext sheetCtx, {
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String label,
    required String subtitle,
    required bool enabled,
    required VoidCallback onTap,
  }) =>
      ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 8),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        title: Text(label,
            style: TextStyle(
                fontWeight: FontWeight.w600,
                color: enabled ? Colors.black87 : Colors.grey)),
        subtitle: Text(subtitle,
            style: const TextStyle(fontSize: 12, color: Colors.black45)),
        onTap: enabled ? onTap : null,
      );

  // ── Schedule card ─────────────────────────────────────────────────────────

  Widget _scheduleChip(String label, Color fg, Color bg) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
        child: Text(label,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: fg)),
      );

  /// Pace status for the schedule strip — mirrors Scramble King's
  /// upcoming / due / overdue / completed tag.
  (Color, String) _scheduleStatus(AppLocalizations l10n, DateTime start, DateTime end) {
    if (_isMatchComplete) return (_kOlive, l10n.statusCompleted);
    if (_now.isAfter(end)) return (Colors.red.shade600, l10n.statusOverdue);
    if (_now.isAfter(start)) return (Colors.amber.shade700, l10n.statusDue);
    return (Colors.green.shade600, l10n.statusUpcoming);
  }

  Widget _buildScheduleCard({bool compact = false}) {
    final start = _match.scheduledStartTime;
    final end   = _match.scheduledEndTime;
    final now   = _now;

    if (start == null || end == null) {
      return Container(
        padding: EdgeInsets.symmetric(
            horizontal: compact ? 10 : 14, vertical: compact ? 8 : 12),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(children: [
          const Icon(Icons.schedule_rounded, size: 14, color: Colors.black38),
          const SizedBox(width: 6),
          if (!compact)
            Text(AppLocalizations.of(context)!.overviewSectionSchedule.toUpperCase(),
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                    color: Colors.black38, letterSpacing: 0.6)),
          const Spacer(),
          Text('${_tournament.minutesForRound(_match.round)} min',
              style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w700, color: Colors.black54)),
        ]),
      );
    }

    final inProgress = _match.startedAt != null && !_isMatchComplete;
    // only flag as "over" while the game is still live (not after completion)
    final isOverEnd  = now.isAfter(end) && !_isMatchComplete;

    String delta(int deltaMin) {
      if (deltaMin.abs() <= 1) return 'on time';
      return deltaMin > 0 ? '+${deltaMin}m' : '${deltaMin}m';
    }

    // ── Start chip ────────────────────────────────────────────────────────────
    // Once the match has started (or is complete), show actual start + delta.
    // Before start, show a live countdown to the scheduled slot.
    Widget startChip;
    if ((inProgress || _isMatchComplete) && _match.startedAt != null) {
      final actualStart = _match.startedAt!;
      final deltaMin    = _isMatchComplete
          ? actualStart.difference(start).inMinutes
          : now.difference(start).inMinutes;
      final isLate      = deltaMin > 1;
      final chipTime    = _isMatchComplete ? _fmtTime(actualStart) : _fmtTime(now);
      startChip = _scheduleChip(
        '$chipTime (${delta(deltaMin)})',
        isLate ? Colors.orange.shade700 : _kOlive,
        isLate ? Colors.orange.withValues(alpha: 0.12) : _kOliveLight,
      );
    } else {
      final minsToStart = start.difference(now).inMinutes;
      if (minsToStart > 0) {
        startChip = _scheduleChip('In ${minsToStart}m', _kOlive, _kOliveLight);
      } else if (minsToStart == 0) {
        startChip = _scheduleChip('Now', _kOlive, _kOliveLight);
      } else {
        startChip = _scheduleChip(
            '${-minsToStart}m late',
            Colors.orange.shade700,
            Colors.orange.withValues(alpha: 0.12));
      }
    }

    // ── End chip ──────────────────────────────────────────────────────────────
    // When complete, show actual completion time + delta from scheduled end.
    // Otherwise always show time remaining / over (visible even before start).
    Widget endChip;
    if (_isMatchComplete && _match.completedAt != null) {
      final actualEnd = _match.completedAt!;
      final deltaMin  = actualEnd.difference(end).inMinutes;
      final isOver    = deltaMin > 1;
      endChip = _scheduleChip(
        '✓ ${_fmtTime(actualEnd)} (${delta(deltaMin)})',
        isOver ? Colors.orange.shade700 : _kOlive,
        isOver ? Colors.orange.withValues(alpha: 0.12) : _kOliveLight,
      );
    } else {
      final minsToEnd = end.difference(now).inMinutes;
      if (minsToEnd > 0) {
        endChip = minsToEnd <= 5
            ? _scheduleChip('${minsToEnd}m left',
                Colors.orange.shade700, Colors.orange.withValues(alpha: 0.12))
            : _scheduleChip('${minsToEnd}m left', Colors.black54, Colors.grey.shade100);
      } else {
        final over = now.difference(end).inMinutes.clamp(0, 9999);
        endChip = _scheduleChip(
            '${over}m over',
            Colors.red.shade700,
            Colors.red.withValues(alpha: 0.1));
      }
    }

    final bgColor     = isOverEnd
        ? Colors.red.withValues(alpha: 0.06)
        : Colors.grey.shade50;
    final borderColor = isOverEnd
        ? Colors.red.withValues(alpha: 0.3)
        : Colors.grey.shade200;
    final labelColor  = isOverEnd ? Colors.red : Colors.black45;
    final timeColor   = isOverEnd ? Colors.red.shade700 : Colors.black87;

    final l10n = AppLocalizations.of(context)!;
    final (statusColor, statusText) = _scheduleStatus(l10n, start, end);

    // ── Compact card (landscape left column) ─────────────────────────────────
    // Full planned start/end block with live pace chips — mirrors the Social
    // Scramble scorecard so the landscape rail carries the same information.
    if (compact) {
      return Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(children: [
              Icon(Icons.schedule_rounded, size: 12, color: labelColor),
              const SizedBox(width: 4),
              Text(l10n.overviewSectionSchedule.toUpperCase(),
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: labelColor,
                      letterSpacing: 0.5)),
            ]),
            const SizedBox(height: 6),
            Row(children: [
              const Icon(Icons.play_circle_outline_rounded,
                  size: 11, color: Colors.black38),
              const SizedBox(width: 4),
              Text(l10n.scorecardPlannedStart,
                  style: const TextStyle(fontSize: 10, color: Colors.black45)),
            ]),
            const SizedBox(height: 2),
            Text(_fmtTime(start),
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: timeColor,
                    fontFeatures: const [FontFeature.tabularFigures()])),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: startChip,
            ),
            const SizedBox(height: 6),
            Row(children: [
              Icon(Icons.stop_circle_outlined,
                  size: 11,
                  color: isOverEnd ? Colors.red.shade300 : Colors.black38),
              const SizedBox(width: 4),
              Text(l10n.scorecardPlannedEnd,
                  style: const TextStyle(fontSize: 10, color: Colors.black45)),
            ]),
            const SizedBox(height: 2),
            Text(_fmtTime(end),
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: timeColor,
                    fontFeatures: const [FontFeature.tabularFigures()])),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: endChip,
            ),
            if (isOverEnd) ...[
              const SizedBox(height: 6),
              Row(children: [
                const Icon(Icons.warning_amber_rounded,
                    size: 12, color: Colors.red),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(l10n.scorecardOverSchedule,
                      style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.red)),
                ),
              ]),
            ],
          ],
        ),
      );
    }

    // ── Portrait card (collapsible) ───────────────────────────────────────────
    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header — always visible, taps to toggle
          GestureDetector(
            onTap: () => setState(() => _scheduleExpanded = !_scheduleExpanded),
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              child: Row(children: [
                Icon(Icons.schedule_rounded, size: 14, color: labelColor),
                const SizedBox(width: 6),
                Text('${_fmtTime(start)} – ${_fmtTime(end)}',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: timeColor)),
                const Spacer(),
                if (!_scheduleExpanded) ...[
                  _scheduleChip(statusText, statusColor,
                      statusColor.withValues(alpha: 0.14)),
                  const SizedBox(width: 6),
                ],
                Icon(
                  _scheduleExpanded
                      ? Icons.expand_less_rounded
                      : Icons.expand_more_rounded,
                  size: 18,
                  color: Colors.black38,
                ),
              ]),
            ),
          ),
          // Expanded content
          if (_scheduleExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(children: [
                    const Icon(Icons.play_circle_outline_rounded,
                        size: 13, color: Colors.black38),
                    const SizedBox(width: 6),
                    SizedBox(
                        width: 36,
                        child: Text(AppLocalizations.of(context)!.btnStart,
                            style: const TextStyle(fontSize: 11, color: Colors.black45))),
                    Text(_fmtTime(start),
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: timeColor,
                            fontFeatures: const [FontFeature.tabularFigures()])),
                    const Spacer(),
                    startChip,
                  ]),
                  const SizedBox(height: 6),
                  Row(children: [
                    Icon(Icons.stop_circle_outlined,
                        size: 13,
                        color: isOverEnd ? Colors.red.shade300 : Colors.black38),
                    const SizedBox(width: 6),
                    SizedBox(
                        width: 36,
                        child: Text(AppLocalizations.of(context)!.scorecardEnd,
                            style: const TextStyle(fontSize: 11, color: Colors.black45))),
                    Text(_fmtTime(end),
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: timeColor,
                            fontFeatures: const [FontFeature.tabularFigures()])),
                    const Spacer(),
                    endChip,
                  ]),
                  if (isOverEnd) ...[
                    const SizedBox(height: 8),
                    Row(children: [
                      const Icon(Icons.warning_amber_rounded,
                          size: 13, color: Colors.red),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(AppLocalizations.of(context)!.scorecardOverScheduleHurry,
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Colors.red)),
                      ),
                    ]),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ── Set overview ──────────────────────────────────────────────────────────

  Widget _buildSetOverview() {
    final maxSets = _fmt.setsPerGame;
    final sets = _match.sets;

    return Row(
      children: List.generate(maxSets, (i) {
        final hasSet = i < sets.length;
        final set = hasSet ? sets[i] : null;
        final isActive = i == _adapter.currentSetIndex;
        final isCompleted = set?.isCompleted ?? false;
        // The pending set tile (not yet a completed set entry) shows live scores
        // even when not the active view, so it doesn't flash "–" during navigation.
        final isPendingTile = !hasSet && i == sets.length;
        final displayScore1 = isActive && !isCompleted
            ? (_isSwapped ? _score2 : _score1)
            : isPendingTile
                ? (_isSwapped ? _adapter.pendingScore2 : _adapter.pendingScore1)
                : (set?.score1 ?? 0);
        final displayScore2 = isActive && !isCompleted
            ? (_isSwapped ? _score1 : _score2)
            : isPendingTile
                ? (_isSwapped ? _adapter.pendingScore1 : _adapter.pendingScore2)
                : (set?.score2 ?? 0);

        Color borderColor;
        Color bgColor;
        if (isActive) {
          borderColor = _kGold;
          bgColor = _kGoldCream;
        } else if (isCompleted) {
          borderColor = _kOlive;
          bgColor = _kOliveLight;
        } else {
          borderColor = Colors.grey.shade300;
          bgColor = Colors.grey.shade100;
        }

        String? winnerLabel;
        if (isCompleted && set != null) {
          final winnerName = set.score1 > set.score2
              ? (_team1?.name ?? '')
              : (_team2?.name ?? '');
          final short = winnerName.length > 7
              ? '${winnerName.substring(0, 7)}… ✓'
              : '$winnerName ✓';
          winnerLabel = short;
        }

        final card = Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: borderColor, width: isActive ? 2 : 1),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(
              '${isCompleted ? '● ' : ''}Set ${i + 1} · ${_fmt.pointsPerSet}',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: isCompleted ? AppColors.inverseSurface : isActive ? _kGold : Colors.grey,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              set == null && !isActive && !isPendingTile ? '–'
                  : isPendingTile && displayScore1 == 0 && displayScore2 == 0 ? '–'
                  : '$displayScore1–$displayScore2',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isActive ? _kGold : isCompleted ? _kOlive : Colors.grey.shade400,
              ),
            ),
            if (winnerLabel != null) ...[
              const SizedBox(height: 2),
              Text(
                winnerLabel,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: _kOlive,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ]),
        );

        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: i < maxSets - 1 ? 6 : 0),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _switchToSet(i),
              child: card,
            ),
          ),
        );
      }),
    );
  }

  // ── Lock banner ───────────────────────────────────────────────────────────

  // ── Serve suggestion banner ───────────────────────────────────────────────

  Widget _buildServesFirstBanner({bool landscape = false}) {
    final pid = _match.suggestedServingPlayerId;
    final name = pid == null ? null : [
      ..._team1?.players ?? [],
      ..._team2?.players ?? [],
    ].where((p) => p.appPlayerId == pid).firstOrNull?.name;

    if (!landscape && name == null) return const SizedBox.shrink();

    final startButton = ElevatedButton.icon(
      onPressed: _startMatch,
      icon: const Icon(Icons.play_arrow_rounded, size: 14),
      label: Text(AppLocalizations.of(context)!.btnStart, style: const TextStyle(fontWeight: FontWeight.w700)),
      style: ElevatedButton.styleFrom(
        backgroundColor: _kOlive,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );

    if (landscape) {
      return Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: _kOliveLight,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _kOlive.withValues(alpha: 0.3)),
        ),
        child: Row(children: [
          if (name != null) ...[
            Expanded(
              flex: 2,
              child: Row(children: [
                const Icon(Icons.sports_volleyball_rounded, size: 14, color: _kOlive),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    AppLocalizations.of(context)!.matchSuggestedToServe(name),
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w600, color: _kOlive),
                  ),
                ),
              ]),
            ),
            const SizedBox(width: 8),
          ],
          Expanded(flex: 1, child: startButton),
        ]),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _kOliveLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _kOlive.withValues(alpha: 0.3)),
      ),
      child: Row(children: [
        const Icon(Icons.sports_volleyball_rounded, size: 14, color: _kOlive),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            AppLocalizations.of(context)!.matchSuggestedToServe(name ?? ''),
            style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600, color: _kOlive),
          ),
        ),
      ]),
    );
  }

  // ── Referee suggestion banner ─────────────────────────────────────────────

  Widget _buildRefereeBanner() {
    final refName = _match.refereeTeamId != null
        ? _tournament.teamById(_match.refereeTeamId!)?.name
        : null;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.blueGrey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.blueGrey.shade200),
      ),
      child: Row(children: [
        Icon(Icons.gavel_rounded, size: 14, color: Colors.blueGrey.shade600),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            refName != null
                ? AppLocalizations.of(context)!.matchSuggestedReferee(refName)
                : AppLocalizations.of(context)!.matchAssignRefereeManually,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.blueGrey.shade700),
          ),
        ),
      ]),
    );
  }

  Widget _buildLockBanner(String message, {String? winnerName}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(children: [
        const Icon(Icons.lock_rounded, size: 16, color: Colors.black54),
        const SizedBox(width: 8),
        Expanded(
          child: Text(message,
              style: const TextStyle(fontSize: 12, color: Colors.black54, fontWeight: FontWeight.w500)),
        ),
        if (winnerName != null) ...[
          const SizedBox(width: 8),
          Text('🏆 $winnerName',
              style: const TextStyle(fontSize: 12, color: _kGoldDark, fontWeight: FontWeight.w700)),
        ],
      ]),
    );
  }

  // ── Score card ────────────────────────────────────────────────────────────

  Widget _buildScoreCard({
    required KoTeam? team,
    required int score,
    required bool isLeading,
    required bool isTeam1,
    required VoidCallback? onIncrement,
    required VoidCallback? onDecrement,
    bool landscape = false,
  }) {
    final teamColor = isTeam1 ? _kGold : _kOlive;
    final cardBg = isTeam1
        ? (isLeading ? _kGoldCardLeading : _kGoldCardBg)
        : (isLeading ? _kOliveCardLeading : _kOliveCardBg);
    final disabled = onIncrement == null;

    final pillWidgets = team == null
        ? <Widget>[]
        : team.players.asMap().entries
            .map((e) => PlayerPill(
                  name: e.value.name,
                  isServing: _isTeam1Serving == isTeam1 && _activePlayerOnSide == e.key,
                  activeColor: teamColor,
                  compact: true,
                ))
            .toList();

    final buttonsRow = Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        IconButton.filled(
          icon: const Icon(Icons.remove),
          onPressed: onDecrement,
          iconSize: landscape ? 20 : 24,
          style: IconButton.styleFrom(
            backgroundColor: disabled ? Colors.grey.shade300 : teamColor,
            foregroundColor: disabled ? Colors.grey : Colors.white,
          ),
        ),
        IconButton.filled(
          icon: const Icon(Icons.add),
          onPressed: onIncrement,
          iconSize: landscape ? 20 : 24,
          style: IconButton.styleFrom(
            backgroundColor: disabled ? Colors.grey.shade300 : teamColor,
            foregroundColor: disabled ? Colors.grey : Colors.white,
          ),
        ),
      ],
    );

    Widget cardContent;
    if (landscape) {
      cardContent = LayoutBuilder(
        builder: (context, constraints) {
          return Column(children: [
            Text(
              team?.name ?? 'TBD',
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Colors.black87),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            PillGrid(pills: pillWidgets),
            Expanded(
              child: FittedBox(
                fit: BoxFit.contain,
                child: Text(
                  '$score',
                  style: TextStyle(
                    fontSize: 120,
                    fontWeight: FontWeight.bold,
                    height: 1.0,
                    color: disabled ? Colors.black38 : Colors.black87,
                  ),
                ),
              ),
            ),
            if (_fmt.setsPerGame > 1)
              Text(
                isTeam1 ? '$_team1SetsWon sets' : '$_team2SetsWon sets',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: teamColor.withValues(alpha: 0.8)),
              ),
            const SizedBox(height: 4),
            buttonsRow,
          ]);
        },
      );
    } else {
      cardContent = Column(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Text(
            team?.name ?? 'TBD',
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Colors.black87),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          PillGrid(pills: pillWidgets, stacked: true),
          const Spacer(),
          Text(
            '$score',
            style: TextStyle(
              fontSize: 56,
              fontWeight: FontWeight.bold,
              height: 1.0,
              color: disabled ? Colors.black38 : Colors.black87,
            ),
          ),
          if (_fmt.setsPerGame > 1)
            Text(
              isTeam1 ? '$_team1SetsWon sets' : '$_team2SetsWon sets',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: teamColor.withValues(alpha: 0.8)),
            ),
          const SizedBox(height: 4),
          buttonsRow,
        ],
      );
    }

    return Card(
      color: cardBg,
      elevation: isLeading ? 6 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: teamColor.withValues(alpha: isLeading ? 1.0 : 0.55),
          width: isLeading ? 2.5 : 1.5,
        ),
      ),
      child: Padding(
        padding: landscape
            ? const EdgeInsets.fromLTRB(10, 8, 10, 8)
            : const EdgeInsets.fromLTRB(10, 12, 10, 10),
        child: cardContent,
      ),
    );
  }

  // ── Manual score entry ────────────────────────────────────────────────────

  Widget _scoreInputRow(String label, TextEditingController ctrl, Color color) =>
      Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 64,
            child: TextField(
              controller: ctrl,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              autofocus: true,
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                isDense: true,
              ),
            ),
          ),
        ],
      );

  Future<void> _showManualScoreDialog() async {
    final setNum = _match.sets.where((s) => s.isCompleted).length + 1;
    final ctrl1 = TextEditingController(text: '$_score1');
    final ctrl2 = TextEditingController(text: '$_score2');
    try {
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: Colors.white,
          titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          contentPadding: const EdgeInsets.fromLTRB(24, 14, 24, 0),
          actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          title: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                    color: _kOliveLight, borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.edit_rounded, color: _kOlive, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                _fmt.setsPerGame > 1
                    ? AppLocalizations.of(context)!.matchSetNScore(setNum)
                    : AppLocalizations.of(context)!.matchSetScore,
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 16),
                _scoreInputRow(_team1?.name ?? 'Team 1', ctrl1, _kGold),
                const SizedBox(height: 10),
                _scoreInputRow(_team2?.name ?? 'Team 2', ctrl2, _kOlive),
              ],
            ),
          ),
          actions: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text(AppLocalizations.of(context)!.btnCancel),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kOlive,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () {
                      final s1 = int.tryParse(ctrl1.text) ?? _score1;
                      final s2 = int.tryParse(ctrl2.text) ?? _score2;
                      Navigator.of(ctx).pop();
                      setState(() {
                        _score1 = s1;
                        _score2 = s2;
                      });
                    },
                    child: Text(AppLocalizations.of(context)!.btnApply,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    } finally {
      Future.delayed(const Duration(milliseconds: 300), () {
        ctrl1.dispose();
        ctrl2.dispose();
      });
    }
  }

  // ── Match actions ─────────────────────────────────────────────────────────

  void _startMatch() {
    _adapter.updateMatch((m) => m.copyWith(
      startedAt: DateTime.now(),
      status: KoMatchStatus.inProgress,
    ));
    setState(() {});
  }

  String _fmtTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  Widget _chip(IconData icon, String label, Color bg, Color fg, {double iconAngle = 0}) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Transform.rotate(angle: iconAngle, child: Icon(icon, size: 11, color: fg)),
          const SizedBox(width: 3),
          Text(label,
              style: TextStyle(
                  fontSize: 11, color: fg, fontWeight: FontWeight.w600)),
        ]),
      );

  Widget _buildMatchActions() {
    final isOneSet = _fmt.setsPerGame == 1;
    final notStarted = _match.startedAt == null && !_isMatchComplete;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildRefereeBanner(),
        const SizedBox(height: 10),
        // Info chips — the scheduled start/end live in the schedule card above,
        // so no separate "starts at" pill here.
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            _chip(Icons.account_tree_rounded, _bracketPositionLabel,
                _kGoldCream, _kGoldDark, iconAngle: pi),
            if (_match.courtAssignment != null)
              _chip(Icons.crop_square_rounded,
                  AppLocalizations.of(context)!.matchCourtLabel(_match.courtAssignment!), _kOliveLight, _kOlive),
            _chip(Icons.filter_1_rounded,
                '${_fmt.setsPerGame} set${_fmt.setsPerGame == 1 ? '' : 's'}',
                Colors.grey.shade100, Colors.black45),
            _chip(Icons.info_outline_rounded, '${_fmt.pointsPerSet} pts',
                Colors.grey.shade100, Colors.black45),
            _chip(Icons.timer_rounded,
                AppLocalizations.of(context)!.labelMinutes(_tournament.minutesForRound(_match.round)),
                _kOliveLight, _kOlive),
          ],
        ),
        const SizedBox(height: 12),

        // Start Match (shown when not yet started)
        if (notStarted) ...[
          ElevatedButton.icon(
            onPressed: _startMatch,
            icon: const Icon(Icons.play_arrow_rounded, size: 18),
            label: Text(AppLocalizations.of(context)!.scorecardStartMatch,
                style: const TextStyle(fontWeight: FontWeight.w700)),
            style: ElevatedButton.styleFrom(
              backgroundColor: _kOlive,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 8),
        ],

        // Complete Set / Undo Set (multi-set, always visible once started)
        if (!isOneSet && !notStarted) ...[
          ElevatedButton.icon(
            onPressed: _isMatchComplete
                ? null
                : _currentSetDone
                    ? _undoSetCompletion
                    : _completeSet,
            icon: Icon(
              _currentSetDone
                  ? Icons.undo_rounded
                  : Icons.check_circle_outline_rounded,
              size: 18,
            ),
            label: Text(
              _currentSetDone
                  ? AppLocalizations.of(context)!.matchUndoSet
                  : AppLocalizations.of(context)!.matchCompleteSet,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _isMatchComplete
                  ? null
                  : _currentSetDone
                      ? Colors.grey.shade500
                      : _kGold,
              foregroundColor: _isMatchComplete ? null : Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 8),
        ],

        // Complete / Undo Match (shown once started)
        if (!notStarted) ...[
          ElevatedButton.icon(
            onPressed:
                _isMatchComplete ? _undoMatchCompletion : _completeMatch,
            icon: Icon(
              _isMatchComplete
                  ? Icons.undo_rounded
                  : Icons.emoji_events_rounded,
              size: 18,
            ),
            label: Text(
              _isMatchComplete
                  ? AppLocalizations.of(context)!.matchUndoMatchCompletion
                  : AppLocalizations.of(context)!.matchCompleteMatch,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _kOlive,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 8),
        ],

        if (!notStarted && !_isMatchComplete && !_currentSetDone) ...[
          OutlinedButton.icon(
            onPressed: _showManualScoreDialog,
            icon: const Icon(Icons.edit_rounded, size: 18),
            label: Text(AppLocalizations.of(context)!.matchSetScoreManually),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 8),
        ],
        OutlinedButton.icon(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_rounded, size: 18),
          label: Text(AppLocalizations.of(context)!.matchBackToBracket),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }
}
