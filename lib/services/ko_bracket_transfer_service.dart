import 'dart:convert';
import 'package:archive/archive.dart';
import '../models/imported_ko_bracket_match.dart';
import '../models/ko_bracket_tournament.dart';
import 'scramble_transfer_service.dart' show TransferException;

export 'scramble_transfer_service.dart' show TransferException;

/// The played result of one KO match, decoded from a `ko_result` QR, to be
/// merged back onto the host's original match. Set scores are **canonical**
/// (score1 = the exported team1 / host team1, score2 = team2), and [winnerSide]
/// is 0 for the first exported team, 1 for the second — because team ids are not
/// stable across devices.
class KoResultUpdate {
  final String parentTournamentId;
  final String matchId;
  final List<KoSet> sets;
  final int winnerSide; // 0 = team1, 1 = team2
  final DateTime? startedAt;
  final DateTime? completedAt;

  const KoResultUpdate({
    required this.parentTournamentId,
    required this.matchId,
    required this.sets,
    required this.winnerSide,
    this.startedAt,
    this.completedAt,
  });
}

/// Encodes/decodes Single Elimination (KO bracket) matches and results for QR
/// transfer — the bracket-shaped parallel of [ScrambleTransferService] and
/// [ScrambleKingTransferService].
///
/// Payloads are a small JSON envelope `{ t, v, d }`, gzipped and base64url
/// encoded so a single match fits comfortably in one QR at low density.
/// Players are carried as **names** (re-indexed to short ids on decode), like
/// the other encoders, which keeps the QR scannable on both platforms.
class KoBracketTransferService {
  KoBracketTransferService._();

  static const _typeMatch = 'ko_match';
  static const _typeResult = 'ko_result';
  static const _version = 1;

  // ── Match export (host → referee) ─────────────────────────────────────────

  /// Encodes one scheduled [match] as a compact payload the referee device
  /// rebuilds into a one-match mini-tournament and scores with the normal KO
  /// bracket scorecard. Both teams must be resolved (non-null).
  ///
  /// [positionLabel] is the human-readable bracket position (e.g.
  /// "Quarter-final · Match 3"), computed on the host from the real round — it's
  /// carried verbatim so the referee's scorecard shows the correct round rather
  /// than deriving it from the one-match mini-tournament (which is always
  /// "Final · Match 1").
  static String encodeMatchExport(KoBracketTournament t, KoMatch match,
      {String? positionLabel}) {
    final fmt = t.formatForRound(match.round);
    final team1 = match.team1Id != null ? t.teamById(match.team1Id!) : null;
    final team2 = match.team2Id != null ? t.teamById(match.team2Id!) : null;
    if (team1 == null || team2 == null) {
      throw TransferException('Match has no opponents to export.');
    }
    final referee =
        match.refereeTeamId != null ? t.teamById(match.refereeTeamId!) : null;

    List<dynamic> teamEntry(KoTeam team) =>
        [team.name, team.players.map((p) => p.name).toList()];

    return _encode(_typeMatch, {
      'p': t.id,
      'g': match.id,
      'c': ?match.courtAssignment,
      'nm': t.name,
      'n': t.playersPerSide,
      'sg': fmt.setsPerGame,
      'pp': fmt.pointsPerSet,
      'sc': ?fmt.sideChangeInterval,
      'nt': fmt.notifyOnTargetReached,
      't1': teamEntry(team1),
      't2': teamEntry(team2),
      if (referee != null) 'rf': referee.name,
      'ss': ?match.scheduledStartTime?.toIso8601String(),
      'pl': ?positionLabel,
    });
  }

