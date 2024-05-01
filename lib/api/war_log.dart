import 'dart:convert';
import 'package:http/http.dart' as http;

class WarLog {
  final List<WarLogDetails> items;

  WarLog({
    required this.items,
  });

  factory WarLog.fromJson(Map<String, dynamic> json) {
    var itemList = (json['items'] as List)
      .map((itemJson) => WarLogDetails.fromJson(itemJson))
      .toList();
    return WarLog(items: itemList);
  }
}

class WarLogDetails {
  final String result;
  final DateTime endTime;
  final int teamSize;
  final int attacksPerMember;
  final ClanDetails clan;
  final ClanDetails opponent;

  WarLogDetails({
    required this.result,
    required this.endTime,
    required this.teamSize,
    required this.attacksPerMember,
    required this.clan,
    required this.opponent,
  });

  factory WarLogDetails.fromJson(Map<String, dynamic> json) {
    return WarLogDetails(
      result: json['result'],
      endTime: DateTime.parse(json['endTime']),
      teamSize: json['teamSize'],
      attacksPerMember: json['attacksPerMember'],
      clan: ClanDetails.fromJson(json['clan']),
      opponent: ClanDetails.fromJson(json['opponent']),
    );
  }
}

class ClanDetails {
  final String tag;
  final String name;
  final Map<String, String> badgeUrls;
  final int clanLevel;
  final int attacks;
  final int stars;
  final double destructionPercentage;
  final int expEarned;

  ClanDetails({
    required this.tag,
    required this.name,
    required this.badgeUrls,
    required this.clanLevel,
    required this.attacks,
    required this.stars,
    required this.destructionPercentage,
    required this.expEarned,
  });

  factory ClanDetails.fromJson(Map<String, dynamic> json) {
    return ClanDetails(
      tag: json['tag'],
      name: json['name'],
      badgeUrls: Map<String, String>.from(json['badgeUrls']),
      clanLevel: json['clanLevel'],
      attacks: json['attacks'],
      stars: json['stars'],
      destructionPercentage: json['destructionPercentage'].toDouble(),
      expEarned: json['expEarned'],
    );
  }
}

class WarLogService {
  static Future<List<dynamic>> fetchWarLogData(String tag) async {
    final response = await http.get(Uri.parse(
        'https://api.clashking.xyz/v1/clans/${tag.substring(1)}/warlog'));
    if (response.statusCode == 200) {
      String body = utf8.decode(response.bodyBytes);
      return json.decode(body);
    } else {
      throw Exception('Failed to load war history data');
    }
  }
}