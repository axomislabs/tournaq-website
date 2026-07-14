import 'dart:convert';
import 'package:archive/archive.dart';
import '../models/imported_scramble_king_court.dart';
import '../models/scramble_king_tournament.dart';
import 'scramble_king_service.dart';

/// Thrown when a QR payload cannot be decoded or is not the expected type.
class ScrambleKingTransferException implements Exception {
  final String message;
  ScrambleKingTransferException(this.message);
  @override
  String toString() => 'ScrambleKingTransferException: $message';
}

/// The played result of one court, decoded from a `sk_result` QR, to be merged
/// back onto the host's original court. Per-team entries are **positional** —
/// aligned to the host formation's `teamSlots` order with the floater (if any)
/// appended last — because slot ids are not stable across devices.
class ScrambleKingResultUpdate {
  final String parentTournamentId;
  final String roundId;
  final int courtNumber;
  final List<({int points, int gamesWon})> teamResults;
  final DateTime? actualStartTime;
  final DateTime? actualEndTime;

  const ScrambleKingResultUpdate({
    required this.parentTournamentId,
    required this.roundId,
    required this.courtNumber,
    required this.teamResults,
    this.actualStartTime,
    this.actualEndTime,
  });
}

/// Encodes/decodes Scramble King (King-of-the-Court) courts and results for QR
/// transfer — the KOTC-shaped parallel of [ScrambleTransferService].
///
/// Payloads are a small JSON envelope `{ t, v, d }`, gzipped and base64url
/// encoded so a single court fits comfortably in one QR at low density.
/// Players are carried as **names** (re-indexed to short ids on decode), like
/// the Social encoder, which keeps the QR scannable on both platforms.
class ScrambleKingTransferService {
  ScrambleKingTransferService._();

  static const _typeCourt = 'sk_court';
  static const _typeResult = 'sk_result';
  static const _version = 1;

  // ── Court export (host → referee) ────────────────────────────────────────

  /// Encodes one [formation] of [round] as a compact payload the referee
  /// device rebuilds into a one-court mini-tournament and plays with the
  /// normal Scramble King scorecard.
  static String encodeCourtExport(
    ScrambleKingTournament t,
    ScrambleKingRound round,
    ScrambleKingCourtFormation formation,
  ) {
    String nameOf(String id) => t.getPlayer(id)?.name ?? id;
    return _encode(_typeCourt, {
      'p': t.id,
      'r': round.id,
      'c': formation.courtNumber,
      'nm': t.name,
      'm': round.matchDuration.inSeconds,
      'bd': round.breakDuration.inSeconds,
      'sp': t.strikePoints,
      'am': t.assignmentMode.name,
      'om': t.oddPlayerMode.name,
      'teams': [
        for (final s in formation.teamSlots)
          [s.teamName, s.playerIds.map(nameOf).toList()],
      ],
      if (formation.floaterSlot != null)
        'fl': [formation.floaterSlot!.teamName, nameOf(formation.floaterSlot!.playerId)],
      // Schedule + pace, only when the host has pace alerts on.
      if (t.paceAlertsEnabled) ...{
        'pa': 1,
        'ss': round.scheduledStartTime.toIso8601String(),
      },
    });
  }

