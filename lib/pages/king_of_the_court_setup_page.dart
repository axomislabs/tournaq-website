import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../app/app_colors.dart';
import '../l10n/app_localizations.dart';
import '../models/group.dart';
import '../models/king_of_the_court_tournament.dart';
import '../services/scramble_service.dart';
import '../utils/session_title_generator.dart';
import '../models/player.dart';
import '../widgets/group_picker_sheet.dart';
import '../widgets/scrollable_page.dart';
import '../widgets/sheet_helpers.dart';
import '../widgets/tournaq_app_bar.dart';
import 'king_of_the_court_scoreboard_page.dart';
import 'scorecard_splash_page.dart' show TournaqSplashPage;

/// Below this many players, Auto-Allplay has no real spare capacity: Court +
/// Challenger always reserve `playersPerTeam * 2` players, and the admin
/// needs at least one more full team's worth of room beyond that (plus
/// themselves) to hand off duty without it looping straight back. Unlike
/// Scramble King, Up Next here is a soft/recomputed suggestion rather than a
/// third reserved slot, so the threshold scales with team size instead of
/// being a fixed number.
int _minAutoAllplayPlayers(int playersPerTeam) => playersPerTeam * 3 + 1;

class KingOfTheCourtSetupPage extends StatefulWidget {
  final List<Player> existingPlayers;
  final List<Group> existingGroups;
  final void Function(KingOfTheCourtTournament) onCreated;
  final Player Function(String name) onCreatePlayer;

  const KingOfTheCourtSetupPage({
    super.key,
    required this.existingPlayers,
    required this.existingGroups,
    required this.onCreated,
    required this.onCreatePlayer,
  });

  @override
  State<KingOfTheCourtSetupPage> createState() =>
      _KingOfTheCourtSetupPageState();
}

class _KingOfTheCourtSetupPageState extends State<KingOfTheCourtSetupPage> {
  // ── Config ints ──────────────────────────────────────────────────────────────
  int _targetPlayerCount                 = 8;
  int _totalMinutes                      = 60;
  int _playersPerTeam                    = 2;
  int _strikePoints                      = 5;
  KotcAssignmentMode _assignmentMode     = KotcAssignmentMode.manual;

  // ── Config controllers ───────────────────────────────────────────────────────
  late final TextEditingController _playerCountCtrl;
  late final TextEditingController _totalMinCtrl;
  late final TextEditingController _strikeCtrl;

  // ── Name ─────────────────────────────────────────────────────────────────────
  final _nameCtrl = TextEditingController();

  // ── Players ───────────────────────────────────────────────────────────────────
  final List<KotcPlayer> _players       = [];
  final _playerNameCtrl   = TextEditingController();
  final _playerSearchCtrl = TextEditingController();


  @override
  void initState() {
    super.initState();
    _playerCountCtrl = TextEditingController(text: '$_targetPlayerCount');
    _totalMinCtrl    = TextEditingController(text: '$_totalMinutes');
    _strikeCtrl      = TextEditingController(text: '$_strikePoints');
    _nameCtrl.text   = _randomName();
  }

