import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../app/app_colors.dart';
import '../models/scramble_tournament.dart';
import '../services/scramble_service.dart';
import '../state/app_state.dart';
import '../widgets/scramble_suggestion_card.dart';
import '../widgets/scrollable_page.dart';
import '../widgets/sheet_helpers.dart';
import '../widgets/tournaq_app_bar.dart';
import 'scramble_overview_page.dart';

class ScrambleSetupPage extends StatefulWidget {
  final AppState appState;
  final void Function(ScrambleTournament) onCreated;

  const ScrambleSetupPage({
    super.key,
    required this.appState,
    required this.onCreated,
  });

  @override
  State<ScrambleSetupPage> createState() => _ScrambleSetupPageState();
}

class _ScrambleSetupPageState extends State<ScrambleSetupPage> {
  // ── Config ints ──────────────────────────────────────────────────────────────
  int _targetPlayerCount = 8;
  int _totalMinutes = 60;
  int _matchMinutes = 4;
  int _courtCount = 1;
  int _playersPerTeam = 2;
  int _breakMinutes = 1;

  // ── Config text controllers (combo fields) ───────────────────────────────────
  late final TextEditingController _targetPlayerCtrl;
  late final TextEditingController _totalMinCtrl;
  late final TextEditingController _matchMinCtrl;
  late final TextEditingController _courtCtrl;
  late final TextEditingController _breakMinCtrl;

  // ── Start / end time ─────────────────────────────────────────────────────────
  bool _startIsNow = true;
  late TimeOfDay _startTime;

  // ── Name (moved to bottom) ────────────────────────────────────────────────────
  final _nameCtrl = TextEditingController();

  // ── Players ───────────────────────────────────────────────────────────────────
  final List<ScramblePlayer> _players = [];
  final _playerNameCtrl   = TextEditingController();
  final _playerSearchCtrl = TextEditingController();

  static final _rng = Random();
  static const _nameTemplates = [
    ('Wild',      'Scramble'),
    ('Lazy',      'Shuffle'),
    ('Happy',     'Chaos'),
    ('Sneaky',    'Mixer'),
    ('Tropical',  'Frenzy'),
    ('Sunset',    'Blitz'),
    ('Neon',      'Scramble'),
    ('Blazing',   'Mix-Up'),
    ('Groovy',    'Shakedown'),
    ('Friendly',  'Rumble'),
    ('Casual',    'Bash'),
    ('Electric',  'Fiesta'),
    ('Cheeky',    'Shuffle'),
    ('Breezy',    'Scramble'),
    ('Absolute',  'Chaos'),
    ('Epic',      'Mixer'),
    ('Sneaky',    'Frenzy'),
    ('Disco',     'Scramble'),
    ('Friday',    'Shuffle'),
    ('Sunday',    'Blitz'),
  ];

  @override
  void initState() {
    super.initState();
    _startTime        = TimeOfDay.now();
    _targetPlayerCtrl = TextEditingController(text: '$_targetPlayerCount');
    _totalMinCtrl     = TextEditingController(text: '$_totalMinutes');
    _matchMinCtrl     = TextEditingController(text: '$_matchMinutes');
    _courtCtrl        = TextEditingController(text: '$_courtCount');
    _breakMinCtrl     = TextEditingController(text: '$_breakMinutes');
    _nameCtrl.text    = _randomName();
  }

  @override
  void dispose() {
    _targetPlayerCtrl.dispose();
    _totalMinCtrl.dispose();
    _matchMinCtrl.dispose();
    _courtCtrl.dispose();
    _breakMinCtrl.dispose();
    _nameCtrl.dispose();
    _playerNameCtrl.dispose();
    _playerSearchCtrl.dispose();
    super.dispose();
  }

  // ── Computed ─────────────────────────────────────────────────────────────────

  String _randomName() {
    final t = _nameTemplates[_rng.nextInt(_nameTemplates.length)];
    return '${t.$1} ${t.$2}';
  }

  Duration get _totalTime     => Duration(minutes: _totalMinutes);
  Duration get _matchDuration => Duration(minutes: _matchMinutes);
  Duration get _breakDuration => Duration(minutes: _breakMinutes);

  int get _activeCourts =>
      min(_courtCount, _players.length ~/ (_playersPerTeam * 2));

