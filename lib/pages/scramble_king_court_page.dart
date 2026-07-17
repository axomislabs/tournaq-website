import 'package:flutter/material.dart';
import '../app/app_colors.dart';
import '../l10n/app_localizations.dart';
import '../models/scramble_king_tournament.dart';
import '../services/scramble_king_service.dart';
import '../services/scramble_king_storage_service.dart';
import '../services/scramble_king_transfer_service.dart';
import '../widgets/editable_info_chip.dart';
import '../widgets/qr_export_sheet.dart';
import '../widgets/scramble_king_court_result_tile.dart';
import '../widgets/scramble_timer_widget.dart';
import '../widgets/sheet_helpers.dart';
import '../widgets/tournaq_app_bar.dart';

const _kGold = AppColors.goldDark;
const _kGoldCardBg = AppColors.goldCardBg;
const _kGoldCardLeading = AppColors.goldCardLeading;
const _kOlive = AppColors.olive;
const _kOliveLight = AppColors.oliveLight;

/// Full snapshot of the live "waiting chain" state — everything an eject
/// mutates besides the on-court slot itself (which is separately restored
/// from the persisted stint record). Captured before each eject and
/// restored verbatim on undo, so undo is exact rather than a fairness
/// re-derivation that can land somewhere slightly different.
typedef _ChainSnapshot = ({
  List<String> pool,
  String? challengerSlotId,
  String? upNextSlotId,
  String? floaterJumperPartnerId,
  String? adminPlayerId,
  String? nextAdminPlayerId,
  Map<String, int> scorekeepCounts,
});

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

  /// True when this court was received from another device via QR and is being
  /// played by a referee. Changes the subtitle, back target, and the app-bar
  /// action (result QR once completed), and hides the upcoming list.
  final bool isImported;

  /// Host tournament id an imported court's result must be returned to.
  final String? parentTournamentId;

  /// Whether local changes persist to this device's main Scramble King store.
  /// False for imported courts — the hub persists them to the imported store
  /// via [onChanged] instead, so a borrowed court never joins the local list.
  final bool saveToStore;

  const ScrambleKingCourtPage({
    super.key,
    required this.tournament,
    required this.roundId,
    required this.courtNumber,
    required this.onChanged,
    this.isImported = false,
    this.parentTournamentId,
    this.saveToStore = true,
  });

  @override
  State<ScrambleKingCourtPage> createState() => _ScrambleKingCourtPageState();
}

class _ScrambleKingCourtPageState extends State<ScrambleKingCourtPage> {
  late ScrambleKingTournament _t;

  String? _onCourtSlotId;
  String? _onCourtTempPartnerId;

  /// Set alongside [_onCourtTempPartnerId] when the on-court slot is a
  /// regular team (not the floater) short one member because that member is
  /// currently the Auto-Allplay scorekeeper — the other named player is
  /// actually on court, paired with [_onCourtTempPartnerId] as a substitute.
  String? _onCourtBenchedPlayerId;
  int _currentPoints = 0;
  String? _challengerSlotId;

  /// The slot displayed as "Up Next" — real stored state (not re-derived on
  /// every read). The visible chain Up Next → Challengers → Court is only
  /// ever shifted by exactly one step at a time; fairness ranking is only
  /// ever consulted to fill the ONE newly-opened gap at the far end. See
  /// `_topUpQueue`.
  String? _upNextSlotId;
  String? _lastEjectedChallengerSlotId;
  List<String> _pool = [];
  String?
  _floaterJumperPartnerId; // jumper mode: locked partner while the floater waits (null ⇒ awaiting ejection)

  /// Auto-Allplay only: the single player currently keeping score instead of
  /// playing. Their team stays a completely normal queue member — see
  /// `_refreshScorekeeper` and the substitution branch in `_startSlot`.
  String? _adminPlayerId;

  /// Auto-Allplay only: the previewed successor once the current admin's
  /// slot reaches Up Next — shown in the banner ahead of the handoff so the
  /// coach can prepare it, committed once the admin's slot reaches
  /// Challengers. Mirrors King of the Court's admin-handoff preview.
  String? _nextAdminPlayerId;

  /// Ephemeral per-court fairness counter (how many times each player has
  /// been asked to keep score this round), used to balance the rotation.
  final Map<String, int> _scorekeepCounts = {};

  /// Full snapshot of the waiting chain, taken right before the most recent
  /// court/challenger ejection and restored verbatim on undo — so "undo,
  /// then redo the same action" reproduces the exact same outcome, the same
  /// way undoing a real-life call would. Re-deriving the chain via fairness
  /// ranking instead (the old "soft undo" approach) can land on a different
  /// queue order or referee handoff than before, which reads as the app
  /// arbitrarily changing its mind to anyone watching the court.
  _ChainSnapshot? _chainBeforeCourtEject;
  _ChainSnapshot? _chainBeforeChallengerEject;

  _ChainSnapshot get _currentChainSnapshot => (
    pool: List.of(_pool),
    challengerSlotId: _challengerSlotId,
    upNextSlotId: _upNextSlotId,
    floaterJumperPartnerId: _floaterJumperPartnerId,
    adminPlayerId: _adminPlayerId,
    nextAdminPlayerId: _nextAdminPlayerId,
    scorekeepCounts: Map.of(_scorekeepCounts),
  );

  void _restoreChainSnapshot(_ChainSnapshot snapshot) {
    _pool = List.of(snapshot.pool);
    _challengerSlotId = snapshot.challengerSlotId;
    _upNextSlotId = snapshot.upNextSlotId;
    _floaterJumperPartnerId = snapshot.floaterJumperPartnerId;
    _adminPlayerId = snapshot.adminPlayerId;
    _nextAdminPlayerId = snapshot.nextAdminPlayerId;
    _scorekeepCounts
      ..clear()
      ..addAll(snapshot.scorekeepCounts);
  }

  final _matchTimerKey = GlobalKey<ScrambleTimerWidgetState>();
  final _stintWatch = Stopwatch();
  Duration? _timerInitialRemaining;
  bool _timerRunning = false;
  bool _scheduleExpanded = false;

  ScrambleKingRound get _round => _t.getRound(widget.roundId)!;
  ScrambleKingCourtFormation get _formation =>
      _round.getCourt(widget.courtNumber)!;
  bool get _hasStarted => _formation.actualStartTime != null;
  bool get _isAutoMode =>
      _t.assignmentMode != ScrambleKingAssignmentMode.manual;
  bool get _isAllPlay =>
      _t.assignmentMode == ScrambleKingAssignmentMode.automatedAllPlay;

  String _assignmentModeLabel(
    AppLocalizations l10n,
  ) => switch (_t.assignmentMode) {
    ScrambleKingAssignmentMode.manual => l10n.doghouseAssignmentManual,
    ScrambleKingAssignmentMode.automated => l10n.doghouseAssignmentAutomated,
    ScrambleKingAssignmentMode.automatedAllPlay => l10n.setupFormatAutoAllplay,
  };

  String _oddPlayerModeLabel(AppLocalizations l10n) =>
      _t.oddPlayerMode == ScrambleKingOddPlayerMode.jumper
      ? l10n.scrambleKingOddPlayerJumperLabel
      : l10n.scrambleKingOddPlayerPlaceholderLabel;

  /// The slot (team or floater) containing the current admin player.
  String? get _adminSlotId {
    if (_adminPlayerId == null) return null;
    if (_formation.floaterSlot?.playerId == _adminPlayerId) {
      return _formation.floaterSlot!.slotId;
    }
    try {
      final teamSlot = _formation.teamSlots.firstWhere(
        (s) => s.playerIds.contains(_adminPlayerId),
      );
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
  bool get _canUndoEjectCourt =>
      _courtStints.isNotEmpty && (!_hasCourt || _isAutoMode);

  @override
  void initState() {
    super.initState();
    _t = widget.tournament;
    // Opening a court no longer auto-starts play — mirrors
    // ScrambleScorecardPage: the court sits in a "ready" state (idle timer,
    // no team on court) until the coach starts it manually via
    // `_startCourt()`, either the dedicated button or the timer row's own
    // Start control. If the court was already started in an earlier
    // session, resume it (or finish it immediately if time already ran out
    // while the app was closed).
    if (_hasStarted && !_formation.isCompleted) {
      final elapsed = DateTime.now().difference(_formation.actualStartTime!);
      final remaining = _round.matchDuration - elapsed;
      if (remaining > Duration.zero) {
        _resumeLiveState();
      } else {
        _timerInitialRemaining = Duration.zero;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _onMatchTimerFinished();
        });
      }
    }
  }

  /// Stamps the court's start time and drops it into live play — the "Start
  /// Court" button and the timer row's Start/Restart control both funnel
  /// here for a not-yet-started court, mirroring
  /// `ScrambleScorecardPage._startMatch`.
  void _startCourt() {
    final updatedFormation = _formation.copyWith(
      actualStartTime: DateTime.now(),
    );
    _t = _t.updateRound(_round.updateCourt(updatedFormation));
    setState(() => _resumeLiveState());
    _persist();
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
    _timerInitialRemaining = remaining <= Duration.zero
        ? Duration.zero
        : remaining;
    final timerHasTimeLeft = _timerInitialRemaining! > Duration.zero;

    _pool = List.from(ScrambleKingService.initialQueueOrder(_formation));
    _floaterJumperPartnerId = null;
    // Reset the chain explicitly — the pool was just rebuilt from scratch,
    // so any slot these were still pointing at (stale, from before a
    // Finish/Undo Finish round-trip) may no longer be a valid member of it.
    _challengerSlotId = null;
    _upNextSlotId = null;
    // Any pending eject snapshot belongs to a chain state that no longer
    // exists post-resume — undo, if still offered, should fall back to
    // fairness re-derivation rather than restoring a stale snapshot.
    _chainBeforeCourtEject = null;
    _chainBeforeChallengerEject = null;

    if (restoredStint != null) {
      _onCourtSlotId = restoredStint.turnSlotId;
      final (tempPartner, benched) = _resolveStintSubstitution(restoredStint);
      _onCourtTempPartnerId = tempPartner;
      _onCourtBenchedPlayerId = benched;
      _currentPoints = restoredStint.points;
      _timerRunning = timerHasTimeLeft;
      _pool.remove(restoredStint.turnSlotId);
      _topUpQueue();
      _lastEjectedChallengerSlotId = null;
      _updateFloaterJumperAssignment();
      _refreshScorekeeper();
    } else {
      _initStart();
    }
  }

