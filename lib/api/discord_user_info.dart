import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class DiscordUser {
  final String id;
  final String username;
  final String avatar;
  final String email;
  final String globalName;
  final String language;
  List<String> tags = [];
  List<Map<String, dynamic>> selectedTagDetails = [];


  DiscordUser({
    required this.id,
    required this.username,
    required this.avatar,
    required this.email,
    required this.globalName,
    required this.language,
  });

  factory DiscordUser.fromJson(Map<String, dynamic> json) {
    return DiscordUser(
      id: json['id'],
      username: json['username'],
      avatar: json['avatar'],
      email: json['email'],
      globalName: json['global_name'],
      language: json['locale'],
    );
  }  
}

Future<DiscordUser> fetchDiscordUser(String accessToken) async {
  final response = await http.get(
    Uri.https('discord.com', '/api/users/@me'),
    headers: {
      'Authorization': 'Bearer $accessToken',
    },
  );

  if (response.statusCode == 200) {
    print("Response user body: ${response.body}");
    DiscordUser user = DiscordUser.fromJson(jsonDecode(response.body));
    user = await fetchUserTags(user); // Fetch user tags
    return user;
  } else {
    throw Exception('Failed to fetch user');
  }
}

Future<DiscordUser> fetchUserTags(DiscordUser user) async {
  final response = await http.post(
    Uri.parse('https://api.clashking.xyz/discord_links'),
    headers: {"Content-Type": "application/json"},
    body: jsonEncode([user.id]),
  );

  if (response.statusCode == 200) {
    String responseBody = utf8.decode(response.bodyBytes);
    print("Response tags body: $responseBody");
    Map<String, dynamic> responseBodyJson = jsonDecode(responseBody);
    responseBodyJson.removeWhere((key, value) => value == null); // Remove entries with null value
    user.tags = responseBodyJson.keys.toList(); // Update 'tags' in 'user'

    final prefs = await SharedPreferences.getInstance();
    prefs.setString('selectedTag', user.tags.first);
    return user;
  } else {
    throw Exception('Failed to load user tags');
  }
}



  