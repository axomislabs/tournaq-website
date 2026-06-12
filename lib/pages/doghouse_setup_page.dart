import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../app/app_colors.dart';
import '../models/doghouse_drill.dart';
import '../services/scramble_service.dart';
import '../state/app_state.dart';
import '../widgets/scrollable_page.dart';
import '../widgets/sheet_helpers.dart';
import '../widgets/tournaq_app_bar.dart';
import 'doghouse_scoreboard_page.dart';

const _kGold      = AppColors.goldDark;
const _kGoldLight = AppColors.goldCream;

class DoghouseSetupPage extends StatefulWidget {
  final AppState appState;
  final void Function(DoghouseTournament) onCreated;

  const DoghouseSetupPage({
    super.key,
    required this.appState,
    required this.onCreated,
  });

  @override
  State<DoghouseSetupPage> createState() => _DoghouseSetupPageState();
}

class _DoghouseSetupPageState extends State<DoghouseSetupPage> {
  int _targetPlayerCount = 8;
  int _totalMinutes      = 60;
  int _playersPerTeam    = 2;
  int _escapePoints      = 3;
  int _ejectThreshold    = 3;

  late final TextEditingController _playerCountCtrl;
  late final TextEditingController _totalMinCtrl;
  late final TextEditingController _escapeCtrl;
  late final TextEditingController _ejectCtrl;

  final _nameCtrl        = TextEditingController();
  final _playerNameCtrl  = TextEditingController();
  final _playerSearchCtrl = TextEditingController();

  final List<DoghousePlayer> _players = [];

  static final _rng = Random();
  static const _nameTemplates = [
    ('Escape',   'Session'),
    ('Doghouse', 'Dash'),
    ('Side',     'Out'),
    ('Break',    'Out'),
    ('Hustle',   'Hour'),
    ('Serving',  'Time'),
    ('Back',     'Yard'),
    ('Grind',    'Session'),
    ('Serve',    'Battle'),
    ('Net',      'Breaker'),
    ('Rally',    'Rumble'),
    ('Beach',    'Grind'),
    ('Sand',     'Session'),
    ('Court',    'Battle'),
    ('Block',    'Party'),
    ('Spike',    'Session'),
    ('Sand',     'Storm'),
    ('Power',    'Serve'),
    ('Hard',     'Court'),
    ('Game',     'Day'),
  ];

  @override
  void initState() {
    super.initState();
    _playerCountCtrl = TextEditingController(text: '$_targetPlayerCount');
    _totalMinCtrl    = TextEditingController(text: '$_totalMinutes');
    _escapeCtrl      = TextEditingController(text: '$_escapePoints');
    _ejectCtrl       = TextEditingController(text: '$_ejectThreshold');
    _nameCtrl.text   = _randomName();
  }

  @override
  void dispose() {
    _playerCountCtrl.dispose();
    _totalMinCtrl.dispose();
    _escapeCtrl.dispose();
    _ejectCtrl.dispose();
    _nameCtrl.dispose();
    _playerNameCtrl.dispose();
    _playerSearchCtrl.dispose();
    super.dispose();
  }

  String _randomName() {
    final t = _nameTemplates[_rng.nextInt(_nameTemplates.length)];
    return '${t.$1} ${t.$2}';
  }

  int get _minPlayers => _playersPerTeam * 2;

  bool get _canCreate =>
      _nameCtrl.text.trim().isNotEmpty &&
      _totalMinutes > 0 &&
      _players.length >= _minPlayers;

