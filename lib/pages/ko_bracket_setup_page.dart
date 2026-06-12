import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../app/app_colors.dart';
import '../models/ko_bracket_tournament.dart';
import '../models/player.dart';
import '../state/app_state.dart';
import '../widgets/scrollable_page.dart';
import '../widgets/sheet_helpers.dart';
import '../widgets/tournaq_app_bar.dart';
import 'ko_bracket_bracket_page.dart';

// ── Constants ─────────────────────────────────────────────────────────────────

const _kGold = AppColors.gold;
const _kGoldDark = AppColors.goldDark;
const _kGoldCream = AppColors.goldCream;
const _kOlive = AppColors.olive;

final _rng = Random();

const _nameTemplates = [
  ('Golden', 'Bracket'),
  ('Iron', 'Fist'),
  ('Thunder', 'Cup'),
  ('Steel', 'Cage'),
  ('Crown', 'Classic'),
  ('Champion', 'Cup'),
  ('Elite', 'Eight'),
  ('Final', 'Fury'),
  ('Blazing', 'Bracket'),
  ('Sunset', 'Showdown'),
  ('Neon', 'Knockout'),
  ('Wild', 'Card'),
  ('Friday', 'Fight'),
  ('Epic', 'Bracket'),
  ('Sneaky', 'Semifinal'),
];

// ── Page ──────────────────────────────────────────────────────────────────────

class KoBracketSetupPage extends StatefulWidget {
  final AppState appState;
  final void Function(KoBracketTournament) onCreated;

  const KoBracketSetupPage({
    super.key,
    required this.appState,
    required this.onCreated,
  });

  @override
  State<KoBracketSetupPage> createState() => _KoBracketSetupPageState();
}

class _KoBracketSetupPageState extends State<KoBracketSetupPage> {
  // ── Format ────────────────────────────────────────────────────────────────
  int _teamCount = 8;
  int _playersPerSide = 2;
  int _courtCount = 2;

  // ── Mode ──────────────────────────────────────────────────────────────────
  KoBracketGenerationMode _generationMode = KoBracketGenerationMode.random;
  KoOddTeamStrategy _oddStrategy = KoOddTeamStrategy.byes;

  // ── Game settings ─────────────────────────────────────────────────────────
  int _minutesPerGame = 30;
  KoRoundFormat _earlyFormat = const KoRoundFormat(setsPerGame: 1, pointsPerSet: 15);
  KoRoundFormat _finalFormat = const KoRoundFormat(setsPerGame: 3, pointsPerSet: 21);
  int _finalRoundsCount = 2;

  // ── Schedule ──────────────────────────────────────────────────────────────
  DateTime _estimatedStart = DateTime.now().add(const Duration(hours: 1));

  // ── Teams ─────────────────────────────────────────────────────────────────
  late List<KoTeam> _teams;

