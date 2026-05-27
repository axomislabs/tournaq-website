import 'package:flutter/material.dart';

import '../models/game.dart';
import '../models/game_set.dart';
import '../models/game_team_lineup.dart';
import '../services/app_data_service.dart';
import '../state/app_state.dart';
import '../widgets/app_drawer.dart';
import '../widgets/tournaq_app_bar.dart';
import '../widgets/scrollable_page.dart';

const _kGold = Color(0xFFA97800);
const _kGoldLight = Color(0xFFFFF8E1);
const _kOlive = Color(0xFF556B2F);
const _kOliveLight = Color(0xFFEEF2E6);

// Score card team backgrounds — always shown, stronger when leading
const _kGoldCardBg = Color(0xFFFFE082);       // Team 1 base (amber 200)
const _kGoldCardLeading = Color(0xFFFFBF00);   // Team 1 leading (deep amber)
const _kOliveCardBg = Color(0xFFC8DC82);      // Team 2 base (light olive)
const _kOliveCardLeading = Color(0xFF96C23C);  // Team 2 leading (rich olive)

class _ScoreEvent {
  final bool isLeft;
  final int setIndex;
  final int prevService;
  final bool changedService;

  const _ScoreEvent({
    required this.isLeft,
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
    _scoreEvents.clear();
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
        isLeft: isLeft,
        setIndex: _game.currentSetIndex,
        prevService: prevService,
        changedService: changedService,
      ));
      // Auto-swap sides when the side-change threshold is reached.
      if (_shouldShowSideChangeReminder()) _isSwapped = !_isSwapped;
    });
  }

  void _removeScore({required bool isLeft}) {
    int eventIndex = -1;
    for (int i = _scoreEvents.length - 1; i >= 0; i--) {
      if (_scoreEvents[i].isLeft == isLeft &&
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
    widget.onAppStateChanged(newState);
    // Stay on page — no Navigator.pop()
  }

  void _undoGameCompletion() {
    final newState = AppDataService.undoGameCompletion(_localState, _game.id);
    setState(() {
      _localState = newState;
      _game = newState.getGameById(widget.gameId)!;
      _loadActiveSetScores();
    });
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

  // ── Build ─────────────────────────────────────────────────────────────────

  void _showGameOptions(BuildContext context) {
    final scoreLocked = _isGameComplete || _isActiveSetCompleted;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Game Options',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: scoreLocked ? Colors.grey.shade100 : const Color(0xFFFFF8E1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.swap_horiz,
                      color: scoreLocked ? Colors.grey : _kGold,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    'Swap Teams',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: scoreLocked ? Colors.grey : Colors.black87,
                    ),
                  ),
                  subtitle: const Text(
                    'Switch left and right sides',
                    style: TextStyle(fontSize: 12, color: Colors.black45),
                  ),
                  onTap: scoreLocked
                      ? null
                      : () {
                          Navigator.of(context).pop();
                          _swap();
                        },
                ),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: _kOliveLight,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.rotate_right_rounded,
                      color: _kOlive,
                      size: 20,
                    ),
                  ),
                  title: const Text(
                    'Change Service',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text(
                    'Advance to next server',
                    style: TextStyle(fontSize: 12, color: Colors.black45),
                  ),
                  onTap: () {
                    Navigator.of(context).pop();
                    _rotateActivePlayer();
                  },
                ),
              ],
            ),
          ),
        ),
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
      appBar: const TournaQAppBar(title: 'Game Scorecard'),
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
                    const SizedBox(height: 4),
                    if (_isGameComplete)
                      _buildLockBanner('Game completed — undo completion to edit scores')
                    else if (_isActiveSetCompleted)
                      _buildLockBanner('Set completed — undo completion to edit scores'),
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
                              compact: true,
                              fillHeight: true,
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
                              compact: true,
                              fillHeight: true,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_shouldShowSideChangeReminder()) ...[
                      const SizedBox(height: 4),
                      Card(
                        color: Colors.yellow[100],
                        margin: EdgeInsets.zero,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          child: Text(
                            'Side change — total score: ${_score1 + _score2}',
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ],
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
                  'Gameplay Controls',
                  Icons.sports_volleyball_rounded,
                  trailing: optionsButton,
                ),
                const SizedBox(height: 10),
                _buildSetOverview(),
                const SizedBox(height: 12),
                if (_isGameComplete)
                  _buildLockBanner('Game completed — undo completion to edit scores')
                else if (_isActiveSetCompleted)
                  _buildLockBanner('Set completed — undo completion to edit scores'),
                portraitScoreCards,
                if (_shouldShowSideChangeReminder()) ...[
                  const SizedBox(height: 8),
                  Card(
                    color: Colors.yellow[100],
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      child: Text(
                        'Side change — total score: ${_score1 + _score2}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                _buildSectionHeader('Match Actions', Icons.emoji_events_rounded),
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
                  ? const Color(0xFF303030)
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
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      runSpacing: 6,
      children: [
        const Text(
          'Target score:',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
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

  Widget _buildLockBanner(String message) {
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
  }) {
    final isTeam1 = teamId == _game.team1Id;
    final teamColor = isTeam1 ? _kGold : _kOlive;
    final cardBg = isTeam1
        ? (isLeading ? _kGoldCardLeading : _kGoldCardBg)
        : (isLeading ? _kOliveCardLeading : _kOliveCardBg);
    final disabled = onIncrement == null;
    final players = _getPlayerNames(teamId);

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
        padding: compact
            ? const EdgeInsets.fromLTRB(8, 6, 8, 6)
            : const EdgeInsets.fromLTRB(10, 12, 10, 10),
        child: Column(
          mainAxisSize: fillHeight ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment: fillHeight ? MainAxisAlignment.spaceEvenly : MainAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: disabled ? null : () => _showLineupEditor(teamId, teamName),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      teamName,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: fillHeight ? 18 : compact ? 12 : 13,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                  if (!disabled) ...[
                    const SizedBox(width: 3),
                    const Icon(Icons.edit_rounded, size: 11, color: Colors.black54),
                  ],
                ],
              ),
            ),
            Text(
              '/ $_targetPoints',
              style: TextStyle(
                fontSize: 11,
                color: teamColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (fillHeight)
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
              )
            else
              Text(
                '$score',
                style: TextStyle(
                  fontSize: compact ? 38 : 56,
                  fontWeight: FontWeight.bold,
                  height: 1.0,
                  color: disabled ? Colors.black38 : Colors.black87,
                ),
              ),
            Row(
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
                    minimumSize: compact ? const Size(36, 36) : null,
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
                    minimumSize: compact ? const Size(36, 36) : null,
                    tapTargetSize: compact ? MaterialTapTargetSize.shrinkWrap : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(child: _buildPlayerChip(teamId, players[0], 0, compact: compact)),
                const SizedBox(width: 4),
                Expanded(child: _buildPlayerChip(teamId, players[1], 1, compact: compact)),
              ],
            ),
          ],
        ),
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
          const Divider(height: 1, color: Color(0xFFEEEEEE)),
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
              label: Text(isSetCompleted ? 'Undo Set Completion' : 'Complete Set'),
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
            label: Text(
                isGameComplete ? 'Undo Game Completion' : 'Complete Game'),
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
            label: const Text('Save & Return to Games'),
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

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 36),
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
            const Text('Edit player names',
                style: TextStyle(color: Colors.black45, fontSize: 13)),
            const SizedBox(height: 20),
            _field('Player 1', _p1, 'e.g. Alex'),
            const SizedBox(height: 8),
            Center(
              child: TextButton.icon(
                onPressed: _swapPlayers,
                icon: const Icon(Icons.swap_vert_rounded, size: 18, color: _kOlive),
                label: const Text(
                  'Swap Players',
                  style: TextStyle(color: _kOlive, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 8),
            _field('Player 2', _p2, 'e.g. Jordan'),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  final name1 =
                      _p1.text.trim().isEmpty ? 'Player 1' : _p1.text.trim();
                  final name2 =
                      _p2.text.trim().isEmpty ? 'Player 2' : _p2.text.trim();
                  widget.onSave(name1, name2);
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kGold,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Save Players',
                    style:
                        TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    );
  }

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
}
