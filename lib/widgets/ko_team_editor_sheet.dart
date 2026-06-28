import 'package:flutter/material.dart';
import '../app/app_colors.dart';
import '../l10n/app_localizations.dart';
import '../models/group.dart';
import '../models/ko_bracket_tournament.dart';
import '../models/player.dart';
import '../models/team.dart';
import 'group_picker_sheet.dart';
import 'sheet_helpers.dart';
import '../utils/team_name_generator.dart';

const _kGold      = AppColors.gold;
const _kGoldDark  = AppColors.goldDark;
const _kGoldCream = AppColors.goldCream;
const _kOlive     = AppColors.olive;

enum _EditorMode { choice, create, import }

// ── Team editor sheet ─────────────────────────────────────────────────────────

class KoTeamEditorSheet extends StatefulWidget {
  final KoTeam team;
  final List<Player> existingPlayers;
  final List<Team> existingTeams;
  final List<Group> existingGroups;
  final KoBracketGenerationMode generationMode;
  final Player Function(String name) onCreatePlayer;
  final void Function(KoTeam) onSave;
  final String Function(String name, List<String> linkedPlayerIds) onCreateTeam;
  final void Function(String id, String name, int? skillRating)? onUpdatePlayer;

  const KoTeamEditorSheet({
    super.key,
    required this.team,
    required this.existingPlayers,
    required this.existingTeams,
    required this.existingGroups,
    required this.generationMode,
    required this.onCreatePlayer,
    required this.onSave,
    required this.onCreateTeam,
    this.onUpdatePlayer,
  });

  @override
  State<KoTeamEditorSheet> createState() => _KoTeamEditorSheetState();
}

