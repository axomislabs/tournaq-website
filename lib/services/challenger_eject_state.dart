/// Session-only undo buffer for ejecting a not-yet-playing "Challenger" team
/// slot without recording a completed game (the challenger never actually
/// played). Shared by King of the Court and Doghouse, which both have an
/// identical on-court team → Challengers → Up Next queue chain in automated
/// modes.
class ChallengerEjectState<P> {
  List<P>? _lastEjected;

  bool get canUndo => _lastEjected != null;

  /// The team currently pending undo, if any — for callers that need to
  /// check membership (e.g. clearing the buffer when one of its players is
  /// ejected/replaced from the roster entirely).
  List<P>? get pending => _lastEjected;

  /// Ejects [current] (the Challenger slot) and promotes [promoted] (the
  /// already-computed Up Next team) into it. Returns the new Challenger
  /// team, or null if [promoted] isn't a full team (nothing to promote).
  List<P>? eject({
    required List<P> current,
    required List<P> promoted,
    required int teamSize,
  }) {
    if (promoted.length != teamSize) return null;
    _lastEjected = List<P>.from(current);
    return promoted;
  }

  /// Restores the last-ejected Challenger team, or null if there's nothing
  /// to undo.
  List<P>? undo() {
    final restored = _lastEjected;
    _lastEjected = null;
    return restored;
  }

  void clear() => _lastEjected = null;
}
