import 'package:flutter/material.dart';
import '../app/app_colors.dart';
import '../l10n/app_localizations.dart';
import '../models/game.dart';
import '../models/ko_bracket_tournament.dart';
import '../models/player.dart';
import '../models/team.dart';
import '../services/app_data_service.dart';
import '../state/app_state.dart';
import '../utils/team_name_generator.dart';
import 'assign_dialog.dart';
import 'ko_team_editor_sheet.dart';
import 'sheet_helpers.dart';

class QuickStartSheet extends StatefulWidget {
  final AppState appState;

  const QuickStartSheet({super.key, required this.appState});

  @override
  State<QuickStartSheet> createState() => _QuickStartSheetState();
}

class _QuickStartSheetState extends State<QuickStartSheet> {
  MatchFormat? _format;
  bool _showRandom = false;
  int _playersPerTeam = 2;
  late AppState _state;

  // Slot state — either an imported hub team ID or a manually configured KoTeam
  String? _team1Id;
  String? _team2Id;
  KoTeam? _newTeam1;
  KoTeam? _newTeam2;

  String _randomTeam1Name = '';
  String _randomTeam2Name = '';

  @override
  void initState() {
    super.initState();
    _state = widget.appState;
    _generateRandomNames();
  }

  @override
  void dispose() => super.dispose();

  String? get _effectiveTeam1Id => _newTeam1?.hubTeamId ?? _team1Id;
  String? get _effectiveTeam2Id => _newTeam2?.hubTeamId ?? _team2Id;

  // ── Helpers ───────────────────────────────────────────────────────────────

  Player _createPlayer(String name) {
    final player = Player(id: AppState.generateId(), name: name);
    setState(() => _state = _state.addPlayer(player));
    return player;
  }

  String _createTeam(String name, List<String> linkedPlayerIds) {
    final team = Team(id: AppState.generateId(), name: name, userIds: linkedPlayerIds);
    setState(() => _state = _state.addTeam(team));
    return team.id;
  }

  void _updatePlayer(String id, String name, int? skillRating) {
    final player = _state.getPlayerById(id);
    if (player == null) return;
    setState(() => _state = _state.updatePlayer(player.copyWith(
      name: name,
      skillRating: skillRating,
      clearSkillRating: skillRating == null,
    )));
  }

  KoTeam _makeNewTeam(String label) => KoTeam(
        id: KoTeam.generateId(),
        name: label,
        players: List.generate(
          _playersPerTeam,
          (i) => KoPlayerSnapshot(appPlayerId: '', name: 'Player ${i + 1}'),
        ),
      );

  KoTeam _resizeTeam(KoTeam team) {
    if (team.players.length == _playersPerTeam) return team;
    final players = List.generate(
      _playersPerTeam,
      (i) => i < team.players.length
          ? team.players[i]
          : KoPlayerSnapshot(appPlayerId: '', name: 'Player ${i + 1}'),
    );
    return team.copyWith(players: players, clearHubTeamId: true);
  }

  Future<void> _importTeam(int slot, String title) async {
    final excludeId = slot == 1 ? _effectiveTeam2Id : _effectiveTeam1Id;
    final teams = _state.teams
        .where((t) => t.id != excludeId)
        .map((t) {
          final count = _state.getPlayersForTeam(t.id).length;
          return (id: t.id, name: '${t.name} · ${count}p');
        })
        .toList();
    final teamIds = teams.map((t) => t.id).toSet();
    final groups = _state.groups
        .where((g) => g.teamIds.any((id) => teamIds.contains(id)))
        .toList();
    final selected = await showTeamPickerSheet(
      context: context,
      title: title,
      teams: teams,
      groups: groups,
    );
    if (selected != null && mounted) {
      setState(() {
        if (slot == 1) { _team1Id = selected; _newTeam1 = null; }
        else { _team2Id = selected; _newTeam2 = null; }
      });
    }
  }

