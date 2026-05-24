import 'package:flutter/material.dart';
import '../services/app_data_service.dart';
import '../state/app_state.dart';

class CreateClubSheet extends StatefulWidget {
  final AppState appState;
  const CreateClubSheet({super.key, required this.appState});
  @override
  State<CreateClubSheet> createState() => _CreateClubSheetState();
}

class _CreateClubSheetState extends State<CreateClubSheet> {
  final _nameCtrl = TextEditingController();
  final Set<String> _playerIds = {};
  final Set<String> _teamIds = {};
  final Set<String> _tournamentIds = {};

  @override
  void dispose() { _nameCtrl.dispose(); super.dispose(); }

  bool get _canCreate => _nameCtrl.text.trim().isNotEmpty;

  void _create() {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    var state = AppDataService.createClub(widget.appState, name: name);
    final clubId = state.clubs.last.id;
    for (final id in _playerIds) {
      state = AppDataService.assignPlayerToClub(state, playerId: id, clubId: clubId);
    }
    for (final id in _teamIds) {
      state = AppDataService.assignTeamToClub(state, teamId: id, clubId: clubId);
    }
    for (final id in _tournamentIds) {
      state = AppDataService.assignTournamentToClub(state, tournamentId: id, clubId: clubId);
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
    final teams = widget.appState.teams.map((t) => (id: t.id, name: t.name)).toList();
    final tournaments = widget.appState.tournaments.map((t) => (id: t.id, name: t.name)).toList();

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
                  child: const Icon(Icons.shield_rounded, color: Color(0xFFB08B1E), size: 22)),
                const SizedBox(width: 12),
                const Text('Create Club', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
              ]),
              const SizedBox(height: 24),

              const Text('Name', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.black54)),
              const SizedBox(height: 8),
              TextField(
                controller: _nameCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  hintText: 'Club name'),
                onChanged: (_) => setState(() {}),
              ),

              _buildAssignSection('Assign Players', players, _playerIds),
              _buildAssignSection('Assign Teams', teams, _teamIds),
              _buildAssignSection('Assign Tournaments', tournaments, _tournamentIds),
              const SizedBox(height: 24),

              SizedBox(width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _canCreate ? _create : null,
                  icon: const Icon(Icons.check_rounded),
                  label: const Text('Create Club', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
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
