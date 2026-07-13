import 'dart:convert';
import 'package:archive/archive.dart';
import '../models/imported_scorecard.dart';
import '../models/scramble_tournament.dart';

/// Thrown when a QR payload cannot be decoded or is not the expected type.
class TransferException implements Exception {
  final String message;
  TransferException(this.message);
  @override
  String toString() => 'TransferException: $message';
}

/// The completed result of a game, decoded from a `sc_result` QR, to be merged
/// back onto the host's original game.
class ScrambleResultUpdate {
  final String parentTournamentId;
  final String gameId;
  final String roundId;
  final int sideAScore;
  final int sideBScore;
  final DateTime? actualStartTime;
  final DateTime? actualEndTime;

  const ScrambleResultUpdate({
    required this.parentTournamentId,
    required this.gameId,
    required this.roundId,
    required this.sideAScore,
    required this.sideBScore,
    this.actualStartTime,
    this.actualEndTime,
  });
}

/// Encodes/decodes Social Scramble scorecards and results for QR transfer.
///
/// Payloads are a small JSON envelope `{ t, v, d }`, gzipped and base64url
/// encoded so a single game fits comfortably in one QR code at low density.
class ScrambleTransferService {
  ScrambleTransferService._();

  static const _typeGame = 'sc_game';
  static const _typeResult = 'sc_result';
  static const _version = 2;

  // ── Game export (host → referee) ───────────────────────────────────────────

  /// Encodes a single scheduled [game] as a compact payload that the referee
  /// device rebuilds into a one-game mini-tournament and scores with the normal
  /// scorecard screen.
  ///
  /// Only the three ids needed to return the result to the host — parent
  /// tournament, game and round — are carried verbatim. Players are sent as
  /// names (re-indexed to short ids on decode), which keeps the QR low-density
  /// so it scans reliably on both platforms (Android's decoder in particular
  /// struggles with the dense codes a full UUID payload produced).
  static String encodeGameExport(
    ScrambleTournament t,
    ScrambleGame game,
    ScrambleRound round,
  ) {
    // No l10n available in this wire-format encoder (the receiving device
    // may have a different locale) — 'Placeholder' is sent as plain text,
    // same as other hardcoded strings in this payload.
    String nameOf(String id) =>
        ScrambleGame.isPlaceholder(id) ? 'Placeholder' : t.getPlayer(id)?.name ?? id;
    final aNames = game.sideAPlayerIds.map(nameOf).toList();
    final bNames = game.sideBPlayerIds.map(nameOf).toList();

    // First server as an index into the concatenated [sideA..., sideB...].
    int? firstServer;
    if (game.firstServerId != null) {
      final ai = game.sideAPlayerIds.indexOf(game.firstServerId!);
      if (ai >= 0) {
        firstServer = ai;
      } else {
        final bi = game.sideBPlayerIds.indexOf(game.firstServerId!);
        if (bi >= 0) firstServer = aNames.length + bi;
      }
    }

    return _encode(_typeGame, {
      'p': t.id,
      'g': game.id,
      'r': game.roundId,
      'c': game.courtNumber,
      'n': t.playersPerTeam,
      'm': round.matchDuration.inSeconds,
      'nm': t.name,
      'a': aNames,
      'b': bNames,
      'fs': ?firstServer,
      'ta': ?game.teamNameA,
      'tb': ?game.teamNameB,
      if (game.arbitratorId != null) 'ar': nameOf(game.arbitratorId!),
      // Schedule + pace, only when the host has pace alerts on — keeps
      // non-pace QRs at minimal size.
      if (t.paceAlertsEnabled) ...{
        'pa': 1,
        'ss': round.scheduledStartTime.toIso8601String(),
        'bd': round.breakDuration.inSeconds,
      },
    });
  }