  void _openNewTeamEditor(int slot) {
    final current = slot == 1 ? _newTeam1 : _newTeam2;
    final team = _resizeTeam(current ?? _makeNewTeam(slot == 1 ? 'Team 1' : 'Team 2'));
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => KoTeamEditorSheet(
        team: team,
        existingPlayers: _state.players,
        existingTeams: _state.teams,
        existingGroups: _state.groups,
        generationMode: KoBracketGenerationMode.random,
        startInCreateMode: true,
        onCreatePlayer: _createPlayer,
        onCreateTeam: _createTeam,
        onUpdatePlayer: _updatePlayer,
        onSave: (updated) => setState(() {
          if (slot == 1) { _newTeam1 = updated; _team1Id = null; }
          else { _newTeam2 = updated; _team2Id = null; }
        }),
      ),
    );
  }

  void _generateRandomNames() {
    final names = TeamNameGenerator.uniqueNames(2);
    setState(() {
      _randomTeam1Name = names[0];
      _randomTeam2Name = names[1];
    });
  }

  void _startGame(String team1Id, String team2Id) {
    final newState = AppDataService.createQuickGame(
      _state,
      team1Id: team1Id,
      team2Id: team2Id,
      playersPerSide: _playersPerTeam,
      matchFormat: _format!,
    );
    final gameId = newState.games.last.id;
    Navigator.pop(context, (state: newState, gameId: gameId));
  }

  void _startWithRandomTeams() {
    var newState = AppDataService.createTeamWithPlayers(
      _state,
      name: _randomTeam1Name,
      playerCount: _playersPerTeam,
    );
    final team1Id = newState.teams.last.id;
    newState = AppDataService.createTeamWithPlayers(
      newState,
      name: _randomTeam2Name,
      playerCount: _playersPerTeam,
    );
    final team2Id = newState.teams.last.id;
    _state = newState;
    _startGame(team1Id, team2Id);
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return OrientationBuilder(
      builder: (context, orientation) {
        final isLandscape = orientation == Orientation.landscape;
        return TournaQSheet(
          body: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(24, 8, 24, isLandscape ? 16 : 40),
            child: _buildCurrentStep(l10n, isLandscape),
          ),
        );
      },
    );
  }

  Widget _buildCurrentStep(AppLocalizations l10n, bool isLandscape) {
    if (_format == null) return _buildFormatPicker(l10n, isLandscape);
    if (_showRandom) return _buildRandom(l10n, isLandscape);
    return _buildUnifiedTeamPicker(l10n, isLandscape);
  }

  // ── Format picker ─────────────────────────────────────────────────────────

  Widget _buildFormatPicker(AppLocalizations l10n, bool isLandscape) {
    const sectionLabel = TextStyle(
        fontWeight: FontWeight.w600, fontSize: 14, color: Colors.black54);

    final styleSelector = DropdownButton<int>(
      value: _playersPerTeam,
      underline: const SizedBox.shrink(),
      items: List.generate(5, (i) {
        final n = i + 2;
        return DropdownMenuItem(value: n, child: Text('${n}v$n'));
      }),
      onChanged: (v) => setState(() => _playersPerTeam = v!),
    );

    final card1 = _buildOptionCard(
      icon: Icons.filter_1_rounded,
      label: l10n.formatOneSet,
      subtitle: l10n.formatOneSetSubtitle,
      onTap: () => setState(() => _format = MatchFormat.oneSet),
      compact: isLandscape,
    );
    final card2 = _buildOptionCard(
      icon: Icons.filter_3_rounded,
      label: l10n.formatBestOfThree,
      subtitle: l10n.formatBestOfThreeSubtitle,
      onTap: () => setState(() => _format = MatchFormat.bestOfThree),
      compact: isLandscape,
    );

    if (isLandscape) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _compactHeader(Icons.flash_on_rounded, 'Game Setup'),
              const SizedBox(height: 12),
              Text(l10n.labelStyle, style: sectionLabel),
              const SizedBox(height: 6),
              DropdownButton<int>(
                value: _playersPerTeam,
                isExpanded: true,
                underline: const SizedBox.shrink(),
                items: List.generate(5, (i) {
                  final n = i + 2;
                  return DropdownMenuItem(
                      value: n,
                      child: Text('${n}v$n',
                          style: const TextStyle(fontSize: 13)));
                }),
                onChanged: (v) => setState(() => _playersPerTeam = v!),
              ),
            ]),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 6,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Format', style: sectionLabel),
                const SizedBox(height: 8),
                card1,
                const SizedBox(height: 8),
                card2,
              ],
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fullHeader(Icons.flash_on_rounded, 'Game Setup'),
        const SizedBox(height: 20),
        Text(l10n.labelStyle, style: sectionLabel),
        const SizedBox(height: 8),
        styleSelector,
        const SizedBox(height: 20),
        const Text('Format', style: sectionLabel),
        const SizedBox(height: 12),
        card1,
        const SizedBox(height: 12),
        card2,
      ],
    );
  }

  // ── Unified team picker ───────────────────────────────────────────────────

  Widget _buildUnifiedTeamPicker(AppLocalizations l10n, bool isLandscape) {
    final id1 = _effectiveTeam1Id;
    final id2 = _effectiveTeam2Id;
    final canStart = id1 != null && id2 != null && id1 != id2;
    final title = _format == MatchFormat.oneSet ? l10n.formatOneSet : l10n.formatBestOfThreeShort;

    final slot1 = _buildTeamSlot(label: l10n.teamOne, slot: 1, l10n: l10n, compact: isLandscape);
    final slot2 = _buildTeamSlot(label: l10n.teamTwo, slot: 2, l10n: l10n, compact: isLandscape);
    final randomCard = _buildOptionCard(
      icon: Icons.casino_rounded,
      label: l10n.teamMethodRandom,
      subtitle: l10n.teamMethodRandomSubtitle,
      onTap: () => setState(() => _showRandom = true),
      compact: isLandscape,
    );

    if (isLandscape) {
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: _buildCompactBackHeader(title, onBack: () => setState(() => _format = null))),
          const SizedBox(width: 12),
          _buildCompactStartButton(l10n, onPressed: canStart ? () => _startGame(id1, id2) : null),
        ]),
        const SizedBox(height: 12),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: slot1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            child: Text(l10n.labelVs, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Colors.black26)),
          ),
          Expanded(child: slot2),
        ]),
        const SizedBox(height: 10),
        randomCard,
      ]);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildBackHeader(title, onBack: () => setState(() => _format = null)),
        const SizedBox(height: 20),
        slot1,
        _importedTeamSizeWarning(1),
        const SizedBox(height: 12),
        Center(child: Text(l10n.labelVs, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Colors.black26))),
        const SizedBox(height: 12),
        slot2,
        _importedTeamSizeWarning(2),
        const SizedBox(height: 20),
        randomCard,
        const SizedBox(height: 20),
        _buildStartButton(l10n, onPressed: canStart ? () => _startGame(id1, id2) : null),
      ],
    );
  }

  Widget _buildTeamSlot({
    required String label,
    required int slot,
    required AppLocalizations l10n,
    bool compact = false,
  }) {
    final newTeam = slot == 1 ? _newTeam1 : _newTeam2;
    final teamId = slot == 1 ? _team1Id : _team2Id;

    String? name;
    List<String> playerNames = [];

    if (newTeam != null) {
      name = newTeam.name;
      playerNames = newTeam.players.map((p) => p.name).toList();
    } else if (teamId != null) {
      name = _state.getTeamById(teamId)?.name;
      playerNames = _state.getPlayersForTeam(teamId).map((p) => p.name).toList();
    }

    final isConfigured = name != null;
    final iconColor = isConfigured ? AppColors.olive : Colors.black38;
    final borderColor = isConfigured ? AppColors.olive : Colors.grey.shade300;
    final bgColor = isConfigured ? AppColors.oliveLight : Colors.grey.shade50;
    final titleStr = slot == 1 ? l10n.teamOne : l10n.teamTwo;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: compact ? 8 : 10),
      decoration: BoxDecoration(
        border: Border.all(color: borderColor, width: isConfigured ? 1.5 : 1.0),
        borderRadius: BorderRadius.circular(12),
        color: bgColor,
      ),
      child: Row(children: [
        Icon(Icons.groups_rounded, color: iconColor, size: compact ? 18 : 20),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w600,
                color: isConfigured ? AppColors.olive.withValues(alpha: 0.7) : Colors.black38)),
            const SizedBox(height: 2),
            if (name != null) ...[
              Text(name, style: TextStyle(
                  fontSize: compact ? 13 : 14, fontWeight: FontWeight.w600,
                  color: AppColors.olive),
                  overflow: TextOverflow.ellipsis),
              if (playerNames.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(playerNames.join(' · '),
                    style: TextStyle(fontSize: 11, color: AppColors.olive.withValues(alpha: 0.7)),
                    overflow: TextOverflow.ellipsis),
              ],
            ] else
              Text('Tap Import or Edit to configure',
                  style: TextStyle(fontSize: compact ? 12 : 13, color: Colors.black38)),
          ]),
        ),
        IconButton(
          icon: const Icon(Icons.download_rounded, size: 18),
          tooltip: 'Import from hub',
          color: iconColor,
          onPressed: () => _importTeam(slot, titleStr),
        ),
        IconButton(
          icon: const Icon(Icons.edit_rounded, size: 18),
          tooltip: 'Edit manually',
          color: iconColor,
          onPressed: () => _openNewTeamEditor(slot),
        ),
      ]),
    );
  }

  Widget _importedTeamSizeWarning(int slot) {
    final teamId = slot == 1 ? _team1Id : _team2Id;
    final newTeam = slot == 1 ? _newTeam1 : _newTeam2;
    if (teamId == null || newTeam != null) return const SizedBox.shrink();
    final count = _state.getPlayersForTeam(teamId).length;
    if (count == _playersPerTeam) return const SizedBox.shrink();

    final String message;
    if (count < _playersPerTeam) {
      final missing = _playersPerTeam - count;
      message = '$count of $_playersPerTeam players — $missing placeholder${missing == 1 ? '' : 's'} will be added';
    } else {
      final benched = count - _playersPerTeam;
      message = '$count of $_playersPerTeam players — $benched player${benched == 1 ? '' : 's'} will be benched';
    }

    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(children: [
        const Icon(Icons.info_outline_rounded, size: 13, color: Colors.amber),
        const SizedBox(width: 5),
        Expanded(
          child: Text(message,
              style: const TextStyle(fontSize: 11, color: Colors.black54)),
        ),
      ]),
    );
  }

  // ── Random teams ──────────────────────────────────────────────────────────

  Widget _buildRandom(AppLocalizations l10n, bool isLandscape) {
    final onBack = () => setState(() => _showRandom = false);

    if (isLandscape) {
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: _buildCompactBackHeader(l10n.quickStartRandomTeamsTitle, onBack: onBack)),
          const SizedBox(width: 12),
          OutlinedButton.icon(
            onPressed: _generateRandomNames,
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: Text(l10n.quickStartReRoll, style: const TextStyle(fontSize: 13)),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: _startWithRandomTeams,
            icon: const Icon(Icons.play_arrow_rounded, size: 18),
            label: Text(l10n.btnStart, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.gold,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ]),
        const SizedBox(height: 12),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Expanded(child: _buildRandomTeamBadge(_randomTeam1Name, compact: true)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(l10n.labelVs, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: Colors.black38)),
          ),
          Expanded(child: _buildRandomTeamBadge(_randomTeam2Name, compact: true)),
        ]),
      ]);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildBackHeader(l10n.quickStartRandomTeamsTitle, onBack: onBack),
        const SizedBox(height: 36),
        Center(
          child: Column(
            children: [
              _buildRandomTeamBadge(_randomTeam1Name),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(l10n.labelVs, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 22, color: Colors.black38)),
              ),
              _buildRandomTeamBadge(_randomTeam2Name),
            ],
          ),
        ),
        const SizedBox(height: 28),
        OutlinedButton.icon(
          onPressed: _generateRandomNames,
          icon: const Icon(Icons.refresh_rounded),
          label: Text(l10n.quickStartReRollTeams),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 12),
        _buildStartButton(l10n, onPressed: _startWithRandomTeams),
      ],
    );
  }

  Widget _buildRandomTeamBadge(String name, {bool compact = false}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 16 : 24, vertical: compact ? 10 : 16),
      decoration: BoxDecoration(
        color: AppColors.goldCream,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.goldBadgeBorder, width: 1.5),
      ),
      child: Row(
        mainAxisSize: compact ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.casino_rounded, color: AppColors.gold, size: compact ? 16 : 20),
          SizedBox(width: compact ? 8 : 10),
          Flexible(
            child: Text(
              name,
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: compact ? 15 : 18, color: Colors.black87),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // ── Shared UI helpers ─────────────────────────────────────────────────────

  Widget _fullHeader(IconData icon, String title) {
    return Row(children: [
      Container(
        padding: const EdgeInsets.all(8),
        decoration: const BoxDecoration(color: AppColors.goldCream, shape: BoxShape.circle),
        child: Icon(icon, color: AppColors.gold, size: 22),
      ),
      const SizedBox(width: 12),
      Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
    ]);
  }

  Widget _compactHeader(IconData icon, String title) {
    return Row(children: [
      Container(
        padding: const EdgeInsets.all(7),
        decoration: const BoxDecoration(color: AppColors.goldCream, shape: BoxShape.circle),
        child: Icon(icon, color: AppColors.gold, size: 18),
      ),
      const SizedBox(width: 10),
      Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
    ]);
  }

  Widget _buildBackHeader(String title, {VoidCallback? onBack}) {
    return Row(
      children: [
        GestureDetector(
          onTap: onBack ?? () => setState(() => _format = null),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.grey[100], shape: BoxShape.circle),
            child: const Icon(Icons.arrow_back_ios_new_rounded, size: 16),
          ),
        ),
        const SizedBox(width: 12),
        Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
      ],
    );
  }

  Widget _buildCompactBackHeader(String title, {VoidCallback? onBack}) {
    return Row(
      children: [
        GestureDetector(
          onTap: onBack ?? () => setState(() => _format = null),
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: Colors.grey[100], shape: BoxShape.circle),
            child: const Icon(Icons.arrow_back_ios_new_rounded, size: 14),
          ),
        ),
        const SizedBox(width: 10),
        Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
      ],
    );
  }

  Widget _buildOptionCard({
    required IconData icon,
    required String label,
    required String subtitle,
    required VoidCallback onTap,
    bool compact = false,
  }) {
    final iconSize = compact ? 36.0 : 44.0;
    final padding = compact
        ? const EdgeInsets.symmetric(horizontal: 12, vertical: 10)
        : const EdgeInsets.all(16);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.divider),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              width: iconSize,
              height: iconSize,
              decoration: const BoxDecoration(color: AppColors.goldCream, shape: BoxShape.circle),
              child: Icon(icon, color: AppColors.gold, size: compact ? 18 : 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(fontWeight: FontWeight.w600, fontSize: compact ? 14 : 15)),
                  Text(subtitle, style: TextStyle(color: Colors.black45, fontSize: compact ? 12 : 13)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.black26),
          ],
        ),
      ),
    );
  }

  Widget _buildStartButton(AppLocalizations l10n, {required VoidCallback? onPressed}) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.play_arrow_rounded),
        label: Text(l10n.btnStartGame, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.gold,
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.grey[200],
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _buildCompactStartButton(AppLocalizations l10n, {required VoidCallback? onPressed}) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.play_arrow_rounded, size: 18),
      label: Text(l10n.btnStartGame, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.gold,
        foregroundColor: Colors.white,
        disabledBackgroundColor: Colors.grey[200],
        padding: const EdgeInsets.symmetric(vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}
