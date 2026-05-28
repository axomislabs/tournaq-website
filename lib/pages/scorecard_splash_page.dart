import 'package:flutter/material.dart';
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
            child: OrientationBuilder(
              builder: (context, orientation) {
                if (orientation == Orientation.landscape) {
                  final halfWidth = MediaQuery.of(context).size.width * 0.35;
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(
                          'assets/tournaq-rectangle.png',
                          width: halfWidth,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Scoring, Games and Tournament Management',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color(0xFFF0D47A),
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
                              color: const Color(0xFFF0D47A),
                              backgroundColor:
                                  const Color(0xFFF0D47A).withValues(alpha: 0.2),
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
                      'assets/tournaq-square.png',
                      width: 300,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 20),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        'Scoring, Games and Tournament Management',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFFF0D47A),
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
                          color: const Color(0xFFF0D47A),
                          backgroundColor:
                              const Color(0xFFF0D47A).withValues(alpha: 0.2),
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
