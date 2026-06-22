import 'package:flutter/material.dart';
import '../app/app_colors.dart';
import '../models/club.dart';
import 'sheet_helpers.dart';

/// Bottom sheet for picking a club filter.
///
/// Returns via [Navigator.pop]:
///   - `''`      → user cleared the filter (All clubs)
///   - `club.id` → user selected a specific club
///   - `null`    → user dismissed without making a choice
class ClubPickerSheet extends StatefulWidget {
  final List<Club> clubs;
  final String? selectedId;

  const ClubPickerSheet({
    super.key,
    required this.clubs,
    this.selectedId,
  });

  @override
  State<ClubPickerSheet> createState() => _ClubPickerSheetState();
}

class _ClubPickerSheetState extends State<ClubPickerSheet> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchCtrl.text.toLowerCase();
    final filtered = query.isEmpty
        ? widget.clubs
        : widget.clubs
            .where((c) => c.name.toLowerCase().contains(query))
            .toList();

    return TournaQSheet(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Header ─────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 16, 0),
            child: Row(children: [
              const Expanded(
                child: Text(
                  'Filter by Club',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
              ),
              if (widget.selectedId != null)
                TextButton(
                  onPressed: () => Navigator.of(context).pop(''),
                  style: TextButton.styleFrom(
                      foregroundColor: Colors.red.shade400,
                      padding: const EdgeInsets.symmetric(horizontal: 8)),
                  child: const Text('Clear filter',
                      style: TextStyle(fontSize: 13)),
                ),
            ]),
          ),

          // ── Search ──────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              controller: _searchCtrl,
              autofocus: widget.clubs.length > 8,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                isDense: true,
                hintText: 'Search clubs…',
                prefixIcon: const Icon(Icons.search_rounded,
                    size: 18, color: Colors.black45),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close_rounded,
                            size: 16, color: Colors.black38),
                        onPressed: () =>
                            setState(() => _searchCtrl.clear()),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      )
                    : null,
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),

          // ── List ────────────────────────────────────────────────────────
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
              itemCount: filtered.length + 1, // +1 for "All clubs"
              itemBuilder: (_, i) {
                if (i == 0) {
                  final isSelected = widget.selectedId == null;
                  return _clubTile(
                    icon: Icons.public_rounded,
                    name: 'All clubs',
                    isSelected: isSelected,
                    onTap: () => Navigator.of(context).pop(''),
                  );
                }
                final club = filtered[i - 1];
                final isSelected = club.id == widget.selectedId;
                return _clubTile(
                  icon: Icons.home_rounded,
                  name: club.name,
                  isSelected: isSelected,
                  onTap: () => Navigator.of(context).pop(club.id),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _clubTile({
    required IconData icon,
    required String name,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.goldCream : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? AppColors.goldBadgeBorder
                : Colors.grey.shade200,
          ),
        ),
        child: Row(children: [
          Icon(icon,
              size: 16,
              color: isSelected ? AppColors.goldDark : Colors.black45),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              name,
              style: TextStyle(
                fontSize: 14,
                fontWeight:
                    isSelected ? FontWeight.w700 : FontWeight.w500,
                color:
                    isSelected ? AppColors.goldDark : Colors.black87,
              ),
            ),
          ),
          if (isSelected)
            const Icon(Icons.check_rounded,
                size: 16, color: AppColors.goldDark),
        ]),
      ),
    );
  }
}
