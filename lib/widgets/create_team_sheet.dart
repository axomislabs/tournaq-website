import 'dart:math';
import 'package:flutter/material.dart';
import '../app/app_colors.dart';
import '../models/team.dart';
import '../services/app_data_service.dart';
import '../state/app_state.dart';
import 'sheet_helpers.dart';

class CreateTeamSheet extends StatefulWidget {
  final AppState appState;
  const CreateTeamSheet({super.key, required this.appState});
  @override
  State<CreateTeamSheet> createState() => _CreateTeamSheetState();
}

class _CreateTeamSheetState extends State<CreateTeamSheet> {
  final _nameCtrl = TextEditingController();
  TeamScope _scope = TeamScope.temporary;
  final Set<String> _tournamentIds = {};
  final Set<String> _clubIds = {};
  final _rng = Random();

  static const _prefixes = ['Falcon','Phoenix','Lion','Tiger','Eagle','Storm','Dragon','Viper','Thunder','Raven','Comet','Shadow','Blaze','Orbit','Nova'];
  static const _suffixes = ['Squad','Team','Crew','Force','Unit','Pack','Alliance','Legion','Clan','Dynasty'];

  @override
  void initState() { super.initState(); _suggestName(); }

  @override
  void dispose() { _nameCtrl.dispose(); super.dispose(); }

  void _suggestName() {
    setState(() {
      _nameCtrl.text = '${_prefixes[_rng.nextInt(_prefixes.length)]} ${_suffixes[_rng.nextInt(_suffixes.length)]}';
    });
  }

  bool get _canCreate => _nameCtrl.text.trim().isNotEmpty;

  String _scopeLabel(TeamScope s) => switch (s) {
    TeamScope.temporary => 'Temporary',
    TeamScope.tournament => 'Tournament',
    TeamScope.club => 'Club',
  };

  void _create() {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    var state = AppDataService.createTeamWithPlayers(widget.appState, name: name, scope: _scope);
    final teamId = state.teams.last.id;
    for (final id in _tournamentIds) {
      state = AppDataService.assignTeamToTournament(state, teamId: teamId, tournamentId: id);
    }
    for (final id in _clubIds) {
      state = AppDataService.assignTeamToClub(state, teamId: teamId, clubId: id);
    }
    Navigator.pop(context, state);
  }

  Widget _buildChipSection(String label, List<({String id, String name})> items, Set<String> selected) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SizedBox(height: 16),
      Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.black54)),
      const SizedBox(height: 8),
      Wrap(spacing: 8, runSpacing: 4,
        children: items.map((item) => FilterChip(
          label: Text(item.name),
          selected: selected.contains(item.id),
          selectedColor: AppColors.goldCream,
          checkmarkColor: AppColors.gold,
          onSelected: (v) => setState(() {
            if (v) { selected.add(item.id); } else { selected.remove(item.id); }
          }),
        )).toList(),
      ),
    ]);
  }

  Widget _buildPortrait(List<({String id, String name})> tournaments, List<({String id, String name})> clubs) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Container(padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(color: AppColors.goldCream, shape: BoxShape.circle),
            child: const Icon(Icons.group_rounded, color: AppColors.gold, size: 22)),
          const SizedBox(width: 12),
          const Text('Create Team', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
        ]),
        const SizedBox(height: 24),

        Row(children: [
          const Expanded(child: Text('Name', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.black54))),
          GestureDetector(
            onTap: _suggestName,
            child: const Row(children: [
              Icon(Icons.shuffle_rounded, size: 14, color: AppColors.gold),
              SizedBox(width: 4),
              Text('Suggest', style: TextStyle(fontSize: 12, color: AppColors.gold, fontWeight: FontWeight.w600)),
            ]),
          ),
        ]),
        const SizedBox(height: 8),
        TextField(
          controller: _nameCtrl,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14)),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 16),

        const Text('Scope', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.black54)),
        const SizedBox(height: 8),
        DropdownButtonFormField<TeamScope>(
          initialValue: _scope,
          decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14)),
          items: TeamScope.values.map((s) => DropdownMenuItem(value: s, child: Text(_scopeLabel(s)))).toList(),
          onChanged: (v) { if (v != null) setState(() => _scope = v); },
        ),

        _buildChipSection('Assign to Tournaments', tournaments, _tournamentIds),
        _buildChipSection('Assign to Clubs', clubs, _clubIds),
        const SizedBox(height: 24),

        SizedBox(width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _canCreate ? _create : null,
            icon: const Icon(Icons.check_rounded),
            label: const Text('Create Team', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
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
    );
  }

  Widget _buildLandscape(List<({String id, String name})> tournaments, List<({String id, String name})> clubs) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        // Header row: icon + title + Create button
        Row(children: [
          Container(padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(color: AppColors.goldCream, shape: BoxShape.circle),
            child: const Icon(Icons.group_rounded, color: AppColors.gold, size: 18)),
          const SizedBox(width: 10),
          const Expanded(child: Text('Create Team', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800))),
          ElevatedButton.icon(
            onPressed: _canCreate ? _create : null,
            icon: const Icon(Icons.check_rounded, size: 16),
            label: const Text('Create', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.gold,
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.grey[200],
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ]),
        const SizedBox(height: 12),

        // Name + Scope side-by-side
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(flex: 5, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Expanded(child: Text('Name', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.black54))),
              GestureDetector(
                onTap: _suggestName,
                child: const Row(children: [
                  Icon(Icons.shuffle_rounded, size: 12, color: AppColors.gold),
                  SizedBox(width: 3),
                  Text('Suggest', style: TextStyle(fontSize: 11, color: AppColors.gold, fontWeight: FontWeight.w600)),
                ]),
              ),
            ]),
            const SizedBox(height: 6),
            TextField(
              controller: _nameCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                isDense: true,
              ),
              onChanged: (_) => setState(() {}),
            ),
          ])),
          const SizedBox(width: 12),
          Expanded(flex: 4, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Scope', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.black54)),
            const SizedBox(height: 6),
            DropdownButtonFormField<TeamScope>(
              initialValue: _scope,
              isDense: true,
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              items: TeamScope.values.map((s) => DropdownMenuItem(
                value: s,
                child: Text(_scopeLabel(s), style: const TextStyle(fontSize: 13)),
              )).toList(),
              onChanged: (v) { if (v != null) setState(() => _scope = v); },
            ),
          ])),
        ]),

        _buildChipSection('Tournaments', tournaments, _tournamentIds),
        _buildChipSection('Clubs', clubs, _clubIds),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tournaments = widget.appState.tournaments.map((t) => (id: t.id, name: t.name)).toList();
    final clubs = widget.appState.clubs.map((c) => (id: c.id, name: c.name)).toList();

    return OrientationBuilder(
      builder: (context, orientation) => TournaQSheet(
        body: orientation == Orientation.landscape
            ? _buildLandscape(tournaments, clubs)
            : _buildPortrait(tournaments, clubs),
      ),
    );
  }
}