  List<ScrambleSuggestion> get _suggestions => ScrambleService.validate(
        totalAvailableTime: _totalTime,
        matchDuration:      _matchDuration,
        breakDuration:      _breakDuration,
        courtCount:         _courtCount,
        playerCount:        _targetPlayerCount,
        playersPerTeam:     _playersPerTeam,
      );

  // ── Time helpers ─────────────────────────────────────────────────────────────

  TimeOfDay _resolveStart() =>
      _startIsNow ? TimeOfDay.now() : _startTime;

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
    final picked = await showTimePicker(
      context: context,
      initialTime: _resolveStart(),
    );
    if (picked == null) return;
    setState(() {
      _startTime   = picked;
      _startIsNow  = false;
    });
  }

  Future<void> _pickEndTime() async {
    final start  = _resolveStart();
    final picked = await showTimePicker(
      context: context,
      initialTime: _addMinutesToTime(start, _totalMinutes),
    );
    if (picked == null) return;
    final startMins = start.hour * 60 + start.minute;
    var   endMins   = picked.hour * 60 + picked.minute;
    if (endMins <= startMins) endMins += 24 * 60; // handle overnight
    final newTotal = endMins - startMins;
    setState(() {
      _totalMinutes      = newTotal;
      _totalMinCtrl.text = '$newTotal';
    });
  }

  bool get _canCreate =>
      _nameCtrl.text.trim().isNotEmpty &&
      _matchMinutes > 0 &&
      _totalMinutes > 0 &&
      _players.length == _targetPlayerCount &&
      !_suggestions.any((s) => s.isBlocking);

  // ── Actions ──────────────────────────────────────────────────────────────────

  void _create() {
    final tournament = ScrambleService.buildTournament(
      name:               _nameCtrl.text.trim(),
      totalAvailableTime: _totalTime,
      matchDuration:      _matchDuration,
      breakDuration:      _breakDuration,
      courtCount:         _courtCount,
      playersPerTeam:     _playersPerTeam,
      players:            _players,
      startTime:          _resolveStartDateTime(),
    );
    widget.onCreated(tournament);
    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (_) => ScrambleOverviewPage(
        tournament: tournament,
        onChanged:  widget.onCreated,
      ),
    ));
  }

  void _applySuggestion(ScrambleSuggestion s) {
    setState(() {
      switch (s.type) {
        case ScrambleSuggestionType.increaseTotalTime:
          _totalMinutes += (_matchMinutes + _breakMinutes) * 3;
          _totalMinCtrl.text = '$_totalMinutes';
        case ScrambleSuggestionType.reduceBreakDuration:
          _breakMinutes = max(0, _breakMinutes - 2);
          _breakMinCtrl.text = '$_breakMinutes';
        case ScrambleSuggestionType.adjustCourtCount:
          _courtCount = _activeCourts;
          _courtCtrl.text = '$_courtCount';
        case ScrambleSuggestionType.repeatedTeammates:
        case ScrambleSuggestionType.adjustMatchDuration:
        case ScrambleSuggestionType.adjustPlayerCount:
          break;
      }
    });
  }

  // ── Players summary card & sheet ─────────────────────────────────────────────

  Widget _buildPlayersSummaryCard() {
    final count  = _players.length;
    final target = _targetPlayerCount;
    final exact  = count == target;
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
                  ? const Text('Tap to add players',
                      style: TextStyle(color: Colors.black38, fontSize: 13))
                  : Text(
                      '$count/$target players added',
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
            _players.add(ScramblePlayer(
              id:     ScramblePlayer.generateId(),
              name:   trimmed,
              source: ScramblePlayerSource.created,
            ));
            _playerNameCtrl.clear();
            rebuild();
          }

          void addExisting(String appUserId, String name) {
            if (_players.any((p) => p.appUserId == appUserId)) return;
            _players.add(ScramblePlayer(
              id:        ScramblePlayer.generateId(),
              name:      name,
              source:    ScramblePlayerSource.existing,
              appUserId: appUserId,
            ));
            rebuild();
          }

          void fillRandom() {
            final needed = _targetPlayerCount - _players.length;
            if (needed <= 0) return;
            _players.addAll(ScrambleService.generateRandomPlayers(needed));
            rebuild();
          }

          void remove(int i) {
            _players.removeAt(i);
            rebuild();
          }

          void clearAll() async {
            final confirmed = await showDialog<bool>(
              context: ctx,
              builder: (dCtx) => AlertDialog(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                title: const Text('Remove all players?',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                content: const Text(
                    'This will remove all added players from the list.',
                    style: TextStyle(fontSize: 14, color: Colors.black54)),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(dCtx).pop(false),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(dCtx).pop(true),
                    style:
                        TextButton.styleFrom(foregroundColor: Colors.red),
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
                  // Header
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

                  // Existing players — searchable list
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
                      onTap: () =>
                          setSheetState(() => searchActive = true),
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
                    ],
                  ],

                  // Fill random + count
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
                            'Fill ${_targetPlayerCount - _players.length} random'),
                        style: TextButton.styleFrom(
                            foregroundColor: AppColors.olive),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Added player list
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
                            side: BorderSide(color: Colors.grey.shade200),
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
                                  fontSize: 10, color: Colors.black38)),
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

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final suggestions = _suggestions;
    final canCreate   = _canCreate;

    return Scaffold(
      appBar: TournaQAppBar(title: 'Social Scramble', subtitle: 'New Tournament'),
      body: ScrollablePage(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [

            // ── Config grid ───────────────────────────────────────────────────
            _sectionHeader('Tournament Setup', Icons.tune_rounded),
            const SizedBox(height: 14),

            // Row 1 — target players / available time
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _comboField(
                    label:    'Target Players',
                    ctrl:     _targetPlayerCtrl,
                    presets:  [4, 6, 8, 10, 12, 16, 20, 24],
                    onParsed: (v) => _targetPlayerCount = v.clamp(4, 64),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _comboField(
                    label:    'Available Time',
                    ctrl:     _totalMinCtrl,
                    presets:  [30, 45, 60, 90, 120, 180, 240],
                    onParsed: (v) => _totalMinutes = v.clamp(1, 999),
                    unit:     'min',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Row 2 — match duration / courts
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _comboField(
                    label:    'Match Duration',
                    ctrl:     _matchMinCtrl,
                    presets:  [5, 8, 10, 12, 15, 20, 25, 30],
                    onParsed: (v) => _matchMinutes = v.clamp(1, 999),
                    unit:     'min',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _comboField(
                    label:    'Courts',
                    ctrl:     _courtCtrl,
                    presets:  [1, 2, 3, 4, 5, 6, 8],
                    onParsed: (v) => _courtCount = v.clamp(1, 32),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Row 3 — format / break
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _formatField()),
                const SizedBox(width: 12),
                Expanded(
                  child: _comboField(
                    label:    'Break Between Rounds',
                    ctrl:     _breakMinCtrl,
                    presets:  [0, 2, 3, 5, 7, 10],
                    onParsed: (v) => _breakMinutes = v.clamp(0, 999),
                    unit:     'min',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Row 4 — start time / end time
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _tapField(
                  label:    'Planned Start Time',
                  value:    _startIsNow ? 'Now' : _fmtTod(_startTime),
                  onTap:    _pickStartTime,
                  trailing: _startIsNow
                      ? const Icon(Icons.access_time_rounded, size: 18, color: Colors.black45)
                      : GestureDetector(
                          onTap: () => setState(() => _startIsNow = true),
                          child: const Icon(Icons.refresh_rounded, size: 18, color: Colors.black45),
                        ),
                )),
                const SizedBox(width: 12),
                Expanded(child: _tapField(
                  label: 'Planned End Time',
                  value: _fmtTod(_addMinutesToTime(_resolveStart(), _totalMinutes)),
                  onTap: _pickEndTime,
                  trailing: const Icon(Icons.access_time_rounded, size: 18, color: Colors.black45),
                )),
              ],
            ),
            const SizedBox(height: 20),

            // Schedule preview (live)
            _schedulePreview(),

            // ── Suggestions ───────────────────────────────────────────────────
            if (suggestions.isNotEmpty) ...[
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),
              _sectionHeader('Suggestions', Icons.lightbulb_outline_rounded),
              const SizedBox(height: 12),
              ...suggestions.map((s) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: ScrambleSuggestionCard(
                      suggestion: s,
                      onAction: s.actionLabel != null
                          ? () => _applySuggestion(s)
                          : null,
                    ),
                  )),
            ],

            // ── Players ───────────────────────────────────────────────────────
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            _sectionHeader('Players', Icons.group_rounded),
            const SizedBox(height: 12),
            _buildPlayersSummaryCard(),

            // ── Name (bottom) ─────────────────────────────────────────────────
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

            // ── Status + Create button ────────────────────────────────────────
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Icon(
                    canCreate
                        ? Icons.check_circle_rounded
                        : Icons.error_outline_rounded,
                    color: canCreate ? AppColors.olive : Colors.red.shade600,
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
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Schedule Preview ─────────────────────────────────────────────────────────

  // Inline gcd so the preview doesn't depend on the private ScrambleService._gcd.
  static int _gcd(int a, int b) => b == 0 ? a : _gcd(b, a % b);

  Widget _schedulePreview() {
    final roundMin        = _matchMinutes + _breakMinutes;
    final playersPerCourt = _playersPerTeam * 2;
    final activePlayers   =
        min(_courtCount, _targetPlayerCount ~/ playersPerCourt) * playersPerCourt;
    final sittingOut      = _targetPlayerCount - activePlayers;
    final rawRounds       = roundMin > 0 ? _totalMinutes ~/ roundMin : 0;

    int rounds;
    if (sittingOut > 0 && activePlayers > 0 && rawRounds > 0) {
      final fairUnit = _targetPlayerCount ~/ _gcd(_targetPlayerCount, activePlayers);
      final snapped  = (rawRounds ~/ fairUnit) * fairUnit;
      rounds = snapped > 0 ? snapped : rawRounds;
    } else {
      rounds = rawRounds;
    }
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.oliveLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Schedule Preview',
            style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: AppColors.olive),
          ),
          const SizedBox(height: 8),
          _previewRow('Round duration',
              '${_matchMinutes}m match + ${_breakMinutes}m break = ${roundMin}m'),
          _previewRow('Rounds', '$rounds'),
          () {
            final scheduledMins = rounds * roundMin;
            final h = scheduledMins ~/ 60;
            final m = scheduledMins % 60;
            final durationStr = h > 0 ? '${h}h ${m}m' : '${m}m';
            final endTime     = _addMinutesToTime(_resolveStart(), scheduledMins);
            return Column(
              children: [
                _previewRow('Scheduled duration', durationStr),
                _previewRow('Scheduled end time', _fmtTod(endTime)),
              ],
            );
          }(),
        ],
      ),
    );
  }

  Widget _previewRow(String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 3),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: const TextStyle(fontSize: 12, color: Colors.black54)),
            Text(value,
                style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
      );

  // ── Combo field (text input + presets popup) ─────────────────────────────────

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

  // ── Format dropdown ───────────────────────────────────────────────────────────

  Widget _formatField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Format',
          style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.black54),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<int>(
          // ignore: deprecated_member_use
          value: _playersPerTeam,
          isDense: true,
          decoration: InputDecoration(
            contentPadding:
                const EdgeInsets.fromLTRB(12, 10, 4, 10),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
          items: [2, 3, 4]
              .map((n) => DropdownMenuItem(
                    value: n,
                    child: Text('${n}v$n'),
                  ))
              .toList(),
          onChanged: (v) {
            if (v != null) setState(() => _playersPerTeam = v);
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

  Widget _fieldLabel(String text) => Text(
        text,
        style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.black54),
      );

  Widget _tapField({
    required String label,
    required String value,
    required VoidCallback onTap,
    Widget? trailing,
  }) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.black54)),
          const SizedBox(height: 6),
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade600),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Expanded(child: Text(value)),
                  if (trailing case final Widget t) t,
                ],
              ),
            ),
          ),
        ],
      );

  InputDecoration _inputDecoration({String? hint}) => InputDecoration(
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      );

  Color _sourceColor(ScramblePlayerSource s) => switch (s) {
        ScramblePlayerSource.existing => AppColors.olive,
        ScramblePlayerSource.created  => AppColors.goldDark,
        ScramblePlayerSource.random   => Colors.blueGrey,
      };

  String _sourceLabel(ScramblePlayerSource s) => switch (s) {
        ScramblePlayerSource.existing => 'Existing player',
        ScramblePlayerSource.created  => 'New player',
        ScramblePlayerSource.random   => 'Random placeholder',
      };
}
