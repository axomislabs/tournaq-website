import 'package:uuid/uuid.dart';
import '../services/device_id_service.dart';
import 'player_status.dart';

const _uuid = Uuid();

enum ScrambleKingTournamentStatus { setup, inProgress, completed }

enum ScrambleKingPlayerSource { existing, created, random }

enum ScrambleKingAssignmentMode { manual, automated, automatedAllPlay }

enum ScrambleKingOddPlayerMode { placeholder, jumper }

enum ScrambleKingStintEndReason { strike, manual, timeout }

// ── Player ────────────────────────────────────────────────────────────────────

class ScrambleKingPlayer {
  final String id;
  final String name;
  final ScrambleKingPlayerSource source;
  final String? appUserId;
  final PlayerStatus status;

  const ScrambleKingPlayer({
    required this.id,
    required this.name,
    required this.source,
    this.appUserId,
    this.status = PlayerStatus.active,
  });

  bool get isActive => status.isActive;

  ScrambleKingPlayer copyWith({
    String? name,
    PlayerStatus? status,
    String? appUserId,
    bool clearAppUserId = false,
  }) =>
      ScrambleKingPlayer(
        id: id,
        name: name ?? this.name,
        source: source,
        appUserId: clearAppUserId ? null : (appUserId ?? this.appUserId),
        status: status ?? this.status,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'source': source.name,
        'appUserId': appUserId,
        'status': status.name,
      };

  factory ScrambleKingPlayer.fromJson(Map<String, dynamic> j) =>
      ScrambleKingPlayer(
        id: j['id'] as String,
        name: j['name'] as String,
        source: ScrambleKingPlayerSource.values.byName(
            (j['source'] as String?) ?? ScrambleKingPlayerSource.random.name),
        appUserId: j['appUserId'] as String?,
        status: PlayerStatus.values.byName(
            (j['status'] as String?) ?? PlayerStatus.active.name),
      );

  static String generateId() => _uuid.v4();
}

// ── Team / floater slots ────────────────────────────────────────────────────
// A slot keeps a stable identity for the whole round as it cycles on/off
// court and through the queue. Both ScrambleKingTeamSlot and
// ScrambleKingFloaterSlot are scoring identities — the floater's team is
// credited normally; only their per-game partner is a dynamic stand-in
// (see ScrambleKingStint below).

class ScrambleKingTeamSlot {
  final String slotId;
  final List<String> playerIds; // exactly 2 named players
  final String? teamName; // fun per-round name, e.g. "Steel Cobras"

  const ScrambleKingTeamSlot({
    required this.slotId,
    required this.playerIds,
    this.teamName,
  });

  Map<String, dynamic> toJson() => {
        'slotId': slotId,
        'playerIds': playerIds,
        'teamName': teamName,
      };

  factory ScrambleKingTeamSlot.fromJson(Map<String, dynamic> j) =>
      ScrambleKingTeamSlot(
        slotId: j['slotId'] as String,
        playerIds: List<String>.from(j['playerIds'] as List),
        teamName: j['teamName'] as String?,
      );

  static String generateId() => _uuid.v4();
}

/// The odd player's team — a single fixed player who queues and scores
/// exactly like any [ScrambleKingTeamSlot]. In placeholder mode their second
/// "teammate" slot is never filled by a named player at all. In jumper mode
/// it is filled by a partner locked in via `pickJumperPartner` once the team
/// reaches the front of the queue, kept unchanged through to the court.
class ScrambleKingFloaterSlot {
  final String slotId;
  final String playerId;
  final String? teamName; // fun per-round name, same pool as ScrambleKingTeamSlot

  const ScrambleKingFloaterSlot({
    required this.slotId,
    required this.playerId,
    this.teamName,
  });

  Map<String, dynamic> toJson() => {
        'slotId': slotId,
        'playerId': playerId,
        'teamName': teamName,
      };

  factory ScrambleKingFloaterSlot.fromJson(Map<String, dynamic> j) =>
      ScrambleKingFloaterSlot(
        slotId: j['slotId'] as String,
        playerId: j['playerId'] as String,
        teamName: j['teamName'] as String?,
      );

  static String generateId() => _uuid.v4();
}

// ── Court formation ──────────────────────────────────────────────────────────
// The formation decided for one court for one round, fixed once computed.

