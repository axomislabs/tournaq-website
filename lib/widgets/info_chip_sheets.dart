import 'package:flutter/material.dart';
import '../app/app_colors.dart';
import '../l10n/app_localizations.dart';
import 'sheet_helpers.dart';

/// Generic mid-game edit sheets opened from a Match Controls [InfoChip]
/// (editable_info_chip.dart), shared by King of the Court and Doghouse.
/// Each returns the new value on Save (via `Navigator.pop(ctx, value)`) or
/// null if dismissed without saving.
Widget _sheetHeader(
  BuildContext context,
  BuildContext sheetContext,
  String title,
  VoidCallback onSave,
) {
  final l10n = AppLocalizations.of(context)!;
  return Row(children: [
    Expanded(
      child: Text(title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
    ),
    TextButton(
      onPressed: onSave,
      style: TextButton.styleFrom(foregroundColor: AppColors.goldDark),
      child: Text(l10n.btnSave,
          style: const TextStyle(fontWeight: FontWeight.w700)),
    ),
  ]);
}

Future<T?> showEnumPickerSheet<T>({
  required BuildContext context,
  required String title,
  String? helpText,
  required T initialValue,
  required List<DropdownMenuItem<T>> items,
}) {
  var value = initialValue;
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setSheet) => TournaQSheet(
        body: Padding(
          padding: EdgeInsets.fromLTRB(
              20, 8, 20, MediaQuery.of(ctx).viewInsets.bottom + 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              _sheetHeader(context, ctx, title, () => Navigator.of(ctx).pop(value)),
              const SizedBox(height: 20),
              DropdownButtonFormField<T>(
                initialValue: value,
                isDense: true,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
                  border:
                      OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                items: items,
                onChanged: (v) {
                  if (v != null) setSheet(() => value = v);
                },
              ),
              if (helpText != null) ...[
                const SizedBox(height: 12),
                Text(helpText,
                    style: const TextStyle(fontSize: 12, color: Colors.black45)),
              ],
            ],
          ),
        ),
      ),
    ),
  );
}

Future<int?> showNumericStepperSheet({
  required BuildContext context,
  required String title,
  String? helpText,
  required int initialValue,
  required List<int> presets,
  int min = 0,
  int max = 999,
  // Shown instead of the numeral when value == 0. Leave null for fields that
  // never mean "off" (e.g. escape points / loss limit, where min should be 1).
  String? offLabel,
}) {
  var value = initialValue;
  return showModalBottomSheet<int>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setSheet) {
        final isOff = offLabel != null && value == 0;
        return TournaQSheet(
          body: Padding(
            padding: EdgeInsets.fromLTRB(
                20, 8, 20, MediaQuery.of(ctx).viewInsets.bottom + 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                _sheetHeader(context, ctx, title, () => Navigator.of(ctx).pop(value)),
                const SizedBox(height: 20),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  IconButton.filled(
                    onPressed: value > min
                        ? () => setSheet(() => value = (value - 1).clamp(min, max))
                        : null,
                    icon: const Icon(Icons.remove_rounded),
                    style: IconButton.styleFrom(
                        backgroundColor: AppColors.goldCream,
                        foregroundColor: AppColors.goldDark),
                  ),
                  const SizedBox(width: 20),
                  SizedBox(
                    width: 64,
                    child: Text(
                      isOff ? offLabel : '$value',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: isOff ? 14 : 26,
                          fontWeight: FontWeight.w800,
                          color: isOff ? Colors.black45 : AppColors.goldDark),
                    ),
                  ),
                  const SizedBox(width: 20),
                  IconButton.filled(
                    onPressed: value < max
                        ? () => setSheet(() => value = (value + 1).clamp(min, max))
                        : null,
                    icon: const Icon(Icons.add_rounded),
                    style: IconButton.styleFrom(
                        backgroundColor: AppColors.goldCream,
                        foregroundColor: AppColors.goldDark),
                  ),
                ]),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: presets.map((p) {
                    final selected = p == value;
                    return ChoiceChip(
                      label: Text(offLabel != null && p == 0 ? offLabel : '$p'),
                      selected: selected,
                      onSelected: (_) => setSheet(() => value = p),
                      selectedColor: AppColors.goldCream,
                      labelStyle: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: selected ? AppColors.goldDark : Colors.black54),
                    );
                  }).toList(),
                ),
                if (helpText != null) ...[
                  const SizedBox(height: 14),
                  Text(helpText,
                      style: const TextStyle(fontSize: 12, color: Colors.black45)),
                ],
              ],
            ),
          ),
        );
      },
    ),
  );
}

Future<int?> showTeamSizeSheet({
  required BuildContext context,
  required String title,
  String? helpText,
  required int initialValue,
  List<int> sizes = const [2, 3, 4, 5, 6],
}) {
  var size = initialValue;
  return showModalBottomSheet<int>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setSheet) => TournaQSheet(
        body: Padding(
          padding: EdgeInsets.fromLTRB(
              20, 8, 20, MediaQuery.of(ctx).viewInsets.bottom + 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              _sheetHeader(context, ctx, title, () => Navigator.of(ctx).pop(size)),
              const SizedBox(height: 20),
              DropdownButtonFormField<int>(
                initialValue: size,
                isDense: true,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
                  border:
                      OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                items: sizes
                    .map((n) => DropdownMenuItem(value: n, child: Text('${n}vs$n')))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setSheet(() => size = v);
                },
              ),
              if (helpText != null) ...[
                const SizedBox(height: 12),
                Text(helpText,
                    style: const TextStyle(fontSize: 12, color: Colors.black45)),
              ],
            ],
          ),
        ),
      ),
    ),
  );
}