  void _create() {
    if (!_canCreate) return;
    final tournament = DoghouseTournament(
      id:             DoghouseTournament.generateId(),
      name:           _nameCtrl.text.trim(),
      totalTime:      Duration(minutes: _totalMinutes),
      playersPerTeam: _playersPerTeam,
      courtCount:     1,
      escapePoints:   _escapePoints,
      ejectThreshold: _ejectThreshold,
      status:         DoghouseTournamentStatus.setup,
      players:        List.from(_players),
      games:          [],
      createdAt:      DateTime.now(),
    );
    widget.onCreated(tournament);
    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (_) => DoghouseScoreboardPage(
        tournament: tournament,
        appState:   widget.appState,
        onChanged:  widget.onCreated,
      ),
    ));
  }

  // ── Players summary card ──────────────────────────────────────────────────

  Widget _buildPlayersSummaryCard() {
    final count  = _players.length;
    final min    = _minPlayers;
    final enough = count >= min;
    final hasAny = count > 0;

    final borderColor = hasAny && !enough
        ? Colors.red.shade300
        : enough
            ? _kGold
            : Colors.grey.shade300;
    final bgColor = hasAny && !enough
        ? Colors.red.shade50
        : enough
            ? _kGoldLight
            : Colors.grey.shade50;
    final iconColor = hasAny && !enough
        ? Colors.red.shade600
        : enough
            ? _kGold
            : Colors.black38;
    final textColor = hasAny && !enough
        ? Colors.red.shade700
        : enough
            ? _kGold
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

  // ── Players sheet ─────────────────────────────────────────────────────────

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
            _players.add(DoghousePlayer(
              id:     DoghousePlayer.generateId(),
              name:   trimmed,
              source: DoghousePlayerSource.created,
            ));
            _playerNameCtrl.clear();
            rebuild();
          }

          void addExisting(String appUserId, String name) {
            if (_players.any((p) => p.appUserId == appUserId)) return;
            _players.add(DoghousePlayer(
              id:        DoghousePlayer.generateId(),
              name:      name,
              source:    DoghousePlayerSource.existing,
              appUserId: appUserId,
            ));
            rebuild();
          }

          void fillRandom() {
            final needed = _targetPlayerCount - _players.length;
            if (needed <= 0) return;
            final generated = ScrambleService.generateRandomPlayers(needed);
            for (final p in generated) {
              _players.add(DoghousePlayer(
                id:     DoghousePlayer.generateId(),
                name:   p.name,
                source: DoghousePlayerSource.random,
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
                          backgroundColor: _kGold,
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

                  if (allExisting.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _fieldLabel('Existing Players (${allExisting.length})'),
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
                                    color: _kGold),
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
                        icon: const Icon(Icons.shuffle_rounded, size: 16),
                        label: Text(
                            'Fill ${(_targetPlayerCount - _players.length).clamp(0, 999)} random'),
                        style: TextButton.styleFrom(
                            foregroundColor: _kGold),
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

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final canCreate = _canCreate;

    return Scaffold(
      appBar: const TournaQAppBar(title: 'Doghouse', subtitle: 'New Tournament'),
      body: ScrollablePage(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Row 2 — style
            _styleField(),
            const SizedBox(height: 14),

            // Row 3 — escape points / eject threshold
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _comboField(
                    label:    'Escape Points',
                    ctrl:     _escapeCtrl,
                    presets:  [1, 2, 3, 5, 7, 10],
                    onParsed: (v) => _escapePoints = v.clamp(1, 999),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _comboField(
                    label:    'Eject Threshold',
                    ctrl:     _ejectCtrl,
                    presets:  [1, 2, 3, 5, 7, 10],
                    onParsed: (v) => _ejectThreshold = v.clamp(1, 999),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            const Divider(),
            const SizedBox(height: 16),
            _sectionHeader('Players', Icons.group_rounded),
            const SizedBox(height: 12),
            _buildPlayersSummaryCard(),

            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            _fieldLabel('Tournament Name'),
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

            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Icon(
                    canCreate
                        ? Icons.check_circle_rounded
                        : Icons.error_outline_rounded,
                    color: canCreate ? _kGold : Colors.red.shade600,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    canCreate ? 'Setup looks good!' : 'Setup incomplete',
                    style: TextStyle(
                      color: canCreate ? _kGold : Colors.red.shade600,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: canCreate ? _create : null,
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

  // ── Style dropdown ────────────────────────────────────────────────────────

  Widget _styleField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Style',
          style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.black54),
        ),
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

  // ── Combo field ───────────────────────────────────────────────────────────

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
        Text(
          label,
          style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.black54),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10)),
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

  Widget _fieldLabel(String text) => Text(
        text,
        style: const TextStyle(
            fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black54),
      );

  InputDecoration _inputDecoration({String? hint}) => InputDecoration(
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      );

  Color _sourceColor(DoghousePlayerSource s) => switch (s) {
        DoghousePlayerSource.existing => AppColors.olive,
        DoghousePlayerSource.created  => _kGold,
        DoghousePlayerSource.random   => Colors.blueGrey,
      };

  String _sourceLabel(DoghousePlayerSource s) => switch (s) {
        DoghousePlayerSource.existing => 'Existing player',
        DoghousePlayerSource.created  => 'New player',
        DoghousePlayerSource.random   => 'Random placeholder',
      };
}
