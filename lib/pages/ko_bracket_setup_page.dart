import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../app/app_colors.dart';
import '../models/group.dart';
import '../models/ko_bracket_tournament.dart';
import '../models/player.dart';
import '../models/team.dart';
import '../widgets/group_picker_sheet.dart';
import '../widgets/scrollable_page.dart';
import '../widgets/sheet_helpers.dart';
import '../widgets/tournaq_app_bar.dart';
import 'ko_bracket_bracket_page.dart';

// ── Constants ─────────────────────────────────────────────────────────────────

const _kGold      = AppColors.gold;
const _kGoldDark  = AppColors.goldDark;
const _kGoldCream = AppColors.goldCream;
const _kOlive     = AppColors.olive;

final _rng = Random();

const _teamAdjectives = [
  'Thunder', 'Iron', 'Swift', 'Bold', 'Red', 'Blue', 'Gold', 'Silver',
  'Dark', 'Storm', 'Crimson', 'Blazing', 'Frozen', 'Shadow', 'Solar',
  'Mighty', 'Royal', 'Wild', 'Steel', 'Fire',
];
const _teamNouns = [
  'Hawks', 'Bears', 'Lions', 'Eagles', 'Wolves', 'Panthers', 'Sharks',
  'Tigers', 'Foxes', 'Dragons', 'Cobras', 'Ravens', 'Falcons', 'Jaguars',
  'Vipers', 'Stallions', 'Rhinos', 'Gladiators', 'Titans', 'Strikers',
];

String _pickFunName(Set<String> used) {
  String name;
  var attempts = 0;
  do {
    final adj  = _teamAdjectives[_rng.nextInt(_teamAdjectives.length)];
    final noun = _teamNouns[_rng.nextInt(_teamNouns.length)];
    name = '$adj $noun';
    attempts++;
  } while (used.contains(name) && attempts < 200);
  used.add(name);
  return name;
}

const _nameTemplates = [
  ('Golden', 'Bracket'), ('Iron', 'Fist'),    ('Thunder', 'Cup'),
  ('Steel', 'Cage'),     ('Crown', 'Classic'), ('Champion', 'Cup'),
  ('Elite', 'Eight'),    ('Final', 'Fury'),    ('Blazing', 'Bracket'),
  ('Sunset', 'Showdown'),('Neon', 'Knockout'), ('Wild', 'Card'),
  ('Friday', 'Fight'),   ('Epic', 'Bracket'),  ('Sneaky', 'Semifinal'),
];

// ── Page ──────────────────────────────────────────────────────────────────────

class KoBracketSetupPage extends StatefulWidget {
  final List<Player> existingPlayers;
  final List<Team>   existingTeams;
  final List<Group>   existingGroups;
  final Player Function(String name) onCreatePlayer;
  final String Function(String name, List<String> linkedPlayerIds) onCreateTeam;
  final void Function(KoBracketTournament) onCreated;

  const KoBracketSetupPage({
    super.key,
    required this.existingPlayers,
    required this.existingTeams,
    required this.existingGroups,
    required this.onCreatePlayer,
    required this.onCreateTeam,
    required this.onCreated,
  });

  @override
  State<KoBracketSetupPage> createState() => _KoBracketSetupPageState();
}

class _KoBracketSetupPageState extends State<KoBracketSetupPage> {
  // ── Format ────────────────────────────────────────────────────────────────
  int _teamCount      = 8;
  int _playersPerSide = 2;
  int _courtCount     = 2;

  // ── Mode ──────────────────────────────────────────────────────────────────
  KoBracketGenerationMode _generationMode = KoBracketGenerationMode.random;
  KoOddTeamStrategy       _oddStrategy    = KoOddTeamStrategy.byes;

  // ── Game settings ─────────────────────────────────────────────────────────
  KoRoundFormat _earlyFormat     = const KoRoundFormat(setsPerGame: 1, pointsPerSet: 15);
  KoRoundFormat _finalFormat     = const KoRoundFormat(setsPerGame: 3, pointsPerSet: 21);
  int _finalRoundsCount          = 2;
  int _earlyBreakMinutes         = 0;
  int _finalBreakMinutes         = 0;

  // ── Schedule ──────────────────────────────────────────────────────────────
  DateTime _estimatedStart = DateTime.now().add(const Duration(hours: 1));

  // ── Teams ─────────────────────────────────────────────────────────────────
  List<KoTeam> _teams = [];

  // ── Name ──────────────────────────────────────────────────────────────────
  late final TextEditingController _nameCtrl;
  late final TextEditingController _teamCountCtrl;
  late final TextEditingController _courtCtrl;
  final _newTeamNameCtrl = TextEditingController();
  final _teamSearchCtrl  = TextEditingController();

