import 'dart:io';

import 'package:file_picker/file_picker.dart' show FilePicker, FileType;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../app/app_colors.dart';
import '../app/app_links.dart';
import '../l10n/app_localizations.dart';
import '../services/roster_transfer_service.dart';
import '../state/app_state.dart';
import '../utils/url_utils.dart';
import '../widgets/assign_dialog.dart' show actionMenuItem;
import '../widgets/bracket_background.dart';
import '../widgets/tournaq_app_bar.dart';
import 'groups_page.dart';
import 'teams_page.dart';
import 'users_page.dart';

class AdministrationPage extends StatefulWidget {
  final AppState appState;
  final Function(AppState) onAppStateChanged;

  const AdministrationPage({
    super.key,
    required this.appState,
    required this.onAppStateChanged,
  });

  @override
  State<AdministrationPage> createState() => _AdministrationPageState();
}

class _AdministrationPageState extends State<AdministrationPage> {
  static const _xlsxMime =
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _shareBytes(List<int> bytes, String filename) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$filename');
    await file.writeAsBytes(bytes, flush: true);
    await SharePlus.instance.share(ShareParams(
      files: [XFile(file.path, mimeType: _xlsxMime)],
      subject: filename,
    ));
  }

  Future<void> _downloadTemplate() async {
    await _shareBytes(
        RosterTransferService.buildTemplate(), 'tournaq_roster_template.xlsx');
  }

  Future<void> _export() async {
    final l10n = AppLocalizations.of(context)!;
    if (widget.appState.players.isEmpty) {
      _showMessage(l10n.rosterNothingToExport);
      return;
    }
    await _shareBytes(
        RosterTransferService.export(widget.appState), 'tournaq_roster.xlsx');
  }

  Future<void> _import() async {
    final l10n = AppLocalizations.of(context)!;
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
      withData: true,
    );
    if (!mounted) return;
    final bytes = result?.files.isNotEmpty == true ? result!.files.first.bytes : null;
    if (bytes == null) return;

    final plan = RosterTransferService.parse(widget.appState, bytes);
    if (!mounted) return;
    if (!plan.isValid) {
      _showMessage(l10n.rosterImportInvalidFile);
      return;
    }
    if (!plan.hasChanges) {
      _showMessage(l10n.rosterImportNoChanges);
      return;
    }

    final confirmed = await _showImportConfirm(plan);
    if (confirmed != true || !mounted) return;

    // Stronger confirmation for a large deletion set.
    final existing = widget.appState.players.length;
    final deletes = plan.playersToDelete.length;
    final largeDelete =
        deletes >= 5 || (existing > 0 && deletes > 0 && deletes * 2 >= existing);
    if (largeDelete) {
      final sure = await _showStrongDeleteConfirm(deletes);
      if (sure != true || !mounted) return;
    }

    widget.onAppStateChanged(plan.newState);
    _showMessage(l10n.rosterImportDone(
        plan.playersCreated, plan.playersUpdated, plan.playersDeleted));
  }

  Future<bool?> _showImportConfirm(RosterImportPlan plan) {
    final l10n = AppLocalizations.of(context)!;
    final hasDeletes = plan.playersToDelete.isNotEmpty;
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
        actionsPadding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        title: Text(
          l10n.rosterImportTitle,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.rosterImportSummary(plan.playersCreated, plan.playersUpdated,
                    plan.teamsCreated, plan.groupsCreated),
                style: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.5),
              ),
              if (hasDeletes) ...[
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 18),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        l10n.rosterImportDeleteWarning(plan.playersToDelete.length),
                        style: const TextStyle(
                            fontSize: 14, color: Colors.red, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  plan.playersToDelete.join(', '),
                  style: const TextStyle(fontSize: 13, color: Colors.black54),
                ),
              ],
              if (!plan.mirrorEligible) ...[
                const SizedBox(height: 12),
                Text(
                  l10n.rosterMirrorDisabledNote,
                  style: const TextStyle(
                      fontSize: 12, color: Colors.black45, fontStyle: FontStyle.italic),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.btnCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              hasDeletes ? l10n.rosterImportConfirmDelete : l10n.rosterImportConfirm,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: hasDeletes ? Colors.red : AppColors.goldDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<bool?> _showStrongDeleteConfirm(int count) {
    final l10n = AppLocalizations.of(context)!;
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          l10n.rosterImportTitle,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
        content: Text(
          l10n.rosterImportDeleteWarning(count),
          style: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.btnCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              l10n.btnDelete,
              style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _showInfo(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
        actionsPadding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        title: Text(
          l10n.navAdmin,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
        content: SingleChildScrollView(
          child: Text(
            l10n.adminHelpBody,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black54,
              height: 1.6,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () =>
                openExternalUrl(ctx, AppLinks.featureUserAdministration),
            child: Text(l10n.btnLearnMore),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              l10n.btnGotIt,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: TournaQAppBar(
        title: l10n.navAdmin,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            tooltip: l10n.rosterMenuTooltip,
            onSelected: (value) {
              switch (value) {
                case 'template':
                  _downloadTemplate();
                case 'import':
                  _import();
                case 'export':
                  _export();
                case 'info':
                  _showInfo(context);
              }
            },
            itemBuilder: (_) => [
              actionMenuItem('template', Icons.file_download_outlined,
                  l10n.rosterDownloadTemplate),
              actionMenuItem('import', Icons.upload_rounded, l10n.rosterImport),
              actionMenuItem('export', Icons.download_rounded, l10n.rosterExport),
              const PopupMenuDivider(),
              actionMenuItem('info', Icons.info_outline_rounded, l10n.rosterMenuInfo),
            ],
          ),
        ],
      ),
      body: BracketBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _AdminTile(
                icon: Icons.person_rounded,
                color: AppColors.gold,
                gradientEnd: AppColors.goldGradientEnd,
                name: l10n.navPlayers,
                description: l10n.adminManagePlayers,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => UsersPage(
                      appState: widget.appState,
                      onAppStateChanged: widget.onAppStateChanged,
                    ),
                  ),
                ),
              ),
              _AdminTile(
                icon: Icons.groups_rounded,
                color: AppColors.gold,
                gradientEnd: AppColors.goldGradientEnd,
                name: l10n.navTeams,
                description: l10n.adminManageTeams,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => TeamsPage(
                      appState: widget.appState,
                      onAppStateChanged: widget.onAppStateChanged,
                    ),
                  ),
                ),
              ),
              _AdminTile(
                icon: Icons.shield_rounded,
                color: AppColors.gold,
                gradientEnd: AppColors.goldGradientEnd,
                name: l10n.navClubs,
                description: l10n.adminManageGroups,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => GroupsPage(
                      appState: widget.appState,
                      onAppStateChanged: widget.onAppStateChanged,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdminTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color gradientEnd;
  final String name;
  final String description;
  final VoidCallback onTap;

  const _AdminTile({
    required this.icon,
    required this.color,
    required this.gradientEnd,
    required this.name,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color, gradientEnd],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.28),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.1,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    description,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.80),
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.chevron_right_rounded,
              color: Colors.white,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }
}
