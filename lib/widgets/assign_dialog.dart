import 'package:flutter/material.dart';
import '../app/app_colors.dart';
import '../l10n/app_localizations.dart';
import '../models/group.dart';
import 'group_picker_sheet.dart';

/// Shows a bottom sheet with a live-search field and a tappable list.
/// Returns the selected ID, or null if dismissed.
Future<String?> showSearchPickerSheet({
  required BuildContext context,
  required String title,
  required List<({String id, String name})> items,
  String? emptyMessage,
}) async {
  if (items.isEmpty) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(emptyMessage ?? AppLocalizations.of(context)!.assignNothingAvailable)),
      );
    }
    return null;
  }
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _SearchPickerSheet(title: title, items: items),
  );
}

class _SearchPickerSheet extends StatefulWidget {
  final String title;
  final List<({String id, String name})> items;
  const _SearchPickerSheet({required this.title, required this.items});
  @override
  State<_SearchPickerSheet> createState() => _SearchPickerSheetState();
}

class _SearchPickerSheetState extends State<_SearchPickerSheet> {
  final _searchCtrl = TextEditingController();
  List<({String id, String name})> _filtered = [];

  @override
  void initState() {
    super.initState();
    _filtered = widget.items;
    _searchCtrl.addListener(_onSearch);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearch() {
    final q = _searchCtrl.text.toLowerCase();
    setState(() {
      _filtered = q.isEmpty
          ? widget.items
          : widget.items.where((i) => i.name.toLowerCase().contains(q)).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    return Container(
      margin: EdgeInsets.only(bottom: mq.viewInsets.bottom),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      constraints: BoxConstraints(maxHeight: mq.size.height * 0.75),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 10, bottom: 4),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.black12,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.title,
                    style: const TextStyle(
                        fontSize: 17, fontWeight: FontWeight.w800)),
                const SizedBox(height: 12),
                TextField(
                  controller: _searchCtrl,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'Search…',
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    isDense: true,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Flexible(
            child: _filtered.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(32),
                    child: Text('No matches',
                        style: TextStyle(color: Colors.black45)),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: _filtered.length,
                    itemBuilder: (ctx, i) {
                      final item = _filtered[i];
                      return ListTile(
                        leading: const Icon(Icons.person_rounded,
                            color: AppColors.olive),
                        title: Text(item.name),
                        onTap: () => Navigator.of(ctx).pop(item.id),
                      );
                    },
                  ),
          ),
          SizedBox(height: mq.padding.bottom + 8),
        ],
      ),
    );
  }
}

/// Shows a bottom sheet with a group-filter button + inline search for picking a team.
/// Returns the selected team ID, or null if dismissed.
Future<String?> showTeamPickerSheet({
  required BuildContext context,
  required String title,
  required List<({String id, String name})> teams,
  required List<Group> groups,
}) async {
  if (teams.isEmpty) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.assignNothingAvailable)),
      );
    }
    return null;
  }
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _TeamPickerSheet(title: title, teams: teams, groups: groups),
  );
}

class _TeamPickerSheet extends StatefulWidget {
  final String title;
  final List<({String id, String name})> teams;
  final List<Group> groups;
  const _TeamPickerSheet({
    required this.title,
    required this.teams,
    required this.groups,
  });
  @override
  State<_TeamPickerSheet> createState() => _TeamPickerSheetState();
}

class _TeamPickerSheetState extends State<_TeamPickerSheet> {
  final _searchCtrl = TextEditingController();
  String? _selectedGroupId;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<({String id, String name})> get _filtered {
    final q = _searchCtrl.text.toLowerCase();
    var result = widget.teams;
    if (_selectedGroupId != null) {
      final group = widget.groups.firstWhere((g) => g.id == _selectedGroupId);
      result = result.where((t) => group.teamIds.contains(t.id)).toList();
    }
    if (q.isNotEmpty) {
      result = result.where((t) => t.name.toLowerCase().contains(q)).toList();
    }
    return result;
  }

