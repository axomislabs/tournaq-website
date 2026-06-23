import 'package:flutter/material.dart';
import '../scoring/quick_game_adapter.dart';
import '../scoring/live_scoring_page.dart';
import '../state/app_state.dart';

class ScorePage extends StatefulWidget {
  final AppState appState;
  final Function(AppState) onAppStateChanged;
  final String gameId;
  final VoidCallback? onSaveAndReturn;

  const ScorePage({
    super.key,
    required this.appState,
    required this.onAppStateChanged,
    required this.gameId,
    this.onSaveAndReturn,
  });

  @override
  State<ScorePage> createState() => _ScorePageState();
}

class _ScorePageState extends State<ScorePage> {
  late QuickGameAdapter _adapter;

  @override
  void initState() {
    super.initState();
    _adapter = QuickGameAdapter(
      initialState: widget.appState,
      gameId: widget.gameId,
      onStateChanged: widget.onAppStateChanged,
      onSaveAndReturnOverride: widget.onSaveAndReturn,
    );
  }

  @override
  Widget build(BuildContext context) => LiveScoringPage(adapter: _adapter);
}