class _KoTeamEditorSheetState extends State<KoTeamEditorSheet> {
  _EditorMode _mode = _EditorMode.choice;
  bool _fromImport  = false;
  String? _hubTeamId;
  String? _importGroupId;
  late final TextEditingController _nameCtrl;
  late List<KoPlayerSnapshot> _players;
  final _teamSearchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final initialName = widget.team.hubTeamId == null
        ? TeamNameGenerator.randomName()
        : widget.team.name;
    _nameCtrl = TextEditingController(text: initialName);
    _players  = List.from(widget.team.players);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _teamSearchCtrl.dispose();
    super.dispose();
  }

  void _importGlobalTeam(Team team) {
    final slots   = _players.length;
    final matched = <KoPlayerSnapshot>[];
    for (final uid in team.userIds) {
      if (matched.length >= slots) break;
      final player =
          widget.existingPlayers.where((p) => p.id == uid).firstOrNull;
      if (player != null) {
        matched.add(KoPlayerSnapshot(
          appPlayerId: player.id,
          name: player.name,
          skillRating: player.skillRating,
        ));
      }
    }
    while (matched.length < slots) {
      matched.add(KoPlayerSnapshot(
          appPlayerId: '', name: 'Player ${matched.length + 1}'));
    }
    setState(() {
      _nameCtrl.text = team.name;
      _players       = matched;
      _mode          = _EditorMode.create;
      _fromImport    = true;
      _hubTeamId     = team.id;
      _teamSearchCtrl.clear();
    });
  }

  void _save() {
    final name = _nameCtrl.text.trim().isEmpty
        ? widget.team.name
        : _nameCtrl.text.trim();
    String? resolvedHubTeamId = _hubTeamId;
    if (!_fromImport) {
      final linkedIds = _players
          .where((p) => p.appPlayerId.isNotEmpty)
          .map((p) => p.appPlayerId)
          .toList();
      resolvedHubTeamId = widget.onCreateTeam(name, linkedIds);
    }
    widget.onSave(widget.team.copyWith(
      name: name,
      players: _players,
      hubTeamId: resolvedHubTeamId,
    ));
    Navigator.of(context).pop();
  }

  void _showSlotPicker(int slotIndex) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => KoSlotPickerSheet(
        slotIndex: slotIndex,
        currentPlayer: _players[slotIndex],
        existingPlayers: widget.existingPlayers,
        existingGroups: widget.existingGroups,
        onCreatePlayer: widget.onCreatePlayer,
        onUpdatePlayer: widget.onUpdatePlayer,
        onPick: (s) => setState(() => _players[slotIndex] = s),
        onClear: () => setState(() => _players[slotIndex] = KoPlayerSnapshot(
              appPlayerId: '', name: 'Player ${slotIndex + 1}',
            )),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return TournaQSheet(
      body: switch (_mode) {
        _EditorMode.choice => _buildChoice(l10n),
        _EditorMode.create => _buildCreate(l10n),
        _EditorMode.import => _buildImport(l10n),
      },
    );
  }

  Widget _buildChoice(AppLocalizations l10n) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.koEditTeam,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(l10n.koTeamSetupSubtitle,
              style: const TextStyle(fontSize: 13, color: Colors.black54)),
          const SizedBox(height: 20),
          _choiceTile(
            icon: Icons.edit_rounded, color: _kOlive,
            title: l10n.koCreateNew,
            subtitle: l10n.koCreateNewSubtitle,
            onTap: () => setState(() => _mode = _EditorMode.create),
          ),
          const SizedBox(height: 12),
          if (widget.existingTeams.isNotEmpty)
            _choiceTile(
              icon: Icons.groups_rounded, color: _kGold,
              title: l10n.koImportFromHub,
              subtitle: l10n.koImportFromHubSubtitle,
              onTap: () => setState(() => _mode = _EditorMode.import),
            )
          else
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(children: [
                Icon(Icons.groups_rounded, size: 20, color: Colors.grey.shade400),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l10n.koNoTeamsInHub,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
                ),
              ]),
            ),
        ],
      ),
    );
  }

  Widget _choiceTile({
    required IconData icon, required Color color,
    required String title, required String subtitle, required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w700, color: color)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: const TextStyle(fontSize: 12, color: Colors.black54)),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: color, size: 20),
        ]),
      ),
    );
  }

  Widget _buildCreate(AppLocalizations l10n) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(children: [
            GestureDetector(
              onTap: () => setState(() => _mode = _EditorMode.choice),
              child: const Icon(Icons.arrow_back_rounded,
                  size: 20, color: Colors.black54),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(l10n.koEditTeam,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            ),
            TextButton(
              onPressed: _save,
              style: TextButton.styleFrom(foregroundColor: _kGold),
              child: Text(l10n.btnSave,
                  style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
          ]),
          const SizedBox(height: 16),
          Text(l10n.setupTeamNameHint,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.black54)),
          const SizedBox(height: 6),
          TextField(
            controller: _nameCtrl,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              border: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(10))),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              suffixIcon: IconButton(
                icon: const Icon(Icons.shuffle_rounded, size: 20),
                color: _kOlive,
                tooltip: 'Random name',
                onPressed: () => setState(() {
                  _nameCtrl.text = TeamNameGenerator.randomName(
                    excluding: _nameCtrl.text.trim().isEmpty
                        ? null
                        : _nameCtrl.text.trim(),
                  );
                }),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(l10n.koPlayersSection,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.black54)),
          const SizedBox(height: 8),
          ..._players.asMap().entries.map((e) {
            final i              = e.key;
            final p              = e.value;
            final isLinked       = p.appPlayerId.isNotEmpty;
            final needsAttention =
                widget.generationMode == KoBracketGenerationMode.seeded &&
                    (!isLinked || p.skillRating == null);
            return InkWell(
              onTap: () => _showSlotPicker(i),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: needsAttention
                        ? Colors.red.shade300
                        : Colors.grey.shade200,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor:
                        isLinked ? _kOlive : Colors.grey.shade300,
                    child: Text(
                      p.name.isNotEmpty ? p.name[0].toUpperCase() : '?',
                      style: const TextStyle(
                          fontSize: 11,
                          color: Colors.white,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p.name,
                            style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600)),
                        if (isLinked && p.skillRating != null)
                          Text(l10n.koSkillRating(p.skillRating!),
                              style: const TextStyle(
                                  fontSize: 11, color: Colors.black45))
                        else if (isLinked)
                          Text(l10n.koUnrated,
                              style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.orange.shade700))
                        else
                          Text(l10n.koTapToAssign,
                              style: const TextStyle(
                                  fontSize: 11, color: Colors.black38)),
                      ],
                    ),
                  ),
                  Icon(
                    isLinked
                        ? Icons.edit_rounded
                        : Icons.add_circle_outline_rounded,
                    size: 16,
                    color: isLinked ? Colors.black38 : _kGold,
                  ),
                ]),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildImport(AppLocalizations l10n) {
    final query          = _teamSearchCtrl.text.toLowerCase();
    final relevantGroups = widget.existingGroups
        .where((c) => widget.existingTeams.any((t) => c.teamIds.contains(t.id)))
        .toList();
    final filtered = widget.existingTeams.where((t) {
      final matchesGroup = _importGroupId == null ||
          widget.existingGroups
              .any((c) => c.id == _importGroupId && c.teamIds.contains(t.id));
      final matchesQuery = query.isEmpty || t.name.toLowerCase().contains(query);
      return matchesGroup && matchesQuery;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          child: Row(children: [
            GestureDetector(
              onTap: () => setState(() {
                _mode = _EditorMode.choice;
                _teamSearchCtrl.clear();
              }),
              child: const Icon(Icons.arrow_back_rounded,
                  size: 20, color: Colors.black54),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(l10n.koImportTitle,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w800)),
            ),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(children: [
              if (relevantGroups.isNotEmpty)
                GestureDetector(
                  onTap: () async {
                    final picked = await showModalBottomSheet<String>(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => GroupPickerSheet(
                        groups: relevantGroups,
                        selectedId: _importGroupId,
                      ),
                    );
                    if (picked != null) {
                      setState(() =>
                          _importGroupId = picked.isEmpty ? null : picked);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 10),
                    decoration: BoxDecoration(
                      color: _importGroupId != null
                          ? _kGoldCream
                          : Colors.grey.shade50,
                      borderRadius: const BorderRadius.horizontal(
                          left: Radius.circular(11)),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.home_rounded,
                          size: 14,
                          color: _importGroupId != null
                              ? _kGoldDark
                              : Colors.black45),
                      const SizedBox(width: 4),
                      Text(
                        _importGroupId == null
                            ? l10n.filterClub
                            : relevantGroups
                                .firstWhere((c) => c.id == _importGroupId)
                                .name,
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: _importGroupId != null
                                ? _kGoldDark
                                : Colors.black45),
                      ),
                      const SizedBox(width: 2),
                      Icon(Icons.arrow_drop_down_rounded,
                          size: 16,
                          color: _importGroupId != null
                              ? _kGoldDark
                              : Colors.black45),
                    ]),
                  ),
                ),
              if (relevantGroups.isNotEmpty)
                Container(width: 1, height: 36, color: Colors.grey.shade200),
              Expanded(
                child: TextField(
                  controller: _teamSearchCtrl,
                  autofocus: true,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: l10n.setupSearchTeamsHint,
                    prefixIcon: const Icon(Icons.search_rounded,
                        size: 18, color: Colors.black45),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 4, vertical: 10),
                  ),
                ),
              ),
            ]),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Text(l10n.koNoTeamsFound,
                      style: const TextStyle(
                          fontSize: 13, color: Colors.black38)))
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                  itemCount: filtered.length,
                  itemBuilder: (_, i) {
                    final t  = filtered[i];
                    final pc = t.userIds.length;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(color: Colors.grey.shade200)),
                      elevation: 0,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _kGoldCream,
                          child: Text(
                            t.name.isNotEmpty
                                ? t.name[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: _kGoldDark,
                                fontSize: 14),
                          ),
                        ),
                        title: Text(t.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 14)),
                        subtitle: pc > 0
                            ? Text(l10n.koPlayerCount(pc),
                                style: const TextStyle(fontSize: 12))
                            : null,
                        trailing: const Icon(Icons.download_rounded,
                            color: _kGold, size: 20),
                        onTap: () => _importGlobalTeam(t),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

