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
    await Future.delayed(const Duration(milliseconds: 2000));
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
      backgroundColor: const Color(0xFF3A3E16),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/tournaq_background.png',
            fit: BoxFit.cover,
            opacity: const AlwaysStoppedAnimation(0.10),
          ),
          SafeArea(
            child: Column(
              children: [
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Image.asset(
                    'assets/Tournaq_logo_text.png',
                    fit: BoxFit.contain,
                  ),
                ),
                const Spacer(),
                SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    color: const Color(0xFFF0D47A),
                    backgroundColor:
                        const Color(0xFFF0D47A).withValues(alpha: 0.2),
                    strokeWidth: 2,
                  ),
                ),
                const SizedBox(height: 48),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
