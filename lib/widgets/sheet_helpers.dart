import 'package:flutter/material.dart';

/// Shared wrapper for every TournaQ modal bottom sheet.
///
/// Handles:
/// - Keyboard-aware height cap — sheet never exceeds the space above the soft
///   keyboard, so [Flexible] + [SingleChildScrollView] children are always
///   bounded and scroll instead of overflowing.
/// - Rounded top corners (24 px default).
/// - Drag handle.
/// - [Flexible] body slot for the sheet's scrollable content.
class TournaQSheet extends StatelessWidget {
  const TournaQSheet({super.key, required this.body});

  final Widget body;

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final maxH = ((mq.size.height - mq.viewInsets.bottom) * 0.97)
        .clamp(100.0, mq.size.height * 0.92);

    return Padding(
      padding: EdgeInsets.only(bottom: mq.viewInsets.bottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxH),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const _DragHandle(),
              Flexible(child: body),
            ],
          ),
        ),
      ),
    );
  }
}

class _DragHandle extends StatelessWidget {
  const _DragHandle();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 12, bottom: 4),
    child: Center(
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    ),
  );
}