  // ── Name ──────────────────────────────────────────────────────────────────
  late final TextEditingController _nameCtrl;
  late final TextEditingController _minutesCtrl;
  late final TextEditingController _teamCountCtrl;
  late final TextEditingController _courtCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: _randomName());
    _minutesCtrl = TextEditingController(text: '$_minutesPerGame');
    _teamCountCtrl = TextEditingController(text: '$_teamCount');
    _courtCtrl = TextEditingController(text: '$_courtCount');
    _teams = _generateTeams(_teamCount);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _minutesCtrl.dispose();
    _teamCountCtrl.dispose();
    _courtCtrl.dispose();
    super.dispose();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String _randomName() {
    final t = _nameTemplates[_rng.nextInt(_nameTemplates.length)];
    return '${t.$1} ${t.$2}';
  }

  List<KoTeam> _generateTeams(int count) {
    return List.generate(count, (i) {
      final letter = String.fromCharCode(65 + i); // A, B, C...
      return KoTeam(
        id: KoTeam.generateId(),
        name: 'Team $letter',
        players: List.generate(
          _playersPerSide,
          (j) => KoPlayerSnapshot(
            appPlayerId: '',
            name: 'Player ${j + 1}',
          ),
        ),
      );
    });
  }

  void _onTeamCountChanged(int count) {
    setState(() {
      _teamCount = count;
      if (count > _teams.length) {
        for (var i = _teams.length; i < count; i++) {
          final letter = String.fromCharCode(65 + i);
          _teams.add(KoTeam(
            id: KoTeam.generateId(),
            name: 'Team $letter',
            players: List.generate(
              _playersPerSide,
              (j) => KoPlayerSnapshot(appPlayerId: '', name: 'Player ${j + 1}'),
            ),
          ));
        }
      } else if (count < _teams.length) {
        _teams = _teams.sublist(0, count);
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

  // ── Seeded mode validation ────────────────────────────────────────────────

  List<String> get _unratedPlayerNames {
    if (_generationMode != KoBracketGenerationMode.seeded) return [];
    final unrated = <String>[];
    for (final team in _teams) {
      for (final p in team.players) {
        if (p.appPlayerId.isNotEmpty && p.skillRating == null) {
          unrated.add('${p.name} (${team.name})');
        } else if (p.appPlayerId.isEmpty) {
          unrated.add('${p.name} (${team.name}) — not linked to a player');
        }
      }
    }
    return unrated;
  }

  bool get _canCreate {
    if (_nameCtrl.text.trim().isEmpty) return false;
    if (_teamCount < 2) return false;
    if (_generationMode == KoBracketGenerationMode.seeded &&
        _unratedPlayerNames.isNotEmpty) { return false; }
    return true;
  }

  // ── Estimated schedule ────────────────────────────────────────────────────

  KoBracketTournament get _previewTournament => KoBracketTournament(
        id: '',
        name: '',
        generationMode: _generationMode,
        oddTeamStrategy: _oddStrategy,
        playersPerSide: _playersPerSide,
        courtCount: _courtCount,
        minutesPerGame: _minutesPerGame,
        earlyRoundFormat: _earlyFormat,
        finalRoundFormat: _finalFormat,
        finalRoundsCount: _finalRoundsCount,
        estimatedStart: _estimatedStart,
        teams: _teams,
      );

  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes % 60;
    if (h == 0) return '${m}min';
    if (m == 0) return '${h}h';
    return '${h}h ${m}min';
  }

  // ── Create ────────────────────────────────────────────────────────────────

  void _create() {
    if (!_canCreate) return;
    final tournament = KoBracketTournament(
      id: KoBracketTournament.generateId(),
      name: _nameCtrl.text.trim(),
      generationMode: _generationMode,
      oddTeamStrategy: _oddStrategy,
      playersPerSide: _playersPerSide,
      courtCount: _courtCount,
      minutesPerGame: _minutesPerGame,
      earlyRoundFormat: _earlyFormat,
      finalRoundFormat: _finalFormat,
      finalRoundsCount: _finalRoundsCount,
      estimatedStart: _estimatedStart,
      teams: _teams,
      matches: KoBracketGenerator.generate(
        KoBracketTournament(
          id: '',
          name: '',
          generationMode: _generationMode,
          oddTeamStrategy: _oddStrategy,
          playersPerSide: _playersPerSide,
          courtCount: _courtCount,
          minutesPerGame: _minutesPerGame,
          earlyRoundFormat: _earlyFormat,
          finalRoundFormat: _finalFormat,
          finalRoundsCount: _finalRoundsCount,
          estimatedStart: _estimatedStart,
          teams: _teams,
        ),
      ),
      status: KoBracketStatus.inProgress,
    );
    widget.onCreated(tournament);
    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (_) => KoBracketBracketPage(
        tournament: tournament,
        appState: widget.appState,
        onChanged: widget.onCreated,
      ),
    ));
  }

  // ── Team editor sheet ─────────────────────────────────────────────────────

  void _editTeam(int index) {
    final team = _teams[index];
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _TeamEditorSheet(
        team: team,
        appState: widget.appState,
        generationMode: _generationMode,
        onSave: (updated) => setState(() => _teams[index] = updated),
      ),
    );
  }

  void _reorderTeams(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex--;
      final t = _teams.removeAt(oldIndex);
      _teams.insert(newIndex, t);
    });
  }

  void _shuffleTeams() => setState(() => _teams.shuffle(_rng));

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
      _estimatedStart = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final preview = _previewTournament;
    final end = preview.estimatedEnd;
    final unrated = _unratedPlayerNames;

    return Scaffold(
      appBar: const TournaQAppBar(title: 'KO Bracket', subtitle: 'New Tournament'),
      body: ScrollablePage(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Section 1: Format ─────────────────────────────────────────
            _sectionHeader('Format', Icons.tune_rounded),
            const SizedBox(height: 14),
            Row(children: [
              Expanded(
                child: _comboField(
                  label: 'Teams',
                  ctrl: _teamCountCtrl,
                  presets: [4, 6, 8, 10, 12, 16],
                  onParsed: (v) => _onTeamCountChanged(v.clamp(2, 64)),
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

            // ── Section 2: Bracket Mode ───────────────────────────────────
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            _sectionHeader('Bracket Mode', Icons.account_tree_rounded),
            const SizedBox(height: 14),
            _fieldLabel('Generation'),
            const SizedBox(height: 8),
            _segmentedRow(
              options: const ['Random', 'Seeded'],
              selected: _generationMode == KoBracketGenerationMode.random ? 0 : 1,
              onSelected: (i) => setState(() => _generationMode =
                  i == 0 ? KoBracketGenerationMode.random : KoBracketGenerationMode.seeded),
            ),
            const SizedBox(height: 14),
            Row(children: [
              Expanded(child: _fieldLabel('Odd Teams')),
              GestureDetector(
                onTap: _showOddTeamsHelp,
                child: const Icon(Icons.help_outline_rounded, size: 18, color: _kOlive),
              ),
            ]),
            const SizedBox(height: 8),
            _oddStrategyControl(),

            // ── Section 3: Game Settings ──────────────────────────────────
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            _sectionHeader('Game Settings', Icons.sports_volleyball_rounded),
            const SizedBox(height: 14),
            _comboField(
              label: 'Time per Game',
              ctrl: _minutesCtrl,
              presets: [15, 20, 30, 45, 60, 90],
              onParsed: (v) => setState(() => _minutesPerGame = v.clamp(5, 999)),
              unit: 'min',
            ),
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

            // ── Section 4: Schedule ───────────────────────────────────────
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            _sectionHeader('Schedule', Icons.schedule_rounded),
            const SizedBox(height: 14),
            Row(children: [
              Expanded(
                child: _infoChip(
                  icon: Icons.play_circle_outline_rounded,
                  label: 'Start',
                  value: _formatDateTime(_estimatedStart),
                  onTap: _pickStartTime,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _infoChip(
                  icon: Icons.stop_circle_outlined,
                  label: 'Est. End',
                  value: end != null ? _formatDateTime(end) : '—',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _infoChip(
                  icon: Icons.timer_outlined,
                  label: 'Duration',
                  value: _formatDuration(preview.estimatedDuration),
                ),
              ),
            ]),

            // ── Section 5: Teams ──────────────────────────────────────────
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: _sectionHeader('Teams', Icons.groups_rounded)),
              TextButton.icon(
                onPressed: _shuffleTeams,
                icon: const Icon(Icons.shuffle_rounded, size: 16),
                label: const Text('Shuffle'),
                style: TextButton.styleFrom(foregroundColor: _kOlive),
              ),
            ]),
            const SizedBox(height: 8),
            _buildTeamList(),

            // ── Seeded warning ────────────────────────────────────────────
            if (_generationMode == KoBracketGenerationMode.seeded &&
                unrated.isNotEmpty) ...[
              const SizedBox(height: 16),
              _unratedWarning(unrated),
            ],

            // ── Name ──────────────────────────────────────────────────────
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            _fieldLabel('Tournament Name'),
            const SizedBox(height: 8),
            Row(children: [
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
            ]),

            // ── Create ────────────────────────────────────────────────────
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(children: [
                Icon(
                  _canCreate ? Icons.check_circle_rounded : Icons.error_outline_rounded,
                  color: _canCreate ? _kOlive : Colors.red.shade600,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  _canCreate ? 'Ready to start!' : 'Setup incomplete',
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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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

  // ── Team list ─────────────────────────────────────────────────────────────

  Widget _buildTeamList() {
    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _teams.length,
      onReorder: _reorderTeams,
      itemBuilder: (ctx, i) {
        final team = _teams[i];
        final rating = team.skillRating;
        final allLinked = team.players.every((p) => p.appPlayerId.isNotEmpty);
        final hasUnrated = _generationMode == KoBracketGenerationMode.seeded &&
            team.players.any((p) => p.skillRating == null);

        return Container(
          key: ValueKey(team.id),
          margin: const EdgeInsets.only(bottom: 6),
          decoration: BoxDecoration(
            border: Border.all(
              color: hasUnrated ? Colors.red.shade300 : Colors.grey.shade200,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: ListTile(
            dense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
            leading: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: _kGoldCream,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Center(
                child: Text(
                  '${i + 1}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    color: _kGoldDark,
                  ),
                ),
              ),
            ),
            title: Text(
              team.name,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            subtitle: Text(
              team.players.map((p) => p.name).join(' · '),
              style: const TextStyle(fontSize: 11, color: Colors.black45),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (rating != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: _kGoldCream,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.goldBadgeBorder),
                    ),
                    child: Text(
                      '★ $rating',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: _kGoldDark,
                      ),
                    ),
                  )
                else if (_generationMode == KoBracketGenerationMode.seeded)
                  const Icon(Icons.warning_amber_rounded, size: 16, color: Colors.orange),
                const SizedBox(width: 4),
                if (!allLinked && _generationMode == KoBracketGenerationMode.seeded)
                  const Icon(Icons.link_off_rounded, size: 14, color: Colors.red),
                IconButton(
                  icon: const Icon(Icons.edit_rounded, size: 16, color: Colors.black38),
                  onPressed: () => _editTeam(i),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.drag_handle_rounded, color: Colors.black26, size: 18),
              ],
            ),
            onTap: () => _editTeam(i),
          ),
        );
      },
    );
  }

  // ── Unrated warning ───────────────────────────────────────────────────────

  Widget _unratedWarning(List<String> unrated) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        border: Border.all(color: Colors.red.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.warning_amber_rounded, size: 16, color: Colors.red.shade600),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Seeded mode requires all players to have a Skill Level set.',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: Colors.red.shade700,
                ),
              ),
            ),
          ]),
          const SizedBox(height: 8),
          ...unrated.map((name) => Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  '• $name',
                  style: TextStyle(fontSize: 12, color: Colors.red.shade700),
                ),
              )),
          const SizedBox(height: 8),
          Text(
            'Go to Players → select a player → set their Skill Level (1–10).\nOr switch to Random mode to start without ratings.',
            style: TextStyle(fontSize: 12, color: Colors.red.shade600),
          ),
        ],
      ),
    );
  }

  // ── Odd teams help sheet ──────────────────────────────────────────────────

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
              const Text(
                'Odd Teams — How it works',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 20),
              _helpItem(
                icon: Icons.skip_next_rounded,
                color: _kGold,
                title: 'Byes',
                body: 'Top seeds skip round 1 and wait. Weaker seeds play first. '
                    'Fastest setup — ideal when you want to reward higher seedings '
                    'without extra matches.',
                example: 'Example (5 teams): Seeds 1–3 wait. Seeds 4 and 5 play. '
                    'Winner joins the main bracket.',
              ),
              const SizedBox(height: 16),
              _helpItem(
                icon: Icons.play_arrow_rounded,
                color: _kOlive,
                title: 'Play-in',
                body: 'Bottom seeds play a preliminary round to earn their bracket spot. '
                    'Nobody gets a free pass — every team has to win to advance.',
                example: 'Example (5 teams): Seeds 4 and 5 play a play-in. '
                    'Winner takes the last slot in the main bracket.',
              ),
              const SizedBox(height: 16),
              _helpItem(
                icon: Icons.refresh_rounded,
                color: Colors.deepOrange,
                title: 'Play-in + Repechage',
                body: 'Same as play-in, but the highest-scoring loser gets one '
                    'wildcard match for a second chance at the bracket.',
                example: 'Example (5 teams): Seeds 3–5 play two matches. '
                    'Both winners advance. Best-scoring loser plays a repechage '
                    'match — winner takes the final bracket spot.',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _helpItem({
    required IconData icon,
    required Color color,
    required String title,
    required String body,
    required String example,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: color)),
              const SizedBox(height: 4),
              Text(body, style: const TextStyle(fontSize: 13, color: Colors.black87)),
              const SizedBox(height: 4),
              Text(example,
                  style: const TextStyle(
                      fontSize: 12, color: Colors.black45, fontStyle: FontStyle.italic)),
            ],
          ),
        ),
      ],
    );
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _fieldLabel('Sets per game'),
                  const SizedBox(height: 6),
                  _chipRow(
                    options: [1, 3, 5],
                    selected: format.setsPerGame,
                    onSelected: (v) => onChanged(format.copyWith(setsPerGame: v)),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _fieldLabel('Points per set'),
                  const SizedBox(height: 6),
                  _chipRow(
                    options: [11, 15, 21],
                    selected: format.pointsPerSet,
                    onSelected: (v) => onChanged(format.copyWith(pointsPerSet: v)),
                  ),
                ],
              ),
            ),
          ]),
          if (showFinalRoundsCount) ...[
            const SizedBox(height: 10),
            Row(children: [
              _fieldLabel('Applies to last'),
              const SizedBox(width: 10),
              _stepper(
                value: _finalRoundsCount,
                min: 1,
                max: 4,
                onChanged: (v) => setState(() => _finalRoundsCount = v),
              ),
              const SizedBox(width: 6),
              const Text('round(s)', style: TextStyle(fontSize: 12, color: Colors.black54)),
            ]),
          ],
        ],
      ),
    );
  }

  // ── Segmented row ─────────────────────────────────────────────────────────

  Widget _segmentedRow({
    required List<String> options,
    required int selected,
    required void Function(int) onSelected,
  }) {
    return Row(
      children: options.asMap().entries.map((e) {
        final isSelected = e.key == selected;
        return Expanded(
          child: GestureDetector(
            onTap: () => onSelected(e.key),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: EdgeInsets.only(right: e.key < options.length - 1 ? 8 : 0),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? _kGold : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected ? _kGoldDark : Colors.grey.shade300,
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: Center(
                child: Text(
                  e.value,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: isSelected ? Colors.white : Colors.black54,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── Odd strategy control (3-way) ──────────────────────────────────────────

  Widget _oddStrategyControl() {
    const options = ['Byes', 'Play-in', 'Play-in + Repechage'];
    final selected = _oddStrategy.index;
    return _segmentedRow(
      options: options,
      selected: selected,
      onSelected: (i) => setState(() => _oddStrategy = KoOddTeamStrategy.values[i]),
    );
  }

  // ── Chip row ──────────────────────────────────────────────────────────────

  Widget _chipRow({
    required List<int> options,
    required int selected,
    required void Function(int) onSelected,
  }) {
    return Wrap(
      spacing: 6,
      children: options.map((v) {
        final isSelected = v == selected;
        return GestureDetector(
          onTap: () => onSelected(v),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: isSelected ? _kGoldCream : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected ? _kGoldDark : Colors.grey.shade300,
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Text(
              '$v',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 12,
                color: isSelected ? _kGoldDark : Colors.black54,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── Style field (Single Elim only for now) ────────────────────────────────

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
          child: const Row(children: [
            Expanded(
              child: Text(
                'Single Elimination',
                style: TextStyle(fontSize: 14, color: Colors.black87),
              ),
            ),
            Icon(Icons.account_tree_rounded, size: 16, color: Colors.black38),
          ]),
        ),
      ],
    );
  }

  // ── Players-per-side field ────────────────────────────────────────────────

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
          items: [1, 2, 3, 4]
              .map((n) => DropdownMenuItem(value: n, child: Text('${n}vs$n')))
              .toList(),
          onChanged: (v) {
            if (v != null) _onPlayersPerSideChanged(v);
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
      ],
    );
  }

  // ── Schedule info chip ────────────────────────────────────────────────────

  Widget _infoChip({
    required IconData icon,
    required String label,
    required String value,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: _kGoldCream,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.goldBadgeBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(icon, size: 13, color: _kGoldDark),
              const SizedBox(width: 4),
              Text(label,
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: _kGoldDark)),
              if (onTap != null) ...[
                const Spacer(),
                const Icon(Icons.edit_rounded, size: 10, color: _kGoldDark),
              ],
            ]),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.black87),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // ── Stepper ───────────────────────────────────────────────────────────────

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
            size: 22, color: value > min ? _kOlive : Colors.grey.shade300),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Text('$value',
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
      ),
      GestureDetector(
        onTap: value < max ? () => onChanged(value + 1) : null,
        child: Icon(Icons.add_circle_outline_rounded,
            size: 22, color: value < max ? _kOlive : Colors.grey.shade300),
      ),
    ]);
  }

  // ── Shared helpers ────────────────────────────────────────────────────────

  Widget _sectionHeader(String title, IconData icon) => Row(children: [
        Icon(icon, size: 15, color: _kOlive),
        const SizedBox(width: 6),
        Text(
          title.toUpperCase(),
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: _kOlive,
            letterSpacing: 0.4,
          ),
        ),
      ]);

  Widget _fieldLabel(String text) => Text(
        text,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black54),
      );

  InputDecoration _inputDecoration({String? hint}) => InputDecoration(
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      );

  String _formatDateTime(DateTime dt) {
    final weekday = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][dt.weekday - 1];
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$weekday ${dt.day}/${dt.month} $h:$m';
  }
}