  static ImportedScorecard decodeGameExport(String raw) {
    final d = _decode(raw, _typeGame);

    final aNames = (d['a'] as List).cast<String>();
    final bNames = (d['b'] as List).cast<String>();
    if (aNames.isEmpty || bNames.isEmpty) {
      throw TransferException('Malformed scorecard payload.');
    }

    final players = <ScramblePlayer>[];
    final aIds = <String>[];
    final bIds = <String>[];
    for (var i = 0; i < aNames.length; i++) {
      final id = 'a$i';
      aIds.add(id);
      players.add(ScramblePlayer(
          id: id, name: aNames[i], source: ScramblePlayerSource.existing));
    }
    for (var i = 0; i < bNames.length; i++) {
      final id = 'b$i';
      bIds.add(id);
      players.add(ScramblePlayer(
          id: id, name: bNames[i], source: ScramblePlayerSource.existing));
    }

    String? firstServerId;
    final fs = d['fs'] as int?;
    if (fs != null) {
      if (fs < aIds.length) {
        firstServerId = aIds[fs];
      } else if (fs - aIds.length < bIds.length) {
        firstServerId = bIds[fs - aIds.length];
      }
    }

    String? arbitratorId;
    final arbName = d['ar'] as String?;
    if (arbName != null) {
      arbitratorId = 'ref';
      players.add(ScramblePlayer(
          id: arbitratorId,
          name: arbName,
          source: ScramblePlayerSource.existing));
    }

    final gameId = d['g'] as String;
    final roundId = d['r'] as String;
    final matchDuration = Duration(seconds: (d['m'] as num).toInt());
    final now = DateTime.now();

    final paceAlerts = d['pa'] == 1;
    final scheduledStart =
        d['ss'] != null ? DateTime.parse(d['ss'] as String) : now;
    final breakDuration = Duration(seconds: (d['bd'] as num?)?.toInt() ?? 0);

    final round = ScrambleRound(
      id: roundId,
      roundNumber: 1,
      scheduledStartTime: scheduledStart,
      matchDuration: matchDuration,
      breakDuration: breakDuration,
    );
    final rebuiltGame = ScrambleGame(
      id: gameId,
      roundId: roundId,
      courtNumber: (d['c'] as num).toInt(),
      sideAPlayerIds: aIds,
      sideBPlayerIds: bIds,
      firstServerId: firstServerId,
      arbitratorId: arbitratorId,
      teamNameA: d['ta'] as String?,
      teamNameB: d['tb'] as String?,
    );
    final mini = ScrambleTournament(
      id: gameId,
      name: (d['nm'] as String?) ?? '',
      totalAvailableTime: matchDuration,
      matchDuration: matchDuration,
      breakDuration: breakDuration,
      courtCount: 1,
      playersPerTeam: (d['n'] as num?)?.toInt() ?? 2,
      paceAlertsEnabled: paceAlerts,
      startTime: scheduledStart,
      players: players,
      rounds: [round],
      games: [rebuiltGame],
      createdAt: now,
    );

    return ImportedScorecard(
      parentTournamentId: (d['p'] as String?) ?? '',
      tournament: mini,
      importedAt: now,
    );
  }

  // ── Result export (referee → host) ─────────────────────────────────────────

  static String encodeResult(String parentTournamentId, ScrambleGame game) {
    return _encode(_typeResult, {
      'parentId': parentTournamentId,
      'gameId': game.id,
      'roundId': game.roundId,
      'a': game.sideAScore,
      'b': game.sideBScore,
      'st': game.actualStartTime?.toIso8601String(),
      'et': game.actualEndTime?.toIso8601String(),
    });
  }

  static ScrambleResultUpdate decodeResult(String raw) {
    final d = _decode(raw, _typeResult);
    return ScrambleResultUpdate(
      parentTournamentId: (d['parentId'] as String?) ?? '',
      gameId: d['gameId'] as String,
      roundId: (d['roundId'] as String?) ?? '',
      sideAScore: (d['a'] as num).toInt(),
      sideBScore: (d['b'] as num).toInt(),
      actualStartTime:
          d['st'] != null ? DateTime.parse(d['st'] as String) : null,
      actualEndTime:
          d['et'] != null ? DateTime.parse(d['et'] as String) : null,
    );
  }

  // ── internals ──────────────────────────────────────────────────────────────

  static String _encode(String type, Map<String, dynamic> data) {
    final envelope = {'t': type, 'v': _version, 'd': data};
    final jsonBytes = utf8.encode(jsonEncode(envelope));
    final gz = GZipEncoder().encodeBytes(jsonBytes);
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
