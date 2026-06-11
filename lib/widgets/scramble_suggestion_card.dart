import 'package:flutter/material.dart';
import '../app/app_colors.dart';
import '../models/scramble_tournament.dart';

/// Displays a single setup suggestion with an optional quick-action button.
class ScrambleSuggestionCard extends StatelessWidget {
  final ScrambleSuggestion suggestion;
  final VoidCallback? onAction;

  const ScrambleSuggestionCard({
    super.key,
    required this.suggestion,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final blocking  = suggestion.isBlocking;
    final bgColor   = blocking ? Colors.red.shade50   : AppColors.goldCream;
    final bdColor   = blocking ? Colors.red.shade200  : AppColors.comingSoonBorder;
    final iconColor = blocking ? Colors.red.shade700  : AppColors.goldDark;
    final actColor  = blocking ? Colors.red.shade700  : AppColors.goldDark;
    final icon      = blocking
        ? Icons.error_outline_rounded
        : Icons.info_outline_rounded;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: bdColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(icon, size: 16, color: iconColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              suggestion.message,
              style: const TextStyle(fontSize: 13, color: Colors.black87),
            ),
          ),
          if (suggestion.actionLabel != null && onAction != null) ...[
            const SizedBox(width: 8),
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                foregroundColor: actColor,
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                suggestion.actionLabel!,
                style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
