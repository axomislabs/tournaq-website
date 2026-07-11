import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../app/app_colors.dart';
import '../l10n/app_localizations.dart';
import '../models/group.dart';
import '../models/scramble_king_tournament.dart';
import '../models/scramble_tournament.dart' show ScrambleSuggestion;
import '../services/scramble_king_service.dart';
import '../models/player.dart';
import '../widgets/scramble_suggestion_card.dart';
import '../widgets/scrollable_page.dart';
import '../widgets/group_picker_sheet.dart';
import '../widgets/sheet_helpers.dart';
import '../widgets/tournaq_app_bar.dart';
import 'scramble_king_overview_page.dart';
import 'scorecard_splash_page.dart' show TournaqSplashPage;

class ScrambleKingSetupPage extends StatefulWidget {
  final List<Player> existingPlayers;
  final List<Group> existingGroups;
  final void Function(ScrambleKingTournament) onCreated;
  final Player Function(String name) onCreatePlayer;

  const ScrambleKingSetupPage({
    super.key,
    required this.existingPlayers,
    required this.existingGroups,
    required this.onCreated,
    required this.onCreatePlayer,
  });

  @override
  State<ScrambleKingSetupPage> createState() => _ScrambleKingSetupPageState();
}

class _ScrambleKingSetupPageState extends State<ScrambleKingSetupPage> {
  // ── Config ────────────────────────────────────────────────────────────────
  int _targetPlayerCount = 16;
  int _rounds = 6;
  int _matchMinutes = 12;
  int _courtCount = 2;
  int _breakMinutes = 2;
  int _strikePoints = 5;
  ScrambleKingAssignmentMode _assignmentMode = ScrambleKingAssignmentMode.manual;
  ScrambleKingOddPlayerMode _oddPlayerMode = ScrambleKingOddPlayerMode.placeholder;
  bool _paceAlertsEnabled = false;

  late final TextEditingController _targetPlayerCtrl;
  late final TextEditingController _roundsCtrl;
  late final TextEditingController _matchMinCtrl;
  late final TextEditingController _courtCtrl;
  late final TextEditingController _breakMinCtrl;
  late final TextEditingController _strikeCtrl;

  // ── Start time ────────────────────────────────────────────────────────────
  bool _startIsNow = true;
  late TimeOfDay _startTime;

  final _nameCtrl = TextEditingController();

  final List<ScrambleKingPlayer> _players = [];
  final _playerNameCtrl = TextEditingController();
  final _playerSearchCtrl = TextEditingController();

  static final _rng = Random();
  static const _nameTemplates = [
    ('Scramble', 'Crown'),
    ('Royal', 'Mixer'),
    ('Court', 'Kings'),
    ('Shuffle', 'Throne'),
    ('Golden', 'Rally'),
    ('Wild', 'Reign'),
    ('Sunday', 'Scramble'),
    ('Electric', 'Kingdom'),
    ('Friday', 'Rumble'),
    ('Neon', 'Court'),
  ];

  @override
  void initState() {
    super.initState();
    _startTime = TimeOfDay.now();
    _targetPlayerCtrl = TextEditingController(text: '$_targetPlayerCount');
    _roundsCtrl = TextEditingController(text: '$_rounds');
    _matchMinCtrl = TextEditingController(text: '$_matchMinutes');
    _courtCtrl = TextEditingController(text: '$_courtCount');
    _breakMinCtrl = TextEditingController(text: '$_breakMinutes');
    _strikeCtrl = TextEditingController(text: '$_strikePoints');
    _nameCtrl.text = _randomName();
  }

  @override
  void dispose() {
    _targetPlayerCtrl.dispose();
    _roundsCtrl.dispose();
    _matchMinCtrl.dispose();
    _courtCtrl.dispose();
    _breakMinCtrl.dispose();
    _strikeCtrl.dispose();
    _nameCtrl.dispose();
    _playerNameCtrl.dispose();
    _playerSearchCtrl.dispose();
    super.dispose();
  }

  String _randomName() {
    final t = _nameTemplates[_rng.nextInt(_nameTemplates.length)];
    return '${t.$1} ${t.$2}';
  }

  Duration get _matchDuration => Duration(minutes: _matchMinutes);
  Duration get _breakDuration => Duration(minutes: _breakMinutes);

