import 'package:flutter/material.dart';
import '../app/app_colors.dart';

/// Narrow "Eject Challenger" button stacked over a self-disabling "Undo",
/// placed beside the Challengers tile in automated modes. Mirrors the
/// on-court eject column's shape but in olive branding. Shared by King of
/// the Court and Doghouse.
class ChallengerEjectColumn extends StatelessWidget {
  const ChallengerEjectColumn({
    super.key,
    required this.canEject,
    required this.onEject,
    required this.canUndo,
    required this.onUndo,
    required this.ejectLabel,
    required this.undoLabel,
  });

  final bool canEject;
  final VoidCallback onEject;
  final bool canUndo;
  final VoidCallback onUndo;
  final String ejectLabel;
  final String undoLabel;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: canEject ? onEject : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.olive,
              disabledBackgroundColor: Colors.grey.shade300,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.all(8),
              shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.logout_rounded, size: 22),
                  const SizedBox(height: 6),
                  Text(ejectLabel,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 11)),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Expanded(
          flex: 1,
          child: OutlinedButton(
            onPressed: canUndo ? onUndo : null,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.olive,
              side: BorderSide(color: AppColors.olive.withValues(alpha: 0.6)),
              padding: const EdgeInsets.all(8),
              shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.undo_rounded, size: 16),
                  const SizedBox(height: 4),
                  Text(undoLabel,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 10)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
