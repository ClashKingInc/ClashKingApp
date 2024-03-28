// player_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'player_info.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PlayerService {

    Future<void> initEnv() async {
    await dotenv.load(fileName: ".env");
  }

  Future<PlayerStats> fetchPlayerStats() async {
    print('Fetching player stats');
    final prefs = await SharedPreferences.getInstance();
    String? selectedTag = prefs.getString('selectedTag');
    print('Selected tag: $selectedTag');
    if (selectedTag != null) {
      selectedTag = selectedTag.replaceAll('#', '!');
    }

    final response = await http.get(
      Uri.parse('https://api.clashking.xyz/v1/players/$selectedTag'),
    );

    print('Response status: ${response.statusCode}'); // Print response status
    print('Response body: ${response.body}'); // Print response body

    if (response.statusCode == 200) {
      String responseBody = utf8.decode(response.bodyBytes);
      PlayerStats playerStats = PlayerStats.fromJson(jsonDecode(responseBody));
      playerStats.townHallPic = await fetchPlayerTownHallByTownHallLevel(playerStats.townHallLevel);
      return playerStats;
    } else {
      throw Exception('Failed to load player stats');
    }
  }

  Future<String> fetchPlayerTownHallByTownHallLevel(int townHallLevel) async {
    String townHallPic;
    if (townHallLevel >= 1 && townHallLevel <= 16) {
      townHallPic = 'https://clashkingfiles.b-cdn.net/home-base/town-hall-pics/town-hall-$townHallLevel.png';
    } else {
      townHallPic = 'https://clashkingfiles.b-cdn.net/home-base/town-hall-pics/town-hall-16.png';
    }
    return townHallPic;
  }
}
