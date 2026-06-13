import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../app/app_colors.dart';
import '../models/king_of_the_court_tournament.dart';
import '../services/scramble_service.dart';
import '../state/app_state.dart';
import '../widgets/scrollable_page.dart';
import '../widgets/sheet_helpers.dart';
import '../widgets/tournaq_app_bar.dart';
import 'king_of_the_court_scoreboard_page.dart';

class KingOfTheCourtSetupPage extends StatefulWidget {
  final AppState appState;
  final void Function(KingOfTheCourtTournament) onCreated;

  const KingOfTheCourtSetupPage({
    super.key,
    required this.appState,
    required this.onCreated,
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

  static final _rng = Random();
  static const _nameTemplates = [
    ('Golden',    'Throne'),
    ('Royal',     'Rumble'),
    ('Crown',     'Battle'),
    ('Court',     'Kings'),
    ('Champion',  'Chase'),
    ('Iron',      'Throne'),
    ('Neon',      'Kingdom'),
    ('Blazing',   'Crown'),
    ('Friday',    'Kingdom'),
    ('Sunset',    'Royale'),
    ('Electric',  'Court'),
    ('Wild',      'Reign'),
    ('Epic',      'Throne'),
    ('Sneaky',    'King'),
    ('Absolute',  'Royale'),
    ('Groovy',    'Kingdom'),
    ('Tropical',  'Crown'),
    ('Casual',    'Reign'),
    ('Sunday',    'Kingdom'),
    ('Cheeky',    'King'),
  ];

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
    final t = _nameTemplates[_rng.nextInt(_nameTemplates.length)];
    return '${t.$1} ${t.$2}';
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
      builder: (_) => KingOfTheCourtScoreboardPage(
        tournament: session,
        appState:   widget.appState,
        onChanged:  widget.onCreated,
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
                  ? const Text('Tap to add players',
                      style: TextStyle(color: Colors.black38, fontSize: 13))
                  : Text(
                      enough
                          ? '$count players added'
                          : '$count added · need at least $min',
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
    _playerSearchCtrl.clear();
    var searchActive = false;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final query = _playerSearchCtrl.text.toLowerCase();
          final allExisting = widget.appState.players
              .where((u) => !_players.any((p) => p.appUserId == u.id))
              .toList();
          final filteredExisting = query.isEmpty
              ? allExisting
              : allExisting
                  .where((u) => u.name.toLowerCase().contains(query))
                  .toList();

          void rebuild() {
            setSheetState(() {});
            setState(() {});
          }

          void addByName(String name) {
            final trimmed = name.trim();
            if (trimmed.isEmpty) return;
            _players.add(KotcPlayer(
              id:     KotcPlayer.generateId(),
              name:   trimmed,
              source: KotcPlayerSource.created,
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
            final generated = ScrambleService.generateRandomPlayers(needed);
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
                title: const Text('Remove all players?',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700)),
                content: const Text(
                    'This will remove all added players from the list.',
                    style:
                        TextStyle(fontSize: 14, color: Colors.black54)),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(dCtx).pop(false),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(dCtx).pop(true),
                    style: TextButton.styleFrom(
                        foregroundColor: Colors.red),
                    child: const Text('Remove all'),
                  ),
                ],
              ),
            );
            if (confirmed == true) {
              _players.clear();
              rebuild();
            }
          }

          return TournaQSheet(
            body: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Text('Players',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w800)),
                      const Spacer(),
                      if (_players.isNotEmpty)
                        TextButton(
                          onPressed: clearAll,
                          style: TextButton.styleFrom(
                              foregroundColor: Colors.red,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8)),
                          child: const Text('Clear all',
                              style: TextStyle(fontSize: 13)),
                        ),
                      Text(
                        '${_players.length} / $_targetPlayerCount',
                        style: const TextStyle(
                            color: Colors.black45, fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Add by name
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _playerNameCtrl,
                          textCapitalization: TextCapitalization.words,
                          decoration: _inputDecoration(hint: 'Player name'),
                          onSubmitted: addByName,
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () => addByName(_playerNameCtrl.text),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.olive,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Add'),
                      ),
                    ],
                  ),

                  // Existing players
                  if (allExisting.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _fieldLabel(
                        'Existing Players (${allExisting.length})'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _playerSearchCtrl,
                      decoration: InputDecoration(
                        hintText: 'Search players…',
                        isDense: true,
                        prefixIcon: const Icon(Icons.search_rounded,
                            size: 18, color: Colors.black45),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                      ),
                      onTap: () => setSheetState(() => searchActive = true),
                      onChanged: (_) =>
                          setSheetState(() => searchActive = true),
                    ),
                    if (searchActive) ...[
                      const SizedBox(height: 6),
                      if (filteredExisting.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Text('No players match.',
                              style: TextStyle(
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
                                  style:
                                      const TextStyle(fontSize: 13)),
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
                    ],
                  ],

                  // Fill random + added list
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _fieldLabel(
                          'Added (${_players.length}/$_targetPlayerCount)'),
                      TextButton.icon(
                        onPressed: _players.length < _targetPlayerCount
                            ? fillRandom
                            : null,
                        icon:
                            const Icon(Icons.shuffle_rounded, size: 16),
                        label: Text(
                            'Fill ${(_targetPlayerCount - _players.length).clamp(0, 999)} random'),
                        style: TextButton.styleFrom(
                            foregroundColor: AppColors.olive),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  if (_players.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text('No players added yet.',
                          style: TextStyle(
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
                            side:
                                BorderSide(color: Colors.grey.shade200),
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
    final canCreate = _canCreate;

    return Scaffold(
      appBar: const TournaQAppBar(
          title: 'King of the Court', subtitle: 'New Tournament'),
      body: ScrollablePage(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Config grid ───────────────────────────────────────────────────
            _sectionHeader('Tournament Setup', Icons.tune_rounded),
            const SizedBox(height: 14),

            // Row 1 — players / time
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _comboField(
                    label:    'Players',
                    ctrl:     _playerCountCtrl,
                    presets:  [4, 6, 8, 10, 12, 16, 20, 24],
                    onParsed: (v) => _targetPlayerCount = v.clamp(4, 64),
                    helpText: 'Target number of players for the session. '
                        'Used when auto-filling random players. '
                        'Actual participants are added in the Players section below.',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _comboField(
                    label:    'Time',
                    ctrl:     _totalMinCtrl,
                    presets:  [30, 45, 60, 90, 120, 180, 240],
                    onParsed: (v) => _totalMinutes = v.clamp(1, 999),
                    unit:     'min',
                    helpText: 'Total session duration. The timer counts down '
                        'from this value. When time runs out you will be '
                        'prompted to complete the tournament or keep scoring.',
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
                    label:    'Strike Points (0 = off)',
                    ctrl:     _strikeCtrl,
                    presets:  [0, 3, 5, 7, 10, 15, 21],
                    onParsed: (v) => _strikePoints = v.clamp(0, 999),
                    helpText: 'Points a team must score to win the game and be '
                        'ejected as winners. Set to 0 to disable — teams stay '
                        'on court until the coach manually ejects them.',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── Players ───────────────────────────────────────────────────────
            const Divider(),
            const SizedBox(height: 16),
            _sectionHeader('Players', Icons.group_rounded),
            const SizedBox(height: 12),
            _buildPlayersSummaryCard(),

            // ── Name ─────────────────────────────────────────────────────────
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            _fieldLabel('Tournament Name',
                help: 'A name for this session, used to identify '
                    'it in your tournament history.'),
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
                    canCreate ? 'Setup looks good!' : 'Setup incomplete',
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
              child: const Text(
                'Create Tournament',
                style: TextStyle(
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _fieldLabel('Style',
            help: 'The format of each game — 2vs2, 3vs3, and so on. '
                'Sets how many players make up each team on court.'),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _fieldLabel('Assignment',
            help: 'How the next court team is chosen.\n\n'
                'Manual — the coach selects players from the queue by tapping them.\n\n'
                'Automated — TournaQ suggests the best team, prioritising players '
                'who have waited longest and haven\'t been paired together recently. '
                'The coach can re-roll before confirming.'),
        const SizedBox(height: 6),
        DropdownButtonFormField<KotcAssignmentMode>(
          initialValue: _assignmentMode,
          isDense: true,
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
          items: const [
            DropdownMenuItem(
              value: KotcAssignmentMode.manual,
              child: Text('Manual'),
            ),
            DropdownMenuItem(
              value: KotcAssignmentMode.automated,
              child: Text('Automated'),
            ),
          ],
          onChanged: (v) {
            if (v != null) setState(() => _assignmentMode = v);
          },
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
            const Text(
              'Courts',
              style: TextStyle(
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
                  title: const Text('Courts',
                      style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700)),
                  content: const Text(
                    'Currently fixed at 1 court.\n\n'
                    'Multi-court support — assign and track multiple '
                    'simultaneous courts with optimal rotation — is planned '
                    'for a future release.',
                    style: TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                        height: 1.5),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: const Text('Got it',
                          style:
                              TextStyle(fontWeight: FontWeight.w600)),
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
            child: const Text('Got it'),
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
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      );

  Color _sourceColor(KotcPlayerSource s) => switch (s) {
        KotcPlayerSource.existing => AppColors.olive,
        KotcPlayerSource.created  => AppColors.goldDark,
        KotcPlayerSource.random   => Colors.blueGrey,
      };

  String _sourceLabel(KotcPlayerSource s) => switch (s) {
        KotcPlayerSource.existing => 'Existing player',
        KotcPlayerSource.created  => 'New player',
        KotcPlayerSource.random   => 'Random placeholder',
      };
}
