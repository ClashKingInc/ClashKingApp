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

  factory CurrentLeagueInfo.fromJson(Map<String, dynamic> json) {
    return CurrentLeagueInfo(
      state: json['state'] ?? 'No state',
      season: json['season'] ?? 'No season',
      clans: List<ClanLeagueDetails>.from(
          json['clans']?.map((x) => ClanLeagueDetails.fromJson(x)) ?? []),
      rounds: List<ClanLeagueRounds>.from(
          json['rounds']?.map((x) => ClanLeagueRounds.fromJson(x)) ?? []),
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

  factory ClanLeagueRounds.fromJson(Map<String, dynamic> json) {
    var warTags = json['warTags'] as List<dynamic>? ?? [];
    List<String> parsedWarTags = warTags.map((tag) => tag.toString()).toList();
    Future<List<CurrentWarInfo>> warLeagueInfos = fetchWarLeagueInfos(parsedWarTags);
    return ClanLeagueRounds(
      warTags: parsedWarTags,
      warLeagueInfos: warLeagueInfos,
    );
  }

  static Future<List<CurrentWarInfo>> fetchWarLeagueInfos(List<String> warTags) async {
    List<CurrentWarInfo> warLeagueInfos = [];
    for (var warTag in warTags) {
      warTag = warTag.replaceAll('#', '%23');
      final response = await http.get(
        Uri.parse('https://api.clashking.xyz/v1/clanwarleagues/wars/$warTag'),
      );

      if (response.statusCode == 200) {
        CurrentWarInfo warLeagueInfoItem =
            CurrentWarInfo.fromJson(jsonDecode(utf8.decode(response.bodyBytes)), "cwl");
        warLeagueInfos.add(warLeagueInfoItem);
      } else {
        throw Exception(
            'Failed to load war league info with status code: ${response.statusCode}');
      }
    }
    return warLeagueInfos;
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
      return CurrentLeagueInfo.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
    } else {
      throw Exception(
          'Failed to load current league info with status code: ${response.statusCode}');
    }
  }
}


