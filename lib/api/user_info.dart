import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class User {
  final String id;
  final String avatar;
  String globalName;
  bool isDiscordUser = false;
  List<String> tags = [];
  List<Map<String, dynamic>> selectedTagDetails = [];

  User({
    required this.id,
    required this.avatar,
    required this.globalName,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      avatar:
          'https://cdn.discordapp.com/avatars/${json['id']}/${json['avatar']}.png',
      globalName: json['global_name'],
    );
  }

  @override
  String toString() {
    return 'DiscordUser{id: $id, avatar: https://cdn.discordapp.com/avatars/$id/$avatar.png, globalName: $globalName, isDiscordUser : $isDiscordUser, tags: $tags, selectedTagDetails: $selectedTagDetails}';
  }
}

Future<User?> fetchDiscordUser(String accessToken) async {
  if (accessToken != "inviteMode") {
    final response = await http.get(
      Uri.https('discord.com', '/api/users/@me'),
      headers: {
        'Authorization': 'Bearer $accessToken',
      },
    );

    print(response.body);

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
      avatar: 'https://clashkingfiles.b-cdn.net/logos/ClashKing-crown-logo.png',
      globalName: 'ILoveClashKing',
    );
    user.isDiscordUser = false;
    return user;
  }
}

Future<User> fetchDiscordUserTags(User user) async {
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
      final prefs = await SharedPreferences.getInstance();
      prefs.setString('selectedTag', user.tags.first);
    }

    return user;
  } else {
    throw Exception('Failed to load user tags');
  }
}

Future<User> fetchGuestUserTags(User user) async {
  final prefs = await SharedPreferences.getInstance();
  List<String> tags = prefs.getStringList("tags") ?? [];
  user.tags = tags;
  return user;
}
