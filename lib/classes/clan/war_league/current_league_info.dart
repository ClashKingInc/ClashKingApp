import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:clashkingapp/classes/clan/war_league/current_war_info.dart';
import 'package:clashkingapp/classes/clan/description/badge_urls.dart';

class LeagueInfoContainer {
  CurrentLeagueInfo? currentLeagueInfo;
  LeagueInfoContainer({this.currentLeagueInfo});
}

class CurrentLeagueInfo {
  String state;
  String season;
  List<ClanLeagueDetails> clans;
  List<ClanLeagueRounds> rounds;
  late int currentRound;

  CurrentLeagueInfo({
    required this.state,
    required this.season,
    required this.clans,
    required this.rounds,
  }) {
    calculateTotalStarsAndPercentage();
  }

  factory CurrentLeagueInfo.fromJson(
      Map<String, dynamic> json, String clanTag) {
    return CurrentLeagueInfo(
      state: json['state'] ?? 'No state',
      season: json['season'] ?? 'No season',
      clans: List<ClanLeagueDetails>.from(
          json['clans']?.map((x) => ClanLeagueDetails.fromJson(x)) ?? []),
      rounds: List<ClanLeagueRounds>.from(
          json['rounds']?.map((x) => ClanLeagueRounds.fromJson(x, clanTag)) ??
              []),
    );
  }

  Future<CurrentWarInfo?> getActiveWar(String clanTag) async {
    CurrentWarInfo? inWar;
    CurrentWarInfo? inPreparation;
    CurrentWarInfo? lastMatchedWarInfo;

    for (var round in rounds) {
      List<CurrentWarInfo> warLeagueInfos = await round.warLeagueInfos;

      for (var warInfo in warLeagueInfos) {
        if (warInfo.clan.tag == clanTag || warInfo.opponent.tag == clanTag) {
          lastMatchedWarInfo = warInfo;

          if (warInfo.state == 'inWar') {
            return warInfo;
          } else if (warInfo.state == 'preparation') {
            inPreparation = warInfo;
          }
        }
      }
    }

    return inWar ?? inPreparation ?? lastMatchedWarInfo;
  }

  ClanLeagueDetails? getClanDetails(String clanTag) {
    return clans.firstWhere((clan) => clan.tag == clanTag);
  }

  void calculateTotalStarsAndPercentage() async {
    Map<String, Map<String, dynamic>> totalByClan = {};

    // Step 1: Calculate stars and percentage for each clan
    for (var round in rounds) {
      var wars = await round.warLeagueInfos;
      for (var war in wars) {
        if (!totalByClan.containsKey(war.clan.tag)) {
          totalByClan[war.clan.tag] = {'stars': 0, 'percentage': 0.0};
        }
        if (!totalByClan.containsKey(war.opponent.tag)) {
          totalByClan[war.opponent.tag] = {'stars': 0, 'percentage': 0.0};
        }

        bool warEnded = war.endTime.isBefore(DateTime.now());
        bool clanWon = war.clan.stars > war.opponent.stars ||
            (war.clan.stars == war.opponent.stars &&
                war.clan.destructionPercentage >
                    war.opponent.destructionPercentage);

        totalByClan[war.clan.tag]?['stars'] +=
            war.clan.stars + (warEnded && clanWon ? 10 : 0);
        totalByClan[war.opponent.tag]?['stars'] +=
            war.opponent.stars + (warEnded && !clanWon ? 10 : 0);

        totalByClan[war.clan.tag]?['percentage'] +=
            war.clan.destructionPercentage * war.teamSize;
        totalByClan[war.opponent.tag]?['percentage'] +=
            war.opponent.destructionPercentage * war.teamSize;
      }
      // Get current round
      if (!round.warTags.contains("#0")) {
        currentRound = rounds.indexOf(round);
      }
    }

    // Step 2: Assign stars and percentage to each clan
    for (ClanLeagueDetails clan in clans) {
      if (totalByClan.containsKey(clan.tag)) {
        clan.stars = totalByClan[clan.tag]?['stars'] ?? 0;
        clan.destructionPercentage =
            totalByClan[clan.tag]?['percentage'] ?? 0.0;
      }
    }

    // Step 3: Sort clans by stars
    clans.sort((a, b) => b.stars.compareTo(a.stars));

    // Step 4: Assign ranking and calculate star difference with the first-ranked clan
    for (int i = 0; i < clans.length; i++) {
      clans[i].rank = i + 1; // Rank starts from 1

      if (i == 0) {
        // The first-ranked clan has a 0-star difference with itself
        clans[i].starsDifferenceWithFirst = 0;
      } else {
        // Calculate the difference in stars with the first-ranked clan
        clans[i].starsDifferenceWithFirst = clans[0].stars - clans[i].stars;
      }
    }

    // Step 5: Calculate star difference with the previous-ranked clan (for leaderboard purposes)
    for (int i = clans.length - 1; i >= 0; i--) {
      if (i == 0) {
        // The first-ranked clan has 0-star difference (it's the top)
        clans[i].starsDifferenceWithNext = 0;
      } else {
        // Calculate the difference in stars with the previous-ranked clan
        clans[i].starsDifferenceWithNext = clans[i - 1].stars - clans[i].stars;
      }
    }
  }

