import 'dart:convert';
import 'package:http/http.dart' as http;

class WarLeagueInfo {
  final String state;
  final int teamSize;
  final DateTime preparationStartTime;
  final DateTime startTime;
  final DateTime endTime;
  final ClanWarDetails clan;
  final ClanWarDetails opponent;

  WarLeagueInfo({
    required this.state,
    required this.teamSize,
    required this.preparationStartTime,
    required this.startTime,
    required this.endTime,
    required this.clan,
    required this.opponent,
  });

  factory WarLeagueInfo.fromJson(Map<String, dynamic> json) {
    return WarLeagueInfo(
      state: json['state'] ?? 'No state',
      teamSize: json['teamSize'] ?? 0,
      preparationStartTime: DateTime.parse(json['preparationStartTime']),
      startTime: DateTime.parse(json['startTime']),
      endTime: DateTime.parse(json['endTime']),
      clan: ClanWarDetails.fromJson(json['clan'] ?? {}),
      opponent: ClanWarDetails.fromJson(json['opponent'] ?? {}),
    );
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
  final List<WarLeagueMember> members;

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
      members: List<WarLeagueMember>.from(
          json['members']?.map((x) => WarLeagueMember.fromJson(x)) ?? []),
    );
  }

  WarLeagueMember getMemberByTag(String tag) {
    return members.firstWhere((element) => element.tag == tag);
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

class WarLeagueMember {
  final String tag;
  final String name;
  final int townhallLevel;
  final int mapPosition;
  final List<Attack>? attacks;
  final int opponentAttacks;
  final BestOpponentAttack? bestOpponentAttack;

  WarLeagueMember({
    required this.tag,
    required this.name,
    required this.townhallLevel,
    required this.mapPosition,
    this.attacks,
    required this.opponentAttacks,
    this.bestOpponentAttack,
  });

  factory WarLeagueMember.fromJson(Map<String, dynamic> json) {
    return WarLeagueMember(
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
class WarLeagueService {
  Future<WarLeagueInfo> fetchWarLeagueInfo(String warTag) async {
    warTag = warTag.replaceAll('#', '%23');
    final response = await http.get(
      Uri.parse('https://proxy.clashk.ing/v1/clanwarleagues/wars/$warTag'),
    );

    if (response.statusCode == 200) {
      String decodedBody = utf8.decode(response.bodyBytes);
      var json = jsonDecode(decodedBody);
      return WarLeagueInfo.fromJson(json);
    } else {
      throw Exception(
          'Failed to load current war info with status code: ${response.statusCode}');
    }
  }
}
