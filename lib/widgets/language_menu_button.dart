import 'package:flutter/material.dart';
import '../app/app_colors.dart';
import '../l10n/app_localizations.dart';
import '../services/locale_service.dart';

/// Globe icon for an app bar's `actions` that opens a dropdown for switching
/// the app language on the fly — a quick shortcut mirroring the full selector
/// on the Settings page.
///
/// Languages are shown by their own names (English / Deutsch / Español) so
/// they stay recognizable regardless of the current UI language. "Automatic"
/// follows the device locale.
class LanguageMenuButton extends StatelessWidget {
  const LanguageMenuButton({super.key});

  // A non-null sentinel for the "follow device" option: PopupMenuButton treats
  // a null selection as a dismissal, so the Automatic item must carry a value.
  static const String _autoCode = 'auto';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final current = Localizations.localeOf(context).languageCode;
    final savedLocale = LocaleService.loadLocale();

    final options = <({String code, String label})>[
      (code: _autoCode, label: l10n.langAutomatic),
      (code: 'en', label: 'English'),
      (code: 'de', label: 'Deutsch'),
      (code: 'es', label: 'Español'),
    ];

    bool isSelected(String code) => code == _autoCode
        ? savedLocale == null
        : current == code && savedLocale != null;

    return PopupMenuButton<String>(
      icon: const Icon(Icons.language_rounded),
      tooltip: l10n.settingsLanguage,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (code) => LocaleService.changeLocale(
        code == _autoCode ? null : Locale(code),
      ),
      itemBuilder: (context) => options.map((opt) {
        final selected = isSelected(opt.code);
        return PopupMenuItem<String>(
          value: opt.code,
          child: Row(
            children: [
              SizedBox(
                width: 24,
                child: selected
                    ? const Icon(Icons.check_rounded,
                        size: 18, color: AppColors.oliveMedium)
                    : null,
              ),
              const SizedBox(width: 8),
              Text(
                opt.label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
