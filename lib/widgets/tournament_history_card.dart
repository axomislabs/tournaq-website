import 'package:flutter/material.dart';

/// Shared card for displaying a tournament in any history view.
/// Each tournament type fills the slots via its own adapter function.
class TournamentHistoryCard extends StatelessWidget {
  final String name;
  final String typeLabel;
  final Color typeColor;
  final IconData typeIcon;
  final String dateLabel;
  final String statusLabel;
  final bool isActive;
  final List<String> stats;
  final VoidCallback onTap;
  final VoidCallback? onDeleteTap;

  const TournamentHistoryCard({
    super.key,
    required this.name,
    required this.typeLabel,
    required this.typeColor,
    required this.typeIcon,
    required this.dateLabel,
    required this.statusLabel,
    required this.isActive,
    required this.stats,
    required this.onTap,
    this.onDeleteTap,
  });

  @override
  Widget build(BuildContext context) {
    final statusBg = isActive
        ? typeColor.withValues(alpha: 0.12)
        : Colors.grey.shade100;
    final statusFg = isActive ? typeColor : Colors.black38;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: typeColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(typeIcon, color: typeColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: statusBg,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            statusLabel,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: statusFg,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (stats.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        stats.join('  ·  '),
                        style: const TextStyle(
                            fontSize: 12, color: Colors.black54),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 3),
                    Text(
                      dateLabel,
                      style: const TextStyle(
                          fontSize: 11, color: Colors.black38),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              if (onDeleteTap != null)
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert,
                      size: 18, color: Colors.black38),
                  padding: EdgeInsets.zero,
                  onSelected: (v) {
                    if (v == 'delete') onDeleteTap!();
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline,
                              size: 18, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete',
                              style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                )
              else
                const Icon(Icons.chevron_right_rounded,
                    color: Colors.black26, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
