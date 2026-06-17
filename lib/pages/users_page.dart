import 'package:flutter/material.dart';
import '../app/app_colors.dart';
import '../l10n/app_localizations.dart';
import '../models/player.dart';
import '../services/app_data_service.dart';
import '../services/doghouse_storage_service.dart';
import '../services/king_of_the_court_storage_service.dart';
import '../services/scramble_storage_service.dart';
import '../state/app_state.dart';
import '../widgets/tournaq_app_bar.dart';
import '../widgets/assign_dialog.dart';
import '../widgets/create_player_sheet.dart';
import 'user_detail_page.dart';

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
  Map<String, int> _tournamentCountByPlayer = {};

  @override
  void initState() {
    super.initState();
    _localState = widget.appState;
    _searchCtrl.addListener(() => setState(() {}));
    _loadTournamentCounts();
  }

  void _loadTournamentCounts() {
    final counts = <String, int>{};
    void increment(String? id) {
      if (id == null) return;
      counts[id] = (counts[id] ?? 0) + 1;
    }
    for (final t in ScrambleStorageService.loadAll()) {
      for (final p in t.players) { increment(p.appUserId); }
    }
    for (final t in KingOfTheCourtStorageService.loadAll()) {
      for (final p in t.players) { increment(p.appUserId); }
    }
    for (final t in DoghouseStorageService.loadAll()) {
      for (final p in t.players) { increment(p.appUserId); }
    }
    _tournamentCountByPlayer = counts;
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

  Future<void> _assignClub(String userId) async {
    final items = _localState.clubs
        .where((c) => !c.playerIds.contains(userId))
        .map((c) => (id: c.id, name: c.name))
        .toList();
    final selected = await showAssignDialog(
      context: context, title: 'Assign to Club', items: items,
      emptyMessage: 'Player is already in all clubs.',
    );
    if (selected != null && mounted) {
      _updateState(AppDataService.assignPlayerToClub(_localState, playerId: userId, clubId: selected));
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
    final q = _searchCtrl.text.toLowerCase();
    if (q.isEmpty) return _localState.players;
    return _localState.players
        .where((p) => p.name.toLowerCase().contains(q))
        .toList();
  }

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
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: l10n.hintSearchPlayers,
                prefixIcon: const Icon(Icons.search_rounded,
                    size: 18, color: Colors.black45),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
                isDense: true,
              ),
            ),
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
    final clubCount = _localState.clubs
        .where((c) => c.playerIds.contains(player.id))
        .length;
    final tournamentCount = _tournamentCountByPlayer[player.id] ?? 0;
    final stats = <String>[
      '${player.teamIds.length} team(s)',
      if (clubCount > 0) '$clubCount club(s)',
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
                    case 'assign_club': _assignClub(player.id);
                    case 'delete': _deletePlayer(player.id);
                  }
                },
                itemBuilder: (_) => [
                  actionMenuItem('assign_team', Icons.group_rounded,
                      l10n.menuAssignToTeam),
                  actionMenuItem('assign_club', Icons.home_rounded,
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
