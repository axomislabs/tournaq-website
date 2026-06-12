import 'package:uuid/uuid.dart';
import '../services/device_id_service.dart';

const _uuid = Uuid();

enum ScrambleTournamentStatus { setup, inProgress, completed }

enum ScramblePlayerSource { existing, created, random }

enum ScrambleGameStatus { scheduled, inProgress, completed }

// ── Player ────────────────────────────────────────────────────────────────────

class ScramblePlayer {
  final String id;
  final String name;
  final ScramblePlayerSource source;
  final String? appUserId;

  const ScramblePlayer({
    required this.id,
    required this.name,
    required this.source,
    this.appUserId,
  });

  ScramblePlayer copyWith({String? name}) => ScramblePlayer(
        id: id,
        name: name ?? this.name,
        source: source,
        appUserId: appUserId,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'source': source.name,
        'appUserId': appUserId,
      };

  factory ScramblePlayer.fromJson(Map<String, dynamic> j) => ScramblePlayer(
        id: j['id'] as String,
        name: j['name'] as String,
        source: ScramblePlayerSource.values.byName(
            (j['source'] as String?) ?? ScramblePlayerSource.random.name),
        appUserId: j['appUserId'] as String?,
      );

  static String generateId() => _uuid.v4();
}

// ── Game ─────────────────────────────────────────────────────────────────────

class ScrambleGame {
  final String id;
  final String roundId;
  final int courtNumber;
  final List<String> sideAPlayerIds;
  final List<String> sideBPlayerIds;
  final List<String> sittingOutPlayerIds;
  final int sideAScore;
  final int sideBScore;
  final ScrambleGameStatus status;
  final DateTime? actualStartTime;
  final DateTime? actualEndTime;

  const ScrambleGame({
    required this.id,
    required this.roundId,
    required this.courtNumber,
    required this.sideAPlayerIds,
    required this.sideBPlayerIds,
    this.sittingOutPlayerIds = const [],
    this.sideAScore = 0,
    this.sideBScore = 0,
    this.status = ScrambleGameStatus.scheduled,
    this.actualStartTime,
    this.actualEndTime,
  });

  bool get isCompleted => status == ScrambleGameStatus.completed;

  /// 'A', 'B', or null (draw / not completed)
  String? get winningSide {
    if (!isCompleted) return null;
    if (sideAScore > sideBScore) return 'A';
    if (sideBScore > sideAScore) return 'B';
    return null;
  }

  ScrambleGame copyWith({
    int? sideAScore,
    int? sideBScore,
    ScrambleGameStatus? status,
    DateTime? actualStartTime,
    DateTime? actualEndTime,
  }) =>
      ScrambleGame(
        id: id,
        roundId: roundId,
        courtNumber: courtNumber,
        sideAPlayerIds: sideAPlayerIds,
        sideBPlayerIds: sideBPlayerIds,
        sittingOutPlayerIds: sittingOutPlayerIds,
        sideAScore: sideAScore ?? this.sideAScore,
        sideBScore: sideBScore ?? this.sideBScore,
        status: status ?? this.status,
        actualStartTime: actualStartTime ?? this.actualStartTime,
        actualEndTime: actualEndTime ?? this.actualEndTime,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'roundId': roundId,
        'courtNumber': courtNumber,
        'sideAPlayerIds': sideAPlayerIds,
        'sideBPlayerIds': sideBPlayerIds,
        'sittingOutPlayerIds': sittingOutPlayerIds,
        'sideAScore': sideAScore,
        'sideBScore': sideBScore,
        'status': status.name,
        'actualStartTime': actualStartTime?.toIso8601String(),
        'actualEndTime': actualEndTime?.toIso8601String(),
      };

  factory ScrambleGame.fromJson(Map<String, dynamic> j) => ScrambleGame(
        id: j['id'] as String,
        roundId: j['roundId'] as String,
        courtNumber: j['courtNumber'] as int,
        sideAPlayerIds: List<String>.from(
            (j['sideAPlayerIds'] ?? j['teamAPlayerIds'] ?? []) as List),
        sideBPlayerIds: List<String>.from(
            (j['sideBPlayerIds'] ?? j['teamBPlayerIds'] ?? []) as List),
        sittingOutPlayerIds: List<String>.from(
            (j['sittingOutPlayerIds'] ?? []) as List),
        sideAScore: (j['sideAScore'] ?? j['teamAScore'] ?? 0) as int,
        sideBScore: (j['sideBScore'] ?? j['teamBScore'] ?? 0) as int,
        status: ScrambleGameStatus.values.byName(
            (j['status'] as String?) ?? ScrambleGameStatus.scheduled.name),
        actualStartTime: j['actualStartTime'] != null
            ? DateTime.parse(j['actualStartTime'] as String)
            : null,
        actualEndTime: j['actualEndTime'] != null
            ? DateTime.parse(j['actualEndTime'] as String)
            : null,
      );

