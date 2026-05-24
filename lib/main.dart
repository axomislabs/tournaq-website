import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart' as gma;

import 'pages/landing_page.dart';
import 'state/app_state.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (defaultTargetPlatform == TargetPlatform.iOS ||
      defaultTargetPlatform == TargetPlatform.android ||
      kIsWeb) {
    await gma.MobileAds.instance.initialize();
  }

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  AppState _appState = const AppState();

  void _updateAppState(AppState newState) {
    setState(() {
      _appState = newState;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: const Color(0xFFB08B1E),
          brightness: Brightness.light,
        ).copyWith(
          primary: const Color(0xFFB08B1E),
          onPrimary: Colors.black,
          primaryContainer: const Color(0xFFF0D47A),
          onPrimaryContainer: Colors.black,
          secondary: const Color(0xFF65711D),
          onSecondary: Colors.white,
          secondaryContainer: const Color(0xFFDDE1A1),
          onSecondaryContainer: Colors.black,
          tertiary: const Color(0xFF8D6B2B),
          onTertiary: Colors.white,
          tertiaryContainer: const Color(0xFFF3D8A3),
          onTertiaryContainer: Colors.black,
          surface: const Color(0xFFFFF8E1),
          onSurface: Colors.black87,
          surfaceContainerHighest: const Color(0xFFE9DEB8),
          outline: const Color(0xFF7E7351),
          inverseSurface: const Color(0xFF303030),
          onInverseSurface: Colors.white,
          inversePrimary: const Color(0xFF6E7640),
        );

    return MaterialApp(
      title: 'TournaQ',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: colorScheme,
        scaffoldBackgroundColor: Colors.white,
        useMaterial3: true,

        // ── AppBar ─────────────────────────────────────────────────────────
        appBarTheme: AppBarTheme(
          backgroundColor: colorScheme.inversePrimary,
          foregroundColor: colorScheme.onInverseSurface,
          elevation: 0,
          scrolledUnderElevation: 2,
        ),

        // ── Drawer ─────────────────────────────────────────────────────────
        drawerTheme: const DrawerThemeData(
          backgroundColor: Colors.white,
        ),

        // ── Cards ──────────────────────────────────────────────────────────
        cardTheme: CardThemeData(
          color: Colors.white,
          surfaceTintColor: Colors.transparent,
          elevation: 2,
          shadowColor: Colors.black.withValues(alpha: 0.08),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          margin: EdgeInsets.zero,
        ),

        // ── Elevated Button (primary) ───────────────────────────────────────
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6E7640),
            foregroundColor: Colors.white,
            disabledBackgroundColor: Colors.grey.shade200,
            disabledForegroundColor: Colors.grey.shade400,
            elevation: 0,
            shadowColor: Colors.transparent,
            side: const BorderSide(color: Color(0xFFB08B1E), width: 1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            textStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              letterSpacing: 0.2,
            ),
          ),
        ),

        // ── Outlined Button (secondary) ────────────────────────────────────
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF6E7640),
            side: const BorderSide(color: Color(0xFF6E7640), width: 1.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            textStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              letterSpacing: 0.2,
            ),
          ),
        ),

        // ── Text Button ────────────────────────────────────────────────────
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF6E7640),
            textStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
      ),
      home: LandingPage(
        appState: _appState,
        onAppStateChanged: _updateAppState,
      ),
    );
  }
}
