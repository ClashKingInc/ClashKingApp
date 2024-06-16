import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:clashkingapp/api/league_data_manager.dart';

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
  final List<Member> memberList;
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
      memberList: (json['memberList'] as List<dynamic>)
          .map((e) => Member.fromJson(e))
          .toList(),
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
      name: json['name'] ?? 'Unknown country',
      isCountry: json['isCountry'] ?? false,
      countryCode: json['countryCode'] ?? 'No countryCode',
    );
  }
}

class Member {
  final String tag;
  final String name;
  final String role;
  final int townHallLevel;
  final int expLevel;
  final League league;
  final int trophies;
  final int builderBaseTrophies;
  final int clanRank;
  final int previousClanRank;
  final int donations;
  final int donationsReceived;
  final BuilderBaseLeague builderBaseLeague;

  Member({
    required this.tag,
    required this.name,
    required this.role,
    required this.townHallLevel,
    required this.expLevel,
    required this.league,
    required this.trophies,
    required this.builderBaseTrophies,
    required this.clanRank,
    required this.previousClanRank,
    required this.donations,
    required this.donationsReceived,
    required this.builderBaseLeague,
  });

  factory Member.fromJson(Map<String, dynamic> json) {
    return Member(
      tag: json['tag'] ?? 'No tag',
      name: json['name'] ?? 'No name',
      role: json['role'] ?? 'No role',
      townHallLevel: json['townHallLevel'] ?? 0,
      expLevel: json['expLevel'] ?? 0,
      league: League.fromJson(json['league']),
      trophies: json['trophies'] ?? 0,
      builderBaseTrophies: json['builderBaseTrophies'] ?? 0,
      clanRank: json['clanRank'] ?? 0,
      previousClanRank: json['previousClanRank'] ?? 0,
      donations: json['donations'] ?? 0,
      donationsReceived: json['donationsReceived'] ?? 0,
      builderBaseLeague: BuilderBaseLeague.fromJson(json['builderBaseLeague']),
    );
  }
}

class League {
  final int id;
  final String name;
  final IconUrls imageUrl;

  League({
    required this.id,
    required this.name,
    required this.imageUrl,
  });

  factory League.fromJson(Map<String, dynamic> json) {
    return League(
      id: json['id'] ?? 0,
      name: json['name'] ?? 'No name',
      imageUrl: IconUrls.fromJson(json['iconUrls']),
    );
  }
}

class IconUrls {
  final String small;
  final String tiny;
  final String medium;

  IconUrls({
    required this.small,
    required this.tiny,
    required this.medium,
  });

  factory IconUrls.fromJson(Map<String, dynamic> json) {
    return IconUrls(
      small: json['small'] ?? 'No small image URL',
      tiny: json['tiny'] ?? 'No tiny image URL',
      medium: json['medium'] ?? 'No medium image URL',
    );
  }
}

class BuilderBaseLeague {
  final int id;
  final String name;

  BuilderBaseLeague({
    required this.id,
    required this.name,
  });

  factory BuilderBaseLeague.fromJson(Map<String, dynamic> json) {
    return BuilderBaseLeague(
      id: json['id'] ?? 0,
      name: json['name'] ?? 'No name',
    );
  }
}

// Service class to fetch clan info
class ClanService {
  Map<String, String> leagueUrls = {};

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
      clanInfo.warLeague.imageUrl = LeagueDataManager().getLeagueUrl(clanInfo.warLeague.name);

      return clanInfo;
    } else {
      throw Exception('Failed to load clan stats');
    }
  }

  String fetchLeagueImageUrl(String name) {
    return leagueUrls[name] ??
        'https://clashkingfiles.b-cdn.net/clashkinglogo.png';
  }
}
