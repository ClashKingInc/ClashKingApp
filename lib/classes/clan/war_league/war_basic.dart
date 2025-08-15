import 'dart:convert';
import 'package:http/http.dart' as http;

class WarBasicData {
  final String warID;
  final List<Clan> clans;
  final int endTime;

  WarBasicData({required this.warID, required this.clans, required this.endTime
  });

  factory WarBasicData.fromJson(Map<String, dynamic> json) {
    return WarBasicData(
        warID: json['war_id'] ?? '',
        clans: json['clans'] ?? [],
        endTime: json['end_time'] ?? 0
    );
  }
}

  class Clan {
    final String clanTag;
    final String opponentTag;

    Clan({required this.clanTag, required this.opponentTag});

    factory Clan.fromJson(Map<String, dynamic> json) {
      return Clan(
          clanTag: json['clan_tag'] ?? '',
          opponentTag: json['opponent_tag'] ?? ''
      );
    }
  }

class WarBasicService {
  static Future<List<dynamic>> fetchWarBasicData(String tag) async {
    final response = await http.get(Uri.parse(
        'https://api.clashking.xyz/war/${tag.substring(1)}/basic'));
    if (response.statusCode == 200) {
      String body = utf8.decode(response.bodyBytes);
      return json.decode(body);
    } else {
      throw Exception('Failed to load war history data');
    }
  }
}