  @override
  void initState() {
    super.initState();
    _nameCtrl      = TextEditingController(text: _randomName());
    _teamCountCtrl = TextEditingController(text: '$_teamCount');
    _courtCtrl     = TextEditingController(text: '$_courtCount');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _teamCountCtrl.dispose();
    _courtCtrl.dispose();
    _newTeamNameCtrl.dispose();
    _teamSearchCtrl.dispose();
    super.dispose();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String _randomName() {
    final t = _nameTemplates[_rng.nextInt(_nameTemplates.length)];
    return '${t.$1} ${t.$2}';
  }


  void _onTeamCountChanged(int count) {
    setState(() {
      _teamCount = count.clamp(2, 64);
      if (_teams.length > _teamCount) {
        _teams = _teams.sublist(0, _teamCount);
      }
    });
  }

  void _onPlayersPerSideChanged(int pps) {
    setState(() {
      _playersPerSide = pps;
      _teams = _teams.map((t) {
        final players = List.generate(pps, (i) {
          if (i < t.players.length) return t.players[i];
          return KoPlayerSnapshot(appPlayerId: '', name: 'Player ${i + 1}');
        });
        return t.copyWith(players: players);
      }).toList();
    });
  }

  bool get _canCreate =>
      _nameCtrl.text.trim().isNotEmpty &&
      _teamCount >= 2 &&
      _teams.length == _teamCount;


  // ── Team actions ──────────────────────────────────────────────────────────

  void _addExistingTeam(Team hubTeam) {
    final players = List.generate(_playersPerSide, (j) {
      if (j < hubTeam.userIds.length) {
        final p = widget.existingPlayers
            .where((p) => p.id == hubTeam.userIds[j])
            .firstOrNull;
        return p != null
            ? KoPlayerSnapshot(appPlayerId: p.id, name: p.name, skillRating: p.skillRating)
            : KoPlayerSnapshot(appPlayerId: '', name: 'Player ${j + 1}');
      }
      return KoPlayerSnapshot(appPlayerId: '', name: 'Player ${j + 1}');
    });
    setState(() => _teams.add(KoTeam(
      id: KoTeam.generateId(),
      name: hubTeam.name,
      hubTeamId: hubTeam.id,
      players: players,
    )));
  }

  void _createNewTeam() {
    final name = _newTeamNameCtrl.text.trim();
    if (name.isEmpty || _teams.length >= _teamCount) return;
    setState(() {
      _teams.add(KoTeam(
        id: KoTeam.generateId(),
        name: name,
        players: List.generate(
            _playersPerSide,
            (j) => KoPlayerSnapshot(appPlayerId: '', name: 'Player ${j + 1}')),
      ));
      _newTeamNameCtrl.clear();
    });
  }

  void _removeTeam(int index) => setState(() => _teams.removeAt(index));

  void _fillRemaining() {
    if (_teams.length >= _teamCount) return;
    setState(() {
      final used = _teams.map((t) => t.name).toSet();
      final needed = _teamCount - _teams.length;
      for (var i = 0; i < needed; i++) {
        _teams.add(KoTeam(
          id: KoTeam.generateId(),
          name: _pickFunName(used),
          players: List.generate(
            _playersPerSide,
            (j) => KoPlayerSnapshot(appPlayerId: '', name: 'Player ${j + 1}'),
          ),
        ));
      }
    });
  }

  // ── Schedule preview ──────────────────────────────────────────────────────

  KoBracketTournament get _previewTournament {
    final teams = List.generate(
      _teamCount,
      (i) => i < _teams.length
          ? _teams[i]
          : KoTeam(
              id: 'preview_$i',
              name: 'Team ${String.fromCharCode(65 + (i % 26))}',
              players: List.generate(
                _playersPerSide,
                (j) => KoPlayerSnapshot(appPlayerId: '', name: 'Player ${j + 1}'),
              ),
            ),
    );
    final base = KoBracketTournament(
      id: '', name: '',
      generationMode: _generationMode,
      oddTeamStrategy: _oddStrategy,
      playersPerSide: _playersPerSide,
      courtCount: _courtCount,
      earlyRoundFormat: _earlyFormat,
      finalRoundFormat: _finalFormat,
      finalRoundsCount: _finalRoundsCount,
      earlyBreakMinutes: _earlyBreakMinutes,
      finalBreakMinutes: _finalBreakMinutes,
      estimatedStart: _estimatedStart,
      teams: teams,
    );
    final withMatches = base.copyWith(matches: KoBracketGenerator.generate(base));
    return KoBracketScheduler.assignTimes(withMatches);
  }

  // ── Create ────────────────────────────────────────────────────────────────

  void _create() {
    if (!_canCreate) return;
    final teams = _teams.whereType<KoTeam>().toList();
    final base = KoBracketTournament(
      id: KoBracketTournament.generateId(),
      name: _nameCtrl.text.trim(),
      generationMode: _generationMode,
      oddTeamStrategy: _oddStrategy,
      playersPerSide: _playersPerSide,
      courtCount: _courtCount,
      earlyRoundFormat: _earlyFormat,
      finalRoundFormat: _finalFormat,
      finalRoundsCount: _finalRoundsCount,
      earlyBreakMinutes: _earlyBreakMinutes,
      finalBreakMinutes: _finalBreakMinutes,
      estimatedStart: _estimatedStart,
      teams: teams,
      matches: KoBracketGenerator.generate(
        KoBracketTournament(
          id: '', name: '',
          generationMode: _generationMode,
          oddTeamStrategy: _oddStrategy,
          playersPerSide: _playersPerSide,
          courtCount: _courtCount,
          earlyRoundFormat: _earlyFormat,
          finalRoundFormat: _finalFormat,
          finalRoundsCount: _finalRoundsCount,
          estimatedStart: _estimatedStart,
          teams: teams,
        ),
      ),
      status: KoBracketStatus.inProgress,
    );
    final tournament = KoBracketScheduler.assignTimes(base);
    widget.onCreated(tournament);
    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (_) => KoBracketBracketPage(
        tournament: tournament,
        onChanged: widget.onCreated,
        existingPlayers: widget.existingPlayers,
        existingTeams: widget.existingTeams,
        existingGroups: widget.existingGroups,
        onCreatePlayer: widget.onCreatePlayer,
        onCreateTeam: widget.onCreateTeam,
      ),
    ));
  }

  // ── Start time picker ─────────────────────────────────────────────────────

  Future<void> _pickStartTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _estimatedStart,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_estimatedStart),
    );
    if (time == null || !mounted) return;
    setState(() {
      _estimatedStart =
          DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final preview  = _previewTournament;
    final anyEmpty = _teams.length < _teamCount;

    return Scaffold(
      appBar: const TournaQAppBar(
          title: 'Single Elimination', subtitle: 'New Tournament'),
      body: ScrollablePage(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ══ SECTION 1: Tournament Setup ═══════════════════════════════
            _sectionDivider('Tournament Setup', Icons.tune_rounded),
            const SizedBox(height: 14),

            Row(children: [
              Expanded(
                child: _comboField(
                  label: 'Teams',
                  ctrl: _teamCountCtrl,
                  presets: [4, 6, 8, 10, 12, 16],
                  onParsed: _onTeamCountChanged,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(child: _styleField()),
            ]),
            const SizedBox(height: 14),
            Row(children: [
              Expanded(child: _playersPerSideField()),
              const SizedBox(width: 12),
              Expanded(
                child: _comboField(
                  label: 'Courts',
                  ctrl: _courtCtrl,
                  presets: [1, 2, 3, 4, 5, 6],
                  onParsed: (v) => setState(() => _courtCount = v.clamp(1, 32)),
                ),
              ),
            ]),
            const SizedBox(height: 14),
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _fieldLabel('Generation'),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<KoBracketGenerationMode>(
                      initialValue: _generationMode,
                      isDense: true,
                      isExpanded: true,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      items: const [
                        DropdownMenuItem(
                            value: KoBracketGenerationMode.random,
                            child: Text('Random')),
                        DropdownMenuItem(
                            value: KoBracketGenerationMode.seeded,
                            child: Text('Seeded')),
                      ],
                      onChanged: (v) {
                        if (v != null) setState(() => _generationMode = v);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Expanded(child: _fieldLabel('Odd Teams')),
                      GestureDetector(
                        onTap: _showOddTeamsHelp,
                        child: const Icon(Icons.help_outline_rounded,
                            size: 18, color: _kOlive),
                      ),
                    ]),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<KoOddTeamStrategy>(
                      initialValue: _oddStrategy,
                      isDense: true,
                      isExpanded: true,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      items: const [
                        DropdownMenuItem(
                            value: KoOddTeamStrategy.byes, child: Text('Byes')),
                        DropdownMenuItem(
                            value: KoOddTeamStrategy.playIn,
                            child: Text('Play-in')),
                      ],
                      onChanged: (v) {
                        if (v != null) setState(() => _oddStrategy = v);
                      },
                    ),
                  ],
                ),
              ),
            ]),
            const SizedBox(height: 14),
            _roundFormatCard(
              label: 'Early Rounds',
              format: _earlyFormat,
              onChanged: (f) => setState(() => _earlyFormat = f),
            ),
            const SizedBox(height: 10),
            _roundFormatCard(
              label: 'Final Rounds',
              format: _finalFormat,
              onChanged: (f) => setState(() => _finalFormat = f),
              showFinalRoundsCount: true,
            ),
            const SizedBox(height: 14),
            _buildSchedulePreview(preview),
            const SizedBox(height: 14),
            _fieldLabel('Tournament Name'),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(
                child: TextField(
                  controller: _nameCtrl,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () => setState(() => _nameCtrl.text = _randomName()),
                icon: const Icon(Icons.refresh_rounded),
                tooltip: 'Suggest name',
              ),
            ]),
            const SizedBox(height: 28),

            // ══ SECTION 2: Teams ══════════════════════════════════════════
            _sectionDivider('Teams', Icons.groups_rounded),
            const SizedBox(height: 10),
            _buildTeamsCard(),
            const SizedBox(height: 28),

            // ══ Create ════════════════════════════════════════════════════
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(children: [
                Icon(
                  _canCreate
                      ? Icons.check_circle_rounded
                      : Icons.error_outline_rounded,
                  color: _canCreate ? _kOlive : Colors.red.shade600,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  _canCreate
                      ? 'Ready to start!'
                      : anyEmpty
                          ? 'Add all $_teamCount teams to continue'
                          : 'Setup incomplete',
                  style: TextStyle(
                    color: _canCreate ? _kOlive : Colors.red.shade600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ]),
            ),
            ElevatedButton(
              onPressed: _canCreate ? _create : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: _kGold,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text(
                'Create Tournament',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Teams card (tappable, opens sheet) ───────────────────────────────────

  Widget _buildTeamsCard() {
    final exact      = _teams.length == _teamCount;
    final hasAny     = _teams.isNotEmpty;
    final borderColor = exact
        ? _kOlive
        : hasAny
            ? Colors.red.shade300
            : Colors.grey.shade300;
    final bgColor = exact
        ? AppColors.oliveLight
        : hasAny
            ? Colors.red.shade50
            : Colors.grey.shade50;
    final iconColor = exact ? _kOlive : hasAny ? Colors.red.shade600 : Colors.black38;
    final textColor = exact ? _kOlive : hasAny ? Colors.red.shade700 : Colors.black38;

    return InkWell(
      onTap: _showTeamsSheet,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: borderColor, width: exact ? 1.5 : 1.0),
          borderRadius: BorderRadius.circular(12),
          color: bgColor,
        ),
        child: Row(children: [
          Icon(Icons.groups_rounded, color: iconColor, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              hasAny
                  ? '${_teams.length} / $_teamCount teams added'
                  : 'Tap to add teams',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: textColor),
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: iconColor, size: 20),
        ]),
      ),
    );
  }

  // ── Teams sheet ───────────────────────────────────────────────────────────

  void _showTeamsSheet() {
    _teamSearchCtrl.clear();
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
          final isFull       = _teams.length >= _teamCount;
          final addedHubIds  = _teams.map((t) => t.hubTeamId).whereType<String>().toSet();
          final allAvailable = widget.existingTeams
              .where((t) => !addedHubIds.contains(t.id))
              .toList();
          final query         = _teamSearchCtrl.text.toLowerCase();
          final relevantGroups = widget.existingGroups
              .where((c) => widget.existingTeams.any((t) => c.teamIds.contains(t.id)))
              .toList();
          final filteredAvailable = allAvailable.where((t) {
            final matchesGroup  = selectedGroupId == null ||
                widget.existingGroups
                    .any((c) => c.id == selectedGroupId && c.teamIds.contains(t.id));
            final matchesQuery = query.isEmpty || t.name.toLowerCase().contains(query);
            return matchesGroup && matchesQuery;
          }).toList();

          void rebuild() {
            setSheetState(() {});
            setState(() {});
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
                  child: Row(children: [
                    Text(title,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w700)),
                    const Spacer(),
                    ?trailing,
                    Icon(
                      expanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      size: 20,
                      color: Colors.black45,
                    ),
                  ]),
                ),
              );

          return TournaQSheet(
            body: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Header ────────────────────────────────────────────
                  Row(children: [
                    const Text('Teams',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w800)),
                    const Spacer(),
                    if (_teams.isNotEmpty)
                      TextButton(
                        onPressed: () async {
                          final ok = await showDialog<bool>(
                            context: ctx,
                            builder: (dCtx) => AlertDialog(
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16)),
                              title: const Text('Remove all teams?',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700)),
                              content: const Text(
                                  'This will clear all added teams.',
                                  style: TextStyle(
                                      fontSize: 14, color: Colors.black54)),
                              actions: [
                                TextButton(
                                    onPressed: () =>
                                        Navigator.of(dCtx).pop(false),
                                    child: const Text('Cancel')),
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(dCtx).pop(true),
                                  style: TextButton.styleFrom(
                                      foregroundColor: Colors.red),
                                  child: const Text('Remove all'),
                                ),
                              ],
                            ),
                          );
                          if (ok == true) {
                            _teams.clear();
                            rebuild();
                          }
                        },
                        style: TextButton.styleFrom(
                            foregroundColor: Colors.red,
                            padding: const EdgeInsets.symmetric(horizontal: 8)),
                        child: const Text('Clear all',
                            style: TextStyle(fontSize: 13)),
                      ),
                    Text('${_teams.length} / $_teamCount',
                        style: const TextStyle(
                            color: Colors.black45, fontSize: 13)),
                  ]),
                  const Divider(height: 16),

                  // ── Create Team ───────────────────────────────────────
                  sectionHeader(
                    'Create Team',
                    createExpanded,
                    () => setSheetState(() => createExpanded = !createExpanded),
                  ),
                  if (createExpanded) ...[
                    Row(children: [
                      Expanded(
                        child: TextField(
                          controller: _newTeamNameCtrl,
                          textCapitalization: TextCapitalization.words,
                          decoration: InputDecoration(
                            isDense: true,
                            hintText: 'Team name…',
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10)),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                          ),
                          onChanged: (_) => setSheetState(() {}),
                          onSubmitted: (_) {
                            if (!isFull &&
                                _newTeamNameCtrl.text.trim().isNotEmpty) {
                              _createNewTeam();
                              rebuild();
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: !isFull &&
                                _newTeamNameCtrl.text.trim().isNotEmpty
                            ? () {
                                _createNewTeam();
                                rebuild();
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _kOlive,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Add'),
                      ),
                    ]),
                    const SizedBox(height: 8),
                  ],
                  const Divider(height: 8),

                  // ── Add Existing Teams ────────────────────────────────
                  sectionHeader(
                    'Add Existing Teams (${allAvailable.length})',
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
                              setSheetState(() => selectedGroupId =
                                  picked.isEmpty ? null : picked);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 10),
                            decoration: BoxDecoration(
                              color: selectedGroupId != null
                                  ? _kGoldCream
                                  : Colors.grey.shade50,
                              borderRadius: const BorderRadius.horizontal(
                                  left: Radius.circular(11)),
                            ),
                            child:
                                Row(mainAxisSize: MainAxisSize.min, children: [
                              Icon(Icons.home_rounded,
                                  size: 14,
                                  color: selectedGroupId != null
                                      ? _kGoldDark
                                      : Colors.black45),
                              const SizedBox(width: 4),
                              Text(
                                selectedGroupId == null
                                    ? 'Group'
                                    : relevantGroups
                                        .firstWhere(
                                            (c) => c.id == selectedGroupId)
                                        .name,
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: selectedGroupId != null
                                        ? _kGoldDark
                                        : Colors.black45),
                              ),
                              const SizedBox(width: 2),
                              Icon(Icons.arrow_drop_down_rounded,
                                  size: 16,
                                  color: selectedGroupId != null
                                      ? _kGoldDark
                                      : Colors.black45),
                            ]),
                          ),
                        ),
                        Container(
                            width: 1,
                            height: 36,
                            color: Colors.grey.shade200),
                        Expanded(
                          child: TextField(
                            controller: _teamSearchCtrl,
                            decoration: const InputDecoration(
                              hintText: 'Search teams…',
                              isDense: true,
                              prefixIcon: Icon(Icons.search_rounded,
                                  size: 18, color: Colors.black45),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 4, vertical: 10),
                            ),
                            onChanged: (_) => setSheetState(() {}),
                          ),
                        ),
                      ]),
                    ),
                    const SizedBox(height: 6),
                    if (filteredAvailable.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Text('No teams match.',
                            style: TextStyle(
                                color: Colors.black38, fontSize: 13)),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: filteredAvailable.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (_, i) {
                          final team = filteredAvailable[i];
                          return ListTile(
                            dense: true,
                            contentPadding:
                                const EdgeInsets.symmetric(horizontal: 4),
                            leading: CircleAvatar(
                              radius: 14,
                              backgroundColor: isFull
                                  ? Colors.grey.shade100
                                  : _kGoldCream,
                              child: Text(
                                team.name.isNotEmpty
                                    ? team.name[0].toUpperCase()
                                    : '?',
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: isFull
                                        ? Colors.black26
                                        : _kGoldDark),
                              ),
                            ),
                            title: Text(team.name,
                                style: TextStyle(
                                    fontSize: 13,
                                    color: isFull
                                        ? Colors.black38
                                        : Colors.black87)),
                            subtitle: team.userIds.isNotEmpty
                                ? Text(
                                    '${team.userIds.length} player${team.userIds.length == 1 ? '' : 's'}',
                                    style: const TextStyle(fontSize: 11))
                                : null,
                            trailing: IconButton(
                              icon: Icon(Icons.add_circle_outline_rounded,
                                  size: 20,
                                  color: isFull
                                      ? Colors.grey.shade300
                                      : _kOlive),
                              onPressed: isFull
                                  ? null
                                  : () {
                                      _addExistingTeam(team);
                                      rebuild();
                                    },
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          );
                        },
                      ),
                    const SizedBox(height: 8),
                  ],
                  const Divider(height: 8),

                  // ── Added Teams ───────────────────────────────────────
                  sectionHeader(
                    'Added (${_teams.length} / $_teamCount)',
                    addedExpanded,
                    () => setSheetState(() => addedExpanded = !addedExpanded),
                    trailing: _teams.length < _teamCount
                        ? TextButton.icon(
                            onPressed: () {
                              _fillRemaining();
                              rebuild();
                            },
                            icon: const Icon(Icons.shuffle_rounded, size: 14),
                            label: Text(
                              'Fill ${_teamCount - _teams.length} random',
                              style: const TextStyle(fontSize: 12),
                            ),
                            style: TextButton.styleFrom(
                              foregroundColor: _kOlive,
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                            ),
                          )
                        : null,
                  ),
                  if (addedExpanded) ...[
                    if (_teams.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Text('No teams added yet.',
                            style: TextStyle(
                                color: Colors.black38, fontSize: 13)),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _teams.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: 4),
                        itemBuilder: (_, i) {
                          final team = _teams[i];
                          return ListTile(
                            dense: true,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 0),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: BorderSide(color: Colors.grey.shade200),
                            ),
                            leading: CircleAvatar(
                              radius: 14,
                              backgroundColor: _kGoldCream,
                              child: Text(
                                team.name.isNotEmpty
                                    ? team.name[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                    fontSize: 11,
                                    color: _kGoldDark,
                                    fontWeight: FontWeight.w700),
                              ),
                            ),
                            title: Text(team.name,
                                style: const TextStyle(fontSize: 13)),
                            subtitle: Text(
                              team.players.map((p) => p.name).join(' · '),
                              style: const TextStyle(
                                  fontSize: 10, color: Colors.black38),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit_rounded,
                                      size: 16, color: Colors.black38),
                                  onPressed: () {
                                    showModalBottomSheet<void>(
                                      context: context,
                                      isScrollControlled: true,
                                      backgroundColor: Colors.transparent,
                                      builder: (_) => KoTeamEditorSheet(
                                        team: team,
                                        existingPlayers: widget.existingPlayers,
                                        existingTeams: widget.existingTeams,
                                        existingGroups: widget.existingGroups,
                                        generationMode: _generationMode,
                                        onCreatePlayer: widget.onCreatePlayer,
                                        onCreateTeam: widget.onCreateTeam,
                                        onSave: (updated) {
                                          _teams[i] = updated;
                                          rebuild();
                                        },
                                      ),
                                    );
                                  },
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                                IconButton(
                                  icon: Icon(Icons.close_rounded,
                                      size: 16,
                                      color: Colors.red.shade300),
                                  onPressed: () {
                                    _removeTeam(i);
                                    rebuild();
                                  },
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                              ],
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

  // ── Break picker ──────────────────────────────────────────────────────────

  void _pickBreak({required bool isFinal}) {
    final current = isFinal ? _finalBreakMinutes : _earlyBreakMinutes;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TournaQSheet(
        body: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Break — ${isFinal ? 'Final' : 'Early'} Rounds',
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [0, 5, 10, 15, 20, 30, 45, 60].map((v) {
                  final selected = v == current;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        if (isFinal) { _finalBreakMinutes = v; }
                        else { _earlyBreakMinutes = v; }
                      });
                      Navigator.of(context).pop();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: selected ? _kGold : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: selected ? _kGoldDark : Colors.grey.shade300,
                          width: selected ? 1.5 : 1,
                        ),
                      ),
                      child: Text(
                        v == 0 ? 'No break' : '$v min',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: selected ? Colors.white : Colors.black54,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Odd teams help ────────────────────────────────────────────────────────

  void _showOddTeamsHelp() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => TournaQSheet(
        body: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Odd Teams — How it works',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
              const SizedBox(height: 20),
              _helpItem(
                icon: Icons.skip_next_rounded, color: _kGold, title: 'Byes',
                body: 'Top seeds skip round 1 and wait. Weaker seeds play first. '
                    'Fastest setup — ideal when you want to reward higher seedings '
                    'without extra matches.',
                example: 'Example (5 teams): Seeds 1–3 wait. Seeds 4 and 5 play. '
                    'Winner joins the main bracket.',
              ),
              const SizedBox(height: 16),
              _helpItem(
                icon: Icons.play_arrow_rounded, color: _kOlive, title: 'Play-in',
                body: 'Bottom seeds play a preliminary round to earn their bracket spot. '
                    'Nobody gets a free pass — every team has to win to advance.',
                example: 'Example (5 teams): Seeds 4 and 5 play a play-in. '
                    'Winner takes the last slot in the main bracket.',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _helpItem({
    required IconData icon, required Color color,
    required String title, required String body, required String example,
  }) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style: TextStyle(
                  fontWeight: FontWeight.w700, fontSize: 14, color: color)),
          const SizedBox(height: 4),
          Text(body, style: const TextStyle(fontSize: 13, color: Colors.black87)),
          const SizedBox(height: 4),
          Text(example,
              style: const TextStyle(
                  fontSize: 12,
                  color: Colors.black45,
                  fontStyle: FontStyle.italic)),
        ]),
      ),
    ]);
  }

  // ── Round format card ─────────────────────────────────────────────────────

  Widget _roundFormatCard({
    required String label,
    required KoRoundFormat format,
    required void Function(KoRoundFormat) onChanged,
    bool showFinalRoundsCount = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _fieldLabel('Sets per game'),
                const SizedBox(height: 6),
                _chipRow(
                  options: [1, 3, 5],
                  selected: format.setsPerGame,
                  onSelected: (v) => onChanged(format.copyWith(setsPerGame: v)),
                ),
              ]),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _fieldLabel('Points per set'),
                const SizedBox(height: 6),
                _chipRow(
                  options: [11, 15, 21],
                  selected: format.pointsPerSet,
                  onSelected: (v) => onChanged(format.copyWith(pointsPerSet: v)),
                ),
              ]),
            ),
          ]),
          if (showFinalRoundsCount) ...[
            const SizedBox(height: 10),
            Row(children: [
              _fieldLabel('Applies to last'),
              const SizedBox(width: 10),
              _stepper(
                value: _finalRoundsCount,
                min: 1, max: 4,
                onChanged: (v) => setState(() => _finalRoundsCount = v),
              ),
              const SizedBox(width: 6),
              const Text('round(s)',
                  style: TextStyle(fontSize: 12, color: Colors.black54)),
            ]),
          ],
        ],
      ),
    );
  }

  Widget _chipRow({
    required List<int> options,
    required int selected,
    required void Function(int) onSelected,
  }) {
    return Wrap(
      spacing: 6,
      children: options.map((v) {
        final isSel = v == selected;
        return GestureDetector(
          onTap: () => onSelected(v),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: isSel ? _kGoldCream : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSel ? _kGoldDark : Colors.grey.shade300,
                width: isSel ? 1.5 : 1,
              ),
            ),
            child: Text('$v',
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    color: isSel ? _kGoldDark : Colors.black54)),
          ),
        );
      }).toList(),
    );
  }

  Widget _styleField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _fieldLabel('Style'),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade400),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(children: [
            const Expanded(
              child: Text('Single Elimination',
                  style: TextStyle(fontSize: 14, color: Colors.black87)),
            ),
            Transform.rotate(
              angle: pi,
              child: const Icon(Icons.account_tree_rounded, size: 16, color: Colors.black38),
            ),
          ]),
        ),
      ],
    );
  }

  Widget _playersPerSideField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _fieldLabel('Players per side'),
        const SizedBox(height: 6),
        DropdownButtonFormField<int>(
          initialValue: _playersPerSide,
          isDense: true,
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
          items: [1, 2, 3, 4, 5, 6]
              .map((n) => DropdownMenuItem(value: n, child: Text('${n}vs$n')))
              .toList(),
          onChanged: (v) { if (v != null) _onPlayersPerSideChanged(v); },
        ),
      ],
    );
  }

  Widget _comboField({
    required String label,
    required TextEditingController ctrl,
    required List<int> presets,
    required void Function(int) onParsed,
    String? unit,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _fieldLabel(label),
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

  Widget _stepper({
    required int value,
    required int min,
    required int max,
    required void Function(int) onChanged,
  }) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      GestureDetector(
        onTap: value > min ? () => onChanged(value - 1) : null,
        child: Icon(Icons.remove_circle_outline_rounded,
            size: 22,
            color: value > min ? _kOlive : Colors.grey.shade300),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Text('$value',
            style: const TextStyle(
                fontWeight: FontWeight.w700, fontSize: 14)),
      ),
      GestureDetector(
        onTap: value < max ? () => onChanged(value + 1) : null,
        child: Icon(Icons.add_circle_outline_rounded,
            size: 22,
            color: value < max ? _kOlive : Colors.grey.shade300),
      ),
    ]);
  }

  Widget _sectionDivider(String label, IconData icon) => Row(children: [
        Icon(icon, size: 14, color: AppColors.oliveMedium),
        const SizedBox(width: 6),
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.oliveMedium,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(width: 8),
        const Expanded(child: Divider(height: 1)),
      ]);

  // ── Schedule preview ──────────────────────────────────────────────────────

  Widget _buildSchedulePreview(KoBracketTournament preview) {
    final rounds = preview.allRounds;
    if (rounds.isEmpty) return const SizedBox.shrink();

    DateTime? cursor = preview.estimatedStart;
    final rows       = <Widget>[];
    final roundList  =
        rounds.where((r) => preview.matchesForRound(r).isNotEmpty).toList();

    for (var i = 0; i < roundList.length; i++) {
      final round    = roundList[i];
      final matches  = preview.matchesForRound(round);
      final slots    = (matches.length / preview.courtCount).ceil();
      final gameMins = slots * preview.minutesForRound(round);
      final start    = cursor;
      final end      = cursor?.add(Duration(minutes: gameMins));

      final stepsFromFinal = preview.mainRoundCount - round;
      final label = round == 0
          ? 'Play-in'
          : switch (stepsFromFinal) {
              0 => 'Final',
              1 => 'Semi-final',
              2 => 'Quarter-final',
              _ => 'Round $round',
            };

      rows.add(Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(children: [
          SizedBox(
            width: 92,
            child: Text(label,
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87)),
          ),
          Text('${matches.length} match${matches.length == 1 ? '' : 'es'}',
              style: const TextStyle(fontSize: 11, color: Colors.black45)),
          const Spacer(),
          if (start != null && end != null)
            Text('${_fmtTime(start)} – ${_fmtTime(end)}',
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _kGoldDark)),
        ]),
      ));

      final breakMins   = preview.breakAfterRound(round);
      final isLast      = i == roundList.length - 1;
      if (!isLast) {
        final isFinalBreak =
            round >= preview.mainRoundCount - preview.finalRoundsCount + 1;
        rows.add(GestureDetector(
          onTap: () => _pickBreak(isFinal: isFinalBreak),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(children: [
              const SizedBox(width: 92),
              Icon(
                breakMins > 0
                    ? Icons.coffee_rounded
                    : Icons.add_circle_outline_rounded,
                size: 11,
                color: breakMins > 0 ? _kOlive : Colors.black26,
              ),
              const SizedBox(width: 4),
              Text(
                breakMins > 0 ? '$breakMins min break' : 'Add break',
                style: TextStyle(
                    fontSize: 11,
                    color: breakMins > 0 ? _kOlive : Colors.black38),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.edit_rounded, size: 9, color: Colors.black26),
            ]),
          ),
        ));
      }
      cursor = end?.add(Duration(minutes: isLast ? 0 : breakMins));
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _kGoldCream,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.goldBadgeBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.schedule_rounded, size: 13, color: _kGoldDark),
            const SizedBox(width: 6),
            const Text('Schedule Preview',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _kGoldDark)),
            const Spacer(),
            Text(_formatDuration(preview.estimatedDuration),
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _kGoldDark)),
          ]),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: _pickStartTime,
            child: Row(children: [
              const Icon(Icons.play_circle_outline_rounded,
                  size: 12, color: _kGoldDark),
              const SizedBox(width: 4),
              Text('Starts: ${_formatDateTime(_estimatedStart)}',
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _kGoldDark)),
              const SizedBox(width: 4),
              const Icon(Icons.edit_rounded, size: 10, color: _kGoldDark),
            ]),
          ),
          if (rows.isNotEmpty) ...[
            const SizedBox(height: 10),
            const Divider(height: 1, color: AppColors.goldBadgeBorder),
            const SizedBox(height: 8),
            ...rows,
          ],
        ],
      ),
    );
  }

  String _fmtTime(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes % 60;
    if (h == 0) return '${m}min';
    if (m == 0) return '${h}h';
    return '${h}h ${m}min';
  }

  Widget _fieldLabel(String text) => Text(
        text,
        style: const TextStyle(
            fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black54),
      );

  String _formatDateTime(DateTime dt) {
    final weekday =
        ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][dt.weekday - 1];
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$weekday ${dt.day}/${dt.month} $h:$m';
  }
}

