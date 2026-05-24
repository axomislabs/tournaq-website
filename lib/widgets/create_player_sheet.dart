import 'dart:math';
import 'package:flutter/material.dart';
import '../services/app_data_service.dart';
import '../state/app_state.dart';

class CreatePlayerSheet extends StatefulWidget {
  final AppState appState;
  const CreatePlayerSheet({super.key, required this.appState});
  @override
  State<CreatePlayerSheet> createState() => _CreatePlayerSheetState();
}

class _CreatePlayerSheetState extends State<CreatePlayerSheet> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _roleCtrl = TextEditingController();
  final Set<String> _teamIds = {};
  final Set<String> _clubIds = {};
  final _rng = Random();

  static const _firstNames = ['Alex','Charlie','Jordan','Taylor','Morgan','Casey','Jamie','Avery','Riley','Rowan','Skyler','Quinn','Parker','Drew','Reese'];
  static const _lastNames = ['Harper','Brooks','Cole','Reed','Blake','Carter','Lane','Hayes','Hart','West','Fox','Gray','Shaw','Mason','Finn'];

  @override
  void initState() {
    super.initState();
    _suggestName();
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _emailCtrl.dispose(); _roleCtrl.dispose();
    super.dispose();
  }

  void _suggestName() {
    setState(() {
      _nameCtrl.text = '${_firstNames[_rng.nextInt(_firstNames.length)]} ${_lastNames[_rng.nextInt(_lastNames.length)]}';
    });
  }

  bool get _canCreate => _nameCtrl.text.trim().isNotEmpty;

  void _create() {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    var state = AppDataService.createUser(
      widget.appState,
      name: name,
      email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
      role: _roleCtrl.text.trim().isEmpty ? null : _roleCtrl.text.trim(),
    );
    final playerId = state.users.last.id;
    for (final id in _teamIds) {
      state = AppDataService.assignUserToTeam(state, userId: playerId, teamId: id);
    }
    for (final id in _clubIds) {
      state = AppDataService.assignPlayerToClub(state, playerId: playerId, clubId: id);
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
              // Header
              Row(children: [
                Container(padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(color: Color(0xFFFFF8E1), shape: BoxShape.circle),
                  child: const Icon(Icons.person_rounded, color: Color(0xFFB08B1E), size: 22)),
                const SizedBox(width: 12),
                const Text('Create Player', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
              ]),
              const SizedBox(height: 24),

              // Name
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

              // Email
              const Text('Email (optional)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.black54)),
              const SizedBox(height: 8),
              TextField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  hintText: 'player@email.com'),
              ),
              const SizedBox(height: 16),

              // Role
              const Text('Role (optional)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.black54)),
              const SizedBox(height: 8),
              TextField(
                controller: _roleCtrl,
                decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  hintText: 'e.g. Captain, Goalkeeper'),
              ),

              _buildAssignSection('Assign to Teams', teams, _teamIds),
              _buildAssignSection('Assign to Clubs', clubs, _clubIds),
              const SizedBox(height: 24),

              SizedBox(width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _canCreate ? _create : null,
                  icon: const Icon(Icons.check_rounded),
                  label: const Text('Create Player', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
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
