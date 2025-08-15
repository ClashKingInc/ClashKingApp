import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class User {
  final String id;
  final String avatar;
  String globalName;
  bool isDiscordUser = false;
  List<String> tags = [];

  User({
    required this.id,
    required this.avatar,
    required this.globalName,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? "0",
      avatar: (json['avatar'] != null)
          ? 'https://cdn.discordapp.com/avatars/${json['id']}/${json['avatar']}.png'
          : "https://assets.clashk.ing/logos/crown-red/CK-crown-red.png",
      globalName: json['global_name'] ?? json['username'] ?? "ClashKing",
    );
  }

  @override
  String toString() {
    return 'DiscordUser{id: $id, avatar: https://cdn.discordapp.com/avatars/$id/$avatar.png, globalName: $globalName, isDiscordUser : $isDiscordUser, tags: $tags}';
  }
}

Future<User?> fetchDiscordUser(String accessToken) async {
  try {
    if (accessToken != "inviteMode") {
      final response = await http.get(
        Uri.https('discord.com', '/api/users/@me'),
        headers: {
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.statusCode == 200) {
        User user = User.fromJson(jsonDecode(response.body));
        user.isDiscordUser = true;
        user = await fetchDiscordUserTags(user); // Fetch user tags
        return user;
      } else {
        return null;
      }
    } else {
      User user = User(
        id: '0',
        avatar: 'https://assets.clashk.ing/logos/crown-red/CK-crown-red.png',
        globalName: 'ILoveClashKing',
      );
      user.isDiscordUser = false;
      return user;
    }
  } catch (e) {
    Sentry.captureException(e);
    return null;
  }
}

Future<User> fetchDiscordUserTags(User user) async {
  try {
    final response = await http.post(
      Uri.parse('https://api.clashking.xyz/discord_links'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode([user.id]),
    );

    if (response.statusCode == 200) {
      String responseBody = utf8.decode(response.bodyBytes);
      Map<String, dynamic> responseBodyJson = jsonDecode(responseBody);
      responseBodyJson.removeWhere(
          (key, value) => value == null); // Remove entries with null value
      if (responseBodyJson.keys.isNotEmpty) {
        user.tags = responseBodyJson.keys.toList(); // Update 'tags' in 'user'
      }

      return user;
    } else {
      Sentry.captureMessage(
          'Failed to load user tags for user ${user.id}: ${response.statusCode}, ${response.body}');
      // Instead of throwing, return user with empty tags to allow login to continue
      return user;
    }
  } catch (e) {
    Sentry.captureException(e);
    // Return user with empty tags on network error to allow login to continue
    return user;
  }
}

Future<User> fetchGuestUserTags(User user) async {
  final prefs = await SharedPreferences.getInstance();
  List<String> tags = prefs.getStringList("tags") ?? [];
  user.tags = tags;
  return user;
}
