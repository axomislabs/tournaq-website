import 'package:flutter/material.dart';
import '../app/app_colors.dart';
import '../l10n/app_localizations.dart';
import '../models/player.dart';
import '../services/app_data_service.dart';
import '../services/doghouse_storage_service.dart';
import '../services/king_of_the_court_storage_service.dart';
import '../services/local_storage_service.dart';
import '../services/scramble_storage_service.dart';
import '../state/app_state.dart';
import '../widgets/tournaq_app_bar.dart';
import '../widgets/assign_dialog.dart';
import '../widgets/scrollable_page.dart';
import 'group_detail_page.dart';
import 'doghouse_scoreboard_page.dart';
import 'king_of_the_court_scoreboard_page.dart';
import 'scramble_overview_page.dart';
import 'team_detail_page.dart';

class UserDetailPage extends StatefulWidget {
  final AppState appState;
  final Function(AppState) onAppStateChanged;
  final String userId;

  const UserDetailPage({
    super.key,
    required this.appState,
    required this.onAppStateChanged,
    required this.userId,
  });

  @override
  State<UserDetailPage> createState() => _UserDetailPageState();
}

typedef _TournamentEntry = ({
  String id,
  String name,
  String tournamentType, // 'scramble' | 'kotc' | 'doghouse'
});

class _UserDetailPageState extends State<UserDetailPage> {
  late AppState _localState;
  late TextEditingController _nameCtrl;
  List<_TournamentEntry> _playerTournaments = [];

