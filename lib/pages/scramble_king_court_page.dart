import 'dart:math';
import 'package:flutter/material.dart';
import '../app/app_colors.dart';
import '../l10n/app_localizations.dart';
import '../models/scramble_king_tournament.dart';
import '../services/scramble_king_service.dart';
import '../services/scramble_king_storage_service.dart';
import '../widgets/scramble_timer_widget.dart';
import '../widgets/sheet_helpers.dart';
import '../widgets/tournaq_app_bar.dart';

const _kGold = AppColors.goldDark;
const _kGoldCardBg = AppColors.goldCardBg;
const _kGoldCardLeading = AppColors.goldCardLeading;
const _kOlive = AppColors.olive;
const _kOliveLight = AppColors.oliveLight;

/// Live scoring for one court within one round, then — once the round ends
/// for this court — a ranked, editable results view.
///
/// The outer shell (Start → countdown timer → completion → results,
/// round-complete reflow) mirrors `ScrambleScorecardPage`'s game lifecycle.
/// The live-play widget tree is a faithful port of King of the Court's
/// scoreboard (`_buildPortraitBody`/`_buildLandscapeBody` + its tiles),
/// generalized from a single team to a rotating queue of fixed teams.
class ScrambleKingCourtPage extends StatefulWidget {
  final ScrambleKingTournament tournament;
  final String roundId;
  final int courtNumber;
  final void Function(ScrambleKingTournament) onChanged;

  const ScrambleKingCourtPage({
    super.key,
    required this.tournament,
    required this.roundId,
    required this.courtNumber,
    required this.onChanged,
  });

  @override
  State<ScrambleKingCourtPage> createState() => _ScrambleKingCourtPageState();
}

class _ScrambleKingCourtPageState extends State<ScrambleKingCourtPage> {
  late ScrambleKingTournament _t;

  String? _onCourtSlotId;
  String? _onCourtTempPartnerId;
  int _currentPoints = 0;
  String? _challengerSlotId;
  String? _lastEjectedChallengerSlotId;
  List<String> _pool = [];

  String? _adminPlayerId;
  String? _nextAdminPlayerId;

  final _matchTimerKey = GlobalKey<ScrambleTimerWidgetState>();
  final _stintWatch = Stopwatch();
  Duration? _timerInitialRemaining;
  bool _timerRunning = false;

  ScrambleKingRound get _round => _t.getRound(widget.roundId)!;
  ScrambleKingCourtFormation get _formation => _round.getCourt(widget.courtNumber)!;
  bool get _hasStarted => _formation.actualStartTime != null;
  bool get _isAutoMode => _t.assignmentMode != ScrambleKingAssignmentMode.manual;
  bool get _isAllPlay => _t.assignmentMode == ScrambleKingAssignmentMode.automatedAllPlay;

  /// The slot (team or floater) containing the current admin player.
  String? get _adminSlotId {
    if (_adminPlayerId == null) return null;
    if (_formation.floaterSlot?.playerId == _adminPlayerId) {
      return _formation.floaterSlot!.slotId;
    }
    try {
      final teamSlot = _formation.teamSlots.firstWhere(
          (s) => s.playerIds.contains(_adminPlayerId));
      return teamSlot.slotId;
    } catch (_) {
      return null;
    }
  }
  bool get _strikeEnabled => _t.strikePoints > 0;
  bool get _hasCourt => _onCourtSlotId != null;

  List<ScrambleKingStint> get _courtStints =>
      _t.getStintsForCourt(_round.id, widget.courtNumber);

  bool get _canEjectChallenger => _isAutoMode && _challengerSlotId != null;
  bool get _canUndoEjectChallenger => _lastEjectedChallengerSlotId != null;

  /// Mirrors King of the Court's `_canUndo`: available right after an
  /// ejection, either because no one is on court yet (manual mode, before
  /// the next pick) or because we're in an automated mode where the new
  /// team started immediately and can be safely discarded.
  bool get _canUndoEjectCourt => _courtStints.isNotEmpty && (!_hasCourt || _isAutoMode);

  /// Next-best queued slot after the on-court + challenger slots (automated).
  String? get _upNextSlotId {
    if (!_isAutoMode || _pool.isEmpty) return null;
    final ranked = ScrambleKingService.rankQueue(
        queueSlotIds: _pool, onCourtSlotId: _onCourtSlotId, courtStints: _courtStints);
    return ranked.isNotEmpty ? ranked.first : null;
  }

