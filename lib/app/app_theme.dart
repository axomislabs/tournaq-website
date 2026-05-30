import 'package:flutter/material.dart';
import 'app_colors.dart';

/// TournaQ Material 3 theme.
///
/// Extracted from [main.dart] so the theme definition is not buried inside
/// the widget tree. All color values are resolved from [AppColors].
///
/// The color scheme uses a gold/amber seed with olive secondary overrides to
/// create the distinctive TournaQ brand palette.
///
/// Future: Light and dark theme variants can be added here without touching
/// any widget code — just extend [buildTheme] with a [Brightness] parameter.
abstract final class AppTheme {
  static ThemeData buildTheme() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.gold,
      brightness: Brightness.light,
    ).copyWith(
      primary: AppColors.gold,
      onPrimary: Colors.black,
      primaryContainer: AppColors.goldLight,
      onPrimaryContainer: Colors.black,
      secondary: AppColors.oliveSecondary,
      onSecondary: Colors.white,
      secondaryContainer: AppColors.secondaryContainer,
      onSecondaryContainer: Colors.black,
      tertiary: AppColors.tertiary,
      onTertiary: Colors.white,
      tertiaryContainer: AppColors.tertiaryContainer,
      onTertiaryContainer: Colors.black,
      surface: AppColors.goldCream,
      onSurface: Colors.black87,
      surfaceContainerHighest: AppColors.surfaceContainerHighest,
      outline: AppColors.outline,
      inverseSurface: AppColors.inverseSurface,
      onInverseSurface: Colors.white,
      inversePrimary: AppColors.oliveMedium,
    );

    return ThemeData(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: Colors.white,
      useMaterial3: true,

      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.inversePrimary,
        foregroundColor: colorScheme.onInverseSurface,
        elevation: 0,
        scrolledUnderElevation: 2,
      ),

      drawerTheme: const DrawerThemeData(
        backgroundColor: Colors.white,
      ),

      cardTheme: CardThemeData(
        color: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusCard),
        ),
        margin: EdgeInsets.zero,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.gold,
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.grey.shade200,
          disabledForegroundColor: Colors.grey.shade400,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.radiusButton),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            letterSpacing: 0.2,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.gold,
          side: const BorderSide(color: AppColors.gold, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.radiusButton),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            letterSpacing: 0.2,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.gold,
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

/// Shared layout constants referenced by [AppTheme] and UI components.
///
/// Keeping these adjacent to the theme makes it easy to audit whether a
/// hardcoded radius or spacing value should be extracted here.
abstract final class AppConstants {
  /// Default card corner radius (Material 3 large shape).
  static const double radiusCard = 18;

  /// Button corner radius.
  static const double radiusButton = 12;

  /// Small element radius (chips, badges, small containers).
  static const double radiusSmall = 8;

  /// List tile / content card radius.
  static const double radiusTile = 12;

  /// Bottom sheet and dialog top radius.
  static const double radiusSheet = 24;

  // ── Common spacing values ─────────────────────────────────────────────────

  static const double spacingXs = 4;
  static const double spacingSm = 8;
  static const double spacingMd = 16;
  static const double spacingLg = 24;
  static const double spacingXl = 32;
}
