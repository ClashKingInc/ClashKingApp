import 'dart:convert' show jsonDecode;
import 'package:http/http.dart' as http;

class DiscordUser {
  final String id;
  final String username;
  final String avatar;
  final String email;
  final String globalName;
  final String language;

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
      return DiscordUser.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to fetch user');
    }
  }