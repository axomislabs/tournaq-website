import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../models/app_user.dart';
import '../services/app_data_service.dart';
import '../state/app_state.dart';
import '../widgets/app_drawer.dart';
import '../widgets/tournaq_app_bar.dart';
import '../widgets/assign_dialog.dart';
import '../widgets/scrollable_page.dart';
import 'club_detail_page.dart';
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

class _UserDetailPageState extends State<UserDetailPage> {
  late AppState _localState;

  @override
  void initState() {
    super.initState();
    _localState = widget.appState;
  }

  void _updateState(AppState newState) {
    setState(() => _localState = newState);
    widget.onAppStateChanged(newState);
  }

  AppUser? get _user => _localState.getUserById(widget.userId);

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

  // ── Club ──────────────────────────────────────────────────────────────────

  Future<void> _assignClub() async {
    final l10n = AppLocalizations.of(context)!;
    final items = _localState.clubs
        .where((c) => !c.playerIds.contains(widget.userId))
        .map((c) => (id: c.id, name: c.name))
        .toList();
    final selected = await showAssignDialog(
      context: context, title: l10n.menuAssignToClub, items: items,
      emptyMessage: 'Player is already in all clubs.',
    );
    if (selected != null && mounted) {
      _updateState(AppDataService.assignPlayerToClub(_localState, playerId: widget.userId, clubId: selected));
    }
  }

  Future<void> _removeFromClub(String clubId) async {
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
      _updateState(AppDataService.removePlayerFromClub(_localState, playerId: widget.userId, clubId: clubId));
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
    final userClubs = _localState.getPlayerClubs(user.id);

    return Scaffold(
      drawer: AppDrawer(appState: _localState, onAppStateChanged: _updateState),
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
                    Text(user.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
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
                        onPressed: _assignClub,
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
                  subtitle: Text(team.scope.name),
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

            Text(l10n.sectionClubsCount(userClubs.length), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            if (userClubs.isEmpty)
              Center(child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(l10n.notAssignedToClubs, style: const TextStyle(color: Colors.black45)),
              ))
            else
              ...userClubs.map((club) => Card(
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: ListTile(
                  leading: const Icon(Icons.home_rounded),
                  title: Text(club.name),
                  subtitle: Text('${club.playerIds.length} player(s) • ${club.teamIds.length} team(s)'),
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => ClubDetailPage(appState: _localState, onAppStateChanged: _updateState, clubId: club.id),
                  )),
                  trailing: IconButton(
                    icon: const Icon(Icons.remove_circle_outline),
                    onPressed: () => _removeFromClub(club.id),
                  ),
                ),
              )),
          ],
        ),
      ),
    );
  }
}