  Future<void> _pickGroup() async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => GroupPickerSheet(
        groups: widget.groups,
        selectedId: _selectedGroupId,
      ),
    );
    if (picked != null) {
      setState(() => _selectedGroupId = picked.isEmpty ? null : picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final hasGroups = widget.groups.isNotEmpty;
    final filtered = _filtered;
    final groupName = _selectedGroupId == null
        ? null
        : widget.groups.firstWhere((g) => g.id == _selectedGroupId).name;

    return Container(
      margin: EdgeInsets.only(bottom: mq.viewInsets.bottom),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      constraints: BoxConstraints(maxHeight: mq.size.height * 0.75),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 10, bottom: 4),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.black12,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(widget.title,
                      style: const TextStyle(
                          fontSize: 17, fontWeight: FontWeight.w800)),
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(children: [
                    if (hasGroups) ...[
                      GestureDetector(
                        onTap: _pickGroup,
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
                              groupName ?? 'Group',
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
                      Container(
                          width: 1, height: 36, color: Colors.grey.shade200),
                    ],
                    Expanded(
                      child: TextField(
                        controller: _searchCtrl,
                        autofocus: true,
                        onChanged: (_) => setState(() {}),
                        decoration: const InputDecoration(
                          isDense: true,
                          hintText: 'Search teams…',
                          prefixIcon: Icon(Icons.search_rounded,
                              size: 18, color: Colors.black45),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 4, vertical: 10),
                        ),
                      ),
                    ),
                  ]),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Flexible(
            child: filtered.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(32),
                    child: Text('No matches',
                        style: TextStyle(color: Colors.black45)),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: filtered.length,
                    itemBuilder: (ctx, i) {
                      final item = filtered[i];
                      return ListTile(
                        leading: const Icon(Icons.group_rounded,
                            color: AppColors.olive),
                        title: Text(item.name),
                        onTap: () => Navigator.of(ctx).pop(item.id),
                      );
                    },
                  ),
          ),
          SizedBox(height: mq.padding.bottom + 8),
        ],
      ),
    );
  }
}

/// Shows a dropdown-based assignment dialog.
/// Returns the selected ID on confirm, null on cancel or if no items.
Future<String?> showAssignDialog({
  required BuildContext context,
  required String title,
  required List<({String id, String name})> items,
  String? emptyMessage,
}) async {
  if (items.isEmpty) {
    if (context.mounted) {
      final msg = emptyMessage ?? AppLocalizations.of(context)!.assignNothingAvailable;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(msg)));
    }
    return null;
  }
  return showDialog<String>(
    context: context,
    builder: (_) => _AssignDialog(title: title, items: items),
  );
}

/// Shows a confirmation dialog before a destructive delete.
/// Returns true only if the user confirms.
Future<bool> showConfirmDeleteDialog(
  BuildContext context,
  String label,
) async {
  final l10n = AppLocalizations.of(context)!;
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(l10n.dialogDeleteTitle(label)),
      content: Text(l10n.dialogDeleteBody),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text(l10n.btnCancel),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red[400],
            foregroundColor: Colors.white,
          ),
          child: Text(l10n.btnDelete),
        ),
      ],
    ),
  );
  return result == true;
}

class _AssignDialog extends StatefulWidget {
  final String title;
  final List<({String id, String name})> items;
  const _AssignDialog({required this.title, required this.items});
  @override
  State<_AssignDialog> createState() => _AssignDialogState();
}

class _AssignDialogState extends State<_AssignDialog> {
  late String _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.items.first.id;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: DropdownButtonFormField<String>(
        initialValue: _selected,
        items: widget.items
            .map((i) => DropdownMenuItem(value: i.id, child: Text(i.name)))
            .toList(),
        onChanged: (v) {
          if (v != null) setState(() => _selected = v);
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: Text(AppLocalizations.of(context)!.btnCancel),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(_selected),
          child: Text(AppLocalizations.of(context)!.btnAssign),
        ),
      ],
    );
  }
}

/// Builds a consistent PopupMenuItem with an icon and label.
PopupMenuItem<String> actionMenuItem(
  String value,
  IconData icon,
  String label, {
  bool destructive = false,
}) {
  final color = destructive ? Colors.red : null;
  return PopupMenuItem<String>(
    value: value,
    child: Row(children: [
      Icon(icon, size: 18, color: color ?? Colors.black87),
      const SizedBox(width: 10),
      Text(label, style: TextStyle(color: color)),
    ]),
  );
}