class ScrambleKingCourtFormation {
  final int courtNumber;
  final List<ScrambleKingTeamSlot> teamSlots; // order = initial queue order
  final ScrambleKingFloaterSlot? floaterSlot;
  /// Manual score override, keyed by ScrambleKingTeamSlot.slotId. A missing
  /// entry means "use the auto-computed total from stints" for that team.
  final Map<String, int> manualTeamPoints;
  /// Manual games-won override, keyed by ScrambleKingTeamSlot.slotId. A
  /// missing entry means "use the auto-computed total from stints".
  final Map<String, int> manualGamesWon;
  /// Mirrors ScrambleGame's actualStartTime/actualEndTime — per-court
  /// completion, independent of the other courts in the same round. The
  /// round itself is only marked complete once every court is.
  final DateTime? actualStartTime;
  final DateTime? actualEndTime;

  const ScrambleKingCourtFormation({
    required this.courtNumber,
    required this.teamSlots,
    this.floaterSlot,
    this.manualTeamPoints = const {},
    this.manualGamesWon = const {},
    this.actualStartTime,
    this.actualEndTime,
  });

  bool get isCompleted => actualEndTime != null;

  ScrambleKingCourtFormation copyWith({
    Map<String, int>? manualTeamPoints,
    Map<String, int>? manualGamesWon,
    DateTime? actualStartTime,
    DateTime? actualEndTime,
    bool clearActualEndTime = false,
  }) =>
      ScrambleKingCourtFormation(
        courtNumber: courtNumber,
        teamSlots: teamSlots,
        floaterSlot: floaterSlot,
        manualTeamPoints: manualTeamPoints ?? this.manualTeamPoints,
        manualGamesWon: manualGamesWon ?? this.manualGamesWon,
        actualStartTime: actualStartTime ?? this.actualStartTime,
        actualEndTime:
            clearActualEndTime ? null : (actualEndTime ?? this.actualEndTime),
      );

  Map<String, dynamic> toJson() => {
        'courtNumber': courtNumber,
        'teamSlots': teamSlots.map((s) => s.toJson()).toList(),
        'floaterSlot': floaterSlot?.toJson(),
        'manualTeamPoints': manualTeamPoints,
        'manualGamesWon': manualGamesWon,
        'actualStartTime': actualStartTime?.toIso8601String(),
        'actualEndTime': actualEndTime?.toIso8601String(),
      };

  factory ScrambleKingCourtFormation.fromJson(Map<String, dynamic> j) =>
      ScrambleKingCourtFormation(
        courtNumber: j['courtNumber'] as int,
        teamSlots: (j['teamSlots'] as List)
            .map((e) => ScrambleKingTeamSlot.fromJson(
                Map<String, dynamic>.from(e as Map)))
            .toList(),
        floaterSlot: j['floaterSlot'] != null
            ? ScrambleKingFloaterSlot.fromJson(
                Map<String, dynamic>.from(j['floaterSlot'] as Map))
            : null,
        manualTeamPoints: j['manualTeamPoints'] != null
            ? Map<String, int>.from(j['manualTeamPoints'] as Map)
            : const {},
        manualGamesWon: j['manualGamesWon'] != null
            ? Map<String, int>.from(j['manualGamesWon'] as Map)
            : const {},
        actualStartTime: j['actualStartTime'] != null
            ? DateTime.parse(j['actualStartTime'] as String)
            : null,
        actualEndTime: j['actualEndTime'] != null
            ? DateTime.parse(j['actualEndTime'] as String)
            : null,
      );
}

// ── Round ─────────────────────────────────────────────────────────────────────
// Mirrors ScrambleRound's shape exactly (scheduledStartTime + split
// matchDuration/breakDuration) so the Overview page's Timeline section and
// Schedule Preview can be reused verbatim.

class ScrambleKingRound {
  final String id;
  final int roundNumber;
  final DateTime scheduledStartTime;
  final Duration matchDuration;
  final Duration breakDuration;
  final DateTime? actualStartTime;
  final DateTime? actualEndTime;
  final List<ScrambleKingCourtFormation> courts;

  const ScrambleKingRound({
    required this.id,
    required this.roundNumber,
    required this.scheduledStartTime,
    required this.matchDuration,
    required this.breakDuration,
    this.actualStartTime,
    this.actualEndTime,
    required this.courts,
  });

  DateTime get scheduledMatchEndTime => scheduledStartTime.add(matchDuration);
  DateTime get scheduledBreakEndTime => scheduledMatchEndTime.add(breakDuration);
  Duration get totalDuration => matchDuration + breakDuration;

  bool get isCompleted => actualEndTime != null;

  ScrambleKingCourtFormation? getCourt(int courtNumber) => courts
      .cast<ScrambleKingCourtFormation?>()
      .firstWhere((c) => c?.courtNumber == courtNumber, orElse: () => null);

