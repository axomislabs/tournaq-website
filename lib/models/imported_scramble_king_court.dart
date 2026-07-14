import 'scramble_king_tournament.dart';

/// A single Scramble King court received from another device via QR.
///
/// The [tournament] is a trimmed one-round, one-court [ScrambleKingTournament]
/// built on the host device, so the existing Scramble King scorecard screen can
/// render and play it unchanged. [parentTournamentId] links it back to the host
/// tournament so the completed result can be returned to the correct court.
class ImportedScrambleKingCourt {
  final String parentTournamentId;
  final ScrambleKingTournament tournament;
  final DateTime importedAt;

  const ImportedScrambleKingCourt({
    required this.parentTournamentId,
    required this.tournament,
    required this.importedAt,
  });

  /// The single round carried by this court.
  ScrambleKingRound get round => tournament.rounds.first;

  /// The single court formation carried by this import.
  ScrambleKingCourtFormation get formation => round.courts.first;

  /// Parent tournament name — used for grouping/labelling in the hub.
  String get tournamentName => tournament.name;

  /// Unique storage key (equals the mini tournament id: `<roundId>:<court>`).
  String get id => tournament.id;

  ImportedScrambleKingCourt copyWith({ScrambleKingTournament? tournament}) =>
      ImportedScrambleKingCourt(
        parentTournamentId: parentTournamentId,
        tournament: tournament ?? this.tournament,
        importedAt: importedAt,
      );

  Map<String, dynamic> toJson() => {
        'parentTournamentId': parentTournamentId,
        'tournament': tournament.toJson(),
        'importedAt': importedAt.toIso8601String(),
      };

  factory ImportedScrambleKingCourt.fromJson(Map<String, dynamic> j) =>
      ImportedScrambleKingCourt(
        parentTournamentId: (j['parentTournamentId'] as String?) ?? '',
        tournament: ScrambleKingTournament.fromJson(
            Map<String, dynamic>.from(j['tournament'] as Map)),
        importedAt: j['importedAt'] != null
            ? DateTime.parse(j['importedAt'] as String)
            : DateTime.now(),
      );
}
