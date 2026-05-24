import 'dart:math';
import 'package:flutter/material.dart';
import '../models/team.dart';
import '../services/app_data_service.dart';
import '../state/app_state.dart';

class CreateTeamSheet extends StatefulWidget {
  final AppState appState;
  const CreateTeamSheet({super.key, required this.appState});
  @override
  State<CreateTeamSheet> createState() => _CreateTeamSheetState();
}

class _CreateTeamSheetState extends State<CreateTeamSheet> {
  final _nameCtrl = TextEditingController();
  TeamScope _scope = TeamScope.temporary;
  final Set<String> _playerIds = {};
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
    var state = AppDataService.createTeam(widget.appState, name: name, scope: _scope);
    final teamId = state.teams.last.id;
    for (final id in _playerIds) {
      state = AppDataService.assignUserToTeam(state, userId: id, teamId: teamId);
    }
    for (final id in _tournamentIds) {
      state = AppDataService.assignTeamToTournament(state, teamId: teamId, tournamentId: id);
    }
    for (final id in _clubIds) {
      state = AppDataService.assignTeamToClub(state, teamId: teamId, clubId: id);
    }
    Navigator.pop(context, state);
  }

  Widget _buildAssignSection(String label, List<({String id, String name})> items, Set<String> selected) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SizedBox(height: 16),
      Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.black54)),
      const SizedBox(height: 8),
      Wrap(spacing: 8, runSpacing: 4,
        children: items.map((item) => FilterChip(
          label: Text(item.name),
          selected: selected.contains(item.id),
          selectedColor: const Color(0xFFFFF8E1),
          checkmarkColor: const Color(0xFFB08B1E),
          onSelected: (v) => setState(() {
            if (v) { selected.add(item.id); } else { selected.remove(item.id); }
          }),
        )).toList(),
      ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final players = widget.appState.users.map((u) => (id: u.id, name: u.name)).toList();
    final tournaments = widget.appState.tournaments.map((t) => (id: t.id, name: t.name)).toList();
    final clubs = widget.appState.clubs.map((c) => (id: c.id, name: c.name)).toList();

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 4),
            child: Center(child: Container(width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
          ),
          Flexible(child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Row(children: [
                Container(padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(color: Color(0xFFFFF8E1), shape: BoxShape.circle),
                  child: const Icon(Icons.group_rounded, color: Color(0xFFB08B1E), size: 22)),
                const SizedBox(width: 12),
                const Text('Create Team', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
              ]),
              const SizedBox(height: 24),

              Row(children: [
                const Expanded(child: Text('Name', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.black54))),
                GestureDetector(
                  onTap: _suggestName,
                  child: const Row(children: [
                    Icon(Icons.shuffle_rounded, size: 14, color: Color(0xFFB08B1E)),
                    SizedBox(width: 4),
                    Text('Suggest', style: TextStyle(fontSize: 12, color: Color(0xFFB08B1E), fontWeight: FontWeight.w600)),
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

              _buildAssignSection('Assign Players', players, _playerIds),
              _buildAssignSection('Assign to Tournaments', tournaments, _tournamentIds),
              _buildAssignSection('Assign to Clubs', clubs, _clubIds),
              const SizedBox(height: 24),

              SizedBox(width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _canCreate ? _create : null,
                  icon: const Icon(Icons.check_rounded),
                  label: const Text('Create Team', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFB08B1E),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey[200],
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ]),
          )),
        ]),
      ),
    );
  }
}
