import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../models/player.dart';
import '../models/team.dart';
import '../services/app_data_service.dart';
import '../state/app_state.dart';
import '../widgets/tournaq_app_bar.dart';
import '../widgets/assign_dialog.dart';
import '../widgets/scrollable_page.dart';
import 'group_detail_page.dart';
import 'user_detail_page.dart';

class TeamDetailPage extends StatefulWidget {
  final AppState appState;
  final Function(AppState) onAppStateChanged;
  final String teamId;

  const TeamDetailPage({
    super.key,
    required this.appState,
    required this.onAppStateChanged,
    required this.teamId,
  });

  @override
  State<TeamDetailPage> createState() => _TeamDetailPageState();
}

class _TeamDetailPageState extends State<TeamDetailPage> {
  late AppState _localState;
  late TextEditingController _nameCtrl;

  @override
  void initState() {
    super.initState();
    _localState = widget.appState;
    final team = _localState.getTeamById(widget.teamId);
    _nameCtrl = TextEditingController(text: team?.name ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  void _updateState(AppState newState) {
    setState(() => _localState = newState);
    widget.onAppStateChanged(newState);
  }

  Team? get _team => _localState.getTeamById(widget.teamId);

  void _saveName() {
    final team = _team;
    if (team == null) return;
    final newName = _nameCtrl.text.trim();
    if (newName.isEmpty || newName == team.name) return;
    _updateState(AppDataService.updateTeam(_localState, team.copyWith(name: newName)));
  }

  // ── Player ────────────────────────────────────────────────────────────────

  Future<void> _addPlayer() async {
    final l10n = AppLocalizations.of(context)!;
    final team = _team;
    if (team == null) return;
    final existingIds = Set<String>.from(team.userIds);
    final available = _localState.players
        .where((u) => !existingIds.contains(u.id))
        .map((u) => (id: u.id, name: u.name))
        .toList();
    final selected = await showPlayerPickerSheet(
      context: context,
      title: l10n.menuAddPlayer,
      players: available,
      groups: _localState.groups,
      onCreatePlayer: (name) {
        final player = Player(id: AppState.generateId(), name: name);
        setState(() => _localState = _localState.addPlayer(player));
        return player.id;
      },
    );
    if (selected != null && mounted) {
      _updateState(AppDataService.assignUserToTeam(
          _localState, userId: selected, teamId: widget.teamId));
    }
  }

  Future<void> _removePlayer(String userId) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.dialogRemovePlayer),
        content: Text(l10n.dialogRemovePlayerBody),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text(l10n.btnCancel)),
          ElevatedButton(onPressed: () => Navigator.of(ctx).pop(true), child: Text(l10n.btnRemove)),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      _updateState(AppDataService.removeUserFromTeam(_localState, userId: userId, teamId: widget.teamId));
    }
  }

  // ── Group ───────────────────────────────────────────────────────────────────

  Future<void> _assignGroup() async {
    final l10n = AppLocalizations.of(context)!;
    final items = _localState.groups
        .where((c) => !c.teamIds.contains(widget.teamId))
        .map((c) => (id: c.id, name: c.name))
        .toList();
    final selected = await showAssignDialog(
      context: context, title: l10n.menuAssignToClub, items: items,
      emptyMessage: 'Team is already in all groups.',
    );
    if (selected != null && mounted) {
      _updateState(AppDataService.assignTeamToGroup(_localState, teamId: widget.teamId, groupId: selected));
    }
  }

  Future<void> _removeFromGroup(String groupId) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.dialogRemoveFromClub),
        content: Text(l10n.dialogRemoveFromClubBody),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text(l10n.btnCancel)),
          ElevatedButton(onPressed: () => Navigator.of(ctx).pop(true), child: Text(l10n.btnRemove)),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      _updateState(AppDataService.removeTeamFromGroup(_localState, teamId: widget.teamId, groupId: groupId));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final team = _team;
    if (team == null) {
      return Scaffold(
        appBar: TournaQAppBar(title: l10n.pageTeamDetails),
        body: Center(child: Text(l10n.teamNotFound)),
      );
    }

    final teamUsers = _localState.getPlayersForTeam(team.id);
    final teamGroups = _localState.getTeamGroups(team.id);

    return Scaffold(
      appBar: TournaQAppBar(title: l10n.pageTeamDetails),
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
                    const SizedBox(height: 16),
                    Wrap(spacing: 10, runSpacing: 8, children: [
                      ElevatedButton.icon(
                        onPressed: _addPlayer,
                        icon: const Icon(Icons.person_add_rounded, size: 16),
                        label: Text(l10n.menuAddPlayer),
                      ),
                      ElevatedButton.icon(
                        onPressed: _assignGroup,
                        icon: const Icon(Icons.home_rounded, size: 16),
                        label: Text(l10n.menuAddToClub),
                      ),
                    ]),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            Text(l10n.sectionPlayersCount(teamUsers.length), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            if (teamUsers.isEmpty)
              Center(child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(l10n.noPlayersInTeam, style: const TextStyle(color: Colors.black45)),
              ))
            else
              ...teamUsers.map((user) => Card(
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: ListTile(
                  leading: const Icon(Icons.person_rounded),
                  title: Text(user.name),
                  subtitle: Text(user.email ?? ''),
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => UserDetailPage(appState: _localState, onAppStateChanged: _updateState, userId: user.id),
                  )),
                  trailing: IconButton(
                    icon: const Icon(Icons.remove_circle_outline),
                    onPressed: () => _removePlayer(user.id),
                  ),
                ),
              )),

            const SizedBox(height: 20),

            Text(l10n.sectionClubsCount(teamGroups.length), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            if (teamGroups.isEmpty)
              Center(child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(l10n.noClubsInTeam, style: const TextStyle(color: Colors.black45)),
              ))
            else
              ...teamGroups.map((group) => Card(
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: ListTile(
                  leading: const Icon(Icons.home_rounded),
                  title: Text(group.name),
                  subtitle: Text('${group.playerIds.length} player(s) • ${group.tournamentIds.length} tournament(s)'),
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

