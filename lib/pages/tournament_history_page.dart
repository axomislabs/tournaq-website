import 'package:flutter/material.dart';
import '../app/app_colors.dart';
import '../models/scramble_tournament.dart';
import '../services/scramble_storage_service.dart';
import '../state/app_state.dart';
import '../widgets/tournament_history_card.dart';
import '../widgets/tournaq_app_bar.dart';
import 'scramble_overview_page.dart';

// ── Filter types ──────────────────────────────────────────────────────────────

enum TournamentFilter { all, scramble }

extension on TournamentFilter {
  String get label => switch (this) {
        TournamentFilter.all      => 'All',
        TournamentFilter.scramble => 'Social Scramble',
      };
}

// ── Page ──────────────────────────────────────────────────────────────────────

class TournamentHistoryPage extends StatefulWidget {
  final AppState appState;
  final Function(AppState) onAppStateChanged;
  final TournamentFilter initialFilter;

  const TournamentHistoryPage({
    super.key,
    required this.appState,
    required this.onAppStateChanged,
    this.initialFilter = TournamentFilter.all,
  });

  @override
  State<TournamentHistoryPage> createState() =>
      _TournamentHistoryPageState();
}

class _TournamentHistoryPageState extends State<TournamentHistoryPage> {
  late TournamentFilter _filter;
  List<ScrambleTournament> _scrambles = [];

  @override
  void initState() {
    super.initState();
    _filter = widget.initialFilter;
    final all = ScrambleStorageService.loadAll();
    all.sort((a, b) => b.startTime.compareTo(a.startTime));
    _scrambles = all;
  }

  void _onScrambleChanged(ScrambleTournament t) {
    ScrambleStorageService.save(t);
    setState(() {
      final idx = _scrambles.indexWhere((s) => s.id == t.id);
      if (idx >= 0) {
        _scrambles = List.from(_scrambles)..[idx] = t;
      }
    });
  }

  // ── Filtered items ────────────────────────────────────────────────────────

  List<_HistoryEntry> get _entries {
    final entries = <_HistoryEntry>[];
    if (_filter == TournamentFilter.all ||
        _filter == TournamentFilter.scramble) {
      for (final t in _scrambles) {
        entries.add(_HistoryEntry.fromScramble(t));
      }
    }
    // Future types added here when available.
    return entries;
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final entries = _entries;

    return Scaffold(
      appBar: const TournaQAppBar(title: 'Tournament History'),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Filter chips
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: TournamentFilter.values.map((f) {
                final selected = _filter == f;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(f.label),
                    selected: selected,
                    onSelected: (_) => setState(() => _filter = f),
                    selectedColor: AppColors.goldCream,
                    checkmarkColor: AppColors.goldDark,
                    labelStyle: TextStyle(
                      fontSize: 13,
                      fontWeight: selected
                          ? FontWeight.w700
                          : FontWeight.w400,
                      color: selected
                          ? AppColors.goldDark
                          : Colors.black54,
                    ),
                    side: BorderSide(
                      color: selected
                          ? AppColors.goldBadgeBorder
                          : Colors.grey.shade300,
                    ),
                    backgroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                  ),
                );
              }).toList(),
            ),
          ),
          const Divider(height: 1),

          // List
          Expanded(
            child: entries.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.history_rounded,
                            size: 48,
                            color: Colors.grey.shade300),
                        const SizedBox(height: 12),
                        const Text(
                          'No tournaments found.',
                          style: TextStyle(
                              color: Colors.black38, fontSize: 14),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding:
                        const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    itemCount: entries.length,
                    itemBuilder: (_, i) {
                      final e = entries[i];
                      return TournamentHistoryCard(
                        name:        e.name,
                        typeLabel:   e.typeLabel,
                        typeColor:   e.typeColor,
                        typeIcon:    e.typeIcon,
                        dateLabel:   e.dateLabel,
                        statusLabel: e.statusLabel,
                        isActive:    e.isActive,
                        stats:       e.stats,
                        onTap:       () => e.onTap(context, _onScrambleChanged),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ── History entry (type-agnostic row) ─────────────────────────────────────────

class _HistoryEntry {
  final String name;
  final String typeLabel;
  final Color typeColor;
  final IconData typeIcon;
  final String dateLabel;
  final String statusLabel;
  final bool isActive;
  final List<String> stats;
  final void Function(BuildContext, void Function(ScrambleTournament)) onTap;

  const _HistoryEntry({
    required this.name,
    required this.typeLabel,
    required this.typeColor,
    required this.typeIcon,
    required this.dateLabel,
    required this.statusLabel,
    required this.isActive,
    required this.stats,
    required this.onTap,
  });

  factory _HistoryEntry.fromScramble(ScrambleTournament t) {
    final d    = t.startTime;
    final now  = DateTime.now();
    final diff = DateTime(now.year, now.month, now.day)
        .difference(DateTime(d.year, d.month, d.day))
        .inDays;
    final dateLabel = diff == 0
        ? 'Today'
        : diff == 1
            ? 'Yesterday'
            : diff < 7
                ? '$diff days ago'
                : '${d.day}/${d.month}/${d.year}';

    final statusLabel = switch (t.status) {
      ScrambleTournamentStatus.completed  => 'Completed',
      ScrambleTournamentStatus.inProgress => 'In Progress',
      ScrambleTournamentStatus.setup      => 'Setup',
    };

    return _HistoryEntry(
      name:        t.name,
      typeLabel:   'Social Scramble',
      typeColor:   AppColors.gold,
      typeIcon:    Icons.shuffle_rounded,
      dateLabel:   dateLabel,
      statusLabel: statusLabel,
      isActive:    t.status != ScrambleTournamentStatus.completed,
      stats: [
        '${t.playerCount} players',
        '${t.roundCount} rounds',
        '${t.completedGames}/${t.totalGames} games',
      ],
      onTap: (ctx, onChanged) => Navigator.of(ctx).push(MaterialPageRoute(
        builder: (_) => ScrambleOverviewPage(
          tournament: t,
          onChanged:  onChanged,
        ),
      )),
    );
  }
}
