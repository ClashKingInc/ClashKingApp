import 'dart:convert';
import 'package:http/http.dart' as http;

class WarLog {
  final List<WarLogDetails> items;

  WarLog({
    required this.items,
  });

  factory WarLog.fromJson(Map<String, dynamic> json) {
    var itemList = json['items'] != null
        ? (json['items'] as List)
            .map((itemJson) =>
                WarLogDetails.fromJson(itemJson as Map<String, dynamic>))
            .toList()
        : [];
    return WarLog(items: itemList.cast<WarLogDetails>());
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
      result: json['result'] ?? '',
      endTime: DateTime.parse(json['endTime']),
      teamSize: json['teamSize'] ?? 0,
      attacksPerMember: json['attacksPerMember'] ?? 1,
      clan: ClanDetails.fromJson(json['clan']),
      opponent: ClanDetails.fromJson(json['opponent']),
    );
  }
}

class ClanDetails {
  final String tag;
  final String name;
  final BadgeUrls badgeUrls;
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
      tag: json['tag'] ?? '',
      name: json['name'] ?? '',
      badgeUrls: BadgeUrls.fromJson(json['badgeUrls'] ?? {}),
      clanLevel: json['clanLevel'] ?? 0,
      attacks: json['attacks'] ?? 0,
      stars: json['stars'] ?? 0,
      destructionPercentage:
          (json['destructionPercentage'] as num?)?.toDouble() ?? 0.0,
      expEarned: json['expEarned'] ?? 0,
    );
  }
}

class BadgeUrls {
  final String small;
  final String large;
  final String medium;

  BadgeUrls({
    required this.small,
    required this.large,
    required this.medium,
  });

  factory BadgeUrls.fromJson(Map<String, dynamic> json) {
    return BadgeUrls(
      small: json['small'] ?? '',
      large: json['large'] ?? '',
      medium: json['medium'] ?? '',
    );
  }
}

class WarLogService {
  static Future<WarLog> fetchWarLogData(String tag) async {
    final response = await http.get(Uri.parse(
        'https://api.clashking.xyz/v1/clans/${tag.replaceAll('#', '%23')}/warlog'));
    print("warlog : ${response.body}");
    print(response.statusCode);
    if (response.statusCode == 200) {
      String body = utf8.decode(response.bodyBytes);
      Map<String, dynamic> jsonBody = json.decode(body);
      return WarLog.fromJson(jsonBody);
    } else if (response.statusCode == 403) {
      return WarLog(items: []);
    } else {
      throw Exception('Failed to load war history data');
    }
  }
}
