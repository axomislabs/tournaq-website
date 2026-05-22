import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'state/app_state.dart';
import 'pages/landing_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Google Mobile Ads only on supported platforms (iOS, Android, Web)
  if (defaultTargetPlatform == TargetPlatform.iOS ||
      defaultTargetPlatform == TargetPlatform.android ||
      kIsWeb) {
    await MobileAds.instance.initialize();
  }

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late AppState _appState;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _appState = const AppState();
    _initializeSampleData();
  }

  void _initializeSampleData() {
    // Initialize with some sample teams for testing
    // This will be removed once users can create their own data
    setState(() {
      _appState = _appState.addTeam(Team(
        id: AppState.generateId(),
        name: 'Red Dragons',
      ));
      _appState = _appState.addTeam(Team(
        id: AppState.generateId(),
        name: 'Blue Titans',
      ));
      _appState = _appState.addTeam(Team(
        id: AppState.generateId(),
        name: 'Golden Warriors',
      ));
    });
  }

  void _updateAppState(AppState newState) {
    setState(() {
      _appState = newState;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Team Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
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
        ),
        useMaterial3: true,
        appBarTheme: AppBarThemeData(
          backgroundColor: const Color(0xFF6E7640),
          foregroundColor: Colors.white,
        ),
        drawerTheme: const DrawerThemeData(
          backgroundColor: Color(0xFFF0D47A),
        ),
      ),
      home: LandingPage(
        appState: _appState,
        onAppStateChanged: _updateAppState,
      ),
    );
  }
}

// Re-export key models and state for convenience in page files
export 'models/app_user.dart';
export 'models/team.dart';
export 'models/tournament.dart';
export 'models/tournament_mode.dart';
export 'models/game.dart';
export 'models/game_result.dart';
export 'state/app_state.dart';
export 'services/app_data_service.dart';
export 'services/tournament_logic_service.dart';
