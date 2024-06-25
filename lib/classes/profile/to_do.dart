import 'dart:convert';
import 'package:http/http.dart' as http;

class PlayerToDoData {
  final List<PlayerData> items;

  PlayerToDoData({required this.items});

  factory PlayerToDoData.fromJson(Map<String, dynamic> json) {
    var itemList = json['items'] != null
      ? (json['items'] as List).map((itemJson) => PlayerData.fromJson(itemJson as Map<String, dynamic>)).toList()
      : [];
    return PlayerToDoData(items: itemList.cast<PlayerData>());
  }

  @override
  String toString() {
    return 'PlayerToDoData: ${items.toString()}';
  }
}

class PlayerData {
  final String playerTag;
  final String currentClan;
  final LegendData? legends;
  final int seasonPass;
  final int lastActive;
  final RaidData raids;
  final CwlData cwl;
  final ClanGames clanGames;
  //war
  //clanGames

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

class LegendData {
  final List<int> defenses;
  final int numAttacks;
  final List<int> attacks;

  LegendData({
    required this.defenses,
    required this.numAttacks,
    required this.attacks,
  });

  factory LegendData.fromJson(Map<String, dynamic> json) {
    return LegendData(
      defenses: List<int>.from(json['defenses'] ?? []),
      numAttacks: json['num_attacks'] ?? 0,
      attacks: List<int>.from(json['attacks'] ?? []),
    );
  }
}

class DefenseDetail {
  final int change;
  final int time;
  final int trophies;

  DefenseDetail(
      {required this.change, required this.time, required this.trophies});

  factory DefenseDetail.fromJson(Map<String, dynamic> json) {
    return DefenseDetail(
      change: json['change'] ?? 0,
      time: json['time'] ?? 0,
      trophies: json['trophies'] ?? 0,
    );
  }
}

class AttackDetail {
  final int change;
  final int time;
  final int trophies;

  AttackDetail({
    required this.change,
    required this.time,
    required this.trophies,
  });

  factory AttackDetail.fromJson(Map<String, dynamic> json) {
    return AttackDetail(
      change: json['change'] ?? 0,
      time: json['time'] ?? 0,
      trophies: json['trophies'] ?? 0,
    );
  }
}

class RaidData {
  final int attacksDone;
  final int attackLimit;

  RaidData({required this.attacksDone, required this.attackLimit});

  factory RaidData.fromJson(Map<String, dynamic> json) {
    return RaidData(
      attacksDone: json['attacks_done'] ?? 0,
      attackLimit: json['attack_limit'] ?? 0,
    );
  }
}

class CwlData {
  final int attackLimit;
  final int attacksDone;

  CwlData({required this.attackLimit, required this.attacksDone});

  factory CwlData.fromJson(Map<String, dynamic> json) {
    return CwlData(
      attackLimit: json['attack_limit'] ?? 0,
      attacksDone: json['attacks_done'] ?? 0,
    );
  }
}

class ClanGames {
  final String clanTag;
  final int points;

  ClanGames({required this.clanTag, required this.points});

  factory ClanGames.fromJson(Map<String, dynamic> json) {
    return ClanGames(
      clanTag: json['clanTag'] ?? '',
      points: json['points'] ?? 0,
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
