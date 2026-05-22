import 'package:flutter/material.dart';
import '../services/app_data_service.dart';
import '../state/app_state.dart';
import '../widgets/app_drawer.dart';
import '../widgets/create_club_sheet.dart';
import '../widgets/scrollable_page.dart';
import 'club_detail_page.dart';

class ClubsPage extends StatefulWidget {
  final AppState appState;
  final Function(AppState) onAppStateChanged;
  const ClubsPage({super.key, required this.appState, required this.onAppStateChanged});
  @override
  State<ClubsPage> createState() => _ClubsPageState();
}

class _ClubsPageState extends State<ClubsPage> {
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
      builder: (_) => CreateClubSheet(appState: _localState),
    );
    if (result != null && mounted) _updateState(result);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: AppDrawer(appState: _localState, onAppStateChanged: _updateState),
      appBar: AppBar(title: const Text('Clubs'), backgroundColor: Theme.of(context).colorScheme.inversePrimary),
      body: ScrollablePage(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          ElevatedButton.icon(
            onPressed: _showCreateSheet,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Create Club', style: TextStyle(fontWeight: FontWeight.w700)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD9A520),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 24),
          Text('Clubs (${_localState.clubs.length})', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          if (_localState.clubs.isEmpty)
            const Center(child: Padding(
              padding: EdgeInsets.all(24),
              child: Text('No clubs yet.', style: TextStyle(color: Colors.black45)),
            ))
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _localState.clubs.length,
              itemBuilder: (context, index) {
                final club = _localState.clubs[index];
                return ListTile(
                  title: Text(club.name),
                  subtitle: Text('${club.playerIds.length} player(s) • ${club.teamIds.length} team(s) • ${club.tournamentIds.length} tournament(s)'),
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => ClubDetailPage(appState: _localState, onAppStateChanged: _updateState, clubId: club.id),
                  )),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => _updateState(AppDataService.deleteClub(_localState, club.id)),
                  ),
                );
              },
            ),
        ]),
      ),
    );
  }
}
