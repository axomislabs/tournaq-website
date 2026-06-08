import 'package:flutter/material.dart';
import '../app/app_colors.dart';
import '../l10n/app_localizations.dart';
import '../models/scramble_tournament.dart';
import '../models/tournament.dart';
import '../models/tournament_mode.dart';
import '../services/app_data_service.dart';
import '../services/scramble_storage_service.dart';
import '../state/app_state.dart';
import '../widgets/app_drawer.dart';
import '../widgets/tournaq_app_bar.dart';
import '../widgets/assign_dialog.dart';
import '../widgets/create_tournament_sheet.dart';
import '../widgets/filter_bar.dart';
import '../widgets/scrollable_page.dart';
import 'scramble_overview_page.dart';
import 'scramble_setup_page.dart';
import 'tournament_detail_page.dart';

class TournamentsPage extends StatefulWidget {
  final AppState appState;
  final Function(AppState) onAppStateChanged;
  const TournamentsPage({super.key, required this.appState, required this.onAppStateChanged});
  @override
  State<TournamentsPage> createState() => _TournamentsPageState();
}

class _TournamentsPageState extends State<TournamentsPage> {
  late AppState _localState;
  List<ScrambleTournament> _scrambles = [];
  final _searchCtrl = TextEditingController();
  final _teamFilter = <String>{};
  final _playerFilter = <String>{};
  final _clubFilter = <String>{};
  final _modeFilter = <String>{};

  @override
  void initState() {
    super.initState();
    _localState = widget.appState;
    _scrambles = ScrambleStorageService.loadAll();
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

  void _updateScramble(ScrambleTournament t) {
    setState(() {
      final idx = _scrambles.indexWhere((s) => s.id == t.id);
      if (idx >= 0) {
        _scrambles = List.from(_scrambles)..[idx] = t;
      } else {
        _scrambles = [t, ..._scrambles];
      }
    });
    ScrambleStorageService.save(t);
  }

  Future<void> _showCreateSheet() async {
    var openScramble = false;
    final result = await showModalBottomSheet<AppState>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CreateTournamentSheet(
        appState: _localState,
        onTimedScramble: () => openScramble = true,
      ),
    );
    if (!mounted) return;
    if (openScramble) {
      _openScrambleSetup();
    } else if (result != null) {
      _updateState(result);
    }
  }

