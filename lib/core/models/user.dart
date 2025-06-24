class User {
  final String userId;
  final String username;
  final String avatarUrl;
  final List<String> authMethods;
  final String? email;

  User({
    required this.userId,
    required this.username,
    required this.avatarUrl,
    this.authMethods = const [],
    this.email,
  });

  // Factory method to create a User object from a JSON response
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      userId: json['user_id'] ?? '',
      username: json['discord_username'] ?? json['username'] ?? 'Unknown',
      avatarUrl: json['avatar_url'] ?? '',
      authMethods: List<String>.from(json['auth_methods'] ?? []),
      email: json['email'],
    );
  }

  // Convert the User object to a JSON format (useful for caching)
  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'username': username,
      'avatar_url': avatarUrl,
      'auth_methods': authMethods,
      'email': email,
    };
  }

  // Helper methods for checking auth methods
  bool get hasDiscordAuth => authMethods.contains('discord');
  bool get hasEmailAuth => authMethods.contains('email');
  bool get hasMultipleAuthMethods => authMethods.length > 1;
}
