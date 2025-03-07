class User {
  final String userId;
  final String username;
  final String avatarUrl;

  User({
    required this.userId,
    required this.username,
    required this.avatarUrl,
  });

  // Factory method to create a User object from a JSON response
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      userId: json['user_id'],
      username: json['discord_username'],
      avatarUrl: json['avatar_url'],
    );
  }

  // Convert the User object to a JSON format (useful for caching)
  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'discord_username': username,
      'avatar_url': avatarUrl,
    };
  }
}
