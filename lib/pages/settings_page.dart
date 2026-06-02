import 'package:flutter/material.dart';
import '../app/app_colors.dart';
import '../l10n/app_localizations.dart';
import '../services/consent_service.dart';
import '../services/locale_service.dart';
import '../state/app_state.dart';
import '../widgets/app_drawer.dart';
import '../widgets/scrollable_page.dart';
import '../widgets/tournaq_app_bar.dart';

class SettingsPage extends StatelessWidget {
  final AppState appState;
  final void Function(AppState) onAppStateChanged;

  const SettingsPage({
    super.key,
    required this.appState,
    required this.onAppStateChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final current = Localizations.localeOf(context).languageCode;
    final savedLocale = LocaleService.loadLocale();

    final options = <({String? code, String label})>[
      (code: null, label: l10n.langAutomatic),
      (code: 'en', label: l10n.langEnglish),
      (code: 'de', label: l10n.langGerman),
      (code: 'es', label: l10n.langSpanish),
    ];

    return Scaffold(
      drawer: AppDrawer(appState: appState, onAppStateChanged: onAppStateChanged),
      appBar: TournaQAppBar(title: l10n.navSettings),
      body: ScrollablePage(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Icon(Icons.language_rounded, size: 16, color: AppColors.oliveMedium),
              const SizedBox(width: 8),
              Text(
                l10n.settingsLanguage.toUpperCase(),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.oliveMedium,
                  letterSpacing: 0.8,
                ),
              ),
            ]),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: options.map((opt) {
                final isSelected = opt.code == null
                    ? savedLocale == null
                    : current == opt.code && savedLocale != null;
                return GestureDetector(
                  onTap: () => LocaleService.changeLocale(
                    opt.code == null ? null : Locale(opt.code!),
                  ),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.oliveMedium : Colors.transparent,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: isSelected ? AppColors.oliveMedium : Colors.grey.shade300,
                      ),
                    ),
                    child: Text(
                      opt.label,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                        color: isSelected ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            if (ConsentService.supported) ...[
              const SizedBox(height: 32),
              const Divider(),
              const SizedBox(height: 20),
              Row(children: [
                const Icon(Icons.shield_rounded, size: 16, color: AppColors.oliveMedium),
                const SizedBox(width: 8),
                Text(
                  l10n.contactSectionLegal.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.oliveMedium,
                    letterSpacing: 0.8,
                  ),
                ),
              ]),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.oliveLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.tune_rounded, color: AppColors.olive, size: 20),
                ),
                title: Text(l10n.contactPrivacyOptions,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                subtitle: Text(l10n.contactPrivacyOptionsSub,
                    style: const TextStyle(fontSize: 12, color: Colors.black54)),
                trailing: const Icon(Icons.chevron_right_rounded, color: Colors.black38),
                onTap: () => ConsentService.showPrivacyOptions(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