  static String generateId() => _uuid.v4();
}

// ── Round ─────────────────────────────────────────────────────────────────────

class ScrambleRound {
  final String id;
  final int roundNumber;
  final DateTime scheduledStartTime;
  final Duration matchDuration;
  final Duration breakDuration;
  final DateTime? actualStartTime;
  final DateTime? actualEndTime;

  const ScrambleRound({
    required this.id,
    required this.roundNumber,
    required this.scheduledStartTime,
    required this.matchDuration,
    required this.breakDuration,
    this.actualStartTime,
    this.actualEndTime,
  });

  DateTime get scheduledMatchEndTime => scheduledStartTime.add(matchDuration);
  DateTime get scheduledBreakEndTime => scheduledMatchEndTime.add(breakDuration);
  Duration get totalDuration => matchDuration + breakDuration;

  ScrambleRound copyWith({
    DateTime? scheduledStartTime,
    DateTime? actualStartTime,
    DateTime? actualEndTime,
  }) =>
      ScrambleRound(
        id: id,
        roundNumber: roundNumber,
        scheduledStartTime: scheduledStartTime ?? this.scheduledStartTime,
        matchDuration: matchDuration,
        breakDuration: breakDuration,
        actualStartTime: actualStartTime ?? this.actualStartTime,
        actualEndTime: actualEndTime ?? this.actualEndTime,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'roundNumber': roundNumber,
        'scheduledStartTime': scheduledStartTime.toIso8601String(),
        'matchDurationSeconds': matchDuration.inSeconds,
        'breakDurationSeconds': breakDuration.inSeconds,
        'actualStartTime': actualStartTime?.toIso8601String(),
        'actualEndTime': actualEndTime?.toIso8601String(),
      };

  factory ScrambleRound.fromJson(Map<String, dynamic> j) => ScrambleRound(
        id: j['id'] as String,
        roundNumber: j['roundNumber'] as int,
        scheduledStartTime:
            DateTime.parse(j['scheduledStartTime'] as String),
        matchDuration:
            Duration(seconds: j['matchDurationSeconds'] as int),
        breakDuration:
            Duration(seconds: j['breakDurationSeconds'] as int),
        actualStartTime: j['actualStartTime'] != null
            ? DateTime.parse(j['actualStartTime'] as String)
            : null,
        actualEndTime: j['actualEndTime'] != null
            ? DateTime.parse(j['actualEndTime'] as String)
            : null,
      );

  static String generateId() => _uuid.v4();
}

// ── Player Stats (computed, not persisted) ────────────────────────────────────

class ScramblePlayerStats {
  final String playerId;
  final String playerName;
  final int totalPoints;
  final int pointsAgainst;
  final int gamesPlayed;
  final int wins;
  final int losses;
  final int draws;
  final Set<String> uniqueTeammateIds;
  final Set<String> uniqueOpponentIds;
  int rank;

  ScramblePlayerStats({
    required this.playerId,
    required this.playerName,
    this.totalPoints = 0,
    this.pointsAgainst = 0,
    this.gamesPlayed = 0,
    this.wins = 0,
    this.losses = 0,
    this.draws = 0,
    Set<String>? uniqueTeammateIds,
    Set<String>? uniqueOpponentIds,
    this.rank = 0,
  })  : uniqueTeammateIds = uniqueTeammateIds ?? {},
        uniqueOpponentIds = uniqueOpponentIds ?? {};

  int get pointDifference => totalPoints - pointsAgainst;

  double get averagePointsPerGame =>
      gamesPlayed == 0 ? 0 : totalPoints / gamesPlayed;

  int get uniqueTeammates => uniqueTeammateIds.length;
  int get uniqueOpponents => uniqueOpponentIds.length;
}

// ── Tournament ────────────────────────────────────────────────────────────────

class ScrambleTournament {
  final String id;
  final String name;
  final Duration totalAvailableTime;
  final Duration matchDuration;
  final Duration breakDuration;
  final int courtCount;
  /// Players per side: 2 → 2v2, 3 → 3v3.
  final int playersPerTeam;
  final DateTime startTime;
  final ScrambleTournamentStatus status;
  final List<ScramblePlayer> players;
  final List<ScrambleRound> rounds;
  final List<ScrambleGame> games;
  final DateTime createdAt;
  final String deviceId;

  ScrambleTournament({
    required this.id,
    required this.name,
    required this.totalAvailableTime,
    required this.matchDuration,
    required this.breakDuration,
    required this.courtCount,
    this.playersPerTeam = 2,
    required this.startTime,
    required this.status,
    required this.players,
    required this.rounds,
    required this.games,
    required this.createdAt,
    String? deviceId,
  }) : deviceId = deviceId ?? DeviceIdService.currentDeviceId;

  /// How many players fill one court (both sides combined).
  int get playersPerCourt => playersPerTeam * 2;

