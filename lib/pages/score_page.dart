/// Score Page — primary live scoring interface for TournaQ.
///
/// Responsibilities:
///   - Display current match state (score, set progression, active server)
///   - Handle point scoring with full undo support
///   - Manage service rotation across up to 4 player positions
///   - Enforce side-change reminders at configurable score thresholds
///   - Allow team-side swap (display-only, does not affect stored team order)
///   - Support set completion and match completion workflows
///   - Show gameplay history ([GameplayHistoryPage])
///   - Allow in-game player name editing ([GameTeamLineup])
///
/// Intentionally does NOT:
///   - Persist state directly — calls [AppDataService] which returns a new
///     [AppState]; the caller ([LandingPage], [GamesPage]) persists via
///     [LocalStorageService].
///   - Implement tournament bracket logic — that lives in
///     [TournamentLogicService].
///   - Know about clubs, user accounts, or Firebase.
///
/// State management:
///   [_ScoreEvent] records each point for undo. The undo stack replays events
///   in reverse to restore exact pre-point state including service position.
///
/// Display vs. stored team order:
///   [_isSwapped] flips the visual left/right assignment of team1/team2
///   without touching the underlying [Game] object. This means stored results
///   always reference team1Id/team2Id regardless of how the user oriented the
///   screen.
///
/// Side-change logic:
///   A blocking dialog ([_showSideChangeDialog]) is presented when the total
///   score crosses a [_sideChangeThreshold]. The swap itself is applied only
///   after the user confirms, making it impossible to accidentally skip it.
///
/// Future:
///   - Extract scoring control widgets into lib/features/scoring/widgets/
///   - Landscape vs. portrait layouts could be separate widget classes
///   - Live scoring sync (Firebase Realtime Database) can be layered in via
///     a stream subscription without changing the local scoring logic
library;

import 'package:flutter/material.dart';
import '../app/app_colors.dart';
import '../l10n/app_localizations.dart';
import '../models/game.dart';
import '../models/game_set.dart';
import 'gameplay_history_page.dart';
import '../models/game_team_lineup.dart';
import '../services/app_data_service.dart';
import '../services/local_storage_service.dart';
import '../state/app_state.dart';
import '../widgets/app_drawer.dart';
import '../widgets/tournaq_app_bar.dart';
import '../widgets/scrollable_page.dart';
import '../widgets/sheet_helpers.dart';

// File-local color constants — mirror values from AppColors.
// These are kept local to avoid importing app/ in a frequently-rebuilt widget.
const _kGold = AppColors.goldDark;
const _kGoldLight = AppColors.goldCream;
const _kOlive = AppColors.olive;
const _kOliveLight = AppColors.oliveLight;

// Score card team backgrounds — always shown, stronger when leading
const _kGoldCardBg = AppColors.goldCardBg;
const _kGoldCardLeading = AppColors.goldCardLeading;
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

class ScorePage extends StatefulWidget {
  final AppState appState;
  final Function(AppState) onAppStateChanged;
  final String gameId;
  // When provided, called instead of Navigator.pop() by "Save & Return to Games".
  // Use this when the caller's navigation stack doesn't have GamesPage underneath.
  final VoidCallback? onSaveAndReturn;

  const ScorePage({
    super.key,
    required this.appState,
    required this.onAppStateChanged,
    required this.gameId,
    this.onSaveAndReturn,
  });

  @override
  State<ScorePage> createState() => _ScorePageState();
}

class _ScorePageState extends State<ScorePage> {
  late AppState _localState;
  late Game _game;

  // Always stored relative to game.team1Id / game.team2Id, never swapped.
  late int _score1;
  late int _score2;
  late int _targetPoints;

  // Display orientation — flips left/right without touching stored scores.
  bool _isSwapped = false;

  // Active player cycle: 0=team1P1, 1=team2P1, 2=team1P2, 3=team2P2
  int _activePlayerIndex = 0;

  // Service-change undo stack — cleared on set switch.
  final List<_ScoreEvent> _scoreEvents = [];

  // ── Display helpers ───────────────────────────────────────────────────────