  @override
  void initState() {
    super.initState();
    _t = widget.tournament;
    if (!_hasStarted && !_formation.isCompleted) {
      // Opening a court goes straight into live play — no separate "Start"
      // confirmation screen. Stamp the start time directly (no setState:
      // this runs before the first build) and persist after the first frame.
      final updatedFormation = _formation.copyWith(actualStartTime: DateTime.now());
      _t = _t.updateRound(_round.updateCourt(updatedFormation));
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScrambleKingStorageService.save(_t);
        widget.onChanged(_t);
      });
    }
    if (_hasStarted && !_formation.isCompleted) {
      _resumeLiveState();
    }
  }

  /// Restores live-play state for an in-progress court — used both when
  /// first opening a court that's already started, and when undoing a
  /// "Finish Court" action. The round timer only actually starts once a
  /// team is placed on court via `_startSlot` (automated modes do so
  /// synchronously below via `_initStart`; manual mode waits for the
  /// coach's first pick), never merely because the court was opened.
  void _resumeLiveState({ScrambleKingStint? restoredStint}) {
    final elapsed = DateTime.now().difference(_formation.actualStartTime!);
    final remaining = _round.matchDuration - elapsed;
    _timerInitialRemaining = remaining <= Duration.zero ? Duration.zero : remaining;

    if (_isAllPlay && _adminPlayerId == null) {
      final allIds = [
        for (final s in _formation.teamSlots) ...s.playerIds,
        if (_formation.floaterSlot != null) _formation.floaterSlot!.playerId,
      ];
      if (allIds.isNotEmpty) _adminPlayerId = allIds[Random().nextInt(allIds.length)];
    }

    _pool = List.from(ScrambleKingService.initialQueueOrder(_formation));
    if (_adminSlotId != null) _pool.remove(_adminSlotId);

    if (restoredStint != null) {
      _onCourtSlotId = restoredStint.turnSlotId;
      _onCourtTempPartnerId = restoredStint.isFloaterStint ? restoredStint.playerIds[1] : null;
      _currentPoints = restoredStint.points;
      _timerRunning = true;
      _pool.remove(restoredStint.turnSlotId);
      _recomputeChallenger();
    } else {
      _initStart();
    }
  }

  @override
  void dispose() {
    _stintWatch.stop();
    super.dispose();
  }

  void _updateTournament(ScrambleKingTournament updated) {
    setState(() => _t = updated);
    ScrambleKingStorageService.save(_t);
    widget.onChanged(_t);
  }

  String _nameFor(String playerId) => _t.getPlayer(playerId)?.name ?? '?';

  String? _teamNameForSlot(String slotId) {
    for (final s in _formation.teamSlots) {
      if (s.slotId == slotId) return s.teamName;
    }
    return null;
  }

  /// The per-player names shown as chips for a queued slot (2 for a team,
  /// 1 for the floater slot).
  List<String> _slotChipNames(String slotId) {
    if (slotId == _formation.floaterSlot?.slotId) {
      return [_nameFor(_formation.floaterSlot!.playerId)];
    }
    final team = _formation.teamSlots.firstWhere((s) => s.slotId == slotId);
    return team.playerIds.map(_nameFor).toList();
  }

  List<String> _onCourtChipNames() {
    if (_onCourtSlotId == null) return [];
    if (_onCourtSlotId == _formation.floaterSlot?.slotId) {
      return [
        _nameFor(_formation.floaterSlot!.playerId),
        if (_onCourtTempPartnerId != null) _nameFor(_onCourtTempPartnerId!),
      ];
    }
    return _slotChipNames(_onCourtSlotId!);
  }

  // ── Starting a slot on court ────────────────────────────────────────────

  void _startSlot(String slotId, {String? explicitTempPartnerId}) {
    String? tempPartner;
    if (slotId == _formation.floaterSlot?.slotId) {
      if (explicitTempPartnerId != null) {
        tempPartner = explicitTempPartnerId;
      } else {
        final otherTeams = _formation.teamSlots.where((s) => _pool.contains(s.slotId)).toList();
        final pick = _t.oddPlayerMode == ScrambleKingOddPlayerMode.jumper
            ? ScrambleKingService.pickJumperPartner(
                otherQueuedTeams: otherTeams, courtStints: _courtStints)
            : ScrambleKingService.pickPlaceholderPartner(otherQueuedTeams: otherTeams);
        tempPartner = pick?.playerId;
      }
    }
    setState(() {
      _onCourtSlotId = slotId;
      _onCourtTempPartnerId = tempPartner;
      _currentPoints = 0;
      _timerRunning = true;
    });
    _matchTimerKey.currentState?.start();
    _stintWatch
      ..reset()
      ..start();
  }

  void _initStart() {
    if (_pool.isEmpty || !_isAutoMode) return;
    final ranked = ScrambleKingService.rankQueue(
        queueSlotIds: _pool, onCourtSlotId: null, courtStints: _courtStints);
    if (ranked.isEmpty) return;
    final first = ranked.first;
    _pool.remove(first);
    _startSlot(first);
    _recomputeChallenger();
  }

  void _pickManualStart(String slotId) {
    if (slotId == _formation.floaterSlot?.slotId) {
      _showFloaterPartnerPicker((partnerId) {
        setState(() => _pool.remove(slotId));
        _startSlot(slotId, explicitTempPartnerId: partnerId);
      });
      return;
    }
    setState(() => _pool.remove(slotId));
    _startSlot(slotId);
  }

  void _showFloaterPartnerPicker(void Function(String playerId) onPicked) {
    final l10n = AppLocalizations.of(context)!;
    final otherTeams = _formation.teamSlots.where((s) => _pool.contains(s.slotId)).toList();
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.scrambleKingPickFloaterPartner,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final team in otherTeams)
                    for (final pid in team.playerIds)
                      ActionChip(
                        label: Text(_nameFor(pid)),
                        onPressed: () {
                          Navigator.of(ctx).pop();
                          onPicked(pid);
                        },
                      ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Automated challenger pipeline ────────────────────────────────────────

  void _recomputeChallenger() {
    if (!_isAutoMode) return;
    final ranked = ScrambleKingService.rankQueue(
        queueSlotIds: _pool, onCourtSlotId: _onCourtSlotId, courtStints: _courtStints);
    setState(() {
      _challengerSlotId = ranked.isNotEmpty ? ranked.first : null;
      if (_challengerSlotId != null) _pool.remove(_challengerSlotId);
    });
    _updateAdminHandoffCheck();
  }

  void _updateAdminHandoffCheck() {
    if (!_isAllPlay || _adminPlayerId == null || _adminSlotId == null) return;
    final needed = ScrambleKingService.wouldRankFirst(
        slotId: _adminSlotId!,
        queueSlotIds: _pool,
        onCourtSlotId: _onCourtSlotId,
        courtStints: _courtStints);
    if (needed && _nextAdminPlayerId == null) {
      final onCourtTeam = _formation.teamSlots
          .where((s) => s.slotId == _onCourtSlotId)
          .firstOrNull;
      if (onCourtTeam != null) {
        setState(() => _nextAdminPlayerId =
            onCourtTeam.playerIds[Random().nextInt(onCourtTeam.playerIds.length)]);
      }
    } else if (!needed && _nextAdminPlayerId != null) {
      setState(() => _nextAdminPlayerId = null);
    }
  }

  void _ejectChallenger() {
    if (!_canEjectChallenger) return;
    // Promote exactly the slot already shown as "Up Next", rather than
    // re-ranking the pool from scratch — a fresh rank can tie-break back to
    // the slot we just ejected (e.g. neither has played yet this round), so
    // re-ranking risks silently "ejecting" nobody.
    final promoted = _upNextSlotId;
    setState(() {
      _lastEjectedChallengerSlotId = _challengerSlotId;
      _pool.add(_challengerSlotId!);
      _challengerSlotId = promoted;
      if (promoted != null) _pool.remove(promoted);
    });
  }

  void _undoEjectChallenger() {
    if (_lastEjectedChallengerSlotId == null) return;
    setState(() {
      if (_challengerSlotId != null) _pool.add(_challengerSlotId!);
      _pool.remove(_lastEjectedChallengerSlotId);
      _challengerSlotId = _lastEjectedChallengerSlotId;
      _lastEjectedChallengerSlotId = null;
    });
  }

  // ── Scoring / ejection ────────────────────────────────────────────────────

  void _addPoint() {
    if (!_hasCourt || !_timerRunning) return;
    setState(() => _currentPoints++);
    if (_strikeEnabled && _currentPoints >= _t.strikePoints) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _ejectCourt(reason: ScrambleKingStintEndReason.strike));
    }
  }

  void _removePoint() {
    if (!_hasCourt || !_timerRunning || _currentPoints <= 0) return;
    setState(() => _currentPoints--);
  }

  ScrambleKingStint _buildStint({required ScrambleKingStintEndReason reason}) {
    final isFloaterTurn = _onCourtSlotId == _formation.floaterSlot?.slotId;
    final creditSlotId = isFloaterTurn
        ? _formation.teamSlots
            .firstWhere((s) => s.playerIds.contains(_onCourtTempPartnerId))
            .slotId
        : _onCourtSlotId!;
    final playerIds = isFloaterTurn
        ? [_formation.floaterSlot!.playerId, _onCourtTempPartnerId!]
        : _formation.teamSlots.firstWhere((s) => s.slotId == _onCourtSlotId!).playerIds;

    return ScrambleKingStint(
      id: ScrambleKingStint.generateId(),
      roundId: _round.id,
      courtNumber: widget.courtNumber,
      turnSlotId: _onCourtSlotId!,
      creditSlotId: creditSlotId,
      playerIds: playerIds,
      isFloaterStint: isFloaterTurn,
      standInPlayerId: isFloaterTurn ? _formation.floaterSlot!.playerId : null,
      points: _currentPoints,
      gamesWon: reason == ScrambleKingStintEndReason.strike ? 1 : 0,
      startTime: DateTime.now().subtract(_stintWatch.elapsed),
      endTime: DateTime.now(),
      endReason: reason,
    );
  }

  void _ejectCourt({required ScrambleKingStintEndReason reason}) {
    if (_onCourtSlotId == null) return;
    final stint = _buildStint(reason: reason);
    _stintWatch
      ..stop()
      ..reset();

    final ejectedSlot = _onCourtSlotId!;
    setState(() {
      _pool.add(ejectedSlot);
      _onCourtSlotId = null;
      _onCourtTempPartnerId = null;
      _currentPoints = 0;

      if (_isAllPlay && _nextAdminPlayerId != null && _adminSlotId != null) {
        _pool.add(_adminSlotId!);
        _adminPlayerId = _nextAdminPlayerId;
        _nextAdminPlayerId = null;
        if (_adminSlotId != null) _pool.remove(_adminSlotId);
      }
    });
    _updateTournament(_t.addStint(stint));

    if (_isAutoMode && _challengerSlotId != null) {
      final next = _challengerSlotId!;
      setState(() => _challengerSlotId = null);
      _startSlot(next);
      _recomputeChallenger();
    }
  }

  /// Ported from KOTC's `_undoEjection` — a "soft" undo: restores the last
  /// ejected slot + their points, but resets everyone else to a flat pool
  /// and lets the challenger be freshly recomputed, rather than reversing
  /// the promotion chain step by step.
  void _undoEjectCourt() {
    if (!_canUndoEjectCourt) return;
    if (_hasCourt) {
      _stintWatch
        ..stop()
        ..reset();
    }
    final lastStint = _courtStints.last;
    final restoredSlotId = lastStint.turnSlotId;
    setState(() {
      _onCourtSlotId = restoredSlotId;
      _onCourtTempPartnerId = lastStint.isFloaterStint ? lastStint.playerIds[1] : null;
      _currentPoints = lastStint.points;
      _pool = List.from(ScrambleKingService.initialQueueOrder(_formation))..remove(restoredSlotId);
      if (_adminSlotId != null) _pool.remove(_adminSlotId);
      _challengerSlotId = null;
      _lastEjectedChallengerSlotId = null;
    });
    _updateTournament(_t.copyWith(stints: _t.stints.where((s) => s.id != lastStint.id).toList()));
    _stintWatch.reset();
    if (_timerRunning) _stintWatch.start();
    _recomputeChallenger();
  }

  // ── Round-end handling (mirrors ScrambleScorecardPage's timer-finished +
  // _reflowIfRoundComplete pattern) ────────────────────────────────────────

  void _onMatchTimerFinished() {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _timerRunning = false);
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
        contentPadding: const EdgeInsets.fromLTRB(24, 14, 24, 0),
        actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        title: Row(children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
                color: AppColors.goldCream, borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.timer_off_rounded, color: _kGold, size: 20),
          ),
          const SizedBox(width: 12),
          Text(l10n.kotcTimeIsUp,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
        ]),
        content: Text(l10n.scrambleKingRoundEndedBody,
            style: const TextStyle(fontSize: 14, height: 1.5)),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                _completeCourt();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _kGold,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: Text(l10n.scrambleKingCompleteRound,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  void _completeCourt() {
    var updated = _t;
    if (_onCourtSlotId != null) {
      updated = updated.addStint(_buildStint(reason: ScrambleKingStintEndReason.timeout));
    }
    final round = updated.getRound(widget.roundId)!;
    final formation = round.getCourt(widget.courtNumber)!;
    final updatedFormation = formation.copyWith(actualEndTime: DateTime.now());
    updated = updated.updateRound(round.updateCourt(updatedFormation));
    updated = _reflowIfRoundComplete(updated, round.id);

    _stintWatch
      ..stop()
      ..reset();
    _matchTimerKey.currentState?.pause();
    setState(() {
      _onCourtSlotId = null;
      _onCourtTempPartnerId = null;
      _currentPoints = 0;
    });
    _updateTournament(updated);
  }

  ScrambleKingTournament _reflowIfRoundComplete(ScrambleKingTournament updated, String roundId) {
    final round = updated.getRound(roundId)!;
    if (!round.courts.every((c) => c.isCompleted)) return updated;

    final now = DateTime.now();
    final actualEnd =
        round.courts.map((c) => c.actualEndTime ?? now).reduce((a, b) => a.isAfter(b) ? a : b);
    updated = updated.updateRound(round.copyWith(actualEndTime: actualEnd));

    if (actualEnd.isBefore(round.scheduledMatchEndTime)) {
      return ScrambleKingService.reflowAllPending(updated);
    }
    return updated;
  }

  Future<void> _confirmFinishCourt() async {
    final l10n = AppLocalizations.of(context)!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(l10n.scrambleKingFinishCourtTitle),
        content: Text(l10n.scrambleKingFinishCourtBody),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text(l10n.btnCancel)),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: _kOlive, foregroundColor: Colors.white),
            child: Text(l10n.scrambleKingFinishCourt),
          ),
        ],
      ),
    );
    if (ok == true) _completeCourt();
  }

  bool get _canUndoFinishCourt => _formation.isCompleted;

  /// Reverses `_completeCourt()` — clears the court's completion, removes
  /// the synthetic `timeout` stint if one was added (crediting whoever was
  /// on court their partial points), and drops back into live play via the
  /// same `_resumeLiveState` path used to cold-open an in-progress court.
  ///
  /// Known limitation: if this was the last court in its round to finish
  /// early, `_completeCourt` may have already triggered
  /// `ScrambleKingService.reflowAllPending`, rescheduling other rounds —
  /// undoing this one court does not reverse that schedule ripple.
  void _undoFinishCourt() {
    if (!_canUndoFinishCourt) return;
    var updated = _t;
    final stints = updated.getStintsForCourt(_round.id, widget.courtNumber);
    final restoredStint =
        (stints.isNotEmpty && stints.last.endReason == ScrambleKingStintEndReason.timeout)
            ? stints.last
            : null;
    if (restoredStint != null) {
      updated = updated.copyWith(stints: updated.stints.where((s) => s.id != restoredStint.id).toList());
    }
    final round = updated.getRound(widget.roundId)!;
    final formation = round.getCourt(widget.courtNumber)!;
    updated = updated.updateRound(round.updateCourt(formation.copyWith(clearActualEndTime: true)));

    setState(() {
      _t = updated;
      _resumeLiveState(restoredStint: restoredStint);
    });
    ScrambleKingStorageService.save(_t);
    widget.onChanged(_t);
  }

  // ── Manual score override (results view) ─────────────────────────────────

  Future<void> _editTeamResult(ScrambleKingTeamResult team) async {
    final gamesCtrl = TextEditingController(text: '${team.gamesWon}');
    final pointsCtrl = TextEditingController(text: '${team.points}');
    final l10n = AppLocalizations.of(context)!;
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(l10n.scrambleKingEditTeamResult),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: gamesCtrl,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: InputDecoration(
                  labelText: l10n.scrambleKingGamesWonLabel,
                  border: const OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: pointsCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                  labelText: l10n.scrambleKingPointsLabel,
                  border: const OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: Text(l10n.btnCancel)),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.btnSave),
          ),
        ],
      ),
    );
    if (result != true) return;
    final updatedFormation = _formation.copyWith(
      manualGamesWon: {
        ..._formation.manualGamesWon,
        team.slotId: int.tryParse(gamesCtrl.text) ?? team.gamesWon,
      },
      manualTeamPoints: {
        ..._formation.manualTeamPoints,
        team.slotId: int.tryParse(pointsCtrl.text) ?? team.points,
      },
    );
    _updateTournament(_t.updateRound(_round.updateCourt(updatedFormation)));
  }

  // ── Ranking sheet (King of the Court "Player Stats" style, but editable
  // and team-scoped to this court's current round) ─────────────────────────

  void _showRanking() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final l10n = AppLocalizations.of(ctx)!;
          final result =
              ScrambleKingService.computeCourtRoundResult(_t, _round.id, widget.courtNumber);
          final totalPoints = result.teamResults.fold<int>(0, (a, t) => a + t.points);

          return TournaQSheet(
            body: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(l10n.scrambleKingScorecard,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text(
                    l10n.scrambleKingTeamsSummary(result.teamResults.length, totalPoints),
                    style: const TextStyle(fontSize: 13, color: Colors.black45),
                  ),
                  const SizedBox(height: 16),
                  _buildRankingTable(l10n, onEdited: () => setSheetState(() {})),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showAdminOverrideSheet() {
    if (!_isAllPlay) return;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final l10n = AppLocalizations.of(ctx)!;
          final poolPlayers = <(String id, String name)>[];
          for (final slotId in _pool) {
            if (slotId == _formation.floaterSlot?.slotId) {
              poolPlayers
                  .add((_formation.floaterSlot!.playerId, _nameFor(_formation.floaterSlot!.playerId)));
            } else {
              final team = _formation.teamSlots.firstWhere((s) => s.slotId == slotId);
              for (final pid in team.playerIds) {
                poolPlayers.add((pid, _nameFor(pid)));
              }
            }
          }

          return TournaQSheet(
            body: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(l10n.kotcChangeAdmin,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text(
                    l10n.kotcChangeAdminSubtitle,
                    style: const TextStyle(fontSize: 13, color: Colors.black45),
                  ),
                  const SizedBox(height: 16),
                  for (final (pid, name) in poolPlayers)
                    Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      child: Material(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(10),
                        child: InkWell(
                          onTap: () {
                            Navigator.pop(ctx);
                            setState(() {
                              if (_adminSlotId != null) _pool.add(_adminSlotId!);
                              _adminPlayerId = pid;
                              _nextAdminPlayerId = null;
                              if (_adminSlotId != null) _pool.remove(_adminSlotId!);
                            });
                          },
                          borderRadius: BorderRadius.circular(10),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            child: Text(name,
                                style: const TextStyle(
                                    fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87)),
                          ),
                        ),
                      ),
                    ),
                  if (_nextAdminPlayerId != null) ...[
                    const SizedBox(height: 16),
                    Text(l10n.kotcNextAdmin,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.black45)),
                    const SizedBox(height: 8),
                    Text(l10n.kotcNextAdminNote,
                        style: const TextStyle(fontSize: 12, color: Colors.black38)),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.goldCream,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
                      ),
                      child: Row(children: [
                        const Icon(Icons.emoji_events_rounded, size: 14, color: AppColors.goldDark),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(_nameFor(_nextAdminPlayerId!),
                              style: const TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.goldDark)),
                        ),
                      ]),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// The ranked results table (header row + one tappable row per team),
  /// shared by the `_showRanking` sheet and the completed-court body.
  /// [onEdited] fires after a row's edit dialog closes so the caller can
  /// refresh (the sheet needs an explicit nudge; the inline body rebuilds
  /// itself via `_updateTournament`).
  Widget _buildRankingTable(AppLocalizations l10n, {required VoidCallback onEdited}) {
    final result =
        ScrambleKingService.computeCourtRoundResult(_t, _round.id, widget.courtNumber);
    const headerStyle =
        TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.black45);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Row(children: [
            Expanded(child: Text(l10n.scrambleKingTeamsLabel, style: headerStyle)),
            SizedBox(
              width: 44,
              child: Text(l10n.kotcStatGames, textAlign: TextAlign.center, style: headerStyle),
            ),
            SizedBox(
              width: 52,
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.emoji_events_rounded, size: 11, color: Colors.black45),
                const SizedBox(width: 2),
                Text(l10n.kotcStatWins, style: headerStyle),
              ]),
            ),
            SizedBox(
              width: 44,
              child: Text(l10n.kotcStatPts, textAlign: TextAlign.right, style: headerStyle),
            ),
          ]),
        ),
        for (final team in result.teamResults)
          InkWell(
            onTap: () async {
              await _editTeamResult(team);
              onEdited();
            },
            borderRadius: BorderRadius.circular(10),
            child: Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: team.rank == 1 ? AppColors.goldCream : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: team.rank == 1
                        ? _kGold.withValues(alpha: 0.4)
                        : Colors.grey.shade200),
              ),
              child: Row(children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _teamNameForSlot(team.slotId) ??
                            team.playerIds.map(_nameFor).join(' & '),
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: team.rank == 1 ? _kGold : Colors.black87),
                      ),
                      Text(team.playerIds.map(_nameFor).join(' & '),
                          style: const TextStyle(fontSize: 11, color: Colors.black45)),
                    ],
                  ),
                ),
                SizedBox(
                  width: 44,
                  child: Text('${team.gamesPlayed}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w700, color: Colors.black54)),
                ),
                SizedBox(
                  width: 52,
                  child: Text('${team.gamesWon}',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: team.gamesWon > 0 ? _kGold : Colors.black38)),
                ),
                SizedBox(
                  width: 44,
                  child: Text('${team.points}',
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w700, color: Colors.black87)),
                ),
              ]),
            ),
          ),
      ],
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: TournaQAppBar(
        title: l10n.modeScrambleKingName,
        subtitle: l10n.scrambleKingCourtPageTitle(widget.courtNumber),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart_rounded, color: AppColors.goldLight),
            tooltip: l10n.scrambleKingScorecard,
            onPressed: _showRanking,
          ),
        ],
      ),
      body: SafeArea(
        child: _formation.isCompleted
            ? _buildResultsBody(l10n)
            : OrientationBuilder(
                builder: (context, orientation) => orientation == Orientation.landscape
                    ? _buildLandscapeBody(l10n)
                    : _buildPortraitBody(l10n),
              ),
      ),
    );
  }

  // ── Portrait / landscape bodies (ported from KOTC) ───────────────────────

  Widget _buildPortraitBody(AppLocalizations l10n) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _sectionHeader(l10n.doghouseGameplayControls, Icons.sports_volleyball_rounded),
          const SizedBox(height: 10),
          if (_t.paceAlertsEnabled) ...[
            _buildScheduleCard(l10n),
            const SizedBox(height: 10),
          ],
          _buildRoundTimerRow(l10n),
          const SizedBox(height: 10),
          if (_hasCourt && _isAutoMode) ...[
            _buildUpNextTile(l10n),
            const SizedBox(height: 8),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(flex: 4, child: _buildChallengersTile(l10n)),
                  const SizedBox(width: 8),
                  Expanded(flex: 1, child: _buildChallengerEjectColumn(l10n)),
                ],
              ),
            ),
            const SizedBox(height: 8),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(flex: 4, child: _buildActiveScoringTile(l10n)),
                  const SizedBox(width: 8),
                  Expanded(flex: 1, child: _buildCourtEjectColumn(l10n)),
                ],
              ),
            ),
            if (_adminPlayerId != null) ...[
              const SizedBox(height: 8),
              _buildAdminBanner(l10n),
            ],
          ] else if (_hasCourt)
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(flex: 4, child: _buildActiveScoringTile(l10n)),
                  const SizedBox(width: 8),
                  Expanded(flex: 1, child: _buildCourtEjectColumn(l10n)),
                ],
              ),
            )
          else ...[
            _buildPickOrWaitTile(l10n),
            const SizedBox(height: 10),
            _buildFullWidthCourtUndoButton(l10n),
          ],
          const SizedBox(height: 24),
          _sectionHeader(l10n.doghouseMatchControls, Icons.emoji_events_rounded),
          const SizedBox(height: 10),
          _buildMatchControls(l10n),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildLandscapeBody(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildRoundTimerRow(l10n, inline: true),
          const SizedBox(height: 6),
          Expanded(
            child: _hasCourt && _isAutoMode
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(child: _buildUpNextTile(l10n, compact: true)),
                            const SizedBox(height: 6),
                            Expanded(child: _buildChallengersTile(l10n, compact: true)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      SizedBox(width: 56, child: _buildChallengerEjectColumn(l10n)),
                      const SizedBox(width: 6),
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(child: _buildActiveScoringTile(l10n, compact: true)),
                            if (_adminPlayerId != null) ...[
                              const SizedBox(height: 6),
                              _buildAdminBanner(l10n),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      SizedBox(width: 64, child: _buildCourtEjectColumn(l10n)),
                    ],
                  )
                : _hasCourt
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(flex: 4, child: _buildActiveScoringTile(l10n, compact: true)),
                          const SizedBox(width: 8),
                          SizedBox(width: 64, child: _buildCourtEjectColumn(l10n)),
                        ],
                      )
                    : SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildPickOrWaitTile(l10n),
                            const SizedBox(height: 10),
                            _buildFullWidthCourtUndoButton(l10n),
                          ],
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  // ── Schedule card (pace alerts) ──────────────────────────────────────────

  Widget _buildScheduleCard(AppLocalizations l10n) {
    final now = DateTime.now();
    final start = _round.scheduledStartTime;
    final end = _round.scheduledMatchEndTime;

    final Color statusColor;
    final String statusText;
    if (now.isAfter(end)) {
      statusColor = Colors.red.shade600;
      statusText = l10n.statusOverdue;
    } else if (now.isAfter(start)) {
      statusColor = Colors.amber.shade700;
      statusText = l10n.statusDue;
    } else {
      statusColor = Colors.green.shade600;
      statusText = l10n.statusUpcoming;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _kOliveLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.schedule_rounded, size: 15, color: _kOlive),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${_fmtTime(start)} – ${_fmtTime(end)}',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _kOlive),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(statusText,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: statusColor)),
          ),
        ],
      ),
    );
  }

  // ── Round timer row (ported from KOTC session-timer row) ─────────────────

  Widget _buildRoundTimerRow(AppLocalizations l10n, {bool inline = false}) {
    final timer = ScrambleTimerWidget(
      key: _matchTimerKey,
      initial: _timerInitialRemaining ?? _round.matchDuration,
      mode: ScrambleTimerMode.countdown,
      autoStart: _timerRunning,
      compact: true,
      onTick: (_) => setState(() {}),
      onFinished: _onMatchTimerFinished,
    );

    final paused = _matchTimerKey.currentState?.timerState == ScrambleTimerState.paused;
    final controls = <Widget>[
      if (paused)
        _refBtn(Icons.play_arrow_rounded, l10n.btnResume, () {
          _matchTimerKey.currentState?.resume();
          setState(() => _timerRunning = true);
        }, primary: true),
      _refBtn(Icons.pause_rounded, l10n.btnStop, () {
        _matchTimerKey.currentState?.pause();
        setState(() => _timerRunning = false);
      }),
      _refBtn(Icons.replay_rounded, l10n.doghouseStartRestart, () {
        _matchTimerKey.currentState?.restart();
        _matchTimerKey.currentState?.start();
        setState(() => _timerRunning = true);
      }),
      _refTextBtn('+30s',
          () => _matchTimerKey.currentState?.addTime(const Duration(seconds: 30))),
      _refTextBtn('−30s',
          () => _matchTimerKey.currentState?.addTime(const Duration(seconds: -30))),
    ];

    if (inline) {
      return Row(children: [
        const Icon(Icons.timer_rounded, size: 13, color: _kOlive),
        const SizedBox(width: 4),
        timer,
        const SizedBox(width: 8),
        Expanded(
          child: Wrap(spacing: 6, runSpacing: 6, children: controls),
        ),
      ]);
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(children: [
            const Icon(Icons.timer_rounded, size: 14, color: _kOlive),
            const SizedBox(width: 6),
            Text(l10n.scrambleKingRoundTimer,
                style: const TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w700, color: _kOlive, letterSpacing: 0.6)),
            const Spacer(),
            timer,
          ]),
          const SizedBox(height: 10),
          Wrap(spacing: 6, runSpacing: 6, alignment: WrapAlignment.center, children: controls),
        ],
      ),
    );
  }

  // ── Admin banner (all-play) ──────────────────────────────────────────────

  Widget _buildAdminBanner(AppLocalizations l10n) => Material(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: _showAdminOverrideSheet,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Icon(Icons.gavel_rounded, size: 15, color: Colors.black45),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(l10n.scrambleKingRefereeBanner(_nameFor(_adminPlayerId!)),
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black54)),
                ),
              ]),
              if (_nextAdminPlayerId != null) ...[
                const SizedBox(height: 6),
                Row(children: [
                  const SizedBox(width: 23),
                  Text('→ ${l10n.kotcNextAdmin}: ${_nameFor(_nextAdminPlayerId!)}',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 11, fontWeight: FontWeight.w500, color: Colors.black38)),
                ]),
              ],
            ]),
          ),
        ),
      );

  // ── Up Next tile (grey) ──────────────────────────────────────────────────

  Widget _buildUpNextTile(AppLocalizations l10n, {bool compact = false}) {
    final slotId = _upNextSlotId;
    final teamName = slotId != null ? _teamNameForSlot(slotId) : null;
    return Card(
      margin: compact ? EdgeInsets.zero : null,
      color: Colors.grey.shade50,
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: EdgeInsets.all(compact ? 8 : 14),
        child: Column(
          mainAxisSize: compact ? MainAxisSize.max : MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(children: [
              Icon(Icons.schedule_rounded, size: 15, color: Colors.grey.shade500),
              const SizedBox(width: 6),
              Text(l10n.kotcUpNext,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey.shade500,
                      letterSpacing: 0.4)),
            ]),
            SizedBox(height: compact ? 4 : 8),
            if (slotId == null)
              Text(l10n.kotcWaitingForPlayers,
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 12))
            else ...[
              if (teamName != null) _teamCaption(teamName, Colors.grey.shade500),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: _slotChipNames(slotId)
                    .map((n) => _nameChip(n, Colors.grey.shade600,
                        bg: Colors.grey.shade200, border: null, compact: compact))
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── Challengers tile (olive) ─────────────────────────────────────────────

  Widget _buildChallengersTile(AppLocalizations l10n, {bool compact = false}) {
    final hasChallenger = _challengerSlotId != null;
    final teamName = hasChallenger ? _teamNameForSlot(_challengerSlotId!) : null;
    return Card(
      margin: compact ? EdgeInsets.zero : null,
      color: _kOliveLight,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: _kOlive.withValues(alpha: 0.35), width: 1.5),
      ),
      child: Padding(
        padding: EdgeInsets.all(compact ? 8 : 14),
        child: Column(
          mainAxisSize: compact ? MainAxisSize.max : MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(children: [
              const Icon(Icons.groups_rounded, size: 15, color: _kOlive),
              const SizedBox(width: 6),
              Text(l10n.kotcChallengers,
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w700, color: _kOlive, letterSpacing: 0.4)),
            ]),
            SizedBox(height: compact ? 4 : 8),
            if (!hasChallenger)
              Text(l10n.kotcWaitingForPlayers, style: const TextStyle(color: _kOlive, fontSize: 12))
            else ...[
              if (teamName != null) _teamCaption(teamName, _kOlive),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: _slotChipNames(_challengerSlotId!)
                    .map((n) => _nameChip(n, _kOlive,
                        bg: _kOlive.withValues(alpha: 0.15),
                        border: _kOlive.withValues(alpha: 0.4),
                        compact: compact))
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── Active scoring tile (gold) ───────────────────────────────────────────

  Widget _buildActiveScoringTile(AppLocalizations l10n, {bool compact = false}) {
    final nearStrike = _strikeEnabled &&
        _currentPoints >= (_t.strikePoints - 1).clamp(0, _t.strikePoints);
    final isFloaterTurn = _onCourtSlotId == _formation.floaterSlot?.slotId;
    final teamName = _onCourtSlotId != null ? _teamNameForSlot(_onCourtSlotId!) : null;
    final clock = _fmtClock(_stintWatch.elapsed);

    return Card(
      color: nearStrike ? _kGoldCardLeading : _kGoldCardBg,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: _kGold, width: 2),
      ),
      child: Padding(
        padding: compact
            ? const EdgeInsets.fromLTRB(12, 10, 12, 8)
            : const EdgeInsets.fromLTRB(16, 16, 16, 12),
        child: Column(
          mainAxisSize: compact ? MainAxisSize.max : MainAxisSize.min,
          children: [
            if (teamName != null)
              _teamCaption(teamName, _kGold)
            else if (isFloaterTurn)
              _teamCaption(l10n.scrambleKingFloaterTag, _kGold),
            // Player chips
            Wrap(
              spacing: 6,
              runSpacing: 4,
              alignment: WrapAlignment.center,
              children: _onCourtChipNames()
                  .map((n) => _nameChip(n, _kGold,
                      bg: _kGold.withValues(alpha: 0.15),
                      border: _kGold.withValues(alpha: 0.5),
                      compact: compact))
                  .toList(),
            ),
            const SizedBox(height: 8),
            // Game clock + strike badge
            Row(children: [
              Icon(Icons.timer_rounded, size: 12, color: _kGold.withValues(alpha: 0.7)),
              const SizedBox(width: 4),
              Text(clock,
                  style: TextStyle(
                    fontSize: 12,
                    color: _kGold.withValues(alpha: 0.8),
                    fontWeight: FontWeight.w600,
                  )),
              if (_strikeEnabled) ...[
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: nearStrike
                        ? _kGold.withValues(alpha: 0.2)
                        : Colors.black.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.bolt_rounded, size: 13, color: nearStrike ? _kGold : Colors.black45),
                      const SizedBox(width: 2),
                      Text('$_currentPoints / ${_t.strikePoints}',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: nearStrike ? _kGold : Colors.black54)),
                    ],
                  ),
                ),
              ],
            ]),
            // Big score
            if (compact)
              Expanded(
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.contain,
                    child: Text('$_currentPoints',
                        style: const TextStyle(
                            fontSize: 200, fontWeight: FontWeight.bold, height: 1, color: Colors.black87)),
                  ),
                ),
              )
            else
              Text('$_currentPoints',
                  style: const TextStyle(
                      fontSize: 96, fontWeight: FontWeight.bold, height: 1, color: Colors.black87)),
            // +/- buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton.filled(
                  icon: const Icon(Icons.remove),
                  tooltip: '−1',
                  onPressed: (_timerRunning && _currentPoints > 0) ? _removePoint : null,
                  style: IconButton.styleFrom(
                    backgroundColor: (_timerRunning && _currentPoints > 0) ? _kGold : Colors.grey.shade300,
                    foregroundColor: (_timerRunning && _currentPoints > 0) ? Colors.white : Colors.grey,
                    fixedSize: const Size(52, 52),
                  ),
                ),
                IconButton.filled(
                  icon: const Icon(Icons.add),
                  tooltip: '+1',
                  onPressed: _timerRunning ? _addPoint : null,
                  style: IconButton.styleFrom(
                    backgroundColor: _timerRunning ? _kGold : Colors.grey.shade300,
                    foregroundColor: _timerRunning ? Colors.white : Colors.grey,
                    fixedSize: const Size(64, 64),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Narrow eject button (ported from KOTC) ───────────────────────────────

  Widget _buildEjectButton(AppLocalizations l10n) {
    return ElevatedButton(
      onPressed: () => _ejectCourt(reason: ScrambleKingStintEndReason.manual),
      style: ElevatedButton.styleFrom(
        backgroundColor: _kGold,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.all(8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.logout_rounded, size: 22),
            const SizedBox(height: 6),
            Text(l10n.scrambleKingEjectCourt,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11)),
          ],
        ),
      ),
    );
  }

  /// Narrow column beside the Active Scoring tile: eject button, plus an
  /// undo button underneath once one becomes available (ported from KOTC's
  /// landscape "column 3" split).
  Widget _buildCourtEjectColumn(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(flex: 2, child: _buildEjectButton(l10n)),
        const SizedBox(height: 6),
        Expanded(flex: 1, child: _buildCourtUndoButton(l10n)),
      ],
    );
  }

  Widget _buildCourtUndoButton(AppLocalizations l10n) {
    return OutlinedButton(
      onPressed: _canUndoEjectCourt ? _undoEjectCourt : null,
      style: OutlinedButton.styleFrom(
        foregroundColor: _kGold,
        side: BorderSide(color: _kGold.withValues(alpha: 0.6)),
        padding: const EdgeInsets.all(8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.undo_rounded, size: 16),
            const SizedBox(height: 4),
            Text(l10n.kotcUndoEject,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 10)),
          ],
        ),
      ),
    );
  }

  /// Full-width variant for the one case with no adjacent card to hang a
  /// narrow column off: manual mode right after an ejection, before the
  /// coach has picked the next team.
  Widget _buildFullWidthCourtUndoButton(AppLocalizations l10n) {
    return OutlinedButton.icon(
      onPressed: _canUndoEjectCourt ? _undoEjectCourt : null,
      icon: const Icon(Icons.undo_rounded, size: 18),
      label: Text(l10n.kotcUndoLastEjection, style: const TextStyle(fontWeight: FontWeight.w600)),
      style: OutlinedButton.styleFrom(
        foregroundColor: _kGold,
        side: BorderSide(color: _kGold.withValues(alpha: 0.6)),
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // ── Narrow challenger eject button + column (mirrors the court eject) ────

  Widget _buildChallengerEjectColumn(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(flex: 2, child: _buildChallengerEjectButton(l10n)),
        const SizedBox(height: 6),
        Expanded(flex: 1, child: _buildChallengerUndoButton(l10n)),
      ],
    );
  }

  Widget _buildChallengerEjectButton(AppLocalizations l10n) {
    return ElevatedButton(
      onPressed: _canEjectChallenger ? _ejectChallenger : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: _kOlive,
        disabledBackgroundColor: Colors.grey.shade300,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.all(8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.logout_rounded, size: 22),
            const SizedBox(height: 6),
            Text(l10n.scrambleKingEjectChallenger,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Widget _buildChallengerUndoButton(AppLocalizations l10n) {
    return OutlinedButton(
      onPressed: _canUndoEjectChallenger ? _undoEjectChallenger : null,
      style: OutlinedButton.styleFrom(
        foregroundColor: _kOlive,
        side: BorderSide(color: _kOlive.withValues(alpha: 0.6)),
        padding: const EdgeInsets.all(8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.undo_rounded, size: 16),
            const SizedBox(height: 4),
            Text(l10n.kotcUndoEjectChallenger,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 10)),
          ],
        ),
      ),
    );
  }

  // ── Pick-a-team tile (manual) / waiting (automated) ──────────────────────

  Widget _buildPickOrWaitTile(AppLocalizations l10n) {
    if (_isAutoMode) {
      return Card(
        color: Colors.grey.shade50,
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.grey.shade300),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(l10n.kotcWaitingForPlayers,
              style: const TextStyle(color: Colors.black45, fontSize: 13)),
        ),
      );
    }
    return Card(
      color: _kGoldCardBg,
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: _kGold, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(children: [
              const Icon(Icons.groups_rounded, size: 16, color: _kGold),
              const SizedBox(width: 8),
              Text(l10n.scrambleKingPickStartingTeam,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: _kGold)),
            ]),
            const SizedBox(height: 12),
            for (final slotId in _pool)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  onTap: () => _pickManualStart(slotId),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _kGold.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (_teamNameForSlot(slotId) != null)
                                Text(_teamNameForSlot(slotId)!,
                                    style: const TextStyle(
                                        fontSize: 13, fontWeight: FontWeight.w700, color: _kGold)),
                              Text(_slotChipNames(slotId).join(' & '),
                                  style: const TextStyle(fontSize: 12, color: Colors.black54)),
                            ],
                          ),
                        ),
                        const Icon(Icons.play_arrow_rounded, color: _kGold),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── Match controls (ported from KOTC) ────────────────────────────────────

  Widget _buildMatchControls(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            _chip(Icons.emoji_events_rounded, _t.name, _kOliveLight, _kOlive),
            _chip(Icons.grid_view_rounded, '2v2', Colors.grey.shade100, Colors.black45),
            _chip(Icons.people_rounded, '${_formation.teamSlots.length} ${l10n.scrambleKingTeamsLabel.toLowerCase()}',
                Colors.grey.shade100, Colors.black45),
            if (_strikeEnabled)
              _chip(Icons.bolt_rounded, l10n.kotcStrikePoints(_t.strikePoints),
                  AppColors.goldCream, _kGold),
          ],
        ),
        const Divider(height: 20),
        ElevatedButton.icon(
          onPressed: _confirmFinishCourt,
          icon: const Icon(Icons.emoji_events_rounded, size: 18),
          label: Text(l10n.scrambleKingFinishCourt, style: const TextStyle(fontWeight: FontWeight.w700)),
          style: ElevatedButton.styleFrom(
            backgroundColor: _kOlive,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: _showRanking,
          icon: const Icon(Icons.edit_rounded, size: 18),
          label: Text(l10n.scrambleKingEditScore),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.black54,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () => Navigator.of(context).pop(_t),
          icon: const Icon(Icons.arrow_back_rounded, size: 18),
          label: Text(l10n.scrambleKingBackToSchedule, style: const TextStyle(fontWeight: FontWeight.w600)),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.black54,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }

  // ── Results view (round complete) ────────────────────────────────────────

  Widget _buildResultsBody(AppLocalizations l10n) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _sectionHeader(l10n.scrambleKingScorecard, Icons.emoji_events_rounded),
        const SizedBox(height: 12),
        _buildRankingTable(l10n, onEdited: () {}),
        const Divider(height: 24),
        OutlinedButton.icon(
          onPressed: _undoFinishCourt,
          icon: const Icon(Icons.undo_rounded, size: 18),
          label: Text(l10n.scrambleKingUndoFinishCourt, style: const TextStyle(fontWeight: FontWeight.w600)),
          style: OutlinedButton.styleFrom(
            foregroundColor: _kGold,
            side: BorderSide(color: _kGold.withValues(alpha: 0.6)),
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: _showRanking,
          icon: const Icon(Icons.edit_rounded, size: 18),
          label: Text(l10n.scrambleKingEditScore),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.black54,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () => Navigator.of(context).pop(_t),
          icon: const Icon(Icons.arrow_back_rounded, size: 18),
          label: Text(l10n.scrambleKingBackToSchedule, style: const TextStyle(fontWeight: FontWeight.w600)),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.black54,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }

  // ── Shared small helpers (ported from KOTC) ──────────────────────────────

  Widget _teamCaption(String text, Color color) => Padding(
        padding: const EdgeInsets.only(bottom: 3),
        child: Text(text.toUpperCase(),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                fontSize: 10, fontWeight: FontWeight.w700, color: color, letterSpacing: 0.5)),
      );

  Widget _nameChip(String name, Color fg, {required Color bg, Color? border, bool compact = false}) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
          border: border != null ? Border.all(color: border) : null,
        ),
        child: Text(name,
            style: TextStyle(fontSize: compact ? 11 : 13, fontWeight: FontWeight.w700, color: fg)),
      );

  Widget _sectionHeader(String title, IconData icon) => Row(children: [
        Icon(icon, size: 15, color: _kOlive),
        const SizedBox(width: 6),
        Text(title.toUpperCase(),
            style: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.w700, color: _kOlive, letterSpacing: 0.4)),
      ]);

  Widget _chip(IconData icon, String label, Color bg, Color fg) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 11, color: fg),
          const SizedBox(width: 3),
          Text(label, style: TextStyle(fontSize: 11, color: fg, fontWeight: FontWeight.w600)),
        ]),
      );

  Widget _refBtn(IconData icon, String label, VoidCallback onTap, {bool primary = false}) =>
      OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 14),
        label: Text(label, style: const TextStyle(fontSize: 12)),
        style: OutlinedButton.styleFrom(
          foregroundColor: primary ? Colors.white : _kOlive,
          backgroundColor: primary ? _kOlive : null,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          side: BorderSide(color: primary ? _kOlive : Colors.grey.shade300),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      );

  Widget _refTextBtn(String label, VoidCallback onTap) => OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: _kOlive,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          side: BorderSide(color: Colors.grey.shade300),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: Text(label, style: const TextStyle(fontSize: 12)),
      );

  String _fmtClock(Duration d) =>
      '${d.inMinutes.toString().padLeft(2, '0')}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';

  String _fmtTime(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}
