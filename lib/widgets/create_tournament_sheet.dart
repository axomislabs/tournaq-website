import 'dart:math';
import 'package:flutter/material.dart';

import '../models/club.dart';
import '../models/team.dart';
import '../models/tournament_mode.dart';
import '../services/app_data_service.dart';
import '../state/app_state.dart';
import 'hybrid_mode_setup_page.dart';

class CreateTournamentSheet extends StatefulWidget {
  final AppState appState;
  const CreateTournamentSheet({super.key, required this.appState});
  @override
  State<CreateTournamentSheet> createState() => _CreateTournamentSheetState();
}

class _CreateTournamentSheetState extends State<CreateTournamentSheet> {
  final _nameCtrl = TextEditingController();
  final _teamSearchCtrl = TextEditingController();
  final _newClubCtrl = TextEditingController();

  TournamentModeType _mode = TournamentModeType.league;
  List<List<TournamentModeType>> _hybridGroups = [];

  // Team selection
  final Set<String> _selectedTeamIds = {};
  String? _clubFilterId;

  // Random teams
  int _randomTeamCount = 0;
  String _randomClubMode = 'none'; // 'none' | 'existing' | 'new'
  String? _randomExistingClubId;

  // Tournament club assignment
  final Set<String> _tournamentClubIds = {};

  final _rng = Random();

  static const _namePrefixes = ['Summer', 'Winter', 'Spring', 'Autumn', 'Regional', 'National', 'City', 'Open', 'Grand', 'Elite'];
  static const _nameSuffixes = ['League', 'Cup', 'Championship', 'Series', 'Classic', 'Invitational', 'Open', 'Masters'];
  static const _teamPrefixes = ['Falcon', 'Phoenix', 'Lion', 'Tiger', 'Eagle', 'Storm', 'Dragon', 'Viper', 'Thunder', 'Raven'];
  static const _teamSuffixes = ['Squad', 'Team', 'Crew', 'Force', 'Unit', 'Pack', 'Alliance', 'Legion', 'Clan', 'Dynasty'];
  static const _clubSuggestions = ['Champions Club', 'Elite Sports', 'City Athletics', 'Metro United', 'Regional FC', 'Grand Sports', 'Premier Club', 'Summit Athletics'];

  // Threshold for switching between drag-and-drop and searchable list
  static const _dragDropThreshold = 10;

  @override
  void initState() {
    super.initState();
    _nameCtrl.text = _randomName();
    _teamSearchCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _teamSearchCtrl.dispose();
    _newClubCtrl.dispose();
    super.dispose();
  }

  String _randomName() =>
      '${_namePrefixes[_rng.nextInt(_namePrefixes.length)]} ${_nameSuffixes[_rng.nextInt(_nameSuffixes.length)]} ${DateTime.now().year}';

  void _suggestName() => setState(() => _nameCtrl.text = _randomName());

  bool get _canCreate => _nameCtrl.text.trim().isNotEmpty;

  List<Team> get _filteredTeams {
    if (_clubFilterId == null) return widget.appState.teams;
    final club = widget.appState.getClubById(_clubFilterId!);
    if (club == null) return widget.appState.teams;
    return widget.appState.teams.where((t) => club.teamIds.contains(t.id)).toList();
  }

  List<Team> get _searchedTeams {
    final q = _teamSearchCtrl.text.toLowerCase();
    if (q.isEmpty) return _filteredTeams;
    return _filteredTeams.where((t) => t.name.toLowerCase().contains(q)).toList();
  }

  bool get _useDragDrop => _filteredTeams.length <= _dragDropThreshold;