  static ImportedScrambleKingCourt decodeCourtExport(String raw) {
    final d = _decode(raw, _typeCourt);

    final teamsRaw = (d['teams'] as List?) ?? const [];
    if (teamsRaw.isEmpty) {
      throw ScrambleKingTransferException('Malformed court payload.');
    }

    final players = <ScrambleKingPlayer>[];
    final teamSlots = <ScrambleKingTeamSlot>[];
    var pIdx = 0;
    String addPlayer(String name) {
      final id = 'p${pIdx++}';
      players.add(ScrambleKingPlayer(
          id: id, name: name, source: ScrambleKingPlayerSource.existing));
      return id;
    }

    for (var i = 0; i < teamsRaw.length; i++) {
      final entry = teamsRaw[i] as List;
      final teamName = entry[0] as String?;
      final names = (entry[1] as List).cast<String>();
      teamSlots.add(ScrambleKingTeamSlot(
        slotId: 's$i',
        playerIds: names.map(addPlayer).toList(),
        teamName: teamName,
      ));
    }

    ScrambleKingFloaterSlot? floaterSlot;
    final fl = d['fl'] as List?;
    if (fl != null) {
      floaterSlot = ScrambleKingFloaterSlot(
        slotId: 'sf',
        playerId: addPlayer(fl[1] as String),
        teamName: fl[0] as String?,
      );
    }

    final roundId = d['r'] as String;
    final courtNumber = (d['c'] as num).toInt();
    final matchDuration = Duration(seconds: (d['m'] as num).toInt());
    final breakDuration = Duration(seconds: (d['bd'] as num?)?.toInt() ?? 0);
    final now = DateTime.now();
    final scheduledStart = d['ss'] != null ? DateTime.parse(d['ss'] as String) : now;

    final formation = ScrambleKingCourtFormation(
      courtNumber: courtNumber,
      teamSlots: teamSlots,
      floaterSlot: floaterSlot,
    );
    final round = ScrambleKingRound(
      id: roundId,
      roundNumber: 1,
      scheduledStartTime: scheduledStart,
      matchDuration: matchDuration,
      breakDuration: breakDuration,
      courts: [formation],
    );
    final mini = ScrambleKingTournament(
      id: '$roundId:$courtNumber',
      name: (d['nm'] as String?) ?? '',
      courtCount: 1,
      roundCount: 1,
      matchDuration: matchDuration,
      breakDuration: breakDuration,
      strikePoints: (d['sp'] as num?)?.toInt() ?? 0,
      assignmentMode: ScrambleKingAssignmentMode.values
          .byName((d['am'] as String?) ?? ScrambleKingAssignmentMode.manual.name),
      oddPlayerMode: ScrambleKingOddPlayerMode.values
          .byName((d['om'] as String?) ?? ScrambleKingOddPlayerMode.placeholder.name),
      paceAlertsEnabled: d['pa'] == 1,
      startTime: scheduledStart,
      players: players,
      rounds: [round],
      stints: const [],
      createdAt: now,
    );

    return ImportedScrambleKingCourt(
      parentTournamentId: (d['p'] as String?) ?? '',
      tournament: mini,
      importedAt: now,
    );
  }

  // ── Result export (referee → host) ───────────────────────────────────────

  /// Encodes the played court's per-team result. Entries are ordered to match
  /// the host's `teamSlots` (floater last) so the host can merge them back
  /// positionally without relying on slot ids.
  static String encodeResult(
    String parentTournamentId,
    ScrambleKingTournament t,
    ScrambleKingRound round,
    ScrambleKingCourtFormation formation,
  ) {
    final res =
        ScrambleKingService.computeCourtRoundResult(t, round.id, formation.courtNumber);
    final byId = {for (final r in res.teamResults) r.slotId: r};
    final ordered = <ScrambleKingTeamResult>[
      for (final s in formation.teamSlots)
        if (byId[s.slotId] != null) byId[s.slotId]!,
      if (formation.floaterSlot != null && byId[formation.floaterSlot!.slotId] != null)
        byId[formation.floaterSlot!.slotId]!,
    ];
    return _encode(_typeResult, {
      'p': parentTournamentId,
      'r': round.id,
      'c': formation.courtNumber,
      'rs': [for (final r in ordered) {'pts': r.points, 'gw': r.gamesWon}],
      'st': formation.actualStartTime?.toIso8601String(),
      'et': formation.actualEndTime?.toIso8601String(),
    });
  }

  static ScrambleKingResultUpdate decodeResult(String raw) {
    final d = _decode(raw, _typeResult);
    final rs = ((d['rs'] as List?) ?? const []).map((e) {
      final m = Map<String, dynamic>.from(e as Map);
      return (
        points: (m['pts'] as num).toInt(),
        gamesWon: (m['gw'] as num?)?.toInt() ?? 0,
      );
    }).toList();
    return ScrambleKingResultUpdate(
      parentTournamentId: (d['p'] as String?) ?? '',
      roundId: (d['r'] as String?) ?? '',
      courtNumber: (d['c'] as num).toInt(),
      teamResults: rs,
      actualStartTime: d['st'] != null ? DateTime.parse(d['st'] as String) : null,
      actualEndTime: d['et'] != null ? DateTime.parse(d['et'] as String) : null,
    );
  }

  // ── internals ────────────────────────────────────────────────────────────

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
      throw ScrambleKingTransferException('Unrecognized QR code.');
    }
    if (envelope['t'] != expectedType) {
      throw ScrambleKingTransferException('This QR code is not the expected type.');
    }
    if (envelope['v'] != _version) {
      throw ScrambleKingTransferException('Unsupported QR code version.');
    }
    return Map<String, dynamic>.from(envelope['d'] as Map);
  }
}
