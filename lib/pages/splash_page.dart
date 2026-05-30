import 'package:flutter/material.dart';
import '../app/app_assets.dart';
import '../app/app_colors.dart';
import '../l10n/app_localizations.dart';
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
      backgroundColor: AppColors.splashBackground,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            AppAssets.background,
            fit: BoxFit.cover,
            opacity: const AlwaysStoppedAnimation(0.10),
          ),
          SafeArea(
            child: OrientationBuilder(
              builder: (context, orientation) {
                if (orientation == Orientation.landscape) {
                  final halfWidth = MediaQuery.of(context).size.width * 0.35;
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(
                          AppAssets.logoRectangle,
                          width: halfWidth,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          AppLocalizations.of(context)!.appTagline,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppColors.goldLight,
                            fontSize: 20,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: AppColors.goldLight,
                            backgroundColor:
                                AppColors.goldLight.withValues(alpha: 0.2),
                            strokeWidth: 2,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return Column(
                  children: [
                    const Spacer(),
                    Image.asset(
                      AppAssets.logoSquare,
                      width: 300,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        AppLocalizations.of(context)!.appTagline,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.goldLight,
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.2,
                          height: 1.4,
                        ),
                      ),
                    ),
                    const Spacer(),
                    SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        color: AppColors.goldLight,
                        backgroundColor:
                            AppColors.goldLight.withValues(alpha: 0.2),
                        strokeWidth: 2,
                      ),
                    ),
                    const SizedBox(height: 48),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