  /// Recovers `(tempPartner, benchedPlayer)` for a stored stint — needed to
  /// restore `_onCourtTempPartnerId`/`_onCourtBenchedPlayerId` on resume/undo,
  /// since a stint's `playerIds` may differ from its slot's fixed roster (a
  /// jumper-mode floater turn, or an Auto-Allplay scorekeeper's team playing
  /// short). A placeholder-mode floater turn has no recorded partner at all
  /// (`playerIds.length == 1`) — nothing to restore.
  (String?, String?) _resolveStintSubstitution(ScrambleKingStint stint) {
    if (stint.isFloaterStint) {
      return (stint.playerIds.length > 1 ? stint.playerIds[1] : null, null);
    }
    final team = _formation.teamSlots
        .where((s) => s.slotId == stint.turnSlotId)
        .firstOrNull;
    if (team == null) return (null, null);
    final extra = stint.playerIds
        .where((p) => !team.playerIds.contains(p))
        .toList();
    final missing = team.playerIds
        .where((p) => !stint.playerIds.contains(p))
        .toList();
    if (extra.isEmpty || missing.isEmpty) return (null, null);
    return (extra.first, missing.first);
  }

  @override
  void dispose() {
    _stintWatch.stop();
    super.dispose();
  }

  void _updateTournament(ScrambleKingTournament updated) {
    setState(() => _t = updated);
    _persist();
  }

  /// Persists the current [_t]: to this device's Scramble King store (unless
  /// this is an imported court — [saveToStore] false), then always notifies
  /// the owner via [onChanged] so an imported court lands in the imported
  /// store instead. Mirrors ScrambleScorecardPage._persist.
  void _persist() {
    if (widget.saveToStore) ScrambleKingStorageService.save(_t);
    widget.onChanged(_t);
  }

  // ── QR export ──────────────────────────────────────────────────────────────

  /// App-bar action: while the court is live, the ranking view; otherwise a QR
  /// action. Imported courts show the result QR once completed (else export
  /// the court). A host's completed court gets a small menu — export the court,
  /// or view / edit the results — so scoring stays editable now that the
  /// ranking icon is no longer shown at this stage.
  Widget _buildAppBarAction(AppLocalizations l10n) {
    final live = _hasStarted && !_formation.isCompleted;
    if (live) {
      return IconButton(
        icon: const Icon(Icons.bar_chart_rounded, color: AppColors.goldLight),
        tooltip: l10n.scrambleKingScorecard,
        onPressed: _showRanking,
      );
    }
    if (widget.isImported) {
      final result = _formation.isCompleted;
      return PopupMenuButton<String>(
        icon: const Icon(Icons.qr_code_rounded, color: AppColors.goldLight),
        onSelected: (v) {
          if (v == 'export') result ? _exportResult() : _exportCourt();
          if (v == 'edit') _showRanking();
        },
        itemBuilder: (ctx) => [
          PopupMenuItem(
            value: 'export',
            child: Row(
              children: [
                const Icon(Icons.qr_code_rounded, size: 18, color: _kOlive),
                const SizedBox(width: 8),
                Text(
                  result
                      ? l10n.scrambleExportResult
                      : l10n.scrambleKingExportCourt,
                ),
              ],
            ),
          ),
          PopupMenuItem(
            value: 'edit',
            child: Row(
              children: [
                const Icon(Icons.edit_rounded, size: 18, color: _kOlive),
                const SizedBox(width: 8),
                Text(l10n.scrambleKingEditResults),
              ],
            ),
          ),
        ],
      );
    }
    if (_formation.isCompleted) {
      return PopupMenuButton<String>(
        icon: const Icon(Icons.qr_code_rounded, color: AppColors.goldLight),
        onSelected: (v) {
          if (v == 'export') _exportCourt();
          if (v == 'edit') _showRanking();
        },
        itemBuilder: (ctx) => [
          PopupMenuItem(
            value: 'export',
            child: Row(
              children: [
                const Icon(Icons.qr_code_rounded, size: 18, color: _kOlive),
                const SizedBox(width: 8),
                Text(l10n.scrambleKingExportCourt),
              ],
            ),
          ),
          PopupMenuItem(
            value: 'edit',
            child: Row(
              children: [
                const Icon(Icons.edit_rounded, size: 18, color: _kOlive),
                const SizedBox(width: 8),
                Text(l10n.scrambleKingEditResults),
              ],
            ),
          ),
        ],
      );
    }
    return IconButton(
      icon: const Icon(Icons.qr_code_rounded, color: AppColors.goldLight),
      tooltip: l10n.scrambleKingExportCourt,
      onPressed: _exportCourt,
    );
  }

  void _exportCourt() {
    final l10n = AppLocalizations.of(context)!;
    final data = ScrambleKingTransferService.encodeCourtExport(
      _t,
      _round,
      _formation,
    );
    showQrExportSheet(
      context,
      title: l10n.scrambleKingExportCourt,
      subtitle: _courtContext(l10n),
      data: data,
    );
  }

  void _exportResult() {
    final l10n = AppLocalizations.of(context)!;
    final parentId = widget.parentTournamentId ?? _t.id;
    final data = ScrambleKingTransferService.encodeResult(
      parentId,
      _t,
      _round,
      _formation,
    );
    showQrExportSheet(
      context,
      title: l10n.scrambleExportResult,
      subtitle: _courtContext(l10n),
      data: data,
    );
  }

  String _courtContext(AppLocalizations l10n) {
    final teams = <String>[
      for (final s in _formation.teamSlots)
        s.teamName ?? s.playerIds.map(_nameFor).join(' & '),
      if (_formation.floaterSlot != null)
        _formation.floaterSlot!.teamName ??
            _nameFor(_formation.floaterSlot!.playerId),
    ];
    return '${l10n.scrambleKingRoundLabel(_round.roundNumber)} · '
        '${l10n.scrambleKingCourtPageTitle(widget.courtNumber)} · ${teams.join(' · ')}';
  }

  String _nameFor(String playerId) => _t.getPlayer(playerId)?.name ?? '?';

