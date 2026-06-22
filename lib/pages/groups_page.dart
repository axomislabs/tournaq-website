import 'package:flutter/material.dart';
import '../app/app_colors.dart';
import '../models/group.dart';
import '../l10n/app_localizations.dart';
import '../services/app_data_service.dart';
import '../state/app_state.dart';
import '../widgets/tournaq_app_bar.dart';
import '../widgets/assign_dialog.dart';
import '../widgets/create_group_sheet.dart';
import 'group_detail_page.dart';

enum _GroupSearchMode { name, player, team }

class GroupsPage extends StatefulWidget {
  final AppState appState;
  final Function(AppState) onAppStateChanged;
  const GroupsPage({super.key, required this.appState, required this.onAppStateChanged});
  @override
  State<GroupsPage> createState() => _GroupsPageState();
}

class _GroupsPageState extends State<GroupsPage> {
  late AppState _localState;
  final _searchCtrl = TextEditingController();
  _GroupSearchMode _searchMode = _GroupSearchMode.name;

  @override
  void initState() {
    super.initState();
    _localState = widget.appState;
    _searchCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _updateState(AppState s) {
    setState(() => _localState = s);
    widget.onAppStateChanged(s);
  }

  Future<void> _showCreateSheet() async {
    final result = await showModalBottomSheet<AppState>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CreateGroupSheet(appState: _localState),
    );
    if (result != null && mounted) _updateState(result);
  }

  // ── Actions ────────────────────────────────────────────────────────────────

  Future<void> _assignPlayer(String groupId) async {
    final group = _localState.getGroupById(groupId);
    if (group == null) return;
    final items = _localState.players
        .where((u) => !group.playerIds.contains(u.id))
        .map((u) => (id: u.id, name: u.name))
        .toList();
    final selected = await showAssignDialog(
      context: context, title: 'Assign Player', items: items,
      emptyMessage: 'All players are already in this group.',
    );
    if (selected != null && mounted) {
      _updateState(AppDataService.assignPlayerToGroup(_localState, playerId: selected, groupId: groupId));
    }
  }

  Future<void> _assignTeam(String groupId) async {
    final group = _localState.getGroupById(groupId);
    if (group == null) return;
    final items = _localState.teams
        .where((t) => !group.teamIds.contains(t.id))
        .map((t) => (id: t.id, name: t.name))
        .toList();
    final selected = await showAssignDialog(
      context: context, title: 'Assign Team', items: items,
      emptyMessage: 'All teams are already in this group.',
    );
    if (selected != null && mounted) {
      _updateState(AppDataService.assignTeamToGroup(_localState, teamId: selected, groupId: groupId));
    }
  }

  Future<void> _deleteGroup(String groupId) async {
    final group = _localState.getGroupById(groupId);
    if (group == null) return;
    final ok = await showConfirmDeleteDialog(context, group.name);
    if (ok && mounted) _updateState(AppDataService.deleteGroup(_localState, groupId));
  }

  // ── Filter ─────────────────────────────────────────────────────────────────

  List<Group> get _filteredGroups {
    final q = _searchCtrl.text.toLowerCase().trim();
    if (q.isEmpty) return _localState.groups;

    switch (_searchMode) {
      case _GroupSearchMode.name:
        return _localState.groups
            .where((c) => c.name.toLowerCase().contains(q))
            .toList();

      case _GroupSearchMode.player:
        final matchingIds = _localState.players
            .where((p) => p.name.toLowerCase().contains(q))
            .map((p) => p.id)
            .toSet();
        return _localState.groups
            .where((c) => c.playerIds.any(matchingIds.contains))
            .toList();

      case _GroupSearchMode.team:
        final matchingIds = _localState.teams
            .where((t) => t.name.toLowerCase().contains(q))
            .map((t) => t.id)
            .toSet();
        return _localState.groups
            .where((c) => c.teamIds.any(matchingIds.contains))
            .toList();
    }
  }

  // ── Search bar ─────────────────────────────────────────────────────────────

  static const _modeLabels = {
    _GroupSearchMode.name:   'Name',
    _GroupSearchMode.player: 'Player',
    _GroupSearchMode.team:   'Team',
  };

  static const _modeHints = {
    _GroupSearchMode.name:   'Search groups…',
    _GroupSearchMode.player: 'Search by player…',
    _GroupSearchMode.team:   'Search by team…',
  };

  IconData _modeIcon(_GroupSearchMode mode) => switch (mode) {
        _GroupSearchMode.name   => Icons.home_rounded,
        _GroupSearchMode.player => Icons.person_rounded,
        _GroupSearchMode.team   => Icons.group_rounded,
      };

