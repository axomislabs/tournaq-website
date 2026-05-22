import 'dart:math';
import 'package:flutter/material.dart';
import '../models/team.dart';
import '../models/tournament_mode.dart';
import '../services/app_data_service.dart';
import '../state/app_state.dart';

class CreateTournamentSheet extends StatefulWidget {
  final AppState appState;
  const CreateTournamentSheet({super.key, required this.appState});
  @override
  State<CreateTournamentSheet> createState() => _CreateTournamentSheetState();
}

class _CreateTournamentSheetState extends State<CreateTournamentSheet> {
  final _nameCtrl = TextEditingController();
  TournamentModeType _mode = TournamentModeType.league;
  final Set<String> _teamIds = {};
  final Set<String> _clubIds = {};
  int _randomTeamCount = 0;
  final _rng = Random();

  static const _prefixes = ['Summer','Winter','Spring','Autumn','Regional','National','City','Open','Grand','Elite'];
  static const _suffixes = ['League','Cup','Championship','Series','Classic','Invitational','Open','Masters'];

  @override
  void initState() { super.initState(); _suggestName(); }

  @override
  void dispose() { _nameCtrl.dispose(); super.dispose(); }

  void _suggestName() {
    setState(() {
      _nameCtrl.text = '${_prefixes[_rng.nextInt(_prefixes.length)]} ${_suffixes[_rng.nextInt(_suffixes.length)]} ${DateTime.now().year}';
    });
  }

  bool get _canCreate => _nameCtrl.text.trim().isNotEmpty;

  void _create() {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    var state = AppDataService.createTournament(
      widget.appState, name: name, mode: TournamentMode.fromType(_mode));
    final tournamentId = state.tournaments.last.id;

    // Generate random teams if requested
    if (_randomTeamCount > 0) {
      const teamPrefixes = ['Falcon','Phoenix','Lion','Tiger','Eagle','Storm','Dragon','Viper','Thunder','Raven'];
      const teamSuffixes = ['Squad','Team','Crew','Force','Unit','Pack','Alliance','Legion','Clan','Dynasty'];
      for (var i = 0; i < _randomTeamCount; i++) {
        final teamName = '${teamPrefixes[_rng.nextInt(teamPrefixes.length)]} ${teamSuffixes[_rng.nextInt(teamSuffixes.length)]}';
        state = AppDataService.createTeam(state, name: teamName, scope: TeamScope.tournament);
        final teamId = state.teams.last.id;
        state = AppDataService.assignTeamToTournament(state, teamId: teamId, tournamentId: tournamentId);
      }
    }

    for (final id in _teamIds) {
      state = AppDataService.assignTeamToTournament(state, teamId: id, tournamentId: tournamentId);
    }
    for (final id in _clubIds) {
      state = AppDataService.assignTournamentToClub(state, tournamentId: tournamentId, clubId: id);
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
          selectedColor: const Color(0xFFFFF3CC),
          checkmarkColor: const Color(0xFFD9A520),
          onSelected: (v) => setState(() {
            if (v) { selected.add(item.id); } else { selected.remove(item.id); }
          }),
        )).toList(),
      ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final teams = widget.appState.teams.map((t) => (id: t.id, name: t.name)).toList();
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
                  decoration: const BoxDecoration(color: Color(0xFFFFF3CC), shape: BoxShape.circle),
                  child: const Icon(Icons.emoji_events_rounded, color: Color(0xFFD9A520), size: 22)),
                const SizedBox(width: 12),
                const Text('Create Tournament', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
              ]),
              const SizedBox(height: 24),

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
                decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14)),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 16),

              const Text('Mode', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.black54)),
              const SizedBox(height: 8),
              DropdownButtonFormField<TournamentModeType>(
                initialValue: _mode,
                decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14)),
                items: TournamentModeType.values.map((m) => DropdownMenuItem(
                  value: m, child: Text(TournamentMode.fromType(m).displayName))).toList(),
                onChanged: (v) { if (v != null) setState(() => _mode = v); },
              ),
              const SizedBox(height: 16),

              // Random team generation
              const Text('Generate Random Teams', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.black54)),
              const SizedBox(height: 8),
              Wrap(spacing: 8, runSpacing: 4,
                children: [0, 4, 6, 8, 10, 12, 16].map((n) => ChoiceChip(
                  label: Text(n == 0 ? 'None' : '$n'),
                  selected: _randomTeamCount == n,
                  selectedColor: const Color(0xFFFFF3CC),
                  onSelected: (_) => setState(() => _randomTeamCount = n),
                )).toList(),
              ),

              _buildAssignSection('Assign Existing Teams', teams, _teamIds),
              _buildAssignSection('Assign to Clubs', clubs, _clubIds),
              const SizedBox(height: 24),

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
}
