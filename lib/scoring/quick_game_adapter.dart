import 'package:flutter/material.dart';
import '../models/game.dart';
import '../models/game_team_lineup.dart';
import '../services/app_data_service.dart';
import '../services/local_storage_service.dart';
import '../state/app_state.dart';
import '../widgets/team_lineup_editor_sheet.dart';
import 'scoring_adapter.dart';

/// [ScoringAdapter] implementation for the Quick Game flow.
///
/// Wraps [AppState] / [AppDataService] and propagates state changes to the
/// caller via [onStateChanged].
class QuickGameAdapter implements ScoringAdapter {
  AppState _localState;
  late Game _game;
  final String _gameId;
  final Function(AppState) _onStateChanged;
  final VoidCallback? _onSaveAndReturnOverride;

  QuickGameAdapter({
    required AppState initialState,
    required String gameId,
    required Function(AppState) onStateChanged,
    VoidCallback? onSaveAndReturnOverride,
  })  : _localState = initialState,
        _gameId = gameId,
        _onStateChanged = onStateChanged,
        _onSaveAndReturnOverride = onSaveAndReturnOverride {
    _game = initialState.getGameById(gameId)!;
  }

  void _update(AppState newState) {
    _localState = newState;
    _game = newState.getGameById(_gameId)!;
    _onStateChanged(newState);
  }

  // ── Identity ───────────────────────────────────────────────────────────────

  @override String get pageTitle => 'Quick Game';
  @override String get pageSubtitle => 'Scorecard';

  // ── Teams ──────────────────────────────────────────────────────────────────

  @override
  String get team1Name =>
      _game.team1Name.isNotEmpty
          ? _game.team1Name
          : _localState.getTeamById(_game.team1Id)?.name ?? 'Team 1';

  @override
  String get team2Name =>
      _game.team2Name.isNotEmpty
          ? _game.team2Name
          : _localState.getTeamById(_game.team2Id)?.name ?? 'Team 2';

  @override List<String> get team1Players => _resolvePlayerNames(_game.team1Id);
  @override List<String> get team2Players => _resolvePlayerNames(_game.team2Id);

  @override
  int get playersPerSide {
    final lineup = _game.lineups.isNotEmpty ? _game.lineups.first : null;
    final count = lineup?.playerNames.length ?? 0;
    return count > 0
        ? count
        : _localState.getPlayersForTeam(_game.team1Id).length.clamp(2, 6);
  }

  // ── Format ─────────────────────────────────────────────────────────────────

  @override MatchFormat get matchFormat => _game.matchFormat;
  @override int get maxSets => _game.maxSets;

  // ── Current state ──────────────────────────────────────────────────────────

  @override int get currentScore1 =>
      _game.currentSet?.score1 ?? _game.result?.score1 ?? 0;
  @override int get currentScore2 =>
      _game.currentSet?.score2 ?? _game.result?.score2 ?? 0;
  @override int get targetPoints =>
      _game.currentSet?.targetPoints ?? _game.result?.targetPoints ?? 15;
  @override int get currentSetIndex => _game.currentSetIndex;

  @override
  List<AdapterSetInfo> get sets => _game.sets
      .map((s) => AdapterSetInfo(
            score1: s.score1,
            score2: s.score2,
            targetPoints: s.targetPoints,
            isCompleted: s.isCompleted,
            isTeam1Winner: s.winnerTeamId == null
                ? null
                : s.winnerTeamId == _game.team1Id,
          ))
      .toList();

  @override bool get isCurrentSetCompleted =>
      _game.currentSet?.isCompleted ?? false;
  @override bool get isMatchComplete => _game.isMatchComplete;

  @override
  bool? get isTeam1Winner {
    final id = _game.effectiveWinnerTeamId;
    if (id == null) return null;
    return id == _game.team1Id;
  }

  // ── Capability flags ───────────────────────────────────────────────────────

  @override bool get canEditTargetPoints => true;

  // ── Write operations ───────────────────────────────────────────────────────

  @override
  void onLiveScoreChanged(int score1, int score2) {
    if (isCurrentSetCompleted || (score1 == 0 && score2 == 0)) return;
    final newState = AppDataService.updateCurrentSetScore(
      _localState,
      gameId: _gameId,
      score1: score1,
      score2: score2,
    );
    _update(newState);
  }