  void _openScrambleSetup() {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ScrambleSetupPage(
        appState: _localState,
        onCreated: _updateScramble,
      ),
    ));
  }

  void _openScrambleOverview(ScrambleTournament t) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ScrambleOverviewPage(
        tournament: t,
        onChanged: _updateScramble,
      ),
    ));
  }

  // ── Actions ────────────────────────────────────────────────────────────────

  Future<void> _assignTeam(String tournamentId) async {
    final tournament = _localState.getTournamentById(tournamentId);
    if (tournament == null) return;
    final items = _localState.teams
        .where((t) => !tournament.teamIds.contains(t.id))
        .map((t) => (id: t.id, name: t.name))
        .toList();
    final selected = await showAssignDialog(
      context: context, title: 'Assign Team', items: items,
      emptyMessage: 'All teams are already in this tournament.',
    );
    if (selected != null && mounted) {
      _updateState(AppDataService.assignTeamToTournament(_localState, teamId: selected, tournamentId: tournamentId));
    }
  }

  Future<void> _assignClub(String tournamentId) async {
    final items = _localState.clubs
        .where((c) => !c.tournamentIds.contains(tournamentId))
        .map((c) => (id: c.id, name: c.name))
        .toList();
    final selected = await showAssignDialog(
      context: context, title: 'Assign to Club', items: items,
      emptyMessage: 'Tournament is already in all clubs.',
    );
    if (selected != null && mounted) {
      _updateState(AppDataService.assignTournamentToClub(_localState, tournamentId: tournamentId, clubId: selected));
    }
  }

  void _generateGames(String tournamentId) {
    final tournament = _localState.getTournamentById(tournamentId);
    if (tournament == null) return;
    final l10n = AppLocalizations.of(context)!;
    if (tournament.gameIds.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.snackbarGamesAlreadyGenerated)),
      );
      return;
    }
    if (tournament.teamIds.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.snackbarAddTeamsFirst)),
      );
      return;
    }
    _updateState(AppDataService.generateGamesForTournament(_localState, tournament));
  }

  Future<void> _deleteTournament(String tournamentId) async {
    final tournament = _localState.getTournamentById(tournamentId);
    if (tournament == null) return;
    final ok = await showConfirmDeleteDialog(context, tournament.name);
    if (ok && mounted) _updateState(AppDataService.deleteTournament(_localState, tournamentId));
  }

  // ── Filter ─────────────────────────────────────────────────────────────────

  void _clearAll() {
    _searchCtrl.clear();
    setState(() {
      _teamFilter.clear();
      _playerFilter.clear();
      _clubFilter.clear();
      _modeFilter.clear();
    });
  }

  List<Tournament> get _filteredTournaments {
    final q = _searchCtrl.text.toLowerCase();
    return _localState.tournaments.where((t) {
      if (q.isNotEmpty && !t.name.toLowerCase().contains(q)) return false;
      if (_teamFilter.isNotEmpty && !t.teamIds.any(_teamFilter.contains)) return false;
      if (_playerFilter.isNotEmpty) {
        final hasPlayer = _localState.teams
            .where((tm) => t.teamIds.contains(tm.id))
            .any((tm) => tm.userIds.any(_playerFilter.contains));
        if (!hasPlayer) return false;
      }
      if (_clubFilter.isNotEmpty) {
        final inClub = _localState.clubs
            .where((c) => _clubFilter.contains(c.id))
            .any((c) => c.tournamentIds.contains(t.id));
        if (!inClub) return false;
      }
      if (_modeFilter.isNotEmpty && !_modeFilter.contains(t.mode.type.name)) return false;
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final filtered = _filteredTournaments;
    final total = _localState.tournaments.length;
    final modeItems = TournamentModeType.values
        .map((m) => (id: m.name, name: TournamentMode.fromType(m).displayName))
        .toList();

    return Scaffold(
      drawer: AppDrawer(appState: _localState, onAppStateChanged: _updateState),
      appBar: TournaQAppBar(title: l10n.pageTournaments),
      body: ScrollablePage(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          ElevatedButton.icon(
            onPressed: _showCreateSheet,
            icon: const Icon(Icons.add_rounded),
            label: Text(l10n.btnCreateTournament, style: const TextStyle(fontWeight: FontWeight.w700)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.gold,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 20),
          FilterBar(
            searchController: _searchCtrl,
            hintText: l10n.hintSearchTournaments,
            onClearAll: _clearAll,
            groups: [
              FilterGroup(
                label: l10n.filterTeam, icon: Icons.group_rounded,
                items: _localState.teams.map((t) => (id: t.id, name: t.name)).toList(),
                selectedIds: _teamFilter,
                onToggle: (id, v) => setState(() { if (v) { _teamFilter.add(id); } else { _teamFilter.remove(id); } }),
              ),
              FilterGroup(
                label: l10n.filterPlayer, icon: Icons.person_rounded,
                items: _localState.users.map((u) => (id: u.id, name: u.name)).toList(),
                selectedIds: _playerFilter,
                onToggle: (id, v) => setState(() { if (v) { _playerFilter.add(id); } else { _playerFilter.remove(id); } }),
              ),
              FilterGroup(
                label: l10n.filterClub, icon: Icons.home_rounded,
                items: _localState.clubs.map((c) => (id: c.id, name: c.name)).toList(),
                selectedIds: _clubFilter,
                onToggle: (id, v) => setState(() { if (v) { _clubFilter.add(id); } else { _clubFilter.remove(id); } }),
              ),
              FilterGroup(
                label: l10n.filterMode, icon: Icons.tune_rounded,
                items: modeItems,
                selectedIds: _modeFilter,
                onToggle: (id, v) => setState(() { if (v) { _modeFilter.add(id); } else { _modeFilter.remove(id); } }),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── Scramble Tournaments ──────────────────────────────────────────
          if (_scrambles.isNotEmpty) ...[
            const Text('Timed Scramble', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.olive)),
            const SizedBox(height: 8),
            ..._scrambles.map((s) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: Container(
                  width: 40, height: 40,
                  decoration: const BoxDecoration(color: AppColors.oliveLight, shape: BoxShape.circle),
                  child: const Icon(Icons.shuffle_rounded, color: AppColors.olive, size: 20),
                ),
                title: Text(s.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(
                  '${s.playerCount} players · ${s.roundCount} rounds · '
                  '${s.completedGames}/${s.totalGames} games',
                  style: const TextStyle(fontSize: 12),
                ),
                trailing: PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, size: 20),
                  onSelected: (v) async {
                    if (v == 'delete') {
                      await ScrambleStorageService.delete(s.id);
                      setState(() => _scrambles.removeWhere((x) => x.id == s.id));
                    }
                  },
                  itemBuilder: (_) => [
                    actionMenuItem('delete', Icons.delete_outline, l10n.btnDelete, destructive: true),
                  ],
                ),
                onTap: () => _openScrambleOverview(s),
              ),
            )),
            const SizedBox(height: 8),
            const Divider(),
            const SizedBox(height: 8),
          ],

          Text(l10n.sectionTournamentsCount(total), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          if (total == 0)
            Center(child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(l10n.noTournamentsYet, style: const TextStyle(color: Colors.black45)),
            ))
          else if (filtered.isEmpty)
            Center(child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(l10n.noTournamentsFiltered, style: const TextStyle(color: Colors.black45)),
            ))
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final t = filtered[index];
                return ListTile(
                  title: Text(t.name),
                  subtitle: Text('${t.mode.displayName} • ${t.teamIds.length} teams • ${t.gameIds.length} games'),
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => TournamentDetailPage(appState: _localState, onAppStateChanged: _updateState, tournamentId: t.id),
                  )),
                  trailing: PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, size: 20),
                    onSelected: (value) {
                      switch (value) {
                        case 'assign_team': _assignTeam(t.id);
                        case 'assign_club': _assignClub(t.id);
                        case 'generate_games': _generateGames(t.id);
                        case 'delete': _deleteTournament(t.id);
                      }
                    },
                    itemBuilder: (_) => [
                      actionMenuItem('assign_team', Icons.group_rounded, l10n.menuAssignTeam),
                      actionMenuItem('assign_club', Icons.home_rounded, l10n.menuAssignToClub),
                      actionMenuItem('generate_games', Icons.auto_awesome_rounded, l10n.menuGenerateGames),
                      const PopupMenuDivider(),
                      actionMenuItem('delete', Icons.delete_outline, l10n.btnDelete, destructive: true),
                    ],
                  ),
                );
              },
            ),
        ]),
      ),
    );
  }
}