  @override
  void initState() {
    super.initState();
    _localState = widget.appState;
    final player = _localState.getPlayerById(widget.userId);
    _nameCtrl = TextEditingController(text: player?.name ?? '');
    _loadTournaments();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  void _loadTournaments() {
    final id = widget.userId;
    final results = <({_TournamentEntry entry, DateTime date})>[];

    for (final t in ScrambleStorageService.loadAll()) {
      if (t.players.any((p) => p.appUserId == id)) {
        results.add((
          entry: (id: t.id, name: t.name, tournamentType: 'scramble'),
          date: t.startTime,
        ));
      }
    }
    for (final t in KingOfTheCourtStorageService.loadAll()) {
      if (t.players.any((p) => p.appUserId == id)) {
        results.add((
          entry: (id: t.id, name: t.name, tournamentType: 'kotc'),
          date: t.createdAt,
        ));
      }
    }
    for (final t in DoghouseStorageService.loadAll()) {
      if (t.players.any((p) => p.appUserId == id)) {
        results.add((
          entry: (id: t.id, name: t.name, tournamentType: 'doghouse'),
          date: t.createdAt,
        ));
      }
    }

    results.sort((a, b) => b.date.compareTo(a.date));
    setState(() => _playerTournaments = results.map((r) => r.entry).toList());
  }

  void _updateState(AppState newState) {
    setState(() => _localState = newState);
    widget.onAppStateChanged(newState);
  }

  Player? get _user => _localState.getPlayerById(widget.userId);

  // ── Team ─────────────────────────────────────────────────────────────────

  Future<void> _assignTeam() async {
    final l10n = AppLocalizations.of(context)!;
    final user = _user;
    if (user == null) return;
    final items = _localState.teams
        .where((t) => !user.teamIds.contains(t.id))
        .map((t) => (id: t.id, name: t.name))
        .toList();
    final selected = await showAssignDialog(
      context: context, title: l10n.menuAssignToTeam, items: items,
      emptyMessage: 'Player is already in all teams.',
    );
    if (selected != null && mounted) {
      _updateState(AppDataService.assignUserToTeam(_localState, userId: widget.userId, teamId: selected));
    }
  }

  Future<void> _removeFromTeam(String teamId) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.dialogRemoveFromTeam),
        content: Text(l10n.dialogRemoveFromTeamBody),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text(l10n.btnCancel)),
          ElevatedButton(onPressed: () => Navigator.of(ctx).pop(true), child: Text(l10n.btnRemove)),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      _updateState(AppDataService.removeUserFromTeam(_localState, userId: widget.userId, teamId: teamId));
    }
  }

  // ── Group ───────────────────────────────────────────────────────────────────

  Future<void> _assignGroup() async {
    final l10n = AppLocalizations.of(context)!;
    final items = _localState.groups
        .where((c) => !c.playerIds.contains(widget.userId))
        .map((c) => (id: c.id, name: c.name))
        .toList();
    final selected = await showAssignDialog(
      context: context, title: l10n.menuAssignToClub, items: items,
      emptyMessage: 'Player is already in all groups.',
    );
    if (selected != null && mounted) {
      _updateState(AppDataService.assignPlayerToGroup(_localState, playerId: widget.userId, groupId: selected));
    }
  }

  Future<void> _saveName() async {
    final user = _user;
    if (user == null) return;
    final newName = _nameCtrl.text.trim();
    if (newName.isEmpty || newName == user.name) return;
    final updated = user.copyWith(name: newName);
    await LocalStorageService.savePlayer(updated);
    if (mounted) _updateState(_localState.updatePlayer(updated));
  }

  Future<void> _removeFromGroup(String groupId) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.dialogRemoveFromClub),
        content: Text(l10n.dialogRemovePlayerFromClubBody),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text(l10n.btnCancel)),
          ElevatedButton(onPressed: () => Navigator.of(ctx).pop(true), child: Text(l10n.btnRemove)),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      _updateState(AppDataService.removePlayerFromGroup(_localState, playerId: widget.userId, groupId: groupId));
    }
  }

  void _openTournament(_TournamentEntry t) {
    switch (t.tournamentType) {
      case 'scramble':
        final tournament = ScrambleStorageService.loadAll()
            .where((s) => s.id == t.id)
            .firstOrNull;
        if (tournament == null || !mounted) return;
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => ScrambleOverviewPage(
            tournament: tournament,
            onChanged: ScrambleStorageService.save,
          ),
        ));
      case 'kotc':
        final tournament = KingOfTheCourtStorageService.loadAll()
            .where((s) => s.id == t.id)
            .firstOrNull;
        if (tournament == null || !mounted) return;
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => KingOfTheCourtScoreboardPage(
            tournament: tournament,
            existingPlayers: _localState.players,
            onChanged: KingOfTheCourtStorageService.save,
          ),
        ));
      case 'doghouse':
        final tournament = DoghouseStorageService.loadAll()
            .where((s) => s.id == t.id)
            .firstOrNull;
        if (tournament == null || !mounted) return;
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => DoghouseScoreboardPage(
            tournament: tournament,
            existingPlayers: _localState.players,
            onChanged: DoghouseStorageService.save,
          ),
        ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final user = _user;
    if (user == null) {
      return Scaffold(
        appBar: TournaQAppBar(title: l10n.pagePlayerDetails),
        body: Center(child: Text(l10n.playerNotFound)),
      );
    }

    final userTeams = _localState.getTeamsByIds(user.teamIds);
    final userGroups = _localState.getPlayerGroups(user.id);

    return Scaffold(
      appBar: TournaQAppBar(title: l10n.pagePlayerDetails),
      body: ScrollablePage(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              color: Theme.of(context).colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _nameCtrl,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      onEditingComplete: _saveName,
                      onTapOutside: (_) {
                        FocusScope.of(context).unfocus();
                        _saveName();
                      },
                    ),
                    if (user.email != null) ...[
                      const SizedBox(height: 6),
                      Text(l10n.userEmailLabel(user.email!), style: const TextStyle(color: Colors.black54)),
                    ],
                    if (user.role != null) ...[
                      const SizedBox(height: 4),
                      Text(l10n.userRoleLabel(user.role!), style: const TextStyle(color: Colors.black54)),
                    ],
                    const SizedBox(height: 16),
                    Wrap(spacing: 10, runSpacing: 8, children: [
                      ElevatedButton.icon(
                        onPressed: _assignTeam,
                        icon: const Icon(Icons.group_rounded, size: 16),
                        label: Text(l10n.menuAssignToTeam),
                      ),
                      ElevatedButton.icon(
                        onPressed: _assignGroup,
                        icon: const Icon(Icons.home_rounded, size: 16),
                        label: Text(l10n.menuAssignToClub),
                      ),
                    ]),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            Text(l10n.sectionTeamsCount(userTeams.length), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            if (userTeams.isEmpty)
              Center(child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(l10n.notAssignedToTeams, style: const TextStyle(color: Colors.black45)),
              ))
            else
              ...userTeams.map((team) => Card(
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: ListTile(
                  leading: const Icon(Icons.group_rounded),
                  title: Text(team.name),
                  subtitle: null,
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => TeamDetailPage(appState: _localState, onAppStateChanged: _updateState, teamId: team.id),
                  )),
                  trailing: IconButton(
                    icon: const Icon(Icons.remove_circle_outline),
                    onPressed: () => _removeFromTeam(team.id),
                  ),
                ),
              )),

            const SizedBox(height: 20),

            Text(
              'Tournaments (${_playerTournaments.length})',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (_playerTournaments.isEmpty)
              Center(child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Not participating in any tournaments', style: const TextStyle(color: Colors.black45)),
              ))
            else
              ..._playerTournaments.map((t) => Card(
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: ListTile(
                  leading: const Icon(Icons.emoji_events_rounded, color: AppColors.gold),
                  title: Text(t.name),
                  trailing: const Icon(Icons.chevron_right_rounded, color: Colors.black38),
                  onTap: () => _openTournament(t),
                ),
              )),

            const SizedBox(height: 20),

            Text(l10n.sectionClubsCount(userGroups.length), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            if (userGroups.isEmpty)
              Center(child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(l10n.notAssignedToClubs, style: const TextStyle(color: Colors.black45)),
              ))
            else
              ...userGroups.map((group) => Card(
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: ListTile(
                  leading: const Icon(Icons.home_rounded),
                  title: Text(group.name),
                  subtitle: Text('${group.playerIds.length} player(s) • ${group.teamIds.length} team(s)'),
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => GroupDetailPage(appState: _localState, onAppStateChanged: _updateState, groupId: group.id),
                  )),
                  trailing: IconButton(
                    icon: const Icon(Icons.remove_circle_outline),
                    onPressed: () => _removeFromGroup(group.id),
                  ),
                ),
              )),
          ],
        ),
      ),
    );
  }
}
