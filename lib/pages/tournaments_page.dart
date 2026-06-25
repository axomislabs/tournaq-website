import 'dart:math' show pi;
import 'package:flutter/material.dart';
import '../app/app_colors.dart';
import '../app/app_links.dart';
import '../l10n/app_localizations.dart';
import '../utils/url_utils.dart';
import '../services/doghouse_storage_service.dart';
import '../services/king_of_the_court_storage_service.dart';
import '../services/ko_bracket_storage_service.dart';
import '../services/scramble_storage_service.dart';
import '../models/player.dart';
import '../models/team.dart';
import '../state/app_state.dart';
import '../widgets/tournaq_app_bar.dart';
import 'coming_soon_page.dart';
import 'doghouse_hub_page.dart';
import 'games_page.dart';
import 'king_of_the_court_hub_page.dart';
import 'ko_bracket_hub_page.dart';
import 'scramble_hub_page.dart';
import 'tournament_history_page.dart';

class TournamentsPage extends StatefulWidget {
  final AppState appState;
  final Function(AppState) onAppStateChanged;

  const TournamentsPage({
    super.key,
    required this.appState,
    required this.onAppStateChanged,
  });

  @override
  State<TournamentsPage> createState() => _TournamentsPageState();
}

class _TournamentsPageState extends State<TournamentsPage> {
  late AppState _localState;
  int _scrambleCount  = 0;
  int _kotcCount      = 0;
  int _doghouseCount  = 0;
  int _koBracketCount = 0;

  @override
  void initState() {
    super.initState();
    _localState      = widget.appState;
    _scrambleCount   = ScrambleStorageService.loadAll().length;
    _kotcCount       = KingOfTheCourtStorageService.loadAll().length;
    _doghouseCount   = DoghouseStorageService.loadAll().length;
    _koBracketCount  = KoBracketStorageService.loadAll().length;
  }

  void _updateState(AppState s) {
    setState(() => _localState = s);
    widget.onAppStateChanged(s);
  }

  Player _createPlayer(String name) {
    final player = Player(id: AppState.generateId(), name: name);
    _updateState(_localState.addPlayer(player));
    return player;
  }

  void _updatePlayer(String playerId, String newName) {
    final player = _localState.getPlayerById(playerId);
    if (player == null) return;
    _updateState(_localState.updatePlayer(player.copyWith(name: newName)));
  }

  String _createTeam(String name, List<String> linkedPlayerIds) {
    final team = Team(id: AppState.generateId(), name: name, userIds: linkedPlayerIds);
    _updateState(_localState.addTeam(team));
    return team.id;
  }

  void _refreshCounts() {
    setState(() {
      _scrambleCount  = ScrambleStorageService.loadAll().length;
      _kotcCount      = KingOfTheCourtStorageService.loadAll().length;
      _doghouseCount  = DoghouseStorageService.loadAll().length;
      _koBracketCount = KoBracketStorageService.loadAll().length;
    });
  }