  void sortClans(List<ClanLeagueDetails> clans, String sortBy) {
    // Sort the clans by the specified criterion
    if (sortBy == "stars") {
      clans.sort((a, b) => b.stars.compareTo(a.stars));
    } else if (sortBy == "percentage") {
      clans.sort(
          (a, b) => b.destructionPercentage.compareTo(a.destructionPercentage));
    }
  }
}

class ClanLeagueDetails {
  final String tag;
  final String name;
  final BadgeUrls badgeUrls;
  final int clanLevel;
  final List<LeagueMember> members;
  late int stars;
  late double destructionPercentage;
  late int rank;
  late int starsDifferenceWithFirst;
  late int starsDifferenceWithNext;

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

  static Future<List<CurrentWarInfo>> fetchWarLeagueInfos(
      List<String> warTags, String clanTag) async {
    List<Future<CurrentWarInfo?>> futures = [];

    for (var warTag in warTags) {
      if (warTag != "#0") {
        warTag = warTag.replaceAll('#', '%23');
        Future<CurrentWarInfo?> warLeagueInfo =
            fetchWarLeagueInfo(warTag, clanTag);
        futures.add(warLeagueInfo);
      }
    }

    // Filter out null values and convert to Future<CurrentWarInfo>
    var results = await Future.wait(futures);
    return results
        .where((result) => result != null)
        .cast<CurrentWarInfo>()
        .toList();
  }

  static Future<CurrentWarInfo?> fetchWarLeagueInfo(
      String warTag, String clanTag) async {
    int retryCount = 0;
    while (retryCount < 3) {
      // Attempt the request up to 3 times
      try {
        final response = await http.get(
          Uri.parse('https://api.clashking.xyz/v1/clanwarleagues/wars/$warTag'),
        );

        if (response.statusCode == 200) {
          Map<String, dynamic> json =
              jsonDecode(utf8.decode(response.bodyBytes));
          if (json['state'] != "notInWar") {
            return CurrentWarInfo.fromJson(json, "cwl", clanTag, false);
          }
          return null;
        } else {
          // If too many requests, wait before retrying
          retryCount++;
          await Future.delayed(
              Duration(seconds: 1)); // Wait 1 second before retrying
        }
      } catch (e) {
        if (retryCount >= 2) {
          // Only throw after all retries are exhausted
          throw Exception(
              'Failed to load war league after multiple attempts: $e');
        }
        retryCount++;
        await Future.delayed(
            Duration(seconds: 5)); // Wait 5 seconds before retrying
      }
    }
    return null; // Return null if all retries fail
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
