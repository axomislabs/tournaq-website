import 'package:flutter/material.dart';
import '../app/app_colors.dart';
import '../models/doghouse_drill.dart';
import '../models/king_of_the_court_tournament.dart';
import '../models/scramble_tournament.dart';
import '../services/doghouse_storage_service.dart';
import '../services/king_of_the_court_storage_service.dart';
import '../services/scramble_storage_service.dart';
import '../state/app_state.dart';
import '../widgets/tournament_history_card.dart';
import '../widgets/tournaq_app_bar.dart';
import 'doghouse_scoreboard_page.dart';
import 'king_of_the_court_scoreboard_page.dart';
import 'scramble_overview_page.dart';

// ── Filter types ──────────────────────────────────────────────────────────────

enum TournamentFilter { all, scramble, kingOfTheCourt, doghouse }

extension on TournamentFilter {
  String get label => switch (this) {
        TournamentFilter.all            => 'All',
        TournamentFilter.scramble       => 'Social Scramble',
        TournamentFilter.kingOfTheCourt => 'King of the Court',
        TournamentFilter.doghouse       => 'Doghouse',
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
  List<KingOfTheCourtTournament> _kotcTournaments = [];
  List<DoghouseTournament> _doghouseDrills = [];

  @override
  void initState() {
    super.initState();
    _filter = widget.initialFilter;
    final scrambles = ScrambleStorageService.loadAll();
    scrambles.sort((a, b) => b.startTime.compareTo(a.startTime));
    _scrambles       = scrambles;
    _kotcTournaments = KingOfTheCourtStorageService.loadAll();
    _doghouseDrills  = DoghouseStorageService.loadAll();
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

  void _onKotcChanged(KingOfTheCourtTournament s) {
    KingOfTheCourtStorageService.save(s);
    setState(() {
      final idx = _kotcTournaments.indexWhere((e) => e.id == s.id);
      if (idx >= 0) {
        _kotcTournaments = List.from(_kotcTournaments)..[idx] = s;
      }
    });
  }

  void _onDoghouseChanged(DoghouseTournament d) {
    DoghouseStorageService.save(d);
    setState(() {
      final idx = _doghouseDrills.indexWhere((e) => e.id == d.id);
      if (idx >= 0) {
        _doghouseDrills = List.from(_doghouseDrills)..[idx] = d;
      }
    });
  }

  // ── Filtered items ────────────────────────────────────────────────────────

  List<_HistoryEntry> get _entries {
    final entries = <_HistoryEntry>[];
    if (_filter == TournamentFilter.all ||
        _filter == TournamentFilter.scramble) {
      for (final t in _scrambles) {
        entries.add(_HistoryEntry.fromScramble(t, _onScrambleChanged));
      }
    }
    if (_filter == TournamentFilter.all ||
        _filter == TournamentFilter.kingOfTheCourt) {
      for (final s in _kotcTournaments) {
        entries.add(_HistoryEntry.fromKotc(s, _onKotcChanged, widget.appState));
      }
    }
    if (_filter == TournamentFilter.all ||
        _filter == TournamentFilter.doghouse) {
      for (final d in _doghouseDrills) {
        entries.add(_HistoryEntry.fromDoghouse(d, _onDoghouseChanged, widget.appState));
      }
    }
    entries.sort((a, b) => b.date.compareTo(a.date));
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
                        onTap:       () => e.onTap(context),
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
  final DateTime date;
  final void Function(BuildContext) onTap;

  const _HistoryEntry({
    required this.name,
    required this.typeLabel,
    required this.typeColor,
    required this.typeIcon,
    required this.dateLabel,
    required this.statusLabel,
    required this.isActive,
    required this.stats,
    required this.date,
    required this.onTap,
  });

  static String _dateLabel(DateTime d) {
    final now  = DateTime.now();
    final diff = DateTime(now.year, now.month, now.day)
        .difference(DateTime(d.year, d.month, d.day))
        .inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    if (diff < 7)  return '$diff days ago';
    return '${d.day}/${d.month}/${d.year}';
  }

  factory _HistoryEntry.fromScramble(
    ScrambleTournament t,
    void Function(ScrambleTournament) onChanged,
  ) {
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
      dateLabel:   _dateLabel(t.startTime),
      statusLabel: statusLabel,
      isActive:    t.status != ScrambleTournamentStatus.completed,
      date:        t.startTime,
      stats: [
        '${t.playerCount} players',
        '${t.roundCount} rounds',
        '${t.completedGames}/${t.totalGames} games',
      ],
      onTap: (ctx) => Navigator.of(ctx).push(MaterialPageRoute(
        builder: (_) => ScrambleOverviewPage(
          tournament: t,
          onChanged:  onChanged,
        ),
      )),
    );
  }

  factory _HistoryEntry.fromKotc(
    KingOfTheCourtTournament s,
    void Function(KingOfTheCourtTournament) onChanged,
    AppState appState,
  ) {
    final statusLabel = switch (s.status) {
      KotcTournamentStatus.completed  => 'Completed',
      KotcTournamentStatus.inProgress => 'In Progress',
      KotcTournamentStatus.setup      => 'Setup',
    };

    return _HistoryEntry(
      name:        s.name,
      typeLabel:   'King of the Court',
      typeColor:   AppColors.gold,
      typeIcon:    Icons.workspace_premium_rounded,
      dateLabel:   _dateLabel(s.createdAt),
      statusLabel: statusLabel,
      isActive:    s.status != KotcTournamentStatus.completed,
      date:        s.createdAt,
      stats: [
        '${s.playerCount} players',
        '${s.gameCount} games',
        '${s.totalPoints} pts scored',
      ],
      onTap: (ctx) => Navigator.of(ctx).push(MaterialPageRoute(
        builder: (_) => KingOfTheCourtScoreboardPage(
          tournament: s,
          appState:   appState,
          onChanged:  onChanged,
        ),
      )),
    );
  }

  factory _HistoryEntry.fromDoghouse(
    DoghouseTournament d,
    void Function(DoghouseTournament) onChanged,
    AppState appState,
  ) {
    final statusLabel = switch (d.status) {
      DoghouseTournamentStatus.completed  => 'Completed',
      DoghouseTournamentStatus.inProgress => 'In Progress',
      DoghouseTournamentStatus.setup      => 'Setup',
    };

    return _HistoryEntry(
      name:        d.name,
      typeLabel:   'Doghouse',
      typeColor:   AppColors.gold,
      typeIcon:    Icons.pets_rounded,
      dateLabel:   _dateLabel(d.createdAt),
      statusLabel: statusLabel,
      isActive:    d.status != DoghouseTournamentStatus.completed,
      date:        d.createdAt,
      stats: [
        '${d.playerCount} players',
        '${d.gameCount} games',
        '${d.totalEscapes} escapes',
      ],
      onTap: (ctx) => Navigator.of(ctx).push(MaterialPageRoute(
        builder: (_) => DoghouseScoreboardPage(
          tournament: d,
          appState:  appState,
          onChanged: onChanged,
        ),
      )),
    );
  }
}