  String get _leftTeamId => _isSwapped ? _game.team2Id : _game.team1Id;
  String get _rightTeamId => _isSwapped ? _game.team1Id : _game.team2Id;
  int get _leftScore => _isSwapped ? _score2 : _score1;
  int get _rightScore => _isSwapped ? _score1 : _score2;
  bool get _isTeam1Leading => _score1 > _score2;
  bool get _isTeam2Leading => _score2 > _score1;
  bool get _isLeftLeading => _isSwapped ? _isTeam2Leading : _isTeam1Leading;
  bool get _isRightLeading => _isSwapped ? _isTeam1Leading : _isTeam2Leading;
  bool get _isActiveSetCompleted => _game.currentSet?.isCompleted ?? false;
  bool get _isGameComplete => _game.isMatchComplete;
  bool get _isTeam1Serving => _activePlayerIndex % 2 == 0;

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _localState = widget.appState;
    _game = _localState.getGameById(widget.gameId)!;
    _loadActiveSetScores();
  }

  void _loadActiveSetScores() {
    _score1 = _game.currentSet?.score1 ?? _game.result?.score1 ?? 0;
    _score2 = _game.currentSet?.score2 ?? _game.result?.score2 ?? 0;
    _targetPoints = _game.currentSet?.targetPoints ?? _game.result?.targetPoints ?? 15;
    // _scoreEvents is intentionally NOT cleared here so that history
    // accumulates across set switches for the full-match history view.
  }

  // ── State mutations ───────────────────────────────────────────────────────

  void _updateState(AppState newState) {
    setState(() {
      _localState = newState;
      _game = _localState.getGameById(widget.gameId)!;
    });
    widget.onAppStateChanged(newState);
  }

  void _applyDelta({required bool isLeft, required int delta}) {
    if (_isSwapped) {
      if (isLeft) {
        _score2 = (_score2 + delta).clamp(0, 999);
      } else {
        _score1 = (_score1 + delta).clamp(0, 999);
      }
    } else {
      if (isLeft) {
        _score1 = (_score1 + delta).clamp(0, 999);
      } else {
        _score2 = (_score2 + delta).clamp(0, 999);
      }
    }
  }

  void _addScore({required bool isLeft}) {
    final prevService = _activePlayerIndex;
    final scoringIsTeam1 = isLeft ? !_isSwapped : _isSwapped;
    final changedService = scoringIsTeam1 != _isTeam1Serving;
    setState(() {
      _applyDelta(isLeft: isLeft, delta: 1);
      if (changedService) _activePlayerIndex = (_activePlayerIndex + 1) % 4;
      _scoreEvents.add(_ScoreEvent(
        isTeam1Score: scoringIsTeam1,
        setIndex: _game.currentSetIndex,
        prevService: prevService,
        changedService: changedService,
      ));
    });
    if (_shouldShowSideChangeReminder()) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showSideChangeDialog();
      });
    }
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
        title: Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(color: _kGoldLight, borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.swap_horiz_rounded, color: _kGold, size: 20),
            ),
            const SizedBox(width: 12),
            Text(l10n.sideChangeTitle, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          ],
        ),
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
              child: Text(l10n.sideChangeContinue, style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
    if (mounted) setState(() => _isSwapped = !_isSwapped);
  }

  void _removeScore({required bool isLeft}) {
    // Resolve which team the pressed side currently belongs to.
    final removeTeam1 = isLeft ? !_isSwapped : _isSwapped;
    int eventIndex = -1;
    for (int i = _scoreEvents.length - 1; i >= 0; i--) {
      if (_scoreEvents[i].isTeam1Score == removeTeam1 &&
          _scoreEvents[i].setIndex == _game.currentSetIndex) {
        eventIndex = i;
        break;
      }
    }
    setState(() {
      _applyDelta(isLeft: isLeft, delta: -1);
      if (eventIndex >= 0) {
        final event = _scoreEvents[eventIndex];
        if (event.changedService) _activePlayerIndex = event.prevService;
        _scoreEvents.removeAt(eventIndex);
      }
    });
  }

  void _swap() => setState(() => _isSwapped = !_isSwapped);

  void _rotateActivePlayer() =>
      setState(() => _activePlayerIndex = (_activePlayerIndex + 1) % 4);

  void _switchToSet(int setIndex) {
    if (setIndex == _game.currentSetIndex) return;

    // Auto-save unsaved live scores before switching sets.
    var currentState = _localState;
    if (!_isActiveSetCompleted && (_score1 > 0 || _score2 > 0)) {
      final s1 = _isSwapped ? _score2 : _score1;
      final s2 = _isSwapped ? _score1 : _score2;
      currentState = AppDataService.updateCurrentSetScore(
        currentState,
        gameId: _game.id,
        score1: s1,
        score2: s2,
      );
    }

    final newState = AppDataService.setActiveSet(currentState, _game.id, setIndex);
    setState(() {
      _localState = newState;
      _game = newState.getGameById(widget.gameId)!;
      _loadActiveSetScores();
      _activePlayerIndex = 0;
    });
    widget.onAppStateChanged(newState);
  }

  void _toggleCompleteSet() {
    if (_isActiveSetCompleted) {
      final newState = AppDataService.undoSetCompletion(
        _localState,
        gameId: _game.id,
        setIndex: _game.currentSetIndex,
      );
      setState(() {
        _localState = newState;
        _game = newState.getGameById(widget.gameId)!;
        _loadActiveSetScores();
      });
      widget.onAppStateChanged(newState);
    } else {
      final s1 = _isSwapped ? _score2 : _score1;
      final s2 = _isSwapped ? _score1 : _score2;
      final newState = AppDataService.completeSet(
        _localState,
        gameId: _game.id,
        setIndex: _game.currentSetIndex,
        score1: s1,
        score2: s2,
        targetPoints: _targetPoints,
      );
      setState(() {
        _localState = newState;
        _game = newState.getGameById(widget.gameId)!;
        _score1 = _game.currentSet?.score1 ?? _score1;
        _score2 = _game.currentSet?.score2 ?? _score2;
      });
      widget.onAppStateChanged(newState);
    }
  }

  void _doCompleteGame() {
    var currentState = _localState;
    final s1 = _isSwapped ? _score2 : _score1;
    final s2 = _isSwapped ? _score1 : _score2;

    if (_game.matchFormat == MatchFormat.oneSet && !_isActiveSetCompleted) {
      currentState = AppDataService.completeSet(
        currentState,
        gameId: _game.id,
        setIndex: _game.currentSetIndex,
        score1: s1,
        score2: s2,
        targetPoints: _targetPoints,
      );
    }

    final newState = AppDataService.completeGame(currentState, _game.id);
    setState(() {
      _localState = newState;
      _game = newState.getGameById(widget.gameId)!;
      _score1 = _game.currentSet?.score1 ?? _score1;
      _score2 = _game.currentSet?.score2 ?? _score2;
    });
    // Persist the completed game immediately before the full saveAppState runs.
    // This prevents data loss if the app is restarted between saveAppState's
    // clear() and the subsequent put() calls.
    LocalStorageService.saveGame(_game);
    widget.onAppStateChanged(newState);
  }

  void _undoGameCompletion() {
    final newState = AppDataService.undoGameCompletion(_localState, _game.id);
    setState(() {
      _localState = newState;
      _game = newState.getGameById(widget.gameId)!;
      _loadActiveSetScores();
    });
    LocalStorageService.saveGame(_game);
    widget.onAppStateChanged(newState);
  }

  bool _shouldShowSideChangeReminder() {
    if (_isActiveSetCompleted) return false;
    final total = _score1 + _score2;
    if (total == 0) return false;
    if (_targetPoints == 15) return total % 5 == 0;
    if (_targetPoints == 21) return total % 7 == 0;
    return false;
  }

  // ── Player lineup helpers ─────────────────────────────────────────────────

  List<String> _getPlayerNames(String teamId) {
    final lineup = _game.lineups.firstWhere(
      (l) => l.teamId == teamId,
      orElse: () => GameTeamLineup(teamId: teamId),
    );
    final teamUsers = _localState.getUsersForTeam(teamId);
    final teamName = _localState.getTeamById(teamId)?.name ?? 'Team';

    String nameAt(int index) {
      if (index < lineup.playerNames.length && lineup.playerNames[index].isNotEmpty) {
        return lineup.playerNames[index];
      }
      if (index < teamUsers.length) return teamUsers[index].name;
      return 'Player ${index + 1} $teamName';
    }

    return [nameAt(0), nameAt(1)];
  }

  bool _isPlayerActive(String teamId, int playerIndex) =>
      switch (_activePlayerIndex) {
        0 => teamId == _game.team1Id && playerIndex == 0,
        1 => teamId == _game.team2Id && playerIndex == 0,
        2 => teamId == _game.team1Id && playerIndex == 1,
        3 => teamId == _game.team2Id && playerIndex == 1,
        _ => false,
      };

  Future<void> _showLineupEditor(String teamId, String teamName) async {
    final current = _game.lineups.firstWhere(
      (l) => l.teamId == teamId,
      orElse: () => GameTeamLineup(teamId: teamId),
    );
    final assigned = _localState.getUsersForTeam(teamId);

    final initialP1 =
        current.playerNames.isNotEmpty && current.playerNames[0].isNotEmpty
            ? current.playerNames[0]
            : (assigned.isNotEmpty ? assigned[0].name : '');
    final initialP2 =
        current.playerNames.length > 1 && current.playerNames[1].isNotEmpty
            ? current.playerNames[1]
            : (assigned.length > 1 ? assigned[1].name : '');

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _LineupEditorSheet(
        teamName: teamName,
        initialP1: initialP1,
        initialP2: initialP2,
        onSave: (p1, p2) {
          var ns = AppDataService.updateTeamPlayers(
            _localState,
            teamId: teamId,
            player1Name: p1,
            player2Name: p2,
          );
          final lineup = GameTeamLineup(teamId: teamId, playerNames: [p1, p2]);
          ns = AppDataService.updateGameLineup(ns, _game.id, lineup);
          _updateState(ns);
        },
      ),
    );
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

      final target = event.setIndex == _game.currentSetIndex
          ? _targetPoints
          : (event.setIndex < _game.sets.length
              ? _game.sets[event.setIndex].targetPoints
              : _targetPoints);

      entries.add(GameHistoryEntry(
        isTeam1Score: event.isTeam1Score,
        team1Score: scores[0],
        team2Score: scores[1],
        setIndex: event.setIndex,
        targetPoints: target,
        isTeam1Serving: event.prevService % 2 == 0,
        servingPlayerIndex: event.prevService ~/ 2,
        serviceChanged: event.changedService,
      ));
    }

    return entries;
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  void _showGameOptions(BuildContext context) {
    final scoreLocked = _isGameComplete || _isActiveSetCompleted;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetCtx) {
        void openHistory() {
          Navigator.of(sheetCtx).pop();
          final team1Name = _localState.getTeamById(_game.team1Id)?.name ?? 'Team 1';
          final team2Name = _localState.getTeamById(_game.team2Id)?.name ?? 'Team 2';
          Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => GameplayHistoryPage(
              team1Name: team1Name,
              team2Name: team2Name,
              team1Players: _getPlayerNames(_game.team1Id),
              team2Players: _getPlayerNames(_game.team2Id),
              entries: _buildHistoryEntries(),
            ),
          ));
        }

        return OrientationBuilder(
          builder: (_, orientation) {
            final isLandscape = orientation == Orientation.landscape;
            return TournaQSheet(
              body: isLandscape
                  ? _buildGameOptionsLandscape(sheetCtx, scoreLocked, openHistory)
                  : _buildGameOptionsPortrait(sheetCtx, scoreLocked, openHistory),
            );
          },
        );
      },
    );
  }

  Widget _buildGameOptionsPortrait(BuildContext sheetCtx, bool scoreLocked, VoidCallback openHistory) {
    final l10n = AppLocalizations.of(context)!;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(l10n.gameOptions, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        _gameOptionTile(
          sheetCtx,
          icon: Icons.swap_horiz,
          iconBg: scoreLocked ? Colors.grey.shade100 : AppColors.goldCream,
          iconColor: scoreLocked ? Colors.grey : _kGold,
          label: l10n.swapTeams,
          subtitle: l10n.swapTeamsSubtitle,
          enabled: !scoreLocked,
          onTap: () { Navigator.of(sheetCtx).pop(); _swap(); },
        ),
        _gameOptionTile(
          sheetCtx,
          icon: Icons.rotate_right_rounded,
          iconBg: _kOliveLight,
          iconColor: _kOlive,
          label: l10n.changeService,
          subtitle: l10n.changeServiceSubtitle,
          enabled: true,
          onTap: () { Navigator.of(sheetCtx).pop(); _rotateActivePlayer(); },
        ),
        _gameOptionTile(
          sheetCtx,
          icon: Icons.history_rounded,
          iconBg: _kGoldLight,
          iconColor: _kGold,
          label: l10n.pageGameplayHistory,
          subtitle: l10n.gameplayHistorySubtitle,
          enabled: true,
          onTap: openHistory,
        ),
      ]),
    );
  }

  Widget _buildGameOptionsLandscape(BuildContext sheetCtx, bool scoreLocked, VoidCallback openHistory) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(l10n.gameOptions, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: _gameOptionCompact(
            icon: Icons.swap_horiz,
            iconBg: scoreLocked ? Colors.grey.shade100 : AppColors.goldCream,
            iconColor: scoreLocked ? Colors.grey : _kGold,
            label: l10n.swapTeams,
            enabled: !scoreLocked,
            onTap: () { Navigator.of(sheetCtx).pop(); _swap(); },
          )),
          const SizedBox(width: 10),
          Expanded(child: _gameOptionCompact(
            icon: Icons.rotate_right_rounded,
            iconBg: _kOliveLight,
            iconColor: _kOlive,
            label: l10n.changeService,
            enabled: true,
            onTap: () { Navigator.of(sheetCtx).pop(); _rotateActivePlayer(); },
          )),
          const SizedBox(width: 10),
          Expanded(child: _gameOptionCompact(
            icon: Icons.history_rounded,
            iconBg: _kGoldLight,
            iconColor: _kGold,
            label: l10n.historyShort,
            enabled: true,
            onTap: openHistory,
          )),
        ]),
      ]),
    );
  }

  Widget _gameOptionTile(
    BuildContext sheetCtx, {
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String label,
    required String subtitle,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      leading: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(label, style: TextStyle(fontWeight: FontWeight.w600, color: enabled ? Colors.black87 : Colors.grey)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.black45)),
      onTap: enabled ? onTap : null,
    );
  }

  Widget _gameOptionCompact({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String label,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade200),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(color: enabled ? iconBg : Colors.grey.shade100, shape: BoxShape.circle),
            child: Icon(icon, color: enabled ? iconColor : Colors.grey, size: 20),
          ),
          const SizedBox(height: 6),
          Text(label, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: enabled ? Colors.black87 : Colors.grey), textAlign: TextAlign.center),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final team1Name = _localState.getTeamById(_game.team1Id)?.name ?? 'Team 1';
    final team2Name = _localState.getTeamById(_game.team2Id)?.name ?? 'Team 2';
    final leftTeamId = _leftTeamId;
    final rightTeamId = _rightTeamId;
    final leftName = _localState.getTeamById(leftTeamId)?.name ?? 'Team 1';
    final rightName = _localState.getTeamById(rightTeamId)?.name ?? 'Team 2';
    final scoreLocked = _isGameComplete || _isActiveSetCompleted;

    return Scaffold(
      drawer: AppDrawer(appState: _localState, onAppStateChanged: _updateState),
      appBar: TournaQAppBar(title: AppLocalizations.of(context)!.pageGameScorecard),
      body: OrientationBuilder(
        builder: (context, orientation) {
          final isLandscape = orientation == Orientation.landscape;

          final optionsButton = IconButton(
            icon: const Icon(Icons.tune_rounded, size: 20, color: _kOlive),
            tooltip: 'Game Options',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            visualDensity: VisualDensity.compact,
            onPressed: () => _showGameOptions(context),
          );

          // ── Landscape: fills available height, no scroll ────────────
          if (isLandscape) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(child: _buildSetOverview()),
                        const SizedBox(width: 8),
                        optionsButton,
                      ],
                    ),
                    if (_isGameComplete)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: _buildLockBanner(
                          AppLocalizations.of(context)!.lockBannerGame,
                          winnerName: _game.effectiveWinnerTeamId != null
                              ? _localState.getTeamById(_game.effectiveWinnerTeamId!)?.name
                              : null,
                          winnerColor: _game.effectiveWinnerTeamId == _game.team1Id ? _kGold : _kOlive,
                        ),
                      )
                    else if (_isActiveSetCompleted)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: _buildLockBanner(AppLocalizations.of(context)!.lockBannerSet),
                      ),
                    const SizedBox(height: 4),
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: _buildScoreCard(
                              teamId: leftTeamId,
                              teamName: leftName,
                              score: _leftScore,
                              isLeading: _isLeftLeading,
                              onIncrement: scoreLocked ? null : () => _addScore(isLeft: true),
                              onDecrement: scoreLocked ? null : () => _removeScore(isLeft: true),
                              landscape: true,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildScoreCard(
                              teamId: rightTeamId,
                              teamName: rightName,
                              score: _rightScore,
                              isLeading: _isRightLeading,
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
              ),
            );
          }

          // ── Portrait: full layout ───────────────────────────────────
          final portraitScoreCards = Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildScoreCard(
                  teamId: leftTeamId,
                  teamName: leftName,
                  score: _leftScore,
                  isLeading: _isLeftLeading,
                  onIncrement: scoreLocked ? null : () => _addScore(isLeft: true),
                  onDecrement: scoreLocked ? null : () => _removeScore(isLeft: true),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildScoreCard(
                  teamId: rightTeamId,
                  teamName: rightName,
                  score: _rightScore,
                  isLeading: _isRightLeading,
                  onIncrement: scoreLocked ? null : () => _addScore(isLeft: false),
                  onDecrement: scoreLocked ? null : () => _removeScore(isLeft: false),
                ),
              ),
            ],
          );

          return ScrollablePage(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Text(
                    '$team1Name vs $team2Name',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 8),
                _buildSectionHeader(
                  AppLocalizations.of(context)!.sectionGameplayControls,
                  Icons.sports_volleyball_rounded,
                  trailing: optionsButton,
                ),
                const SizedBox(height: 10),
                _buildSetOverview(),
                const SizedBox(height: 12),
                if (_isGameComplete)
                  _buildLockBanner(
                    AppLocalizations.of(context)!.lockBannerGame,
                    winnerName: _game.effectiveWinnerTeamId != null
                        ? _localState.getTeamById(_game.effectiveWinnerTeamId!)?.name
                        : null,
                    winnerColor: _game.effectiveWinnerTeamId == _game.team1Id ? _kGold : _kOlive,
                  )
                else if (_isActiveSetCompleted)
                  _buildLockBanner(AppLocalizations.of(context)!.lockBannerSet),
                portraitScoreCards,
                const SizedBox(height: 24),
                _buildSectionHeader(AppLocalizations.of(context)!.sectionMatchActions, Icons.emoji_events_rounded),
                const SizedBox(height: 8),
                _buildMatchActions(),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── Sections ──────────────────────────────────────────────────────────────

  Widget _buildSetOverview() {
    final maxSets = _game.maxSets;
    return Row(
      children: List.generate(maxSets, (i) {
        final exists = i < _game.sets.length;
        final set = exists ? _game.sets[i] : null;
        final isActive = i == _game.currentSetIndex;
        final isCompleted = set?.isCompleted ?? false;

        // Active non-completed set shows local unsaved scores.
        final displayScore1 = isActive && !isCompleted ? _score1 : (set?.score1 ?? 0);
        final displayScore2 = isActive && !isCompleted ? _score2 : (set?.score2 ?? 0);
        final displayTarget = isActive ? _targetPoints : set?.targetPoints;

        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: i < maxSets - 1 ? 6 : 0),
            child: GestureDetector(
              onTap: () => _switchToSet(i),
              child: _buildSetCard(
                setIndex: i,
                set: set,
                isActive: isActive,
                isCompleted: isCompleted,
                displayScore1: displayScore1,
                displayScore2: displayScore2,
                displayTarget: displayTarget,
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildSetCard({
    required int setIndex,
    required GameSet? set,
    required bool isActive,
    required bool isCompleted,
    required int displayScore1,
    required int displayScore2,
    int? displayTarget,
  }) {
    final Color borderColor;
    final Color bgColor;

    if (isActive) {
      borderColor = _kGold;
      bgColor = _kGoldLight;
    } else if (isCompleted) {
      borderColor = _kOlive;
      bgColor = _kOliveLight;
    } else {
      borderColor = Colors.grey.shade300;
      bgColor = Colors.grey.shade100;
    }

    String? winnerShort;
    if (isCompleted && set?.winnerTeamId != null) {
      final name = _localState.getTeamById(set!.winnerTeamId!)?.name ?? '';
      winnerShort = '${name.length > 7 ? '${name.substring(0, 7)}…' : name} ✓';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor, width: isActive ? 2 : 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${isCompleted ? '● ' : ''}Set ${setIndex + 1}${displayTarget != null ? ' · $displayTarget' : ''}',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isCompleted
                  ? AppColors.inverseSurface
                  : isActive
                      ? _kGold
                      : Colors.grey,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            set == null ? '–' : '$displayScore1–$displayScore2',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: isActive ? _kGold : isCompleted ? _kOlive : Colors.grey.shade400,
            ),
          ),
          if (winnerShort != null) ...[
            const SizedBox(height: 2),
            Text(
              winnerShort,
              style: const TextStyle(fontSize: 9, color: _kOlive),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTargetPoints({bool locked = false}) {
    final l10n = AppLocalizations.of(context)!;
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      runSpacing: 6,
      children: [
        Text(
          l10n.targetScore,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        for (final v in [11, 15, 21])
          ChoiceChip(
            label: Text('$v'),
            selected: _targetPoints == v,
            onSelected: locked ? null : (_) => setState(() => _targetPoints = v),
            selectedColor: _kGoldLight,
            labelStyle: TextStyle(
              fontWeight: FontWeight.w600,
              color: _targetPoints == v ? _kGold : null,
            ),
          ),
      ],
    );
  }

  Widget _buildLockBanner(String message, {String? winnerName, Color winnerColor = _kOlive}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.lock_rounded, size: 16, color: Colors.black54),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.black54,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (winnerName != null) ...[
            const SizedBox(width: 8),
            Text(
              AppLocalizations.of(context)!.gameTileWinner(winnerName),
              style: TextStyle(
                fontSize: 12,
                color: winnerColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildScoreCard({
    required String teamId,
    required String teamName,
    required int score,
    required bool isLeading,
    required VoidCallback? onIncrement,
    required VoidCallback? onDecrement,
    bool compact = false,
    bool fillHeight = false,
    bool landscape = false,
  }) {
    final isTeam1 = teamId == _game.team1Id;
    final teamColor = isTeam1 ? _kGold : _kOlive;
    final cardBg = isTeam1
        ? (isLeading ? _kGoldCardLeading : _kGoldCardBg)
        : (isLeading ? _kOliveCardLeading : _kOliveCardBg);
    final disabled = onIncrement == null;
    final players = _getPlayerNames(teamId);

    EdgeInsets cardPadding;
    if (landscape) {
      cardPadding = const EdgeInsets.fromLTRB(12, 10, 12, 10);
    } else if (compact) {
      cardPadding = const EdgeInsets.fromLTRB(8, 4, 8, 4);
    } else {
      cardPadding = const EdgeInsets.fromLTRB(10, 12, 10, 10);
    }

    final teamNameWidget = GestureDetector(
      onTap: disabled ? null : () => _showLineupEditor(teamId, teamName),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              teamName,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: landscape ? 16 : compact ? 12 : 13,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          if (!disabled) ...[
            const SizedBox(width: 3),
            Icon(Icons.edit_rounded, size: landscape ? 12 : 11, color: Colors.black54),
          ],
        ],
      ),
    );

    final targetWidget = Text(
      '/ $_targetPoints',
      style: TextStyle(
        fontSize: 11,
        color: teamColor,
        fontWeight: FontWeight.w600,
      ),
    );

    final buttonsRow = Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        IconButton.filled(
          icon: const Icon(Icons.remove),
          onPressed: onDecrement,
          tooltip: 'Decrease',
          iconSize: compact ? 18 : 24,
          style: IconButton.styleFrom(
            backgroundColor: disabled ? Colors.grey.shade300 : teamColor,
            foregroundColor: disabled ? Colors.grey : Colors.white,
            fixedSize: compact ? const Size(40, 22) : null,
            tapTargetSize: compact ? MaterialTapTargetSize.shrinkWrap : null,
          ),
        ),
        IconButton.filled(
          icon: const Icon(Icons.add),
          onPressed: onIncrement,
          tooltip: 'Increase',
          iconSize: compact ? 18 : 24,
          style: IconButton.styleFrom(
            backgroundColor: disabled ? Colors.grey.shade300 : teamColor,
            foregroundColor: disabled ? Colors.grey : Colors.white,
            fixedSize: compact ? const Size(40, 22) : null,
            tapTargetSize: compact ? MaterialTapTargetSize.shrinkWrap : null,
          ),
        ),
      ],
    );

    final chipsRow = Row(
      children: [
        Expanded(child: _buildPlayerChip(teamId, players[0], 0, compact: compact || landscape)),
        const SizedBox(width: 4),
        Expanded(child: _buildPlayerChip(teamId, players[1], 1, compact: compact || landscape)),
      ],
    );

    Widget cardContent;
    if (landscape) {
      // Landscape: all mandatory element heights scale proportionally with h so
      // they can NEVER sum to more than h, regardless of how small h becomes
      // (e.g. h=57.5 when the soft keyboard is open behind the player editor).
      //
      // Proportions: name 28% + buttons 47% + spacer 3% = 78% of h (≤ h).
      // The remaining 22% goes to the optional score FittedBox.
      // Optional elements (target label, player chips) are only shown when the
      // leftover budget after mandatory + score accommodates them.
      cardContent = LayoutBuilder(
        builder: (context, constraints) {
          final h = constraints.maxHeight;

          // Mandatory heights — proportional, clamped to sensible maxima.
          final nameH   = (h * 0.28).clamp(0.0, 21.0);
          final btnH    = (h * 0.47).clamp(0.0, 48.0);
          final spacerH = (h * 0.03).clamp(0.0,  2.0);
          // Icon scales with button, never below 12 px.
          final iconSize = (btnH * 0.55).clamp(12.0, 24.0);

          const kTargetH = 15.0;
          const kChipH   = 18.0;

          // Budget remaining for optional + score elements.
          var remaining = h - nameH - btnH - spacerH;

          final showTarget = remaining >= kTargetH + kChipH + 4;
          if (showTarget) remaining -= kTargetH;

          final showChips = remaining >= kChipH + 2;
          if (showChips) remaining -= kChipH;

          // Score takes all remaining space (always ≥ 0 by construction).
          final scoreH = remaining.clamp(0.0, double.infinity);

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: nameH, child: teamNameWidget),
              if (showTarget) SizedBox(height: kTargetH, child: targetWidget),
              if (scoreH > 0)
                SizedBox(
                  height: scoreH,
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
              SizedBox(
                height: btnH,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton.filled(
                      icon: const Icon(Icons.remove),
                      onPressed: onDecrement,
                      tooltip: 'Decrease',
                      iconSize: iconSize,
                      style: IconButton.styleFrom(
                        backgroundColor: disabled ? Colors.grey.shade300 : teamColor,
                        foregroundColor: disabled ? Colors.grey : Colors.white,
                        fixedSize: Size(btnH, btnH),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                    IconButton.filled(
                      icon: const Icon(Icons.add),
                      onPressed: onIncrement,
                      tooltip: 'Increase',
                      iconSize: iconSize,
                      style: IconButton.styleFrom(
                        backgroundColor: disabled ? Colors.grey.shade300 : teamColor,
                        foregroundColor: disabled ? Colors.grey : Colors.white,
                        fixedSize: Size(btnH, btnH),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: spacerH),
              if (showChips) SizedBox(height: kChipH, child: chipsRow),
            ],
          );
        },
      );
    } else {
      cardContent = Column(
        mainAxisSize: fillHeight ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          teamNameWidget,
          if (!compact) targetWidget,
          Text(
            '$score',
            style: TextStyle(
              fontSize: compact ? 22 : 56,
              fontWeight: FontWeight.bold,
              height: 1.0,
              color: disabled ? Colors.black38 : Colors.black87,
            ),
          ),
          buttonsRow,
          SizedBox(height: compact ? 2 : 4),
          chipsRow,
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
        padding: cardPadding,
        child: cardContent,
      ),
    );
  }

  Widget _buildPlayerChip(String teamId, String name, int index, {bool compact = false}) {
    final active = _isPlayerActive(teamId, index);
    final isTeam1 = teamId == _game.team1Id;
    final activeColor = isTeam1 ? _kGold : _kOlive;
    return Container(
      padding: compact
          ? const EdgeInsets.symmetric(horizontal: 4, vertical: 2)
          : const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
      decoration: BoxDecoration(
        color: active ? activeColor : Colors.black12,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: active ? activeColor : Colors.black26,
        ),
      ),
      child: Text(
        name,
        style: TextStyle(
          fontSize: 10,
          fontWeight: active ? FontWeight.w700 : FontWeight.w400,
          color: active ? Colors.white : Colors.black54,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
      ),
    );
  }


  void _saveAndBack() {
    if (!_isActiveSetCompleted && (_score1 > 0 || _score2 > 0)) {
      final s1 = _isSwapped ? _score2 : _score1;
      final s2 = _isSwapped ? _score1 : _score2;
      final newState = AppDataService.updateCurrentSetScore(
        _localState,
        gameId: _game.id,
        score1: s1,
        score2: s2,
      );
      widget.onAppStateChanged(newState);
    }
    if (!mounted) return;
    if (widget.onSaveAndReturn != null) {
      widget.onSaveAndReturn!();
    } else {
      Navigator.of(context).pop();
    }
  }

  Widget _buildSectionHeader(String title, IconData icon, {Widget? trailing}) {
    return Row(
      children: [
        Icon(icon, size: 15, color: _kOlive),
        const SizedBox(width: 6),
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: _kOlive,
            letterSpacing: 0.4,
          ),
        ),
        if (trailing != null) ...[
          const Spacer(),
          trailing,
        ],
      ],
    );
  }

  Widget _buildMatchActions() {
    final l10n = AppLocalizations.of(context)!;
    final isSetCompleted = _isActiveSetCompleted;
    final isGameComplete = _isGameComplete;
    final isOneSet = _game.matchFormat == MatchFormat.oneSet;
    final scoreLocked = isGameComplete || isSetCompleted;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildTargetPoints(locked: scoreLocked),
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.divider),
          const SizedBox(height: 12),
          // Complete Set — hidden for oneSet (one set == the game)
          if (!isOneSet) ...[
            ElevatedButton.icon(
              onPressed: isGameComplete ? null : _toggleCompleteSet,
              icon: Icon(
                isSetCompleted
                    ? Icons.undo_rounded
                    : Icons.check_circle_outline_rounded,
                size: 18,
              ),
              label: Text(isSetCompleted ? l10n.undoSetCompletion : l10n.completeSet),
              style: ElevatedButton.styleFrom(
                backgroundColor: isGameComplete
                    ? null
                    : isSetCompleted
                        ? Colors.grey.shade500
                        : _kGold,
                foregroundColor: isGameComplete ? null : Colors.white,
              ),
            ),
            const SizedBox(height: 8),
          ],
          // Complete Game / Undo Game Completion
          ElevatedButton.icon(
            onPressed: isGameComplete ? _undoGameCompletion : _doCompleteGame,
            icon: Icon(
              isGameComplete ? Icons.undo_rounded : Icons.emoji_events_rounded,
              size: 18,
            ),
            label: Text(isGameComplete ? l10n.undoGameCompletion : l10n.completeGame),
            style: ElevatedButton.styleFrom(
              backgroundColor: _kOlive,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _saveAndBack,
            icon: const Icon(Icons.arrow_back_rounded, size: 18),
            label: Text(l10n.btnSaveAndReturn),
          ),
        ],
      ),
    );
  }
}

// ── Lineup editor sheet ───────────────────────────────────────────────────────
// Owns its own TextEditingControllers so they are disposed by the sheet's
// lifecycle — after the pop animation completes — avoiding the
// ChangeNotifier._dependents assertion that fires when controllers are
// disposed while TextField widgets still hold listeners.

class _LineupEditorSheet extends StatefulWidget {
  final String teamName;
  final String initialP1;
  final String initialP2;
  final void Function(String p1, String p2) onSave;

  const _LineupEditorSheet({
    required this.teamName,
    required this.initialP1,
    required this.initialP2,
    required this.onSave,
  });

  @override
  State<_LineupEditorSheet> createState() => _LineupEditorSheetState();
}

class _LineupEditorSheetState extends State<_LineupEditorSheet> {
  late final TextEditingController _p1;
  late final TextEditingController _p2;

  @override
  void initState() {
    super.initState();
    _p1 = TextEditingController(text: widget.initialP1);
    _p2 = TextEditingController(text: widget.initialP2);
  }

  @override
  void dispose() {
    _p1.dispose();
    _p2.dispose();
    super.dispose();
  }

  void _swapPlayers() {
    setState(() {
      final tmp = _p1.text;
      _p1.text = _p2.text;
      _p2.text = tmp;
    });
  }

  void _saveAndClose() {
    final name1 = _p1.text.trim().isEmpty ? 'Player 1' : _p1.text.trim();
    final name2 = _p2.text.trim().isEmpty ? 'Player 2' : _p2.text.trim();
    widget.onSave(name1, name2);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final keyboardH = mq.viewInsets.bottom;
    final screenH = mq.size.height;
    final isLandscape = mq.size.width > mq.size.height;

    if (isLandscape) {
      // Landscape: side-by-side fields + header save button.
      // Total height ≈ 130px, well within the ~160px available above keyboard.
      return Padding(
        padding: EdgeInsets.only(bottom: keyboardH),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header: team name on left, Save button on right.
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.teamName,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _saveAndClose,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kGold,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      AppLocalizations.of(context)!.btnSavePlayers,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Player 1 | swap icon | Player 2 — all on one row.
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _compactField(AppLocalizations.of(context)!.playerOne, _p1, 'e.g. Alex')),
                  Padding(
                    padding: const EdgeInsets.only(top: 20, left: 8, right: 8),
                    child: GestureDetector(
                      onTap: _swapPlayers,
                      child: const Icon(Icons.swap_horiz_rounded, size: 22, color: _kOlive),
                    ),
                  ),
                  Expanded(child: _compactField(AppLocalizations.of(context)!.playerTwo, _p2, 'e.g. Jordan')),
                ],
              ),
            ],
          ),
        ),
      );
    }

    // Portrait: existing stacked layout.
    // Cap the sheet at the space above the keyboard so it never overflows.
    final maxSheetH = ((screenH - keyboardH) * 0.97).clamp(120.0, screenH * 0.9);
    return Padding(
      padding: EdgeInsets.only(bottom: keyboardH),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxSheetH),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 36),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(widget.teamName,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(AppLocalizations.of(context)!.editPlayerNamesSubtitle,
                    style: const TextStyle(color: Colors.black45, fontSize: 13)),
                const SizedBox(height: 20),
                _field(AppLocalizations.of(context)!.playerOne, _p1, 'e.g. Alex'),
                const SizedBox(height: 8),
                Center(
                  child: TextButton.icon(
                    onPressed: _swapPlayers,
                    icon: const Icon(Icons.swap_vert_rounded, size: 18, color: _kOlive),
                    label: Text(
                      AppLocalizations.of(context)!.swapPlayers,
                      style: const TextStyle(color: _kOlive, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                _field(AppLocalizations.of(context)!.playerTwo, _p2, 'e.g. Jordan'),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saveAndClose,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kGold,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(AppLocalizations.of(context)!.btnSavePlayers,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Full-height field used in portrait layout.
  Widget _field(String label, TextEditingController ctrl, String hint) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: Colors.black54)),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          decoration: InputDecoration(
            hintText: hint,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
          textCapitalization: TextCapitalization.words,
        ),
      ],
    );
  }

  // Compact field used in landscape layout — smaller label + dense TextField.
  Widget _compactField(String label, TextEditingController ctrl, String hint) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12,
                color: Colors.black54)),
        const SizedBox(height: 4),
        TextField(
          controller: ctrl,
          decoration: InputDecoration(
            hintText: hint,
            isDense: true,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          ),
          textCapitalization: TextCapitalization.words,
        ),
      ],
    );
  }
}
