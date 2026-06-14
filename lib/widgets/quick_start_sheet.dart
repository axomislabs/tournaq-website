import 'dart:math';

import 'package:flutter/material.dart';
import '../app/app_colors.dart';
import '../l10n/app_localizations.dart';
import '../models/game.dart';
import '../models/team.dart';
import '../services/app_data_service.dart';
import '../state/app_state.dart';
import 'sheet_helpers.dart';

enum _TeamMethod { existing, createNew, random }

class QuickStartSheet extends StatefulWidget {
  final AppState appState;

  const QuickStartSheet({super.key, required this.appState});

  @override
  State<QuickStartSheet> createState() => _QuickStartSheetState();
}

class _QuickStartSheetState extends State<QuickStartSheet> {
  MatchFormat? _format;
  _TeamMethod? _method;
  int _playersPerTeam = 2;
  late AppState _state;

  String? _team1Id;
  String? _team2Id;

  final _team1Controller = TextEditingController();
  final _team2Controller = TextEditingController();

  String _randomTeam1Name = '';
  String _randomTeam2Name = '';

  static const _adjectives = [
    'Thunder', 'Iron', 'Swift', 'Bold', 'Red', 'Blue', 'Gold', 'Silver',
    'Dark', 'Storm', 'Crimson', 'Blazing', 'Frozen', 'Shadow', 'Solar',
    'Mighty', 'Royal', 'Wild', 'Steel', 'Fire',
  ];
  static const _nouns = [
    'Hawks', 'Bears', 'Lions', 'Eagles', 'Wolves', 'Panthers', 'Sharks',
    'Tigers', 'Foxes', 'Dragons', 'Cobras', 'Ravens', 'Falcons', 'Jaguars',
    'Vipers', 'Stallions', 'Rhinos', 'Gladiators', 'Titans', 'Strikers',
  ];

  @override
  void initState() {
    super.initState();
    _state = widget.appState;
    _generateRandomNames();
  }

  @override
  void dispose() {
    _team1Controller.dispose();
    _team2Controller.dispose();
    super.dispose();
  }

  void _generateRandomNames() {
    final rng = Random();
    final adj1 = _adjectives[rng.nextInt(_adjectives.length)];
    final adj2 = _adjectives[rng.nextInt(_adjectives.length)];
    final noun1 = _nouns[rng.nextInt(_nouns.length)];
    String noun2;
    do {
      noun2 = _nouns[rng.nextInt(_nouns.length)];
    } while (noun2 == noun1);
    setState(() {
      _randomTeam1Name = '$adj1 $noun1';
      _randomTeam2Name = '$adj2 $noun2';
    });
  }

  void _startGame(String team1Id, String team2Id) {
    final newState = AppDataService.createQuickGame(
      _state,
      team1Id: team1Id,
      team2Id: team2Id,
      matchFormat: _format!,
    );
    final gameId = newState.games.last.id;
    Navigator.pop(context, (state: newState, gameId: gameId));
  }

  void _startWithNewTeams() {
    final name1 = _team1Controller.text.trim();
    final name2 = _team2Controller.text.trim();
    if (name1.isEmpty || name2.isEmpty) return;

    var newState = AppDataService.createTeamWithPlayers(
      _state,
      name: name1,
      scope: TeamScope.temporary,
      playerCount: _playersPerTeam,
    );
    final team1Id = newState.teams.last.id;
    newState = AppDataService.createTeamWithPlayers(
      newState,
      name: name2,
      scope: TeamScope.temporary,
      playerCount: _playersPerTeam,
    );
    final team2Id = newState.teams.last.id;
    _state = newState;
    _startGame(team1Id, team2Id);
  }

