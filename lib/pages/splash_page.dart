import 'package:flutter/material.dart';
import '../state/app_state.dart';
import 'landing_page.dart';

class SplashPage extends StatefulWidget {
  final AppState appState;
  final void Function(AppState) onAppStateChanged;

  const SplashPage({
    super.key,
    required this.appState,
    required this.onAppStateChanged,
  });

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _navigate();
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(milliseconds: 2200));
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => LandingPage(
          appState: widget.appState,
          onAppStateChanged: widget.onAppStateChanged,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/tournaq_background.png'),
            fit: BoxFit.cover,
            opacity: 0.08,
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(flex: 2),

              // Logo
              Image.asset(
                'assets/tournaq_logo.png',
                height: 156,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 28),

              // Subtitle
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  'Scoring, Games & Tournament Management',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 30,
                    color: Color(0xFFB08B1E),
                    fontWeight: FontWeight.w400,
                    letterSpacing: 0.1,
                    height: 1.3,
                  ),
                ),
              ),

              const Spacer(flex: 3),

              // Loading indicator
              SizedBox(
                width: 26,
                height: 26,
                child: CircularProgressIndicator(
                  color: const Color(0xFFB08B1E),
                  backgroundColor: const Color(0xFFB08B1E).withValues(alpha: 0.15),
                  strokeWidth: 2.5,
                ),
              ),
              const SizedBox(height: 52),
            ],
          ),
        ),
      ),
    );
  }
}