  ScrambleKingRound copyWith({
    DateTime? scheduledStartTime,
    Duration? matchDuration,
    Duration? breakDuration,
    DateTime? actualStartTime,
    DateTime? actualEndTime,
    List<ScrambleKingCourtFormation>? courts,
  }) =>
      ScrambleKingRound(
        id: id,
        roundNumber: roundNumber,
        scheduledStartTime: scheduledStartTime ?? this.scheduledStartTime,
        matchDuration: matchDuration ?? this.matchDuration,
        breakDuration: breakDuration ?? this.breakDuration,
        actualStartTime: actualStartTime ?? this.actualStartTime,
        actualEndTime: actualEndTime ?? this.actualEndTime,
        courts: courts ?? this.courts,
      );

  ScrambleKingRound updateCourt(ScrambleKingCourtFormation updated) =>
      copyWith(
        courts: courts
            .map((c) => c.courtNumber == updated.courtNumber ? updated : c)
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'roundNumber': roundNumber,
        'scheduledStartTime': scheduledStartTime.toIso8601String(),
        'matchDurationSeconds': matchDuration.inSeconds,
        'breakDurationSeconds': breakDuration.inSeconds,
        'actualStartTime': actualStartTime?.toIso8601String(),
        'actualEndTime': actualEndTime?.toIso8601String(),
        'courts': courts.map((c) => c.toJson()).toList(),
      };

  factory ScrambleKingRound.fromJson(Map<String, dynamic> j) =>
      ScrambleKingRound(
        id: j['id'] as String,
        roundNumber: j['roundNumber'] as int,
        scheduledStartTime: DateTime.parse(j['scheduledStartTime'] as String),
        matchDuration: Duration(seconds: j['matchDurationSeconds'] as int),
        breakDuration: Duration(seconds: j['breakDurationSeconds'] as int),
        actualStartTime: j['actualStartTime'] != null
            ? DateTime.parse(j['actualStartTime'] as String)
            : null,
        actualEndTime: j['actualEndTime'] != null
            ? DateTime.parse(j['actualEndTime'] as String)
            : null,
        courts: (j['courts'] as List)
            .map((e) => ScrambleKingCourtFormation.fromJson(
                Map<String, dynamic>.from(e as Map)))
            .toList(),
      );

  static String generateId() => _uuid.v4();
}

// ── Stint ─────────────────────────────────────────────────────────────────────
// One committed "turn" on court, for one court, in one round.

class ScrambleKingStint {
  final String id;
  final String roundId;
  final int courtNumber;
  /// Whose queue TURN this was — a team slotId, or the floater's slotId.
  final String turnSlotId;
  /// Whose team gets the POINTS — equal to [turnSlotId] for every stint,
  /// including the floater's: the floater's own team is credited, never the
  /// borrowed partner's team.
  final String creditSlotId;
  final List<String> playerIds; // the 2 who actually played this stint
  final bool isFloaterStint;
  final String? standInPlayerId; // set iff isFloaterStint — the floater's id
  final int points;
  final int gamesWon;
  final DateTime startTime;
  final DateTime? endTime;
  final ScrambleKingStintEndReason endReason;

  const ScrambleKingStint({
    required this.id,
    required this.roundId,
    required this.courtNumber,
    required this.turnSlotId,
    required this.creditSlotId,
    required this.playerIds,
    this.isFloaterStint = false,
    this.standInPlayerId,
    this.points = 0,
    this.gamesWon = 0,
    required this.startTime,
    this.endTime,
    this.endReason = ScrambleKingStintEndReason.manual,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'roundId': roundId,
        'courtNumber': courtNumber,
        'turnSlotId': turnSlotId,
        'creditSlotId': creditSlotId,
        'playerIds': playerIds,
        'isFloaterStint': isFloaterStint,
        'standInPlayerId': standInPlayerId,
        'points': points,
        'gamesWon': gamesWon,
        'startTime': startTime.toIso8601String(),
        'endTime': endTime?.toIso8601String(),
        'endReason': endReason.name,
      };

  factory ScrambleKingStint.fromJson(Map<String, dynamic> j) =>
      ScrambleKingStint(
        id: j['id'] as String,
        roundId: j['roundId'] as String,
        courtNumber: j['courtNumber'] as int,
        turnSlotId: j['turnSlotId'] as String,
        creditSlotId: j['creditSlotId'] as String,
        playerIds: List<String>.from(j['playerIds'] as List),
        isFloaterStint: j['isFloaterStint'] as bool? ?? false,
        standInPlayerId: j['standInPlayerId'] as String?,
        points: j['points'] as int? ?? 0,
        gamesWon: j['gamesWon'] as int? ?? 0,
        startTime: DateTime.parse(j['startTime'] as String),
        endTime: j['endTime'] != null
            ? DateTime.parse(j['endTime'] as String)
            : null,
        endReason: ScrambleKingStintEndReason.values.byName(
            (j['endReason'] as String?) ??
                ScrambleKingStintEndReason.manual.name),
      );

  static String generateId() => _uuid.v4();
}

// ── Round/court results (derived) ────────────────────────────────────────────

class ScrambleKingTeamResult {
  final String slotId;
  final List<String> playerIds;
  final int autoPoints;
  final int? manualPoints;
  final int autoGamesWon;
  final int? manualGamesWon;
  final int gamesPlayed;
  int rank;

