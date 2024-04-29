import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:clashkingapp/data/league_data.dart';

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
  final Location location;
  final List<dynamic> memberList;
  final List<dynamic> labels;
  final int requiredBuilderBaseTrophies;
  final int requiredTownhallLevel;
  final Map<String, dynamic> clanCapital;

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
    required this.location,
    required this.memberList,
    required this.labels,
    required this.requiredBuilderBaseTrophies,
    required this.requiredTownhallLevel,
    required this.clanCapital,
  });

  factory ClanInfo.fromJson(Map<String, dynamic> json) {
    return ClanInfo(
      tag: json['tag'] ?? 'No tag',
      name: json['name'] ?? 'No name',
      type: json['type'] ?? 'No type',
      description: json['description'] ?? 'No description',
      isFamilyFriendly: json['isFamilyFriendly'] ?? false,
      badgeUrls: BadgeUrls.fromJson(json['badgeUrls']),
      clanLevel: json['clanLevel'] ?? 0,
      clanPoints: json['clanPoints'] ?? 0,
      clanBuilderBasePoints: json['clanBuilderBasePoints'] ?? 0,
      clanCapitalPoints: json['clanCapitalPoints'] ?? 0,
      capitalLeague: CapitalLeague.fromJson(json['capitalLeague'] ?? {}),
      requiredTrophies: json['requiredTrophies'] ?? 0,
      warFrequency: json['warFrequency'] ?? 'No frequency',
      warWinStreak: json['warWinStreak'] ?? 0,
      warWins: json['warWins'] ?? 0,
      warTies: json['warTies'] ?? 0,
      warLosses: json['warLosses'] ?? 0,
      isWarLogPublic: json['isWarLogPublic'] ?? false,
      warLeague: WarLeague.fromJson(json['warLeague'] ?? {}),
      members: json['members'] ?? 0,
      location: Location.fromJson(json['location'] ?? {}),
      memberList: json['memberList'] ?? [],
      labels: json['labels'] ?? [],
      requiredBuilderBaseTrophies: json['requiredBuilderBaseTrophies'] ?? 0,
      requiredTownhallLevel: json['requiredTownhallLevel'] ?? 0,
      clanCapital: json['clanCapital'] ?? {},
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
  late String imageUrl;

  WarLeague({required this.id, required this.name});

  factory WarLeague.fromJson(Map<String, dynamic> json) {
    WarLeague warLeague = WarLeague(
      id: json['id'],
      name: json['name'],
    );
    return warLeague;
  }
     
}

class Location {
  final String localizedName;
  final int id;
  final String name;
  final bool isCountry;
  final String countryCode;

  Location(
      {required this.localizedName,
      required this.id,
      required this.name,
      required this.isCountry,
      required this.countryCode});

  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      localizedName: json['localizedName'] ?? 'No localizedName',
      id: json['id'] ?? 0,
      name: json['name'] ?? 'No name',
      isCountry: json['isCountry'] ?? false,
      countryCode: json['countryCode'] ?? 'No countryCode',
    );
  }
}

// Service class to fetch clan info
class ClanService {
  Future<void> initEnv() async {
    await dotenv.load(fileName: ".env");
  }

  Future<ClanInfo> fetchClanInfo(String tag) async {
    tag = tag.replaceAll('#', '!');

    final response = await http.get(
      Uri.parse('https://api.clashking.xyz/v1/clans/$tag'),
    );

    if (response.statusCode == 200) {
      String responseBody = utf8.decode(response.bodyBytes);
      ClanInfo clanInfo = ClanInfo.fromJson(jsonDecode(responseBody));
      clanInfo.warLeague.imageUrl = await fetchLeagueImageUrl(clanInfo.warLeague.name);

      return clanInfo;
    } else {
      throw Exception('Failed to load clan stats');
    }
  }

  Future<String> fetchLeagueImageUrl(String name) async {
    if (leaguesUrls.containsKey(name)) {
      // If the league name is in the map, return the corresponding URL and type
      return leaguesUrls[name]!['url']!;
    } else {
      // If the league name is not in the map, return default image URL and type
      return 'https://clashkingfiles.b-cdn.net/clashkinglogo.png';
    }
  }
}
