import 'dart:convert' as convert;
import 'package:clashkingapp/classes/data/game_data_manager.dart';
import 'package:http/http.dart' as http;

class PlayerNameInfo {
  final String tag;
  final String clan;
  final String clanName;
  final String league;
  final String name;
  final int th;
  final int trophies;

  PlayerNameInfo({
    required this.tag,
    required this.clan,
    required this.clanName,
    required this.league,
    required this.name,
    required this.th,
    required this.trophies,
  });
  
  factory PlayerNameInfo.fromJson(Map<String, dynamic> json) {
    return PlayerNameInfo(
      tag: json['tag'] ?? '',
      clan: json['clan'] ?? 'No clan',
      clanName: json['clan_name'] ?? 'No clan',
      league: json['league'] ?? 'Unranked',
      name: json['name'] ?? 'ILoveClashKing',
      th: json['th'] ?? GameDataManager().getMaxTownHallLevel(),
      trophies: json['trophies'] ?? 1,
    );
  }

  static Future<List<PlayerNameInfo>> fetchPlayerNameInfo(String name) async {
    final response = await http.get(Uri.parse('https://api.clashking.xyz/player/search/$name'));
    if (response.statusCode == 200) {
      List<PlayerNameInfo> players = [];
      Map<String, dynamic> data = convert.jsonDecode(convert.utf8.decode(response.bodyBytes));
      for (var item in data['items']) {
        players.add(PlayerNameInfo.fromJson(item));
      }
      return players;
    } else {
      throw Exception('Failed to load player name info');
    }
  }
}