// ── Slot picker sheet (player slots within a team) ────────────────────────────

class KoSlotPickerSheet extends StatefulWidget {
  final int slotIndex;
  final KoPlayerSnapshot currentPlayer;
  final List<Player> existingPlayers;
  final List<Group> existingGroups;
  final Player Function(String name) onCreatePlayer;
  final void Function(KoPlayerSnapshot) onPick;
  final VoidCallback onClear;
  final void Function(String id, String name, int? skillRating)? onUpdatePlayer;

  const KoSlotPickerSheet({
    super.key,
    required this.slotIndex,
    required this.currentPlayer,
    required this.existingPlayers,
    required this.existingGroups,
    required this.onCreatePlayer,
    required this.onPick,
    required this.onClear,
    this.onUpdatePlayer,
  });

  @override
  State<KoSlotPickerSheet> createState() => KoSlotPickerSheetState();
}

class KoSlotPickerSheetState extends State<KoSlotPickerSheet> {
  final _newNameCtrl = TextEditingController();
  final _searchCtrl  = TextEditingController();
  late final TextEditingController _editNameCtrl;
  String? _playerGroupId;
  late List<Player> _players;

  @override
  void initState() {
    super.initState();
    _players      = List.from(widget.existingPlayers);
    _editNameCtrl = TextEditingController(text: widget.currentPlayer.name);
  }

  @override
  void dispose() {
    _newNameCtrl.dispose();
    _searchCtrl.dispose();
    _editNameCtrl.dispose();
    super.dispose();
  }

