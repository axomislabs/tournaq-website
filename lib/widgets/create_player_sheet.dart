import 'dart:math';
import 'package:flutter/material.dart';
import '../app/app_colors.dart';
import '../l10n/app_localizations.dart';
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
  final _nameCtrl        = TextEditingController();
  final _emailCtrl       = TextEditingController();
  final _teamSearchCtrl  = TextEditingController();
  final _groupSearchCtrl = TextEditingController();
  final Set<String> _teamIds = {};
  final Set<String> _groupIds = {};
  bool _teamExpanded = false;
  bool _groupExpanded = false;
  final _rng = Random();

  static const _firstNames = ['Alex','Charlie','Jordan','Taylor','Morgan','Casey','Jamie','Avery','Riley','Rowan','Skyler','Quinn','Parker','Drew','Reese'];
  static const _lastNames  = ['Harper','Brooks','Cole','Reed','Blake','Carter','Lane','Hayes','Hart','West','Fox','Gray','Shaw','Mason','Finn'];

  @override
  void initState() { super.initState(); _suggestName(); }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _teamSearchCtrl.dispose();
    _groupSearchCtrl.dispose();
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
      role: null,
    );
    final playerId = state.players.last.id;
    for (final id in _teamIds) {
      state = AppDataService.assignUserToTeam(state, userId: playerId, teamId: id);
    }
    for (final id in _groupIds) {
      state = AppDataService.assignPlayerToGroup(state, playerId: playerId, groupId: id);
    }
    Navigator.pop(context, state);
  }

  // ── Searchable multi-select picker ────────────────────────────────────────

  Widget _buildSearchPicker({
    required String label,
    required List<({String id, String name})> items,
    required Set<String> selected,
    required TextEditingController searchCtrl,
    required bool expanded,
    required VoidCallback onToggleExpand,
  }) {
    if (items.isEmpty) return const SizedBox.shrink();

    final query    = searchCtrl.text.toLowerCase();
    final filtered = query.isEmpty
        ? items
        : items.where((i) => i.name.toLowerCase().contains(query)).toList();

    final selectedNames = items
        .where((i) => selected.contains(i.id))
        .map((i) => i.name)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(label,
            style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: Colors.black54)),
        const SizedBox(height: 8),
        // Header button
        InkWell(
          onTap: () {
            setState(() {
              onToggleExpand();
              if (!expanded) searchCtrl.clear();
            });
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(
                color: expanded
                    ? AppColors.gold
                    : Colors.grey.shade400,
                width: expanded ? 1.5 : 1.0,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: selectedNames.isEmpty
                      ? Text('Select $label…',
                          style: TextStyle(
                              fontSize: 14, color: Colors.grey.shade500))
                      : Text(
                          selectedNames.join(', '),
                          style: const TextStyle(fontSize: 14),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                ),
                if (selected.isNotEmpty) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.goldCream,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text('${selected.length}',
                        style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.goldDark)),
                  ),
                  const SizedBox(width: 4),
                ],
                Icon(
                  expanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  size: 20,
                  color: Colors.black45,
                ),
              ],
            ),
          ),
        ),
        // Expanded panel
        if (expanded) ...[
          const SizedBox(height: 4),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.gold, width: 1.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Search field
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
                  child: TextField(
                    controller: searchCtrl,
                    autofocus: true,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: 'Search…',
                      prefixIcon: const Icon(Icons.search_rounded,
                          size: 18, color: Colors.black45),
                      contentPadding:
                          const EdgeInsets.symmetric(vertical: 8),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                const Divider(height: 1),
                // List of items
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 200),
                  child: filtered.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.all(16),
                          child: Text('No results.',
                              style: TextStyle(
                                  fontSize: 13, color: Colors.black38)),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          itemCount: filtered.length,
                          itemBuilder: (_, i) {
                            final item    = filtered[i];
                            final isSelected = selected.contains(item.id);
                            return InkWell(
                              onTap: () => setState(() {
                                if (isSelected) {
                                  selected.remove(item.id);
                                } else {
                                  selected.add(item.id);
                                }
                              }),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 10),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(item.name,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: isSelected
                                                ? FontWeight.w600
                                                : FontWeight.w400,
                                          )),
                                    ),
                                    if (isSelected)
                                      const Icon(Icons.check_rounded,
                                          size: 18, color: AppColors.gold),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // ── Portrait ──────────────────────────────────────────────────────────────

  Widget _buildPortrait(
    AppLocalizations l10n,
    List<({String id, String name})> teams,
    List<({String id, String name})> groups,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration:
                const BoxDecoration(color: AppColors.goldCream, shape: BoxShape.circle),
            child: const Icon(Icons.person_rounded, color: AppColors.gold, size: 22),
          ),
          const SizedBox(width: 12),
          Text(l10n.btnCreatePlayer,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
        ]),
        const SizedBox(height: 24),

        // Name
        Row(children: [
          Expanded(
            child: Text(l10n.labelName,
                style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Colors.black54)),
          ),
          GestureDetector(
            onTap: _suggestName,
            child: Row(children: [
              const Icon(Icons.shuffle_rounded, size: 14, color: AppColors.gold),
              const SizedBox(width: 4),
              Text(l10n.btnSuggest,
                  style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.gold,
                      fontWeight: FontWeight.w600)),
            ]),
          ),
        ]),
        const SizedBox(height: 8),
        TextField(
          controller: _nameCtrl,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 16),

        // Email
        Text(l10n.labelEmailOptional,
            style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: Colors.black54)),
        const SizedBox(height: 8),
        TextField(
          controller: _emailCtrl,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            hintText: 'player@email.com',
          ),
        ),

        // Teams
        _buildSearchPicker(
          label: l10n.labelAssignToTeams,
          items: teams,
          selected: _teamIds,
          searchCtrl: _teamSearchCtrl,
          expanded: _teamExpanded,
          onToggleExpand: () {
            _teamExpanded = !_teamExpanded;
            if (_teamExpanded) _groupExpanded = false;
          },
        ),

        // Groups
        _buildSearchPicker(
          label: l10n.labelAssignToClubs,
          items: groups,
          selected: _groupIds,
          searchCtrl: _groupSearchCtrl,
          expanded: _groupExpanded,
          onToggleExpand: () {
            _groupExpanded = !_groupExpanded;
            if (_groupExpanded) _teamExpanded = false;
          },
        ),

        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _canCreate ? _create : null,
            icon: const Icon(Icons.check_rounded),
            label: Text(l10n.btnCreatePlayer,
                style: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 16)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.gold,
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.grey[200],
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ]),
    );
  }

  // ── Landscape ─────────────────────────────────────────────────────────────

  Widget _buildLandscape(
    AppLocalizations l10n,
    List<({String id, String name})> teams,
    List<({String id, String name})> groups,
  ) {
    final fieldBorder   = OutlineInputBorder(borderRadius: BorderRadius.circular(10));
    const fieldPadding  = EdgeInsets.symmetric(horizontal: 12, vertical: 10);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration:
                const BoxDecoration(color: AppColors.goldCream, shape: BoxShape.circle),
            child: const Icon(Icons.person_rounded, color: AppColors.gold, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(l10n.btnCreatePlayer,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          ),
          ElevatedButton.icon(
            onPressed: _canCreate ? _create : null,
            icon: const Icon(Icons.check_rounded, size: 16),
            label: Text(l10n.btnCreate,
                style: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 14)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.gold,
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.grey[200],
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ]),
        const SizedBox(height: 12),

        // Name + Email row
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(
                child: Text(l10n.labelName,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: Colors.black54)),
              ),
              GestureDetector(
                onTap: _suggestName,
                child: Row(children: [
                  const Icon(Icons.shuffle_rounded,
                      size: 12, color: AppColors.gold),
                  const SizedBox(width: 3),
                  Text(l10n.btnSuggest,
                      style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.gold,
                          fontWeight: FontWeight.w600)),
                ]),
              ),
            ]),
            const SizedBox(height: 6),
            TextField(
              controller: _nameCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                  border: fieldBorder,
                  contentPadding: fieldPadding,
                  isDense: true),
              onChanged: (_) => setState(() {}),
            ),
          ])),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(l10n.labelEmailOptional,
                style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: Colors.black54)),
            const SizedBox(height: 6),
            TextField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                  border: fieldBorder,
                  contentPadding: fieldPadding,
                  isDense: true,
                  hintText: 'player@email.com'),
            ),
          ])),
        ]),

        // Teams + Groups row
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            child: _buildSearchPicker(
              label: l10n.pageTeams,
              items: teams,
              selected: _teamIds,
              searchCtrl: _teamSearchCtrl,
              expanded: _teamExpanded,
              onToggleExpand: () {
                _teamExpanded = !_teamExpanded;
                if (_teamExpanded) _groupExpanded = false;
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildSearchPicker(
              label: l10n.pageClubs,
              items: groups,
              selected: _groupIds,
              searchCtrl: _groupSearchCtrl,
              expanded: _groupExpanded,
              onToggleExpand: () {
                _groupExpanded = !_groupExpanded;
                if (_groupExpanded) _teamExpanded = false;
              },
            ),
          ),
        ]),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n  = AppLocalizations.of(context)!;
    final teams = widget.appState.teams.map((t) => (id: t.id, name: t.name)).toList();
    final groups = widget.appState.groups.map((c) => (id: c.id, name: c.name)).toList();

    return OrientationBuilder(
      builder: (context, orientation) => TournaQSheet(
        body: orientation == Orientation.landscape
            ? _buildLandscape(l10n, teams, groups)
            : _buildPortrait(l10n, teams, groups),
      ),
    );
  }
}
