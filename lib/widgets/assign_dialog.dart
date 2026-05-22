import 'package:flutter/material.dart';

/// Shows a dropdown-based assignment dialog.
/// Returns the selected ID on confirm, null on cancel or if no items.
Future<String?> showAssignDialog({
  required BuildContext context,
  required String title,
  required List<({String id, String name})> items,
  String emptyMessage = 'Nothing available to assign.',
}) async {
  if (items.isEmpty) {
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(emptyMessage)));
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
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text('Delete $label?'),
      content: const Text('This cannot be undone.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red[400],
            foregroundColor: Colors.white,
          ),
          child: const Text('Delete'),
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
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(_selected),
          child: const Text('Assign'),
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
