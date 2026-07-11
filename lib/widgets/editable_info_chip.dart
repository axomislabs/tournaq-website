import 'package:flutter/material.dart';

/// Small pill used across scoreboard "Match Controls" rows. When [onTap] is
/// provided it renders as a tappable, ink-responsive chip with a trailing
/// affordance icon (for chips that open a mid-game edit sheet); otherwise
/// it's a static label. Shared by King of the Court and Doghouse.
class InfoChip extends StatelessWidget {
  const InfoChip({
    super.key,
    required this.icon,
    required this.label,
    required this.bg,
    required this.fg,
    this.onTap,
    this.trailingIcon = Icons.edit_rounded,
  });

  final IconData icon;
  final String label;
  final Color bg;
  final Color fg;
  final VoidCallback? onTap;
  final IconData trailingIcon;

  @override
  Widget build(BuildContext context) {
    final content = Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 11, color: fg),
      const SizedBox(width: 3),
      Text(label,
          style:
              TextStyle(fontSize: 11, color: fg, fontWeight: FontWeight.w600)),
      if (onTap != null) ...[
        const SizedBox(width: 3),
        Icon(trailingIcon, size: 11, color: fg.withValues(alpha: 0.7)),
      ],
    ]);

    if (onTap == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration:
            BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
        child: content,
      );
    }

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: content,
        ),
      ),
    );
  }
}