// ── Slot picker sheet (Add Team) ──────────────────────────────────────────────

enum _KoSlotMethod { random, fromHub, create }

class _KoSlotPickerSheet extends StatefulWidget {
  final int slotIndex;
  final int playersPerSide;
  final List<Team> existingTeams;
  final List<Player> existingPlayers;
  final List<Group> existingGroups;
  final String Function(String name, List<String> linkedPlayerIds) onCreateTeam;
  final Set<String> usedNames;

  const _KoSlotPickerSheet({
    required this.slotIndex,
    required this.playersPerSide,
    required this.existingTeams,
    required this.existingPlayers,
    required this.existingGroups,
    required this.onCreateTeam,
    required this.usedNames,
  });

  @override
  State<_KoSlotPickerSheet> createState() => _KoSlotPickerSheetState();
}

class _KoSlotPickerSheetState extends State<_KoSlotPickerSheet> {
  _KoSlotMethod? _method;
  final _nameCtrl   = TextEditingController();
  final _searchCtrl = TextEditingController();
  String? _selectedGroupId;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  KoTeam _makePlayers({required String name, String? hubTeamId, List<KoPlayerSnapshot>? players}) {
    final teamName = name;
    return KoTeam(
      id: KoTeam.generateId(),
      name: teamName,
      players: players ??
          List.generate(
            widget.playersPerSide,
            (j) => KoPlayerSnapshot(appPlayerId: '', name: 'Player ${j + 1}'),
          ),
      hubTeamId: hubTeamId,
    );
  }

