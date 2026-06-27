import 'package:flutter/material.dart';
import '../app/app_colors.dart';
import '../l10n/app_localizations.dart';
import '../models/player_status.dart';

/// A compact player row used in the Players section of Scramble, KoC, and
/// Doghouse scoreboards. Inactive players (ejected / swapped out) are shown
/// with a grey avatar, strikethrough name, and no action buttons.
class TournamentPlayerRow extends StatelessWidget {
  const TournamentPlayerRow({
    super.key,
    required this.name,
    required this.status,
    this.statsLine,
    this.isOnCourt = false,
    this.onEdit,
    this.onSwap,
    this.onEject,
    this.showDisabledActions = false,
  });

  final String name;
  final PlayerStatus status;

  /// e.g. "3g · 12pts" — shown only for active players when non-null.
  final String? statsLine;

  /// When true the avatar turns gold and an "ON COURT" chip appears (KoC / DH).
  final bool isOnCourt;

  /// Action callbacks. When null and [showDisabledActions] is false the button
  /// is hidden entirely (Scramble). When null and [showDisabledActions] is true
  /// the button is shown in a greyed-out state (KoC / DH).
  final VoidCallback? onEdit;
  final VoidCallback? onSwap;
  final VoidCallback? onEject;

  /// KoC / DH pass true so all three action buttons are always visible (some
  /// may be greyed out). Scramble passes false so absent callbacks hide buttons.
  final bool showDisabledActions;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final inactive = !status.isActive;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: inactive
                ? Colors.grey.shade100
                : (isOnCourt ? AppColors.goldCream : AppColors.oliveLight),
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: inactive
                    ? Colors.grey.shade400
                    : (isOnCourt ? AppColors.goldDark : AppColors.olive),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: inactive ? Colors.grey.shade500 : null,
                          decoration:
                              inactive ? TextDecoration.lineThrough : null,
                        ),
                      ),
                    ),
                    if (status != PlayerStatus.active) ...[
                      const SizedBox(width: 6),
                      PlayerStatusChip(status),
                    ],
                    if (!inactive && isOnCourt) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.goldCream,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'ON COURT',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: AppColors.goldDark,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (statsLine != null && !inactive)
                  Text(
                    statsLine!,
                    style: const TextStyle(fontSize: 10, color: Colors.black38),
                  ),
              ],
            ),
          ),
          if (!inactive) ...[
            _actionBtn(
              icon: Icons.edit_rounded,
              color: Colors.black38,
              tooltip: l10n.tooltipEdit,
              onTap: onEdit,
              show: showDisabledActions || onEdit != null,
            ),
            _actionBtn(
              icon: Icons.swap_horiz_rounded,
              color: Colors.orange.shade700,
              tooltip: l10n.tooltipSwap,
              onTap: onSwap,
              show: showDisabledActions || onSwap != null,
            ),
            _actionBtn(
              icon: Icons.person_off_rounded,
              color: Colors.red.shade400,
              tooltip: l10n.tooltipEject,
              onTap: onEject,
              show: showDisabledActions || onEject != null,
            ),
          ],
        ],
      ),
    );
  }

  Widget _actionBtn({
    required IconData icon,
    required Color color,
    required String tooltip,
    required VoidCallback? onTap,
    required bool show,
  }) {
    if (!show) return const SizedBox.shrink();
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon,
              size: 18,
              color: onTap == null ? Colors.grey.shade300 : color),
        ),
      ),
    );
  }
}

/// Inline status chip (LATE, SUB+, SUB−, ejected). Returns an empty
/// [SizedBox] for [PlayerStatus.active]. Used both in [TournamentPlayerRow]
/// and in the history pages.
class PlayerStatusChip extends StatelessWidget {
  const PlayerStatusChip(this.status, {super.key});

  final PlayerStatus status;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final (label, color) = _data(l10n);
    if (label.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  (String, Color) _data(AppLocalizations l10n) => switch (status) {
        PlayerStatus.late => (l10n.scrambleStatusLate, Colors.blue.shade400),
        PlayerStatus.swappedIn =>
          (l10n.scrambleStatusSwappedIn, AppColors.olive),
        PlayerStatus.swappedOut =>
          (l10n.scrambleStatusSwappedOut, Colors.orange.shade600),
        PlayerStatus.ejected =>
          (l10n.doghouseEjected.toLowerCase(), Colors.red.shade400),
        PlayerStatus.active => ('', Colors.transparent),
      };
}
