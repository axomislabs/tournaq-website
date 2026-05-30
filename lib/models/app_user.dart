/// A registered player or team member in TournaQ.
///
/// [AppUser] represents a named person who can be assigned to [Team]s and
/// [Club]s. The model is intentionally lightweight for v1 — no authentication,
/// no passwords, no remote identity. Users are local identifiers only.
///
/// Design decision — local identity without auth:
///   v1 is a single-device, local-first app. "Users" here are roster entries
///   (player names for scorecards and lineups), not authentication principals.
///   When Firebase Auth is introduced, this model will gain a `uid` field
///   linking it to a Firebase user document, but the local [id] field will
///   remain as the primary key within Hive.
///
/// [role] is a free-text field reserved for future use (e.g. "Captain",
///   "Coach"). It is not used in any current scoring or tournament logic.
class AppUser {
  static const int schemaVersion = 1;
  final String id;
  final String name;
  final String? email;
  final List<String> teamIds;
  final String? role;

  const AppUser({
    required this.id,
    required this.name,
    this.email,
    this.teamIds = const [],
    this.role,
  });

  AppUser copyWith({
    String? id,
    String? name,
    String? email,
    List<String>? teamIds,
    String? role,
  }) {
    return AppUser(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      teamIds: teamIds ?? this.teamIds,
      role: role ?? this.role,
    );
  }

  AppUser addTeamId(String teamId) {
    if (teamIds.contains(teamId)) return this;
    return copyWith(teamIds: [...teamIds, teamId]);
  }

  AppUser removeTeamId(String teamId) {
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
      };

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        id: json['id'] as String,
        name: json['name'] as String,
        email: json['email'] as String?,
        teamIds: List<String>.from(json['teamIds'] as List? ?? []),
        role: json['role'] as String?,
      );
}