  void _pop(KoTeam team) => Navigator.of(context).pop(team);

  @override
  Widget build(BuildContext context) {
    return TournaQSheet(
      body: switch (_method) {
        null                    => _buildMethodPicker(),
        _KoSlotMethod.fromHub   => _buildFromHub(),
        _KoSlotMethod.create    => _buildCreate(),
        _KoSlotMethod.random    => const SizedBox.shrink(),
      },
    );
  }

  // ── Method picker ─────────────────────────────────────────────────────────

  Widget _buildMethodPicker() {
    final funName = _pickFunName(Set.from(widget.usedNames));
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: Colors.grey.shade100, shape: BoxShape.circle),
                child: const Icon(Icons.close_rounded, size: 16),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Add Team ${widget.slotIndex + 1}',
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.w800),
              ),
            ),
          ]),
          const SizedBox(height: 8),
          const Text('How would you like to add this team?',
              style: TextStyle(fontSize: 14, color: Colors.black54)),
          const SizedBox(height: 24),
          _optionCard(
            icon: Icons.casino_rounded,
            label: 'Random',
            subtitle: '"$funName"',
            onTap: () => _pop(_makePlayers(name: funName)),
          ),
          const SizedBox(height: 12),
          _optionCard(
            icon: Icons.groups_rounded,
            label: 'From Teams Hub',
            subtitle: 'Pick an existing team from your hub',
            onTap: widget.existingTeams.isEmpty
                ? null
                : () => setState(() => _method = _KoSlotMethod.fromHub),
            disabled: widget.existingTeams.isEmpty,
            disabledHint: 'No teams in hub yet',
          ),
          const SizedBox(height: 12),
          _optionCard(
            icon: Icons.edit_rounded,
            label: 'Create New',
            subtitle: 'Enter a custom name for this team',
            onTap: () => setState(() => _method = _KoSlotMethod.create),
          ),
        ],
      ),
    );
  }

  Widget _optionCard({
    required IconData icon,
    required String label,
    required String subtitle,
    required VoidCallback? onTap,
    bool disabled = false,
    String? disabledHint,
  }) {
    return InkWell(
      onTap: disabled ? null : onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: disabled ? Colors.grey.shade50 : null,
          border: Border.all(
              color:
                  disabled ? Colors.grey.shade200 : AppColors.divider),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: disabled ? Colors.grey.shade100 : _kGoldCream,
              shape: BoxShape.circle,
            ),
            child: Icon(icon,
                color: disabled ? Colors.grey.shade400 : _kGold,
                size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: disabled ? Colors.black38 : Colors.black87)),
                Text(
                  disabled ? (disabledHint ?? subtitle) : subtitle,
                  style: TextStyle(
                      color: disabled ? Colors.black26 : Colors.black45,
                      fontSize: 13),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded,
              color:
                  disabled ? Colors.grey.shade200 : Colors.black26),
        ]),
      ),
    );
  }

  // ── From Hub ──────────────────────────────────────────────────────────────

  Widget _buildFromHub() {
    final query = _searchCtrl.text.toLowerCase();
    final relevantGroups = widget.existingGroups
        .where((c) => widget.existingTeams.any((t) => c.teamIds.contains(t.id)))
        .toList();
    final filtered = widget.existingTeams.where((t) {
      final matchesGroup = _selectedGroupId == null || relevantGroups.any((c) => c.id == _selectedGroupId && c.teamIds.contains(t.id));
      final matchesQuery = query.isEmpty || t.name.toLowerCase().contains(query);
      return matchesGroup && matchesQuery;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          child: Row(children: [
            GestureDetector(
              onTap: () => setState(() {
                _method = null;
                _searchCtrl.clear();
              }),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: Colors.grey.shade100, shape: BoxShape.circle),
                child: const Icon(Icons.arrow_back_ios_new_rounded, size: 16),
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text('From Teams Hub',
                  style:
                      TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            ),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(children: [
              if (relevantGroups.isNotEmpty)
                GestureDetector(
                  onTap: () async {
                    final picked = await showModalBottomSheet<String>(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => GroupPickerSheet(
                        groups: relevantGroups,
                        selectedId: _selectedGroupId,
                      ),
                    );
                    if (picked != null) {
                      setState(() => _selectedGroupId = picked.isEmpty ? null : picked);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    decoration: BoxDecoration(
                      color: _selectedGroupId != null ? AppColors.goldCream : Colors.grey.shade50,
                      borderRadius: const BorderRadius.horizontal(left: Radius.circular(11)),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.home_rounded, size: 14, color: _selectedGroupId != null ? AppColors.goldDark : Colors.black45),
                      const SizedBox(width: 4),
                      Text(
                        _selectedGroupId == null ? 'Group' : relevantGroups.firstWhere((c) => c.id == _selectedGroupId).name,
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _selectedGroupId != null ? AppColors.goldDark : Colors.black45),
                      ),
                      const SizedBox(width: 2),
                      Icon(Icons.arrow_drop_down_rounded, size: 16, color: _selectedGroupId != null ? AppColors.goldDark : Colors.black45),
                    ]),
                  ),
                ),
              if (relevantGroups.isNotEmpty)
                Container(width: 1, height: 36, color: Colors.grey.shade200),
              Expanded(
                child: TextField(
                  controller: _searchCtrl,
                  autofocus: true,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    isDense: true,
                    hintText: 'Search teams…',
                    prefixIcon: Icon(Icons.search_rounded, size: 18, color: Colors.black45),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 10),
                  ),
                ),
              ),
            ]),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Text(
                    _searchCtrl.text.isEmpty
                        ? 'No teams in hub yet.'
                        : 'No teams found.',
                    style: const TextStyle(
                        fontSize: 13, color: Colors.black45),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                  itemCount: filtered.length,
                  itemBuilder: (_, i) {
                    final t  = filtered[i];
                    final pc = t.userIds.length;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(color: Colors.grey.shade200)),
                      child: ListTile(
                        onTap: () {
                          // Map hub team players to snapshots
                          final players = <KoPlayerSnapshot>[];
                          for (final uid in t.userIds) {
                            if (players.length >= widget.playersPerSide) break;
                            final p = widget.existingPlayers
                                .where((p) => p.id == uid)
                                .firstOrNull;
                            if (p != null) {
                              players.add(KoPlayerSnapshot(
                                appPlayerId: p.id,
                                name: p.name,
                                skillRating: p.skillRating,
                              ));
                            }
                          }
                          while (players.length < widget.playersPerSide) {
                            players.add(KoPlayerSnapshot(
                                appPlayerId: '',
                                name: 'Player ${players.length + 1}'));
                          }
                          _pop(_makePlayers(
                              name: t.name,
                              hubTeamId: t.id,
                              players: players));
                        },
                        leading: CircleAvatar(
                          backgroundColor: _kGoldCream,
                          child: Text(
                            t.name.isNotEmpty
                                ? t.name[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: _kGoldDark,
                                fontSize: 14),
                          ),
                        ),
                        title: Text(t.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14)),
                        subtitle: pc > 0
                            ? Text('$pc player${pc == 1 ? '' : 's'}',
                                style: const TextStyle(fontSize: 12))
                            : null,
                        trailing: const Icon(Icons.download_rounded,
                            color: _kGold, size: 20),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // ── Create ────────────────────────────────────────────────────────────────

  Widget _buildCreate() {
    final canSave = _nameCtrl.text.trim().isNotEmpty;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(children: [
            GestureDetector(
              onTap: () => setState(() {
                _method = null;
                _nameCtrl.clear();
              }),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: Colors.grey.shade100, shape: BoxShape.circle),
                child: const Icon(Icons.arrow_back_ios_new_rounded, size: 16),
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text('Create New Team',
                  style:
                      TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            ),
          ]),
          const SizedBox(height: 24),
          const Text('Team Name',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.black54)),
          const SizedBox(height: 8),
          TextField(
            controller: _nameCtrl,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) {
              if (canSave) {
                final name  = _nameCtrl.text.trim();
                final hubId = widget.onCreateTeam(name, []);
                _pop(_makePlayers(name: name, hubTeamId: hubId));
              }
            },
            decoration: InputDecoration(
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10)),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              hintText:
                  'e.g. Team ${String.fromCharCode(65 + (widget.slotIndex % 26))}',
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: canSave
                ? () {
                    final name  = _nameCtrl.text.trim();
                    final hubId = widget.onCreateTeam(name, []);
                    _pop(_makePlayers(name: name, hubTeamId: hubId));
                  }
                : null,
            icon: const Icon(Icons.check_rounded),
            label: const Text('Add Team',
                style: TextStyle(fontWeight: FontWeight.w700)),
            style: ElevatedButton.styleFrom(
              backgroundColor: _kGold,
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.grey.shade200,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Team editor sheet (edit existing team) ────────────────────────────────────

enum _EditorMode { choice, create, import }

class KoTeamEditorSheet extends StatefulWidget {
  final KoTeam team;
  final List<Player> existingPlayers;
  final List<Team> existingTeams;
  final List<Group> existingGroups;
  final KoBracketGenerationMode generationMode;
  final Player Function(String name) onCreatePlayer;
  final void Function(KoTeam) onSave;
  final String Function(String name, List<String> linkedPlayerIds) onCreateTeam;

  const KoTeamEditorSheet({
    super.key,
    required this.team,
    required this.existingPlayers,
    required this.existingTeams,
    required this.existingGroups,
    required this.generationMode,
    required this.onCreatePlayer,
    required this.onSave,
    required this.onCreateTeam,
  });

  @override
  State<KoTeamEditorSheet> createState() => _KoTeamEditorSheetState();
}

class _KoTeamEditorSheetState extends State<KoTeamEditorSheet> {
  _EditorMode _mode = _EditorMode.choice;
  bool _fromImport  = false;
  String? _hubTeamId;
  String? _importGroupId;
  late final TextEditingController _nameCtrl;
  late List<KoPlayerSnapshot> _players;
  final _teamSearchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.team.name);
    _players  = List.from(widget.team.players);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _teamSearchCtrl.dispose();
    super.dispose();
  }

  void _importGlobalTeam(Team team) {
    final slots   = _players.length;
    final matched = <KoPlayerSnapshot>[];
    for (final uid in team.userIds) {
      if (matched.length >= slots) break;
      final player =
          widget.existingPlayers.where((p) => p.id == uid).firstOrNull;
      if (player != null) {
        matched.add(KoPlayerSnapshot(
          appPlayerId: player.id,
          name: player.name,
          skillRating: player.skillRating,
        ));
      }
    }
    while (matched.length < slots) {
      matched.add(KoPlayerSnapshot(
          appPlayerId: '', name: 'Player ${matched.length + 1}'));
    }
    setState(() {
      _nameCtrl.text = team.name;
      _players       = matched;
      _mode          = _EditorMode.create;
      _fromImport    = true;
      _hubTeamId     = team.id;
      _teamSearchCtrl.clear();
    });
  }

  void _save() {
    final name = _nameCtrl.text.trim().isEmpty
        ? widget.team.name
        : _nameCtrl.text.trim();
    String? resolvedHubTeamId = _hubTeamId;
    if (!_fromImport) {
      final linkedIds = _players
          .where((p) => p.appPlayerId.isNotEmpty)
          .map((p) => p.appPlayerId)
          .toList();
      resolvedHubTeamId = widget.onCreateTeam(name, linkedIds);
    }
    widget.onSave(widget.team.copyWith(
      name: name,
      players: _players,
      hubTeamId: resolvedHubTeamId,
    ));
    Navigator.of(context).pop();
  }

  void _showSlotPicker(int slotIndex) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SlotPickerSheet(
        slotIndex: slotIndex,
        currentPlayer: _players[slotIndex],
        existingPlayers: widget.existingPlayers,
        existingGroups: widget.existingGroups,
        onCreatePlayer: widget.onCreatePlayer,
        onPick: (s) => setState(() => _players[slotIndex] = s),
        onClear: () => setState(() => _players[slotIndex] = KoPlayerSnapshot(
              appPlayerId: '', name: 'Player ${slotIndex + 1}',
            )),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return TournaQSheet(
      body: switch (_mode) {
        _EditorMode.choice => _buildChoice(),
        _EditorMode.create => _buildCreate(),
        _EditorMode.import => _buildImport(),
      },
    );
  }

  Widget _buildChoice() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Edit Team',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          const Text('How would you like to set up this team?',
              style: TextStyle(fontSize: 13, color: Colors.black54)),
          const SizedBox(height: 20),
          _choiceTile(
            icon: Icons.edit_rounded, color: _kOlive,
            title: 'A — Create New',
            subtitle: 'Set a custom name and assign players manually',
            onTap: () => setState(() => _mode = _EditorMode.create),
          ),
          const SizedBox(height: 12),
          if (widget.existingTeams.isNotEmpty)
            _choiceTile(
              icon: Icons.groups_rounded, color: _kGold,
              title: 'B — Import from Teams Hub',
              subtitle: 'Pick an existing team — name and players fill in automatically',
              onTap: () => setState(() => _mode = _EditorMode.import),
            )
          else
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(children: [
                Icon(Icons.groups_rounded, size: 20, color: Colors.grey.shade400),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'No teams in Teams Hub yet.\nCreate teams via the Teams section first.',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
                ),
              ]),
            ),
        ],
      ),
    );
  }

  Widget _choiceTile({
    required IconData icon, required Color color,
    required String title, required String subtitle, required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w700, color: color)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: const TextStyle(fontSize: 12, color: Colors.black54)),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: color, size: 20),
        ]),
      ),
    );
  }

  Widget _buildCreate() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(children: [
            GestureDetector(
              onTap: () => setState(() => _mode = _EditorMode.choice),
              child: const Icon(Icons.arrow_back_rounded,
                  size: 20, color: Colors.black54),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text('Edit Team',
                  style:
                      TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            ),
            TextButton(
              onPressed: _save,
              style: TextButton.styleFrom(foregroundColor: _kGold),
              child: const Text('Save',
                  style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ]),
          const SizedBox(height: 16),
          const Text('Team Name',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.black54)),
          const SizedBox(height: 6),
          TextField(
            controller: _nameCtrl,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10)),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
          const SizedBox(height: 20),
          const Text('Players',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.black54)),
          const SizedBox(height: 8),
          ..._players.asMap().entries.map((e) {
            final i            = e.key;
            final p            = e.value;
            final isLinked     = p.appPlayerId.isNotEmpty;
            final needsAttention =
                widget.generationMode == KoBracketGenerationMode.seeded &&
                    (!isLinked || p.skillRating == null);
            return InkWell(
              onTap: () => _showSlotPicker(i),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: needsAttention
                        ? Colors.red.shade300
                        : Colors.grey.shade200,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor:
                        isLinked ? _kOlive : Colors.grey.shade300,
                    child: Text(
                      p.name.isNotEmpty ? p.name[0].toUpperCase() : '?',
                      style: const TextStyle(
                          fontSize: 11,
                          color: Colors.white,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p.name,
                            style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600)),
                        if (isLinked && p.skillRating != null)
                          Text('Skill: ${p.skillRating}',
                              style: const TextStyle(
                                  fontSize: 11, color: Colors.black45))
                        else if (isLinked)
                          Text('Unrated',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.orange.shade700))
                        else
                          const Text('Tap to assign',
                              style: TextStyle(
                                  fontSize: 11, color: Colors.black38)),
                      ],
                    ),
                  ),
                  Icon(
                    isLinked
                        ? Icons.edit_rounded
                        : Icons.add_circle_outline_rounded,
                    size: 16,
                    color: isLinked ? Colors.black38 : _kGold,
                  ),
                ]),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildImport() {
    final query         = _teamSearchCtrl.text.toLowerCase();
    final relevantGroups = widget.existingGroups
        .where((c) => widget.existingTeams.any((t) => c.teamIds.contains(t.id)))
        .toList();
    final filtered = widget.existingTeams.where((t) {
      final matchesGroup  = _importGroupId == null ||
          widget.existingGroups.any((c) => c.id == _importGroupId && c.teamIds.contains(t.id));
      final matchesQuery = query.isEmpty || t.name.toLowerCase().contains(query);
      return matchesGroup && matchesQuery;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          child: Row(children: [
            GestureDetector(
              onTap: () => setState(() {
                _mode = _EditorMode.choice;
                _teamSearchCtrl.clear();
              }),
              child: const Icon(Icons.arrow_back_rounded,
                  size: 20, color: Colors.black54),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text('Import from Teams Hub',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w800)),
            ),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(children: [
              if (relevantGroups.isNotEmpty)
                GestureDetector(
                  onTap: () async {
                    final picked = await showModalBottomSheet<String>(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => GroupPickerSheet(
                        groups: relevantGroups,
                        selectedId: _importGroupId,
                      ),
                    );
                    if (picked != null) {
                      setState(() => _importGroupId = picked.isEmpty ? null : picked);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    decoration: BoxDecoration(
                      color: _importGroupId != null ? _kGoldCream : Colors.grey.shade50,
                      borderRadius: const BorderRadius.horizontal(left: Radius.circular(11)),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.home_rounded, size: 14,
                          color: _importGroupId != null ? _kGoldDark : Colors.black45),
                      const SizedBox(width: 4),
                      Text(
                        _importGroupId == null
                            ? 'Group'
                            : relevantGroups.firstWhere((c) => c.id == _importGroupId).name,
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                            color: _importGroupId != null ? _kGoldDark : Colors.black45),
                      ),
                      const SizedBox(width: 2),
                      Icon(Icons.arrow_drop_down_rounded, size: 16,
                          color: _importGroupId != null ? _kGoldDark : Colors.black45),
                    ]),
                  ),
                ),
              if (relevantGroups.isNotEmpty)
                Container(width: 1, height: 36, color: Colors.grey.shade200),
              Expanded(
                child: TextField(
                  controller: _teamSearchCtrl,
                  autofocus: true,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: 'Search teams…',
                    prefixIcon: const Icon(Icons.search_rounded,
                        size: 18, color: Colors.black45),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 4, vertical: 10),
                  ),
                ),
              ),
            ]),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: filtered.isEmpty
              ? const Center(
                  child: Text('No teams found.',
                      style: TextStyle(fontSize: 13, color: Colors.black38)))
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                  itemCount: filtered.length,
                  itemBuilder: (_, i) {
                    final t  = filtered[i];
                    final pc = t.userIds.length;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(color: Colors.grey.shade200)),
                      elevation: 0,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _kGoldCream,
                          child: Text(
                            t.name.isNotEmpty
                                ? t.name[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: _kGoldDark,
                                fontSize: 14),
                          ),
                        ),
                        title: Text(t.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14)),
                        subtitle: pc > 0
                            ? Text('$pc player${pc == 1 ? '' : 's'}',
                                style: const TextStyle(fontSize: 12))
                            : null,
                        trailing: const Icon(Icons.download_rounded,
                            color: _kGold, size: 20),
                        onTap: () => _importGlobalTeam(t),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

