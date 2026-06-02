/// Central registry of asset paths used across TournaQ.
///
/// All `Image.asset(...)` calls should reference constants from this class
/// rather than hardcoding path strings. This makes asset renames a single-file
/// change and allows static analysis to catch missing references.
///
/// Assets are declared in pubspec.yaml under `flutter.assets`.
abstract final class AppAssets {
  /// Subtle repeating background texture used on scrollable pages and the
  /// app bar header. Rendered at ~6% opacity to add brand depth without
  /// distracting from content.
  static const String background = 'assets/tournaq_background.png';

  /// Horizontal rectangle logo — used in the splash screen, scorecard intro,
  /// and the navigation drawer header.
  static const String logoRectangle = 'assets/tournaq-rectangle.png';

  /// Square / icon-format logo — used in the splash and scorecard intro
  /// alongside the rectangle logo.
  static const String logoSquare = 'assets/tournaq-square.png';

  /// Transparent-background logo — used on the drawer and splash screens.
  static const String logoTransparent = 'assets/tournaq_logo_transparent.png';

  /// App icon source image (not used at runtime — input for flutter_launcher_icons).
  static const String appIcon = 'assets/tournaq_icon.png';
}
