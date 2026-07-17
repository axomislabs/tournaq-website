/// Picks the least-used id from a fairness-tracked rotation (e.g. an
/// Auto-All-Play scorekeeper/admin turn), shared by King of the Court and
/// Doghouse. Ties are broken by longest-since-last-turn, then by id —
/// deterministic (not randomized), so re-deriving from the same candidates
/// and turn history — e.g. right after an undo — always reaches the same
/// pick instead of re-rolling it.
class FairRotationPicker {
  FairRotationPicker._();

  /// [candidateIds] is the pool to pick from. [turnHistory] is the ordered
  /// list of past turns (one entry per game; null entries — e.g. games
  /// recorded before rotation was ever enabled — are ignored).
  static String? pickFairest(
    Iterable<String> candidateIds,
    List<String?> turnHistory,
  ) {
    final list = candidateIds.toList();
    if (list.isEmpty) return null;

    final counts = <String, int>{};
    final lastIndex = <String, int>{};
    for (var i = 0; i < turnHistory.length; i++) {
      final id = turnHistory[i];
      if (id == null) continue;
      counts[id] = (counts[id] ?? 0) + 1;
      lastIndex[id] = i;
    }

    list.sort((a, b) {
      final ca = counts[a] ?? 0;
      final cb = counts[b] ?? 0;
      if (ca != cb) return ca.compareTo(cb); // fewest turns first
      final la = lastIndex[a] ?? -1;
      final lb = lastIndex[b] ?? -1;
      if (la != lb) return la.compareTo(lb); // longest since last (or never) first
      return a.compareTo(b); // deterministic tie-break
    });
    return list.first;
  }
}