// ── Slot picker sheet (player slots) ──────────────────────────────────────────

class _SlotPickerSheet extends StatefulWidget {
  final int slotIndex;
  final KoPlayerSnapshot currentPlayer;
  final List<Player> existingPlayers;
  final List<Group> existingGroups;
  final Player Function(String name) onCreatePlayer;
  final void Function(KoPlayerSnapshot) onPick;
  final VoidCallback onClear;

  const _SlotPickerSheet({
    required this.slotIndex,
    required this.currentPlayer,
    required this.existingPlayers,
    required this.existingGroups,
    required this.onCreatePlayer,
    required this.onPick,
    required this.onClear,
  });

  @override
  State<_SlotPickerSheet> createState() => _SlotPickerSheetState();
}

class _SlotPickerSheetState extends State<_SlotPickerSheet> {
  final _newNameCtrl = TextEditingController();
  final _searchCtrl  = TextEditingController();
  String? _playerGroupId;

  @override
  void dispose() {
    _newNameCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _createNew() {
    final name = _newNameCtrl.text.trim();
    if (name.isEmpty) return;
    final player = widget.onCreatePlayer(name);
    widget.onPick(KoPlayerSnapshot(
      appPlayerId: player.id,
      name: player.name,
      skillRating: player.skillRating,
    ));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isLinked      = widget.currentPlayer.appPlayerId.isNotEmpty;
    final query         = _searchCtrl.text.toLowerCase();
    final relevantGroups = widget.existingGroups
        .where((c) => widget.existingPlayers.any((p) => c.playerIds.contains(p.id)))
        .toList();
    final filtered = widget.existingPlayers.where((p) {
      final matchesGroup  = _playerGroupId == null ||
          widget.existingGroups.any((c) => c.id == _playerGroupId && c.playerIds.contains(p.id));
      final matchesQuery = query.isEmpty || p.name.toLowerCase().contains(query);
      return matchesGroup && matchesQuery;
    }).toList();

    return TournaQSheet(
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(children: [
              Expanded(
                child: Text('Player ${widget.slotIndex + 1}',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w800)),
              ),
              if (isLinked)
                TextButton.icon(
                  onPressed: () {
                    widget.onClear();
                    Navigator.of(context).pop();
                  },
                  icon: const Icon(Icons.close_rounded, size: 14),
                  label: const Text('Clear', style: TextStyle(fontSize: 13)),
                  style: TextButton.styleFrom(
                      foregroundColor: Colors.red.shade400),
                ),
            ]),
            const SizedBox(height: 20),
            _sectionLabel('A — New Player', _kOlive),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(
                child: TextField(
                  controller: _newNameCtrl,
                  textCapitalization: TextCapitalization.words,
                  onChanged: (_) => setState(() {}),
                  onSubmitted: (_) => _createNew(),
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: 'Enter player name…',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _newNameCtrl.text.trim().isNotEmpty
                    ? _createNew
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kOlive,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Create',
                    style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ]),
            const SizedBox(height: 20),
            _sectionLabel('B — From Players Hub', _kGold),
            const SizedBox(height: 8),
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
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => GroupPickerSheet(
                          groups: relevantGroups,
                          selectedId: _playerGroupId,
                        ),
                      );
                      if (picked != null) {
                        setState(() => _playerGroupId = picked.isEmpty ? null : picked);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                      decoration: BoxDecoration(
                        color: _playerGroupId != null ? _kGoldCream : Colors.grey.shade50,
                        borderRadius: const BorderRadius.horizontal(left: Radius.circular(11)),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.home_rounded, size: 14,
                            color: _playerGroupId != null ? _kGoldDark : Colors.black45),
                        const SizedBox(width: 4),
                        Text(
                          _playerGroupId == null
                              ? 'Group'
                              : relevantGroups.firstWhere((c) => c.id == _playerGroupId).name,
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                              color: _playerGroupId != null ? _kGoldDark : Colors.black45),
                        ),
                        const SizedBox(width: 2),
                        Icon(Icons.arrow_drop_down_rounded, size: 16,
                            color: _playerGroupId != null ? _kGoldDark : Colors.black45),
                      ]),
                    ),
                  ),
                if (relevantGroups.isNotEmpty)
                  Container(width: 1, height: 36, color: Colors.grey.shade200),
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: 'Search players…',
                      prefixIcon: const Icon(Icons.search_rounded,
                          size: 18, color: Colors.black45),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 10),
                    ),
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 6),
            if (widget.existingPlayers.isEmpty)
              const Padding(
                padding: EdgeInsets.all(12),
                child: Text('No players in the hub yet.',
                    style: TextStyle(fontSize: 12, color: Colors.black38)),
              )
            else if (filtered.isEmpty)
              const Padding(
                padding: EdgeInsets.all(12),
                child: Text('No players found.',
                    style: TextStyle(fontSize: 12, color: Colors.black38)),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filtered.length.clamp(0, 10),
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (_, i) {
                  final player    = filtered[i];
                  final isCurrent =
                      widget.currentPlayer.appPlayerId == player.id;
                  return ListTile(
                    dense: true,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 4),
                    leading: CircleAvatar(
                      radius: 14,
                      backgroundColor:
                          isCurrent ? _kOlive : _kGoldCream,
                      child: Text(
                        player.name[0].toUpperCase(),
                        style: TextStyle(
                            fontSize: 11,
                            color: isCurrent ? Colors.white : _kGoldDark,
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                    title: Text(player.name,
                        style: const TextStyle(fontSize: 13)),
                    subtitle: player.skillRating != null
                        ? Text('Skill: ${player.skillRating}',
                            style: const TextStyle(fontSize: 11))
                        : const Text('Unrated',
                            style: TextStyle(
                                fontSize: 11, color: Colors.orange)),
                    trailing: isCurrent
                        ? const Icon(Icons.check_rounded,
                            color: _kOlive, size: 18)
                        : const Icon(Icons.add_circle_outline_rounded,
                            color: _kGold, size: 20),
                    onTap: isCurrent
                        ? null
                        : () {
                            widget.onPick(KoPlayerSnapshot(
                              appPlayerId: player.id,
                              name: player.name,
                              skillRating: player.skillRating,
                            ));
                            Navigator.of(context).pop();
                          },
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String label, Color color) => Row(children: [
        Container(
          width: 4, height: 14,
          decoration: BoxDecoration(
              color: color, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 8),
        Text(label,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: color,
                letterSpacing: 0.3)),
        const SizedBox(width: 8),
        Expanded(
            child:
                Divider(height: 1, color: color.withValues(alpha: 0.3))),
      ]);
}
