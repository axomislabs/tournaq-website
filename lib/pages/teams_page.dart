import 'package:flutter/material.dart';
import '../app/app_colors.dart';
import '../l10n/app_localizations.dart';
import '../models/team.dart';
import '../services/app_data_service.dart';
import '../services/ko_bracket_storage_service.dart';
import '../state/app_state.dart';
import '../widgets/tournaq_app_bar.dart';
import '../widgets/assign_dialog.dart';
import '../widgets/create_team_sheet.dart';
import 'team_detail_page.dart';

enum _TeamSearchMode { name, player, tournament }

class TeamsPage extends StatefulWidget {
  final AppState appState;
  final Function(AppState) onAppStateChanged;
  const TeamsPage({super.key, required this.appState, required this.onAppStateChanged});
  @override
  State<TeamsPage> createState() => _TeamsPageState();
}

class _TeamsPageState extends State<TeamsPage> {
  late AppState _localState;
  final _searchCtrl = TextEditingController();
  _TeamSearchMode _searchMode = _TeamSearchMode.name;
  // tournamentName → set of global Team ids that participated
  Map<String, Set<String>> _teamsByTournamentName = {};

  @override
  void initState() {
    super.initState();
    _localState = widget.appState;
    _searchCtrl.addListener(() => setState(() {}));
    _loadTournamentIndex();
  }

