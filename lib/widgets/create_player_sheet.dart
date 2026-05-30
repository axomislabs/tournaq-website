import 'dart:math';
import 'package:flutter/material.dart';
import '../app/app_colors.dart';
import '../services/app_data_service.dart';
import '../state/app_state.dart';
import 'sheet_helpers.dart';

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
  void initState() { super.initState(); _suggestName(); }

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

  Widget _buildPortrait(List<({String id, String name})> teams, List<({String id, String name})> clubs) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Container(padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(color: AppColors.goldCream, shape: BoxShape.circle),
            child: const Icon(Icons.person_rounded, color: AppColors.gold, size: 22)),
          const SizedBox(width: 12),
          const Text('Create Player', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
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

        const Text('Role (optional)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.black54)),
        const SizedBox(height: 8),
        TextField(
          controller: _roleCtrl,
          decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            hintText: 'e.g. Captain, Goalkeeper'),
        ),

        _buildChipSection('Assign to Teams', teams, _teamIds),
        _buildChipSection('Assign to Clubs', clubs, _clubIds),
        const SizedBox(height: 24),

        SizedBox(width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _canCreate ? _create : null,
            icon: const Icon(Icons.check_rounded),
            label: const Text('Create Player', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
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

  Widget _buildLandscape(List<({String id, String name})> teams, List<({String id, String name})> clubs) {
    final fieldBorder = OutlineInputBorder(borderRadius: BorderRadius.circular(10));
    const fieldPadding = EdgeInsets.symmetric(horizontal: 12, vertical: 10);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        // Header row: icon + title + Create button
        Row(children: [
          Container(padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(color: AppColors.goldCream, shape: BoxShape.circle),
            child: const Icon(Icons.person_rounded, color: AppColors.gold, size: 18)),
          const SizedBox(width: 10),
          const Expanded(child: Text('Create Player', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800))),
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

        // Name + Email side-by-side
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
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
              decoration: InputDecoration(border: fieldBorder, contentPadding: fieldPadding, isDense: true),
              onChanged: (_) => setState(() {}),
            ),
          ])),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Email (optional)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.black54)),
            const SizedBox(height: 6),
            TextField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(border: fieldBorder, contentPadding: fieldPadding, isDense: true, hintText: 'player@email.com'),
            ),
          ])),
        ]),
        const SizedBox(height: 10),

        // Role (full width, compact)
        const Text('Role (optional)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.black54)),
        const SizedBox(height: 6),
        TextField(
          controller: _roleCtrl,
          decoration: InputDecoration(
            border: fieldBorder,
            contentPadding: fieldPadding,
            isDense: true,
            hintText: 'e.g. Captain, Goalkeeper',
          ),
        ),

        _buildChipSection('Teams', teams, _teamIds),
        _buildChipSection('Clubs', clubs, _clubIds),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final teams = widget.appState.teams.map((t) => (id: t.id, name: t.name)).toList();
    final clubs = widget.appState.clubs.map((c) => (id: c.id, name: c.name)).toList();

    return OrientationBuilder(
      builder: (context, orientation) => TournaQSheet(
        body: orientation == Orientation.landscape
            ? _buildLandscape(teams, clubs)
            : _buildPortrait(teams, clubs),
      ),
    );
  }
}
