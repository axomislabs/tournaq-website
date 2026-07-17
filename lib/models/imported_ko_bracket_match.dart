import 'ko_bracket_tournament.dart';

/// A single Single-Elimination match received from another device via QR.
///
/// The [tournament] is a trimmed one-round, one-match [KoBracketTournament]
/// built on the host device, so the existing KO bracket scorecard screen can
/// render and play it unchanged. [parentTournamentId] links it back to the host
/// tournament so the completed result can be returned to the correct match.
class ImportedKoBracketMatch {
  final String parentTournamentId;
  final KoBracketTournament tournament;
  final DateTime importedAt;

  /// The bracket position on the host (e.g. "Quarter-final · Match 3"), carried
  /// verbatim so the scorecard shows the real round instead of "Final · Match 1"
  /// (the mini-tournament only has one round).
  final String? positionLabel;

  const ImportedKoBracketMatch({
    required this.parentTournamentId,
    required this.tournament,
    required this.importedAt,
    this.positionLabel,
  });

  /// The single match carried by this import.
  KoMatch get match => tournament.matches.first;

  /// Parent tournament name — used for grouping/labelling in the hub.
  String get tournamentName => tournament.name;

  /// Unique storage key (equals the mini tournament id, i.e. the host match id).
  String get id => tournament.id;

  ImportedKoBracketMatch copyWith({KoBracketTournament? tournament}) =>
      ImportedKoBracketMatch(
        parentTournamentId: parentTournamentId,
        tournament: tournament ?? this.tournament,
        importedAt: importedAt,
        positionLabel: positionLabel,
      );

  Map<String, dynamic> toJson() => {
        'parentTournamentId': parentTournamentId,
        'tournament': tournament.toJson(),
        'importedAt': importedAt.toIso8601String(),
        if (positionLabel != null) 'positionLabel': positionLabel,
      };

  factory ImportedKoBracketMatch.fromJson(Map<String, dynamic> j) =>
      ImportedKoBracketMatch(
        parentTournamentId: (j['parentTournamentId'] as String?) ?? '',
        tournament: KoBracketTournament.fromJson(
            Map<String, dynamic>.from(j['tournament'] as Map)),
        importedAt: j['importedAt'] != null
            ? DateTime.parse(j['importedAt'] as String)
            : DateTime.now(),
        positionLabel: j['positionLabel'] as String?,
      );
}
