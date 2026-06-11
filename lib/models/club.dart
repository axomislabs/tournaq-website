import '../services/device_id_service.dart';

class Club {
  static const int schemaVersion = 2;

  final String id;
  final String name;
  final List<String> playerIds;
  final List<String> teamIds;
  final List<String> tournamentIds;
  final String deviceId;
  final DateTime createdAt;

  Club({
    required this.id,
    required this.name,
    this.playerIds = const [],
    this.teamIds = const [],
    this.tournamentIds = const [],
    String? deviceId,
    DateTime? createdAt,
  })  : deviceId = deviceId ?? DeviceIdService.currentDeviceId,
        createdAt = createdAt ?? DateTime.now();

  Club copyWith({
    String? id,
    String? name,
    List<String>? playerIds,
    List<String>? teamIds,
    List<String>? tournamentIds,
  }) {
    return Club(
      id: id ?? this.id,
      name: name ?? this.name,
      playerIds: playerIds ?? this.playerIds,
      teamIds: teamIds ?? this.teamIds,
      tournamentIds: tournamentIds ?? this.tournamentIds,
      deviceId: deviceId,
      createdAt: createdAt,
    );
  }

  Club addPlayerId(String playerId) {
    if (playerIds.contains(playerId)) return this;
    return copyWith(playerIds: [...playerIds, playerId]);
  }

  Club removePlayerId(String playerId) {
    return copyWith(
        playerIds: playerIds.where((id) => id != playerId).toList());
  }

  Club addTeamId(String teamId) {
    if (teamIds.contains(teamId)) return this;
    return copyWith(teamIds: [...teamIds, teamId]);
  }

  Club removeTeamId(String teamId) {
    return copyWith(
        teamIds: teamIds.where((id) => id != teamId).toList());
  }

  Club addTournamentId(String tournamentId) {
    if (tournamentIds.contains(tournamentId)) return this;
    return copyWith(tournamentIds: [...tournamentIds, tournamentId]);
  }

  Club removeTournamentId(String tournamentId) {
    return copyWith(
      tournamentIds:
          tournamentIds.where((id) => id != tournamentId).toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'schemaVersion': schemaVersion,
        'id': id,
        'name': name,
        'playerIds': playerIds,
        'teamIds': teamIds,
        'tournamentIds': tournamentIds,
        'deviceId': deviceId,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Club.fromJson(Map<String, dynamic> json) => Club(
        id: json['id'] as String,
        name: json['name'] as String,
        playerIds:
            List<String>.from(json['playerIds'] as List? ?? []),
        teamIds: List<String>.from(json['teamIds'] as List? ?? []),
        tournamentIds:
            List<String>.from(json['tournamentIds'] as List? ?? []),
        deviceId: json['deviceId'] as String? ?? '',
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'] as String)
            : DateTime.fromMillisecondsSinceEpoch(0),
      );
}