  static ImportedKoBracketMatch decodeMatchExport(String raw) {
    final d = _decode(raw, _typeMatch);

    final t1raw = d['t1'] as List?;
    final t2raw = d['t2'] as List?;
    if (t1raw == null || t2raw == null) {
      throw TransferException('Malformed match payload.');
    }

    KoTeam buildTeam(String id, List<dynamic> entry) {
      final name = entry[0] as String? ?? '';
      final names = (entry[1] as List).cast<String>();
      return KoTeam(
        id: id,
        name: name,
        players: [
          for (var i = 0; i < names.length; i++)
            KoPlayerSnapshot(appPlayerId: '$id-p$i', name: names[i]),
        ],
      );
    }

    final team1 = buildTeam('t1', t1raw);
    final team2 = buildTeam('t2', t2raw);

    final matchId = d['g'] as String;
    final setsPerGame = (d['sg'] as num?)?.toInt() ?? 1;
    final pointsPerSet = (d['pp'] as num?)?.toInt() ?? 21;
    final fmt = KoRoundFormat(
      setsPerGame: setsPerGame,
      pointsPerSet: pointsPerSet,
      sideChangeInterval: (d['sc'] as num?)?.toInt(),
      notifyOnTargetReached: d['nt'] as bool? ?? false,
    );
    final now = DateTime.now();
    final scheduledStart =
        d['ss'] != null ? DateTime.parse(d['ss'] as String) : null;

    // Single main-round match. round 1 (not 0/play-in) keeps propagation a
    // harmless no-op (there is no next match to advance into). startedAt is set
    // so the referee can score immediately — no "start match" gate on a match
    // that's already underway on the host.
    final match = KoMatch(
      id: matchId,
      round: 1,
      matchIndex: 0,
      team1Id: team1.id,
      team2Id: team2.id,
      courtAssignment: (d['c'] as num?)?.toInt(),
      scheduledStartTime: scheduledStart,
      startedAt: now,
    );

    final mini = KoBracketTournament(
      id: matchId,
      name: (d['nm'] as String?) ?? '',
      playersPerSide: (d['n'] as num?)?.toInt() ?? 2,
      courtCount: 1,
      defaultFormat: fmt,
      roundFormats: {1: fmt},
      estimatedStart: scheduledStart,
      teams: [team1, team2],
      matches: [match],
      status: KoBracketStatus.inProgress,
      createdAt: now,
    );

    return ImportedKoBracketMatch(
      parentTournamentId: (d['p'] as String?) ?? '',
      positionLabel: d['pl'] as String?,
      tournament: mini,
      importedAt: now,
    );
  }

  // ── Result export (referee → host) ────────────────────────────────────────

  /// Encodes the played match's set scores + winning side, to be merged back
  /// onto the host match. [match] must be complete.
  static String encodeResult(String parentTournamentId, KoMatch match) {
    final winnerSide = match.winnerId == match.team2Id ? 1 : 0;
    return _encode(_typeResult, {
      'p': parentTournamentId,
      'g': match.id,
      'w': winnerSide,
      'sets': [
        for (final s in match.sets)
          if (s.isCompleted) {'s1': s.score1, 's2': s.score2},
      ],
      'st': ?match.startedAt?.toIso8601String(),
      'et': ?match.completedAt?.toIso8601String(),
    });
  }

  static KoResultUpdate decodeResult(String raw) {
    final d = _decode(raw, _typeResult);
    final sets = ((d['sets'] as List?) ?? const []).map((e) {
      final m = Map<String, dynamic>.from(e as Map);
      return KoSet(
        score1: (m['s1'] as num?)?.toInt() ?? 0,
        score2: (m['s2'] as num?)?.toInt() ?? 0,
        isCompleted: true,
      );
    }).toList();
    return KoResultUpdate(
      parentTournamentId: (d['p'] as String?) ?? '',
      matchId: d['g'] as String,
      sets: sets,
      winnerSide: (d['w'] as num?)?.toInt() ?? 0,
      startedAt: d['st'] != null ? DateTime.parse(d['st'] as String) : null,
      completedAt: d['et'] != null ? DateTime.parse(d['et'] as String) : null,
    );
  }

  // ── internals ──────────────────────────────────────────────────────────────

  static String _encode(String type, Map<String, dynamic> data) {
    final envelope = {'t': type, 'v': _version, 'd': data};
    final jsonBytes = utf8.encode(jsonEncode(envelope));
    final gz = GZipEncoder().encode(jsonBytes)!;
    return base64Url.encode(gz);
  }

  static Map<String, dynamic> _decode(String raw, String expectedType) {
    Map<String, dynamic> envelope;
    try {
      final bytes = base64Url.decode(raw.trim());
      final jsonBytes = GZipDecoder().decodeBytes(bytes);
      envelope =
          Map<String, dynamic>.from(jsonDecode(utf8.decode(jsonBytes)) as Map);
    } catch (_) {
      throw TransferException('Unrecognized QR code.');
    }
    if (envelope['t'] != expectedType) {
      throw TransferException('This QR code is not the expected type.');
    }
    if (envelope['v'] != _version) {
      throw TransferException('Unsupported QR code version.');
    }
    return Map<String, dynamic>.from(envelope['d'] as Map);
  }
}
