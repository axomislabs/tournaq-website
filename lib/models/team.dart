import '../services/device_id_service.dart';

enum TeamScope {
  temporary,
  tournament,
  club,
}

class Team {
  static const int schemaVersion = 2;
  final String id;
  final String name;
  final List<String> userIds;
  final List<String> tournamentIds;
  final TeamScope scope;
  final String deviceId;
  final DateTime createdAt;

  Team({
    required this.id,
    required this.name,
    this.userIds = const [],
    this.tournamentIds = const [],
    this.scope = TeamScope.temporary,
    String? deviceId,
    DateTime? createdAt,
  })  : deviceId = deviceId ?? DeviceIdService.currentDeviceId,
        createdAt = createdAt ?? DateTime.now();

  Team copyWith({
    String? id,
    String? name,
    List<String>? userIds,
    List<String>? tournamentIds,
    TeamScope? scope,
  }) {
    return Team(
      id: id ?? this.id,
      name: name ?? this.name,
      userIds: userIds ?? this.userIds,
      tournamentIds: tournamentIds ?? this.tournamentIds,
      scope: scope ?? this.scope,
      deviceId: deviceId,
      createdAt: createdAt,
    );
  }

  Team addUserId(String userId) {
    if (userIds.contains(userId)) return this;
    return copyWith(userIds: [...userIds, userId]);
  }

  Team removeUserId(String userId) {
    return copyWith(
      userIds: userIds.where((id) => id != userId).toList(),
    );
  }

  Team addTournamentId(String tournamentId) {
    if (tournamentIds.contains(tournamentId)) return this;
    return copyWith(tournamentIds: [...tournamentIds, tournamentId]);
  }

  Team removeTournamentId(String tournamentId) {
    return copyWith(
      tournamentIds: tournamentIds.where((id) => id != tournamentId).toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'schemaVersion': schemaVersion,
        'id': id,
        'name': name,
        'userIds': userIds,
        'tournamentIds': tournamentIds,
        'scope': scope.name,
        'deviceId': deviceId,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Team.fromJson(Map<String, dynamic> json) => Team(
        id: json['id'] as String,
        name: json['name'] as String,
        userIds: List<String>.from(json['userIds'] as List? ?? []),
        tournamentIds:
            List<String>.from(json['tournamentIds'] as List? ?? []),
        scope: TeamScope.values.firstWhere(
          (e) => e.name == json['scope'],
          orElse: () => TeamScope.temporary,
        ),
        deviceId: json['deviceId'] as String? ?? '',
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'] as String)
            : DateTime.fromMillisecondsSinceEpoch(0),
      );
}
