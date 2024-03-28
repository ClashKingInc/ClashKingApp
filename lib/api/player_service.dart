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
    String townHallPic = '';

    switch (townHallLevel) {
      case 1:
        townHallPic = 'https://clashkingfiles.b-cdn.net/town-hall-pics/town-hall-1.png';
        break;
      case 2:
        townHallPic = 'https://clashkingfiles.b-cdn.net/town-hall-pics/town-hall-2.png';
        break;
      case 3:
        townHallPic = 'https://clashkingfiles.b-cdn.net/town-hall-pics/town-hall-3.png';
        break;
      case 4:
        townHallPic = 'https://clashkingfiles.b-cdn.net/town-hall-pics/town-hall-4.png';
        break;
      case 5:
        townHallPic = 'https://clashkingfiles.b-cdn.net/town-hall-pics/town-hall-5.png';
        break;
      case 6:
        townHallPic = 'https://clashkingfiles.b-cdn.net/town-hall-pics/town-hall-6.png';
        break;
      case 7:
        townHallPic = 'https://clashkingfiles.b-cdn.net/town-hall-pics/town-hall-7.png';
        break;
      case 8:
        townHallPic = 'https://clashkingfiles.b-cdn.net/town-hall-pics/town-hall-8.png';
        break;
      case 9:
        townHallPic = 'https://clashkingfiles.b-cdn.net/town-hall-pics/town-hall-9.png';
        break;
      case 10:
        townHallPic = 'https://clashkingfiles.b-cdn.net/town-hall-pics/town-hall-10.png';
        break;
      case 11:
        townHallPic = 'https://clashkingfiles.b-cdn.net/town-hall-pics/town-hall-11.png';
        break;
      case 12:
        townHallPic = 'https://clashkingfiles.b-cdn.net/town-hall-pics/town-hall-12.png';
        break;
      case 13:
        townHallPic = 'https://clashkingfiles.b-cdn.net/town-hall-pics/town-hall-13.png';
        break;
      case 14:
        townHallPic = 'https://clashkingfiles.b-cdn.net/town-hall-pics/town-hall-14.png';
        break;
      case 15:
        townHallPic = 'https://clashkingfiles.b-cdn.net/town-hall-pics/town-hall-15.png';
        break;
      case 16:
        townHallPic = 'https://clashkingfiles.b-cdn.net/town-hall-pics/town-hall-16.png';
        break;
      default:
        townHallPic = 'https://clashkingfiles.b-cdn.net/town-hall-pics/town-hall-16.png';
    }

    return townHallPic;
  }
}
