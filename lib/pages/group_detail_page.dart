import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../models/club.dart';
import '../services/app_data_service.dart';
import '../state/app_state.dart';
import '../widgets/app_drawer.dart';
import '../widgets/tournaq_app_bar.dart';
import '../widgets/assign_dialog.dart';
import '../widgets/scrollable_page.dart';
import 'team_detail_page.dart';
import 'user_detail_page.dart';

class ClubDetailPage extends StatefulWidget {
  final AppState appState;
  final Function(AppState) onAppStateChanged;
  final String clubId;

  const ClubDetailPage({
    super.key,
    required this.appState,
    required this.onAppStateChanged,
    required this.clubId,
  });

  @override
  State<ClubDetailPage> createState() => _ClubDetailPageState();
}

class _ClubDetailPageState extends State<ClubDetailPage> {
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

  Club? get _club => _localState.getClubById(widget.clubId);

  // ── Players ──────────────────────────────────────────────────────────────

  Future<void> _assignPlayer() async {
    final l10n = AppLocalizations.of(context)!;
    final club = _club;
    if (club == null) return;
    final items = _localState.players
        .where((u) => !club.playerIds.contains(u.id))
        .map((u) => (id: u.id, name: u.name))
        .toList();
    final selected = await showAssignDialog(
      context: context, title: l10n.menuAddPlayer, items: items,
      emptyMessage: 'All players are already in this club.',
    );
    if (selected != null && mounted) {
      _updateState(AppDataService.assignPlayerToClub(_localState, playerId: selected, clubId: widget.clubId));
    }
  }

  Future<void> _removePlayer(String playerId) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.dialogRemovePlayer),
        content: Text(l10n.dialogRemovePlayerFromClubBody),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text(l10n.btnCancel)),
          ElevatedButton(onPressed: () => Navigator.of(ctx).pop(true), child: Text(l10n.btnRemove)),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      _updateState(AppDataService.removePlayerFromClub(_localState, playerId: playerId, clubId: widget.clubId));
    }
  }

  // ── Teams ─────────────────────────────────────────────────────────────────

  Future<void> _assignTeam() async {
    final l10n = AppLocalizations.of(context)!;
    final club = _club;
    if (club == null) return;
    final items = _localState.teams
        .where((t) => !club.teamIds.contains(t.id))
        .map((t) => (id: t.id, name: t.name))
        .toList();
    final selected = await showAssignDialog(
      context: context, title: l10n.menuAddTeam, items: items,
      emptyMessage: 'All teams are already in this club.',
    );
    if (selected != null && mounted) {
      _updateState(AppDataService.assignTeamToClub(_localState, teamId: selected, clubId: widget.clubId));
    }
  }

  Future<void> _removeTeam(String teamId) async {
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
      _updateState(AppDataService.removeTeamFromClub(_localState, teamId: teamId, clubId: widget.clubId));
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final club = _club;
    if (club == null) {
      return Scaffold(
        appBar: TournaQAppBar(title: l10n.pageClubDetails),
        body: Center(child: Text(l10n.clubNotFound)),
      );
    }

    final players = _localState.players.where((u) => club.playerIds.contains(u.id)).toList();
    final teams = _localState.teams.where((t) => club.teamIds.contains(t.id)).toList();

    return Scaffold(
      drawer: AppDrawer(appState: _localState, onAppStateChanged: _updateState),
      appBar: TournaQAppBar(title: l10n.pageClubDetails),
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
                    Text(club.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    Wrap(spacing: 12, runSpacing: 8, children: [
                      ElevatedButton.icon(
                        onPressed: _assignPlayer,
                        icon: const Icon(Icons.person_rounded, size: 16),
                        label: Text(l10n.menuAddPlayer),
                      ),
                      ElevatedButton.icon(
                        onPressed: _assignTeam,
                        icon: const Icon(Icons.group_rounded, size: 16),
                        label: Text(l10n.menuAddTeam),
                      ),
                    ]),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            Text(l10n.sectionPlayersCount(players.length), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            if (players.isEmpty)
              Center(child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(l10n.noPlayersInTeam, style: const TextStyle(color: Colors.black45)),
              ))
            else
              ...players.map((u) => Card(
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: ListTile(
                  leading: const Icon(Icons.person_rounded),
                  title: Text(u.name),
                  subtitle: Text(u.email ?? ''),
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => UserDetailPage(appState: _localState, onAppStateChanged: _updateState, userId: u.id),
                  )),
                  trailing: IconButton(
                    icon: const Icon(Icons.remove_circle_outline),
                    onPressed: () => _removePlayer(u.id),
                  ),
                ),
              )),

            const SizedBox(height: 20),

            Text(l10n.sectionTeamsCount(teams.length), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            if (teams.isEmpty)
              Center(child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(l10n.noTeamsYet, style: const TextStyle(color: Colors.black45)),
              ))
            else
              ...teams.map((t) => Card(
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: ListTile(
                  leading: const Icon(Icons.group_rounded),
                  title: Text(t.name),
                  subtitle: Text(t.scope.name),
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => TeamDetailPage(appState: _localState, onAppStateChanged: _updateState, teamId: t.id),
                  )),
                  trailing: IconButton(
                    icon: const Icon(Icons.remove_circle_outline),
                    onPressed: () => _removeTeam(t.id),
                  ),
                ),
              )),

          ],
        ),
      ),
    );
  }
}
