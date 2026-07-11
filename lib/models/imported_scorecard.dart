import 'scramble_tournament.dart';

/// A single Social Scramble scorecard received from another device via QR.
///
/// The [tournament] is a trimmed one-round, one-game [ScrambleTournament] built
/// on the host device, so the existing scorecard screen can render and score it
/// unchanged. [parentTournamentId] links it back to the host tournament so the
/// completed result can be returned to the correct game.
class ImportedScorecard {
  final String parentTournamentId;
  final ScrambleTournament tournament;
  final DateTime importedAt;

  const ImportedScorecard({
    required this.parentTournamentId,
    required this.tournament,
    required this.importedAt,
  });

  /// The single game carried by this scorecard.
  ScrambleGame get game => tournament.games.first;

  /// The single round carried by this scorecard.
  ScrambleRound get round => tournament.rounds.first;

  /// Parent tournament name — used for grouping/filtering in the hub.
  String get tournamentName => tournament.name;

  /// Unique storage key (equals the original game id).
  String get id => tournament.id;

  ImportedScorecard copyWith({ScrambleTournament? tournament}) =>
      ImportedScorecard(
        parentTournamentId: parentTournamentId,
        tournament: tournament ?? this.tournament,
        importedAt: importedAt,
      );

  Map<String, dynamic> toJson() => {
        'parentTournamentId': parentTournamentId,
        'tournament': tournament.toJson(),
        'importedAt': importedAt.toIso8601String(),
      };

  factory ImportedScorecard.fromJson(Map<String, dynamic> j) =>
      ImportedScorecard(
        parentTournamentId: (j['parentTournamentId'] as String?) ?? '',
        tournament: ScrambleTournament.fromJson(
            Map<String, dynamic>.from(j['tournament'] as Map)),
        importedAt: j['importedAt'] != null
            ? DateTime.parse(j['importedAt'] as String)
            : DateTime.now(),
      );
}
