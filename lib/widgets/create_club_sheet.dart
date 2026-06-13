import 'package:flutter/material.dart';
import '../app/app_colors.dart';
import '../l10n/app_localizations.dart';
import '../services/app_data_service.dart';
import '../state/app_state.dart';
import 'sheet_helpers.dart';

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

  Widget _buildPortrait(
    AppLocalizations l10n,
    List<({String id, String name})> players,
    List<({String id, String name})> teams,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Container(padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(color: AppColors.goldCream, shape: BoxShape.circle),
            child: const Icon(Icons.shield_rounded, color: AppColors.gold, size: 22)),
          const SizedBox(width: 12),
          Text(l10n.btnCreateClub, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
        ]),
        const SizedBox(height: 24),

        Text(l10n.labelName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.black54)),
        const SizedBox(height: 8),
        TextField(
          controller: _nameCtrl,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            hintText: l10n.hintClubName,
          ),
          onChanged: (_) => setState(() {}),
        ),

        _buildChipSection(l10n.labelAssignPlayers, players, _playerIds),
        _buildChipSection(l10n.labelAssignTeams, teams, _teamIds),
        const SizedBox(height: 24),

        SizedBox(width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _canCreate ? _create : null,
            icon: const Icon(Icons.check_rounded),
            label: Text(l10n.btnCreateClub, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
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

  Widget _buildLandscape(
    AppLocalizations l10n,
    List<({String id, String name})> players,
    List<({String id, String name})> teams,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Container(padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(color: AppColors.goldCream, shape: BoxShape.circle),
            child: const Icon(Icons.shield_rounded, color: AppColors.gold, size: 18)),
          const SizedBox(width: 10),
          Expanded(child: Text(l10n.btnCreateClub, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800))),
          ElevatedButton.icon(
            onPressed: _canCreate ? _create : null,
            icon: const Icon(Icons.check_rounded, size: 16),
            label: Text(l10n.btnCreate, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
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

        Text(l10n.labelName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.black54)),
        const SizedBox(height: 6),
        TextField(
          controller: _nameCtrl,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            isDense: true,
            hintText: l10n.hintClubName,
          ),
          onChanged: (_) => setState(() {}),
        ),

        _buildChipSection(l10n.pagePlayers, players, _playerIds),
        _buildChipSection(l10n.pageTeams, teams, _teamIds),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final players = widget.appState.players.map((u) => (id: u.id, name: u.name)).toList();
    final teams = widget.appState.teams.map((t) => (id: t.id, name: t.name)).toList();

    return OrientationBuilder(
      builder: (context, orientation) => TournaQSheet(
        body: orientation == Orientation.landscape
            ? _buildLandscape(l10n, players, teams)
            : _buildPortrait(l10n, players, teams),
      ),
    );
  }
}
