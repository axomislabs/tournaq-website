import 'package:flutter/material.dart';

/// Central color palette for TournaQ.
///
/// All UI colors are derived from two primary hues:
///   - Gold/amber family  → primary brand identity
///   - Olive/green family → secondary brand identity
///
/// Usage: import this file wherever a color constant is needed instead of
/// defining file-local `_kGold`/`_kOlive` constants.
///
/// Future: If the brand palette changes, update only here.
abstract final class AppColors {
  // ── Primary gold / amber family ───────────────────────────────────────────

  /// Main gold — primary brand color, buttons, highlights.
  static const Color gold = Color(0xFFB08B1E);

  /// Darker gold — used for score page accents and some card elements.
  static const Color goldDark = Color(0xFFA97800);

  /// Amber 200 — team-1 card background in score view.
  static const Color goldCardBg = Color(0xFFFFE082);

  /// Deep amber — team-1 leading indicator in score view.
  static const Color goldCardLeading = Color(0xFFFFBF00);

  /// Light warm gold — primary container, surface, chip backgrounds.
  static const Color goldLight = Color(0xFFF0D47A);

  /// Cream — very light warm tint used for icon backgrounds and surfaces.
  static const Color goldCream = Color(0xFFFFF8E1);

  /// Gradient end stop — paired with [gold] in card gradients.
  static const Color goldGradientEnd = Color(0xFFC9A030);

  /// Badge/chip border — used on the random-team name badges.
  static const Color goldBadgeBorder = Color(0xFFE8C84E);

  // ── Secondary olive / green family ────────────────────────────────────────

  /// Dark olive — secondary brand color, confirmed actions, section headers.
  static const Color olive = Color(0xFF556B2F);

  /// Medium olive — inverse primary, drawer header background.
  static const Color oliveMedium = Color(0xFF6E7640);

  /// Secondary color — darker olive used in theme secondary.
  static const Color oliveSecondary = Color(0xFF65711D);

  /// Light olive — team-2 card background in score view.
  static const Color oliveCardBg = Color(0xFFC8DC82);

  /// Rich olive — team-2 leading indicator in score view.
  static const Color oliveCardLeading = Color(0xFF96C23C);

  /// Very light olive — icon container backgrounds, tinted surfaces.
  static const Color oliveLight = Color(0xFFEEF2E6);

  // ── Theme surface / neutral colors ────────────────────────────────────────

  /// Secondary container color.
  static const Color secondaryContainer = Color(0xFFDDE1A1);

  /// Tertiary — warm brown accent.
  static const Color tertiary = Color(0xFF8D6B2B);

  /// Tertiary container.
  static const Color tertiaryContainer = Color(0xFFF3D8A3);

  /// Surface container highest — used for elevated surfaces.
  static const Color surfaceContainerHighest = Color(0xFFE9DEB8);

  /// Outline — muted border color.
  static const Color outline = Color(0xFF7E7351);

  /// Inverse surface — dark background for snackbars and toasts.
  static const Color inverseSurface = Color(0xFF303030);

  // ── Utility ───────────────────────────────────────────────────────────────

  /// Hairline divider gray.
  static const Color divider = Color(0xFFEEEEEE);

  /// Very light gray — placeholder backgrounds.
  static const Color surfaceGray = Color(0xFFF0F0F0);

  /// Disabled icon background — used for locked/unavailable items.
  static const Color disabledIconBg = Color(0xFFF5F5F5);

  /// Disabled card background — softer than surfaceGray.
  static const Color disabledCardBg = Color(0xFFF9F9F9);

  /// "Coming Soon" chip border.
  static const Color comingSoonBorder = Color(0xFFB0BA78);

  /// "Coming Soon" chip text/icon.
  static const Color comingSoonText = Color(0xFF6E7640);

  /// Deep dark olive — splash and scorecard-intro screen background.
  /// Shared between [SplashPage] and [ScorecardSplashPage].
  static const Color splashBackground = Color(0xFF3A3E16);

  /// Instagram brand pink — used for the Instagram contact link icon background.
  static const Color instagramPink = Color(0xFFE1306C);
}
