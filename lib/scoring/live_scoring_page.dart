import 'package:flutter/material.dart';
import '../app/app_colors.dart';
import '../l10n/app_localizations.dart';
import '../models/game.dart';
import '../pages/gameplay_history_page.dart';
import '../widgets/tournaq_app_bar.dart';
import '../widgets/sheet_helpers.dart';
import '../widgets/player_pill.dart';
import 'scoring_adapter.dart';

const _kGold      = AppColors.goldDark;
const _kGoldLight = AppColors.goldCream;
const _kOlive     = AppColors.olive;
const _kOliveLight = AppColors.oliveLight;

const _kGoldCardBg      = AppColors.goldCardBg;
const _kGoldCardLeading = AppColors.goldCardLeading;
const _kOliveCardBg     = AppColors.oliveCardBg;
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

/// The shared live-scoring UI used by all tournament modes.
///
/// All tournament-specific persistence is delegated to [ScoringAdapter].
/// Ephemeral state (live scores, service rotation, side-swap, history events)
/// lives here and is intentionally not persisted — it resets each session.
///
/// To add a new tournament type: implement [ScoringAdapter] and push this
/// page with the new adapter. No changes to this file required.
class LiveScoringPage extends StatefulWidget {
  final ScoringAdapter adapter;
  const LiveScoringPage({super.key, required this.adapter});

  @override
  State<LiveScoringPage> createState() => _LiveScoringPageState();
}

class _LiveScoringPageState extends State<LiveScoringPage> {
  late int _score1;
  late int _score2;
  late int _targetPoints;

  bool _isSwapped = false;
  int _activePlayerIndex = 0;
  final List<_ScoreEvent> _scoreEvents = [];

  // ── Display helpers ────────────────────────────────────────────────────────

  bool get _isTeam1Serving   => _activePlayerIndex % 2 == 0;
  int  get _activePlayerOnSide => _activePlayerIndex ~/ 2;

