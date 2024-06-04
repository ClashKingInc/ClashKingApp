import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:clashkingapp/api/current_war_info.dart';

class CurrentLeagueInfo {
  final String state;
  final String season;
  final List<ClanLeagueDetails> clans;
  final List<ClanLeagueRounds> rounds;

  CurrentLeagueInfo({
    required this.state,
    required this.season,
    required this.clans,
    required this.rounds,
  });

  factory CurrentLeagueInfo.fromJson(Map<String, dynamic> json, String clanTag) {
    return CurrentLeagueInfo(
      state: json['state'] ?? 'No state',
      season: json['season'] ?? 'No season',
      clans: List<ClanLeagueDetails>.from(
          json['clans']?.map((x) => ClanLeagueDetails.fromJson(x)) ?? []),
      rounds: List<ClanLeagueRounds>.from(
          json['rounds']?.map((x) => ClanLeagueRounds.fromJson(x, clanTag)) ?? []),
    );
  }
}

class ClanLeagueDetails {
  final String tag;
  final String name;
  final BadgeUrls badgeUrls;
  final int clanLevel;
  final List<LeagueMember> members;

  ClanLeagueDetails({
    required this.tag,
    required this.name,
    required this.badgeUrls,
    required this.clanLevel,
    required this.members,
  });

  factory ClanLeagueDetails.fromJson(Map<String, dynamic> json) {
    return ClanLeagueDetails(
      tag: json['tag'] ?? 'No tag',
      name: json['name'] ?? 'No name',
      badgeUrls: BadgeUrls.fromJson(json['badgeUrls'] ?? {}),
      clanLevel: json['clanLevel'] ?? 0,
      members: List<LeagueMember>.from(
          json['members']?.map((x) => LeagueMember.fromJson(x)) ?? []),
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

class LeagueMember {
  final String tag;
  final String name;
  final int townHallLevel;

  LeagueMember({
    required this.tag,
    required this.name,
    required this.townHallLevel,
  });

  factory LeagueMember.fromJson(Map<String, dynamic> json) {
    return LeagueMember(
      tag: json['tag'] ?? 'No tag',
      name: json['name'] ?? 'No name',
      townHallLevel: json['townHallLevel'] ?? 0,
    );
  }
}

class ClanLeagueRounds {
  final List<String> warTags;
  final Future<List<CurrentWarInfo>> warLeagueInfos;

  ClanLeagueRounds({
    required this.warTags,
    required this.warLeagueInfos,
  });

  factory ClanLeagueRounds.fromJson(Map<String, dynamic> json, String clanTag) {
    var warTags = json['warTags'] as List<dynamic>? ?? [];
    List<String> parsedWarTags = warTags.map((tag) => tag.toString()).toList();
    Future<List<CurrentWarInfo>> warLeagueInfos = 
        fetchWarLeagueInfos(parsedWarTags, clanTag);
    return ClanLeagueRounds(
      warTags: parsedWarTags,
      warLeagueInfos: warLeagueInfos,
    );
  }

  static Future<List<CurrentWarInfo>> fetchWarLeagueInfos(List<String> warTags, String clanTag) async {
    List<Future<CurrentWarInfo?>> futures = [];

    for (var warTag in warTags) {
      if (warTag != "#0") {
        warTag = warTag.replaceAll('#', '%23');
        Future<CurrentWarInfo?> warLeagueInfo = fetchWarLeagueInfo(warTag, clanTag);
        futures.add(warLeagueInfo);
      }
    }

    // Filter out null values and convert to Future<CurrentWarInfo>
    var results = await Future.wait(futures);
    return results.where((result) => result != null).cast<CurrentWarInfo>().toList();
  }

  static Future<CurrentWarInfo?> fetchWarLeagueInfo(String warTag, String clanTag) async {
    final response = await http.get(
      Uri.parse('https://api.clashking.xyz/v1/clanwarleagues/wars/$warTag'),
    );

    if (response.statusCode == 200) {
      Map<String, dynamic> json = jsonDecode(utf8.decode(response.bodyBytes));
      if (json['state'] != "notInWar") {
        return CurrentWarInfo.fromJson(json, "cwl", clanTag);
      }
    } else if (response.statusCode == 429) {
      throw Exception('Too many requests at the same time. Please retry in a few minutes.');
    } else {
      throw Exception('Failed to load war league info with status code: ${response.statusCode}');
    }

    return null;
  }
}


// Service
class CurrentLeagueService {
  Future<CurrentLeagueInfo> fetchCurrentLeagueInfo(String tag) async {
    tag = tag.replaceAll('#', '%23'); // URL encode the '#' character
    final response = await http.get(
      Uri.parse(
          'https://api.clashking.xyz/v1/clans/$tag/currentwar/leaguegroup'),
    );

    if (response.statusCode == 200) {
      return CurrentLeagueInfo.fromJson(
          jsonDecode(utf8.decode(response.bodyBytes)), tag);
    } else {
      throw Exception(
          'Failed to load current league info with status code: ${response.statusCode}');
    }
  }
}