  ScrambleKingTeamResult({
    required this.slotId,
    required this.playerIds,
    required this.autoPoints,
    this.manualPoints,
    this.autoGamesWon = 0,
    this.manualGamesWon,
    this.gamesPlayed = 0,
    this.rank = 0,
  });

  int get points => manualPoints ?? autoPoints;
  int get gamesWon => manualGamesWon ?? autoGamesWon;
  bool get isManualOverride => manualPoints != null || manualGamesWon != null;
}

class ScrambleKingCourtRoundResult {
  final int courtNumber;
  final List<ScrambleKingTeamResult> teamResults; // ranked, points desc

  const ScrambleKingCourtRoundResult({
    required this.courtNumber,
    required this.teamResults,
  });
}

// ── Player stats (computed, not persisted) ───────────────────────────────────

class ScrambleKingPlayerStats {
  final String playerId;
  final String playerName;
  final PlayerStatus status;
  final int totalPoints;
  final int totalGamesWon;
  final int roundsPlayed;
  int rank;

  ScrambleKingPlayerStats({
    required this.playerId,
    required this.playerName,
    this.status = PlayerStatus.active,
    this.totalPoints = 0,
    this.totalGamesWon = 0,
    this.roundsPlayed = 0,
    this.rank = 0,
  });
}

// ── Tournament ────────────────────────────────────────────────────────────────

class ScrambleKingTournament {
  final String id;
  final String name;
  final int courtCount; // 1-8
  final int roundCount; // target number of rounds
  final Duration matchDuration;
  final Duration breakDuration;
  final int strikePoints; // 0 = manual-only ejection
  final ScrambleKingAssignmentMode assignmentMode;
  final ScrambleKingOddPlayerMode oddPlayerMode;
  final bool paceAlertsEnabled;
  final DateTime startTime;
  final List<ScrambleKingPlayer> players;
  final List<ScrambleKingRound> rounds; // all rounds pre-generated upfront
  final List<ScrambleKingStint> stints; // flat, append-only history
  final DateTime createdAt;
  final String deviceId;

  ScrambleKingTournament({
    required this.id,
    required this.name,
    required this.courtCount,
    required this.roundCount,
    required this.matchDuration,
    required this.breakDuration,
    this.strikePoints = 0,
    this.assignmentMode = ScrambleKingAssignmentMode.manual,
    this.oddPlayerMode = ScrambleKingOddPlayerMode.placeholder,
    this.paceAlertsEnabled = false,
    required this.startTime,
    required this.players,
    required this.rounds,
    required this.stints,
    required this.createdAt,
    String? deviceId,
  }) : deviceId = deviceId ?? DeviceIdService.currentDeviceId;

  int get playerCount => players.length;
  int get roundsCount => rounds.length;
  int get completedRounds => rounds.where((r) => r.isCompleted).length;
  double get progressFraction =>
      rounds.isEmpty ? 0 : completedRounds / rounds.length;

  ScrambleKingTournamentStatus get status {
    if (rounds.isEmpty) return ScrambleKingTournamentStatus.setup;
    if (completedRounds == rounds.length) {
      return ScrambleKingTournamentStatus.completed;
    }
    if (completedRounds > 0 || stints.isNotEmpty) {
      return ScrambleKingTournamentStatus.inProgress;
    }
    return ScrambleKingTournamentStatus.setup;
  }

  ScrambleKingRound? getRound(String roundId) => rounds
      .cast<ScrambleKingRound?>()
      .firstWhere((r) => r?.id == roundId, orElse: () => null);