  Widget _buildSearchBar() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
            controller: _searchCtrl,
            decoration: InputDecoration(
              hintText: _modeHints[_searchMode],
              hintStyle: const TextStyle(fontSize: 13, color: Colors.black38),
              prefixIcon: const Icon(Icons.search_rounded, size: 16, color: Colors.black38),
              suffixIcon: _searchCtrl.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close_rounded, size: 16, color: Colors.black38),
                      onPressed: () => setState(() => _searchCtrl.clear()),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
              isDense: true,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: _GroupSearchMode.values.map((m) {
            final selected = m == _searchMode;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => setState(() {
                  _searchMode = m;
                  _searchCtrl.clear();
                }),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: selected ? AppColors.goldCream : Colors.transparent,
                    border: Border.all(
                      color: selected ? AppColors.gold : Colors.grey.shade300,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_modeIcon(m), size: 13,
                          color: selected ? AppColors.goldDark : Colors.black45),
                      const SizedBox(width: 5),
                      Text(_modeLabels[m]!,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                            color: selected ? AppColors.goldDark : Colors.black54,
                          )),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ── Hero card ──────────────────────────────────────────────────────────────

  Widget _buildHeroCard(AppLocalizations l10n) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.gold, AppColors.goldGradientEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.gold.withValues(alpha: 0.28),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.home_rounded, color: Colors.white, size: 22),
              SizedBox(width: 8),
              Text(
                'Groups',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            'Manage your global group pool',
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.90),
                fontSize: 13,
                fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _showCreateSheet,
            icon: const Icon(Icons.add_rounded),
            label: Text(l10n.btnCreateClub,
                style: const TextStyle(fontWeight: FontWeight.w700)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.gold,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final filtered = _filteredGroups;
    final total = _localState.groups.length;

    return Scaffold(
      appBar: TournaQAppBar(title: l10n.pageClubs),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Hero card ──────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: _buildHeroCard(l10n),
          ),
          const SizedBox(height: 20),

          // ── Section header ─────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Icon(Icons.home_rounded, size: 20, color: AppColors.oliveMedium),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${l10n.pageClubs} ($total)',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
          ),

          // ── Search ─────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: _buildSearchBar(),
          ),
          const SizedBox(height: 8),

          // ── Group list ─────────────────────────────────────────────────
          Expanded(
            child: total == 0
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.home_rounded, size: 48, color: Colors.grey.shade300),
                        const SizedBox(height: 12),
                        Text(l10n.noClubsYet,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                                color: Colors.black45)),
                        const SizedBox(height: 4),
                        const Text('Tap Create Group to get started.',
                            style: TextStyle(color: Colors.black38, fontSize: 13)),
                      ],
                    ),
                  )
                : filtered.isEmpty
                    ? Center(
                        child: Text(l10n.noClubsFiltered,
                            style: const TextStyle(color: Colors.black45)),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                        itemCount: filtered.length,
                        itemBuilder: (_, i) => _buildGroupCard(filtered[i], l10n),
                      ),
          ),
        ],
      ),
    );
  }

  // ── Group card ─────────────────────────────────────────────────────────────

  Widget _buildGroupCard(Group group, AppLocalizations l10n) {
    final playerCount = group.playerIds.length;
    final teamCount   = group.teamIds.length;
    final stats = <String>[
      '$playerCount player${playerCount == 1 ? '' : 's'}',
      if (teamCount > 0) '$teamCount team${teamCount == 1 ? '' : 's'}',
    ];

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => GroupDetailPage(
              appState: _localState, onAppStateChanged: _updateState, groupId: group.id),
        )),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.goldCream,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.home_rounded, size: 20, color: AppColors.gold),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(group.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 15)),
                    const SizedBox(height: 2),
                    Text(stats.join(' · '),
                        style: const TextStyle(fontSize: 12, color: Colors.black45)),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, size: 20, color: Colors.black38),
                onSelected: (value) {
                  switch (value) {
                    case 'assign_player': _assignPlayer(group.id);
                    case 'assign_team':   _assignTeam(group.id);
                    case 'delete':        _deleteGroup(group.id);
                  }
                },
                itemBuilder: (_) => [
                  actionMenuItem('assign_player', Icons.person_rounded, l10n.menuAssignPlayer),
                  actionMenuItem('assign_team',   Icons.group_rounded,  l10n.menuAssignTeam),
                  const PopupMenuDivider(),
                  actionMenuItem('delete', Icons.delete_outline, l10n.btnDelete, destructive: true),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