  @override
  void onSetCompleted(int score1, int score2, int targetPoints) {
    final newState = AppDataService.completeSet(
      _localState,
      gameId: _gameId,
      setIndex: _game.currentSetIndex,
      score1: score1,
      score2: score2,
      targetPoints: targetPoints,
    );
    _update(newState);
  }

  @override
  void onSetUndone(int setIndex) {
    final newState = AppDataService.undoSetCompletion(
      _localState,
      gameId: _gameId,
      setIndex: setIndex,
    );
    _update(newState);
  }

  @override
  void onSetActivated(int setIndex, int currentScore1, int currentScore2) {
    var state = _localState;
    if (!isCurrentSetCompleted && (currentScore1 > 0 || currentScore2 > 0)) {
      state = AppDataService.updateCurrentSetScore(
        state,
        gameId: _gameId,
        score1: currentScore1,
        score2: currentScore2,
      );
    }
    final newState = AppDataService.setActiveSet(state, _gameId, setIndex);
    _update(newState);
  }

  @override
  void onMatchCompleted(int score1, int score2, int targetPoints) {
    var state = _localState;
    if (_game.matchFormat == MatchFormat.oneSet && !isCurrentSetCompleted) {
      state = AppDataService.completeSet(
        state,
        gameId: _gameId,
        setIndex: _game.currentSetIndex,
        score1: score1,
        score2: score2,
        targetPoints: targetPoints,
      );
      _localState = state;
      _game = state.getGameById(_gameId)!;
    }
    final newState = AppDataService.completeGame(state, _gameId);
    _update(newState);
    LocalStorageService.saveGame(_game);
  }

  @override
  void onMatchCompletionUndone() {
    final newState = AppDataService.undoGameCompletion(_localState, _gameId);
    _update(newState);
    LocalStorageService.saveGame(_game);
  }

  // ── Optional capabilities ──────────────────────────────────────────────────

  @override
  Future<void> Function(bool isTeam1, BuildContext context)? get onEditLineup =>
      _editLineup;

  @override VoidCallback? get onSaveAndReturnOverride => _onSaveAndReturnOverride;

  // ── Private helpers ────────────────────────────────────────────────────────

  List<String> _resolvePlayerNames(String teamId) {
    final lineup = _game.lineups.firstWhere(
      (l) => l.teamId == teamId,
      orElse: () => GameTeamLineup(teamId: teamId),
    );
    final teamUsers = _localState.getPlayersForTeam(teamId);
    final teamName = teamId == _game.team1Id ? team1Name : team2Name;
    final n = playersPerSide;

    return List.generate(n, (i) {
      if (i < lineup.playerNames.length && lineup.playerNames[i].isNotEmpty) {
        return lineup.playerNames[i];
      }
      if (i < teamUsers.length) return teamUsers[i].name;
      return 'Player ${i + 1} $teamName';
    });
  }

  Future<void> _editLineup(bool isTeam1, BuildContext context) async {
    final teamId   = isTeam1 ? _game.team1Id : _game.team2Id;
    final teamName = isTeam1 ? team1Name : team2Name;
    final current  = _game.lineups.firstWhere(
      (l) => l.teamId == teamId,
      orElse: () => GameTeamLineup(teamId: teamId),
    );
    final n        = playersPerSide;
    final assigned = _localState.getPlayersForTeam(teamId);

    final activeNames = List.generate(n, (i) {
      if (i < current.playerNames.length && current.playerNames[i].isNotEmpty) {
        return current.playerNames[i];
      }
      if (i < assigned.length) return assigned[i].name;
      return 'Player ${i + 1} $teamName';
    });
    final benchNames = List<String>.from(current.benchNames);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TeamLineupEditorSheet(
        teamName: teamName,
        activeNames: activeNames,
        benchNames: benchNames,
        onSave: (active, bench) {
          var ns = AppDataService.updateTeamPlayersFromList(
            _localState,
            teamId: teamId,
            names: [...active, ...bench],
          );
          ns = AppDataService.updateGameLineup(
            ns,
            _gameId,
            GameTeamLineup(
              teamId: teamId,
              playerNames: active,
              benchNames: bench,
            ),
          );
          _update(ns);
        },
      ),
    );
  }
}
