import 'package:flutter/material.dart';
import '../app/app_colors.dart';
import '../l10n/app_localizations.dart';
import '../models/group.dart';
import '../models/imported_scorecard.dart';
import '../models/scramble_tournament.dart';
import '../models/player.dart';
import '../services/imported_scorecard_storage_service.dart';
import '../services/scramble_storage_service.dart';
import '../services/scramble_transfer_service.dart';
import '../widgets/tournament_history_card.dart';
import '../widgets/tournaq_app_bar.dart';
import 'qr_scan_page.dart';
import 'scramble_overview_page.dart';
import 'scramble_scorecard_page.dart';
import 'scramble_setup_page.dart';

class ScrambleHubPage extends StatefulWidget {
  final List<Player> existingPlayers;
  final List<Group> existingGroups;
  final Player Function(String name) onCreatePlayer;
  final void Function(String playerId, String newName)? onUpdatePlayer;

  const ScrambleHubPage({
    super.key,
    required this.existingPlayers,
    required this.existingGroups,
    required this.onCreatePlayer,
    this.onUpdatePlayer,
  });

  @override
  State<ScrambleHubPage> createState() => _ScrambleHubPageState();
}

class _ScrambleHubPageState extends State<ScrambleHubPage> {
  List<ScrambleTournament> _scrambles = [];
  List<ImportedScorecard> _imported = [];
  final TextEditingController _importFilter = TextEditingController();
  bool _showImportedTab = false;

  @override
  void initState() {
    super.initState();
    _loadScrambles();
    _loadImported();
  }

  @override
  void dispose() {
    _importFilter.dispose();
    super.dispose();
  }

  void _loadScrambles() {
    final all = ScrambleStorageService.loadAll();
    all.sort((a, b) => b.startTime.compareTo(a.startTime));
    setState(() => _scrambles = all);
  }

  void _loadImported() {
    setState(() => _imported = ImportedScorecardStorageService.loadAll());
  }

  List<ImportedScorecard> get _filteredImported {
    final q = _importFilter.text.trim().toLowerCase();
    if (q.isEmpty) return _imported;
    return _imported
        .where((s) => s.tournamentName.toLowerCase().contains(q))
        .toList();
  }

  // ── Import / scan ─────────────────────────────────────────────────────────

