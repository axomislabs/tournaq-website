import 'package:flutter/material.dart';
import '../app/app_colors.dart';
import '../l10n/app_localizations.dart';
import '../models/group.dart';
import '../models/player.dart';
import '../models/player_status.dart';
import 'group_picker_sheet.dart';
import 'sheet_helpers.dart';
import 'tournament_player_row.dart';

/// An entry shown in the optional "Players Added" section (KoC / DH).
class PlayerPickerEntry {
  final String id;
  final String name;
  final PlayerStatus status;

  const PlayerPickerEntry({
    required this.id,
    required this.name,
    required this.status,
  });
}

/// Reusable bottom-sheet for picking or adding tournament players.
///
/// Used by Social Scramble (single-pick: sheet closes on selection) and by
/// KoC / Doghouse (multi-add: sheet stays open, shows an "Added" list).
///
/// Callbacks return `true` to close the sheet or `false` to stay open.
class PlayerPickerSheet extends StatefulWidget {
  const PlayerPickerSheet({
    super.key,
    required this.title,
    required this.subtitle,
    required this.existingPlayers,
    required this.alreadyInIds,
    required this.nameHint,
    required this.onCreateByName,
    required this.onAddExisting,
    this.existingGroups = const [],
    this.addedPlayers,
    this.onRemoveAdded,
    this.onFillRandom,
    this.addedCountLabel,
    this.fillRandomLabel,
  });

  final String title;
  final String subtitle;

  final List<Player> existingPlayers;

  /// App-user IDs already in the tournament — excluded from the picker list.
  final Set<String> alreadyInIds;

  final String nameHint;

  /// Called with the typed name. Return `true` to close the sheet.
  final Future<bool> Function(String name) onCreateByName;

  /// Called with an existing player. Return `true` to close the sheet.
  final Future<bool> Function(String appUserId, String name) onAddExisting;

  final List<Group> existingGroups;

  // ── Optional "Players Added" section (KoC / DH only) ─────────────────────
  final List<PlayerPickerEntry>? addedPlayers;
  final void Function(String id)? onRemoveAdded;
  final VoidCallback? onFillRandom;
  final String? addedCountLabel;
  final String? fillRandomLabel;

  @override
  State<PlayerPickerSheet> createState() => _PlayerPickerSheetState();
}

class _PlayerPickerSheetState extends State<PlayerPickerSheet> {
  final _nameCtrl   = TextEditingController();
  final _searchCtrl = TextEditingController();
  bool _createOpen   = true;
  bool _existingOpen = false;
  String? _selectedGroupId;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleCreateByName(String raw) async {
    final name = raw.trim();
    if (name.isEmpty) return;
    final close = await widget.onCreateByName(name);
    if (!mounted) return;
    if (close) {
      Navigator.of(context).pop();
    } else {
      _nameCtrl.clear();
    }
  }

  Future<void> _handleAddExisting(String appUserId, String name) async {
    final close = await widget.onAddExisting(appUserId, name);
    if (close && mounted) Navigator.of(context).pop();
  }

