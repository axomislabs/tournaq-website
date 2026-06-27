import 'package:flutter/material.dart';

/// Lays out a list of already-built pill widgets in a consistent grid.
///
/// Portrait (stacked: true)  — one pill per row, each stretched to full width.
/// Landscape (stacked: false) — two pills per row; if the count is odd the last
/// pill is centered at 50 % width to match the pair rows above it.
class PillGrid extends StatelessWidget {
  final List<Widget> pills;
  final bool stacked;

  const PillGrid({super.key, required this.pills, this.stacked = false});

  @override
  Widget build(BuildContext context) {
    if (pills.isEmpty) return const SizedBox.shrink();

    if (stacked) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: pills
            .expand((p) => [p, const SizedBox(height: 4)])
            .take(pills.length * 2 - 1)
            .toList(),
      );
    }

    // 2-column grid
    final rows = <Widget>[];
    for (var i = 0; i < pills.length; i += 2) {
      if (rows.isNotEmpty) rows.add(const SizedBox(height: 4));
      if (i + 1 < pills.length) {
        rows.add(Row(children: [
          Expanded(child: pills[i]),
          const SizedBox(width: 4),
          Expanded(child: pills[i + 1]),
        ]));
      } else {
        rows.add(Align(
          alignment: Alignment.center,
          child: FractionallySizedBox(widthFactor: 0.5, child: pills[i]),
        ));
      }
    }
    return Column(mainAxisSize: MainAxisSize.min, children: rows);
  }
}

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
          ],
        ),
      ),
    );
  }
}
