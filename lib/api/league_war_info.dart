/*
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'clan_info.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ClanInfo {
  final String tag;
  final String name;
  final String type;
  final String description;
  final bool isFamilyFriendly;
  final BadgeUrls badgeUrls;
  final int clanLevel;
  final int clanPoints;
  final int clanBuilderBasePoints;
  final int clanCapitalPoints;
  final CapitalLeague capitalLeague;
  final int requiredTrophies;
  final String warFrequency;
  final int warWinStreak;
  final int warWins;
  final int warTies;
  final int warLosses;
  final bool isWarLogPublic;
  final WarLeague warLeague;
  final int members;
  final List<dynamic> memberList; // Assuming member list details are not provided
  final List<dynamic> labels; // Assuming label details are not provided
  final int requiredBuilderBaseTrophies;
  final int requiredTownhallLevel;
  final Map<String, dynamic> clanCapital; // Assuming detailed structure is not provided

  ClanInfo({
    required this.tag,
    required this.name,
    required this.type,
    required this.description,
    required this.isFamilyFriendly,
    required this.badgeUrls,
    required this.clanLevel,
    required this.clanPoints,
    required this.clanBuilderBasePoints,
    required this.clanCapitalPoints,
    required this.capitalLeague,
    required this.requiredTrophies,
    required this.warFrequency,
    required this.warWinStreak,
    required this.warWins,
    required this.warTies,
    required this.warLosses,
    required this.isWarLogPublic,
    required this.warLeague,
    required this.members,
    required this.memberList,
    required this.labels,
    required this.requiredBuilderBaseTrophies,
    required this.requiredTownhallLevel,
    required this.clanCapital,
  });

  factory ClanInfo.fromJson(Map<String, dynamic> json) {
    return ClanInfo(
      tag: json['tag'],
      name: json['name'],
      type: json['type'],
      description: json['description'],
      isFamilyFriendly: json['isFamilyFriendly'],
      badgeUrls: BadgeUrls.fromJson(json['badgeUrls']),
      clanLevel: json['clanLevel'],
      clanPoints: json['clanPoints'],
      clanBuilderBasePoints: json['clanBuilderBasePoints'],
      clanCapitalPoints: json['clanCapitalPoints'],
      capitalLeague: CapitalLeague.fromJson(json['capitalLeague']),
      requiredTrophies: json['requiredTrophies'],
      warFrequency: json['warFrequency'],
      warWinStreak: json['warWinStreak'],
      warWins: json['warWins'],
      warTies: json['warTies'],
      warLosses: json['warLosses'],
      isWarLogPublic: json['isWarLogPublic'],
      warLeague: WarLeague.fromJson(json['warLeague']),
      members: json['members'],
      memberList: json['memberList'],
      labels: json['labels'],
      requiredBuilderBaseTrophies: json['requiredBuilderBaseTrophies'],
      requiredTownhallLevel: json['requiredTownhallLevel'],
      clanCapital: json['clanCapital'],
    );
  }
}

class BadgeUrls {
  final String small;
  final String large;
  final String medium;

  BadgeUrls({required this.small, required this.large, required this.medium});

  factory BadgeUrls.fromJson(Map<String, dynamic> json) {
    return BadgeUrls(
      small: json['small'],
      large: json['large'],
      medium: json['medium'],
    );
  }
}

class CapitalLeague {
  final int id;
  final String name;

  CapitalLeague({required this.id, required this.name});

  factory CapitalLeague.fromJson(Map<String, dynamic> json) {
    return CapitalLeague(
      id: json['id'],
      name: json['name'],
    );
  }
}

class WarLeague {
  final int id;
  final String name;

  WarLeague({required this.id, required this.name});

  factory WarLeague.fromJson(Map<String, dynamic> json) {
    return WarLeague(
      id: json['id'],
      name: json['name'],
    );
  }
}

*/


/*
// Service
class CurrentWarService {

    Future<void> initEnv() async {
    await dotenv.load(fileName: ".env");
  }

  Future<CurrentWarLog> fetchCurrentWar() async {
    final response = await http.get(
      Uri.parse('https://api.clashking.xyz/v1/clans/!VY2J0LL/currentwar'),
    );

    print('Response status: ${response.statusCode}'); // Print response status
    print('Response body: ${response.body}'); // Print response body

    if (response.statusCode == 200) {
      return ClanInfo.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load clan stats');
    }
  }
}

class WarHistoryService {

    Future<void> initEnv() async {
    await dotenv.load(fileName: ".env");
  }

  Future<WarLog> fetchCurrentWar() async {
    final response = await http.get(
      Uri.parse('https://api.clashking.xyz/v1/clans/!VY2J0LL/currentwar'),
    );

    print('Response status: ${response.statusCode}'); // Print response status
    print('Response body: ${response.body}'); // Print response body

    if (response.statusCode == 200) {
      return ClanInfo.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load clan stats');
    }
  }
}

*/