  Widget _sectionHeader(String label, bool open, VoidCallback onToggle) =>
      InkWell(
        onTap: onToggle,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(children: [
            Expanded(
              child: Text(label,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w700)),
            ),
            Icon(
              open ? Icons.expand_less_rounded : Icons.expand_more_rounded,
              size: 18,
              color: Colors.black45,
            ),
          ]),
        ),
      );

  Widget _searchBar(List<Group> relevantGroups) => Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(children: [
          if (relevantGroups.isNotEmpty) ...[
            GestureDetector(
              onTap: () async {
                final picked = await showModalBottomSheet<String>(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => GroupPickerSheet(
                    groups: relevantGroups,
                    selectedId: _selectedGroupId,
                  ),
                );
                if (picked != null) {
                  setState(() =>
                      _selectedGroupId = picked.isEmpty ? null : picked);
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 10),
                decoration: BoxDecoration(
                  color: _selectedGroupId != null
                      ? AppColors.goldCream
                      : Colors.grey.shade50,
                  borderRadius: const BorderRadius.horizontal(
                      left: Radius.circular(11)),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.home_rounded,
                      size: 14,
                      color: _selectedGroupId != null
                          ? AppColors.goldDark
                          : Colors.black45),
                  const SizedBox(width: 4),
                  Text(
                    _selectedGroupId == null
                        ? 'Group'
                        : relevantGroups
                            .firstWhere((g) => g.id == _selectedGroupId)
                            .name,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: _selectedGroupId != null
                            ? AppColors.goldDark
                            : Colors.black45),
                  ),
                  const SizedBox(width: 2),
                  Icon(Icons.arrow_drop_down_rounded,
                      size: 16,
                      color: _selectedGroupId != null
                          ? AppColors.goldDark
                          : Colors.black45),
                ]),
              ),
            ),
            Container(width: 1, height: 36, color: Colors.grey.shade200),
          ],
          Expanded(
            child: TextField(
              controller: _searchCtrl,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context)!.setupSearchPlayersHint,
                isDense: true,
                prefixIcon: const Icon(Icons.search_rounded,
                    size: 18, color: Colors.black45),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 4, vertical: 10),
              ),
            ),
          ),
        ]),
      );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final query       = _searchCtrl.text.toLowerCase();
    final allExisting = widget.existingPlayers
        .where((p) => !widget.alreadyInIds.contains(p.id))
        .toList();
    final relevantGroups = widget.existingGroups
        .where((g) =>
            widget.existingPlayers.any((p) => g.playerIds.contains(p.id)))
        .toList();
    final filtered = allExisting.where((p) {
      final matchesGroup = _selectedGroupId == null ||
          widget.existingGroups.any(
              (g) => g.id == _selectedGroupId && g.playerIds.contains(p.id));
      final matchesQuery =
          query.isEmpty || p.name.toLowerCase().contains(query);
      return matchesGroup && matchesQuery;
    }).toList();

    return TournaQSheet(
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(widget.title,
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 2),
            Text(widget.subtitle,
                style: const TextStyle(fontSize: 12, color: Colors.black45)),
            const SizedBox(height: 16),

            // ── Create Player ────────────────────────────────────────────
            _sectionHeader(
              l10n.setupSectionCreatePlayer,
              _createOpen,
              () => setState(() => _createOpen = !_createOpen),
            ),
            if (_createOpen) ...[
              const SizedBox(height: 8),
              Row(children: [
                Expanded(
                  child: TextField(
                    controller: _nameCtrl,
                    autofocus: true,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      hintText: widget.nameHint,
                      isDense: true,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 12),
                    ),
                    onSubmitted: _handleCreateByName,
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => _handleCreateByName(_nameCtrl.text),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.olive,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 14),
                  ),
                  child: Text(l10n.btnAdd),
                ),
              ]),
              const SizedBox(height: 12),
            ],

            const Divider(height: 1),
            const SizedBox(height: 4),

            // ── Add Existing Players ─────────────────────────────────────
            _sectionHeader(
              l10n.setupAddExistingPlayers(allExisting.length),
              _existingOpen,
              () => setState(() => _existingOpen = !_existingOpen),
            ),
            if (_existingOpen) ...[
              const SizedBox(height: 6),
              if (allExisting.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(l10n.overviewAllPlayersAlready,
                      style: const TextStyle(
                          fontSize: 13, color: Colors.black38)),
                )
              else ...[
                _searchBar(relevantGroups),
                const SizedBox(height: 6),
                if (filtered.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(l10n.doghouseNoPlayersMatch,
                        style: const TextStyle(
                            color: Colors.black38, fontSize: 13)),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final p = filtered[i];
                      return ListTile(
                        dense: true,
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 4),
                        leading: CircleAvatar(
                          radius: 14,
                          backgroundColor: AppColors.oliveLight,
                          child: Text(
                            p.name.isNotEmpty
                                ? p.name[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.olive,
                            ),
                          ),
                        ),
                        title: Text(p.name,
                            style: const TextStyle(fontSize: 13)),
                        trailing: IconButton(
                          icon: const Icon(
                              Icons.add_circle_outline_rounded,
                              size: 20,
                              color: AppColors.olive),
                          onPressed: () =>
                              _handleAddExisting(p.id, p.name),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      );
                    },
                  ),
              ],
            ],

            // ── Players Added (KoC / DH only) ────────────────────────────
            if (widget.addedPlayers != null) ...[
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (widget.addedCountLabel != null)
                    Text(
                      widget.addedCountLabel!,
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.black54),
                    ),
                  if (widget.onFillRandom != null &&
                      widget.fillRandomLabel != null)
                    TextButton.icon(
                      onPressed: widget.onFillRandom,
                      icon: const Icon(Icons.shuffle_rounded, size: 16),
                      label: Text(widget.fillRandomLabel!),
                      style: TextButton.styleFrom(
                          foregroundColor: AppColors.olive),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              if (widget.addedPlayers!.isEmpty)
                Text(l10n.doghouseNoLatePlayersYet,
                    style: const TextStyle(
                        color: Colors.black38, fontSize: 13))
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: widget.addedPlayers!.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 4),
                  itemBuilder: (_, i) {
                    final entry = widget.addedPlayers![i];
                    return ListTile(
                      dense: true,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(color: Colors.grey.shade200),
                      ),
                      leading: CircleAvatar(
                        radius: 14,
                        backgroundColor: AppColors.goldCream,
                        child: Text(
                          entry.name.isNotEmpty
                              ? entry.name[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.goldDark,
                              fontWeight: FontWeight.w700),
                        ),
                      ),
                      title: Row(children: [
                        Text(entry.name,
                            style: const TextStyle(fontSize: 13)),
                        if (entry.status != PlayerStatus.active) ...[
                          const SizedBox(width: 6),
                          PlayerStatusChip(entry.status),
                        ],
                      ]),
                      trailing: widget.onRemoveAdded == null
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.close_rounded,
                                  size: 16, color: Colors.black38),
                              onPressed: () =>
                                  widget.onRemoveAdded!(entry.id),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                    );
                  },
                ),
            ],
          ],
        ),
      ),
    );
  }
}
