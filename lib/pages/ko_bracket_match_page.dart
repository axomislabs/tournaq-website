import 'dart:async';
import 'dart:math' show Random, pi;
import 'package:flutter/material.dart';
import '../app/app_colors.dart';
import '../l10n/app_localizations.dart';
import '../models/ko_bracket_tournament.dart';
import '../services/ko_bracket_storage_service.dart';
import '../widgets/player_pill.dart';
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

  const KoBracketMatchPage({
    super.key,
    required this.tournament,
    required this.matchId,
    required this.onChanged,
  });

  @override
  State<KoBracketMatchPage> createState() => _KoBracketMatchPageState();
}

class _KoBracketMatchPageState extends State<KoBracketMatchPage> {
  late KoBracketTournament _tournament;
  late KoMatch _match;
  late KoRoundFormat _fmt;
  bool _scheduleExpanded = false;

  // ── Live scores for the active set ───────────────────────────────────────
  int _score1 = 0;
  int _score2 = 0;
  bool _isSwapped = false;

  // ── Timer ─────────────────────────────────────────────────────────────────
  Timer? _timer;
  DateTime _now = DateTime.now();

  // ── Score events (service tracking + history) ─────────────────────────────
  int _activePlayerIndex = 0;
  final List<_ScoreEvent> _scoreEvents = [];

  @override
  void initState() {
    super.initState();
    _tournament = widget.tournament;
    _match = _tournament.matches.firstWhere((m) => m.id == widget.matchId);
    _fmt = _tournament.formatForRound(_match.round);
    _initScores();
    _now = DateTime.now();
    _startTimer();
    _assignSuggestionsIfNeeded();
  }