  void _createNew() {
    final name = _newNameCtrl.text.trim();
    if (name.isEmpty) return;
    final player = widget.onCreatePlayer(name);
    setState(() => _players.add(player));
    widget.onPick(KoPlayerSnapshot(
      appPlayerId: player.id,
      name: player.name,
      skillRating: player.skillRating,
    ));
    Navigator.of(context).pop();
  }

  void _saveEdit() {
    final name = _editNameCtrl.text.trim();
    if (name.isEmpty) return;
    final current = widget.currentPlayer;
    widget.onUpdatePlayer?.call(current.appPlayerId, name, current.skillRating);
    widget.onPick(KoPlayerSnapshot(
      appPlayerId: current.appPlayerId,
      name: name,
      skillRating: current.skillRating,
    ));
    setState(() {
      final idx = _players.indexWhere((p) => p.id == current.appPlayerId);
      if (idx >= 0) _players[idx] = _players[idx].copyWith(name: name);
    });
    Navigator.of(context).pop();
  }

  void _showEditPlayer(
      BuildContext context, Player player, AppLocalizations l10n) {
    final nameCtrl = TextEditingController(text: player.name);
    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          title: Text(l10n.koEditPlayer,
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          content: TextField(
            controller: nameCtrl,
            textCapitalization: TextCapitalization.words,
            autofocus: true,
            onChanged: (_) => setDlgState(() {}),
            decoration: InputDecoration(
              isDense: true,
              labelText: l10n.koPlayerNameLabel,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10)),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 10),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(l10n.btnCancel),
            ),
            TextButton(
              onPressed: nameCtrl.text.trim().isEmpty
                  ? null
                  : () {
                      final name = nameCtrl.text.trim();
                      widget.onUpdatePlayer
                          ?.call(player.id, name, player.skillRating);
                      setState(() {
                        final idx =
                            _players.indexWhere((p) => p.id == player.id);
                        if (idx >= 0) {
                          _players[idx] = player.copyWith(name: name);
                        }
                      });
                      Navigator.of(ctx).pop();
                    },
              style: TextButton.styleFrom(foregroundColor: _kGold),
              child: Text(l10n.btnSave,
                  style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n           = AppLocalizations.of(context)!;
    final isLinked       = widget.currentPlayer.appPlayerId.isNotEmpty;
    final query          = _searchCtrl.text.toLowerCase();
    final relevantGroups = widget.existingGroups
        .where((c) => _players.any((p) => c.playerIds.contains(p.id)))
        .toList();
    final filtered = _players.where((p) {
      final matchesGroup = _playerGroupId == null ||
          widget.existingGroups.any(
              (c) => c.id == _playerGroupId && c.playerIds.contains(p.id));
      final matchesQuery =
          query.isEmpty || p.name.toLowerCase().contains(query);
      return matchesGroup && matchesQuery;
    }).toList();

    return TournaQSheet(
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(children: [
              Expanded(
                child: Text(l10n.setupPlayerN(widget.slotIndex + 1),
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w800)),
              ),
              if (isLinked)
                TextButton.icon(
                  onPressed: () {
                    widget.onClear();
                    Navigator.of(context).pop();
                  },
                  icon: const Icon(Icons.close_rounded, size: 14),
                  label: Text(l10n.btnClear,
                      style: const TextStyle(fontSize: 13)),
                  style: TextButton.styleFrom(
                      foregroundColor: Colors.red.shade400),
                ),
            ]),
            const SizedBox(height: 20),

            // ── A: Edit current player (only when linked) ─────────────
            if (isLinked) ...[
              _sectionLabel(l10n.koSectionAEditPlayer, _kOlive),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(
                  child: TextField(
                    controller: _editNameCtrl,
                    textCapitalization: TextCapitalization.words,
                    onChanged: (_) => setState(() {}),
                    onSubmitted: (_) => _saveEdit(),
                    decoration: InputDecoration(
                      isDense: true,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _editNameCtrl.text.trim().isNotEmpty
                      ? _saveEdit
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kOlive,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text(l10n.btnSave,
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                ),
              ]),
              const SizedBox(height: 20),
            ],

            // ── B (or A): New Player ──────────────────────────────────
            _sectionLabel(
              isLinked ? l10n.koSectionBNewPlayer : l10n.koSectionANewPlayer,
              _kOlive,
            ),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(
                child: TextField(
                  controller: _newNameCtrl,
                  textCapitalization: TextCapitalization.words,
                  onChanged: (_) => setState(() {}),
                  onSubmitted: (_) => _createNew(),
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: 'Enter player name…',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _newNameCtrl.text.trim().isNotEmpty
                    ? _createNew
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kOlive,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: Text(l10n.btnCreate,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
              ),
            ]),
            const SizedBox(height: 20),

            // ── C (or B): From Players Hub ────────────────────────────
            _sectionLabel(
              isLinked ? l10n.koSectionCFromHub : l10n.koFromPlayersHub,
              _kGold,
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(children: [
                if (relevantGroups.isNotEmpty)
                  GestureDetector(
                    onTap: () async {
                      final picked = await showModalBottomSheet<String>(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => GroupPickerSheet(
                          groups: relevantGroups,
                          selectedId: _playerGroupId,
                        ),
                      );
                      if (picked != null) {
                        setState(() =>
                            _playerGroupId = picked.isEmpty ? null : picked);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 10),
                      decoration: BoxDecoration(
                        color: _playerGroupId != null
                            ? _kGoldCream
                            : Colors.grey.shade50,
                        borderRadius: const BorderRadius.horizontal(
                            left: Radius.circular(11)),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.home_rounded,
                            size: 14,
                            color: _playerGroupId != null
                                ? _kGoldDark
                                : Colors.black45),
                        const SizedBox(width: 4),
                        Text(
                          _playerGroupId == null
                              ? l10n.filterClub
                              : relevantGroups
                                  .firstWhere((c) => c.id == _playerGroupId)
                                  .name,
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: _playerGroupId != null
                                  ? _kGoldDark
                                  : Colors.black45),
                        ),
                        const SizedBox(width: 2),
                        Icon(Icons.arrow_drop_down_rounded,
                            size: 16,
                            color: _playerGroupId != null
                                ? _kGoldDark
                                : Colors.black45),
                      ]),
                    ),
                  ),
                if (relevantGroups.isNotEmpty)
                  Container(width: 1, height: 36, color: Colors.grey.shade200),
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: l10n.setupSearchPlayersHint,
                      prefixIcon: const Icon(Icons.search_rounded,
                          size: 18, color: Colors.black45),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 10),
                    ),
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 6),
            if (_players.isEmpty)
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(l10n.koNoPlayersInHub,
                    style: const TextStyle(
                        fontSize: 12, color: Colors.black38)),
              )
            else if (filtered.isEmpty)
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(l10n.koNoPlayersFound,
                    style: const TextStyle(
                        fontSize: 12, color: Colors.black38)),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filtered.length.clamp(0, 20),
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (_, i) {
                  final player   = filtered[i];
                  final isCurrent =
                      widget.currentPlayer.appPlayerId == player.id;
                  return ListTile(
                    dense: true,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 4),
                    leading: CircleAvatar(
                      radius: 14,
                      backgroundColor:
                          isCurrent ? _kOlive : _kGoldCream,
                      child: Text(
                        player.name[0].toUpperCase(),
                        style: TextStyle(
                            fontSize: 11,
                            color: isCurrent ? Colors.white : _kGoldDark,
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                    title:
                        Text(player.name, style: const TextStyle(fontSize: 13)),
                    subtitle: player.skillRating != null
                        ? Text(l10n.koSkillRating(player.skillRating!),
                            style: const TextStyle(fontSize: 11))
                        : Text(l10n.koUnrated,
                            style: const TextStyle(
                                fontSize: 11, color: Colors.orange)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.onUpdatePlayer != null)
                          GestureDetector(
                            onTap: () =>
                                _showEditPlayer(context, player, l10n),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 6),
                              child: Icon(Icons.edit_rounded,
                                  size: 16, color: Colors.black38),
                            ),
                          ),
                        isCurrent
                            ? const Icon(Icons.check_rounded,
                                color: _kOlive, size: 18)
                            : const Icon(Icons.add_circle_outline_rounded,
                                color: _kGold, size: 20),
                      ],
                    ),
                    onTap: isCurrent
                        ? null
                        : () {
                            widget.onPick(KoPlayerSnapshot(
                              appPlayerId: player.id,
                              name: player.name,
                              skillRating: player.skillRating,
                            ));
                            Navigator.of(context).pop();
                          },
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String label, Color color) => Row(children: [
        Container(
          width: 4,
          height: 14,
          decoration: BoxDecoration(
              color: color, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 8),
        Text(label,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: color,
                letterSpacing: 0.3)),
        const SizedBox(width: 8),
        Expanded(
            child: Divider(height: 1, color: color.withValues(alpha: 0.3))),
      ]);
}
