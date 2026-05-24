import 'package:flutter/material.dart';

const Color _kGold = Color(0xFFB08B1E);
const Color _kGoldPale = Color(0xFFFFF8E1);

class FilterGroup {
  final String label;
  final IconData icon;
  final List<({String id, String name})> items;
  final Set<String> selectedIds;
  final void Function(String id, bool selected) onToggle;

  const FilterGroup({
    required this.label,
    required this.icon,
    required this.items,
    required this.selectedIds,
    required this.onToggle,
  });

  bool get isActive => selectedIds.isNotEmpty;
}

class FilterBar extends StatelessWidget {
  final TextEditingController searchController;
  final String hintText;
  final List<FilterGroup> groups;
  final VoidCallback onClearAll;

  const FilterBar({
    super.key,
    required this.searchController,
    this.hintText = 'Search...',
    required this.groups,
    required this.onClearAll,
  });

  bool get _hasActiveFilters =>
      searchController.text.isNotEmpty || groups.any((g) => g.isActive);

  @override
  Widget build(BuildContext context) {
    final visibleGroups = groups.where((g) => g.items.isNotEmpty).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: searchController,
          decoration: InputDecoration(
            hintText: hintText,
            prefixIcon: const Icon(Icons.search_rounded, color: Colors.black38),
            suffixIcon: searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear_rounded, size: 18),
                    onPressed: searchController.clear,
                  )
                : null,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
        for (final group in visibleGroups) ...[
          const SizedBox(height: 10),
          _FilterGroupRow(group: group),
        ],
        if (_hasActiveFilters) ...[
          const SizedBox(height: 2),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: onClearAll,
              icon: const Icon(Icons.filter_alt_off_rounded, size: 16),
              label: const Text('Clear filters'),
              style: TextButton.styleFrom(
                foregroundColor: _kGold,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _FilterGroupRow extends StatelessWidget {
  final FilterGroup group;
  const _FilterGroupRow({required this.group});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Icon(group.icon, size: 13, color: Colors.black45),
          const SizedBox(width: 4),
          Text(
            group.label.toUpperCase(),
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: Colors.black45,
              letterSpacing: 0.8,
            ),
          ),
          if (group.isActive) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(color: _kGold, borderRadius: BorderRadius.circular(6)),
              child: Text(
                '${group.selectedIds.length}',
                style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ]),
        const SizedBox(height: 5),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: group.items.map((item) {
              final selected = group.selectedIds.contains(item.id);
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: FilterChip(
                  label: Text(item.name, style: const TextStyle(fontSize: 13)),
                  selected: selected,
                  selectedColor: _kGoldPale,
                  checkmarkColor: _kGold,
                  side: selected
                      ? const BorderSide(color: _kGold, width: 1.2)
                      : BorderSide(color: Colors.grey.shade300),
                  onSelected: (v) => group.onToggle(item.id, v),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