// ── Team editor sheet ─────────────────────────────────────────────────────────

class _TeamEditorSheet extends StatefulWidget {
  final KoTeam team;
  final AppState appState;
  final KoBracketGenerationMode generationMode;
  final void Function(KoTeam) onSave;

  const _TeamEditorSheet({
    required this.team,
    required this.appState,
    required this.generationMode,
    required this.onSave,
  });

  @override
  State<_TeamEditorSheet> createState() => _TeamEditorSheetState();
}

class _TeamEditorSheetState extends State<_TeamEditorSheet> {
  late final TextEditingController _nameCtrl;
  late List<KoPlayerSnapshot> _players;
  final _searchCtrl = TextEditingController();
  bool _searchActive = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.team.name);
    _players = List.from(widget.team.players);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _pickPlayer(int slotIndex, Player appPlayer) {
    setState(() {
      _players[slotIndex] = KoPlayerSnapshot(
        appPlayerId: appPlayer.id,
        name: appPlayer.name,
        skillRating: appPlayer.skillRating,
      );
      _searchActive = false;
      _searchCtrl.clear();
    });
  }

  void _clearSlot(int slotIndex) {
    setState(() {
      _players[slotIndex] = KoPlayerSnapshot(
        appPlayerId: '',
        name: 'Player ${slotIndex + 1}',
      );
    });
  }

  void _save() {
    widget.onSave(widget.team.copyWith(
      name: _nameCtrl.text.trim().isEmpty ? widget.team.name : _nameCtrl.text.trim(),
      players: _players,
    ));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchCtrl.text.toLowerCase();
    final allPlayers = widget.appState.players;
    final filtered = query.isEmpty
        ? allPlayers
        : allPlayers.where((p) => p.name.toLowerCase().contains(query)).toList();

    return TournaQSheet(
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(children: [
              const Expanded(
                child: Text('Edit Team',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              ),
              TextButton(
                onPressed: _save,
                style: TextButton.styleFrom(foregroundColor: AppColors.gold),
                child: const Text('Save', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ]),
            const SizedBox(height: 16),

            // Team name
            const Text('Team Name',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black54)),
            const SizedBox(height: 6),
            TextField(
              controller: _nameCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
            const SizedBox(height: 20),

            // Player slots
            const Text('Players',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black54)),
            const SizedBox(height: 8),
            ..._players.asMap().entries.map((e) {
              final i = e.key;
              final p = e.value;
              final isLinked = p.appPlayerId.isNotEmpty;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: widget.generationMode == KoBracketGenerationMode.seeded &&
                            (!isLinked || p.skillRating == null)
                        ? Colors.red.shade300
                        : Colors.grey.shade200,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: isLinked ? AppColors.olive : Colors.grey.shade300,
                    child: Text(
                      p.name.isNotEmpty ? p.name[0].toUpperCase() : '?',
                      style: const TextStyle(
                          fontSize: 11, color: Colors.white, fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p.name,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        if (isLinked && p.skillRating != null)
                          Text('Skill: ${p.skillRating}',
                              style: const TextStyle(fontSize: 11, color: Colors.black45))
                        else if (isLinked && p.skillRating == null)
                          Text('Unrated',
                              style: TextStyle(fontSize: 11, color: Colors.orange.shade700))
                        else
                          Text('Not linked',
                              style: const TextStyle(fontSize: 11, color: Colors.black38)),
                      ],
                    ),
                  ),
                  if (isLinked)
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 16, color: Colors.black38),
                      onPressed: () => _clearSlot(i),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                ]),
              );
            }),

            // Player search
            const SizedBox(height: 8),
            if (allPlayers.isNotEmpty) ...[
              TextField(
                controller: _searchCtrl,
                decoration: InputDecoration(
                  hintText: 'Search app players…',
                  isDense: true,
                  prefixIcon:
                      const Icon(Icons.search_rounded, size: 18, color: Colors.black45),
                  border:
                      OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                onTap: () => setState(() => _searchActive = true),
                onChanged: (_) => setState(() => _searchActive = true),
              ),
              if (_searchActive && filtered.isNotEmpty) ...[
                const SizedBox(height: 6),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filtered.length.clamp(0, 8),
                  separatorBuilder: (context, i) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final player = filtered[i];
                    final alreadyInSlot =
                        _players.any((p) => p.appPlayerId == player.id);
                    // Find first free slot
                    final freeSlot =
                        _players.indexWhere((p) => p.appPlayerId.isEmpty);
                    return ListTile(
                      dense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                      title: Text(player.name,
                          style: const TextStyle(fontSize: 13)),
                      subtitle: player.skillRating != null
                          ? Text('Skill: ${player.skillRating}',
                              style: const TextStyle(fontSize: 11))
                          : const Text('Unrated',
                              style: TextStyle(
                                  fontSize: 11, color: Colors.orange)),
                      trailing: alreadyInSlot || freeSlot < 0
                          ? const Icon(Icons.check_rounded,
                              size: 18, color: AppColors.olive)
                          : IconButton(
                              icon: const Icon(
                                  Icons.add_circle_outline_rounded,
                                  size: 20,
                                  color: AppColors.gold),
                              onPressed: () => _pickPlayer(freeSlot, player),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                    );
                  },
                ),
              ],
            ] else
              const Text(
                'No players in the app yet. Add players via the Players section first.',
                style: TextStyle(fontSize: 12, color: Colors.black45),
              ),
          ],
        ),
      ),
    );
  }
}
