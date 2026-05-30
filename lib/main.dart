import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'app/app_theme.dart';
import 'pages/splash_page.dart';
import 'services/consent_service.dart';
import 'services/local_storage_service.dart';
import 'state/app_state.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LocalStorageService.init();
  // MobileAds is initialized by ConsentService after the UMP consent flow.
  final savedState = LocalStorageService.loadAppState();
  runApp(MyApp(initialState: savedState));
}

class MyApp extends StatefulWidget {
  final AppState initialState;
  const MyApp({super.key, required this.initialState});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late AppState _appState;

  @override
  void initState() {
    super.initState();
    _appState = widget.initialState;
    // Run UMP consent flow then initialize MobileAds once the first frame is
    // rendered (a visible activity/ViewController is required on Android/iOS).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ConsentService.initialize();
    });
  }

  void _updateAppState(AppState newState) {
    setState(() => _appState = newState);
    LocalStorageService.saveAppState(newState); // fire-and-forget
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TournaQ',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.buildTheme(),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('de'),
      ],
      home: SplashPage(
        appState: _appState,
        onAppStateChanged: _updateAppState,
      ),
    );
  }
}