  // Read-only view of every team on this court (team name + player names),
  // opened from the "Teams" pill in Match Controls (live + imported court).
  void _showTeamsSheet(AppLocalizations l10n) {
    Widget teamRow(String? teamName, String players) => Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _kOliveLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (teamName != null) ...[
            Text(
              teamName,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: _kOlive,
              ),
            ),
            const SizedBox(height: 2),
          ],
          Text(
            players,
            style: const TextStyle(fontSize: 13, color: Colors.black87),
          ),
        ],
      ),
    );

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => TournaQSheet(
        body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Icon(Icons.groups_rounded, size: 20, color: _kOlive),
                  const SizedBox(width: 8),
                  Text(
                    l10n.pageTeams,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              for (final s in _formation.teamSlots)
                teamRow(s.teamName, s.playerIds.map(_nameFor).join(' & ')),
              if (_formation.floaterSlot != null)
                teamRow(
                  _formation.floaterSlot!.teamName,
                  _nameFor(_formation.floaterSlot!.playerId),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String? _teamNameForSlot(String slotId) {
    if (slotId == _formation.floaterSlot?.slotId) {
      return _formation.floaterSlot!.teamName;
    }
    for (final s in _formation.teamSlots) {
      if (s.slotId == slotId) return s.teamName;
    }
    return null;
  }

  /// The per-player names shown as chips for a queued slot (2 for a team,
  /// just the floater's own name for the floater slot — its rotating partner
  /// is rendered separately as a token chip, see `_floaterPartnerChip`).
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
      // Just the floater's own name, exactly like the waiting tiles — the
      // partner (if any) is always shown via the `_floaterPartnerChip` role
      // badge instead, never as a second plain name chip.
      return [_nameFor(_formation.floaterSlot!.playerId)];
    }
    if (_onCourtBenchedPlayerId != null && _onCourtTempPartnerId != null) {
      final team = _formation.teamSlots.firstWhere(
        (s) => s.slotId == _onCourtSlotId,
      );
      final activeMember = team.playerIds.firstWhere(
        (p) => p != _onCourtBenchedPlayerId,
      );
      return [_nameFor(activeMember), _nameFor(_onCourtTempPartnerId!)];
    }
    return _slotChipNames(_onCourtSlotId!);
  }

  // ── Starting a slot on court ────────────────────────────────────────────

  void _startSlot(String slotId, {String? explicitTempPartnerId}) {
    String? tempPartner;
    String? benchedPlayerId;
    if (slotId == _formation.floaterSlot?.slotId) {
      if (explicitTempPartnerId != null) {
        tempPartner = explicitTempPartnerId;
      } else if (_t.oddPlayerMode == ScrambleKingOddPlayerMode.jumper) {
        // Use the lock verbatim — it was fixed the moment this team entered
        // Up Next (see `_updateFloaterJumperAssignment`) and is never
        // re-picked or re-validated here, however long ago that was. The
        // fallback pick only covers a genuine bootstrap gap (this team
        // became the very first one on court, with no prior waiting phase
        // to lock a partner in) — see `_initStart`.
        tempPartner = _floaterJumperPartnerId;
      }
      // Placeholder mode: tempPartner stays null, always — the app never
      // assigns or displays a specific partner for that slot; see
      // `_buildStint`/`_onCourtChipNames` for how a null partner is handled.
    } else if (_isAllPlay && _adminPlayerId != null) {
      // Auto-Allplay: if one of this team's two named players is currently
      // the scorekeeper, the other plays with a borrowed stand-in instead —
      // the same placeholder/jumper mechanism the floater uses. This is a
      // fallback for the rare "tight court" case; `_refreshScorekeeper`
      // normally hands scorekeeping off before a team is put on court.
      final team = _formation.teamSlots.firstWhere((s) => s.slotId == slotId);
      if (team.playerIds.contains(_adminPlayerId)) {
        benchedPlayerId = _adminPlayerId;
        if (explicitTempPartnerId != null) {
          tempPartner = explicitTempPartnerId;
        } else {
          // This is a distinct mechanic from the odd-player floater — a real
          // stand-in is unconditionally required here (the benched player's
          // teammate needs someone to actually play with), independent of
          // `oddPlayerMode`, so always use the fairness-based pick.
          final otherTeams = _formation.teamSlots
              .where((s) => _pool.contains(s.slotId))
              .toList();
          final pick = ScrambleKingService.pickJumperPartner(
            otherQueuedTeams: otherTeams,
            courtStints: _courtStints,
          );
          tempPartner = pick?.playerId;
        }
      }
    }
    setState(() {
      _onCourtSlotId = slotId;
      _onCourtTempPartnerId = tempPartner;
      _onCourtBenchedPlayerId = benchedPlayerId;
      _currentPoints = 0;
      _timerRunning = true;
      // The floater (if it was the one started) is now on court, not waiting.
      if (slotId == _formation.floaterSlot?.slotId) {
        _floaterJumperPartnerId = null;
      }
    });
    _matchTimerKey.currentState?.start();
    _stintWatch
      ..reset()
      ..start();
  }

  void _initStart() {
    if (_pool.isEmpty || !_isAutoMode) return;
    final ranked = ScrambleKingService.rankQueue(
      queueSlotIds: _pool,
      onCourtSlotId: null,
      courtStints: _courtStints,
    );
    if (ranked.isEmpty) return;
    final first = ranked.first;
    _pool.remove(first);
    if (first == _formation.floaterSlot?.slotId &&
        _t.oddPlayerMode == ScrambleKingOddPlayerMode.jumper) {
      // The floater is about to become the very first team on court, with
      // no prior Up Next/Challenger phase to lock a partner in — lock one
      // now, using the exact same rule, so `_startSlot` never has to pick.
      _lockFloaterJumperPartnerIfNeeded();
    }
    _startSlot(first);
    setState(() {
      _topUpQueue();
      _lastEjectedChallengerSlotId = null;
      _updateFloaterJumperAssignment();
    });
    _refreshScorekeeper();
  }

  void _pickManualStart(String slotId) {
    if (slotId == _formation.floaterSlot?.slotId &&
        _t.oddPlayerMode == ScrambleKingOddPlayerMode.jumper) {
      // Placeholder mode has no partner to pick — the coach just sends the
      // floater to court directly, same as any other slot below.
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
    final otherTeams = _formation.teamSlots
        .where((s) => _pool.contains(s.slotId))
        .toList();
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.scrambleKingPickFloaterPartner,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
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

  // ── Deterministic queue chain ─────────────────────────────────────────────
  //
  // The visible chain is Court → Challengers → Up Next → (pool). It is only
  // ever advanced by exactly one step at a time (see `_ejectCourt`,
  // `_ejectChallenger`): whatever is already shown as Challengers/Up Next is
  // promoted verbatim, never re-ranked or displaced. `_topUpQueue` is the
  // single place fairness ranking is consulted, and only to fill whichever
  // one or two chain slots are currently empty (a fresh pick per empty
  // slot). This replaces the previous re-rank-from-scratch-on-every-eject
  // approach, which could silently promote a different team than the one
  // the coach saw displayed as "Up Next".

  /// Fills any gap in the Challenger → Up Next chain from the pool, ranking
  /// fresh for whichever position is empty. Never touches a slot that's
  /// already filled. Used both for the initial fill (both positions empty)
  /// and to top up after a vacancy shifts one slot out of the chain.
  void _topUpQueue() {
    if (!_isAutoMode) return;
    if (_challengerSlotId == null) {
      final ranked = ScrambleKingService.rankQueue(
        queueSlotIds: _pool,
        onCourtSlotId: _onCourtSlotId,
        courtStints: _courtStints,
      );
      _challengerSlotId = ranked.isNotEmpty ? ranked.first : null;
      if (_challengerSlotId != null) _pool.remove(_challengerSlotId);
    }
    if (_upNextSlotId == null) {
      final busyTeam = _busyJumperPartnerTeamSlotId;
      final ranked = ScrambleKingService.rankQueue(
        queueSlotIds: busyTeam == null
            ? _pool
            : _pool.where((id) => id != busyTeam).toList(),
        onCourtSlotId: _onCourtSlotId,
        courtStints: _courtStints,
      );
      _upNextSlotId = ranked.isNotEmpty ? ranked.first : null;
      if (_upNextSlotId != null) _pool.remove(_upNextSlotId);
    }
  }

  /// Manual override for the auto-picked Up Next: cycles to the next-ranked
  /// queued team (the same fairness order used to fill the slot), swapping the
  /// current pick back into the pool. Mirrors the "Re-roll" affordance on
  /// Doghouse / King of the Court, adapted to Scramble King's single-slot
  /// queue.
  void _rerollUpNext() {
    final current = _upNextSlotId;
    if (current == null || _pool.isEmpty) return;
    final busyTeam = _busyJumperPartnerTeamSlotId;
    final eligiblePool = busyTeam == null
        ? _pool
        : _pool.where((id) => id != busyTeam).toList();
    final candidates = ScrambleKingService.rankQueue(
      queueSlotIds: [...eligiblePool, current],
      onCourtSlotId: _onCourtSlotId,
      courtStints: _courtStints,
    );
    if (candidates.length <= 1) return;
    final idx = candidates.indexOf(current);
    final next = candidates[(idx + 1) % candidates.length];
    if (next == current) return;
    setState(() {
      _pool = [..._pool, current]..remove(next);
      _upNextSlotId = next;
      // Up Next feeds the jumper-mode borrowed-partner choice — refresh it so
      // the displayed pairing matches the newly-picked team.
      _updateFloaterJumperAssignment();
    });
  }

  /// Jumper mode only: the moment the floater's slot enters the chain as
  /// Challenger or Up Next, lock in a specific borrowed partner — chosen
  /// fairly (least-played), preferring someone who isn't themselves about
  /// to be pulled onto court as Up Next. Once locked, it is NEVER swapped or
  /// re-validated (see `_startSlot`) — only cleared once the floater's own
  /// stint ends, so the next trip locks in fresh. Leaves
  /// `_floaterJumperPartnerId` null while no pool candidate exists yet (⇒
  /// "awaiting ejection" in the UI); re-attempts on every subsequent chain
  /// advance until one does.
  void _updateFloaterJumperAssignment() {
    final floaterSlot = _formation.floaterSlot?.slotId;
    if (floaterSlot == null ||
        !_isAutoMode ||
        _t.oddPlayerMode != ScrambleKingOddPlayerMode.jumper) {
      _floaterJumperPartnerId = null;
      return;
    }
    final waiting =
        _challengerSlotId == floaterSlot || _upNextSlotId == floaterSlot;
    if (!waiting) {
      _floaterJumperPartnerId = null;
      return;
    }
    _lockFloaterJumperPartnerIfNeeded();
  }

  /// Locks `_floaterJumperPartnerId` if not already locked. Extracted so
  /// `_initStart` can lock it before the floater's very first stint (when
  /// there's no prior Up Next/Challenger phase to have triggered
  /// `_updateFloaterJumperAssignment` already).
  void _lockFloaterJumperPartnerIfNeeded() {
    if (_floaterJumperPartnerId != null) return;
    final allOtherTeams = _formation.teamSlots
        .where((s) => _pool.contains(s.slotId))
        .toList();
    // Prefer a partner from a team that isn't about to be pulled onto court
    // itself (i.e. not the current Up Next) — falls back to including it
    // if nothing else is available.
    final preferredTeams = allOtherTeams
        .where((s) => s.slotId != _upNextSlotId)
        .toList();
    final pick = ScrambleKingService.pickJumperPartner(
      otherQueuedTeams: preferredTeams.isNotEmpty
          ? preferredTeams
          : allOtherTeams,
      courtStints: _courtStints,
      // The current Auto-Allplay scorekeeper must never end up double-booked
      // as a borrowed jumper partner — but their teammate, if any, is still
      // free to play, so only the one player is excluded, not the whole team.
      excludePlayerIds: {?_adminPlayerId},
    );
    _floaterJumperPartnerId = pick?.playerId; // null ⇒ awaiting ejection
  }

  /// Jumper mode only: whoever is currently the floater's live borrowed
  /// partner, for as long as that partner is actually engaged alongside the
  /// floater as Challenger or Court — i.e. actually playing right now, not
  /// just queued. Returns null once the floater's own engagement ends (the
  /// partner reverts to unassigned, same as `_floaterJumperPartnerId`).
  String? get _busyJumperPartnerId {
    final floaterSlot = _formation.floaterSlot?.slotId;
    if (floaterSlot == null ||
        _t.oddPlayerMode != ScrambleKingOddPlayerMode.jumper) {
      return null;
    }
    if (_onCourtSlotId == floaterSlot) return _onCourtTempPartnerId;
    if (_challengerSlotId == floaterSlot) return _floaterJumperPartnerId;
    return null;
  }

  /// The team slot currently supplying [_busyJumperPartnerId]. Court/
  /// Challenger is a live "win-stays" pairing (see `_ejectCourt`/
  /// `_ejectChallenger`) — if the floater's side wins and stays engaged,
  /// whoever is Up Next gets promoted to face them next. That team slot must
  /// therefore never be Up Next while this holds, or the borrowed player
  /// could end up rostered against their own team.
  String? get _busyJumperPartnerTeamSlotId {
    final partnerId = _busyJumperPartnerId;
    if (partnerId == null) return null;
    return _formation.teamSlots
        .where((s) => s.playerIds.contains(partnerId))
        .firstOrNull
        ?.slotId;
  }

  /// The slot (team or floater) a given player currently belongs to.
  String? _slotIdForPlayer(String playerId) {
    if (_formation.floaterSlot?.playerId == playerId) {
      return _formation.floaterSlot!.slotId;
    }
    return _formation.teamSlots
        .where((s) => s.playerIds.contains(playerId))
        .firstOrNull
        ?.slotId;
  }

  /// Picks the least-scorekept-so-far candidate from [candidates], tie-break
  /// by player id — deterministic (not shuffled) so that re-deriving from
  /// the same candidate set and counts, e.g. right after an undo, always
  /// reaches the same pick instead of re-rolling it.
  String? _pickFairestScorekeeper(Iterable<String> candidates) {
    if (candidates.isEmpty) return null;
    final sorted = candidates.toList()
      ..sort((a, b) {
        final byCount = (_scorekeepCounts[a] ?? 0).compareTo(
          _scorekeepCounts[b] ?? 0,
        );
        return byCount != 0 ? byCount : a.compareTo(b);
      });
    return sorted.first;
  }

  /// Auto-Allplay only: keeps the rotating single-player scorekeeper
  /// assignment fair and current, with a two-phase handoff mirroring King
  /// of the Court: as soon as the scorekeeper's own slot reaches Up Next, a
  /// successor is previewed (`_nextAdminPlayerId`) so the coach can prepare
  /// the handover; the swap only actually commits once that slot reaches
  /// Challengers. Called after every chain advance.
  ///
  /// Bootstraps from whoever's left waiting once on-court + challenger are
  /// already seeded. If no eligible waiting player exists at commit time (a
  /// tight court), the current scorekeeper is kept and their team plays
  /// short instead, via the `_startSlot` substitute fallback.
  void _refreshScorekeeper() {
    if (!_isAllPlay) return;

    // A pool team's slot doesn't move when one of its members is borrowed
    // out as the floater's jumper partner — so without this exclusion that
    // player would look like a normal waiting candidate here, even though
    // they're actually mid-match as Challenger or Court right now.
    final busyJumperPartnerId = _busyJumperPartnerId;
    final eligible = <String>[];
    for (final slotId in _pool) {
      if (slotId == _formation.floaterSlot?.slotId) {
        eligible.add(_formation.floaterSlot!.playerId);
      } else {
        final team = _formation.teamSlots.firstWhere((s) => s.slotId == slotId);
        eligible.addAll(team.playerIds);
      }
    }
    eligible.remove(busyJumperPartnerId);
    final upNext = _upNextSlotId;

    if (_adminPlayerId == null) {
      final preferred = eligible
          .where((pid) => _slotIdForPlayer(pid) != upNext)
          .toList();
      final pick = _pickFairestScorekeeper(
        preferred.isNotEmpty ? preferred : eligible,
      );
      if (pick != null) {
        setState(() {
          _adminPlayerId = pick;
          _scorekeepCounts[pick] = (_scorekeepCounts[pick] ?? 0) + 1;
        });
      }
      return;
    }

    final adminSlot = _adminSlotId;
    if (adminSlot == null) return;

    if (adminSlot == _challengerSlotId) {
      // COMMIT: the previewed successor becomes real, right as the admin's
      // slot is about to be promoted to court. The preview can go stale
      // between being set and committed — this same chain-advance's
      // `_topUpQueue()` may have already pulled the previewed player's team
      // out of the pool and into Up Next — so it's only honored if they're
      // still actually eligible; otherwise a fresh pick is made from who's
      // in the pool right now.
      final candidates = eligible
          .where((pid) => pid != _adminPlayerId)
          .toList();
      final preferred = candidates
          .where((pid) => _slotIdForPlayer(pid) != upNext)
          .toList();
      final previewStillValid =
          _nextAdminPlayerId != null && eligible.contains(_nextAdminPlayerId);
      final successor = previewStillValid
          ? _nextAdminPlayerId
          : _pickFairestScorekeeper(
              preferred.isNotEmpty ? preferred : candidates,
            );
      if (successor != null) {
        setState(() {
          _adminPlayerId = successor;
          _nextAdminPlayerId = null;
          _scorekeepCounts[successor] = (_scorekeepCounts[successor] ?? 0) + 1;
        });
      }
      return;
    }

    if (adminSlot == upNext) {
      // PREVIEW: one step away from being needed — compute (and hold) a
      // successor so the coach can see the handoff coming.
      if (_nextAdminPlayerId == null) {
        final candidates = eligible
            .where((pid) => pid != _adminPlayerId)
            .toList();
        final preferred = candidates
            .where((pid) => _slotIdForPlayer(pid) != upNext)
            .toList();
        final pick = _pickFairestScorekeeper(
          preferred.isNotEmpty ? preferred : candidates,
        );
        if (pick != null) setState(() => _nextAdminPlayerId = pick);
      }
    } else if (_nextAdminPlayerId != null) {
      // No longer imminent — clear the stale preview.
      setState(() => _nextAdminPlayerId = null);
    }
  }

  void _ejectChallenger() {
    if (!_canEjectChallenger) return;
    _chainBeforeChallengerEject = _currentChainSnapshot;
    setState(() {
      _lastEjectedChallengerSlotId = _challengerSlotId;
      _pool.add(_challengerSlotId!);
      _challengerSlotId = _upNextSlotId; // promote exactly the visible Up Next
      _upNextSlotId = null;
      _topUpQueue();
      _updateFloaterJumperAssignment();
    });
    _refreshScorekeeper();
  }

  void _undoEjectChallenger() {
    if (_lastEjectedChallengerSlotId == null) return;
    final snapshot = _chainBeforeChallengerEject;
    setState(() {
      if (snapshot != null) {
        _restoreChainSnapshot(snapshot);
        _chainBeforeChallengerEject = null;
      } else {
        // Fallback: shouldn't normally happen (every eject takes a
        // snapshot) — falls back to the old "soft undo" (both
        // currently-visible slots return to the pool, the old challenger is
        // restored, and fairness re-derives a fresh Up Next) rather than
        // perfectly rewinding the reveal.
        if (_challengerSlotId != null) _pool.add(_challengerSlotId!);
        if (_upNextSlotId != null) _pool.add(_upNextSlotId!);
        _pool.remove(_lastEjectedChallengerSlotId);
        _challengerSlotId = _lastEjectedChallengerSlotId;
        _upNextSlotId = null;
        _topUpQueue();
        _updateFloaterJumperAssignment();
      }
      _lastEjectedChallengerSlotId = null;
    });
    if (snapshot == null) _refreshScorekeeper();
  }

  // ── Scoring / ejection ────────────────────────────────────────────────────

  void _addPoint() {
    if (!_hasCourt || !_timerRunning) return;
    setState(() => _currentPoints++);
    if (_strikeEnabled && _currentPoints >= _t.strikePoints) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _ejectCourt(reason: ScrambleKingStintEndReason.strike),
      );
    }
  }

  void _removePoint() {
    if (!_hasCourt || !_timerRunning || _currentPoints <= 0) return;
    setState(() => _currentPoints--);
  }

  ScrambleKingStint _buildStint({required ScrambleKingStintEndReason reason}) {
    final isFloaterTurn = _onCourtSlotId == _formation.floaterSlot?.slotId;
    final List<String> playerIds;
    if (isFloaterTurn) {
      // Placeholder mode leaves _onCourtTempPartnerId null — the app never
      // assigns or records a specific partner for that slot; only jumper
      // mode (or a manual explicit pick) ever has one here.
      playerIds = [_formation.floaterSlot!.playerId, ?_onCourtTempPartnerId];
    } else if (_onCourtBenchedPlayerId != null &&
        _onCourtTempPartnerId != null) {
      // Auto-Allplay tight-court fallback: this team played short a member
      // (busy scorekeeping) — the stint's real playerIds substitute in the
      // borrowed partner, even though the slot's fixed roster still
      // includes the benched player (and is still credited normally below).
      final team = _formation.teamSlots.firstWhere(
        (s) => s.slotId == _onCourtSlotId!,
      );
      playerIds = [
        for (final pid in team.playerIds)
          if (pid != _onCourtBenchedPlayerId) pid,
        _onCourtTempPartnerId!,
      ];
    } else {
      playerIds = _formation.teamSlots
          .firstWhere((s) => s.slotId == _onCourtSlotId!)
          .playerIds;
    }

    return ScrambleKingStint(
      id: ScrambleKingStint.generateId(),
      roundId: _round.id,
      courtNumber: widget.courtNumber,
      turnSlotId: _onCourtSlotId!,
      // The on-court slot's own team is always credited — including the
      // floater's own team, and a scorekeeper-short team playing with a sub.
      creditSlotId: _onCourtSlotId!,
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
    _chainBeforeCourtEject = _currentChainSnapshot;
    final stint = _buildStint(reason: reason);
    _stintWatch
      ..stop()
      ..reset();

    final ejectedSlot = _onCourtSlotId!;
    setState(() {
      _pool.add(ejectedSlot);
      _onCourtSlotId = null;
      _onCourtTempPartnerId = null;
      _onCourtBenchedPlayerId = null;
      _currentPoints = 0;
    });
    _updateTournament(_t.addStint(stint));

    if (_isAutoMode && _challengerSlotId != null) {
      // Promote exactly the slot already shown as Challengers, and shift
      // Up Next into its place — the chain never gets re-ranked, only the
      // one freshly-opened gap at the end does (via `_topUpQueue` below).
      final next = _challengerSlotId!;
      _challengerSlotId = _upNextSlotId;
      _upNextSlotId = null;
      _startSlot(next); // its own setState flushes the two lines above too
      setState(() {
        _topUpQueue();
        _updateFloaterJumperAssignment();
      });
      _refreshScorekeeper();
    }
  }

  /// Restores the last ejected slot + their points, and the rest of the
  /// waiting chain exactly as it was right before the ejection (see
  /// `_chainBeforeCourtEject`) — so undo, then redo, reproduces the same
  /// result rather than letting fairness ranking re-derive a possibly
  /// different one.
  ///
  /// If a team is currently on court and has already racked up points of
  /// its own, undoing would silently overwrite them with the restored
  /// team's tally — so that case is confirmed first.
  Future<void> _undoEjectCourt() async {
    if (!_canUndoEjectCourt) return;
    if (_currentPoints > 0) {
      final l10n = AppLocalizations.of(context)!;
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(l10n.scrambleKingUndoDiscardPointsTitle),
          content: Text(l10n.scrambleKingUndoDiscardPointsBody(_currentPoints)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(l10n.btnCancel),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                foregroundColor: Colors.white,
              ),
              child: Text(l10n.scrambleKingUndoDiscardPointsConfirm),
            ),
          ],
        ),
      );
      if (ok != true) return;
      if (!mounted) return;
    }
    if (_hasCourt) {
      _stintWatch
        ..stop()
        ..reset();
    }
    final lastStint = _courtStints.last;
    final restoredSlotId = lastStint.turnSlotId;
    final (tempPartner, benched) = _resolveStintSubstitution(lastStint);
    final snapshot = _chainBeforeCourtEject;
    setState(() {
      _onCourtSlotId = restoredSlotId;
      _onCourtTempPartnerId = tempPartner;
      _onCourtBenchedPlayerId = benched;
      _currentPoints = lastStint.points;
      if (snapshot != null) {
        _restoreChainSnapshot(snapshot);
        _chainBeforeCourtEject = null;
      } else {
        // Fallback: shouldn't normally happen (every eject takes a
        // snapshot) — falls back to the old "soft undo" (reset everyone
        // else to a flat pool and let the chain be freshly re-seeded)
        // rather than reversing the promotion step by step.
        _pool = List.from(ScrambleKingService.initialQueueOrder(_formation))
          ..remove(restoredSlotId);
        _floaterJumperPartnerId = null;
        _challengerSlotId = null;
        _upNextSlotId = null;
        _topUpQueue();
        _updateFloaterJumperAssignment();
      }
      _lastEjectedChallengerSlotId = null;
    });
    _updateTournament(
      _t.copyWith(
        stints: _t.stints.where((s) => s.id != lastStint.id).toList(),
      ),
    );
    _stintWatch.reset();
    if (_timerRunning) _stintWatch.start();
    if (snapshot == null) _refreshScorekeeper();
  }

  // ── Round-end handling (mirrors ScrambleScorecardPage's timer-finished +
  // _reflowIfRoundComplete pattern) ────────────────────────────────────────

  void _onMatchTimerFinished() {
    setState(() => _timerRunning = false);
    _completeCourt();
  }

  void _completeCourt() {
    var updated = _t;
    if (_onCourtSlotId != null) {
      updated = updated.addStint(
        _buildStint(reason: ScrambleKingStintEndReason.timeout),
      );
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
      _onCourtBenchedPlayerId = null;
      _currentPoints = 0;
    });
    _updateTournament(updated);
  }

  ScrambleKingTournament _reflowIfRoundComplete(
    ScrambleKingTournament updated,
    String roundId,
  ) {
    final round = updated.getRound(roundId)!;
    if (!round.courts.every((c) => c.isCompleted)) return updated;

    final now = DateTime.now();
    final actualEnd = round.courts
        .map((c) => c.actualEndTime ?? now)
        .reduce((a, b) => a.isAfter(b) ? a : b);
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
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.btnCancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: _kOlive,
              foregroundColor: Colors.white,
            ),
            child: Text(l10n.scrambleKingFinishCourt),
          ),
        ],
      ),
    );
    if (ok != true) return;
    _completeCourt();
    // Ending the court before time runs out skips the natural review step,
    // so open the editable results sheet immediately in case the auto-scored
    // stint needs a correction.
    if (!mounted) return;
    _showRanking();
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
        (stints.isNotEmpty &&
            stints.last.endReason == ScrambleKingStintEndReason.timeout)
        ? stints.last
        : null;
    if (restoredStint != null) {
      updated = updated.copyWith(
        stints: updated.stints.where((s) => s.id != restoredStint.id).toList(),
      );
    }
    final round = updated.getRound(widget.roundId)!;
    final formation = round.getCourt(widget.courtNumber)!;
    updated = updated.updateRound(
      round.updateCourt(formation.copyWith(clearActualEndTime: true)),
    );

    setState(() {
      _t = updated;
      _resumeLiveState(restoredStint: restoredStint);
    });
    if (_timerInitialRemaining == Duration.zero) {
      // Match time had already elapsed when this court was finished —
      // silently re-enter the finished state (no ticking, no re-firing
      // onFinished) so we land on the live scorecard and STAY there,
      // instead of the timer immediately re-counting down 0→amber→red and
      // re-triggering completion on its own.
      _matchTimerKey.currentState?.markFinished();
    }
    _persist();
  }

  // ── Manual score override (results view) ─────────────────────────────────

  Future<void> _editTeamResult(ScrambleKingTeamResult team) async {
    final gamesCtrl = TextEditingController(text: '${team.gamesWon}');
    final pointsCtrl = TextEditingController(text: '${team.points}');
    final l10n = AppLocalizations.of(context)!;
    final playerNames = team.playerIds.map(_nameFor).join(' & ');
    final teamName = _teamNameForSlot(team.slotId) ?? playerNames;
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(l10n.scrambleKingEditTeamResult),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              teamName,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
            ),
            if (teamName != playerNames)
              Text(
                playerNames,
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
            const SizedBox(height: 16),
            TextField(
              controller: gamesCtrl,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: InputDecoration(
                labelText: l10n.scrambleKingGamesWonLabel,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: pointsCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: l10n.scrambleKingPointsLabel,
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.btnCancel),
          ),
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
          final result = ScrambleKingService.computeCourtRoundResult(
            _t,
            _round.id,
            widget.courtNumber,
          );
          final totalPoints = result.teamResults.fold<int>(
            0,
            (a, t) => a + t.points,
          );

          return TournaQSheet(
            body: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.scrambleKingScorecard,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.scrambleKingTeamsSummary(
                      result.teamResults.length,
                      totalPoints,
                    ),
                    style: const TextStyle(fontSize: 13, color: Colors.black45),
                  ),
                  const SizedBox(height: 16),
                  _buildRankingTable(
                    l10n,
                    onEdited: () => setSheetState(() {}),
                  ),
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
          // Excludes the current jumper partner too — their team slot stays
          // in `_pool` while they're individually borrowed out to play
          // Challenger/Court, but they must never double as admin.
          final busyJumperPartnerId = _busyJumperPartnerId;
          final poolPlayers = <(String id, String name)>[];
          for (final slotId in _pool) {
            if (slotId == _formation.floaterSlot?.slotId) {
              poolPlayers.add((
                _formation.floaterSlot!.playerId,
                _nameFor(_formation.floaterSlot!.playerId),
              ));
            } else {
              final team = _formation.teamSlots.firstWhere(
                (s) => s.slotId == slotId,
              );
              for (final pid in team.playerIds) {
                if (pid != busyJumperPartnerId) {
                  poolPlayers.add((pid, _nameFor(pid)));
                }
              }
            }
          }

          return TournaQSheet(
            body: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.kotcChangeAdmin,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
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
                        color: pid == _adminPlayerId
                            ? AppColors.goldCream
                            : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(10),
                        child: InkWell(
                          onTap: () {
                            Navigator.pop(ctx);
                            setState(() {
                              _adminPlayerId = pid;
                              _nextAdminPlayerId = null;
                              _scorekeepCounts[pid] =
                                  (_scorekeepCounts[pid] ?? 0) + 1;
                            });
                            _refreshScorekeeper();
                          },
                          borderRadius: BorderRadius.circular(10),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            child: Text(
                              name,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: pid == _adminPlayerId
                                    ? AppColors.goldDark
                                    : Colors.black87,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  if (_nextAdminPlayerId != null) ...[
                    const Divider(height: 24),
                    Text(
                      l10n.kotcNextAdmin,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.black45,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.scrambleKingNextAdminNote,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black45,
                      ),
                    ),
                    const SizedBox(height: 8),
                    for (final (pid, name) in poolPlayers.where(
                      (p) => p.$1 != _adminPlayerId,
                    ))
                      Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        child: Material(
                          color: pid == _nextAdminPlayerId
                              ? Colors.grey.shade200
                              : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(10),
                          child: InkWell(
                            onTap: () {
                              Navigator.pop(ctx);
                              setState(() => _nextAdminPlayerId = pid);
                            },
                            borderRadius: BorderRadius.circular(10),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              child: Text(
                                name,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: pid == _nextAdminPlayerId
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          ),
                        ),
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
  Widget _buildRankingTable(
    AppLocalizations l10n, {
    required VoidCallback onEdited,
  }) {
    final result = ScrambleKingService.computeCourtRoundResult(
      _t,
      _round.id,
      widget.courtNumber,
    );
    const headerStyle = TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w700,
      color: Colors.black45,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Row(
            children: [
              Expanded(
                child: Text(l10n.scrambleKingTeamsLabel, style: headerStyle),
              ),
              SizedBox(
                width: 44,
                child: Text(
                  l10n.kotcStatGames,
                  textAlign: TextAlign.center,
                  style: headerStyle,
                ),
              ),
              SizedBox(
                width: 52,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.emoji_events_rounded,
                      size: 11,
                      color: Colors.black45,
                    ),
                    const SizedBox(width: 2),
                    Flexible(
                      child: Text(
                        l10n.kotcStatWins,
                        style: headerStyle,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 44,
                child: Text(
                  l10n.kotcStatPts,
                  textAlign: TextAlign.right,
                  style: headerStyle,
                ),
              ),
            ],
          ),
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
                color: team.rank == 1
                    ? AppColors.goldCream
                    : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: team.rank == 1
                      ? _kGold.withValues(alpha: 0.4)
                      : Colors.grey.shade200,
                ),
              ),
              child: Row(
                children: [
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
                            color: team.rank == 1 ? _kGold : Colors.black87,
                          ),
                        ),
                        Text(
                          team.playerIds.map(_nameFor).join(' & '),
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.black45,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 44,
                    child: Text(
                      '${team.gamesPlayed}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 52,
                    child: Text(
                      '${team.gamesWon}',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: team.gamesWon > 0 ? _kGold : Colors.black38,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 44,
                    child: Text(
                      '${team.points}',
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
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
        subtitle: widget.isImported
            ? l10n.scrambleImportedScorecard
            : l10n.scrambleKingScorecard,
        actions: [_buildAppBarAction(l10n)],
      ),
      body: SafeArea(
        child: OrientationBuilder(
          builder: (context, orientation) =>
              orientation == Orientation.landscape
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
          _sectionHeader(
            l10n.doghouseGameplayControls,
            Icons.sports_volleyball_rounded,
          ),
          const SizedBox(height: 10),
          if (_t.paceAlertsEnabled) ...[
            _buildScheduleCard(l10n),
            const SizedBox(height: 10),
          ],
          _buildRoundTimerRow(l10n),
          const SizedBox(height: 10),
          if (_formation.isCompleted) ...[
            _buildRoundCompleteBanner(l10n),
          ] else if (!_hasStarted) ...[
            _buildStartCourtCard(l10n),
          ] else if (_hasCourt && _isAutoMode) ...[
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
          _sectionHeader(
            l10n.doghouseMatchControls,
            Icons.emoji_events_rounded,
          ),
          const SizedBox(height: 10),
          _buildMatchControls(l10n),
          _buildUpcomingCourts(l10n),
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
            child: Stack(
              children: [
                _buildLandscapeCourtContent(l10n),
                if (_t.paceAlertsEnabled && _scheduleExpanded)
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 0,
                    child: _buildLandscapePacePanel(l10n),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // The court content under the timer row. The pace panel is overlaid on top
  // of this (via a Stack in _buildLandscapeBody) rather than inserted above it,
  // so expanding the schedule never shrinks the scoring tile into an overflow.
  Widget _buildLandscapeCourtContent(AppLocalizations l10n) {
    return _formation.isCompleted
                ? SingleChildScrollView(child: _buildRoundCompleteBanner(l10n))
                : !_hasStarted
                ? SingleChildScrollView(child: _buildStartCourtCard(l10n))
                : _hasCourt && _isAutoMode
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: _buildUpNextTile(l10n, compact: true),
                            ),
                            const SizedBox(height: 6),
                            Expanded(
                              child: _buildChallengersTile(l10n, compact: true),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      SizedBox(
                        width: 56,
                        child: _buildChallengerEjectColumn(l10n),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: _buildActiveScoringTile(
                                l10n,
                                compact: true,
                              ),
                            ),
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
                      Expanded(
                        flex: 4,
                        child: _buildActiveScoringTile(l10n, compact: true),
                      ),
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
                  );
  }

  // ── Schedule card (pace alerts) ──────────────────────────────────────────

  (Color, String) _scheduleStatus(AppLocalizations l10n) {
    final now = DateTime.now();
    if (now.isAfter(_round.scheduledMatchEndTime)) {
      return (Colors.red.shade600, l10n.statusOverdue);
    }
    if (now.isAfter(_round.scheduledStartTime)) {
      return (Colors.amber.shade700, l10n.statusDue);
    }
    return (Colors.green.shade600, l10n.statusUpcoming);
  }

  Widget _scheduleChip(String label, Color fg, Color bg) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      label,
      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: fg),
    ),
  );

  // Actual-vs-planned start/end chips (mirrors ScrambleScorecardPage).
  String _paceDelta(int m) =>
      m.abs() <= 1 ? 'on time' : (m > 0 ? '+${m}m' : '${m}m');

  Widget _startChip() {
    final start = _round.scheduledStartTime;
    final actualStart = _formation.actualStartTime;
    if (actualStart != null) {
      final m = actualStart.difference(start).inMinutes;
      final late = m > 1;
      return _scheduleChip(
        '${_fmtTime(actualStart)} (${_paceDelta(m)})',
        late ? Colors.orange.shade700 : _kOlive,
        late ? Colors.orange.withValues(alpha: 0.12) : _kOliveLight,
      );
    }
    final mins = start.difference(DateTime.now()).inMinutes;
    if (mins > 0) return _scheduleChip('In ${mins}m', _kOlive, _kOliveLight);
    if (mins == 0) return _scheduleChip('Now', _kOlive, _kOliveLight);
    return _scheduleChip(
      '${-mins}m late',
      Colors.orange.shade700,
      Colors.orange.withValues(alpha: 0.12),
    );
  }

  Widget _endChip() {
    final end = _round.scheduledMatchEndTime;
    final actualEnd = _formation.actualEndTime;
    if (_formation.isCompleted && actualEnd != null) {
      final m = actualEnd.difference(end).inMinutes;
      final over = m > 1;
      return _scheduleChip(
        '✓ ${_fmtTime(actualEnd)} (${_paceDelta(m)})',
        over ? Colors.orange.shade700 : _kOlive,
        over ? Colors.orange.withValues(alpha: 0.12) : _kOliveLight,
      );
    }
    final mins = end.difference(DateTime.now()).inMinutes;
    if (mins > 0) {
      final soon = mins <= 5;
      return _scheduleChip(
        '${mins}m left',
        soon ? Colors.orange.shade700 : Colors.black54,
        soon ? Colors.orange.withValues(alpha: 0.12) : Colors.grey.shade100,
      );
    }
    final over = DateTime.now().difference(end).inMinutes.clamp(0, 9999);
    return _scheduleChip(
      '${over}m over',
      Colors.red.shade700,
      Colors.red.withValues(alpha: 0.1),
    );
  }

  // Shared expanded detail — start row, end row, and the "hurry up" warning
  // when overdue. Used by the portrait collapsible card and the landscape
  // inline expanding strip.
  Widget _buildScheduleDetail(AppLocalizations l10n) {
    final start = _round.scheduledStartTime;
    final end = _round.scheduledMatchEndTime;
    final isOverEnd =
        DateTime.now().isAfter(end) && !_formation.isCompleted;
    final timeColor = isOverEnd ? Colors.red.shade700 : Colors.black87;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            const Icon(
              Icons.play_circle_outline_rounded,
              size: 13,
              color: Colors.black38,
            ),
            const SizedBox(width: 6),
            SizedBox(
              width: 40,
              child: Text(
                l10n.btnStart,
                style: const TextStyle(fontSize: 11, color: Colors.black45),
              ),
            ),
            Text(
              _fmtTime(start),
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: timeColor,
              ),
            ),
            const Spacer(),
            _startChip(),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Icon(
              Icons.stop_circle_outlined,
              size: 13,
              color: isOverEnd ? Colors.red.shade300 : Colors.black38,
            ),
            const SizedBox(width: 6),
            SizedBox(
              width: 40,
              child: Text(
                l10n.scorecardEnd,
                style: const TextStyle(fontSize: 11, color: Colors.black45),
              ),
            ),
            Text(
              _fmtTime(end),
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: timeColor,
              ),
            ),
            const Spacer(),
            _endChip(),
          ],
        ),
        if (isOverEnd) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded, size: 13, color: Colors.red),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  l10n.scorecardOverScheduleHurry,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.red,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  // Compact tappable pace indicator (target end time + status chip) for the
  // landscape timer row — toggles the inline expanding detail strip.
  Widget _buildPaceChip(AppLocalizations l10n) {
    final (statusColor, statusText) = _scheduleStatus(l10n);
    return InkWell(
      onTap: () => setState(() => _scheduleExpanded = !_scheduleExpanded),
      borderRadius: BorderRadius.circular(20),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.flag_outlined, size: 13, color: _kOlive),
          const SizedBox(width: 3),
          Text(
            _fmtTime(_round.scheduledMatchEndTime),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: _kOlive,
            ),
          ),
          const SizedBox(width: 6),
          _scheduleChip(
            statusText,
            statusColor,
            statusColor.withValues(alpha: 0.14),
          ),
          Icon(
            _scheduleExpanded
                ? Icons.expand_less_rounded
                : Icons.expand_more_rounded,
            size: 16,
            color: Colors.black38,
          ),
        ],
      ),
    );
  }

  // Landscape overlay panel — the expanded schedule detail floated over the
  // court (opaque, same olive / overdue-red palette as the portrait schedule
  // card) so it never reflows the tiles beneath it.
  Widget _buildLandscapePacePanel(AppLocalizations l10n) {
    final isOverEnd = DateTime.now().isAfter(_round.scheduledMatchEndTime) &&
        !_formation.isCompleted;
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isOverEnd ? const Color(0xFFFCE9E9) : _kOliveLight,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isOverEnd
                ? Colors.red.withValues(alpha: 0.3)
                : _kOlive.withValues(alpha: 0.25),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: _buildScheduleDetail(l10n),
      ),
    );
  }

  // Portrait collapsible schedule card.
  Widget _buildScheduleCard(AppLocalizations l10n) {
    final (statusColor, statusText) = _scheduleStatus(l10n);
    final isOverEnd = DateTime.now().isAfter(_round.scheduledMatchEndTime) &&
        !_formation.isCompleted;
    final labelColor = isOverEnd ? Colors.red : _kOlive;
    return Container(
      decoration: BoxDecoration(
        color: isOverEnd ? Colors.red.withValues(alpha: 0.06) : _kOliveLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isOverEnd ? Colors.red.withValues(alpha: 0.3) : Colors.transparent,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () => setState(() => _scheduleExpanded = !_scheduleExpanded),
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              child: Row(
                children: [
                  Icon(Icons.schedule_rounded, size: 14, color: labelColor),
                  const SizedBox(width: 6),
                  Text(
                    '${_fmtTime(_round.scheduledStartTime)} – ${_fmtTime(_round.scheduledMatchEndTime)}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: labelColor,
                    ),
                  ),
                  const Spacer(),
                  if (!_scheduleExpanded) ...[
                    _scheduleChip(
                      statusText,
                      statusColor,
                      statusColor.withValues(alpha: 0.14),
                    ),
                    const SizedBox(width: 6),
                  ],
                  Icon(
                    _scheduleExpanded
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    size: 18,
                    color: Colors.black38,
                  ),
                ],
              ),
            ),
          ),
          if (_scheduleExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
              child: _buildScheduleDetail(l10n),
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

    final ts = _matchTimerKey.currentState?.timerState;
    final running = ts == ScrambleTimerState.running;
    final paused = ts == ScrambleTimerState.paused;
    final notStarted = !_hasStarted;
    // Keep the control row to a single line (mirrors ScrambleScorecardPage):
    // Pause and Resume are mutually exclusive, and the trailing button is
    // contextual — Start when idle, Restart once the court is under way.
    final controls = <Widget>[
      if (running)
        _refBtn(Icons.pause_rounded, l10n.btnStop, () {
          _matchTimerKey.currentState?.pause();
          setState(() => _timerRunning = false);
        })
      else if (paused)
        _refBtn(Icons.play_arrow_rounded, l10n.btnResume, () {
          _matchTimerKey.currentState?.resume();
          setState(() => _timerRunning = true);
        }, primary: true),
      _refBtn(
        notStarted ? Icons.play_arrow_rounded : Icons.replay_rounded,
        notStarted ? l10n.btnStart : l10n.btnRestart,
        () {
          if (!_hasStarted) {
            _startCourt();
            return;
          }
        // Always records the current time and resets the timer to the full
        // match duration before starting — mirrors
        // ScrambleScorecardPage._startOrRestart. `restart()` alone can't be
        // trusted here since `_timerInitialRemaining` may be stale (e.g.
        // zero, from a previous cold-open), so reset explicitly.
        final updatedFormation = _formation.copyWith(
          actualStartTime: DateTime.now(),
        );
        _t = _t.updateRound(_round.updateCourt(updatedFormation));
        _matchTimerKey.currentState?.setRemaining(_round.matchDuration);
        _matchTimerKey.currentState?.start();
        setState(() => _timerRunning = true);
        _persist();
      }),
      _refTextBtn(
        '+30s',
        () => _matchTimerKey.currentState?.addTime(const Duration(seconds: 30)),
      ),
      _refTextBtn(
        '−30s',
        () =>
            _matchTimerKey.currentState?.addTime(const Duration(seconds: -30)),
      ),
    ];

    if (inline) {
      return Row(
        children: [
          const Icon(Icons.timer_rounded, size: 13, color: _kOlive),
          const SizedBox(width: 4),
          timer,
          const SizedBox(width: 8),
          Expanded(child: Wrap(spacing: 6, runSpacing: 6, children: controls)),
          if (_t.paceAlertsEnabled) ...[
            const SizedBox(width: 8),
            _buildPaceChip(l10n),
          ],
        ],
      );
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
          Row(
            children: [
              const Icon(Icons.timer_rounded, size: 14, color: _kOlive),
              const SizedBox(width: 6),
              Text(
                l10n.scrambleKingRoundTimer,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: _kOlive,
                  letterSpacing: 0.6,
                ),
              ),
              const Spacer(),
              timer,
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            alignment: WrapAlignment.center,
            children: controls,
          ),
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
        child: Row(
          children: [
            const Icon(Icons.gavel_rounded, size: 15, color: Colors.black45),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                l10n.scrambleKingRefereeBanner(_nameFor(_adminPlayerId!)),
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.black54,
                ),
              ),
            ),
            if (_nextAdminPlayerId != null) ...[
              const SizedBox(width: 8),
              const Icon(
                Icons.arrow_forward_rounded,
                size: 13,
                color: Colors.black38,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  _nameFor(_nextAdminPlayerId!),
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ),
            ],
            const SizedBox(width: 6),
            const Icon(Icons.edit_rounded, size: 13, color: Colors.black38),
          ],
        ),
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
        padding: EdgeInsets.all(compact ? 6 : 14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Label + team name always render in full here, outside the
            // scrollable body below — so the team name stays visible no
            // matter how many lines the player chips wrap onto.
            _upNextTileHeader(l10n, teamName, compact),
            SizedBox(height: compact ? 2 : 8),
            // Same rationale as the selection/suggestion tiles: this has no
            // Expanded/flexible child, so at squeezed heights (Up Next and
            // Challengers each get roughly half of what the active scoring
            // tile gets, stacked in the same column) it scrolls instead of
            // relying on a fixed height budget.
            compact
                ? SingleChildScrollView(
                    child: _upNextTileBody(l10n, slotId, compact))
                : _upNextTileBody(l10n, slotId, compact),
          ],
        ),
      ),
    );
  }

  Widget _upNextTileHeader(
    AppLocalizations l10n,
    String? teamName,
    bool compact,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(
              Icons.schedule_rounded,
              size: compact ? 13 : 15,
              color: Colors.grey.shade500,
            ),
            const SizedBox(width: 6),
            Text(
              l10n.kotcUpNext,
              style: TextStyle(
                fontSize: compact ? 11 : 12,
                fontWeight: FontWeight.w700,
                color: Colors.grey.shade500,
                letterSpacing: 0.4,
              ),
            ),
            const Spacer(),
            if (_upNextSlotId != null && _pool.isNotEmpty)
              compact
                  ? IconButton(
                      onPressed: _rerollUpNext,
                      icon: const Icon(Icons.refresh_rounded, size: 15),
                      color: _kOlive,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      visualDensity: VisualDensity.compact,
                      tooltip: l10n.quickStartReRoll,
                    )
                  : TextButton.icon(
                      onPressed: _rerollUpNext,
                      icon: const Icon(Icons.refresh_rounded, size: 13),
                      label: Text(
                        l10n.quickStartReRoll,
                        style: const TextStyle(fontSize: 11),
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: _kOlive,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
          ],
        ),
        if (teamName != null) ...[
          SizedBox(height: compact ? 1 : 3),
          _teamCaption(teamName, Colors.grey.shade500, compact: compact),
        ],
      ],
    );
  }

  Widget _upNextTileBody(AppLocalizations l10n, String? slotId, bool compact) {
    if (slotId == null) {
      return Text(
        l10n.kotcWaitingForPlayers,
        style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
      );
    }
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: [
        ..._slotChipNames(slotId).map(
          (n) => _nameChip(
            n,
            Colors.grey.shade600,
            bg: Colors.grey.shade200,
            border: null,
            compact: compact,
          ),
        ),
        if (slotId == _formation.floaterSlot?.slotId)
          _floaterPartnerChip(
            l10n,
            Colors.grey.shade600,
            bg: Colors.grey.shade200,
            border: Colors.grey.shade400,
            compact: compact,
            partnerId: _floaterJumperPartnerId,
          ),
      ],
    );
  }

  // ── Challengers tile (olive) ─────────────────────────────────────────────

  Widget _buildChallengersTile(AppLocalizations l10n, {bool compact = false}) {
    final hasChallenger = _challengerSlotId != null;
    final teamName = hasChallenger
        ? _teamNameForSlot(_challengerSlotId!)
        : null;
    return Card(
      margin: compact ? EdgeInsets.zero : null,
      color: _kOliveLight,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: _kOlive.withValues(alpha: 0.35), width: 1.5),
      ),
      child: Padding(
        padding: EdgeInsets.all(compact ? 6 : 14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Label + team name always render in full here — see
            // `_upNextTileHeader` for why this is kept out of the scrollable
            // body below.
            _challengersTileHeader(l10n, teamName, compact),
            SizedBox(height: compact ? 2 : 8),
            // Same rationale as _upNextTileBody.
            compact
                ? SingleChildScrollView(
                    child: _challengersTileBody(l10n, hasChallenger, compact))
                : _challengersTileBody(l10n, hasChallenger, compact),
          ],
        ),
      ),
    );
  }

  Widget _challengersTileHeader(
    AppLocalizations l10n,
    String? teamName,
    bool compact,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(Icons.groups_rounded, size: compact ? 13 : 15, color: _kOlive),
            const SizedBox(width: 6),
            Text(
              l10n.kotcChallengers,
              style: TextStyle(
                fontSize: compact ? 11 : 12,
                fontWeight: FontWeight.w700,
                color: _kOlive,
                letterSpacing: 0.4,
              ),
            ),
          ],
        ),
        if (teamName != null) ...[
          SizedBox(height: compact ? 1 : 3),
          _teamCaption(teamName, _kOlive, compact: compact),
        ],
      ],
    );
  }

  Widget _challengersTileBody(
    AppLocalizations l10n,
    bool hasChallenger,
    bool compact,
  ) {
    if (!hasChallenger) {
      return Text(
        l10n.kotcWaitingForPlayers,
        style: const TextStyle(color: _kOlive, fontSize: 12),
      );
    }
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: [
        ..._slotChipNames(_challengerSlotId!).map(
          (n) => _nameChip(
            n,
            _kOlive,
            bg: _kOlive.withValues(alpha: 0.15),
            border: _kOlive.withValues(alpha: 0.4),
            compact: compact,
          ),
        ),
        if (_challengerSlotId == _formation.floaterSlot?.slotId)
          _floaterPartnerChip(
            l10n,
            _kOlive,
            bg: _kOlive.withValues(alpha: 0.15),
            border: _kOlive.withValues(alpha: 0.4),
            compact: compact,
            partnerId: _floaterJumperPartnerId,
          ),
      ],
    );
  }

  // ── Active scoring tile (gold) ───────────────────────────────────────────

  Widget _buildActiveScoringTile(
    AppLocalizations l10n, {
    bool compact = false,
  }) {
    final nearStrike =
        _strikeEnabled &&
        _currentPoints >= (_t.strikePoints - 1).clamp(0, _t.strikePoints);
    final teamName = _onCourtSlotId != null
        ? _teamNameForSlot(_onCourtSlotId!)
        : null;
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
            ? const EdgeInsets.fromLTRB(12, 8, 12, 6)
            : const EdgeInsets.fromLTRB(16, 16, 16, 12),
        child: Column(
          mainAxisSize: compact ? MainAxisSize.max : MainAxisSize.min,
          children: [
            // Tile header, mirroring the "UP NEXT" / "CHALLENGERS" tiles.
            Row(
              children: [
                Icon(
                  Icons.sports_volleyball_rounded,
                  size: compact ? 13 : 15,
                  color: _kGold,
                ),
                const SizedBox(width: 6),
                Text(
                  l10n.scrambleKingCourtLabel.toUpperCase(),
                  style: TextStyle(
                    fontSize: compact ? 11 : 12,
                    fontWeight: FontWeight.w700,
                    color: _kGold,
                    letterSpacing: 0.4,
                  ),
                ),
              ],
            ),
            SizedBox(height: compact ? 2 : 8),
            if (teamName != null) _teamCaption(teamName, _kGold, compact: compact),
            // Player chips
            Wrap(
              spacing: 6,
              runSpacing: 4,
              alignment: WrapAlignment.center,
              children: [
                ..._onCourtChipNames().map(
                  (n) => _nameChip(
                    n,
                    _kGold,
                    bg: _kGold.withValues(alpha: 0.15),
                    border: _kGold.withValues(alpha: 0.5),
                    compact: compact,
                  ),
                ),
                // Same role badge as the waiting tiles, so the floater's
                // team reads as a permanent [Name] + [role] pairing all
                // round, on court included. Here the relevant partner is
                // whoever is actually playing this stint
                // (`_onCourtTempPartnerId`), not the waiting-phase lock —
                // that was already cleared the moment this stint started.
                if (_onCourtSlotId == _formation.floaterSlot?.slotId)
                  _floaterPartnerChip(
                    l10n,
                    _kGold,
                    bg: _kGold.withValues(alpha: 0.15),
                    border: _kGold.withValues(alpha: 0.5),
                    compact: compact,
                    partnerId: _onCourtTempPartnerId,
                  ),
              ],
            ),
            SizedBox(height: compact ? 2 : 8),
            // Game clock + strike badge
            Row(
              children: [
                Icon(
                  Icons.timer_rounded,
                  size: compact ? 11 : 12,
                  color: _kGold.withValues(alpha: 0.7),
                ),
                const SizedBox(width: 4),
                Text(
                  clock,
                  style: TextStyle(
                    fontSize: compact ? 11 : 12,
                    color: _kGold.withValues(alpha: 0.8),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (_strikeEnabled) ...[
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: nearStrike
                          ? _kGold.withValues(alpha: 0.2)
                          : Colors.black.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.bolt_rounded,
                          size: 13,
                          color: nearStrike ? _kGold : Colors.black45,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '$_currentPoints / ${_t.strikePoints}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: nearStrike ? _kGold : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            // Big score. In compact/landscape mode the counter sits between
            // the +/- buttons in one Row (instead of stacked above a
            // separate button row) so it shares the buttons' guaranteed
            // height — on short Android screens a number squeezed into its
            // own slot above the buttons could shrink to near-invisible;
            // between the buttons it always gets a real, visible size.
            // Mirrors King of the Court / Doghouse's identical fix.
            if (compact)
              Expanded(
                child: Row(
                  children: [
                    IconButton.filled(
                      icon: const Icon(Icons.remove),
                      tooltip: '−1',
                      onPressed: (_timerRunning && _currentPoints > 0)
                          ? _removePoint
                          : null,
                      style: IconButton.styleFrom(
                        backgroundColor: (_timerRunning && _currentPoints > 0)
                            ? _kGold
                            : Colors.grey.shade300,
                        foregroundColor: (_timerRunning && _currentPoints > 0)
                            ? Colors.white
                            : Colors.grey,
                        fixedSize: const Size(44, 44),
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: FittedBox(
                          fit: BoxFit.contain,
                          child: Text(
                            '$_currentPoints',
                            style: const TextStyle(
                              fontSize: 200,
                              fontWeight: FontWeight.bold,
                              height: 1,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ),
                    ),
                    IconButton.filled(
                      icon: const Icon(Icons.add),
                      tooltip: '+1',
                      onPressed: _timerRunning ? _addPoint : null,
                      style: IconButton.styleFrom(
                        backgroundColor:
                            _timerRunning ? _kGold : Colors.grey.shade300,
                        foregroundColor:
                            _timerRunning ? Colors.white : Colors.grey,
                        fixedSize: const Size(52, 52),
                      ),
                    ),
                  ],
                ),
              )
            else ...[
              Text(
                '$_currentPoints',
                style: const TextStyle(
                  fontSize: 96,
                  fontWeight: FontWeight.bold,
                  height: 1,
                  color: Colors.black87,
                ),
              ),
              // +/- buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton.filled(
                    icon: const Icon(Icons.remove),
                    tooltip: '−1',
                    onPressed: (_timerRunning && _currentPoints > 0)
                        ? _removePoint
                        : null,
                    style: IconButton.styleFrom(
                      backgroundColor: (_timerRunning && _currentPoints > 0)
                          ? _kGold
                          : Colors.grey.shade300,
                      foregroundColor: (_timerRunning && _currentPoints > 0)
                          ? Colors.white
                          : Colors.grey,
                      fixedSize: const Size(52, 52),
                    ),
                  ),
                  IconButton.filled(
                    icon: const Icon(Icons.add),
                    tooltip: '+1',
                    onPressed: _timerRunning ? _addPoint : null,
                    style: IconButton.styleFrom(
                      backgroundColor:
                          _timerRunning ? _kGold : Colors.grey.shade300,
                      foregroundColor:
                          _timerRunning ? Colors.white : Colors.grey,
                      fixedSize: const Size(64, 64),
                    ),
                  ),
                ],
              ),
            ],
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
            Text(
              l10n.scrambleKingEjectCourt,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11),
            ),
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
            Text(
              l10n.kotcUndoEject,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 10),
            ),
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
      label: Text(
        l10n.kotcUndoLastEjection,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
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
            Text(
              l10n.scrambleKingEjectChallenger,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11),
            ),
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
            Text(
              l10n.kotcUndoEjectChallenger,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  // ── Ready-state card (not yet started) ───────────────────────────────────

  Widget _buildStartCourtCard(AppLocalizations l10n) => Card(
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
          Row(
            children: [
              const Icon(
                Icons.sports_volleyball_rounded,
                size: 16,
                color: _kGold,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.scrambleKingReadyToStart,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: _kGold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _startCourt,
            icon: const Icon(Icons.play_arrow_rounded, size: 20),
            label: Text(
              l10n.scrambleKingStartCourt,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _kGold,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    ),
  );

  // ── Round-complete banner (replaces the live queue once finished) ────────

  Widget _buildRoundCompleteBanner(AppLocalizations l10n) => Material(
    color: _kOliveLight,
    borderRadius: BorderRadius.circular(16),
    child: InkWell(
      onTap: _showRanking,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _kOlive.withValues(alpha: 0.3), width: 2),
        ),
        child: Column(
          children: [
            const Icon(Icons.check_circle_rounded, size: 36, color: _kOlive),
            const SizedBox(height: 8),
            Text(
              l10n.scrambleKingCourtCompleteBanner,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: _kOlive,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.scrambleKingCourtCompleteHint,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: _kOlive.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    ),
  );

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
          child: Text(
            l10n.kotcWaitingForPlayers,
            style: const TextStyle(color: Colors.black45, fontSize: 13),
          ),
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
            Row(
              children: [
                const Icon(Icons.groups_rounded, size: 16, color: _kGold),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.scrambleKingPickStartingTeam,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: _kGold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            for (final slotId in _pool)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  onTap: () => _pickManualStart(slotId),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
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
                                Text(
                                  _teamNameForSlot(slotId)!,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: _kGold,
                                  ),
                                ),
                              Text(
                                _slotChipNames(slotId).join(' & '),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.black54,
                                ),
                              ),
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
            InfoChip(
              icon: Icons.groups_rounded,
              label: l10n.pageTeams,
              bg: _kOliveLight,
              fg: _kOlive,
              onTap: () => _showTeamsSheet(l10n),
              trailingIcon: Icons.unfold_more_rounded,
            ),
            _chip(
              Icons.repeat_rounded,
              l10n.scrambleKingRoundLabel(_round.roundNumber),
              Colors.grey.shade100,
              Colors.black45,
            ),
            _chip(
              Icons.stadium_rounded,
              l10n.scrambleKingCourtPageTitle(widget.courtNumber),
              Colors.grey.shade100,
              Colors.black45,
            ),
            _chip(Icons.emoji_events_rounded, _t.name, _kOliveLight, _kOlive),
            _chip(
              Icons.grid_view_rounded,
              '2v2',
              Colors.grey.shade100,
              Colors.black45,
            ),
            _chip(
              Icons.tune_rounded,
              _assignmentModeLabel(l10n),
              Colors.grey.shade100,
              Colors.black45,
            ),
            if (_formation.floaterSlot != null)
              _chip(
                Icons.swap_horiz_rounded,
                _oddPlayerModeLabel(l10n),
                Colors.grey.shade100,
                Colors.black45,
              ),
            if (_strikeEnabled)
              _chip(
                Icons.bolt_rounded,
                l10n.kotcStrikePoints(_t.strikePoints),
                AppColors.goldCream,
                _kGold,
              ),
          ],
        ),
        const Divider(height: 20),
        if (_formation.isCompleted)
          OutlinedButton.icon(
            onPressed: _undoFinishCourt,
            icon: const Icon(Icons.undo_rounded, size: 18),
            label: Text(
              l10n.scrambleKingUndoFinishCourt,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: _kGold,
              backgroundColor: Colors.white,
              side: BorderSide(color: _kGold.withValues(alpha: 0.6)),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          )
        else
          ElevatedButton.icon(
            onPressed: _confirmFinishCourt,
            icon: const Icon(Icons.emoji_events_rounded, size: 18),
            label: Text(
              l10n.scrambleKingFinishCourt,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _kOlive,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () => Navigator.of(context).pop(_t),
          icon: const Icon(Icons.arrow_back_rounded, size: 18),
          label: Text(
            l10n.scrambleKingBackToSchedule,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.black54,
            backgroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }

  // ── Shared small helpers (ported from KOTC) ──────────────────────────────

  Widget _teamCaption(String text, Color color, {bool compact = false}) => Padding(
    padding: EdgeInsets.only(bottom: compact ? 1 : 3),
    child: Text(
      text.toUpperCase(),
      textAlign: TextAlign.center,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: compact ? 9 : 10,
        fontWeight: FontWeight.w700,
        color: color,
        letterSpacing: 0.5,
      ),
    ),
  );

  Widget _nameChip(
    String name,
    Color fg, {
    required Color bg,
    Color? border,
    bool compact = false,
  }) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(20),
      border: border != null ? Border.all(color: border) : null,
    ),
    child: Text(
      name,
      style: TextStyle(
        fontSize: compact ? 11 : 13,
        fontWeight: FontWeight.w700,
        color: fg,
      ),
    ),
  );

  /// The partner token shown beside the floater's name — in every tile
  /// (Up Next, Challengers, **and** Court), never just some of them, so the
  /// role reads as a permanent fixture of the floater's team all round, the
  /// same way it does in placeholder mode. In placeholder mode it's always
  /// the generic "Placeholder" label — the app never names, assigns, or
  /// substitutes a specific person for that slot. In jumper mode it's
  /// "Jumper: {name}" once someone is assigned, else "Jumper · awaiting
  /// ejection"; [partnerId] is the caller's job to supply, since who that
  /// is depends on context — the still-waiting lock (`_floaterJumperPartnerId`)
  /// while queued, or the partner actually on court with them
  /// (`_onCourtTempPartnerId`) once playing. Styled as a lighter, icon-led
  /// chip so it reads as a slot filled by a role, not a fixed named player.
  Widget _floaterPartnerChip(
    AppLocalizations l10n,
    Color fg, {
    required Color bg,
    Color? border,
    bool compact = false,
    required String? partnerId,
  }) {
    final (
      IconData icon,
      String label,
    ) = _t.oddPlayerMode == ScrambleKingOddPlayerMode.placeholder
        ? (
            Icons.person_add_alt_1_rounded,
            l10n.scrambleKingOddPlayerPlaceholderLabel,
          )
        : partnerId != null
        ? (
            Icons.move_up_rounded,
            l10n.scrambleKingJumperPartner(_nameFor(partnerId)),
          )
        : (Icons.hourglass_empty_rounded, l10n.scrambleKingJumperAwaiting);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: (border ?? fg).withValues(alpha: 0.5),
          style: BorderStyle.solid,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: compact ? 12 : 14, color: fg.withValues(alpha: 0.8)),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: compact ? 11 : 13,
                fontWeight: FontWeight.w600,
                fontStyle: FontStyle.italic,
                color: fg.withValues(alpha: 0.85),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Upcoming courts ────────────────────────────────────────────────────────

  /// Every not-yet-finished court across all rounds, in round order, EXCEPT
  /// the one currently open on this scorecard. Sibling courts in the same
  /// round are included so the coach can hop between them. No cap — the list
  /// scrolls, and showing all outstanding courts is more useful than a subset.
  List<({ScrambleKingRound round, ScrambleKingCourtFormation formation})>
  _upcomingCourts() {
    final result =
        <({ScrambleKingRound round, ScrambleKingCourtFormation formation})>[];
    final sorted = _t.rounds.toList()
      ..sort((a, b) => a.roundNumber.compareTo(b.roundNumber));
    for (final round in sorted) {
      for (final court in round.courts) {
        if (court.isCompleted) continue;
        // Skip only the court currently open on this scorecard.
        if (round.id == _round.id && court.courtNumber == widget.courtNumber) {
          continue;
        }
        result.add((round: round, formation: court));
      }
    }
    return result;
  }

  /// Groups the flat [_upcomingCourts] list into contiguous per-round sections
  /// (the source is round-ordered, so a single pass suffices).
  List<({ScrambleKingRound round, List<ScrambleKingCourtFormation> courts})>
  _groupUpcomingByRound(
    List<({ScrambleKingRound round, ScrambleKingCourtFormation formation})>
    entries,
  ) {
    final groups =
        <
          ({ScrambleKingRound round, List<ScrambleKingCourtFormation> courts})
        >[];
    for (final e in entries) {
      if (groups.isNotEmpty && groups.last.round.id == e.round.id) {
        groups.last.courts.add(e.formation);
      } else {
        groups.add((round: e.round, courts: [e.formation]));
      }
    }
    return groups;
  }

  Widget _buildUpcomingCourts(AppLocalizations l10n) {
    // An imported court is a one-court mini tournament with no siblings to
    // jump to — keep the section visible but show a placeholder pointing back
    // to the host device, mirroring the Social Scramble scorecard.
    if (widget.isImported) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 24),
          _sectionHeader(l10n.scorecardUpcomingGames, Icons.event_note_rounded),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Text(
              l10n.scrambleKingImportedUpcomingHint,
              style: const TextStyle(fontSize: 13, color: Colors.black38),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      );
    }
    final upcoming = _upcomingCourts();
    if (upcoming.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 24),
        _sectionHeader(l10n.scorecardUpcomingGames, Icons.event_note_rounded),
        const SizedBox(height: 10),
        for (final group in _groupUpcomingByRound(upcoming)) ...[
          Padding(
            padding: const EdgeInsets.only(top: 2, bottom: 4),
            child: Row(
              children: [
                Text(
                  l10n.scrambleKingRoundLabel(group.round.roundNumber),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.black54,
                  ),
                ),
                if (group.round.courts.length > 1) ...[
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.call_split_rounded,
                    size: 11,
                    color: Colors.black38,
                  ),
                  const SizedBox(width: 3),
                  // Count all courts in the round (incl. the current one and any
                  // already finished), not just those listed below.
                  Text(
                    l10n.scorecardParallelCourts(group.round.courts.length),
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.black38,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Reuse the exact overview court card — player names emphasized,
          // team name below — so an upcoming court reads identically here.
          for (final court in group.courts)
            ScrambleKingCourtResultTile(
              tournament: _t,
              round: group.round,
              formation: court,
              onTap: () => _openUpcomingCourt(group.round, court),
            ),
        ],
      ],
    );
  }

  void _openUpcomingCourt(
    ScrambleKingRound round,
    ScrambleKingCourtFormation formation,
  ) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => ScrambleKingCourtPage(
          tournament: _t,
          roundId: round.id,
          courtNumber: formation.courtNumber,
          onChanged: widget.onChanged,
        ),
      ),
    );
  }

  Widget _sectionHeader(String title, IconData icon) => Row(
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
    ],
  );

  Widget _chip(IconData icon, String label, Color bg, Color fg) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 11, color: fg),
        const SizedBox(width: 3),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: fg,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );

  Widget _refBtn(
    IconData icon,
    String label,
    VoidCallback onTap, {
    bool primary = false,
  }) => OutlinedButton.icon(
    onPressed: onTap,
    icon: Icon(icon, size: 14),
    label: Text(label, style: const TextStyle(fontSize: 12)),
    style: OutlinedButton.styleFrom(
      foregroundColor: primary ? Colors.white : _kOlive,
      backgroundColor: primary ? _kOlive : null,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      side: BorderSide(color: primary ? _kOlive : Colors.grey.shade300),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      minimumSize: const Size(0, 30),
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
      minimumSize: const Size(0, 30),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    ),
    child: Text(label, style: const TextStyle(fontSize: 12)),
  );

  String _fmtClock(Duration d) =>
      '${d.inMinutes.toString().padLeft(2, '0')}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';

  String _fmtTime(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}
