import 'package:flutter/material.dart';
import '../app/app_assets.dart';
import '../app/app_colors.dart';
import '../l10n/app_localizations.dart';
import '../state/app_state.dart';
import 'score_page.dart';

class ScorecardSplashPage extends StatefulWidget {
  final AppState appState;
  final Function(AppState) onAppStateChanged;
  final String gameId;
  final VoidCallback? onSaveAndReturn;

  const ScorecardSplashPage({
    super.key,
    required this.appState,
    required this.onAppStateChanged,
    required this.gameId,
    this.onSaveAndReturn,
  });

  @override
  State<ScorecardSplashPage> createState() => _ScorecardSplashPageState();
}

class _ScorecardSplashPageState extends State<ScorecardSplashPage> {
  @override
  void initState() {
    super.initState();
    // Defer to post-frame so we never touch state during build.
    WidgetsBinding.instance.addPostFrameCallback((_) => _proceed());
  }

  Future<void> _proceed() async {
    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;

    // Mark intro as shown after the delay, right before navigating.
    var state = widget.appState;
    final game = state.getGameById(widget.gameId);
    if (game != null && !game.hasShownScorecardIntro) {
      state = state.updateGame(game.copyWith(hasShownScorecardIntro: true));
      widget.onAppStateChanged(state);
    }

    if (!mounted) return;
    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (_) => ScorePage(
        appState: state,
        onAppStateChanged: widget.onAppStateChanged,
        gameId: widget.gameId,
        onSaveAndReturn: widget.onSaveAndReturn,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) => _TournaqSplash(loading: true);
}

// ── Shared splash visual ──────────────────────────────────────────────────────

class _TournaqSplash extends StatelessWidget {
  final bool loading;
  const _TournaqSplash({this.loading = true});

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
                        if (loading) ...[
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
                      ],
                    ),
                  );
                }
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
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
                    if (loading) ...[
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
