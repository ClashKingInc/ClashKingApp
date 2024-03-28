// player_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'player_info.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:clashkingapp/api/clan_info.dart';
import 'package:clashkingapp/api/current_war_info.dart';


class PlayerService {

    Future<void> initEnv() async {
    await dotenv.load(fileName: ".env");
  }
  
  Future<PlayerAccounts> fetchPlayerAccounts(List<String> tags) async {
    PlayerAccounts playerAccounts = PlayerAccounts(items: [], clanInfo: [], warInfo: []);
    PlayerStats playerStats;
    ClanInfo clanInfo;
    CurrentWarInfo warInfo;
    
    for (int i = 0; i < tags.length; i++) {
      print('Fetching player stats for tag: ${tags[i]}');
      playerStats = await fetchPlayerStats(tags[i]);
      playerAccounts.items.add(playerStats);
      print("clan: ${playerStats.clan.tag}");
      clanInfo = await fetchClanInfo(playerStats.clan.tag);
      playerAccounts.clanInfo.add(clanInfo);
      warInfo = await fetchCurrentWarInfo(playerStats.clan.tag);
      playerAccounts.warInfo.add(warInfo);
    }
    return playerAccounts;
  }

  Future<PlayerStats> fetchPlayerStats(String tag) async {
    print('Fetching player stats');
    tag = tag.replaceAll('#', '!');

    final response = await http.get(
      Uri.parse('https://api.clashking.xyz/v1/players/$tag'),
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

  Future<ClanInfo> fetchClanInfo(String clanTag) async {
    print('Fetching clan info');
    clanTag = clanTag.replaceAll('#', '!');
    final response = await http.get(
      Uri.parse('https://api.clashking.xyz/v1/clans/$clanTag'),
    );

    print('Response status: ${response.statusCode}'); // Print response status
    print('Response body: ${response.body}'); // Print response body

    if (response.statusCode == 200) {
      String responseBody = utf8.decode(response.bodyBytes);
      ClanInfo clanInfo = ClanInfo.fromJson(jsonDecode(responseBody));
      return clanInfo;
    } else {
      throw Exception('Failed to load clan info');
    }
  }

  Future<CurrentWarInfo> fetchCurrentWarInfo(String clanTag) async {
    print('Fetching current war info');    
    clanTag = clanTag.replaceAll('#', '!');
    final response = await http.get(
      Uri.parse('https://api.clashking.xyz/v1/clans/$clanTag/currentwar'),
    );

    print('Response status: ${response.statusCode}'); // Print response status
    print('Response body: ${response.body}'); // Print response body

    if (response.statusCode == 200) {
      String responseBody = utf8.decode(response.bodyBytes);
      CurrentWarInfo warInfo = CurrentWarInfo.fromJson(jsonDecode(responseBody));
      return warInfo;
    } else {
      throw Exception('Failed to load current war info');
    }
  }
  
}