  @override
  void dispose() {
    _playerCountCtrl.dispose();
    _totalMinCtrl.dispose();
    _strikeCtrl.dispose();
    _nameCtrl.dispose();
    _playerNameCtrl.dispose();
    _playerSearchCtrl.dispose();
    super.dispose();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────────

  String _randomName() {
    return SessionTitleGenerator.random(SessionTitleTheme.kingOfCourt);
  }

  int get _minPlayers => _playersPerTeam * 2; // always 1 court

  bool get _canCreate =>
      _nameCtrl.text.trim().isNotEmpty &&
      _totalMinutes > 0 &&
      _players.length >= _minPlayers;

  void _create() {
    if (!_canCreate) return;
    final session = KingOfTheCourtTournament(
      id:             KingOfTheCourtTournament.generateId(),
      name:           _nameCtrl.text.trim(),
      totalTime:      Duration(minutes: _totalMinutes),
      playersPerTeam:  _playersPerTeam,
      courtCount:      1,
      strikePoints:    _strikePoints,
      assignmentMode:  _assignmentMode,
      status:          KotcTournamentStatus.setup,
      players:        List.from(_players),
      games:          [],
      createdAt:      DateTime.now(),
    );
    widget.onCreated(session);
    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (_) => TournaqSplashPage(
        destination: KingOfTheCourtScoreboardPage(
          tournament:      session,
          existingPlayers: widget.existingPlayers,
          onChanged:       widget.onCreated,
          onCreatePlayer:  widget.onCreatePlayer,
        ),
      ),
    ));
  }

  // ── Players summary card ──────────────────────────────────────────────────────

  Widget _buildPlayersSummaryCard() {
    final count  = _players.length;
    final min    = _minPlayers;
    final enough = count >= min;
    final hasAny = count > 0;

    final borderColor = hasAny && !enough
        ? Colors.red.shade300
        : enough
            ? AppColors.olive
            : Colors.grey.shade300;
    final bgColor = hasAny && !enough
        ? Colors.red.shade50
        : enough
            ? AppColors.oliveLight
            : Colors.grey.shade50;
    final iconColor = hasAny && !enough
        ? Colors.red.shade600
        : enough
            ? AppColors.olive
            : Colors.black38;
    final textColor = hasAny && !enough
        ? Colors.red.shade700
        : enough
            ? AppColors.olive
            : Colors.black38;

    return InkWell(
      onTap: _showPlayersSheet,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: borderColor, width: enough ? 1.5 : 1.0),
          borderRadius: BorderRadius.circular(12),
          color: bgColor,
        ),
        child: Row(
          children: [
            Icon(Icons.group_rounded, color: iconColor, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: count == 0
                  ? Text(AppLocalizations.of(context)!.doghouseTapToAddPlayers,
                      style: const TextStyle(color: Colors.black38, fontSize: 13))
                  : Text(
                      enough
                          ? AppLocalizations.of(context)!.doghouseNPlayersAdded(count)
                          : AppLocalizations.of(context)!.doghouseNeedAtLeastN(count, min),
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: textColor,
                      ),
                    ),
            ),
            Icon(
              count == 0
                  ? Icons.add_circle_outline_rounded
                  : Icons.edit_rounded,
              color: iconColor,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  // ── Players sheet ─────────────────────────────────────────────────────────────

  void _showPlayersSheet() {
    final l10n = AppLocalizations.of(context)!;
    _playerSearchCtrl.clear();
    var createExpanded   = false;
    var existingExpanded = false;
    var addedExpanded    = false;
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
            final matchesGroup = selectedGroupId == null || widget.existingGroups.any((c) => c.id == selectedGroupId && c.playerIds.contains(u.id));
            final matchesQuery = query.isEmpty || u.name.toLowerCase().contains(query);
            return matchesGroup && matchesQuery;
          }).toList();

          void rebuild() {
            setSheetState(() {});
            setState(() {});
          }

          Future<void> addByName(String name) async {
            final trimmed = name.trim();
            if (trimmed.isEmpty) return;
            if (_players.any((p) =>
                p.name.toLowerCase() == trimmed.toLowerCase())) {
              final proceed = await showDialog<bool>(
                context: ctx,
                builder: (dCtx) => AlertDialog(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  title: Text(l10n.setupDuplicateNameTitle,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700)),
                  content: Text(
                    l10n.setupDuplicateNameBody(trimmed),
                    style: const TextStyle(
                        fontSize: 14, color: Colors.black54),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(dCtx).pop(false),
                      child: Text(l10n.btnCancel),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.of(dCtx).pop(true),
                      child: Text(l10n.btnAddAnyway),
                    ),
                  ],
                ),
              );
              if (proceed != true) return;
            }
            final newPlayer = widget.onCreatePlayer(trimmed);
            _players.add(KotcPlayer(
              id:        KotcPlayer.generateId(),
              name:      trimmed,
              source:    KotcPlayerSource.existing,
              appUserId: newPlayer.id,
            ));
            _playerNameCtrl.clear();
            rebuild();
          }

          void addExisting(String appUserId, String name) {
            if (_players.any((p) => p.appUserId == appUserId)) return;
            _players.add(KotcPlayer(
              id:        KotcPlayer.generateId(),
              name:      name,
              source:    KotcPlayerSource.existing,
              appUserId: appUserId,
            ));
            rebuild();
          }

          void fillRandom() {
            final needed = _targetPlayerCount - _players.length;
            if (needed <= 0) return;
            final generated = ScrambleService.generateRandomPlayers(
              needed,
              existing: _players.map((p) => p.name).toSet(),
            );
            for (final p in generated) {
              _players.add(KotcPlayer(
                id:     KotcPlayer.generateId(),
                name:   p.name,
                source: KotcPlayerSource.random,
              ));
            }
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
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                title: Text(l10n.doghouseRemoveAllTitle,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700)),
                content: Text(l10n.doghouseRemoveAllBody,
                    style: const TextStyle(
                        fontSize: 14, color: Colors.black54)),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(dCtx).pop(false),
                    child: Text(l10n.btnCancel),
                  ),
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
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.black87)),
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
                  // ── Main header ─────────────────────────────────────────
                  Row(
                    children: [
                      Text(l10n.setupSectionPlayers,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w800)),
                      const Spacer(),
                      if (_players.isNotEmpty)
                        TextButton(
                          onPressed: clearAll,
                          style: TextButton.styleFrom(
                              foregroundColor: Colors.red,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8)),
                          child: Text(l10n.doghouseClearAll,
                              style: const TextStyle(fontSize: 13)),
                        ),
                      Text(
                        '${_players.length} / $_targetPlayerCount',
                        style: const TextStyle(
                            color: Colors.black45, fontSize: 13),
                      ),
                    ],
                  ),
                  const Divider(height: 16),

                  // ── Create Player ───────────────────────────────────────
                  sectionHeader(
                    l10n.setupSectionCreatePlayer,
                    createExpanded,
                    () => setSheetState(
                        () => createExpanded = !createExpanded),
                  ),
                  if (createExpanded) ...[
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _playerNameCtrl,
                            textCapitalization: TextCapitalization.words,
                            decoration:
                                _inputDecoration(hint: l10n.setupPlayerNameHint),
                            onSubmitted: addByName,
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () =>
                              addByName(_playerNameCtrl.text),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.olive,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text(l10n.btnAdd),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                  const Divider(height: 8),

                  // ── Existing Players ────────────────────────────────────
                  sectionHeader(
                    l10n.setupAddExistingPlayers(allExisting.length),
                    existingExpanded,
                    () => setSheetState(
                        () => existingExpanded = !existingExpanded),
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
                                setSheetState(() => selectedGroupId = picked.isEmpty ? null : picked);
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                              decoration: BoxDecoration(
                                color: selectedGroupId != null ? AppColors.goldCream : Colors.grey.shade50,
                                borderRadius: const BorderRadius.horizontal(left: Radius.circular(11)),
                              ),
                              child: Row(mainAxisSize: MainAxisSize.min, children: [
                                Icon(Icons.home_rounded, size: 14, color: selectedGroupId != null ? AppColors.goldDark : Colors.black45),
                                const SizedBox(width: 4),
                                Text(
                                  selectedGroupId == null ? 'Group' : relevantGroups.firstWhere((c) => c.id == selectedGroupId).name,
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: selectedGroupId != null ? AppColors.goldDark : Colors.black45),
                                ),
                                const SizedBox(width: 2),
                                Icon(Icons.arrow_drop_down_rounded, size: 16, color: selectedGroupId != null ? AppColors.goldDark : Colors.black45),
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
                            style: const TextStyle(
                                color: Colors.black38, fontSize: 13)),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: filteredExisting.length,
                        separatorBuilder: (_, _) =>
                            const Divider(height: 1),
                        itemBuilder: (_, i) {
                          final u = filteredExisting[i];
                          return ListTile(
                            dense: true,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 4),
                            title: Text(u.name,
                                style: const TextStyle(fontSize: 13)),
                            trailing: IconButton(
                              icon: const Icon(
                                  Icons.add_circle_outline_rounded,
                                  size: 20,
                                  color: AppColors.olive),
                              onPressed: () =>
                                  addExisting(u.id, u.name),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          );
                        },
                      ),
                    const SizedBox(height: 8),
                  ],
                  const Divider(height: 8),

                  // ── Added ───────────────────────────────────────────────
                  sectionHeader(
                    l10n.doghouseAddedCount(_players.length, _targetPlayerCount),
                    addedExpanded,
                    () => setSheetState(
                        () => addedExpanded = !addedExpanded),
                    trailing: _players.length < _targetPlayerCount
                        ? TextButton.icon(
                            onPressed: fillRandom,
                            icon: const Icon(Icons.shuffle_rounded,
                                size: 14),
                            label: Text(
                              l10n.doghouseFillNRandom(
                                  (_targetPlayerCount - _players.length).clamp(0, 999)),
                              style: const TextStyle(fontSize: 12),
                            ),
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.olive,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 4),
                            ),
                          )
                        : null,
                  ),
                  if (addedExpanded) ...[
                    if (_players.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(l10n.doghouseSetupNoPlayers,
                            style: const TextStyle(
                                color: Colors.black38, fontSize: 13)),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _players.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: 4),
                        itemBuilder: (_, i) {
                          final p = _players[i];
                          return ListTile(
                            dense: true,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 0),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: BorderSide(
                                  color: Colors.grey.shade200),
                            ),
                            leading: CircleAvatar(
                              radius: 14,
                              backgroundColor: _sourceColor(p.source),
                              child: Text(
                                p.name.isNotEmpty
                                    ? p.name[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700),
                              ),
                            ),
                            title: Text(p.name,
                                style: const TextStyle(fontSize: 13)),
                            subtitle: Text(_sourceLabel(p.source),
                                style: const TextStyle(
                                    fontSize: 10,
                                    color: Colors.black38)),
                            trailing: IconButton(
                              icon: const Icon(Icons.close_rounded,
                                  size: 16, color: Colors.black38),
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

  // ── Build ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l10n      = AppLocalizations.of(context)!;
    final canCreate = _canCreate;

    return Scaffold(
      appBar: TournaQAppBar(
          title: 'King of the Court', subtitle: l10n.doghouseNewTournament),
      body: ScrollablePage(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Config grid ───────────────────────────────────────────────────
            _sectionHeader(l10n.doghouseTournamentSetup, Icons.tune_rounded),
            const SizedBox(height: 14),

            // Row 1 — players / time
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _comboField(
                    label:    l10n.navPlayers,
                    ctrl:     _playerCountCtrl,
                    presets:  [4, 6, 8, 10, 12, 16, 20, 24],
                    onParsed: (v) => _targetPlayerCount = v.clamp(4, 64),
                    helpText: l10n.kotcSetupPlayersHelp,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _comboField(
                    label:    l10n.labelTime,
                    ctrl:     _totalMinCtrl,
                    presets:  [30, 45, 60, 90, 120, 180, 240],
                    onParsed: (v) => _totalMinutes = v.clamp(1, 999),
                    unit:     'min',
                    helpText: l10n.kotcSetupTimeHelp,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Row 2 — style / assignment
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _styleField()),
                const SizedBox(width: 12),
                Expanded(child: _assignmentModeField()),
              ],
            ),
            const SizedBox(height: 14),

            // Row 3 — courts (locked) / strike points
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _lockedCourtsField()),
                const SizedBox(width: 12),
                Expanded(
                  child: _comboField(
                    label:    l10n.kotcSetupStrikeLabel,
                    ctrl:     _strikeCtrl,
                    presets:  [0, 3, 5, 7, 10, 15, 21],
                    onParsed: (v) => _strikePoints = v.clamp(0, 999),
                    helpText: l10n.kotcSetupStrikeHelp,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── Players ───────────────────────────────────────────────────────
            const Divider(),
            const SizedBox(height: 16),
            _sectionHeader(l10n.setupSectionPlayers, Icons.group_rounded),
            const SizedBox(height: 12),
            _buildPlayersSummaryCard(),

            // ── Name ─────────────────────────────────────────────────────────
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
                  onPressed: () =>
                      setState(() => _nameCtrl.text = _randomName()),
                  icon: const Icon(Icons.refresh_rounded),
                  tooltip: 'Suggest name',
                ),
              ],
            ),

            // ── Create ────────────────────────────────────────────────────────
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Icon(
                    canCreate
                        ? Icons.check_circle_rounded
                        : Icons.error_outline_rounded,
                    color: canCreate
                        ? AppColors.olive
                        : Colors.red.shade600,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    canCreate ? l10n.doghouseSetupGood : l10n.doghouseSetupIncomplete,
                    style: TextStyle(
                      color: canCreate
                          ? AppColors.olive
                          : Colors.red.shade600,
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
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                l10n.btnCreateTournament,
                style: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Style dropdown ────────────────────────────────────────────────────────────

  Widget _styleField() {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _fieldLabel(l10n.kotcSetupStyleLabel, help: l10n.kotcSetupStyleHelp),
        const SizedBox(height: 6),
        DropdownButtonFormField<int>(
          initialValue: _playersPerTeam,
          isDense: true,
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
          items: [2, 3, 4, 5, 6]
              .map((n) => DropdownMenuItem(
                    value: n,
                    child: Text('${n}vs$n'),
                  ))
              .toList(),
          onChanged: (v) {
            if (v != null) setState(() => _playersPerTeam = v);
          },
        ),
      ],
    );
  }

  // ── Assignment mode dropdown ──────────────────────────────────────────────────

  Widget _assignmentModeField() {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _fieldLabel(l10n.kotcSetupAssignmentLabel, help: l10n.kotcSetupAssignmentHelp),
        const SizedBox(height: 6),
        DropdownButtonFormField<KotcAssignmentMode>(
          initialValue: _assignmentMode,
          isDense: true,
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
          items: [
            DropdownMenuItem(
              value: KotcAssignmentMode.manual,
              child: Text(AppLocalizations.of(context)!.doghouseAssignmentManual),
            ),
            DropdownMenuItem(
              value: KotcAssignmentMode.automated,
              child: Text(AppLocalizations.of(context)!.doghouseAssignmentAutomated),
            ),
            DropdownMenuItem(
              value: KotcAssignmentMode.automatedAllPlay,
              child: Text(AppLocalizations.of(context)!.setupFormatAutoAllplay),
            ),
          ],
          onChanged: (v) {
            if (v != null) setState(() => _assignmentMode = v);
          },
        ),
        if (_assignmentMode == KotcAssignmentMode.automatedAllPlay &&
            _targetPlayerCount < _minAutoAllplayPlayers(_playersPerTeam)) ...[
          const SizedBox(height: 6),
          _autoAllplayLowPlayersNote(
              l10n, _minAutoAllplayPlayers(_playersPerTeam)),
        ],
      ],
    );
  }

  /// Advisory (non-blocking) note shown once Auto-Allplay is selected with
  /// fewer than [minPlayers] configured — the mode still works below that,
  /// it just leaves the rotating admin with no real spare capacity to hand
  /// off to.
  Widget _autoAllplayLowPlayersNote(AppLocalizations l10n, int minPlayers) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.info_outline_rounded, size: 14, color: Colors.orange.shade800),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            l10n.autoAllplayLowPlayersWarning(minPlayers),
            style: TextStyle(fontSize: 11, color: Colors.orange.shade800),
          ),
        ),
      ],
    );
  }

  // ── Courts field (locked to 1) ────────────────────────────────────────────────

  Widget _lockedCourtsField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              AppLocalizations.of(context)!.setupCourts,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.black54),
            ),
            const SizedBox(width: 4),
            GestureDetector(
              onTap: () => showDialog<void>(
                context: context,
                builder: (ctx) => AlertDialog(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  title: Text(AppLocalizations.of(context)!.setupCourts,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700)),
                  content: Text(
                    AppLocalizations.of(context)!.setupCourtsInfoBody,
                    style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                        height: 1.5),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: Text(AppLocalizations.of(context)!.btnGotIt,
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
              child: const Icon(Icons.info_outline_rounded,
                  size: 14, color: Colors.black38),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          height: 40,
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              const Text('1',
                  style: TextStyle(
                      fontSize: 14,
                      color: Colors.black45,
                      fontWeight: FontWeight.w600)),
              const Spacer(),
              Icon(Icons.lock_outline_rounded,
                  size: 14, color: Colors.grey.shade400),
            ],
          ),
        ),
      ],
    );
  }

  // ── Combo field ───────────────────────────────────────────────────────────────

  Widget _comboField({
    required String label,
    required TextEditingController ctrl,
    required List<int> presets,
    required void Function(int) onParsed,
    String? unit,
    String? helpText,
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
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
            border:
                OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            suffix: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (unit != null)
                  Text(unit,
                      style: const TextStyle(
                          fontSize: 13, color: Colors.black45)),
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
                  child: const Icon(Icons.arrow_drop_down,
                      size: 18, color: Colors.black45),
                ),
              ],
            ),
          ),
          onChanged: (s) {
            final v = int.tryParse(s);
            if (v != null) setState(() => onParsed(v));
          },
        ),
      ],
    );
  }

  // ── Shared helpers ────────────────────────────────────────────────────────────

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
        title: Text(title,
            style: const TextStyle(
                fontSize: 15, fontWeight: FontWeight.w700)),
        content: Text(body,
            style: const TextStyle(
                fontSize: 14, color: Colors.black54, height: 1.5)),
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
      style: const TextStyle(
          fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black54),
    );
    if (help == null) return label;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        label,
        const SizedBox(width: 4),
        GestureDetector(
          onTap: () => _showFieldHelp(text, help),
          child: const Icon(Icons.info_outline_rounded,
              size: 14, color: Colors.black38),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration({String? hint}) => InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      );

  Color _sourceColor(KotcPlayerSource s) => switch (s) {
        KotcPlayerSource.existing => AppColors.olive,
        KotcPlayerSource.created  => AppColors.goldDark,
        KotcPlayerSource.random   => Colors.blueGrey,
      };

  String _sourceLabel(KotcPlayerSource s) {
    final l10n = AppLocalizations.of(context)!;
    return switch (s) {
      KotcPlayerSource.existing => l10n.doghouseSourceExisting,
      KotcPlayerSource.created  => l10n.doghouseSourceNew,
      KotcPlayerSource.random   => l10n.doghouseSourceRandom,
    };
  }
}
