import 'package:flutter/material.dart';
import 'local_storage_service.dart';

class LocaleService {
  static const _key = 'languageCode';

  // Registered by MyApp so any widget can trigger a locale change without
  // threading a callback through every widget constructor.
  static void Function(Locale?)? _onChanged;

  static void register(void Function(Locale?) callback) {
    _onChanged = callback;
  }

  static void changeLocale(Locale? locale) {
    _onChanged?.call(locale);
    saveLocale(locale);
  }

  static Locale? loadLocale() {
    final code = LocalStorageService.getPref(_key);
    if (code == null || code.isEmpty) return null;
    return Locale(code);
  }

  static Future<void> saveLocale(Locale? locale) =>
      LocalStorageService.setPref(_key, locale?.languageCode ?? '');
}
