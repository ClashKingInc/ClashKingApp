import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:clashkingapp/classes/clan/description/badge_urls.dart';

class WarInfoContainer {
  CurrentWarInfo? currentWarInfo;

  WarInfoContainer({this.currentWarInfo});
}

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
    required this.clan,
    required this.opponent,
    required this.type,
  });

  factory CurrentWarInfo.fromJson(
      Map<String, dynamic> json, String type, String clanTag, bool bypass) {
    return CurrentWarInfo(
      state: json['state'] ?? 'No state',
      teamSize: json['teamSize'] ?? 0,
      attacksPerMember: json['attacksPerMember'] ?? 1,
      preparationStartTime: DateTime.parse(json['preparationStartTime']),
      startTime: DateTime.parse(json['startTime']),
      endTime: DateTime.parse(json['endTime']),
      clan: (bypass == false)
          ? ClanWarDetails.fromJson(json['clan']['tag'] == clanTag
              ? json['clan']
              : json['opponent'] ?? {})
          : ClanWarDetails.fromJson(json['clan']['tag'] == clanTag
              ? json['opponent']
              : json['clan'] ?? {}),
      opponent: (bypass == false)
          ? ClanWarDetails.fromJson(json['clan']['tag'] == clanTag
              ? json['opponent']
              : json['clan'] ?? {})
          : ClanWarDetails.fromJson(json['clan']['tag'] == clanTag
              ? json['clan']
              : json['opponent'] ?? {}),
      type: type,
    );
  }

  WarMember? fetchClanMemberByTag(String tag) {
    WarMember? member = clan.members.firstWhere(
      (element) => element.tag == tag,
      orElse: () => WarMember(
        tag: '',
        name: '',
        townhallLevel: 0,
        mapPosition: 0,
        attacks: [],
        opponentAttacks: 0,
        bestOpponentAttack: null,
      ),
    );
    if (member.tag == '') {
      member = opponent.members.firstWhere(
        (element) => element.tag == tag,
        orElse: () => WarMember(
          tag: '',
          name: '',
          townhallLevel: 0,
          mapPosition: 0,
          attacks: [],
          opponentAttacks: 0,
          bestOpponentAttack: null,
        ),
      );
    }
    return member.tag == 'No tag' ? null : member;
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

  WarMember fetchMemberByTag(String tag) {
    return members.firstWhere((element) => element.tag == tag);
  }
}

class WarMember {
  final String tag;
  final String name;
  final int townhallLevel;
  final int mapPosition;
  final List<WarAttack>? attacks;
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
      attacks: (json['attacks'] as List?)
              ?.map((x) => WarAttack.fromJson(x))
              .toList() ??
          [],
      opponentAttacks: json['opponentAttacks'] ?? 0,
      bestOpponentAttack: json['bestOpponentAttack'] != null
          ? BestOpponentAttack.fromJson(json['bestOpponentAttack'])
          : null,
    );
  }
}

class WarAttack {
  final String attackerTag;
  final String defenderTag;
  final int stars;
  final int destructionPercentage;
  final int order;
  final int duration;

  WarAttack({
    required this.attackerTag,
    required this.defenderTag,
    required this.stars,
    required this.destructionPercentage,
    required this.order,
    required this.duration,
  });

  factory WarAttack.fromJson(Map<String, dynamic> json) {
    return WarAttack(
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
  static Future<CurrentWarInfo?> fetchWarDataFromTime(
      String tag, DateTime end) async {
    String endTime = end.toIso8601String();
    endTime = endTime.replaceAll('-', '').replaceAll(':', '');

    final response = await http.get(Uri.parse(
        'https://api.clashking.xyz/war/${tag.substring(1)}/previous/$endTime'));
    if (response.statusCode == 200) {
      String body = utf8.decode(response.bodyBytes);
      Map<String, dynamic> jsonBody = json.decode(body);
      return CurrentWarInfo.fromJson(jsonBody, 'current', tag, false);
    } else {
      return null;
    }
  }
}