  void _startWithRandomTeams() {
    var newState = AppDataService.createTeamWithPlayers(
      _state,
      name: _randomTeam1Name,
      scope: TeamScope.temporary,
      playerCount: _playersPerTeam,
    );
    final team1Id = newState.teams.last.id;
    newState = AppDataService.createTeamWithPlayers(
      newState,
      name: _randomTeam2Name,
      scope: TeamScope.temporary,
      playerCount: _playersPerTeam,
    );
    final team2Id = newState.teams.last.id;
    _state = newState;
    _startGame(team1Id, team2Id);
  }

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
    if (_method == null) return _buildMethodPicker(l10n, isLandscape);
    return _buildTeamPicker(l10n, isLandscape);
  }

  Widget _buildFormatPicker(AppLocalizations l10n, bool isLandscape) {
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
              _compactHeader(Icons.flash_on_rounded, l10n.quickStartShort),
              const SizedBox(height: 6),
              Text(l10n.quickStartFormatQuestion,
                  style: const TextStyle(color: Colors.black54, fontSize: 14)),
            ]),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 6,
            child: Column(children: [
              card1,
              const SizedBox(height: 8),
              card2,
            ]),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fullHeader(Icons.flash_on_rounded, l10n.quickStartTitle),
        const SizedBox(height: 8),
        Text(l10n.quickStartFormatQuestion,
            style: const TextStyle(color: Colors.black54, fontSize: 15)),
        const SizedBox(height: 24),
        card1,
        const SizedBox(height: 12),
        card2,
      ],
    );
  }

  Widget _buildPlayerCountSelector() {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      children: [
        Text(
          l10n.labelStyle,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: Colors.black54,
          ),
        ),
        const SizedBox(width: 12),
        DropdownButton<int>(
          value: _playersPerTeam,
          items: List.generate(5, (i) {
            final n = i + 2;
            return DropdownMenuItem(value: n, child: Text('${n}vs$n'));
          }),
          onChanged: (v) => setState(() => _playersPerTeam = v!),
          underline: const SizedBox.shrink(),
          borderRadius: BorderRadius.circular(10),
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildMethodPicker(AppLocalizations l10n, bool isLandscape) {
    final title = _format == MatchFormat.oneSet ? l10n.formatOneSet : l10n.formatBestOfThreeShort;
    final card1 = _buildOptionCard(
      icon: Icons.group_rounded,
      label: l10n.teamMethodExisting,
      subtitle: l10n.teamMethodExistingSubtitle,
      onTap: () => setState(() => _method = _TeamMethod.existing),
      compact: isLandscape,
    );
    final card2 = _buildOptionCard(
      icon: Icons.edit_rounded,
      label: l10n.teamMethodNew,
      subtitle: l10n.teamMethodNewSubtitle,
      onTap: () => setState(() => _method = _TeamMethod.createNew),
      compact: isLandscape,
    );
    final card3 = _buildOptionCard(
      icon: Icons.casino_rounded,
      label: l10n.teamMethodRandom,
      subtitle: l10n.teamMethodRandomSubtitle,
      onTap: () => setState(() => _method = _TeamMethod.random),
      compact: isLandscape,
    );

    if (isLandscape) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _buildCompactBackHeader(title, onBack: () => setState(() => _format = null)),
              const SizedBox(height: 6),
              Text(l10n.quickStartChooseTeams, style: const TextStyle(color: Colors.black54, fontSize: 14)),
            ]),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 6,
            child: Column(children: [
              card1,
              const SizedBox(height: 8),
              card2,
              const SizedBox(height: 8),
              card3,
            ]),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildBackHeader(title, onBack: () => setState(() => _format = null)),
        const SizedBox(height: 8),
        Text(l10n.quickStartTeamQuestion, style: const TextStyle(color: Colors.black54, fontSize: 15)),
        const SizedBox(height: 24),
        card1,
        const SizedBox(height: 12),
        card2,
        const SizedBox(height: 12),
        card3,
      ],
    );
  }

  Widget _buildTeamPicker(AppLocalizations l10n, bool isLandscape) {
    switch (_method!) {
      case _TeamMethod.existing:
        return _buildExistingTeams(l10n, isLandscape);
      case _TeamMethod.createNew:
        return _buildCreateNew(l10n, isLandscape);
      case _TeamMethod.random:
        return _buildRandom(l10n, isLandscape);
    }
  }

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
          onTap: onBack ?? () => setState(() => _method = null),
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
          onTap: onBack ?? () => setState(() => _method = null),
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

  Widget _buildExistingTeams(AppLocalizations l10n, bool isLandscape) {
    final teams = _state.teams;
    final backHeader = isLandscape
        ? _buildCompactBackHeader(l10n.quickStartSelectTeamsTitle)
        : _buildBackHeader(l10n.quickStartSelectTeamsTitle);

    if (teams.length < 2) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          backHeader,
          SizedBox(height: isLandscape ? 16 : 48),
          Center(
            child: Column(
              children: [
                const Icon(Icons.group_off_rounded, size: 52, color: Colors.black26),
                const SizedBox(height: 12),
                Text(l10n.quickStartNotEnoughTeams, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                const SizedBox(height: 4),
                Text(
                  l10n.quickStartNotEnoughTeamsBody,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.black45),
                ),
              ],
            ),
          ),
        ],
      );
    }

    final fieldBorder = OutlineInputBorder(borderRadius: BorderRadius.circular(12));
    final fieldPadding = const EdgeInsets.symmetric(horizontal: 16, vertical: 14);
    final canStart = _team1Id != null && _team2Id != null && _team1Id != _team2Id;

    if (isLandscape) {
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: _buildCompactBackHeader(l10n.quickStartSelectTeamsTitle)),
          const SizedBox(width: 12),
          _buildCompactStartButton(l10n, onPressed: canStart ? () => _startGame(_team1Id!, _team2Id!) : null),
        ]),
        const SizedBox(height: 12),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(l10n.teamOne, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.black54)),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              initialValue: _team1Id,
              isDense: true,
              decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)), contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
              hint: Text(l10n.quickStartChooseTeam1, style: const TextStyle(fontSize: 13)),
              items: teams.where((t) => t.id != _team2Id).map((t) => DropdownMenuItem(value: t.id, child: Text(t.name, style: const TextStyle(fontSize: 13)))).toList(),
              onChanged: (v) => setState(() => _team1Id = v),
            ),
          ])),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(l10n.teamTwo, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.black54)),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              initialValue: _team2Id,
              isDense: true,
              decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)), contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
              hint: Text(l10n.quickStartChooseTeam2, style: const TextStyle(fontSize: 13)),
              items: teams.where((t) => t.id != _team1Id).map((t) => DropdownMenuItem(value: t.id, child: Text(t.name, style: const TextStyle(fontSize: 13)))).toList(),
              onChanged: (v) => setState(() => _team2Id = v),
            ),
          ])),
        ]),
      ]);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        backHeader,
        const SizedBox(height: 24),
        Text(l10n.teamOne, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.black54)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: _team1Id,
          decoration: InputDecoration(border: fieldBorder, contentPadding: fieldPadding),
          hint: Text(l10n.quickStartChooseTeam1),
          items: teams.where((t) => t.id != _team2Id).map((t) => DropdownMenuItem(value: t.id, child: Text(t.name))).toList(),
          onChanged: (v) => setState(() => _team1Id = v),
        ),
        const SizedBox(height: 20),
        Text(l10n.teamTwo, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.black54)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: _team2Id,
          decoration: InputDecoration(border: fieldBorder, contentPadding: fieldPadding),
          hint: Text(l10n.quickStartChooseTeam2),
          items: teams.where((t) => t.id != _team1Id).map((t) => DropdownMenuItem(value: t.id, child: Text(t.name))).toList(),
          onChanged: (v) => setState(() => _team2Id = v),
        ),
        const SizedBox(height: 28),
        _buildStartButton(l10n, onPressed: canStart ? () => _startGame(_team1Id!, _team2Id!) : null),
      ],
    );
  }

  Widget _buildCreateNew(AppLocalizations l10n, bool isLandscape) {
    final fieldBorder = OutlineInputBorder(borderRadius: BorderRadius.circular(12));
    final fieldPadding = const EdgeInsets.symmetric(horizontal: 16, vertical: 14);
    final canStart = _team1Controller.text.trim().isNotEmpty && _team2Controller.text.trim().isNotEmpty;

    if (isLandscape) {
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: _buildCompactBackHeader(l10n.quickStartCreateTeamsTitle)),
          const SizedBox(width: 12),
          _buildCompactStartButton(l10n, onPressed: canStart ? _startWithNewTeams : null),
        ]),
        const SizedBox(height: 12),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(l10n.quickStartTeam1Name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.black54)),
            const SizedBox(height: 6),
            TextField(
              controller: _team1Controller,
              decoration: InputDecoration(hintText: l10n.hintTeam1Example, border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)), contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10), isDense: true),
              textCapitalization: TextCapitalization.words,
              onChanged: (_) => setState(() {}),
            ),
          ])),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(l10n.quickStartTeam2Name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.black54)),
            const SizedBox(height: 6),
            TextField(
              controller: _team2Controller,
              decoration: InputDecoration(hintText: l10n.hintTeam2Example, border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)), contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10), isDense: true),
              textCapitalization: TextCapitalization.words,
              onChanged: (_) => setState(() {}),
            ),
          ])),
        ]),
        const SizedBox(height: 10),
        _buildPlayerCountSelector(),
      ]);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildBackHeader(l10n.quickStartCreateTeamsTitle),
        const SizedBox(height: 24),
        Text(l10n.quickStartTeam1Name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.black54)),
        const SizedBox(height: 8),
        TextField(
          controller: _team1Controller,
          decoration: InputDecoration(hintText: l10n.hintTeam1Example, border: fieldBorder, contentPadding: fieldPadding),
          textCapitalization: TextCapitalization.words,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 20),
        Text(l10n.quickStartTeam2Name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.black54)),
        const SizedBox(height: 8),
        TextField(
          controller: _team2Controller,
          decoration: InputDecoration(hintText: l10n.hintTeam2Example, border: fieldBorder, contentPadding: fieldPadding),
          textCapitalization: TextCapitalization.words,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 20),
        _buildPlayerCountSelector(),
        const SizedBox(height: 20),
        _buildStartButton(l10n, onPressed: canStart ? _startWithNewTeams : null),
      ],
    );
  }

  Widget _buildRandom(AppLocalizations l10n, bool isLandscape) {
    if (isLandscape) {
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: _buildCompactBackHeader(l10n.quickStartRandomTeamsTitle)),
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
        const SizedBox(height: 10),
        _buildPlayerCountSelector(),
      ]);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildBackHeader(l10n.quickStartRandomTeamsTitle),
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
        _buildPlayerCountSelector(),
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
}
