import 'package:flutter/material.dart';

/// Shared pill widget used on both the QuickGame and Scramble scorecards.
///
/// Shows the player name with an optional serving indicator (volleyball icon)
/// and an optional edit affordance. Pass a non-null [onTap] to enable editing.
class PlayerPill extends StatelessWidget {
  final String name;
  final bool isServing;
  final Color activeColor;
  final bool compact;
  final double fontSize;
  final VoidCallback? onTap;

  const PlayerPill({
    super.key,
    required this.name,
    required this.isServing,
    required this.activeColor,
    this.compact = false,
    this.fontSize = 10,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: compact
            ? const EdgeInsets.symmetric(horizontal: 4, vertical: 2)
            : const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: isServing ? activeColor : Colors.black12,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isServing ? activeColor : Colors.black26,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isServing) ...[
              const Icon(Icons.sports_volleyball_rounded, size: 9, color: Colors.white),
              const SizedBox(width: 3),
            ],
            Flexible(
              child: Text(
                name,
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: isServing ? FontWeight.w700 : FontWeight.w400,
                  color: isServing ? Colors.white : Colors.black54,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (onTap != null) ...[
              const SizedBox(width: 3),
              Icon(
                Icons.edit_rounded,
                size: 8,
                color: isServing ? Colors.white70 : Colors.black38,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
