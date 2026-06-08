import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../app/app_colors.dart';
import '../models/scramble_tournament.dart';
import '../services/scramble_service.dart';
import '../state/app_state.dart';
import '../widgets/scramble_suggestion_card.dart';
import '../widgets/scrollable_page.dart';
import '../widgets/tournaq_app_bar.dart';
import 'scramble_overview_page.dart';

/// Multi-step setup screen for a new Timed Scramble tournament.
///
/// Steps:
///   1. Basic config: name, total time, match duration, break duration, courts
///   2. Players: select existing, create new, or fill with randoms
///   3. Review: suggestions + confirm
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
  // ── Step tracking ───────────────────────────────────────────────────────────
  int _step = 0;
  static const _totalSteps = 3;

  // ── Step 1 fields ───────────────────────────────────────────────────────────
  final _nameCtrl = TextEditingController();
  int _totalMinutes = 60;
  int _matchMinutes = 12;
  int _breakMinutes = 3;
  int _courtCount = 2;
  int _playersPerTeam = 2;

  static final _rng = Random();
  static const _namePrefixes = [
    'Summer', 'Beach', 'Open', 'City', 'Grand', 'Spring', 'Evening'
  ];
  static const _nameSuffixes = [
    'Scramble', 'Mix', 'Shuffle', 'Mixer', 'Chaos Cup', 'Remix'
  ];

  // ── Step 2 fields ───────────────────────────────────────────────────────────
  final List<ScramblePlayer> _players = [];
  final _playerNameCtrl = TextEditingController();
  int _targetPlayerCount = 8;

  // ── Step 3 ──────────────────────────────────────────────────────────────────
  List<ScrambleSuggestion> _suggestions = [];

  @override
  void initState() {
    super.initState();
    _nameCtrl.text = _randomName();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _playerNameCtrl.dispose();
    super.dispose();
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  String _randomName() =>
      '${_namePrefixes[_rng.nextInt(_namePrefixes.length)]} '
      '${_nameSuffixes[_rng.nextInt(_nameSuffixes.length)]} '
      '${DateTime.now().year}';

  Duration get _totalTime => Duration(minutes: _totalMinutes);
  Duration get _matchDuration => Duration(minutes: _matchMinutes);
  Duration get _breakDuration => Duration(minutes: _breakMinutes);

  int get _activeCourts =>
      min(_courtCount, _players.length ~/ (_playersPerTeam * 2));

  int get _roundCount {
    final rd = _matchMinutes + _breakMinutes;
    return rd > 0 ? _totalMinutes ~/ rd : 0;
  }

  void _goNext() {
    if (_step == 1) _computeSuggestions();
    if (_step < _totalSteps - 1) setState(() => _step++);
  }

  void _goBack() {
    if (_step > 0) setState(() => _step--);
  }

  void _computeSuggestions() {
    _suggestions = ScrambleService.validate(
      totalAvailableTime: _totalTime,
      matchDuration: _matchDuration,
      breakDuration: _breakDuration,
      courtCount: _courtCount,
      playerCount: _players.length,
      playersPerTeam: _playersPerTeam,
    );
  }

  bool get _step1Valid =>
      _nameCtrl.text.trim().isNotEmpty &&
      _matchMinutes > 0 &&
      _totalMinutes > 0;

  bool get _step2Valid => _players.length >= _playersPerTeam * 2;

  void _create() {
    final tournament = ScrambleService.buildTournament(
      name: _nameCtrl.text.trim(),
      totalAvailableTime: _totalTime,
      matchDuration: _matchDuration,
      breakDuration: _breakDuration,
      courtCount: _courtCount,
      playersPerTeam: _playersPerTeam,
      players: _players,
      startTime: DateTime.now(),
    );
    widget.onCreated(tournament);
    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (_) => ScrambleOverviewPage(
        tournament: tournament,
        onChanged: widget.onCreated,
      ),
    ));
  }

  // ── Player helpers ───────────────────────────────────────────────────────────

  void _addPlayerByName(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    setState(() {
      _players.add(ScramblePlayer(
        id: ScramblePlayer.generateId(),
        name: trimmed,
        source: ScramblePlayerSource.created,
      ));
    });
    _playerNameCtrl.clear();
  }

  void _addExistingPlayer(String appUserId, String name) {
    if (_players.any((p) => p.appUserId == appUserId)) return;
    setState(() {
      _players.add(ScramblePlayer(
        id: ScramblePlayer.generateId(),
        name: name,
        source: ScramblePlayerSource.existing,
        appUserId: appUserId,
      ));
    });
  }

  void _fillWithRandom() {
    final needed = _targetPlayerCount - _players.length;
    if (needed <= 0) return;
    setState(() {
      _players.addAll(ScrambleService.generateRandomPlayers(needed));
    });
  }

  void _removePlayer(int index) {
    setState(() => _players.removeAt(index));
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TournaQAppBar(
        title: 'Timed Scramble Setup',
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Center(
              child: Text(
                'Step ${_step + 1}/$_totalSteps',
                style: const TextStyle(
                    color: AppColors.goldCream, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
      body: ScrollablePage(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildProgressBar(),
            const SizedBox(height: 24),
            if (_step == 0) _buildStep1(),
            if (_step == 1) _buildStep2(),
            if (_step == 2) _buildStep3(),
            const SizedBox(height: 32),
            _buildNavButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    return Row(
      children: List.generate(_totalSteps, (i) {
        final active = i <= _step;
        return Expanded(
          child: Container(
            height: 4,
            margin: EdgeInsets.only(left: i > 0 ? 4 : 0),
            decoration: BoxDecoration(
              color: active ? AppColors.olive : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      }),
    );
  }

  // ── Step 1: Basic Config ─────────────────────────────────────────────────────

  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('Tournament Name'),
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
        const SizedBox(height: 20),
        _sectionLabel('Total Available Time'),
        const SizedBox(height: 8),
        _minutePicker(
          value: _totalMinutes,
          options: [30, 45, 60, 90, 120, 180, 240],
          onChanged: (v) => setState(() => _totalMinutes = v),
        ),
        const SizedBox(height: 20),
        _sectionLabel('Match Duration'),
        const SizedBox(height: 8),
        _minutePicker(
          value: _matchMinutes,
          options: [5, 8, 10, 12, 15, 20, 25, 30],
          onChanged: (v) => setState(() => _matchMinutes = v),
        ),
        const SizedBox(height: 20),
        _sectionLabel('Break Between Rounds'),
        const SizedBox(height: 8),
        _minutePicker(
          value: _breakMinutes,
          options: [0, 2, 3, 5, 7, 10],
          onChanged: (v) => setState(() => _breakMinutes = v),
        ),
        const SizedBox(height: 20),
        _sectionLabel('Number of Courts'),
        const SizedBox(height: 8),
        _intPicker(
          value: _courtCount,
          min: 1,
          max: 8,
          onChanged: (v) => setState(() => _courtCount = v),
        ),
        const SizedBox(height: 20),
        _sectionLabel('Players per Team'),
        const SizedBox(height: 8),
        Row(
          children: [2, 3].map((n) => Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text('${n}v$n'),
              selected: _playersPerTeam == n,
              selectedColor: AppColors.goldCream,
              checkmarkColor: AppColors.goldDark,
              onSelected: (_) => setState(() => _playersPerTeam = n),
            ),
          )).toList(),
        ),
        const SizedBox(height: 24),
        _schedulePreview(),
      ],
    );
  }

  Widget _schedulePreview() {
    final roundMin = _matchMinutes + _breakMinutes;
    final rounds = roundMin > 0 ? _totalMinutes ~/ roundMin : 0;
    final playersPerCourt = _playersPerTeam * 2;
    // Preview uses a placeholder player count — shown live in Step 2 review.
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.oliveLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Schedule Preview',
              style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: AppColors.olive)),
          const SizedBox(height: 8),
          _previewRow('Round duration',
              '${_matchMinutes}m match + ${_breakMinutes}m break = ${roundMin}m'),
          _previewRow('Rounds', '$rounds'),
          _previewRow('Format', '$_playersPerTeam v $_playersPerTeam  ·  $playersPerCourt players per court'),
          _previewRow('Courts', '$_courtCount'),
          _previewRow('Total games', '${rounds * _courtCount}'),
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
                style:
                    const TextStyle(fontSize: 12, color: Colors.black54)),
            Text(value,
                style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
      );

  // ── Step 2: Players ──────────────────────────────────────────────────────────

  Widget _buildStep2() {
    final existingUsers = widget.appState.users
        .where((u) => !_players.any((p) => p.appUserId == u.id))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('Target Player Count'),
        const SizedBox(height: 8),
        _intPicker(
          value: _targetPlayerCount,
          min: 4,
          max: 32,
          onChanged: (v) => setState(() => _targetPlayerCount = v),
        ),
        const SizedBox(height: 20),
        _sectionLabel('Add Player by Name'),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _playerNameCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: _inputDecoration(hint: 'Player name'),
                onSubmitted: _addPlayerByName,
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () => _addPlayerByName(_playerNameCtrl.text),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.olive,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Add'),
            ),
          ],
        ),
        if (existingUsers.isNotEmpty) ...[
          const SizedBox(height: 16),
          _sectionLabel('Select Existing Players'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: existingUsers.map((u) => ActionChip(
              label: Text(u.name, style: const TextStyle(fontSize: 12)),
              onPressed: () => _addExistingPlayer(u.id, u.name),
              backgroundColor: AppColors.goldCream,
            )).toList(),
          ),
        ],
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _sectionLabel(
                'Players (${_players.length}/$_targetPlayerCount)'),
            TextButton.icon(
              onPressed:
                  _players.length < _targetPlayerCount ? _fillWithRandom : null,
              icon: const Icon(Icons.shuffle_rounded, size: 16),
              label: Text('Fill ${_targetPlayerCount - _players.length} random'),
              style: TextButton.styleFrom(
                  foregroundColor: AppColors.olive),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_players.isEmpty)
          const Text('No players added yet.',
              style: TextStyle(color: Colors.black38, fontSize: 13))
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _players.length,
            separatorBuilder: (context, i) => const SizedBox(height: 4),
            itemBuilder: (_, i) {
              final p = _players[i];
              return ListTile(
                dense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(color: Colors.grey.shade200)),
                leading: CircleAvatar(
                  radius: 14,
                  backgroundColor: _sourceColor(p.source),
                  child: Text(
                    p.name.isNotEmpty ? p.name[0].toUpperCase() : '?',
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
                  onPressed: () => _removePlayer(i),
                ),
              );
            },
          ),
      ],
    );
  }

  Color _sourceColor(ScramblePlayerSource s) => switch (s) {
        ScramblePlayerSource.existing => AppColors.olive,
        ScramblePlayerSource.created => AppColors.goldDark,
        ScramblePlayerSource.random => Colors.blueGrey,
      };

  String _sourceLabel(ScramblePlayerSource s) => switch (s) {
        ScramblePlayerSource.existing => 'Existing player',
        ScramblePlayerSource.created => 'New player',
        ScramblePlayerSource.random => 'Random placeholder',
      };

  // ── Step 3: Review & Suggestions ────────────────────────────────────────────

  Widget _buildStep3() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.oliveLight,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _nameCtrl.text.trim(),
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              _reviewRow(Icons.timer_rounded,
                  'Total time: $_totalMinutes min'),
              _reviewRow(Icons.sports_volleyball_rounded,
                  'Match: $_matchMinutes min  ·  Break: $_breakMinutes min'),
              _reviewRow(Icons.sports_volleyball_rounded,
                  'Format: $_playersPerTeam v $_playersPerTeam'),
              _reviewRow(Icons.grid_view_rounded,
                  '$_courtCount court${_courtCount > 1 ? 's' : ''}  ·  $_roundCount rounds'),
              _reviewRow(Icons.group_rounded,
                  '${_players.length} players  ·  ${_roundCount * _courtCount} total games'),
              _reviewRow(Icons.person_rounded, () {
                final active = _activeCourts * _playersPerTeam * 2;
                final out = _players.length - active;
                return '$active players active per round'
                    '${out > 0 ? '  ·  $out sit out' : ''}';
              }()),
            ],
          ),
        ),
        if (_suggestions.isNotEmpty) ...[
          const SizedBox(height: 20),
          const Text(
            'Suggestions',
            style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: Colors.black54),
          ),
          const SizedBox(height: 8),
          ..._suggestions.map((s) => ScrambleSuggestionCard(
                suggestion: s,
                onAction: s.actionLabel != null
                    ? () => _applySuggestion(s)
                    : null,
              )),
        ] else ...[
          const SizedBox(height: 16),
          const Row(
            children: [
              Icon(Icons.check_circle_rounded,
                  color: AppColors.olive, size: 16),
              SizedBox(width: 6),
              Text('Setup looks good!',
                  style: TextStyle(
                      color: AppColors.olive,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ],
    );
  }

  Widget _reviewRow(IconData icon, String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          children: [
            Icon(icon, size: 14, color: AppColors.olive),
            const SizedBox(width: 8),
            Expanded(
                child: Text(text,
                    style: const TextStyle(fontSize: 13))),
          ],
        ),
      );

  void _applySuggestion(ScrambleSuggestion s) {
    switch (s.type) {
      case ScrambleSuggestionType.increaseTotalTime:
        final extra = (_matchMinutes + _breakMinutes) * 3;
        setState(() {
          _totalMinutes += extra;
          _step = 0;
        });
      case ScrambleSuggestionType.reduceBreakDuration:
        setState(() {
          _breakMinutes = max(0, _breakMinutes - 2);
          _step = 0;
        });
      case ScrambleSuggestionType.adjustMatchDuration:
        setState(() => _step = 0);
      case ScrambleSuggestionType.adjustPlayerCount:
        setState(() => _step = 1);
      case ScrambleSuggestionType.adjustCourtCount:
        setState(() {
          _courtCount = _activeCourts;
          _step = 0;
        });
    }
    _computeSuggestions();
  }

  // ── Nav Buttons ──────────────────────────────────────────────────────────────

  Widget _buildNavButtons() {
    final canAdvance = _step == 0
        ? _step1Valid
        : _step == 1
            ? _step2Valid
            : true;

    return Row(
      children: [
        if (_step > 0)
          Expanded(
            child: OutlinedButton(
              onPressed: _goBack,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Back'),
            ),
          ),
        if (_step > 0) const SizedBox(width: 10),
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: canAdvance
                ? (_step < _totalSteps - 1 ? _goNext : _create)
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.olive,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              _step < _totalSteps - 1 ? 'Next' : 'Create Tournament',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }

  // ── Shared Widgets ───────────────────────────────────────────────────────────

  Widget _sectionLabel(String text) => Text(
        text,
        style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: Colors.black54),
      );

  InputDecoration _inputDecoration({String? hint}) => InputDecoration(
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      );

  Widget _minutePicker({
    required int value,
    required List<int> options,
    required void Function(int) onChanged,
  }) =>
      Wrap(
        spacing: 6,
        runSpacing: 4,
        children: options
            .map((o) => ChoiceChip(
                  label: Text('${o}m'),
                  selected: value == o,
                  selectedColor: AppColors.goldCream,
                  checkmarkColor: AppColors.goldDark,
                  onSelected: (_) => onChanged(o),
                ))
            .toList(),
      );

  Widget _intPicker({
    required int value,
    required int min,
    required int max,
    required void Function(int) onChanged,
  }) =>
      Row(
        children: [
          IconButton(
            onPressed: value > min ? () => onChanged(value - 1) : null,
            icon: const Icon(Icons.remove_rounded),
          ),
          SizedBox(
            width: 48,
            child: TextField(
              controller: TextEditingController(text: '$value'),
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(vertical: 8),
                isDense: true,
              ),
              onSubmitted: (s) {
                final v = int.tryParse(s);
                if (v != null) onChanged(v.clamp(min, max));
              },
            ),
          ),
          IconButton(
            onPressed: value < max ? () => onChanged(value + 1) : null,
            icon: const Icon(Icons.add_rounded),
          ),
        ],
      );
}
