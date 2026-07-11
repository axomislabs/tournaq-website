import 'package:flutter/material.dart';
import '../app/app_colors.dart';
import 'sheet_helpers.dart';

/// A minimal {id, name} pair — avoids depending on either mode's concrete
/// player type.
typedef AdminCandidate = ({String id, String name});

/// Tappable info pill showing the current Auto-All-Play admin/scorekeeper
/// (and, if a handoff is pending, the next one). Shared by King of the
/// Court and Doghouse.
class AdminRotationTile extends StatelessWidget {
  const AdminRotationTile({
    super.key,
    required this.adminName,
    required this.nextAdminName,
    required this.adminTag,
    required this.onTap,
  });

  final String? adminName;
  final String? nextAdminName;
  final String adminTag;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(children: [
          const Icon(Icons.manage_accounts_rounded,
              size: 15, color: Colors.black45),
          const SizedBox(width: 6),
          Text(
            adminTag,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: Colors.black45,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              adminName ?? '—',
              overflow: TextOverflow.ellipsis,
              style:
                  const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
          ),
          if (nextAdminName != null) ...[
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward_rounded,
                size: 13, color: Colors.black38),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                nextAdminName!,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ),
          ],
          const SizedBox(width: 8),
          const Icon(Icons.edit_rounded, size: 13, color: Colors.black38),
        ]),
      ),
    );
  }
}

/// Bottom sheet to override the current admin, and (if a handoff is
/// pending) the successor picked from [onCourtTeam].
Future<void> showAdminOverrideSheet({
  required BuildContext context,
  required String title,
  required String subtitle,
  required List<AdminCandidate> pool,
  required String? currentAdminId,
  required void Function(String id) onSetAdmin,
  List<AdminCandidate>? onCourtTeam,
  String? nextAdminId,
  String? nextAdminLabel,
  String? nextAdminNote,
  void Function(String id)? onSetNextAdmin,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => TournaQSheet(
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(subtitle,
                style: const TextStyle(fontSize: 12, color: Colors.black45)),
            const SizedBox(height: 16),
            ...pool.map((p) {
              final isCurrent = p.id == currentAdminId;
              return ListTile(
                dense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                leading: CircleAvatar(
                  radius: 14,
                  backgroundColor:
                      isCurrent ? AppColors.goldCream : Colors.grey.shade100,
                  child: Text(
                    p.name.isNotEmpty ? p.name[0].toUpperCase() : '?',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isCurrent ? AppColors.goldDark : Colors.black54),
                  ),
                ),
                title: Text(p.name,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight:
                            isCurrent ? FontWeight.w700 : FontWeight.w500)),
                trailing: isCurrent
                    ? const Icon(Icons.manage_accounts_rounded,
                        size: 18, color: AppColors.goldDark)
                    : null,
                onTap: isCurrent
                    ? null
                    : () {
                        Navigator.of(ctx).pop();
                        onSetAdmin(p.id);
                      },
              );
            }),
            if (onCourtTeam != null &&
                onCourtTeam.isNotEmpty &&
                nextAdminId != null) ...[
              const Divider(height: 24),
              if (nextAdminLabel != null)
                Text(
                  nextAdminLabel,
                  style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.black45,
                      letterSpacing: 0.5),
                ),
              if (nextAdminNote != null) ...[
                const SizedBox(height: 4),
                Text(nextAdminNote,
                    style: const TextStyle(fontSize: 12, color: Colors.black45)),
              ],
              const SizedBox(height: 8),
              ...onCourtTeam.map((p) {
                final isNext = p.id == nextAdminId;
                return ListTile(
                  dense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                  leading: CircleAvatar(
                    radius: 14,
                    backgroundColor:
                        isNext ? Colors.grey.shade200 : Colors.grey.shade100,
                    child: Text(
                      p.name.isNotEmpty ? p.name[0].toUpperCase() : '?',
                      style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.black54),
                    ),
                  ),
                  title: Text(p.name,
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight:
                              isNext ? FontWeight.w700 : FontWeight.w500)),
                  trailing: isNext
                      ? const Icon(Icons.schedule_rounded,
                          size: 18, color: Colors.black45)
                      : null,
                  onTap: () {
                    Navigator.of(ctx).pop();
                    onSetNextAdmin?.call(p.id);
                  },
                );
              }),
            ],
          ],
        ),
      ),
    ),
  );
}
