import 'package:flutter/material.dart';
import '../services/app_data_service.dart';
import '../state/app_state.dart';
import '../widgets/app_drawer.dart';
import '../widgets/create_tournament_sheet.dart';
import '../widgets/scrollable_page.dart';
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

  @override
  void initState() { super.initState(); _localState = widget.appState; }

  void _updateState(AppState s) {
    setState(() => _localState = s);
    widget.onAppStateChanged(s);
  }

  Future<void> _showCreateSheet() async {
    final result = await showModalBottomSheet<AppState>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CreateTournamentSheet(appState: _localState),
    );
    if (result != null && mounted) _updateState(result);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: AppDrawer(appState: _localState, onAppStateChanged: _updateState),
      appBar: AppBar(title: const Text('Tournaments'), backgroundColor: Theme.of(context).colorScheme.inversePrimary),
      body: ScrollablePage(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          ElevatedButton.icon(
            onPressed: _showCreateSheet,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Create Tournament', style: TextStyle(fontWeight: FontWeight.w700)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD9A520),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 24),
          Text('Tournaments (${_localState.tournaments.length})', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          if (_localState.tournaments.isEmpty)
            const Center(child: Padding(
              padding: EdgeInsets.all(24),
              child: Text('No tournaments yet.', style: TextStyle(color: Colors.black45)),
            ))
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _localState.tournaments.length,
              itemBuilder: (context, index) {
                final t = _localState.tournaments[index];
                return ListTile(
                  title: Text(t.name),
                  subtitle: Text('${t.mode.displayName} • ${t.teamIds.length} teams • ${t.gameIds.length} games'),
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => TournamentDetailPage(appState: _localState, onAppStateChanged: _updateState, tournamentId: t.id),
                  )),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'delete') _updateState(AppDataService.deleteTournament(_localState, t.id));
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(value: 'delete', child: Text('Delete Tournament')),
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
