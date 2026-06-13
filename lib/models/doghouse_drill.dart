import 'package:uuid/uuid.dart';
import '../services/device_id_service.dart';

const _uuid = Uuid();

enum DoghouseTournamentStatus { setup, inProgress, completed }

enum DoghousePlayerSource { existing, created, random }

enum DoghouseAssignmentMode { manual, automated }

// ── Player ────────────────────────────────────────────────────────────────────

class DoghousePlayer {
  final String id;
  final String name;
  final DoghousePlayerSource source;
  final String? appUserId;
  final bool isLate;

  const DoghousePlayer({
    required this.id,
    required this.name,
    required this.source,
    this.appUserId,
    this.isLate = false,
  });

  DoghousePlayer copyWith({String? name}) => DoghousePlayer(
        id: id,
        name: name ?? this.name,
        source: source,
        appUserId: appUserId,
        isLate: isLate,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'source': source.name,
        'appUserId': appUserId,
        'isLate': isLate,
      };

  factory DoghousePlayer.fromJson(Map<String, dynamic> j) => DoghousePlayer(
        id: j['id'] as String,
        name: j['name'] as String,
        source: DoghousePlayerSource.values.byName(
            (j['source'] as String?) ?? DoghousePlayerSource.random.name),
        appUserId: j['appUserId'] as String?,
        isLate: j['isLate'] as bool? ?? false,
      );

  static String generateId() => _uuid.v4();
}

// ── Game ──────────────────────────────────────────────────────────────────────
// One team's time in the doghouse — committed when the game ends.

class DoghouseGame {
  final String id;
  final List<String> playerIds;
  final int points;      // points scored by the doghouse team
  final int gamesLost;   // times the court team scored
  final int gamesWon;    // 1 if escaped, 0 if auto-ejected
  final DateTime startTime;
  final DateTime? endTime;

  const DoghouseGame({
    required this.id,
    required this.playerIds,
    this.points = 0,
    this.gamesLost = 0,
    this.gamesWon = 0,
    required this.startTime,
    this.endTime,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'playerIds': playerIds,
        'points': points,
        'gamesLost': gamesLost,
        'gamesWon': gamesWon,
        'startTime': startTime.toIso8601String(),
        'endTime': endTime?.toIso8601String(),
      };

  factory DoghouseGame.fromJson(Map<String, dynamic> j) => DoghouseGame(
        id: j['id'] as String,
        playerIds: List<String>.from(j['playerIds'] as List),
        points: (j['points'] ?? j['sideOuts']) as int? ?? 0,
        gamesLost: j['gamesLost'] as int? ?? 0,
        gamesWon: j['gamesWon'] as int? ?? 0,
        startTime: DateTime.parse(j['startTime'] as String),
        endTime: j['endTime'] != null
            ? DateTime.parse(j['endTime'] as String)
            : null,
      );

  static String generateId() => _uuid.v4();
}

// ── Drill ─────────────────────────────────────────────────────────────────────

class DoghouseTournament {
  final String id;
  final String name;
  final Duration totalTime;
  final int playersPerTeam;
  final int courtCount;      // always 1, kept for model consistency
  final int escapePoints;    // side-outs needed to escape
  final int lossLimit;  // games lost before auto-eject
  final DoghouseAssignmentMode assignmentMode;
  final DoghouseTournamentStatus status;
  final List<DoghousePlayer> players;
  final List<DoghouseGame> games;
  final DateTime createdAt;
  final String deviceId;
  final int? remainingSeconds;

  DoghouseTournament({
    required this.id,
    required this.name,
    required this.totalTime,
    this.playersPerTeam = 2,
    this.courtCount = 1,
    this.escapePoints = 3,
    this.lossLimit = 3,
    this.assignmentMode = DoghouseAssignmentMode.manual,
    required this.status,
    required this.players,
    required this.games,
    required this.createdAt,
    String? deviceId,
    this.remainingSeconds,
  }) : deviceId = deviceId ?? DeviceIdService.currentDeviceId;

  int get playerCount  => players.length;
  int get gameCount    => games.length;
  int get totalEscapes => games.where((g) => g.gamesWon > 0).length;
  int get totalPoints => games.fold(0, (sum, g) => sum + g.points);

  Map<String, int> get pointsPerPlayer {
    final map = <String, int>{};
    for (final game in games) {
      for (final pid in game.playerIds) {
        map[pid] = (map[pid] ?? 0) + game.points;
      }
    }
    return map;
  }

  Map<String, int> get escapesPerPlayer {
    final map = <String, int>{};
    for (final game in games) {
      for (final pid in game.playerIds) {
        map[pid] = (map[pid] ?? 0) + game.gamesWon;
      }
    }
    return map;
  }

  Map<String, int> get gamesLostPerPlayer {
    final map = <String, int>{};
    for (final game in games) {
      if (game.gamesWon == 0) {
        for (final pid in game.playerIds) {
          map[pid] = (map[pid] ?? 0) + 1;
        }
      }
    }
    return map;
  }

  Map<String, int> get gamesPerPlayer {
    final map = <String, int>{};
    for (final game in games) {
      for (final pid in game.playerIds) {
        map[pid] = (map[pid] ?? 0) + 1;
      }
    }
    return map;
  }

  DoghouseTournament copyWith({
    DoghouseTournamentStatus? status,
    List<DoghousePlayer>? players,
    List<DoghouseGame>? games,
    int? remainingSeconds,
  }) =>
      DoghouseTournament(
        id: id,
        name: name,
        totalTime: totalTime,
        playersPerTeam: playersPerTeam,
        courtCount: courtCount,
        escapePoints: escapePoints,
        lossLimit: lossLimit,
        assignmentMode: assignmentMode,
        status: status ?? this.status,
        players: players ?? this.players,
        games: games ?? this.games,
        createdAt: createdAt,
        deviceId: deviceId,
        remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'totalTimeSeconds': totalTime.inSeconds,
        'playersPerTeam': playersPerTeam,
        'courtCount': courtCount,
        'escapePoints': escapePoints,
        'lossLimit': lossLimit,
        'assignmentMode': assignmentMode.name,
        'status': status.name,
        'players': players.map((p) => p.toJson()).toList(),
        'games': games.map((g) => g.toJson()).toList(),
        'createdAt': createdAt.toIso8601String(),
        'deviceId': deviceId,
        'remainingSeconds': remainingSeconds,
      };

  factory DoghouseTournament.fromJson(Map<String, dynamic> j) => DoghouseTournament(
        id: j['id'] as String,
        name: j['name'] as String,
        totalTime: Duration(seconds: j['totalTimeSeconds'] as int),
        playersPerTeam: j['playersPerTeam'] as int? ?? 2,
        courtCount: j['courtCount'] as int? ?? 1,
        escapePoints: j['escapePoints'] as int? ?? 3,
        lossLimit: (j['lossLimit'] ?? j['ejectThreshold']) as int? ?? 3,
        assignmentMode: DoghouseAssignmentMode.values.byName(
            (j['assignmentMode'] as String?) ?? DoghouseAssignmentMode.manual.name),
        status: DoghouseTournamentStatus.values.byName(
            (j['status'] as String?) ?? DoghouseTournamentStatus.setup.name),
        players: (j['players'] as List)
            .map((e) =>
                DoghousePlayer.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
        games: ((j['games'] as List?) ?? [])
            .map((e) =>
                DoghouseGame.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
        createdAt: DateTime.parse(j['createdAt'] as String),
        deviceId: j['deviceId'] as String? ?? '',
        remainingSeconds: j['remainingSeconds'] as int?,
      );

  static String generateId() => _uuid.v4();
}