  Future<void> _scanToImport() async {
    final l10n = AppLocalizations.of(context)!;
    final raw = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => QrScanPage(hint: l10n.scrambleScanScorecardHint),
      ),
    );
    if (raw == null || !mounted) return;

    ImportedScorecard imported;
    try {
      imported = ScrambleTransferService.decodeGameExport(raw);
    } catch (_) {
      _showSnack(l10n.scrambleScanNotScorecard);
      return;
    }
    await ImportedScorecardStorageService.save(imported);
    _loadImported();
    setState(() => _showImportedTab = true);
    _showSnack(l10n.scrambleImportSuccess(imported.tournamentName));
  }

  void _openImportedScorecard(ImportedScorecard imp) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ScrambleScorecardPage(
        tournament: imp.tournament,
        game: imp.game,
        round: imp.round,
        isImported: true,
        parentTournamentId: imp.parentTournamentId,
        saveToStore: false,
        onChanged: (updated) => _persistImported(imp, updated),
      ),
    ));
  }

  void _persistImported(ImportedScorecard imp, ScrambleTournament updated) {
    final newImp = imp.copyWith(tournament: updated);
    ImportedScorecardStorageService.save(newImp);
    setState(() {
      final idx = _imported.indexWhere((s) => s.id == newImp.id);
      if (idx >= 0) _imported = List.from(_imported)..[idx] = newImp;
    });
  }

  Future<void> _deleteOneImported(ImportedScorecard imp) async {
    await ImportedScorecardStorageService.delete(imp.id);
    setState(() => _imported.removeWhere((s) => s.id == imp.id));
  }

  Future<void> _deleteAllImported() async {
    if (_imported.isEmpty) return;
    final l10n = AppLocalizations.of(context)!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(l10n.scrambleImportedDeleteAllTitle,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        content: Text(
          l10n.scrambleImportedDeleteAllBody(_imported.length),
          style: const TextStyle(fontSize: 14, color: Colors.black54),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.btnCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(l10n.btnDeleteAll),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      for (final s in _imported) {
        await ImportedScorecardStorageService.delete(s.id);
      }
      setState(() => _imported = []);
    }
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  String _gameStatusLabel(AppLocalizations l10n, ScrambleGameStatus s) =>
      switch (s) {
        ScrambleGameStatus.completed => l10n.statusCompleted,
        ScrambleGameStatus.inProgress => l10n.statusInProgress,
        ScrambleGameStatus.scheduled => l10n.scrambleStatusScheduled,
      };

  void _persist(ScrambleTournament t) {
    ScrambleStorageService.save(t);
    setState(() {
      final idx = _scrambles.indexWhere((s) => s.id == t.id);
      if (idx >= 0) {
        _scrambles = List.from(_scrambles)..[idx] = t;
      } else {
        _scrambles = [t, ..._scrambles];
      }
    });
  }

  void _openSetup() {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ScrambleSetupPage(
        existingPlayers: widget.existingPlayers,
        existingGroups: widget.existingGroups,
        onCreated: _persist,
        onCreatePlayer: widget.onCreatePlayer,
      ),
    ));
  }

  void _openOverview(ScrambleTournament t) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ScrambleOverviewPage(
        tournament:     t,
        onChanged:      _persist,
        onCreatePlayer: widget.onCreatePlayer,
        onUpdatePlayer: widget.onUpdatePlayer,
      ),
    ));
  }

  Future<void> _deleteOne(ScrambleTournament t) async {
    final l10n = AppLocalizations.of(context)!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(l10n.doghouseDeleteTournamentTitle,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        content: Text(
          l10n.doghouseDeleteTournamentBody(t.name),
          style: const TextStyle(fontSize: 14, color: Colors.black54),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.btnCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(l10n.btnDelete),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      await ScrambleStorageService.delete(t.id);
      setState(() => _scrambles.removeWhere((s) => s.id == t.id));
    }
  }

  Future<void> _deleteAll() async {
    if (_scrambles.isEmpty) return;
    final l10n = AppLocalizations.of(context)!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(l10n.doghouseDeleteAllTitle,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        content: Text(
          l10n.doghouseDeleteAllBody(_scrambles.length),
          style: const TextStyle(fontSize: 14, color: Colors.black54),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.btnCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(l10n.btnDeleteAll),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      for (final t in _scrambles) {
        await ScrambleStorageService.delete(t.id);
      }
      setState(() => _scrambles.clear());
    }
  }

  // ── Card adapter ──────────────────────────────────────────────────────────

  String _statusLabel(AppLocalizations l10n, ScrambleTournament t) =>
      switch (t.status) {
        ScrambleTournamentStatus.completed  => l10n.statusCompleted,
        ScrambleTournamentStatus.inProgress => l10n.statusInProgress,
        ScrambleTournamentStatus.setup      => l10n.statusSetup,
      };

  String _dateLabel(AppLocalizations l10n, ScrambleTournament t) {
    final d    = t.startTime;
    final now  = DateTime.now();
    final diff = DateTime(now.year, now.month, now.day)
        .difference(DateTime(d.year, d.month, d.day))
        .inDays;
    if (diff == 0) return l10n.dateToday;
    if (diff == 1) return l10n.dateYesterday;
    if (diff < 7)  return l10n.dateDaysAgo(diff);
    return '${d.day}/${d.month}/${d.year}';
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final showImported = _showImportedTab && _imported.isNotEmpty;
    return Scaffold(
      appBar: TournaQAppBar(
        title: 'Social Scrambles',
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner_rounded),
            tooltip: l10n.scrambleScanToImport,
            onPressed: _scanToImport,
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // ── Start card ───────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: _buildStartCard(l10n),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 20)),

          // ── History | Imported toggle (only when there's something imported) ──
          if (_imported.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildTabToggle(l10n),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 16)),
          ],

          if (showImported)
            ..._buildImportedSlivers(l10n)
          else
            ..._buildHistorySlivers(l10n),

          const SliverToBoxAdapter(child: SizedBox(height: 16)),
        ],
      ),
    );
  }

  /// Compact two-segment switcher so imported scorecards stay one tap away
  /// instead of sinking below a long tournament history list.
  Widget _buildTabToggle(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: _tabPill(
              label: '${l10n.scrambleTabHistory} (${_scrambles.length})',
              selected: !_showImportedTab,
              onTap: () => setState(() => _showImportedTab = false),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _tabPill(
              label: '${l10n.scrambleTabImported} (${_imported.length})',
              selected: _showImportedTab,
              onTap: () => setState(() => _showImportedTab = true),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tabPill({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: selected ? AppColors.gold : Colors.black45,
          ),
        ),
      ),
    );
  }

  // ── Tournament history slivers ──────────────────────────────────────────

  List<Widget> _buildHistorySlivers(AppLocalizations l10n) {
    return [
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              const Icon(Icons.history_rounded,
                  size: 20, color: AppColors.oliveMedium),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.doghouseTournamentHistory(_scrambles.length),
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w800),
                ),
              ),
              if (_scrambles.isNotEmpty)
                TextButton.icon(
                  onPressed: _deleteAll,
                  icon: const Icon(Icons.delete_outline, size: 16),
                  label: Text(l10n.btnDeleteAll,
                      style: const TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(
                      foregroundColor: Colors.red.shade400),
                ),
            ],
          ),
        ),
      ),
      const SliverToBoxAdapter(child: SizedBox(height: 8)),
      if (_scrambles.isEmpty)
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.shuffle_rounded,
                    size: 48, color: Colors.grey.shade300),
                const SizedBox(height: 12),
                Text(l10n.doghouseNoTournamentsYet,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: Colors.black45)),
                const SizedBox(height: 4),
                Text(l10n.doghouseNoTournamentsHint,
                    style: const TextStyle(
                        color: Colors.black38, fontSize: 13)),
              ],
            ),
          ),
        )
      else
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (_, i) {
                final t = _scrambles[i];
                return TournamentHistoryCard(
                  name:        t.name,
                  typeLabel:   'Social Scrambles',
                  typeColor:   AppColors.gold,
                  typeIcon:    Icons.shuffle_rounded,
                  dateLabel:   _dateLabel(l10n, t),
                  statusLabel: _statusLabel(l10n, t),
                  isActive:
                      t.status != ScrambleTournamentStatus.completed,
                  stats: [
                    l10n.doghouseStatsPlayers(t.playerCount),
                    l10n.statsRounds(t.roundCount),
                    l10n.statsGamesOf(t.completedGames, t.totalGames),
                  ],
                  onTap:       () => _openOverview(t),
                  onDeleteTap: () => _deleteOne(t),
                );
              },
              childCount: _scrambles.length,
            ),
          ),
        ),
    ];
  }

  // ── Imported scorecards slivers ───────────────────────────────────────────

  List<Widget> _buildImportedSlivers(AppLocalizations l10n) {
    final filtered = _filteredImported;
    return [
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _importFilter,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: l10n.scrambleImportedFilterHint,
                    prefixIcon: const Icon(Icons.search_rounded,
                        size: 20, color: Colors.black38),
                    suffixIcon: _importFilter.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () =>
                                setState(() => _importFilter.clear()),
                          )
                        : null,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              TextButton.icon(
                onPressed: _deleteAllImported,
                icon: const Icon(Icons.delete_outline, size: 16),
                label: Text(l10n.btnDeleteAll,
                    style: const TextStyle(fontSize: 12)),
                style: TextButton.styleFrom(
                    foregroundColor: Colors.red.shade400),
              ),
            ],
          ),
        ),
      ),
      if (filtered.isEmpty)
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Text(l10n.scrambleImportedEmpty,
                style: const TextStyle(color: Colors.black38, fontSize: 13)),
          ),
        )
      else
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (_, i) => _importedCard(l10n, filtered[i]),
              childCount: filtered.length,
            ),
          ),
        ),
    ];
  }

  Widget _importedCard(AppLocalizations l10n, ImportedScorecard imp) {
    final game = imp.game;
    final teamA = game.sideAPlayerIds
        .map((id) => imp.tournament.getPlayer(id)?.name ?? id)
        .join(' & ');
    final teamB = game.sideBPlayerIds
        .map((id) => imp.tournament.getPlayer(id)?.name ?? id)
        .join(' & ');
    return TournamentHistoryCard(
      name: imp.tournamentName,
      typeLabel: 'Imported',
      typeColor: AppColors.gold,
      typeIcon: Icons.qr_code_rounded,
      dateLabel: _importedDateLabel(l10n, imp),
      statusLabel: _gameStatusLabel(l10n, game.status),
      isActive: game.status != ScrambleGameStatus.completed,
      stats: [
        l10n.scrambleImportedCourt(game.courtNumber),
        '$teamA vs $teamB',
      ],
      onTap: () => _openImportedScorecard(imp),
      onDeleteTap: () => _deleteOneImported(imp),
    );
  }

  String _importedDateLabel(AppLocalizations l10n, ImportedScorecard imp) {
    final d = imp.importedAt;
    final now = DateTime.now();
    final diff = DateTime(now.year, now.month, now.day)
        .difference(DateTime(d.year, d.month, d.day))
        .inDays;
    if (diff == 0) return l10n.dateToday;
    if (diff == 1) return l10n.dateYesterday;
    if (diff < 7) return l10n.dateDaysAgo(diff);
    return '${d.day}/${d.month}/${d.year}';
  }

  Widget _buildStartCard(AppLocalizations l10n) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.gold, AppColors.goldGradientEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.gold.withValues(alpha: 0.28),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.shuffle_rounded, color: Colors.white, size: 22),
              SizedBox(width: 8),
              Text(
                'Social Scrambles',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            l10n.modeSocialScramblesDesc,
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.90),
                fontSize: 13,
                fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _openSetup,
            icon: const Icon(Icons.add_rounded),
            label: Text(l10n.doghouseNewTournament,
                style: const TextStyle(fontWeight: FontWeight.w700)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.gold,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}
