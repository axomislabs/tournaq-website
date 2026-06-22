import 'package:flutter/material.dart';
import '../app/app_colors.dart';
import '../l10n/app_localizations.dart';
import '../models/player.dart';
import '../services/app_data_service.dart';
import '../services/doghouse_storage_service.dart';
import '../services/king_of_the_court_storage_service.dart';
import '../services/ko_bracket_storage_service.dart';
import '../services/scramble_storage_service.dart';
import '../state/app_state.dart';
import '../widgets/tournaq_app_bar.dart';
import '../widgets/assign_dialog.dart';
import '../widgets/create_player_sheet.dart';
import 'user_detail_page.dart';

enum _SearchMode { name, team, tournament }

class UsersPage extends StatefulWidget {
  final AppState appState;
  final Function(AppState) onAppStateChanged;
  const UsersPage({super.key, required this.appState, required this.onAppStateChanged});
  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  late AppState _localState;
  final _searchCtrl = TextEditingController();
  _SearchMode _searchMode = _SearchMode.name;
  Map<String, int> _tournamentCountByPlayer = {};
  // tournamentName → set of appUserIds who participated
  Map<String, Set<String>> _playersByTournamentName = {};

  @override
  void initState() {
    super.initState();
    _localState = widget.appState;
    _searchCtrl.addListener(() => setState(() {}));
    _loadTournamentCounts();
  }