  /// How many courts can be active given current player count.
  int get activeCourts => players.length ~/ playersPerCourt;

  /// Players sitting out each round when activeCourts × playersPerCourt < playerCount.
  int get sittingOutCount => players.length - (activeCourts * playersPerCourt);

  int get playerCount => players.length;
  int get roundCount => rounds.length;
  int get totalGames => games.length;
  int get completedGames => games.where((g) => g.isCompleted).length;

  double get progressFraction =>
      totalGames == 0 ? 0 : completedGames / totalGames;

  ScrambleRound? getRound(String roundId) =>
      rounds.cast<ScrambleRound?>().firstWhere(
            (r) => r?.id == roundId,
            orElse: () => null,
          );

  ScramblePlayer? getPlayer(String playerId) =>
      players.cast<ScramblePlayer?>().firstWhere(
            (p) => p?.id == playerId,
            orElse: () => null,
          );

  List<ScrambleGame> getGamesForRound(String roundId) =>
      games.where((g) => g.roundId == roundId).toList()
        ..sort((a, b) => a.courtNumber.compareTo(b.courtNumber));

  ScrambleTournament copyWith({
    String? name,
    ScrambleTournamentStatus? status,
    List<ScramblePlayer>? players,
    List<ScrambleRound>? rounds,
    List<ScrambleGame>? games,
    DateTime? startTime,
  }) =>
      ScrambleTournament(
        id: id,
        name: name ?? this.name,
        totalAvailableTime: totalAvailableTime,
        matchDuration: matchDuration,
        breakDuration: breakDuration,
        courtCount: courtCount,
        playersPerTeam: playersPerTeam,
        startTime: startTime ?? this.startTime,
        status: status ?? this.status,
        players: players ?? this.players,
        rounds: rounds ?? this.rounds,
        games: games ?? this.games,
        createdAt: createdAt,
        deviceId: deviceId,
      );

  ScrambleTournament updateGame(ScrambleGame updated) => copyWith(
        games:
            games.map((g) => g.id == updated.id ? updated : g).toList(),
      );

  ScrambleTournament updateRound(ScrambleRound updated) => copyWith(
        rounds:
            rounds.map((r) => r.id == updated.id ? updated : r).toList(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'totalAvailableTimeSeconds': totalAvailableTime.inSeconds,
        'matchDurationSeconds': matchDuration.inSeconds,
        'breakDurationSeconds': breakDuration.inSeconds,
        'courtCount': courtCount,
        'playersPerTeam': playersPerTeam,
        'startTime': startTime.toIso8601String(),
        'status': status.name,
        'players': players.map((p) => p.toJson()).toList(),
        'rounds': rounds.map((r) => r.toJson()).toList(),
        'games': games.map((g) => g.toJson()).toList(),
        'createdAt': createdAt.toIso8601String(),
        'deviceId': deviceId,
      };

  factory ScrambleTournament.fromJson(Map<String, dynamic> j) =>
      ScrambleTournament(
        id: j['id'] as String,
        name: j['name'] as String,
        totalAvailableTime:
            Duration(seconds: j['totalAvailableTimeSeconds'] as int),
        matchDuration:
            Duration(seconds: j['matchDurationSeconds'] as int),
        breakDuration:
            Duration(seconds: j['breakDurationSeconds'] as int),
        courtCount: j['courtCount'] as int,
        playersPerTeam: j['playersPerTeam'] as int? ?? 2,
        startTime: DateTime.parse(j['startTime'] as String),
        status: ScrambleTournamentStatus.values.byName(
            (j['status'] as String?) ??
                ScrambleTournamentStatus.setup.name),
        players: (j['players'] as List)
            .map((e) => ScramblePlayer.fromJson(
                Map<String, dynamic>.from(e as Map)))
            .toList(),
        rounds: (j['rounds'] as List)
            .map((e) => ScrambleRound.fromJson(
                Map<String, dynamic>.from(e as Map)))
            .toList(),
        games: (j['games'] as List)
            .map((e) => ScrambleGame.fromJson(
                Map<String, dynamic>.from(e as Map)))
            .toList(),
        createdAt: DateTime.parse(j['createdAt'] as String),
        deviceId: j['deviceId'] as String? ?? '',
      );

  static String generateId() => _uuid.v4();
}

// ── Setup Suggestion ──────────────────────────────────────────────────────────

enum ScrambleSuggestionType {
  increaseTotalTime,
  reduceBreakDuration,
  adjustMatchDuration,
  adjustPlayerCount,
  adjustCourtCount,
  repeatedTeammates,
  largeGroup,
}

class ScrambleSuggestion {
  final ScrambleSuggestionType type;
  final String message;
  final String? actionLabel;
  final bool isBlocking;

  const ScrambleSuggestion({
    required this.type,
    required this.message,
    this.actionLabel,
    this.isBlocking = false,
  });
}