  void _openQuickGames() {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => GamesPage(
        appState: _localState,
        onAppStateChanged: _updateState,
      ),
    ));
  }

  void _openScrambleHub() {
    Navigator.of(context)
        .push(MaterialPageRoute(
          builder: (_) => ScrambleHubPage(
            existingPlayers: _localState.players,
            existingGroups: _localState.groups,
            onCreatePlayer: _createPlayer,
            onUpdatePlayer: _updatePlayer,
          ),
        ))
        .then((_) => _refreshCounts());
  }

  void _openKotcHub() {
    Navigator.of(context)
        .push(MaterialPageRoute(
          builder: (_) => KingOfTheCourtHubPage(
            existingPlayers: _localState.players,
            existingGroups: _localState.groups,
            onCreatePlayer: _createPlayer,
          ),
        ))
        .then((_) => _refreshCounts());
  }

  void _openDoghouseHub() {
    Navigator.of(context)
        .push(MaterialPageRoute(
          builder: (_) => DoghouseHubPage(
            existingPlayers: _localState.players,
            existingGroups: _localState.groups,
            onCreatePlayer: _createPlayer,
          ),
        ))
        .then((_) => _refreshCounts());
  }

  void _openHistory({TournamentFilter filter = TournamentFilter.all}) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => TournamentHistoryPage(
        existingPlayers: _localState.players,
        initialFilter: filter,
        onCreatePlayer: _createPlayer,
      ),
    ));
  }

  void _openKoBracketHub() {
    Navigator.of(context)
        .push(MaterialPageRoute(
          builder: (_) => KoBracketHubPage(
            existingPlayers: _localState.players,
            existingTeams: _localState.teams,
            existingGroups: _localState.groups,
            onCreatePlayer: _createPlayer,
            onCreateTeam: _createTeam,
          ),
        ))
        .then((_) => _refreshCounts());
  }

  Future<void> _deleteAllHistory() async {
    final total = _scrambleCount + _kotcCount + _doghouseCount + _koBracketCount;
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(l10n.tournamentsDeleteTitle,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        content: Text(
          l10n.tournamentsDeleteBody(total),
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
            child: Text(l10n.tournamentsDeleteAll),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    for (final t in ScrambleStorageService.loadAll()) {
      await ScrambleStorageService.delete(t.id);
    }
    for (final t in KingOfTheCourtStorageService.loadAll()) {
      await KingOfTheCourtStorageService.delete(t.id);
    }
    for (final t in DoghouseStorageService.loadAll()) {
      await DoghouseStorageService.delete(t.id);
    }
    for (final t in KoBracketStorageService.loadAll()) {
      await KoBracketStorageService.delete(t.id);
    }
    _refreshCounts();
  }

  void _openComingSoon(String title, String description) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) =>
          ComingSoonPage(title: title, shortDescription: description),
    ));
  }

  void _showPageInfo() {
    final l10n = AppLocalizations.of(context)!;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
        actionsPadding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        title: Text(l10n.navTournaments,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
        content: SingleChildScrollView(
          child: Text(
            l10n.tournamentsInfoContent,
            style: const TextStyle(fontSize: 14, color: Colors.black54, height: 1.6),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => openExternalUrl(ctx, AppLinks.modeGamesAndTournaments),
            child: Text(l10n.btnLearnMore),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.btnGotIt,
                style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: TournaQAppBar(
        title: l10n.navTournaments,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline_rounded),
            tooltip: 'About Tournament Hub',
            onPressed: _showPageInfo,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Quick Games ────────────────────────────────────────────
            _sectionHeader(l10n.tournamentsSectionQuickGames, Icons.flash_on_rounded),
            const SizedBox(height: 12),
            Column(children: [
              _TypeTile(
                icon:         Icons.flash_on_rounded,
                color:        AppColors.gold,
                gradientEnd:  AppColors.goldGradientEnd,
                name:         'Quick Games',
                description:  l10n.modeQuickGamesDesc,
                onTap:        _openQuickGames,
                learnMoreUrl: AppLinks.modeQuickGame,
                helpText:
                    'Quick Games lets you start a scored match on the spot — '
                    'no tournament setup required. Pick two teams, set the '
                    'format, and start tracking the score immediately.\n\n'
                    'Ideal for casual play, training sessions, or any time '
                    'you just want to run a game without a bracket.',
              ),
            ]),
            const SizedBox(height: 24),

            // ── Single Competitions & Socials ──────────────────────────
            _sectionHeader(l10n.tournamentsSectionSingle, Icons.people_rounded),
            const SizedBox(height: 12),
            Column(children: [
              _TypeTile(
                icon:         Icons.shuffle_rounded,
                color:        AppColors.gold,
                gradientEnd:  AppColors.goldGradientEnd,
                name:         'Social Scrambles',
                description:  l10n.modeSocialScramblesDesc,
                count:        _scrambleCount,
                onTap:        _openScrambleHub,
                learnMoreUrl: AppLinks.modeSocialScramble,
                helpText:
                    'Social Scrambles is a timed, rotating mixer where teams are randomly '
                    'reshuffled every round. No one stays partnered for long — the whole '
                    'point is to play with and against as many different people as possible '
                    'across the session.\n\n'
                    'Perfect for beach sessions, open days, or any group that wants '
                    'competitive play without the pressure of a fixed bracket.\n\n'
                    'Fair by design. TournaQ schedules every player into the maximum number '
                    'of rounds while keeping wait times as short as possible. When not '
                    'everyone can fit on court at once, sitting-out rotations are balanced '
                    'so no player waits longer than others.\n\n'
                    'How a round works:\n'
                    '• Teams are randomly drawn at the start of each round\n'
                    '• All courts play simultaneously for the set match duration\n'
                    '• A short break follows before the next round\n'
                    '• Cumulative wins are tracked across all rounds\n\n'
                    'Add your players, set a session timer, and go.',
              ),
              _TypeTile(
                icon:         Icons.workspace_premium_rounded,
                color:        AppColors.gold,
                gradientEnd:  AppColors.goldGradientEnd,
                name:         'King of the Court',
                description:  l10n.modeKotcDesc,
                count:        _kotcCount,
                onTap:        _openKotcHub,
                learnMoreUrl: AppLinks.modeKingOfTheCourt,
                helpText:
                    'King of the Court is a fast, individual competition where every '
                    'player fights for the crown. Players rotate on and off court in '
                    'groups, scoring points for each rally won — but the ranking is '
                    'entirely personal. The player who accumulates the most game wins '
                    '(then points) across the session takes the title.\n\n'
                    'Short format, high energy — perfect as a session warm-up or a '
                    'standalone competition.\n\n'
                    'Fair by design. TournaQ\'s Automated assignment ensures everyone '
                    'plays with and against different people, keeping wait times low '
                    'and avoiding repeat pairings. Because matchups stay balanced '
                    'throughout the session, the final standings are a genuine '
                    'reflection of individual performance — not just who got the '
                    'easiest draw.\n\n'
                    'How a game works:\n'
                    '• Win a rally → each player on that side scores a point\n'
                    '• Reach your Strike Points target → current group wins the game, '
                    'everyone rotates back to the queue\n'
                    '• Coach manually ejects → stint ends, points recorded as-is\n'
                    '• Next players step up immediately\n\n'
                    'Before you start, agree on:\n'
                    '• Who serves each rally\n'
                    '• Whether to use Strike Points and what the target should be\n\n'
                    'Add your players, set a session timer, and go.',
              ),
              _TypeTile(
                icon:         Icons.pets_rounded,
                color:        AppColors.gold,
                gradientEnd:  AppColors.goldGradientEnd,
                name:         'Doghouse',
                description:  l10n.modeDoghouseDesc,
                count:        _doghouseCount,
                onTap:        _openDoghouseHub,
                learnMoreUrl: AppLinks.modeDoghouse,
                helpText:
                    'Doghouse is a fast, competitive tournament where the action never stops. '
                    'One team battles from the doghouse — score enough points to escape and make '
                    'way for the next challengers. Hit your loss limit first and you\'re out.\n\n'
                    'Short format, high intensity — great as a session warm-up or a standalone competition.\n\n'
                    'Fair by design. TournaQ\'s Automated assignment ensures everyone plays with and '
                    'against different people, keeping wait times low and avoiding repeat pairings. '
                    'Because matchups stay balanced throughout the session, the final standings are a '
                    'genuine reflection of how each player performed — not just who got the easier draw.\n\n'
                    'How a game works:\n'
                    '• Win a rally → score a point\n'
                    '• Lose a rally → game lost, point score resets\n'
                    '• Reach your Escape Points target → escaped, back to the queue\n'
                    '• Hit the Loss Limit → ejected, next team steps in\n\n'
                    'Before you start, agree on:\n'
                    '• Which team serves each rally\n'
                    '• Escape Points and Loss Limit settings\n\n'
                    'Add your players, set a session timer, and go.',
              ),
            ]),

            // ── Team Competitions ──────────────────────────────────────
            const SizedBox(height: 24),
            _sectionHeader(l10n.tournamentsSectionTeam, Icons.groups_rounded),
            const SizedBox(height: 12),
            Column(children: [
              _TypeTile(
                icon:         Icons.table_chart_rounded,
                color:        AppColors.olive,
                gradientEnd:  AppColors.oliveMedium,
                name:         'League',
                description:  l10n.modeLeagueDesc,
                comingSoon:   true,
                onTap: () => _openComingSoon(
                    'League / Round Robin',
                    l10n.modeLeagueShortDesc),
                learnMoreUrl: AppLinks.featuresPage,
                helpText:     'Detailed description coming soon.',
              ),
              _TypeTile(
                icon:         Icons.account_tree_rounded,
                iconAngle:    pi,
                color:        AppColors.gold,
                gradientEnd:  AppColors.goldGradientEnd,
                name:         'Single Elimination',
                description:  l10n.modeSingleElimDesc,
                count:        _koBracketCount,
                onTap:        _openKoBracketHub,
                learnMoreUrl: AppLinks.modeKoSystem,
                helpText:     'Detailed description coming soon.',
              ),
              _TypeTile(
                icon:         Icons.device_hub_rounded,
                color:        AppColors.tertiary,
                gradientEnd:  const Color(0xFF6D4C2E),
                name:         'Double Elimination',
                description:  l10n.modeDoubleElimDesc,
                comingSoon:   true,
                onTap: () => _openComingSoon(
                    'Double Elimination',
                    l10n.modeDoubleElimShortDesc),
                learnMoreUrl: AppLinks.featuresPage,
                helpText:     'Detailed description coming soon.',
              ),
              _TypeTile(
                icon:         Icons.stacked_bar_chart_rounded,
                color:        const Color(0xFF00897B),
                gradientEnd:  const Color(0xFF00695C),
                name:         'Group + SE',
                description:  l10n.modeGroupSeDesc,
                comingSoon:   true,
                onTap: () => _openComingSoon(
                    'Group + Single Elimination',
                    l10n.modeGroupSeShortDesc),
                learnMoreUrl: AppLinks.featuresPage,
                helpText:     'Detailed description coming soon.',
              ),
              _TypeTile(
                icon:         Icons.stacked_line_chart_rounded,
                color:        const Color(0xFF6D4C41),
                gradientEnd:  const Color(0xFF4E342E),
                name:         'Group + DE',
                description:  l10n.modeGroupDeDesc,
                comingSoon:   true,
                onTap: () => _openComingSoon(
                    'Group + Double Elimination',
                    l10n.modeGroupDeShortDesc),
                learnMoreUrl: AppLinks.featuresPage,
                helpText:     'Detailed description coming soon.',
              ),
              _TypeTile(
                icon:         Icons.swap_vert_rounded,
                color:        const Color(0xFF00897B),
                gradientEnd:  const Color(0xFF00695C),
                name:         'Swiss System',
                description:  l10n.modeSwissDesc,
                comingSoon:   true,
                onTap: () => _openComingSoon(
                    'Swiss System',
                    l10n.modeSwissShortDesc),
                learnMoreUrl: AppLinks.featuresPage,
                helpText:     'Detailed description coming soon.',
              ),
            ]),

            // ── History shortcut ───────────────────────────────────────
            const SizedBox(height: 28),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _sectionHeader(l10n.tournamentsSectionHistory, Icons.history_rounded),
                const Spacer(),
                if (_scrambleCount + _kotcCount + _doghouseCount + _koBracketCount > 0)
                  TextButton(
                    onPressed: _deleteAllHistory,
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    child: Text(l10n.tournamentsDeleteAll, style: const TextStyle(fontSize: 13)),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            _HistoryShortcutTile(
              label: l10n.tournamentsAllLabel,
              count: _scrambleCount + _kotcCount + _doghouseCount,
              onTap: _openHistory,
            ),
            const SizedBox(height: 6),
            _HistoryShortcutTile(
              label:     'Social Scrambles',
              count:     _scrambleCount,
              typeColor: AppColors.gold,
              typeIcon:  Icons.shuffle_rounded,
              onTap: () => _openHistory(filter: TournamentFilter.scramble),
            ),
            const SizedBox(height: 6),
            _HistoryShortcutTile(
              label:     'King of the Court',
              count:     _kotcCount,
              typeColor: AppColors.gold,
              typeIcon:  Icons.workspace_premium_rounded,
              onTap: () => _openHistory(filter: TournamentFilter.kingOfTheCourt),
            ),
            const SizedBox(height: 6),
            _HistoryShortcutTile(
              label:     'Doghouse',
              count:     _doghouseCount,
              typeColor: AppColors.gold,
              typeIcon:  Icons.pets_rounded,
              onTap: () => _openHistory(filter: TournamentFilter.doghouse),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title, IconData icon) => Row(
        children: [
          Icon(icon, size: 15, color: AppColors.olive),
          const SizedBox(width: 6),
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.olive,
              letterSpacing: 0.4,
            ),
          ),
        ],
      );
}

// ── Type tile ─────────────────────────────────────────────────────────────────

class _TypeTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color gradientEnd;
  final String name;
  final String description;
  final int count;
  final bool comingSoon;
  final VoidCallback onTap;
  final String? helpText;
  final String? learnMoreUrl;
  final double iconAngle;

  const _TypeTile({
    required this.icon,
    required this.color,
    required this.gradientEnd,
    required this.name,
    required this.description,
    required this.onTap,
    this.count = 0,
    this.comingSoon = false,
    this.helpText,
    this.learnMoreUrl,
    this.iconAngle = 0,
  });

  void _showHelp(BuildContext context) {
    final text = helpText ?? 'Detailed description coming soon.';
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
        actionsPadding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        title: Text(name,
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.w800)),
        content: SingleChildScrollView(
          child: Text(
            text,
            style: const TextStyle(
                fontSize: 14, color: Colors.black54, height: 1.6),
          ),
        ),
        actions: [
          if (learnMoreUrl != null)
            TextButton(
              onPressed: () => openExternalUrl(ctx, learnMoreUrl!),
              child: const Text('Learn more'),
            ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Got it',
                style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final gradientColors = comingSoon
        ? [Colors.grey.shade400, Colors.grey.shade600]
        : [color, gradientEnd];
    final shadowColor = comingSoon ? Colors.grey : color;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: shadowColor.withValues(alpha: 0.28),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      shape: BoxShape.circle,
                    ),
                    child: Transform.rotate(
                      angle: iconAngle,
                      child: Icon(icon, color: Colors.white, size: 26),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(right: 70),
                          child: Text(
                            name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 19,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.1,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          description,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.80),
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 12,
              right: 12,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (comingSoon)
                    Container(
                      margin: const EdgeInsets.only(right: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.20),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Soon',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    )
                  else if (count > 0)
                    Container(
                      margin: const EdgeInsets.only(right: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.20),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$count',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  GestureDetector(
                    onTap: () => _showHelp(context),
                    child: Icon(
                      Icons.info_outline_rounded,
                      size: 20,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── History shortcut tile ─────────────────────────────────────────────────────

class _HistoryShortcutTile extends StatelessWidget {
  final String label;
  final int count;
  final Color? typeColor;
  final IconData? typeIcon;
  final VoidCallback onTap;

  const _HistoryShortcutTile({
    required this.label,
    required this.count,
    required this.onTap,
    this.typeColor,
    this.typeIcon,
  });

  @override
  Widget build(BuildContext context) {
    final color = typeColor ?? AppColors.olive;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade200),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(typeIcon ?? Icons.history_rounded, size: 18, color: color),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (count > 0)
              Text(
                '$count',
                style: TextStyle(
                    fontSize: 13,
                    color: color,
                    fontWeight: FontWeight.w700),
              ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right_rounded,
                size: 18, color: Colors.black26),
          ],
        ),
      ),
    );
  }
}
