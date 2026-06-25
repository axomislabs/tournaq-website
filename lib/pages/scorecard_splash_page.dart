import 'package:flutter/material.dart';
import '../app/app_assets.dart';
import '../app/app_colors.dart';
import '../l10n/app_localizations.dart';

class TournaqSplashPage extends StatefulWidget {
  final Widget destination;

  const TournaqSplashPage({super.key, required this.destination});

  @override
  State<TournaqSplashPage> createState() => _TournaqSplashPageState();
}

class _TournaqSplashPageState extends State<TournaqSplashPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _proceed());
  }

  Future<void> _proceed() async {
    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => widget.destination),
    );
  }

  @override
  Widget build(BuildContext context) => const _TournaqSplash();
}

// ── Splash visual ─────────────────────────────────────────────────────────────

class _TournaqSplash extends StatelessWidget {
  const _TournaqSplash();

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
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset(
                            AppAssets.logoTransparent,
                            width: halfWidth * 1.55,
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
                    ),
                  );
                }
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Spacer(),
                    Image.asset(
                      AppAssets.logoTransparent,
                      width: 380,
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
                    const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        color: AppColors.goldLight,
                        backgroundColor: AppColors.goldLight,
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
