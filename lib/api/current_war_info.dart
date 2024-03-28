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

  CurrentWarInfo({
    required this.state,
    required this.teamSize,
    required this.attacksPerMember,
    required this.preparationStartTime,
    required this.startTime,
    required this.endTime,
    required this.clan,
    required this.opponent,
  });

  factory CurrentWarInfo.fromJson(Map<String, dynamic> json) {
    return CurrentWarInfo(
      state: json['state'],
      teamSize: json['teamSize'],
      attacksPerMember: json['attacksPerMember'],
      preparationStartTime: DateTime.parse(json['preparationStartTime']),
      startTime: DateTime.parse(json['startTime']),
      endTime: DateTime.parse(json['endTime']),
      clan: ClanWarDetails.fromJson(json['clan']),
      opponent: ClanWarDetails.fromJson(json['opponent']),
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
      tag: json['tag'],
      name: json['name'],
      badgeUrls: BadgeUrls.fromJson(json['badgeUrls']),
      clanLevel: json['clanLevel'],
      attacks: json['attacks'],
      stars: json['stars'],
      destructionPercentage: json['destructionPercentage'],
      members: List<WarMember>.from(json['members'].map((x) => WarMember.fromJson(x))),
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
  final Attack? bestOpponentAttack;

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
      tag: json['tag'],
      name: json['name'],
      townhallLevel: json['townhallLevel'],
      mapPosition: json['mapPosition'],
      attacks: json['attacks'] != null
          ? List<Attack>.from(json['attacks'].map((x) => Attack.fromJson(x)))
          : null,
      opponentAttacks: json['opponentAttacks'],
      bestOpponentAttack: json['bestOpponentAttack'] != null
          ? Attack.fromJson(json['bestOpponentAttack'])
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
      attackerTag: json['attackerTag'],
      defenderTag: json['defenderTag'],
      stars: json['stars'],
      destructionPercentage: json['destructionPercentage'],
      order: json['order'],
      duration: json['duration'],
    );
  }
}


// Service


class CurrentWarService {

    Future<void> initEnv() async {
    await dotenv.load(fileName: ".env");
  }

  Future<CurrentWarInfo> fetchCurrentWarInfo(tag) async {
    tag = tag.replaceAll('#', '!');
    final response = await http.get(
      Uri.parse('https://api.clashking.xyz/v1/clans/$tag/currentwar'),
    );

    print('Response status: ${response.statusCode}'); // Print response status
    print('Response body: ${response.body}'); // Print response body

    if (response.statusCode == 200) {
      String responseBody = utf8.decode(response.bodyBytes);
      return CurrentWarInfo.fromJson(jsonDecode(responseBody));
    } else {
      throw Exception('Failed to load current war info');
    }
  }
}
/*
Gros chêne : VY2J0LL
Le petit chêne : 2QPCJQQ2U
Gland Esport : 2GRCROPUG 
*/