  int  get _leftScore  => _isSwapped ? _score2 : _score1;
  int  get _rightScore => _isSwapped ? _score1 : _score2;
  bool get _isTeam1Leading => _score1 > _score2;
  bool get _isTeam2Leading => _score2 > _score1;
  bool get _isLeftLeading  => _isSwapped ? _isTeam2Leading : _isTeam1Leading;
  bool get _isRightLeading => _isSwapped ? _isTeam1Leading : _isTeam2Leading;
  bool get _isLeftTeam1    => !_isSwapped;

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _score1       = widget.adapter.currentScore1;
    _score2       = widget.adapter.currentScore2;
    _targetPoints = widget.adapter.targetPoints;
  }

  // ── State mutations ────────────────────────────────────────────────────────

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
    final prevService    = _activePlayerIndex;
    final scoringIsTeam1 = isLeft ? !_isSwapped : _isSwapped;
    final changedService = scoringIsTeam1 != _isTeam1Serving;
    final perSide        = widget.adapter.playersPerSide;
    setState(() {
      _applyDelta(isLeft: isLeft, delta: 1);
      if (changedService) {
        _activePlayerIndex = (_activePlayerIndex + 1) % (2 * perSide);
      }
      _scoreEvents.add(_ScoreEvent(
        isTeam1Score: scoringIsTeam1,
        setIndex: widget.adapter.currentSetIndex,
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
        title: Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: _kGoldLight, borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.swap_horiz_rounded, color: _kGold, size: 20),
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

  void _removeScore({required bool isLeft}) {
    final removeTeam1 = isLeft ? !_isSwapped : _isSwapped;
    final currentSet  = widget.adapter.currentSetIndex;
    int eventIndex = -1;
    for (int i = _scoreEvents.length - 1; i >= 0; i--) {
      if (_scoreEvents[i].isTeam1Score == removeTeam1 &&
          _scoreEvents[i].setIndex == currentSet) {
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

  void _rotateActivePlayer() {
    final perSide = widget.adapter.playersPerSide;
    setState(() => _activePlayerIndex = (_activePlayerIndex + 1) % (2 * perSide));
  }

  void _switchToSet(int setIndex) {
    if (setIndex == widget.adapter.currentSetIndex) return;
    final s1 = _isSwapped ? _score2 : _score1;
    final s2 = _isSwapped ? _score1 : _score2;
    setState(() {
      widget.adapter.onSetActivated(setIndex, s1, s2);
      _score1       = widget.adapter.currentScore1;
      _score2       = widget.adapter.currentScore2;
      _targetPoints = widget.adapter.targetPoints;
      _activePlayerIndex = 0;
      // _scoreEvents intentionally not cleared — history accumulates across sets.
    });
  }

  void _toggleCompleteSet() {
    final s1 = _isSwapped ? _score2 : _score1;
    final s2 = _isSwapped ? _score1 : _score2;
    if (widget.adapter.isCurrentSetCompleted) {
      setState(() {
        widget.adapter.onSetUndone(widget.adapter.currentSetIndex);
        _score1 = widget.adapter.currentScore1;
        _score2 = widget.adapter.currentScore2;
      });
    } else {
      setState(() {
        widget.adapter.onSetCompleted(s1, s2, _targetPoints);
        _score1 = widget.adapter.currentScore1;
        _score2 = widget.adapter.currentScore2;
      });
    }
  }

  void _doCompleteGame() {
    final s1 = _isSwapped ? _score2 : _score1;
    final s2 = _isSwapped ? _score1 : _score2;
    setState(() {
      widget.adapter.onMatchCompleted(s1, s2, _targetPoints);
      _score1 = widget.adapter.currentScore1;
      _score2 = widget.adapter.currentScore2;
    });
  }

  void _undoGameCompletion() {
    setState(() {
      widget.adapter.onMatchCompletionUndone();
      _score1       = widget.adapter.currentScore1;
      _score2       = widget.adapter.currentScore2;
      _targetPoints = widget.adapter.targetPoints;
    });
  }

  bool _shouldShowSideChangeReminder() {
    if (widget.adapter.isCurrentSetCompleted) return false;
    final total = _score1 + _score2;
    if (total == 0) return false;
    if (_targetPoints == 15) return total % 5 == 0;
    if (_targetPoints == 21) return total % 7 == 0;
    return false;
  }

  void _saveAndBack() {
    if (!widget.adapter.isCurrentSetCompleted) {
      final s1 = _isSwapped ? _score2 : _score1;
      final s2 = _isSwapped ? _score1 : _score2;
      if (s1 > 0 || s2 > 0) widget.adapter.onLiveScoreChanged(s1, s2);
    }
    if (!mounted) return;
    final override = widget.adapter.onSaveAndReturnOverride;
    if (override != null) {
      override();
    } else {
      Navigator.of(context).pop();
    }
  }

  // ── History ────────────────────────────────────────────────────────────────

  List<GameHistoryEntry> _buildHistoryEntries() {
    final entries   = <GameHistoryEntry>[];
    final setScores = <int, List<int>>{};

    for (final event in _scoreEvents) {
      final scores = setScores.putIfAbsent(event.setIndex, () => [0, 0]);
      if (event.isTeam1Score) {
        scores[0]++;
      } else {
        scores[1]++;
      }

      final adapterSets = widget.adapter.sets;
      final target = event.setIndex == widget.adapter.currentSetIndex
          ? _targetPoints
          : (event.setIndex < adapterSets.length
              ? adapterSets[event.setIndex].targetPoints
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

  // ── Game options sheet ─────────────────────────────────────────────────────

  void _showGameOptions(BuildContext context) {
    final scoreLocked = widget.adapter.isMatchComplete ||
        widget.adapter.isCurrentSetCompleted;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetCtx) {
        void openHistory() {
          Navigator.of(sheetCtx).pop();
          Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => GameplayHistoryPage(
              team1Name: widget.adapter.team1Name,
              team2Name: widget.adapter.team2Name,
              team1Players: widget.adapter.team1Players,
              team2Players: widget.adapter.team2Players,
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

  Widget _buildGameOptionsPortrait(
      BuildContext sheetCtx, bool scoreLocked, VoidCallback openHistory) {
    final l10n = AppLocalizations.of(context)!;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(l10n.gameOptions,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
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

  Widget _buildGameOptionsLandscape(
      BuildContext sheetCtx, bool scoreLocked, VoidCallback openHistory) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(l10n.gameOptions,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
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
      title: Text(label,
          style: TextStyle(
              fontWeight: FontWeight.w600,
              color: enabled ? Colors.black87 : Colors.grey)),
      subtitle: Text(subtitle,
          style: const TextStyle(fontSize: 12, color: Colors.black45)),
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
            decoration: BoxDecoration(
                color: enabled ? iconBg : Colors.grey.shade100,
                shape: BoxShape.circle),
            child: Icon(icon, color: enabled ? iconColor : Colors.grey, size: 20),
          ),
          const SizedBox(height: 6),
          Text(label,
              style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  color: enabled ? Colors.black87 : Colors.grey),
              textAlign: TextAlign.center),
        ]),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final adapter     = widget.adapter;
    final leftName    = _isLeftTeam1 ? adapter.team1Name : adapter.team2Name;
    final rightName   = _isLeftTeam1 ? adapter.team2Name : adapter.team1Name;
    final scoreLocked = adapter.isMatchComplete || adapter.isCurrentSetCompleted;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _saveAndBack();
      },
      child: Scaffold(
        appBar: TournaQAppBar(
            title: adapter.pageTitle, subtitle: adapter.pageSubtitle),
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

            // ── Landscape ─────────────────────────────────────────────────
            if (isLandscape) {
              return SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(children: [
                        Expanded(child: _buildSetOverview()),
                        const SizedBox(width: 8),
                        optionsButton,
                      ]),
                      if (adapter.isMatchComplete)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: _buildLockBanner(
                            AppLocalizations.of(context)!.lockBannerGame,
                            isTeam1Winner: adapter.isTeam1Winner,
                            gameComplete: true,
                          ),
                        )
                      else if (adapter.isCurrentSetCompleted)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: _buildLockBanner(
                              AppLocalizations.of(context)!.lockBannerSet),
                        ),
                      const SizedBox(height: 4),
                      Expanded(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(child: _buildScoreCard(
                              isTeam1: _isLeftTeam1,
                              teamName: leftName,
                              score: _leftScore,
                              isLeading: _isLeftLeading,
                              onIncrement: scoreLocked ? null : () => _addScore(isLeft: true),
                              onDecrement: scoreLocked ? null : () => _removeScore(isLeft: true),
                              landscape: true,
                            )),
                            const SizedBox(width: 10),
                            Expanded(child: _buildScoreCard(
                              isTeam1: !_isLeftTeam1,
                              teamName: rightName,
                              score: _rightScore,
                              isLeading: _isRightLeading,
                              onIncrement: scoreLocked ? null : () => _addScore(isLeft: false),
                              onDecrement: scoreLocked ? null : () => _removeScore(isLeft: false),
                              landscape: true,
                            )),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            // ── Portrait ──────────────────────────────────────────────────
            final portraitScoreCards = IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: _buildScoreCard(
                    isTeam1: _isLeftTeam1,
                    teamName: leftName,
                    score: _leftScore,
                    isLeading: _isLeftLeading,
                    fillHeight: true,
                    onIncrement: scoreLocked ? null : () => _addScore(isLeft: true),
                    onDecrement: scoreLocked ? null : () => _removeScore(isLeft: true),
                  )),
                  const SizedBox(width: 10),
                  Expanded(child: _buildScoreCard(
                    isTeam1: !_isLeftTeam1,
                    teamName: rightName,
                    score: _rightScore,
                    isLeading: _isRightLeading,
                    fillHeight: true,
                    onIncrement: scoreLocked ? null : () => _addScore(isLeft: false),
                    onDecrement: scoreLocked ? null : () => _removeScore(isLeft: false),
                  )),
                ],
              ),
            );

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Text(
                      '${adapter.team1Name} vs ${adapter.team2Name}',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700),
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
                  if (adapter.isMatchComplete)
                    _buildLockBanner(
                      AppLocalizations.of(context)!.lockBannerGame,
                      isTeam1Winner: adapter.isTeam1Winner,
                      gameComplete: true,
                    )
                  else if (adapter.isCurrentSetCompleted)
                    _buildLockBanner(
                        AppLocalizations.of(context)!.lockBannerSet),
                  portraitScoreCards,
                  const SizedBox(height: 24),
                  _buildSectionHeader(
                      AppLocalizations.of(context)!.sectionMatchActions,
                      Icons.emoji_events_rounded),
                  const SizedBox(height: 8),
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

  // ── Sections ───────────────────────────────────────────────────────────────

  Widget _buildSetOverview() {
    final adapter    = widget.adapter;
    final maxSets    = adapter.maxSets;
    final adapterSets = adapter.sets;

    return Row(
      children: List.generate(maxSets, (i) {
        final setInfo    = i < adapterSets.length ? adapterSets[i] : null;
        final isActive   = i == adapter.currentSetIndex;
        final isCompleted = setInfo?.isCompleted ?? false;

        final displayScore1 =
            isActive && !isCompleted ? _score1 : (setInfo?.score1 ?? 0);
        final displayScore2 =
            isActive && !isCompleted ? _score2 : (setInfo?.score2 ?? 0);
        final displayTarget =
            isActive ? _targetPoints : setInfo?.targetPoints;

        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: i < maxSets - 1 ? 6 : 0),
            child: GestureDetector(
              onTap: () => _switchToSet(i),
              child: _buildSetCard(
                setIndex: i,
                setInfo: setInfo,
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
    required AdapterSetInfo? setInfo,
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
      bgColor     = _kGoldLight;
    } else if (isCompleted) {
      borderColor = _kOlive;
      bgColor     = _kOliveLight;
    } else {
      borderColor = Colors.grey.shade300;
      bgColor     = Colors.grey.shade100;
    }

    String? winnerShort;
    if (isCompleted && setInfo?.isTeam1Winner != null) {
      final name = setInfo!.isTeam1Winner!
          ? widget.adapter.team1Name
          : widget.adapter.team2Name;
      winnerShort =
          '${name.length > 7 ? '${name.substring(0, 7)}…' : name} ✓';
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
            setInfo == null ? '–' : '$displayScore1–$displayScore2',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: isActive
                  ? _kGold
                  : isCompleted
                      ? _kOlive
                      : Colors.grey.shade400,
            ),
          ),
          if (winnerShort != null) ...[
            const SizedBox(height: 2),
            Text(winnerShort,
                style: const TextStyle(fontSize: 9, color: _kOlive),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ],
        ],
      ),
    );
  }

  Widget _buildTargetPoints({bool locked = false}) {
    final l10n = AppLocalizations.of(context)!;
    final editable = widget.adapter.canEditTargetPoints && !locked;
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      runSpacing: 6,
      children: [
        Text(l10n.targetScore,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        for (final v in [11, 15, 21])
          ChoiceChip(
            label: Text('$v'),
            selected: _targetPoints == v,
            onSelected: editable ? (_) => setState(() => _targetPoints = v) : null,
            selectedColor: _kGoldLight,
            labelStyle: TextStyle(
              fontWeight: FontWeight.w600,
              color: _targetPoints == v ? _kGold : null,
            ),
          ),
      ],
    );
  }

  Widget _buildLockBanner(
    String message, {
    bool? isTeam1Winner,
    bool gameComplete = false,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final winnerName = gameComplete && isTeam1Winner != null
        ? (isTeam1Winner
            ? widget.adapter.team1Name
            : widget.adapter.team2Name)
        : null;
    final resolvedWinnerColor = isTeam1Winner == true ? _kGold : _kOlive;
    final resultLabel = gameComplete
        ? (winnerName != null
            ? l10n.gameTileWinner(winnerName)
            : l10n.noWinnerDetermined)
        : null;
    final resultColor = winnerName != null ? resolvedWinnerColor : Colors.black38;

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
              style: const TextStyle(
                  fontSize: 12,
                  color: Colors.black54,
                  fontWeight: FontWeight.w500)),
        ),
        if (resultLabel != null) ...[
          const SizedBox(width: 8),
          Text(resultLabel,
              style: TextStyle(
                  fontSize: 12,
                  color: resultColor,
                  fontWeight: FontWeight.w700)),
        ],
      ]),
    );
  }

  Widget _buildScoreCard({
    required bool isTeam1,
    required String teamName,
    required int score,
    required bool isLeading,
    required VoidCallback? onIncrement,
    required VoidCallback? onDecrement,
    bool compact = false,
    bool fillHeight = false,
    bool landscape = false,
  }) {
    final teamColor = isTeam1 ? _kGold : _kOlive;
    final cardBg    = isTeam1
        ? (isLeading ? _kGoldCardLeading : _kGoldCardBg)
        : (isLeading ? _kOliveCardLeading : _kOliveCardBg);
    final disabled  = onIncrement == null;
    final players   = isTeam1
        ? widget.adapter.team1Players
        : widget.adapter.team2Players;

    EdgeInsets cardPadding;
    if (landscape) {
      cardPadding = const EdgeInsets.fromLTRB(12, 10, 12, 10);
    } else if (compact) {
      cardPadding = const EdgeInsets.fromLTRB(8, 4, 8, 4);
    } else {
      cardPadding = const EdgeInsets.fromLTRB(10, 12, 10, 10);
    }

    final canEdit = widget.adapter.onEditLineup != null;
    final teamNameWidget = GestureDetector(
      onTap: (disabled || !canEdit)
          ? null
          : () async {
              await widget.adapter.onEditLineup!(isTeam1, context);
              if (mounted) setState(() {});
            },
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
          if (!disabled && canEdit) ...[
            const SizedBox(width: 3),
            Icon(Icons.edit_rounded,
                size: landscape ? 12 : 11, color: Colors.black54),
          ],
        ],
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
            tapTargetSize:
                compact ? MaterialTapTargetSize.shrinkWrap : null,
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
            tapTargetSize:
                compact ? MaterialTapTargetSize.shrinkWrap : null,
          ),
        ),
      ],
    );

    final activeColor = isTeam1 ? _kGold : _kOlive;
    final chipsRow = Wrap(
      spacing: 4,
      runSpacing: 4,
      alignment: WrapAlignment.center,
      children: players.asMap().entries.map((e) => PlayerPill(
        name: e.value,
        isServing: _isTeam1Serving == isTeam1 && _activePlayerOnSide == e.key,
        activeColor: activeColor,
        compact: compact || landscape,
      )).toList(),
    );

    Widget cardContent;
    if (landscape) {
      cardContent = LayoutBuilder(
        builder: (context, constraints) {
          final h       = constraints.maxHeight;
          final nameH   = (h * 0.28).clamp(0.0, 21.0);
          final btnH    = (h * 0.47).clamp(0.0, 48.0);
          final spacerH = (h * 0.03).clamp(0.0,  2.0);
          final iconSize = (btnH * 0.55).clamp(12.0, 24.0);

          return SizedBox(
            height: h,
            child: Column(children: [
              SizedBox(height: nameH, child: teamNameWidget),
              const SizedBox(height: 4),
              chipsRow,
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
                        backgroundColor:
                            disabled ? Colors.grey.shade300 : teamColor,
                        foregroundColor:
                            disabled ? Colors.grey : Colors.white,
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
                        backgroundColor:
                            disabled ? Colors.grey.shade300 : teamColor,
                        foregroundColor:
                            disabled ? Colors.grey : Colors.white,
                        fixedSize: Size(btnH, btnH),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: spacerH),
            ]),
          );
        },
      );
    } else {
      cardContent = Column(
        mainAxisSize: fillHeight ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          teamNameWidget,
          const SizedBox(height: 4),
          chipsRow,
          if (fillHeight) const Spacer(),
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
      child: Padding(padding: cardPadding, child: cardContent),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, {Widget? trailing}) {
    return Row(children: [
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
      if (trailing != null) ...[const Spacer(), trailing],
    ]);
  }

  Widget _buildMatchActions() {
    final l10n          = AppLocalizations.of(context)!;
    final adapter       = widget.adapter;
    final isSetCompleted  = adapter.isCurrentSetCompleted;
    final isGameComplete  = adapter.isMatchComplete;
    final isOneSet        = adapter.matchFormat == MatchFormat.oneSet;
    final scoreLocked     = isGameComplete || isSetCompleted;

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
          if (!isOneSet) ...[
            ElevatedButton.icon(
              onPressed: isGameComplete ? null : _toggleCompleteSet,
              icon: Icon(
                isSetCompleted
                    ? Icons.undo_rounded
                    : Icons.check_circle_outline_rounded,
                size: 18,
              ),
              label: Text(
                  isSetCompleted ? l10n.undoSetCompletion : l10n.completeSet),
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
          ElevatedButton.icon(
            onPressed:
                isGameComplete ? _undoGameCompletion : _doCompleteGame,
            icon: Icon(
              isGameComplete ? Icons.undo_rounded : Icons.emoji_events_rounded,
              size: 18,
            ),
            label: Text(isGameComplete
                ? l10n.undoGameCompletion
                : l10n.completeGame),
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