  void _loadTournamentIndex() {
    final byName = <String, Set<String>>{};
    for (final t in KoBracketStorageService.loadAll()) {
      for (final team in t.teams) {
        if (team.hubTeamId != null) {
          (byName[t.name] ??= {}).add(team.hubTeamId!);
        }
      }
    }
    setState(() => _teamsByTournamentName = byName);
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
      builder: (_) => CreateTeamSheet(appState: _localState),
    );
    if (result != null && mounted) _updateState(result);
  }

  // ── Actions ────────────────────────────────────────────────────────────────

  Future<void> _assignGroup(String teamId) async {
    final items = _localState.groups
        .where((c) => !c.teamIds.contains(teamId))
        .map((c) => (id: c.id, name: c.name))
        .toList();
    final selected = await showAssignDialog(
      context: context, title: 'Assign to Group', items: items,
      emptyMessage: 'Team is already in all groups.',
    );
    if (selected != null && mounted) {
      _updateState(AppDataService.assignTeamToGroup(_localState, teamId: teamId, groupId: selected));
    }
  }

  Future<void> _deleteTeam(String teamId) async {
    final team = _localState.getTeamById(teamId);
    if (team == null) return;
    final ok = await showConfirmDeleteDialog(context, team.name);
    if (ok && mounted) _updateState(AppDataService.deleteTeam(_localState, teamId));
  }

  Future<void> _deleteAllTeams() async {
    final count = _localState.teams.length;
    if (count == 0) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete All Teams',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        content: Text(
          'This removes all $count teams from your team pool.\n\n'
          'Players will lose their team memberships and groups will '
          'lose their team references.\n\n'
          'Any games that were played with these teams will show a '
          'generic name ("Team 1 / Team 2") instead of the team name.',
          style: const TextStyle(fontSize: 14, color: Colors.black54, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    var state = _localState;
    for (final team in List.from(state.teams)) {
      state = AppDataService.deleteTeam(state, team.id);
    }
    _updateState(state);
  }

  // ── Filter ─────────────────────────────────────────────────────────────────

  List<Team> get _filteredTeams {
    final q = _searchCtrl.text.toLowerCase().trim();
    if (q.isEmpty) return _localState.teams;

    switch (_searchMode) {
      case _TeamSearchMode.name:
        return _localState.teams
            .where((t) => t.name.toLowerCase().contains(q))
            .toList();

      case _TeamSearchMode.player:
        final matchingPlayerIds = _localState.players
            .where((p) => p.name.toLowerCase().contains(q))
            .map((p) => p.id)
            .toSet();
        return _localState.teams
            .where((t) => t.userIds.any(matchingPlayerIds.contains))
            .toList();

      case _TeamSearchMode.tournament:
        final matchingTeamIds = _teamsByTournamentName.entries
            .where((e) => e.key.toLowerCase().contains(q))
            .expand((e) => e.value)
            .toSet();
        return _localState.teams
            .where((t) => matchingTeamIds.contains(t.id))
            .toList();
    }
  }

  // ── Search bar ────────────────────────────────────────────────────────────

  static const _modeLabels = {
    _TeamSearchMode.name:       'Name',
    _TeamSearchMode.player:     'Player',
    _TeamSearchMode.tournament: 'Tournament',
  };

  static const _modeHints = {
    _TeamSearchMode.name:       'Search teams…',
    _TeamSearchMode.player:     'Search by player…',
    _TeamSearchMode.tournament: 'Search by tournament…',
  };

  IconData _modeIcon(_TeamSearchMode mode) => switch (mode) {
        _TeamSearchMode.name       => Icons.group_rounded,
        _TeamSearchMode.player     => Icons.person_rounded,
        _TeamSearchMode.tournament => Icons.emoji_events_rounded,
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
          children: _TeamSearchMode.values.map((m) {
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

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l10n     = AppLocalizations.of(context)!;
    final filtered = _filteredTeams;
    final total    = _localState.teams.length;

    return Scaffold(
      appBar: TournaQAppBar(title: l10n.pageTeams),
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
                const Icon(Icons.group_rounded,
                    size: 20, color: AppColors.oliveMedium),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${l10n.pageTeams} ($total)',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                ),
                if (total > 0)
                  TextButton.icon(
                    onPressed: _deleteAllTeams,
                    icon: const Icon(Icons.delete_outline, size: 16),
                    label: const Text('Delete All',
                        style: TextStyle(fontSize: 12)),
                    style: TextButton.styleFrom(
                        foregroundColor: Colors.red.shade400),
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

          // ── Team list ──────────────────────────────────────────────────
          Expanded(
            child: total == 0
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.group_rounded,
                            size: 48, color: Colors.grey.shade300),
                        const SizedBox(height: 12),
                        Text(l10n.noTeamsYet,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                                color: Colors.black45)),
                        const SizedBox(height: 4),
                        const Text('Tap Create Team to get started.',
                            style: TextStyle(
                                color: Colors.black38, fontSize: 13)),
                      ],
                    ),
                  )
                : filtered.isEmpty
                    ? Center(
                        child: Text(l10n.noTeamsFiltered,
                            style:
                                const TextStyle(color: Colors.black45)),
                      )
                    : ListView.builder(
                        padding:
                            const EdgeInsets.fromLTRB(16, 4, 16, 16),
                        itemCount: filtered.length,
                        itemBuilder: (_, i) =>
                            _buildTeamCard(filtered[i], l10n),
                      ),
          ),
        ],
      ),
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
              Icon(Icons.group_rounded, color: Colors.white, size: 22),
              SizedBox(width: 8),
              Text(
                'Teams',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            'Manage your global team pool',
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.90),
                fontSize: 13,
                fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _showCreateSheet,
            icon: const Icon(Icons.add_rounded),
            label: Text(l10n.btnCreateTeam,
                style: const TextStyle(fontWeight: FontWeight.w700)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.gold,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  // ── Team card ──────────────────────────────────────────────────────────────

  Widget _buildTeamCard(Team team, AppLocalizations l10n) {
    final memberCount = _localState.getPlayersForTeam(team.id).length;
    final groupCount  = _localState.groups
        .where((c) => c.teamIds.contains(team.id))
        .length;
    final stats = <String>[
      '$memberCount player${memberCount == 1 ? '' : 's'}',
      if (groupCount > 0) '$groupCount group${groupCount == 1 ? '' : 's'}',
    ];

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => TeamDetailPage(
              appState: _localState,
              onAppStateChanged: _updateState,
              teamId: team.id),
        )),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              // Avatar
              Container(
                width: 42,
                height: 42,
                decoration: const BoxDecoration(
                  color: AppColors.goldCream,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    team.name.isNotEmpty
                        ? team.name[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 17,
                      color: AppColors.goldDark,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            team.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 14),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                    ),
                    if (stats.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        stats.join('  ·  '),
                        style: const TextStyle(
                            fontSize: 12, color: Colors.black54),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 4),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert,
                    size: 18, color: Colors.black38),
                padding: EdgeInsets.zero,
                onSelected: (value) {
                  switch (value) {
                    case 'edit':
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => TeamDetailPage(
                            appState: _localState,
                            onAppStateChanged: _updateState,
                            teamId: team.id),
                      ));
                    case 'assign_group': _assignGroup(team.id);
                    case 'delete': _deleteTeam(team.id);
                  }
                },
                itemBuilder: (_) => [
                  actionMenuItem('edit', Icons.edit_rounded, l10n.menuEditPlayers),
                  actionMenuItem('assign_group', Icons.home_rounded, l10n.menuAssignToClub),
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
