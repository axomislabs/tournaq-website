class AppUser {
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
