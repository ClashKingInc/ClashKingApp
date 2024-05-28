import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class CurrentWarInfo {
  final String state;
  final int teamSize;
  final int attacksPerMember;
  final DateTime preparationStartTime;
  final DateTime startTime;
  final DateTime endTime;
  final ClanWarDetails clan;
  final ClanWarDetails opponent;
  final String type;

  CurrentWarInfo({
    required this.state,
    required this.teamSize,
    required this.attacksPerMember,
    required this.preparationStartTime,
    required this.startTime,
    required this.endTime,
    required this.clan ,
    required this.opponent,
    required this.type,
  });

  factory CurrentWarInfo.fromJson(Map<String, dynamic> json, String type) {
    if (json['state'] == "notInwar" && json["teamSize"] == 0) {
      return CurrentWarInfo(
        state: json['state'] ?? 'No state',
        teamSize: 0,
        attacksPerMember: 0,
        preparationStartTime: DateTime.now(),
        startTime: DateTime.now(),
        endTime: DateTime.now(),
        clan: ClanWarDetails.fromJson({}),
        opponent: ClanWarDetails.fromJson({}),
        type: type,
      );
    } else {
      return CurrentWarInfo(
        state: json['state'] ?? 'No state',
        teamSize: json['teamSize'] ?? 0,
        attacksPerMember: json['attacksPerMember'] ?? 1,
        preparationStartTime: DateTime.parse(json['preparationStartTime']),
        startTime: DateTime.parse(json['startTime']),
        endTime: DateTime.parse(json['endTime']),
        clan: ClanWarDetails.fromJson(json['clan'] ?? {}),
        opponent: ClanWarDetails.fromJson(json['opponent'] ?? {}),
        type: type,
      );
    }
  }
}

class ClanWarDetails {
  final String tag;
  final String name;
  final BadgeUrls badgeUrls;
  final int clanLevel;
  final int attacks;
  final int stars;
  final double destructionPercentage;
  final List<WarMember> members;

  ClanWarDetails({
    required this.tag,
    required this.name,
    required this.badgeUrls,
    required this.clanLevel,
    required this.attacks,
    required this.stars,
    required this.destructionPercentage,
    required this.members,
  });

  factory ClanWarDetails.fromJson(Map<String, dynamic> json) {
    return ClanWarDetails(
      tag: json['tag'] ?? 'No tag',
      name: json['name'] ?? 'No name',
      badgeUrls: BadgeUrls.fromJson(json['badgeUrls'] ?? {}),
      clanLevel: json['clanLevel'] ?? 0,
      attacks: json['attacks'] ?? 0,
      stars: json['stars'] ?? 0,
      destructionPercentage: (json['destructionPercentage'] ?? 0.0).toDouble(),
      members: List<WarMember>.from(
          json['members']?.map((x) => WarMember.fromJson(x)) ?? []),
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
      small: json['small'],
      large: json['large'],
      medium: json['medium'],
    );
  }
}

class WarMember {
  final String tag;
  final String name;
  final int townhallLevel;
  final int mapPosition;
  final List<Attack>? attacks;
  final int opponentAttacks;
  final BestOpponentAttack? bestOpponentAttack;

  WarMember({
    required this.tag,
    required this.name,
    required this.townhallLevel,
    required this.mapPosition,
    this.attacks,
    required this.opponentAttacks,
    this.bestOpponentAttack,
  });

  factory WarMember.fromJson(Map<String, dynamic> json) {
    return WarMember(
      tag: json['tag'] ?? 'No tag',
      name: json['name'] ?? 'No name',
      townhallLevel: json['townhallLevel'] ?? 0,
      mapPosition: json['mapPosition'] ?? 0,
      attacks:
          (json['attacks'] as List?)?.map((x) => Attack.fromJson(x)).toList() ??
              [],
      opponentAttacks: json['opponentAttacks'] ?? 0,
      bestOpponentAttack: json['bestOpponentAttack'] != null
          ? BestOpponentAttack.fromJson(json['bestOpponentAttack'])
          : null,
    );
  }
}

class Attack {
  final String attackerTag;
  final String defenderTag;
  final int stars;
  final int destructionPercentage;
  final int order;
  final int duration;

  Attack({
    required this.attackerTag,
    required this.defenderTag,
    required this.stars,
    required this.destructionPercentage,
    required this.order,
    required this.duration,
  });

  factory Attack.fromJson(Map<String, dynamic> json) {
    return Attack(
      attackerTag: json['attackerTag'] ?? 'No attackerTag',
      defenderTag: json['defenderTag'] ?? 'No defenderTag',
      stars: json['stars'] ?? 0,
      destructionPercentage: (json['destructionPercentage'] ?? 0.0),
      order: json['order'] ?? 0,
      duration: json['duration'] ?? 0,
    );
  }
}

class BestOpponentAttack {
  final String attackerTag;
  final String defenderTag;
  final int stars;
  final int destructionPercentage;
  final int order;
  final int duration;

  BestOpponentAttack({
    required this.attackerTag,
    required this.defenderTag,
    required this.stars,
    required this.destructionPercentage,
    required this.order,
    required this.duration,
  });

  factory BestOpponentAttack.fromJson(Map<String, dynamic> json) {
    return BestOpponentAttack(
      attackerTag: json['attackerTag'] ?? 'No attackerTag',
      defenderTag: json['defenderTag'] ?? 'No defenderTag',
      stars: json['stars'] ?? 0,
      destructionPercentage: (json['destructionPercentage'] ?? 0.0),
      order: json['order'] ?? 0,
      duration: json['duration'] ?? 0,
    );
  }
}

// Service
class CurrentWarService {
  Future<void> initEnv() async {
    await dotenv.load(fileName: ".env");
  }

  Future<CurrentWarInfo> fetchCurrentWarInfo(String tag, String type) async {
    tag = tag.replaceAll('#', '%23');

    late http.Response response;

    if (type == "war") {
      response = await http.get(
        Uri.parse('https://api.clashking.xyz/v1/clans/$tag/currentwar'),
      );
    } else {
      response = await http.get(
        Uri.parse('https://api.clashking.xyz/v1/clanwarleagues/wars/$tag'),
      );
    }

    print(response.body);

    if (response.statusCode == 200) {
      return CurrentWarInfo.fromJson(jsonDecode(response.body), type);
    } else {
      throw Exception('Failed to load current war info with status code: ${response.statusCode}');
    }
  }

  static Future<CurrentWarInfo?> fetchWarDataFromTime(String tag, DateTime end) async {
    String endTime = end.toIso8601String();
    endTime = endTime.replaceAll('-', '').replaceAll(':', '');
    
    final response = await http.get(Uri.parse('https://api.clashking.xyz/war/${tag.substring(1)}/previous/$endTime'));
    print('test');
    if (response.statusCode == 200) {
      String body = utf8.decode(response.bodyBytes);
      Map<String, dynamic> jsonBody = json.decode(body);
      return CurrentWarInfo.fromJson(jsonBody, 'current');
    } else {
      return null;
    }
  }
}