  TimeOfDay _resolveStart() => _startIsNow ? TimeOfDay.now() : _startTime;

  TimeOfDay _addMinutesToTime(TimeOfDay t, int minutes) {
    final total = t.hour * 60 + t.minute + minutes;
    return TimeOfDay(hour: (total ~/ 60) % 24, minute: total % 60);
  }

  String _fmtTod(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  DateTime _resolveStartDateTime() {
    if (_startIsNow) return DateTime.now();
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, _startTime.hour, _startTime.minute);
  }

  Future<void> _pickStartTime() async {
    final picked = await showTimePicker(context: context, initialTime: _resolveStart());
    if (picked == null) return;
    setState(() {
      _startTime = picked;
      _startIsNow = false;
    });
  }

  List<ScrambleSuggestion> get _suggestions => ScrambleKingService.validate(
        playerCount: _targetPlayerCount,
        courtCount: _courtCount,
        roundCount: _rounds,
        matchDuration: _matchDuration,
      );

  bool get _canCreate =>
      _nameCtrl.text.trim().isNotEmpty &&
      _matchMinutes > 0 &&
      _rounds > 0 &&
      _players.length == _targetPlayerCount &&
      !_suggestions.any((s) => s.isBlocking);

  void _create() {
    if (!_canCreate) return;
    final tournament = ScrambleKingService.buildTournament(
      name: _nameCtrl.text.trim(),
      roundCount: _rounds,
      matchDuration: _matchDuration,
      breakDuration: _breakDuration,
      courtCount: _courtCount,
      strikePoints: _strikePoints,
      assignmentMode: _assignmentMode,
      oddPlayerMode: _oddPlayerMode,
      players: List.from(_players),
      startTime: _resolveStartDateTime(),
      paceAlertsEnabled: _paceAlertsEnabled,
    );
    widget.onCreated(tournament);
    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (_) => TournaqSplashPage(
        destination: ScrambleKingOverviewPage(
          tournament: tournament,
          existingPlayers: widget.existingPlayers,
          existingGroups: widget.existingGroups,
          onChanged: widget.onCreated,
          onCreatePlayer: widget.onCreatePlayer,
        ),
      ),
    ));
  }

  // ── Players summary card ─────────────────────────────────────────────────

  Widget _buildPlayersSummaryCard() {
    final count = _players.length;
    final target = _targetPlayerCount;
    final exact = count == target;
    final hasAny = count > 0;

    final borderColor = hasAny && !exact
        ? Colors.red.shade300
        : exact
            ? AppColors.olive
            : Colors.grey.shade300;
    final bgColor = hasAny && !exact
        ? Colors.red.shade50
        : exact
            ? AppColors.oliveLight
            : Colors.grey.shade50;
    final iconColor = hasAny && !exact
        ? Colors.red.shade600
        : exact
            ? AppColors.olive
            : Colors.black38;
    final textColor = hasAny && !exact
        ? Colors.red.shade700
        : exact
            ? AppColors.olive
            : Colors.black38;

    final l10n = AppLocalizations.of(context)!;
    return InkWell(
      onTap: _showPlayersSheet,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: borderColor, width: exact ? 1.5 : 1.0),
          borderRadius: BorderRadius.circular(12),
          color: bgColor,
        ),
        child: Row(
          children: [
            Icon(Icons.group_rounded, color: iconColor, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: count == 0
                  ? Text(l10n.doghouseTapToAddPlayers,
                      style: const TextStyle(color: Colors.black38, fontSize: 13))
                  : Text(
                      l10n.setupPlayersOf(count, target),
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: textColor,
                      ),
                    ),
            ),
            Icon(
              count == 0 ? Icons.add_circle_outline_rounded : Icons.edit_rounded,
              color: iconColor,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  // ── Players sheet ─────────────────────────────────────────────────────────

  void _showPlayersSheet() {
    final l10n = AppLocalizations.of(context)!;
    _playerSearchCtrl.clear();
    var createExpanded = false;
    var existingExpanded = false;
    var addedExpanded = false;
    String? selectedGroupId;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final query = _playerSearchCtrl.text.toLowerCase();
          final allExisting = widget.existingPlayers
              .where((u) => !_players.any((p) => p.appUserId == u.id))
              .toList();
          final relevantGroups = widget.existingGroups
              .where((c) => widget.existingPlayers.any((u) => c.playerIds.contains(u.id)))
              .toList();
          final filteredExisting = allExisting.where((u) {
            final matchesGroup = selectedGroupId == null ||
                widget.existingGroups.any((c) =>
                    c.id == selectedGroupId && c.playerIds.contains(u.id));
            final matchesQuery =
                query.isEmpty || u.name.toLowerCase().contains(query);
            return matchesGroup && matchesQuery;
          }).toList();

          void rebuild() {
            setSheetState(() {});
            setState(() {});
          }

          Future<void> addByName(String name) async {
            final trimmed = name.trim();
            if (trimmed.isEmpty) return;
            if (_players.any((p) => p.name.toLowerCase() == trimmed.toLowerCase())) {
              final proceed = await showDialog<bool>(
                context: ctx,
                builder: (dCtx) => AlertDialog(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  title: Text(l10n.setupDuplicateNameTitle,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  content: Text(l10n.setupDuplicateNameBody(trimmed),
                      style: const TextStyle(fontSize: 14, color: Colors.black54)),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.of(dCtx).pop(false),
                        child: Text(l10n.btnCancel)),
                    ElevatedButton(
                        onPressed: () => Navigator.of(dCtx).pop(true),
                        child: Text(l10n.btnAddAnyway)),
                  ],
                ),
              );
              if (proceed != true) return;
            }
            final newPlayer = widget.onCreatePlayer(trimmed);
            _players.add(ScrambleKingPlayer(
              id: ScrambleKingPlayer.generateId(),
              name: trimmed,
              source: ScrambleKingPlayerSource.existing,
              appUserId: newPlayer.id,
            ));
            _playerNameCtrl.clear();
            rebuild();
          }

          void addExisting(String appUserId, String name) {
            if (_players.any((p) => p.appUserId == appUserId)) return;
            _players.add(ScrambleKingPlayer(
              id: ScrambleKingPlayer.generateId(),
              name: name,
              source: ScrambleKingPlayerSource.existing,
              appUserId: appUserId,
            ));
            rebuild();
          }

          void fillRandom() {
            final needed = _targetPlayerCount - _players.length;
            if (needed <= 0) return;
            _players.addAll(ScrambleKingService.generateRandomPlayers(needed));
            rebuild();
          }

          void remove(int i) {
            _players.removeAt(i);
            rebuild();
          }

          Future<void> clearAll() async {
            final confirmed = await showDialog<bool>(
              context: ctx,
              builder: (dCtx) => AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                title: Text(l10n.doghouseRemoveAllTitle,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                content: Text(l10n.doghouseRemoveAllBody,
                    style: const TextStyle(fontSize: 14, color: Colors.black54)),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.of(dCtx).pop(false),
                      child: Text(l10n.btnCancel)),
                  TextButton(
                    onPressed: () => Navigator.of(dCtx).pop(true),
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                    child: Text(l10n.doghouseRemoveAll),
                  ),
                ],
              ),
            );
            if (confirmed == true) {
              _players.clear();
              rebuild();
            }
          }

          Widget sectionHeader(
            String title,
            bool expanded,
            VoidCallback onToggle, {
            Widget? trailing,
          }) =>
              InkWell(
                onTap: onToggle,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    children: [
                      Text(title,
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w700, color: Colors.black87)),
                      const Spacer(),
                      if (trailing case final t?) t,
                      Icon(
                        expanded
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        size: 20,
                        color: Colors.black45,
                      ),
                    ],
                  ),
                ),
              );

          return TournaQSheet(
            body: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Text(l10n.setupSectionPlayers,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                      const Spacer(),
                      if (_players.isNotEmpty)
                        TextButton(
                          onPressed: clearAll,
                          style: TextButton.styleFrom(
                              foregroundColor: Colors.red,
                              padding: const EdgeInsets.symmetric(horizontal: 8)),
                          child: Text(l10n.doghouseClearAll, style: const TextStyle(fontSize: 13)),
                        ),
                      Text('${_players.length} / $_targetPlayerCount',
                          style: const TextStyle(color: Colors.black45, fontSize: 13)),
                    ],
                  ),
                  const Divider(height: 16),
                  sectionHeader(
                    l10n.setupSectionCreatePlayer,
                    createExpanded,
                    () => setSheetState(() => createExpanded = !createExpanded),
                  ),
                  if (createExpanded) ...[
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _playerNameCtrl,
                            textCapitalization: TextCapitalization.words,
                            decoration: _inputDecoration(hint: l10n.setupPlayerNameHint),
                            onSubmitted: addByName,
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () => addByName(_playerNameCtrl.text),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.olive,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text(l10n.btnAdd),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                  const Divider(height: 8),
                  sectionHeader(
                    l10n.setupAddExistingPlayers(allExisting.length),
                    existingExpanded,
                    () => setSheetState(() => existingExpanded = !existingExpanded),
                  ),
                  if (existingExpanded) ...[
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(children: [
                        if (relevantGroups.isNotEmpty)
                          GestureDetector(
                            onTap: () async {
                              final picked = await showModalBottomSheet<String>(
                                context: ctx,
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                                builder: (_) => GroupPickerSheet(
                                  groups: relevantGroups,
                                  selectedId: selectedGroupId,
                                ),
                              );
                              if (picked != null) {
                                setSheetState(
                                    () => selectedGroupId = picked.isEmpty ? null : picked);
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                              decoration: BoxDecoration(
                                color: selectedGroupId != null
                                    ? AppColors.goldCream
                                    : Colors.grey.shade50,
                                borderRadius: const BorderRadius.horizontal(left: Radius.circular(11)),
                              ),
                              child: Row(mainAxisSize: MainAxisSize.min, children: [
                                Icon(Icons.home_rounded,
                                    size: 14,
                                    color: selectedGroupId != null
                                        ? AppColors.goldDark
                                        : Colors.black45),
                                const SizedBox(width: 4),
                                Text(
                                  selectedGroupId == null
                                      ? 'Group'
                                      : relevantGroups.firstWhere((c) => c.id == selectedGroupId).name,
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: selectedGroupId != null
                                          ? AppColors.goldDark
                                          : Colors.black45),
                                ),
                                const SizedBox(width: 2),
                                Icon(Icons.arrow_drop_down_rounded,
                                    size: 16,
                                    color: selectedGroupId != null
                                        ? AppColors.goldDark
                                        : Colors.black45),
                              ]),
                            ),
                          ),
                        if (relevantGroups.isNotEmpty)
                          Container(width: 1, height: 36, color: Colors.grey.shade200),
                        Expanded(
                          child: TextField(
                            controller: _playerSearchCtrl,
                            decoration: InputDecoration(
                              hintText: l10n.setupSearchPlayersHint,
                              isDense: true,
                              prefixIcon: const Icon(Icons.search_rounded, size: 18, color: Colors.black45),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
                            ),
                            onChanged: (_) => setSheetState(() {}),
                          ),
                        ),
                      ]),
                    ),
                    const SizedBox(height: 6),
                    if (filteredExisting.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(l10n.doghouseNoPlayersMatch,
                            style: const TextStyle(color: Colors.black38, fontSize: 13)),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: filteredExisting.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (_, i) {
                          final u = filteredExisting[i];
                          return ListTile(
                            dense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                            title: Text(u.name, style: const TextStyle(fontSize: 13)),
                            trailing: IconButton(
                              icon: const Icon(Icons.add_circle_outline_rounded,
                                  size: 20, color: AppColors.olive),
                              onPressed: () => addExisting(u.id, u.name),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          );
                        },
                      ),
                    const SizedBox(height: 8),
                  ],
                  const Divider(height: 8),
                  sectionHeader(
                    l10n.doghouseAddedCount(_players.length, _targetPlayerCount),
                    addedExpanded,
                    () => setSheetState(() => addedExpanded = !addedExpanded),
                    trailing: _players.length < _targetPlayerCount
                        ? TextButton.icon(
                            onPressed: fillRandom,
                            icon: const Icon(Icons.shuffle_rounded, size: 14),
                            label: Text(
                              l10n.doghouseFillNRandom(_targetPlayerCount - _players.length),
                              style: const TextStyle(fontSize: 12),
                            ),
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.olive,
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                            ),
                          )
                        : null,
                  ),
                  if (addedExpanded) ...[
                    if (_players.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(l10n.doghouseSetupNoPlayers,
                            style: const TextStyle(color: Colors.black38, fontSize: 13)),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _players.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 4),
                        itemBuilder: (_, i) {
                          final p = _players[i];
                          return ListTile(
                            dense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: BorderSide(color: Colors.grey.shade200),
                            ),
                            leading: CircleAvatar(
                              radius: 14,
                              backgroundColor: _sourceColor(p.source),
                              child: Text(
                                p.name.isNotEmpty ? p.name[0].toUpperCase() : '?',
                                style: const TextStyle(
                                    fontSize: 11, color: Colors.white, fontWeight: FontWeight.w700),
                              ),
                            ),
                            title: Text(p.name, style: const TextStyle(fontSize: 13)),
                            subtitle: Text(_sourceLabel(p.source),
                                style: const TextStyle(fontSize: 10, color: Colors.black38)),
                            trailing: IconButton(
                              icon: const Icon(Icons.close_rounded, size: 16, color: Colors.black38),
                              onPressed: () => remove(i),
                            ),
                          );
                        },
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

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final suggestions = _suggestions;
    final canCreate = _canCreate;

    return Scaffold(
      appBar: TournaQAppBar(
          title: l10n.modeScrambleKingName, subtitle: l10n.doghouseNewTournament),
      body: ScrollablePage(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _sectionHeader(l10n.doghouseTournamentSetup, Icons.tune_rounded),
            const SizedBox(height: 14),

            // Row 1 — target players / rounds
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _comboField(
                    label: l10n.setupTargetPlayers,
                    ctrl: _targetPlayerCtrl,
                    presets: const [8, 12, 16, 20, 24, 32, 48],
                    onParsed: (v) => _targetPlayerCount = v.clamp(4, 128),
                    helpText: l10n.scrambleKingSetupPlayersHelp,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _comboField(
                    label: l10n.setupRoundsLabel,
                    ctrl: _roundsCtrl,
                    presets: const [3, 4, 5, 6, 8, 10, 12],
                    onParsed: (v) => _rounds = v.clamp(1, 999),
                    caption: '= ${_matchMinutes + _breakMinutes} min/round',
                    helpText: l10n.scrambleKingSetupRoundsHelp,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Row 2 — round duration / break between rounds (durations together)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _comboField(
                    label: l10n.setupMatchDuration,
                    ctrl: _matchMinCtrl,
                    presets: const [8, 10, 12, 15, 20, 25, 30],
                    onParsed: (v) => _matchMinutes = v.clamp(1, 999),
                    unit: 'min',
                    helpText: l10n.scrambleKingSetupDurationHelp,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _comboField(
                    label: l10n.setupBreakBetweenRounds,
                    ctrl: _breakMinCtrl,
                    presets: const [0, 2, 3, 5, 7, 10],
                    onParsed: (v) => _breakMinutes = v.clamp(0, 999),
                    unit: 'min',
                    helpText: l10n.setupBreakBetweenRounds,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Row 3 — courts / strike points
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _comboField(
                    label: l10n.setupCourts,
                    ctrl: _courtCtrl,
                    presets: const [1, 2, 3, 4, 5, 6, 8],
                    onParsed: (v) => _courtCount = v.clamp(1, 8),
                    helpText: l10n.scrambleKingSetupCourtsHelp,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _comboField(
                    label: l10n.kotcSetupStrikeLabel,
                    ctrl: _strikeCtrl,
                    presets: const [0, 3, 5, 7, 10, 15, 21],
                    onParsed: (v) => _strikePoints = v.clamp(0, 999),
                    helpText: l10n.kotcSetupStrikeHelp,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Row 4 — assignment mode / odd player mode
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _assignmentModeField()),
                const SizedBox(width: 12),
                Expanded(child: _oddPlayerModeField()),
              ],
            ),
            const SizedBox(height: 4),

            // Pace alerts toggle (mirrors Social Scramble)
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _paceAlertsEnabled,
              onChanged: (v) => setState(() => _paceAlertsEnabled = v),
              activeThumbColor: AppColors.gold,
              title: Text(l10n.timelinePaceAlertsTitle,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              subtitle: Text(l10n.timelinePaceAlertsSubtitle,
                  style: const TextStyle(fontSize: 12, color: Colors.black54)),
            ),
            const SizedBox(height: 4),

            // Schedule preview (live)
            _schedulePreview(),

            // ── Suggestions ───────────────────────────────────────────────────
            if (suggestions.isNotEmpty) ...[
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),
              _sectionHeader(l10n.setupSuggestions, Icons.lightbulb_outline_rounded),
              const SizedBox(height: 12),
              ...suggestions.map((s) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: ScrambleSuggestionCard(suggestion: s),
                  )),
            ],

            // ── Players ───────────────────────────────────────────────────────
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            _sectionHeader(l10n.setupSectionPlayers, Icons.group_rounded),
            const SizedBox(height: 12),
            _buildPlayersSummaryCard(),

            // ── Name (bottom) ─────────────────────────────────────────────────
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            _fieldLabel(l10n.doghouseTournamentName),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _nameCtrl,
                    textCapitalization: TextCapitalization.words,
                    decoration: _inputDecoration(),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => setState(() => _nameCtrl.text = _randomName()),
                  icon: const Icon(Icons.refresh_rounded),
                  tooltip: 'Suggest name',
                ),
              ],
            ),

            // ── Status + Create button ────────────────────────────────────────
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Icon(
                    canCreate ? Icons.check_circle_rounded : Icons.error_outline_rounded,
                    color: canCreate ? AppColors.olive : Colors.red.shade600,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    canCreate ? l10n.doghouseSetupGood : l10n.doghouseSetupIncomplete,
                    style: TextStyle(
                      color: canCreate ? AppColors.olive : Colors.red.shade600,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: canCreate ? _create : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.olive,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                l10n.btnCreateTournament,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Schedule Preview ─────────────────────────────────────────────────────

  Widget _schedulePreview() {
    final roundMin = _matchMinutes + _breakMinutes;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.oliveLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Builder(builder: (ctx) {
        final l10n = AppLocalizations.of(ctx)!;
        final scheduledMins = _rounds * roundMin;
        final h = scheduledMins ~/ 60;
        final m = scheduledMins % 60;
        final durationStr = h > 0 ? '${h}h ${m}m' : '${m}m';
        final endTime = _addMinutesToTime(_resolveStart(), scheduledMins);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.setupSchedulePreview,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.olive),
            ),
            const SizedBox(height: 4),
            _buildStartAndEndRow(l10n, endTime),
            const SizedBox(height: 4),
            const Divider(height: 1, thickness: 0.5, color: AppColors.gold),
            const SizedBox(height: 6),
            _previewRow(l10n.setupRoundDuration,
                '${_matchMinutes}m match + ${_breakMinutes}m break = ${roundMin}m'),
            _previewRow(l10n.setupRoundsLabel, '$_rounds'),
            _previewRow(l10n.setupScheduledDuration, durationStr),
          ],
        );
      }),
    );
  }

  Widget _buildStartAndEndRow(AppLocalizations l10n, TimeOfDay endTime) {
    final startText = _startIsNow ? 'Now' : _fmtTod(_startTime);
    return InkWell(
      onTap: _pickStartTime,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    const Icon(Icons.play_circle_outline_rounded, size: 13, color: Colors.black38),
                    const SizedBox(width: 5),
                    Text(l10n.timelineStart(startText),
                        style: const TextStyle(fontSize: 12, color: Colors.black54)),
                  ]),
                  const SizedBox(height: 2),
                  Row(children: [
                    const Icon(Icons.flag_outlined, size: 13, color: Colors.black38),
                    const SizedBox(width: 5),
                    Text(l10n.timelinePredictedEnd(_fmtTod(endTime)),
                        style: const TextStyle(fontSize: 12, color: Colors.black54)),
                  ]),
                ],
              ),
            ),
            const Icon(Icons.edit_rounded, size: 14, color: AppColors.olive),
          ],
        ),
      ),
    );
  }

  Widget _previewRow(String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 3),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.black54)),
            Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
      );

  // ── Combo field ───────────────────────────────────────────────────────────

  Widget _comboField({
    required String label,
    required TextEditingController ctrl,
    required List<int> presets,
    required void Function(int) onParsed,
    String? unit,
    String? helpText,
    String? caption,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _fieldLabel(label, help: helpText),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            suffix: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (unit != null)
                  Text(unit, style: const TextStyle(fontSize: 13, color: Colors.black45)),
                PopupMenuButton<int>(
                  tooltip: 'Quick pick',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onSelected: (v) => setState(() {
                    ctrl.text = '$v';
                    onParsed(v);
                  }),
                  itemBuilder: (_) => presets
                      .map((p) => PopupMenuItem<int>(
                            value: p,
                            child: Text(unit != null ? '$p $unit' : '$p'),
                          ))
                      .toList(),
                  child: const Icon(Icons.arrow_drop_down, size: 18, color: Colors.black45),
                ),
              ],
            ),
          ),
          onChanged: (s) {
            final v = int.tryParse(s);
            if (v != null) setState(() => onParsed(v));
          },
        ),
        if (caption != null) ...[
          const SizedBox(height: 4),
          Text(caption, style: const TextStyle(fontSize: 11, color: Colors.black45)),
        ],
      ],
    );
  }

  Widget _assignmentModeField() {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _fieldLabel(l10n.kotcSetupAssignmentLabel, help: l10n.kotcSetupAssignmentHelp),
        const SizedBox(height: 6),
        DropdownButtonFormField<ScrambleKingAssignmentMode>(
          initialValue: _assignmentMode,
          isDense: true,
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
          items: [
            DropdownMenuItem(
              value: ScrambleKingAssignmentMode.manual,
              child: Text(l10n.doghouseAssignmentManual),
            ),
            DropdownMenuItem(
              value: ScrambleKingAssignmentMode.automated,
              child: Text(l10n.doghouseAssignmentAutomated),
            ),
            DropdownMenuItem(
              value: ScrambleKingAssignmentMode.automatedAllPlay,
              child: Text(l10n.setupFormatAutoAllplay),
            ),
          ],
          onChanged: (v) {
            if (v != null) setState(() => _assignmentMode = v);
          },
        ),
      ],
    );
  }

  Widget _oddPlayerModeField() {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _fieldLabel(l10n.scrambleKingOddPlayerLabel, help: l10n.scrambleKingOddPlayerHelp),
        const SizedBox(height: 6),
        DropdownButtonFormField<ScrambleKingOddPlayerMode>(
          initialValue: _oddPlayerMode,
          isDense: true,
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
          items: [
            DropdownMenuItem(
              value: ScrambleKingOddPlayerMode.placeholder,
              child: Text(l10n.scrambleKingOddPlayerPlaceholderLabel),
            ),
            DropdownMenuItem(
              value: ScrambleKingOddPlayerMode.jumper,
              child: Text(l10n.scrambleKingOddPlayerJumperLabel),
            ),
          ],
          onChanged: (v) {
            if (v != null) setState(() => _oddPlayerMode = v);
          },
        ),
      ],
    );
  }

  // ── Shared helpers ────────────────────────────────────────────────────────

  Widget _sectionHeader(String title, IconData icon) => Row(
        children: [
          Icon(icon, size: 15, color: AppColors.olive),
          const SizedBox(width: 6),
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.olive,
              letterSpacing: 0.4,
            ),
          ),
        ],
      );

  void _showFieldHelp(String title, String body) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
        actionsPadding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        title: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
        content:
            Text(body, style: const TextStyle(fontSize: 14, color: Colors.black54, height: 1.5)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(AppLocalizations.of(context)!.btnGotIt),
          ),
        ],
      ),
    );
  }

  Widget _fieldLabel(String text, {String? help}) {
    final label = Text(
      text,
      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black54),
    );
    if (help == null) return label;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        label,
        const SizedBox(width: 4),
        GestureDetector(
          onTap: () => _showFieldHelp(text, help),
          child: const Icon(Icons.info_outline_rounded, size: 14, color: Colors.black38),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration({String? hint}) => InputDecoration(
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      );

  Color _sourceColor(ScrambleKingPlayerSource s) => switch (s) {
        ScrambleKingPlayerSource.existing => AppColors.olive,
        ScrambleKingPlayerSource.created => AppColors.goldDark,
        ScrambleKingPlayerSource.random => Colors.blueGrey,
      };

  String _sourceLabel(ScrambleKingPlayerSource s) {
    final l10n = AppLocalizations.of(context)!;
    return switch (s) {
      ScrambleKingPlayerSource.existing => l10n.doghouseSourceExisting,
      ScrambleKingPlayerSource.created => l10n.doghouseSourceNew,
      ScrambleKingPlayerSource.random => l10n.doghouseSourceRandom,
    };
  }
}
