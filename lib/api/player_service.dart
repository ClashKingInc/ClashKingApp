// player_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'player_info.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class PlayerService {

    Future<void> initEnv() async {
    await dotenv.load(fileName: ".env");
  }

  Future<PlayerStats> fetchPlayerStats() async {
    final response = await http.get(
      Uri.parse('https://api.clashking.xyz/v1/players/!8GLYGGJQ'),
    );

    print('Response status: ${response.statusCode}'); // Print response status
    print('Response body: ${response.body}'); // Print response body

    if (response.statusCode == 200) {
      String responseBody = utf8.decode(response.bodyBytes);
      return PlayerStats.fromJson(jsonDecode(responseBody));
    } else {
      throw Exception('Failed to load player stats');
    }
  }
}