  Future<void> _openHybridSetup() async {
    final result = await Navigator.of(context).push<List<List<TournamentModeType>>>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => HybridModeSetupPage(
          modeTypes: TournamentModeType.values.where((m) => m != TournamentModeType.hybrid).toList(),
          initialGroups: _hybridGroups,
        ),
      ),
    );
    if (result != null && mounted) {
      setState(() => _hybridGroups = result);
    }
  }

  void _create() {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;

    var state = AppDataService.createTournament(
      widget.appState,
      name: name,
      mode: TournamentMode.fromType(_mode),
    );
    final tournamentId = state.tournaments.last.id;

    // Apply hybrid groups
    if (_mode == TournamentModeType.hybrid && _hybridGroups.isNotEmpty) {
      final t = state.getTournamentById(tournamentId)!;
      state = state.updateTournament(t.copyWith(hybridGroups: _hybridGroups));
    }

    // Generate random teams
    if (_randomTeamCount > 0) {
      String? randomClubId;

      if (_randomClubMode == 'existing' && _randomExistingClubId != null) {
        randomClubId = _randomExistingClubId;
      } else if (_randomClubMode == 'new') {
        final clubName = _newClubCtrl.text.trim().isNotEmpty
            ? _newClubCtrl.text.trim()
            : _clubSuggestions[_rng.nextInt(_clubSuggestions.length)];
        state = AppDataService.createClub(state, name: clubName);
        randomClubId = state.clubs.last.id;
        state = AppDataService.assignTournamentToClub(state, tournamentId: tournamentId, clubId: randomClubId);
      }

      for (var i = 0; i < _randomTeamCount; i++) {
        final teamName = '${_teamPrefixes[_rng.nextInt(_teamPrefixes.length)]} ${_teamSuffixes[_rng.nextInt(_teamSuffixes.length)]}';
        state = AppDataService.createTeam(state, name: teamName, scope: TeamScope.tournament);
        final teamId = state.teams.last.id;
        state = AppDataService.assignTeamToTournament(state, teamId: teamId, tournamentId: tournamentId);
        if (randomClubId != null) {
          state = AppDataService.assignTeamToClub(state, teamId: teamId, clubId: randomClubId);
        }
      }
    }

    // Assign existing selected teams
    for (final id in _selectedTeamIds) {
      state = AppDataService.assignTeamToTournament(state, teamId: id, tournamentId: tournamentId);
    }

    // Assign tournament to clubs
    for (final id in _tournamentClubIds) {
      state = AppDataService.assignTournamentToClub(state, tournamentId: tournamentId, clubId: id);
    }

    Navigator.pop(context, state);
  }

  @override
  Widget build(BuildContext context) {
    final clubs = widget.appState.clubs;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          // Drag handle
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 4),
            child: Center(child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
            )),
          ),
          Flexible(child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              // Header
              Row(children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(color: Color(0xFFFFF3CC), shape: BoxShape.circle),
                  child: const Icon(Icons.emoji_events_rounded, color: Color(0xFFD9A520), size: 22),
                ),
                const SizedBox(width: 12),
                const Text('Create Tournament', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
              ]),
              const SizedBox(height: 24),

              // ── Name ────────────────────────────────────────────────────
              Row(children: [
                const Expanded(child: Text('Name', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.black54))),
                GestureDetector(
                  onTap: _suggestName,
                  child: const Row(children: [
                    Icon(Icons.shuffle_rounded, size: 14, color: Color(0xFFD9A520)),
                    SizedBox(width: 4),
                    Text('Suggest', style: TextStyle(fontSize: 12, color: Color(0xFFD9A520), fontWeight: FontWeight.w600)),
                  ]),
                ),
              ]),
              const SizedBox(height: 8),
              TextField(
                controller: _nameCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 16),

              // ── Mode ────────────────────────────────────────────────────
              const Text('Mode', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.black54)),
              const SizedBox(height: 8),
              DropdownButtonFormField<TournamentModeType>(
                initialValue: _mode,
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                items: TournamentModeType.values.map((m) => DropdownMenuItem(
                  value: m, child: Text(TournamentMode.fromType(m).displayName),
                )).toList(),
                onChanged: (v) { if (v != null) setState(() => _mode = v); },
              ),

              // Hybrid setup button
              if (_mode == TournamentModeType.hybrid) ...[
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: _openHybridSetup,
                  icon: const Icon(Icons.tune_rounded, size: 18),
                  label: Text(
                    _hybridGroups.isEmpty
                        ? 'Configure Hybrid Groups'
                        : '${_hybridGroups.length} group${_hybridGroups.length == 1 ? '' : 's'} configured — tap to edit',
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFD9A520),
                    side: const BorderSide(color: Color(0xFFD9A520)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],

              const SizedBox(height: 24),
              const Divider(height: 1),
              const SizedBox(height: 20),

              // ── Existing Teams ───────────────────────────────────────────
              const Text('Assign Existing Teams', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.black54)),
              const SizedBox(height: 10),

              if (widget.appState.teams.isEmpty)
                const Text('No teams available yet.', style: TextStyle(color: Colors.black45, fontSize: 13))
              else ...[
                // Club filter
                if (clubs.isNotEmpty) ...[
                  _buildClubFilter(clubs),
                  const SizedBox(height: 10),
                ],
                _useDragDrop ? _buildDragDropSection() : _buildSearchableSection(),
              ],

              const SizedBox(height: 24),
              const Divider(height: 1),
              const SizedBox(height: 20),

              // ── Random Teams ─────────────────────────────────────────────
              const Text('Generate Random Teams', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.black54)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8, runSpacing: 4,
                children: [0, 4, 6, 8, 10, 12, 16].map((n) => ChoiceChip(
                  label: Text(n == 0 ? 'None' : '$n'),
                  selected: _randomTeamCount == n,
                  selectedColor: const Color(0xFFFFF3CC),
                  checkmarkColor: const Color(0xFFD9A520),
                  onSelected: (_) => setState(() => _randomTeamCount = n),
                )).toList(),
              ),

              if (_randomTeamCount > 0) ...[
                const SizedBox(height: 14),
                const Text('Club for random teams', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.black54)),
                const SizedBox(height: 4),
                _buildRandomClubSection(clubs),
              ],

              // ── Tournament Club Assignment ────────────────────────────────
              if (clubs.isNotEmpty) ...[
                const SizedBox(height: 24),
                const Divider(height: 1),
                const SizedBox(height: 20),
                const Text('Assign to Clubs', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.black54)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8, runSpacing: 4,
                  children: clubs.map((c) => FilterChip(
                    label: Text(c.name),
                    selected: _tournamentClubIds.contains(c.id),
                    selectedColor: const Color(0xFFFFF3CC),
                    checkmarkColor: const Color(0xFFD9A520),
                    onSelected: (v) => setState(() {
                      if (v) { _tournamentClubIds.add(c.id); } else { _tournamentClubIds.remove(c.id); }
                    }),
                  )).toList(),
                ),
              ],

              const SizedBox(height: 28),

              // Create button
              SizedBox(width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _canCreate ? _create : null,
                  icon: const Icon(Icons.check_rounded),
                  label: const Text('Create Tournament', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD9A520),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey[200],
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ]),
          )),
        ]),
      ),
    );
  }

  Widget _buildClubFilter(List<Club> clubs) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(children: [
        FilterChip(
          label: const Text('All clubs'),
          selected: _clubFilterId == null,
          selectedColor: const Color(0xFFFFF3CC),
          checkmarkColor: const Color(0xFFD9A520),
          onSelected: (_) => setState(() => _clubFilterId = null),
        ),
        ...clubs.map((c) => Padding(
          padding: const EdgeInsets.only(left: 8),
          child: FilterChip(
            label: Text(c.name),
            selected: _clubFilterId == c.id,
            selectedColor: const Color(0xFFFFF3CC),
            checkmarkColor: const Color(0xFFD9A520),
            onSelected: (_) => setState(() => _clubFilterId = _clubFilterId == c.id ? null : c.id),
          ),
        )),
      ]),
    );
  }

  Widget _buildDragDropSection() {
    final available = _filteredTeams.where((t) => !_selectedTeamIds.contains(t.id)).toList();
    final allSelected = widget.appState.teams.where((t) => _selectedTeamIds.contains(t.id)).toList();

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      // Available chips (draggable + tappable)
      if (available.isEmpty && allSelected.isEmpty)
        const Text('No teams in this club.', style: TextStyle(color: Colors.black45, fontSize: 13))
      else if (available.isNotEmpty) ...[
        const Text('Available', style: TextStyle(fontSize: 12, color: Colors.black45, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8, runSpacing: 6,
          children: available.map((t) => LongPressDraggable<String>(
            data: t.id,
            delay: const Duration(milliseconds: 200),
            feedback: Material(
              color: Colors.transparent,
              child: Chip(
                label: Text(t.name),
                backgroundColor: const Color(0xFFD9A520),
                labelStyle: const TextStyle(color: Colors.white, fontSize: 13),
              ),
            ),
            childWhenDragging: Opacity(
              opacity: 0.3,
              child: Chip(label: Text(t.name)),
            ),
            child: ActionChip(
              label: Text(t.name),
              avatar: const Icon(Icons.add_rounded, size: 14),
              onPressed: () => setState(() => _selectedTeamIds.add(t.id)),
            ),
          )).toList(),
        ),
        const SizedBox(height: 10),
      ],

      // Drop zone showing all selected teams
      DragTarget<String>(
        onWillAcceptWithDetails: (d) => !_selectedTeamIds.contains(d.data),
        onAcceptWithDetails: (d) => setState(() => _selectedTeamIds.add(d.data)),
        builder: (context, candidateData, _) {
          final isHovering = candidateData.isNotEmpty;
          final showEmpty = allSelected.isEmpty && !isHovering;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.all(12),
            constraints: const BoxConstraints(minHeight: 56),
            decoration: BoxDecoration(
              color: isHovering ? const Color(0xFFFFF3CC) : Colors.grey[50],
              border: Border.all(
                color: isHovering ? const Color(0xFFD9A520) : Colors.grey[300]!,
                width: isHovering ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: showEmpty
                ? Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.drag_indicator_rounded, size: 16, color: Colors.grey[400]),
                    const SizedBox(width: 6),
                    Text(
                      'Tap or drag teams here',
                      style: TextStyle(color: Colors.grey[400], fontSize: 13),
                    ),
                  ])
                : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(
                      'Selected (${allSelected.length})',
                      style: const TextStyle(fontSize: 12, color: Colors.black45, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8, runSpacing: 6,
                      children: [
                        ...allSelected.map((t) => Chip(
                          label: Text(t.name),
                          backgroundColor: const Color(0xFFFFF3CC),
                          deleteIconColor: const Color(0xFFD9A520),
                          labelStyle: const TextStyle(fontSize: 13),
                          onDeleted: () => setState(() => _selectedTeamIds.remove(t.id)),
                        )),
                        if (isHovering)
                          Opacity(
                            opacity: 0.5,
                            child: Chip(
                              label: Text(
                                widget.appState.getTeamById(candidateData.first!)?.name ?? '',
                              ),
                              backgroundColor: const Color(0xFFFFF3CC),
                              labelStyle: const TextStyle(fontSize: 13),
                            ),
                          ),
                      ],
                    ),
                  ]),
          );
        },
      ),
    ]);
  }

  Widget _buildSearchableSection() {
    final searched = _searchedTeams;
    final allSelected = widget.appState.teams.where((t) => _selectedTeamIds.contains(t.id)).toList();

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      // Selected chips
      if (allSelected.isNotEmpty) ...[
        Text('Selected (${allSelected.length})', style: const TextStyle(fontSize: 12, color: Colors.black45, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8, runSpacing: 6,
          children: allSelected.map((t) => Chip(
            label: Text(t.name),
            backgroundColor: const Color(0xFFFFF3CC),
            deleteIconColor: const Color(0xFFD9A520),
            labelStyle: const TextStyle(fontSize: 13),
            onDeleted: () => setState(() => _selectedTeamIds.remove(t.id)),
          )).toList(),
        ),
        const SizedBox(height: 10),
      ],

      // Search field
      TextField(
        controller: _teamSearchCtrl,
        decoration: InputDecoration(
          hintText: 'Search teams...',
          prefixIcon: const Icon(Icons.search_rounded, size: 20),
          isDense: true,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
      ),
      const SizedBox(height: 8),

      if (searched.isEmpty)
        const Padding(
          padding: EdgeInsets.all(8),
          child: Text('No teams found.', style: TextStyle(color: Colors.black45, fontSize: 13)),
        )
      else
        ...searched.map((t) => CheckboxListTile(
          dense: true,
          title: Text(t.name, style: const TextStyle(fontSize: 14)),
          subtitle: Text(t.scope.name, style: const TextStyle(fontSize: 12)),
          value: _selectedTeamIds.contains(t.id),
          activeColor: const Color(0xFFD9A520),
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
          onChanged: (v) => setState(() {
            if (v == true) { _selectedTeamIds.add(t.id); } else { _selectedTeamIds.remove(t.id); }
          }),
        )),
    ]);
  }

  Widget _buildRandomClubSection(List<Club> clubs) {
    return RadioGroup<String>(
      groupValue: _randomClubMode,
      onChanged: (v) { if (v != null) setState(() => _randomClubMode = v); },
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      RadioListTile<String>(
        dense: true,
        contentPadding: EdgeInsets.zero,
        title: const Text('No club', style: TextStyle(fontSize: 14)),
        value: 'none',
        activeColor: const Color(0xFFD9A520),
      ),
      if (clubs.isNotEmpty)
        RadioListTile<String>(
          dense: true,
          contentPadding: EdgeInsets.zero,
          title: const Text('Add to existing club', style: TextStyle(fontSize: 14)),
          value: 'existing',
          activeColor: const Color(0xFFD9A520),
        ),
      if (_randomClubMode == 'existing' && clubs.isNotEmpty)
        Padding(
          padding: const EdgeInsets.only(left: 32, bottom: 8),
          child: DropdownButtonFormField<String>(
            initialValue: _randomExistingClubId,
            hint: const Text('Select a club', style: TextStyle(fontSize: 13)),
            decoration: InputDecoration(
              isDense: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            items: clubs.map((c) => DropdownMenuItem(
              value: c.id, child: Text(c.name, style: const TextStyle(fontSize: 13)),
            )).toList(),
            onChanged: (v) => setState(() => _randomExistingClubId = v),
          ),
        ),
      RadioListTile<String>(
        dense: true,
        contentPadding: EdgeInsets.zero,
        title: const Text('Create new club', style: TextStyle(fontSize: 14)),
        value: 'new',
        activeColor: const Color(0xFFD9A520),
      ),
      if (_randomClubMode == 'new')
        Padding(
          padding: const EdgeInsets.only(left: 32, bottom: 8),
          child: Row(children: [
            Expanded(child: TextField(
              controller: _newClubCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                hintText: 'Club name (leave blank for random)',
                isDense: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              style: const TextStyle(fontSize: 13),
            )),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => setState(() => _newClubCtrl.text = _clubSuggestions[_rng.nextInt(_clubSuggestions.length)]),
              child: const Tooltip(
                message: 'Suggest a name',
                child: Icon(Icons.shuffle_rounded, size: 20, color: Color(0xFFD9A520)),
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}