  ScrambleKingPlayer? getPlayer(String playerId) => players
      .cast<ScrambleKingPlayer?>()
      .firstWhere((p) => p?.id == playerId, orElse: () => null);

  List<ScrambleKingStint> getStintsForRound(String roundId) =>
      stints.where((s) => s.roundId == roundId).toList();

  List<ScrambleKingStint> getStintsForCourt(String roundId, int courtNumber) =>
      stints
          .where((s) => s.roundId == roundId && s.courtNumber == courtNumber)
          .toList()
        ..sort((a, b) => a.startTime.compareTo(b.startTime));

  ScrambleKingTournament copyWith({
    String? name,
    int? courtCount,
    int? roundCount,
    int? strikePoints,
    DateTime? startTime,
    bool? paceAlertsEnabled,
    ScrambleKingAssignmentMode? assignmentMode,
    ScrambleKingOddPlayerMode? oddPlayerMode,
    List<ScrambleKingPlayer>? players,
    List<ScrambleKingRound>? rounds,
    List<ScrambleKingStint>? stints,
  }) =>
      ScrambleKingTournament(
        id: id,
        name: name ?? this.name,
        courtCount: courtCount ?? this.courtCount,
        roundCount: roundCount ?? this.roundCount,
        matchDuration: matchDuration,
        breakDuration: breakDuration,
        strikePoints: strikePoints ?? this.strikePoints,
        assignmentMode: assignmentMode ?? this.assignmentMode,
        oddPlayerMode: oddPlayerMode ?? this.oddPlayerMode,
        paceAlertsEnabled: paceAlertsEnabled ?? this.paceAlertsEnabled,
        startTime: startTime ?? this.startTime,
        players: players ?? this.players,
        rounds: rounds ?? this.rounds,
        stints: stints ?? this.stints,
        createdAt: createdAt,
        deviceId: deviceId,
      );

  ScrambleKingTournament updateRound(ScrambleKingRound updated) => copyWith(
        rounds: rounds.map((r) => r.id == updated.id ? updated : r).toList(),
      );

  ScrambleKingTournament addStint(ScrambleKingStint stint) => copyWith(
        stints: [...stints, stint],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'courtCount': courtCount,
        'roundCount': roundCount,
        'matchDurationSeconds': matchDuration.inSeconds,
        'breakDurationSeconds': breakDuration.inSeconds,
        'strikePoints': strikePoints,
        'assignmentMode': assignmentMode.name,
        'oddPlayerMode': oddPlayerMode.name,
        'paceAlertsEnabled': paceAlertsEnabled,
        'startTime': startTime.toIso8601String(),
        'players': players.map((p) => p.toJson()).toList(),
        'rounds': rounds.map((r) => r.toJson()).toList(),
        'stints': stints.map((s) => s.toJson()).toList(),
        'createdAt': createdAt.toIso8601String(),
        'deviceId': deviceId,
      };

  factory ScrambleKingTournament.fromJson(Map<String, dynamic> j) =>
      ScrambleKingTournament(
        id: j['id'] as String,
        name: j['name'] as String,
        courtCount: j['courtCount'] as int,
        roundCount: j['roundCount'] as int,
        matchDuration: Duration(seconds: j['matchDurationSeconds'] as int),
        breakDuration: Duration(seconds: j['breakDurationSeconds'] as int),
        strikePoints: j['strikePoints'] as int? ?? 0,
        assignmentMode: ScrambleKingAssignmentMode.values.byName(
            (j['assignmentMode'] as String?) ??
                ScrambleKingAssignmentMode.manual.name),
        oddPlayerMode: ScrambleKingOddPlayerMode.values.byName(
            (j['oddPlayerMode'] as String?) ??
                ScrambleKingOddPlayerMode.placeholder.name),
        paceAlertsEnabled: j['paceAlertsEnabled'] as bool? ?? false,
        startTime: DateTime.parse(j['startTime'] as String),
        players: (j['players'] as List)
            .map((e) => ScrambleKingPlayer.fromJson(
                Map<String, dynamic>.from(e as Map)))
            .toList(),
        rounds: (j['rounds'] as List)
            .map((e) => ScrambleKingRound.fromJson(
                Map<String, dynamic>.from(e as Map)))
            .toList(),
        stints: (j['stints'] as List)
            .map((e) => ScrambleKingStint.fromJson(
                Map<String, dynamic>.from(e as Map)))
            .toList(),
        createdAt: DateTime.parse(j['createdAt'] as String),
        deviceId: j['deviceId'] as String? ?? '',
      );

  static String generateId() => _uuid.v4();
}
