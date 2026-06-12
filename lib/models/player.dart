import '../services/device_id_service.dart';

class Player {
  static const int schemaVersion = 2;
  final String id;
  final String name;
  final String? email;
  final List<String> teamIds;
  final String? role;
  final String deviceId;
  final DateTime createdAt;
  // 1 = beginner, 10 = elite. null = unrated.
  final int? skillRating;

  Player({
    required this.id,
    required this.name,
    this.email,
    this.teamIds = const [],
    this.role,
    String? deviceId,
    DateTime? createdAt,
    this.skillRating,
  })  : deviceId = deviceId ?? DeviceIdService.currentDeviceId,
        createdAt = createdAt ?? DateTime.now();

  Player copyWith({
    String? id,
    String? name,
    String? email,
    List<String>? teamIds,
    String? role,
    int? skillRating,
    bool clearSkillRating = false,
  }) {
    return Player(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      teamIds: teamIds ?? this.teamIds,
      role: role ?? this.role,
      deviceId: deviceId,
      createdAt: createdAt,
      skillRating: clearSkillRating ? null : (skillRating ?? this.skillRating),
    );
  }

  Player addTeamId(String teamId) {
    if (teamIds.contains(teamId)) return this;
    return copyWith(teamIds: [...teamIds, teamId]);
  }

  Player removeTeamId(String teamId) {
    return copyWith(
      teamIds: teamIds.where((id) => id != teamId).toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'schemaVersion': schemaVersion,
        'id': id,
        'name': name,
        'email': email,
        'teamIds': teamIds,
        'role': role,
        'deviceId': deviceId,
        'createdAt': createdAt.toIso8601String(),
        'skillRating': skillRating,
      };

  factory Player.fromJson(Map<String, dynamic> json) => Player(
        id: json['id'] as String,
        name: json['name'] as String,
        email: json['email'] as String?,
        teamIds: List<String>.from(json['teamIds'] as List? ?? []),
        role: json['role'] as String?,
        deviceId: json['deviceId'] as String? ?? '',
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'] as String)
            : DateTime.fromMillisecondsSinceEpoch(0),
        skillRating: json['skillRating'] as int?,
      );
}