  @override
  void dispose() {
    _timer?.cancel();
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

  bool get _isMatchComplete => _match.isComplete;
  int get _currentSetIndex => _match.sets.where((s) => s.isCompleted).length;
  bool get _currentSetDone {
    if (_match.sets.isEmpty) return false;
    final last = _match.sets.last;
    return last.isCompleted;
  }

  int get _team1SetsWon => _match.sets.where((s) => s.isCompleted && s.score1 > s.score2).length;
  int get _team2SetsWon => _match.sets.where((s) => s.isCompleted && s.score2 > s.score1).length;

  void _initScores() {
    _score1 = 0;
    _score2 = 0;
  }

  // ── Suggestions (serve + referee) ────────────────────────────────────────

  void _assignSuggestionsIfNeeded() {
    if (_match.startedAt != null || _isMatchComplete) return;
    var match = _match;
    var tournament = _tournament;
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
      tournament = tournament.updateMatch(match);
      KoBracketStorageService.save(tournament);
      setState(() {
        _tournament = tournament;
        _match = match;
      });
    }
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
    final total = _score1 + _score2;
    if (total == 0) return false;
    if (_fmt.pointsPerSet == 15) return total % 5 == 0;
    if (_fmt.pointsPerSet == 21) return total % 7 == 0;
    return false;
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

  // ── Scoring ───────────────────────────────────────────────────────────────

  void _addScore({required bool isLeft}) {
    if (_isMatchComplete || _currentSetDone) return;
    final isTeam1 = isLeft ? !_isSwapped : _isSwapped;
    final prevService = _activePlayerIndex;
    final changedService = isTeam1 != _isTeam1Serving;
    final perSide = _tournament.playersPerSide;
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
    if (_shouldShowSideChangeReminder()) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showSideChangeDialog();
      });
    }
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

  // ── Set & match completion ────────────────────────────────────────────────

  void _completeSet() {
    if (_isMatchComplete) return;
    final s1 = _isSwapped ? _score2 : _score1;
    final s2 = _isSwapped ? _score1 : _score2;
    if (s1 == s2) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Scores are tied — a set cannot end in a draw.'),
        duration: Duration(seconds: 2),
      ));
      return;
    }
    final newSet = KoSet(score1: s1, score2: s2, isCompleted: true);
    final updatedSets = [..._match.sets, newSet];
    var updatedMatch = _match.copyWith(sets: updatedSets);

    // Determine winner if sets are decided.
    final setsToWin = (_fmt.setsPerGame / 2).ceil();
    final t1Sets = updatedSets.where((s) => s.isCompleted && s.score1 > s.score2).length;
    final t2Sets = updatedSets.where((s) => s.isCompleted && s.score2 > s.score1).length;

    if (t1Sets >= setsToWin || t2Sets >= setsToWin) {
      final winnerId = t1Sets >= setsToWin ? _match.team1Id : _match.team2Id;
      updatedMatch = updatedMatch.copyWith(
        winnerId: winnerId,
        status: KoMatchStatus.completed,
        completedAt: DateTime.now(),
      );
      _persist(updatedMatch, isComplete: true);
    } else {
      _persist(updatedMatch, isComplete: false);
    }

    setState(() {
      _activePlayerIndex = 0;
      _initScores();
    });
  }

  void _undoSetCompletion() {
    if (_match.sets.isEmpty) return;
    final last = _match.sets.last;
    if (!last.isCompleted) return;
    final updatedSets = _match.sets.sublist(0, _match.sets.length - 1);
    final updatedMatch = _match.copyWith(
      sets: updatedSets,
      winnerId: null,
      status: _match.sets.length == 1 ? KoMatchStatus.inProgress : _match.status,
    );
    setState(() {
      _score1 = last.score1;
      _score2 = last.score2;
      _activePlayerIndex = 0;
    });
    _persist(updatedMatch, isComplete: false);
  }

  void _completeMatch() {
    if (_isMatchComplete) return;
    // Save current live scores as the final set if not yet done.
    final s1 = _isSwapped ? _score2 : _score1;
    final s2 = _isSwapped ? _score1 : _score2;
    List<KoSet> sets = _match.sets;
    if (!_currentSetDone && (s1 > 0 || s2 > 0)) {
      if (s1 == s2) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Scores are tied — a winner must be determined before completing.'),
          duration: Duration(seconds: 2),
        ));
        return;
      }
      sets = [...sets, KoSet(score1: s1, score2: s2, isCompleted: true)];
    }

    final t1Sets = sets.where((s) => s.isCompleted && s.score1 > s.score2).length;
    final t2Sets = sets.where((s) => s.isCompleted && s.score2 > s.score1).length;
    if (t1Sets == t2Sets) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Sets are tied — a winner must be determined before completing.'),
        duration: Duration(seconds: 2),
      ));
      return;
    }
    final winnerId = t1Sets > t2Sets ? _match.team1Id : _match.team2Id;

    final updatedMatch = _match.copyWith(
      sets: sets,
      winnerId: winnerId,
      status: KoMatchStatus.completed,
      completedAt: DateTime.now(),
    );
    _timer?.cancel();
    _persist(updatedMatch, isComplete: true);
  }

  void _undoMatchCompletion() {
    final updatedMatch = _match.copyWith(
      winnerId: null,
      status: KoMatchStatus.inProgress,
      completedAt: null,
    );
    _persist(updatedMatch, isComplete: false);
    _startTimer();
  }

  // ── Persist ───────────────────────────────────────────────────────────────

  void _persist(KoMatch updatedMatch, {required bool isComplete}) {
    var updated = _tournament.updateMatch(updatedMatch);

    if (isComplete && updatedMatch.winnerId != null) {
      final propagated = updatedMatch.round == 0
          ? KoBracketGenerator.propagatePlayInWinner(updated.matches, updatedMatch.id)
          : KoBracketGenerator.propagateWinner(updated.matches, updatedMatch.id);
      updated = updated.copyWith(matches: propagated);
    }

    if (updated.allMatchesComplete) {
      updated = updated.copyWith(status: KoBracketStatus.completed);
    } else if (updated.status == KoBracketStatus.setup) {
      updated = updated.copyWith(status: KoBracketStatus.inProgress);
    }

    KoBracketStorageService.save(updated);
    setState(() {
      _tournament = updated;
      _match = updated.matches.firstWhere((m) => m.id == widget.matchId);
      _fmt = updated.formatForRound(_match.round);
    });
    widget.onChanged(updated);
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

    final optionsButton = IconButton(
      icon: const Icon(Icons.tune_rounded, size: 20, color: _kOlive),
      tooltip: 'Match Options',
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
      visualDensity: VisualDensity.compact,
      onPressed: _showOptions,
    );

    return Scaffold(
      appBar: TournaQAppBar(
        title: 'Single Elimination',
        subtitle: 'Scorecard',
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_rounded, size: 20, color: _kOlive),
            tooltip: 'Match Options',
            onPressed: _showOptions,
          ),
        ],
      ),
      body: SafeArea(
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
                        'Match complete',
                        winnerName: _match.winnerId != null
                            ? _tournament.teamById(_match.winnerId!)?.name
                            : null,
                      ),
                    ] else if (_currentSetDone) ...[
                      const SizedBox(height: 4),
                      _buildLockBanner('Set complete — confirm before next set'),
                    ] else if (_match.startedAt == null) ...[
                      const SizedBox(height: 4),
                      _buildServesFirstBanner(),
                    ],
                    const SizedBox(height: 4),
                    // Schedule + score cards
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Compact schedule — keep as narrow as possible
                          Expanded(
                            flex: 2,
                            child: _buildScheduleCard(compact: true),
                          ),
                          const SizedBox(width: 8),
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
                  const SizedBox(height: 10),
                  _buildScheduleCard(),
                  const SizedBox(height: 10),
                  _buildSetOverview(),

                  // ── Banners ─────────────────────────────────────────────
                  const SizedBox(height: 10),
                  if (_match.startedAt == null && !_isMatchComplete)
                    _buildServesFirstBanner(),
                  if (_isMatchComplete)
                    _buildLockBanner(
                      'Match complete',
                      winnerName: _match.winnerId != null
                          ? _tournament.teamById(_match.winnerId!)?.name
                          : null,
                    )
                  else if (_currentSetDone)
                    _buildLockBanner('Set complete — confirm before next set'),

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
    );
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
              const Text('Match Options',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              _optionTile(
                sheetCtx,
                icon: Icons.swap_horiz_rounded,
                iconBg: _isMatchComplete ? Colors.grey.shade100 : _kGoldCream,
                iconColor: _isMatchComplete ? Colors.grey : _kGoldDark,
                label: 'Swap Sides',
                subtitle: 'Switch left and right display',
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
                subtitle: 'View point-by-point history',
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
            const Text('SCHEDULE',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
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
      final deltaMin    = actualStart.difference(start).inMinutes;
      final isLate      = deltaMin > 1;
      startChip = _scheduleChip(
        '${_fmtTime(actualStart)} (${delta(deltaMin)})',
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

    // ── Compact card (landscape left column) ─────────────────────────────────
    // Fully vertical: every element on its own line so no minimum horizontal
    // space is required beyond the widest chip (~90–110 px).
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
            // Header
            Row(children: [
              Icon(Icons.schedule_rounded, size: 12, color: labelColor),
              const SizedBox(width: 4),
              Text('SCHEDULE',
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: labelColor,
                      letterSpacing: 0.5)),
            ]),
            const SizedBox(height: 6),
            // Start label
            Row(children: [
              const Icon(Icons.play_circle_outline_rounded,
                  size: 11, color: Colors.black38),
              const SizedBox(width: 4),
              const Text('Planned start',
                  style: TextStyle(fontSize: 10, color: Colors.black45)),
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
            // End label
            Row(children: [
              Icon(Icons.stop_circle_outlined,
                  size: 11,
                  color: isOverEnd ? Colors.red.shade300 : Colors.black38),
              const SizedBox(width: 4),
              const Text('Planned end',
                  style: TextStyle(fontSize: 10, color: Colors.black45)),
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
                const Flexible(
                  child: Text('Over schedule!',
                      style: TextStyle(
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
    final collapsedChip = (inProgress || _isMatchComplete) ? endChip : startChip;

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
                Text('SCHEDULE',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: labelColor,
                        letterSpacing: 0.6)),
                const Spacer(),
                if (!_scheduleExpanded) ...[
                  collapsedChip,
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
                    const SizedBox(
                        width: 36,
                        child: Text('Start',
                            style: TextStyle(fontSize: 11, color: Colors.black45))),
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
                    const SizedBox(
                        width: 36,
                        child: Text('End',
                            style: TextStyle(fontSize: 11, color: Colors.black45))),
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
                      const Flexible(
                        child: Text('Over schedule · Hurry up!',
                            style: TextStyle(
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
        final isActive = i == _currentSetIndex && !_isMatchComplete;
        final isCompleted = set?.isCompleted ?? false;

        final displayScore1 = isActive && !isCompleted ? (_isSwapped ? _score2 : _score1) : (set?.score1 ?? 0);
        final displayScore2 = isActive && !isCompleted ? (_isSwapped ? _score1 : _score2) : (set?.score2 ?? 0);

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

        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: i < maxSets - 1 ? 6 : 0),
            child: Container(
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
                  set == null && !isActive ? '–' : '$displayScore1–$displayScore2',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isActive ? _kGold : isCompleted ? _kOlive : Colors.grey.shade400,
                  ),
                ),
              ]),
            ),
          ),
        );
      }),
    );
  }

  // ── Lock banner ───────────────────────────────────────────────────────────

  // ── Serve suggestion banner ───────────────────────────────────────────────

  Widget _buildServesFirstBanner() {
    final pid = _match.suggestedServingPlayerId;
    if (pid == null) return const SizedBox.shrink();
    final name = [
      ..._team1?.players ?? [],
      ..._team2?.players ?? [],
    ].where((p) => p.appPlayerId == pid).firstOrNull?.name ?? '';
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
            '$name suggested to start serving',
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
                ? '$refName suggested as referee'
                : 'Assign a referee manually',
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

    final pills = team == null
        ? const SizedBox.shrink()
        : Wrap(
            spacing: 4,
            runSpacing: 4,
            alignment: WrapAlignment.center,
            children: team.players.asMap().entries
                .map((e) => PlayerPill(
                      name: e.value.name,
                      isServing: _isTeam1Serving == isTeam1 && _activePlayerOnSide == e.key,
                      activeColor: teamColor,
                      compact: true,
                    ))
                .toList(),
          );

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
            pills,
            Expanded(
              child: FittedBox(
                fit: BoxFit.contain,
                child: Text(
                  '$score',
                  style: TextStyle(
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
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            team?.name ?? 'TBD',
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Colors.black87),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          pills,
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
                _fmt.setsPerGame > 1 ? 'Set $setNum Score' : 'Set Score',
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
                    child: const Text('Cancel'),
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
                    child: const Text('Apply',
                        style: TextStyle(fontWeight: FontWeight.w600)),
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
    final started = _match.copyWith(
      startedAt: DateTime.now(),
      status: KoMatchStatus.inProgress,
    );
    final t = _tournament.updateMatch(started);
    KoBracketStorageService.save(t);
    setState(() {
      _tournament = t;
      _match = started;
    });
    widget.onChanged(t);
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
    final startTime = _match.scheduledStartTime;
    final notStarted = _match.startedAt == null && !_isMatchComplete;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildRefereeBanner(),
        const SizedBox(height: 10),
        // Info chips
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            _chip(Icons.account_tree_rounded, _bracketPositionLabel,
                _kGoldCream, _kGoldDark, iconAngle: pi),
            if (_match.courtAssignment != null)
              _chip(Icons.crop_square_rounded,
                  'Court ${_match.courtAssignment}', _kOliveLight, _kOlive),
            _chip(Icons.info_outline_rounded, _fmt.label,
                Colors.grey.shade100, Colors.black45),
            if (startTime != null)
              _chip(Icons.schedule_rounded, 'Starts ${_fmtTime(startTime)}',
                  Colors.grey.shade100, Colors.black45),
            _chip(Icons.timer_rounded, '${_tournament.minutesForRound(_match.round)} min',
                _kOliveLight, _kOlive),
          ],
        ),
        const SizedBox(height: 12),

        // Start Match (shown when not yet started)
        if (notStarted) ...[
          ElevatedButton.icon(
            onPressed: _startMatch,
            icon: const Icon(Icons.play_arrow_rounded, size: 18),
            label: const Text('Start Match',
                style: TextStyle(fontWeight: FontWeight.w700)),
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

        // Complete Set (multi-set, shown once started)
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
            label: Text(_currentSetDone ? 'Undo Set' : 'Complete Set',
                style: const TextStyle(fontWeight: FontWeight.w700)),
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
              _isMatchComplete ? 'Undo Match Completion' : 'Complete Match',
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
            label: const Text('Set Score Manually'),
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
          label: const Text('Back to Bracket'),
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