  void _loadTournamentCounts() {
    final counts  = <String, int>{};
    final byName  = <String, Set<String>>{};

    void add(String? playerId, String tournamentName) {
      if (playerId == null) return;
      counts[playerId] = (counts[playerId] ?? 0) + 1;
      (byName[tournamentName] ??= {}).add(playerId);
    }

    for (final t in ScrambleStorageService.loadAll()) {
      for (final p in t.players) { add(p.appUserId, t.name); }
    }
    for (final t in KingOfTheCourtStorageService.loadAll()) {
      for (final p in t.players) { add(p.appUserId, t.name); }
    }
    for (final t in DoghouseStorageService.loadAll()) {
      for (final p in t.players) { add(p.appUserId, t.name); }
    }
    for (final t in KoBracketStorageService.loadAll()) {
      for (final team in t.teams) {
        for (final p in team.players) { add(p.appPlayerId.isEmpty ? null : p.appPlayerId, t.name); }
      }
    }

    setState(() {
      _tournamentCountByPlayer   = counts;
      _playersByTournamentName   = byName;
    });
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
      builder: (_) => CreatePlayerSheet(appState: _localState),
    );
    if (result != null && mounted) _updateState(result);
  }

  // ── Actions ────────────────────────────────────────────────────────────────

  Future<void> _assignTeam(String userId) async {
    final user = _localState.getPlayerById(userId);
    if (user == null) return;
    final items = _localState.teams
        .where((t) => !user.teamIds.contains(t.id))
        .map((t) => (id: t.id, name: t.name))
        .toList();
    final selected = await showAssignDialog(
      context: context, title: 'Assign to Team', items: items,
      emptyMessage: 'Player is already in all teams.',
    );
    if (selected != null && mounted) {
      _updateState(AppDataService.assignUserToTeam(_localState, userId: userId, teamId: selected));
    }
  }

  Future<void> _assignGroup(String userId) async {
    final items = _localState.groups
        .where((c) => !c.playerIds.contains(userId))
        .map((c) => (id: c.id, name: c.name))
        .toList();
    final selected = await showAssignDialog(
      context: context, title: 'Assign to Group', items: items,
      emptyMessage: 'Player is already in all groups.',
    );
    if (selected != null && mounted) {
      _updateState(AppDataService.assignPlayerToGroup(_localState, playerId: userId, groupId: selected));
    }
  }

  Future<void> _deletePlayer(String userId) async {
    final user = _localState.getPlayerById(userId);
    if (user == null) return;
    final ok = await showConfirmDeleteDialog(context, user.name);
    if (ok && mounted) _updateState(AppDataService.deleteUser(_localState, userId));
  }

  Future<void> _deleteAllPlayers() async {
    final count = _localState.players.length;
    if (count == 0) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete All Players',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        content: Text(
          'This removes all $count players from your player pool.\n\n'
          'Existing tournaments and game history are not affected — '
          'those keep their own player records. To remove players from '
          'a tournament, delete the tournament itself.\n\n'
          'Players will also be removed from any teams they belong to.',
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
            ),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    var state = _localState;
    for (final player in List.from(state.players)) {
      state = AppDataService.deleteUser(state, player.id);
    }
    _updateState(state);
  }

  List<Player> get _filteredPlayers {
    final q = _searchCtrl.text.toLowerCase().trim();
    if (q.isEmpty) return _localState.players;

    switch (_searchMode) {
      case _SearchMode.name:
        return _localState.players
            .where((p) => p.name.toLowerCase().contains(q))
            .toList();

      case _SearchMode.team:
        final matchingTeamIds = _localState.teams
            .where((t) => t.name.toLowerCase().contains(q))
            .map((t) => t.id)
            .toSet();
        return _localState.players
            .where((p) => p.teamIds.any(matchingTeamIds.contains))
            .toList();

      case _SearchMode.tournament:
        final matchingPlayerIds = _playersByTournamentName.entries
            .where((e) => e.key.toLowerCase().contains(q))
            .expand((e) => e.value)
            .toSet();
        return _localState.players
            .where((p) => matchingPlayerIds.contains(p.id))
            .toList();
    }
  }

  // ── Search bar ────────────────────────────────────────────────────────────

  static const _modeLabels = {
    _SearchMode.name:       'Name',
    _SearchMode.team:       'Team',
    _SearchMode.tournament: 'Tournament',
  };

  static const _modeHints = {
    _SearchMode.name:       'Search players…',
    _SearchMode.team:       'Search by team…',
    _SearchMode.tournament: 'Search by tournament…',
  };

  Widget _buildSearchBar(AppLocalizations l10n) {
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
          children: _SearchMode.values.map((m) {
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

  IconData _modeIcon(_SearchMode mode) => switch (mode) {
        _SearchMode.name       => Icons.person_rounded,
        _SearchMode.team       => Icons.group_rounded,
        _SearchMode.tournament => Icons.emoji_events_rounded,
      };

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final total = _localState.players.length;
    final filtered = _filteredPlayers;

    return Scaffold(
      appBar: TournaQAppBar(title: l10n.pagePlayers),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Start card ─────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: _buildStartCard(l10n),
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
                    '${l10n.pagePlayers} ($total)',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                ),
                if (total > 0)
                  TextButton.icon(
                    onPressed: _deleteAllPlayers,
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
            child: _buildSearchBar(l10n),
          ),
          const SizedBox(height: 8),

          // ── Player list ────────────────────────────────────────────────
          Expanded(
            child: total == 0
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.people_rounded,
                            size: 48, color: Colors.grey.shade300),
                        const SizedBox(height: 12),
                        Text(l10n.noPlayersYet,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                                color: Colors.black45)),
                        const SizedBox(height: 4),
                        const Text('Tap Add Player to get started.',
                            style: TextStyle(
                                color: Colors.black38, fontSize: 13)),
                      ],
                    ),
                  )
                : filtered.isEmpty
                    ? Center(
                        child: Text(l10n.noPlayersFiltered,
                            style: const TextStyle(color: Colors.black45)),
                      )
                    : ListView.builder(
                        padding:
                            const EdgeInsets.fromLTRB(16, 4, 16, 16),
                        itemCount: filtered.length,
                        itemBuilder: (_, i) =>
                            _buildPlayerCard(filtered[i], l10n),
                      ),
          ),
        ],
      ),
    );
  }

  // ── Start card ─────────────────────────────────────────────────────────────

  Widget _buildStartCard(AppLocalizations l10n) {
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
              Icon(Icons.people_rounded, color: Colors.white, size: 22),
              SizedBox(width: 8),
              Text(
                'Players',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            'Manage your global player pool',
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.90),
                fontSize: 13,
                fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: _showCreateSheet,
                icon: const Icon(Icons.add_rounded),
                label: Text(l10n.btnCreatePlayer,
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
        ],
      ),
    );
  }

  // ── Player card ────────────────────────────────────────────────────────────

  Widget _buildPlayerCard(Player player, AppLocalizations l10n) {
    final groupCount = _localState.groups
        .where((c) => c.playerIds.contains(player.id))
        .length;
    final tournamentCount = _tournamentCountByPlayer[player.id] ?? 0;
    final stats = <String>[
      '${player.teamIds.length} team(s)',
      if (groupCount > 0) '$groupCount group(s)',
      if (tournamentCount > 0) '$tournamentCount tournament(s)',
    ];
    final skill = player.skillRating;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => UserDetailPage(
              appState: _localState,
              onAppStateChanged: _updateState,
              userId: player.id),
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
                  color: AppColors.oliveLight,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    player.name.isNotEmpty
                        ? player.name[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 17,
                      color: AppColors.olive,
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
                            player.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 14),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (skill != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.goldCream,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Skill $skill',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: AppColors.goldDark,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (stats.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        stats.join('  ·  '),
                        style: const TextStyle(
                            fontSize: 12, color: Colors.black54),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
                    case 'assign_team': _assignTeam(player.id);
                    case 'assign_group': _assignGroup(player.id);
                    case 'delete': _deletePlayer(player.id);
                  }
                },
                itemBuilder: (_) => [
                  actionMenuItem('assign_team', Icons.group_rounded,
                      l10n.menuAssignToTeam),
                  actionMenuItem('assign_group', Icons.home_rounded,
                      l10n.menuAssignToClub),
                  const PopupMenuDivider(),
                  actionMenuItem('delete', Icons.delete_outline,
                      l10n.btnDelete, destructive: true),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
