import 'package:uuid/uuid.dart';
import '../services/device_id_service.dart';

const _uuid = Uuid();

enum KotcTournamentStatus { setup, inProgress, completed }

enum KotcPlayerSource { existing, created, random }

// ── Player ────────────────────────────────────────────────────────────────────

class KotcPlayer {
  final String id;
  final String name;
  final KotcPlayerSource source;
  final String? appUserId;
  // True when the player joined after the tournament started.
  final bool isLate;

  const KotcPlayer({
    required this.id,
    required this.name,
    required this.source,
    this.appUserId,
    this.isLate = false,
  });

  KotcPlayer copyWith({String? name}) => KotcPlayer(
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

  factory KotcPlayer.fromJson(Map<String, dynamic> j) => KotcPlayer(
        id: j['id'] as String,
        name: j['name'] as String,
        source: KotcPlayerSource.values.byName(
            (j['source'] as String?) ?? KotcPlayerSource.random.name),
        appUserId: j['appUserId'] as String?,
        isLate: j['isLate'] as bool? ?? false,
      );

  static String generateId() => _uuid.v4();
}

// ── Game ──────────────────────────────────────────────────────────────────────
// One team's time on court — committed when the team is ejected.

class KotcGame {
  final String id;
  final List<String> playerIds;
  final int points;
  final int gamesWon;
  final DateTime startTime;
  final DateTime? endTime;

  const KotcGame({
    required this.id,
    required this.playerIds,
    this.points = 0,
    this.gamesWon = 0,
    required this.startTime,
    this.endTime,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'playerIds': playerIds,
        'points': points,
        'gamesWon': gamesWon,
        'startTime': startTime.toIso8601String(),
        'endTime': endTime?.toIso8601String(),
      };

  factory KotcGame.fromJson(Map<String, dynamic> j) => KotcGame(
        id: j['id'] as String,
        playerIds: List<String>.from(j['playerIds'] as List),
        points: j['points'] as int? ?? 0,
        gamesWon: j['gamesWon'] as int? ?? 0,
        startTime: DateTime.parse(j['startTime'] as String),
        endTime: j['endTime'] != null
            ? DateTime.parse(j['endTime'] as String)
            : null,
      );

  static String generateId() => _uuid.v4();
}

// ── Tournament ────────────────────────────────────────────────────────────────

class KingOfTheCourtTournament {
  final String id;
  final String name;
  final Duration totalTime;
  final int playersPerTeam;
  final int courtCount;
  final int strikePoints;
  final KotcTournamentStatus status;
  final List<KotcPlayer> players;
  final List<KotcGame> games;
  final DateTime createdAt;
  final String deviceId;
  // Persisted so the timer survives app restarts.
  final int? remainingSeconds;

  KingOfTheCourtTournament({
    required this.id,
    required this.name,
    required this.totalTime,
    this.playersPerTeam = 2,
    this.courtCount = 1,
    this.strikePoints = 0,
    required this.status,
    required this.players,
    required this.games,
    required this.createdAt,
    String? deviceId,
    this.remainingSeconds,
  }) : deviceId = deviceId ?? DeviceIdService.currentDeviceId;

  int get playerCount => players.length;
  int get gameCount   => games.length;

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

  Map<String, int> get gamesWonPerPlayer {
    final map = <String, int>{};
    for (final game in games) {
      for (final pid in game.playerIds) {
        map[pid] = (map[pid] ?? 0) + game.gamesWon;
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

  KingOfTheCourtTournament copyWith({
    KotcTournamentStatus? status,
    List<KotcPlayer>? players,
    List<KotcGame>? games,
    int? remainingSeconds,
  }) =>
      KingOfTheCourtTournament(
        id: id,
        name: name,
        totalTime: totalTime,
        playersPerTeam: playersPerTeam,
        courtCount: courtCount,
        strikePoints: strikePoints,
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
        'strikePoints': strikePoints,
        'status': status.name,
        'players': players.map((p) => p.toJson()).toList(),
        'games': games.map((g) => g.toJson()).toList(),
        'createdAt': createdAt.toIso8601String(),
        'deviceId': deviceId,
        'remainingSeconds': remainingSeconds,
      };

  factory KingOfTheCourtTournament.fromJson(Map<String, dynamic> j) {
    // Accept both 'games' (new) and 'stints' (legacy) key.
    final rawGames = (j['games'] ?? j['stints']) as List? ?? [];
    return KingOfTheCourtTournament(
      id: j['id'] as String,
      name: j['name'] as String,
      totalTime: Duration(seconds: j['totalTimeSeconds'] as int),
      playersPerTeam: j['playersPerTeam'] as int? ?? 2,
      courtCount: j['courtCount'] as int? ?? 1,
      strikePoints: j['strikePoints'] as int? ?? 0,
      status: KotcTournamentStatus.values.byName(
          (j['status'] as String?) ?? KotcTournamentStatus.setup.name),
      players: (j['players'] as List)
          .map((e) =>
              KotcPlayer.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      games: rawGames
          .map((e) =>
              KotcGame.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      createdAt: DateTime.parse(j['createdAt'] as String),
      deviceId: j['deviceId'] as String? ?? '',
      remainingSeconds: j['remainingSeconds'] as int?,
    );
  }

  static String generateId() => _uuid.v4();
}
