import 'package:flutter/material.dart';
import '../app/app_colors.dart';
import '../l10n/app_localizations.dart';
import '../models/team.dart';
import '../services/app_data_service.dart';
import '../state/app_state.dart';
import '../widgets/app_drawer.dart';
import '../widgets/tournaq_app_bar.dart';
import '../widgets/assign_dialog.dart';
import '../widgets/scrollable_page.dart';
import '../widgets/sheet_helpers.dart';
import 'club_detail_page.dart';
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

  @override
  void initState() {
    super.initState();
    _localState = widget.appState;
  }

  void _updateState(AppState newState) {
    setState(() => _localState = newState);
    widget.onAppStateChanged(newState);
  }

  Team? get _team => _localState.getTeamById(widget.teamId);

  // ── Player ────────────────────────────────────────────────────────────────

  Future<void> _editPlayers() async {
    final team = _team;
    if (team == null) return;
    final users = _localState.getPlayersForTeam(team.id);
    final p1Name = users.isNotEmpty ? users[0].name : 'Player 1 ${team.name}';
    final p2Name = users.length > 1 ? users[1].name : 'Player 2 ${team.name}';

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditPlayersSheet(
        teamName: team.name,
        initialP1: p1Name,
        initialP2: p2Name,
        onSave: (p1, p2) {
          final ns = AppDataService.updateTeamPlayers(
            _localState,
            teamId: widget.teamId,
            player1Name: p1,
            player2Name: p2,
          );
          _updateState(ns);
        },
      ),
    );
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

  // ── Club ──────────────────────────────────────────────────────────────────

  Future<void> _assignClub() async {
    final l10n = AppLocalizations.of(context)!;
    final items = _localState.clubs
        .where((c) => !c.teamIds.contains(widget.teamId))
        .map((c) => (id: c.id, name: c.name))
        .toList();
    final selected = await showAssignDialog(
      context: context, title: l10n.menuAssignToClub, items: items,
      emptyMessage: 'Team is already in all clubs.',
    );
    if (selected != null && mounted) {
      _updateState(AppDataService.assignTeamToClub(_localState, teamId: widget.teamId, clubId: selected));
    }
  }

  Future<void> _removeFromClub(String clubId) async {
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
      _updateState(AppDataService.removeTeamFromClub(_localState, teamId: widget.teamId, clubId: clubId));
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
    final teamClubs = _localState.getTeamClubs(team.id);

    return Scaffold(
      drawer: AppDrawer(appState: _localState, onAppStateChanged: _updateState),
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
                    Text(team.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(l10n.teamScopeLabel(team.scope.name), style: const TextStyle(color: Colors.black54)),
                    const SizedBox(height: 16),
                    Wrap(spacing: 10, runSpacing: 8, children: [
                      ElevatedButton.icon(
                        onPressed: _editPlayers,
                        icon: const Icon(Icons.edit_rounded, size: 16),
                        label: Text(l10n.menuEditPlayers),
                      ),
                      ElevatedButton.icon(
                        onPressed: _assignClub,
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

            Text(l10n.sectionClubsCount(teamClubs.length), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            if (teamClubs.isEmpty)
              Center(child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(l10n.noClubsInTeam, style: const TextStyle(color: Colors.black45)),
              ))
            else
              ...teamClubs.map((club) => Card(
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: ListTile(
                  leading: const Icon(Icons.home_rounded),
                  title: Text(club.name),
                  subtitle: Text('${club.playerIds.length} player(s) • ${club.tournamentIds.length} tournament(s)'),
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

class _EditPlayersSheet extends StatefulWidget {
  final String teamName;
  final String initialP1;
  final String initialP2;
  final void Function(String p1, String p2) onSave;

  const _EditPlayersSheet({
    required this.teamName,
    required this.initialP1,
    required this.initialP2,
    required this.onSave,
  });

  @override
  State<_EditPlayersSheet> createState() => _EditPlayersSheetState();
}

class _EditPlayersSheetState extends State<_EditPlayersSheet> {
  late final TextEditingController _p1;
  late final TextEditingController _p2;

  @override
  void initState() {
    super.initState();
    _p1 = TextEditingController(text: widget.initialP1);
    _p2 = TextEditingController(text: widget.initialP2);
  }

  @override
  void dispose() {
    _p1.dispose();
    _p2.dispose();
    super.dispose();
  }

  void _save(BuildContext context) {
    final n1 = _p1.text.trim().isEmpty ? widget.initialP1 : _p1.text.trim();
    final n2 = _p2.text.trim().isEmpty ? widget.initialP2 : _p2.text.trim();
    widget.onSave(n1, n2);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return OrientationBuilder(
      builder: (context, orientation) {
        final isLandscape = orientation == Orientation.landscape;
        return TournaQSheet(
          body: isLandscape ? _buildLandscape(context) : _buildPortrait(context),
        );
      },
    );
  }

  Widget _buildPortrait(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 36),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(widget.teamName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        Text(l10n.editPlayerNamesSubtitle, style: const TextStyle(color: Colors.black45, fontSize: 13)),
        const SizedBox(height: 20),
        _field(l10n.playerOne, _p1),
        const SizedBox(height: 14),
        _field(l10n.playerTwo, _p2),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => _save(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.gold,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(l10n.btnSavePlayers, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          ),
        ),
      ]),
    );
  }

  Widget _buildLandscape(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(widget.teamName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            Text(l10n.editPlayerNamesSubtitle, style: const TextStyle(color: Colors.black45, fontSize: 12)),
          ])),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: () => _save(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.gold,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(l10n.btnSave, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
          ),
        ]),
        const SizedBox(height: 12),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: _compactField(l10n.playerOne, _p1)),
          const SizedBox(width: 12),
          Expanded(child: _compactField(l10n.playerTwo, _p2)),
        ]),
      ]),
    );
  }

  Widget _field(String label, TextEditingController ctrl) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.black54)),
      const SizedBox(height: 6),
      TextField(
        controller: ctrl,
        decoration: InputDecoration(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
        textCapitalization: TextCapitalization.words,
      ),
    ]);
  }

  Widget _compactField(String label, TextEditingController ctrl) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Colors.black54)),
      const SizedBox(height: 5),
      TextField(
        controller: ctrl,
        decoration: InputDecoration(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(9)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          isDense: true,
        ),
        textCapitalization: TextCapitalization.words,
      ),
    ]);
  }
}
