import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:clashkingapp/classes/profile/todo/cwl_data.dart';
import 'package:clashkingapp/classes/profile/todo/legends_data.dart';
import 'package:clashkingapp/classes/profile/todo/raids_data.dart';
import 'package:clashkingapp/classes/profile/todo/clan_games_data.dart';
import 'package:clashkingapp/classes/profile/todo/player_to_do.dart';



class PlayerData {
  final String playerTag;
  final String currentClan;
  final LegendData? legends;
  final int seasonPass;
  final int lastActive;
  final RaidData raids;
  final CwlData cwl;
  final ClanGames clanGames;

  PlayerData({
    required this.playerTag,
    required this.currentClan,
    this.legends,
    required this.seasonPass,
    required this.lastActive,
    required this.raids,
    required this.cwl,
    required this.clanGames,
  });

  factory PlayerData.fromJson(Map<String, dynamic> json) {
    return PlayerData(
      playerTag: json['player_tag'] ?? '',
      currentClan: json['current_clan'] ?? 'No clan',
      legends: json['legends'] != null && json['legends'].isNotEmpty ? LegendData.fromJson(json['legends']) : null,
      seasonPass: json['season_pass'] is int ? json['season_pass'] : 0,
      lastActive: json['last_active'] ?? 0,
      raids: json['raids'] != null && json['raids'].isNotEmpty ? RaidData.fromJson(json['raids']) : RaidData(attacksDone: 0, attackLimit: 0),
      cwl: json['cwl'] != null && json['cwl'].isNotEmpty ? CwlData.fromJson(json['cwl']) : CwlData(attacksDone: 0, attackLimit: 0),
      clanGames: json['clan_games'] != null && json['clan_games'].isNotEmpty ? ClanGames.fromJson(json['clan_games']) : ClanGames(clanTag: "#VY2J0LL", points: 0),
    );
  }
}


class PlayerDataService {
  static Future<PlayerToDoData> fetchPlayerToDoData(List<String> tags) async {
    final tagsParameter = tags.asMap().entries.map((entry) {
      String encodedTag = entry.value.replaceAll('#', '%23');
      return '${entry.key == 0 ? '' : '&'}player_tags=$encodedTag';
    }).join('');
    final response = await http.get(Uri.parse('https://api.clashking.xyz/player/to-do?$tagsParameter'));

    if (response.statusCode == 200) {
      String body = utf8.decode(response.bodyBytes);
      Map<String, dynamic> jsonBody = json.decode(body);
      return PlayerToDoData.fromJson(jsonBody);
    } else {
      throw Exception('Failed to load player data');
    }
  }
}
