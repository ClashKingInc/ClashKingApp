import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

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
      clans: List<ClanLeagueDetails>.from(json['clans']?.map((x) => ClanLeagueDetails.fromJson(x)) ?? []),
      rounds: List<ClanLeagueRounds>.from(json['rounds']?.map((x) => ClanLeagueRounds.fromJson(x)) ?? []),
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
      members: List<LeagueMember>.from(json['members']?.map((x) => LeagueMember.fromJson(x)) ?? []),
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
      name: json['name']  ?? 'No name',
      townHallLevel: json['townHallLevel'] ?? 0,
    );
  }
}

class ClanLeagueRounds {
  final List<List<String>> warTags;

  ClanLeagueRounds({
    required this.warTags,
  });

  factory ClanLeagueRounds.fromJson(Map<String, dynamic> json) {
    var rounds = json['rounds'] as List<dynamic>? ?? [];
    List<List<String>> parsedWarTags = rounds.map((round) {
      var warTags = round['warTags'] as List<dynamic>? ?? [];
      return warTags.map((tag) => tag.toString()).toList();
    }).toList();
    return ClanLeagueRounds(
      warTags: parsedWarTags,
    );
  }
}

// Service
class CurrentLeagueService {
  Future<void> initEnv() async {
    await dotenv.load(fileName: ".env");
  }

  Future<CurrentLeagueInfo> fetchCurrentLeagueInfo(String tag) async {
    tag = tag.replaceAll('#', '%23'); // URL encode the '#' character
    final response = await http.get(
      Uri.parse('https://api.clashking.xyz/v1/clans/$tag/currentwar/leaguegroup'),
      headers: {
        'Authorization': 'Bearer ${dotenv.env['API_KEY']}'
      },
    );

    if (response.statusCode == 200) {
      return CurrentLeagueInfo.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load current league info with status code: ${response.statusCode}');
    }
  }
}