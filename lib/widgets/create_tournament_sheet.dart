import 'dart:math';
import 'package:flutter/material.dart';
import '../app/app_colors.dart';
import '../l10n/app_localizations.dart';
import '../models/club.dart';
import '../models/team.dart';
import '../models/tournament_mode.dart';
import '../services/app_data_service.dart';
import '../state/app_state.dart';
import 'hybrid_mode_setup_page.dart';
import 'sheet_helpers.dart';

class CreateTournamentSheet extends StatefulWidget {
  final AppState appState;
  /// Called when the user selects Timed Scramble and taps Create.
  /// The sheet pops itself; the caller should navigate to ScrambleSetupPage.
  final VoidCallback? onTimedScramble;
  const CreateTournamentSheet({
    super.key,
    required this.appState,
    this.onTimedScramble,
  });
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
    if (_mode == TournamentModeType.timedScramble) {
      Navigator.pop(context);
      widget.onTimedScramble?.call();
      return;
    }

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
      state = AppDataService.updateTournament(state, t.copyWith(hybridGroups: _hybridGroups));
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
    final l10n = AppLocalizations.of(context)!;
    final clubs = widget.appState.clubs;

    return TournaQSheet(
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(color: AppColors.goldCream, shape: BoxShape.circle),
              child: const Icon(Icons.emoji_events_rounded, color: AppColors.gold, size: 22),
            ),
            const SizedBox(width: 12),
            Text(l10n.btnCreateTournament, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
          ]),
          const SizedBox(height: 24),

          Row(children: [
            Expanded(child: Text(l10n.labelName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.black54))),
            GestureDetector(
              onTap: _suggestName,
              child: Row(children: [
                const Icon(Icons.shuffle_rounded, size: 14, color: AppColors.gold),
                const SizedBox(width: 4),
                Text(l10n.btnSuggest, style: const TextStyle(fontSize: 12, color: AppColors.gold, fontWeight: FontWeight.w600)),
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

          Text(l10n.labelMode, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.black54)),
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

          if (_mode == TournamentModeType.hybrid) ...[
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: _openHybridSetup,
              icon: const Icon(Icons.tune_rounded, size: 18),
              label: Text(
                _hybridGroups.isEmpty
                    ? l10n.hybridConfigureGroups
                    : l10n.hybridGroupsConfigured(_hybridGroups.length),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.gold,
                side: const BorderSide(color: AppColors.gold),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],

          const SizedBox(height: 24),
          const Divider(height: 1),
          const SizedBox(height: 20),

          Text(l10n.labelAssignExistingTeams, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.black54)),
          const SizedBox(height: 10),

          if (widget.appState.teams.isEmpty)
            Text(l10n.noTeamsAvailableYet, style: const TextStyle(color: Colors.black45, fontSize: 13))
          else ...[
            if (clubs.isNotEmpty) ...[
              _buildClubFilter(l10n, clubs),
              const SizedBox(height: 10),
            ],
            _useDragDrop ? _buildDragDropSection(l10n) : _buildSearchableSection(l10n),
          ],

          const SizedBox(height: 24),
          const Divider(height: 1),
          const SizedBox(height: 20),

          Text(l10n.labelGenerateRandomTeams, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.black54)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8, runSpacing: 4,
            children: [0, 4, 6, 8, 10, 12, 16].map((n) => ChoiceChip(
              label: Text(n == 0 ? l10n.labelNone : '$n'),
              selected: _randomTeamCount == n,
              selectedColor: AppColors.goldCream,
              checkmarkColor: AppColors.gold,
              onSelected: (_) => setState(() => _randomTeamCount = n),
            )).toList(),
          ),

          if (_randomTeamCount > 0) ...[
            const SizedBox(height: 14),
            Text(l10n.labelClubForRandomTeams, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.black54)),
            const SizedBox(height: 4),
            _buildRandomClubSection(l10n, clubs),
          ],

          if (clubs.isNotEmpty) ...[
            const SizedBox(height: 24),
            const Divider(height: 1),
            const SizedBox(height: 20),
            Text(l10n.labelAssignToClubs, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.black54)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8, runSpacing: 4,
              children: clubs.map((c) => FilterChip(
                label: Text(c.name),
                selected: _tournamentClubIds.contains(c.id),
                selectedColor: AppColors.goldCream,
                checkmarkColor: AppColors.gold,
                onSelected: (v) => setState(() {
                  if (v) { _tournamentClubIds.add(c.id); } else { _tournamentClubIds.remove(c.id); }
                }),
              )).toList(),
            ),
          ],

          const SizedBox(height: 28),

          SizedBox(width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _canCreate ? _create : null,
              icon: const Icon(Icons.check_rounded),
              label: Text(l10n.btnCreateTournament, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gold,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey[200],
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildClubFilter(AppLocalizations l10n, List<Club> clubs) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(children: [
        FilterChip(
          label: Text(l10n.filterAllClubs),
          selected: _clubFilterId == null,
          selectedColor: AppColors.goldCream,
          checkmarkColor: AppColors.gold,
          onSelected: (_) => setState(() => _clubFilterId = null),
        ),
        ...clubs.map((c) => Padding(
          padding: const EdgeInsets.only(left: 8),
          child: FilterChip(
            label: Text(c.name),
            selected: _clubFilterId == c.id,
            selectedColor: AppColors.goldCream,
            checkmarkColor: AppColors.gold,
            onSelected: (_) => setState(() => _clubFilterId = _clubFilterId == c.id ? null : c.id),
          ),
        )),
      ]),
    );
  }

  Widget _buildDragDropSection(AppLocalizations l10n) {
    final available = _filteredTeams.where((t) => !_selectedTeamIds.contains(t.id)).toList();
    final allSelected = widget.appState.teams.where((t) => _selectedTeamIds.contains(t.id)).toList();

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      if (available.isEmpty && allSelected.isEmpty)
        Text(l10n.noTeamsInClub, style: const TextStyle(color: Colors.black45, fontSize: 13))
      else if (available.isNotEmpty) ...[
        Text(l10n.labelAvailable, style: const TextStyle(fontSize: 12, color: Colors.black45, fontWeight: FontWeight.w600)),
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
                backgroundColor: AppColors.gold,
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
              color: isHovering ? AppColors.goldCream : Colors.grey[50],
              border: Border.all(
                color: isHovering ? AppColors.gold : Colors.grey[300]!,
                width: isHovering ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: showEmpty
                ? Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.drag_indicator_rounded, size: 16, color: Colors.grey[400]),
                    const SizedBox(width: 6),
                    Text(l10n.hintDragTeamsHere, style: TextStyle(color: Colors.grey[400], fontSize: 13)),
                  ])
                : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(
                      l10n.labelSelectedCount(allSelected.length),
                      style: const TextStyle(fontSize: 12, color: Colors.black45, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8, runSpacing: 6,
                      children: [
                        ...allSelected.map((t) => Chip(
                          label: Text(t.name),
                          backgroundColor: AppColors.goldCream,
                          deleteIconColor: AppColors.gold,
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
                              backgroundColor: AppColors.goldCream,
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

  Widget _buildSearchableSection(AppLocalizations l10n) {
    final searched = _searchedTeams;
    final allSelected = widget.appState.teams.where((t) => _selectedTeamIds.contains(t.id)).toList();

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      if (allSelected.isNotEmpty) ...[
        Text(l10n.labelSelectedCount(allSelected.length), style: const TextStyle(fontSize: 12, color: Colors.black45, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8, runSpacing: 6,
          children: allSelected.map((t) => Chip(
            label: Text(t.name),
            backgroundColor: AppColors.goldCream,
            deleteIconColor: AppColors.gold,
            labelStyle: const TextStyle(fontSize: 13),
            onDeleted: () => setState(() => _selectedTeamIds.remove(t.id)),
          )).toList(),
        ),
        const SizedBox(height: 10),
      ],

      TextField(
        controller: _teamSearchCtrl,
        decoration: InputDecoration(
          hintText: l10n.hintSearchTeams,
          prefixIcon: const Icon(Icons.search_rounded, size: 20),
          isDense: true,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
      ),
      const SizedBox(height: 8),

      if (searched.isEmpty)
        Padding(
          padding: const EdgeInsets.all(8),
          child: Text(l10n.noTeamsFoundSearch, style: const TextStyle(color: Colors.black45, fontSize: 13)),
        )
      else
        ...searched.map((t) => CheckboxListTile(
          dense: true,
          title: Text(t.name, style: const TextStyle(fontSize: 14)),
          subtitle: Text(t.scope.name, style: const TextStyle(fontSize: 12)),
          value: _selectedTeamIds.contains(t.id),
          activeColor: AppColors.gold,
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
          onChanged: (v) => setState(() {
            if (v == true) { _selectedTeamIds.add(t.id); } else { _selectedTeamIds.remove(t.id); }
          }),
        )),
    ]);
  }

  Widget _buildRandomClubSection(AppLocalizations l10n, List<Club> clubs) {
    return RadioGroup<String>(
      groupValue: _randomClubMode,
      onChanged: (v) { if (v != null) setState(() => _randomClubMode = v); },
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      RadioListTile<String>(
        dense: true,
        contentPadding: EdgeInsets.zero,
        title: Text(l10n.radioNoClub, style: const TextStyle(fontSize: 14)),
        value: 'none',
        activeColor: AppColors.gold,
      ),
      if (clubs.isNotEmpty)
        RadioListTile<String>(
          dense: true,
          contentPadding: EdgeInsets.zero,
          title: Text(l10n.radioAddToExistingClub, style: const TextStyle(fontSize: 14)),
          value: 'existing',
          activeColor: AppColors.gold,
        ),
      if (_randomClubMode == 'existing' && clubs.isNotEmpty)
        Padding(
          padding: const EdgeInsets.only(left: 32, bottom: 8),
          child: DropdownButtonFormField<String>(
            initialValue: _randomExistingClubId,
            hint: Text(l10n.hintSelectClub, style: const TextStyle(fontSize: 13)),
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
        title: Text(l10n.radioCreateNewClub, style: const TextStyle(fontSize: 14)),
        value: 'new',
        activeColor: AppColors.gold,
      ),
      if (_randomClubMode == 'new')
        Padding(
          padding: const EdgeInsets.only(left: 32, bottom: 8),
          child: Row(children: [
            Expanded(child: TextField(
              controller: _newClubCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                hintText: l10n.hintClubNameRandom,
                isDense: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              style: const TextStyle(fontSize: 13),
            )),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => setState(() => _newClubCtrl.text = _clubSuggestions[_rng.nextInt(_clubSuggestions.length)]),
              child: Tooltip(
                message: l10n.tooltipSuggestName,
                child: const Icon(Icons.shuffle_rounded, size: 20, color: AppColors.gold),
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}
