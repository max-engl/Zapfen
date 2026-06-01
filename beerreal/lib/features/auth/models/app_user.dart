class AppUser {
  final String id;
  final String username;
  final String email;
  final String role;
  final String? avatarUrl;
  final String? avatarColor;
  final String? avatarInitial;

  const AppUser({
    required this.id,
    required this.username,
    required this.email,
    required this.role,
    this.avatarUrl,
    this.avatarColor,
    this.avatarInitial,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: (json['id'] ?? json['_id'] ?? '') as String,
      username: json['username'] as String,
      email: json['email'] as String,
      role: json['role'] as String,
      avatarUrl: json['avatarUrl'] as String?,
      avatarColor: json['avatarColor'] as String?,
      avatarInitial: json['avatarInitial'] as String?,
    );
  }
}
