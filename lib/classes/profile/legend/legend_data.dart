import 'package:clashkingapp/classes/profile/legend/legend_defense.dart';
import 'package:intl/intl.dart';
import 'package:clashkingapp/classes/profile/legend/legend_ranking.dart';
import 'package:clashkingapp/classes/profile/legend/legend_attack.dart';
import 'package:clashkingapp/classes/profile/legend/legend_day.dart';
import 'package:clashkingapp/classes/profile/legend/legend_season.dart';
import 'package:clashkingapp/classes/profile/legend/legend_functions.dart';
import 'package:clashkingapp/classes/profile/legend/legends_season_trophies.dart';
import 'package:clashkingapp/classes/functions.dart';

class PlayerLegendData {
  final Map<String, LegendDay> legendData;
  final LegendRanking legendRanking;
  late final List<LegendSeason> legendSeasons;
  final String name;
  final String tag;
  final int townHallLevel;
  final Map<String, dynamic> rankings;
  final int streak;
  List<dynamic> seasonsData = [];
  String firstTrophies = '0';
  String currentTrophies = "0";
  int diffTrophies = 0;
  List<dynamic> attacksList = [];
  List<dynamic> defensesList = [];
  final bool isInLegend;
  String attackIcon =
      "https://clashkingfiles.b-cdn.net/icons/Icon_HV_Sword.png";
  String defenseIcon =
      "https://clashkingfiles.b-cdn.net/icons/Icon_HV_Shield_Arrow.png";
  String legendIcon =
      "https://clashkingfiles.b-cdn.net/icons/Icon_HV_League_Legend_3_Border_No_Padding.png";

  PlayerLegendData(
      {required this.legendData,
      required this.legendRanking,
      required this.name,
      required this.tag,
      required this.townHallLevel,
      required this.rankings,
      required this.streak,
      required this.isInLegend});

  factory PlayerLegendData.fromJson(Map<String, dynamic> json) {
    var legendDataJson = json['legends'] as Map<String, dynamic>? ?? {};
    Map<String, LegendDay> legendDataMap = legendDataJson
        .map((key, value) => MapEntry(key, LegendDay.fromJson(key, value)));
    DateTime selectedDate = DateTime.now().toUtc().subtract(Duration(hours: 5));
    String date = DateFormat('yyyy-MM-dd')
        .format(selectedDate.subtract(Duration(days: 1)));

    return PlayerLegendData(
        legendData: legendDataMap,
        legendRanking: LegendRanking.fromJson(json['rankings'] ?? {}),
        name: json['name'] ?? '',
        tag: json['tag'] ?? '',
        townHallLevel: json['townhall'] ?? 0,
        rankings: json['rankings'] ?? {},
        streak: json['streak'] ?? 0,
        isInLegend: legendDataMap.isNotEmpty &&
            PlayerLegendData.isAboveThreshold(legendDataMap, date));
  }

  Map<String, dynamic> toJson() {
    return {
      'legends': legendData.map((key, value) => MapEntry(key, value.toJson())),
      'legendRanking': legendRanking,
      'name': name,
      'tag': tag,
      'townHallLevel': townHallLevel,
      'rankings': rankings,
      'streak': streak,
    };
  }

  bool get isEmpty => legendData.isEmpty;
  bool get isNotEmpty => legendData.isNotEmpty;

  static bool isAboveThreshold(
      Map<String, dynamic> legendDataMap, String date) {

    if (!legendDataMap.containsKey(date)) {
      return false;
    }

    LegendDay dailyData = legendDataMap[date];
    List<Attack> newAttacks = dailyData.newAttacks ;
    List<Defense> newDefenses = dailyData.newDefenses;

    int latestAttackTime = 0;
    int latestTrophies = 0;

    // Find the latest attack
    if (newAttacks.isNotEmpty) {
      var latestAttack =
          newAttacks.reduce((a, b) => a.time > b.time ? a : b);
      latestAttackTime = latestAttack.time;
      latestTrophies = latestAttack.trophies;
    }

    // Find the latest defense
    if (newDefenses.isNotEmpty) {
      var latestDefense =
          newDefenses.reduce((a, b) => a.time > b.time ? a : b);
      if (latestDefense.time > latestAttackTime) {
        latestTrophies = latestDefense.trophies;
      }
    }

    // Check if the latest trophies are above 4900
    return latestTrophies > 4900;
  }

  SeasonTrophies getTrophiesBySeason(DateTime month) {
    int totalAttacks = 0;
    int totalDefenses = 0;
    int totalAttacksTrophies = 0;
    int totalDefensesTrophies = 0;
    int totalTrophies = 0;
    int totalDays = 0;
    int daysInLegend = 0;
    double percentageNoStarsDefenses = 0;
    double percentageNoStarsAttacks = 0;
    double percentageOneStarsDefenses = 0;
    double percentageOneStarsAttacks = 0;
    double percentageTwoStarsDefenses = 0;
    double percentageTwoStarsAttacks = 0;
    double percentageThreeStarsDefenses = 0;
    double percentageThreeStarsAttacks = 0;

    List<LegendDay> seasonLegendDays = [];
    LegendDay? lastLegendDay;

    List<DateTime> seasonDates = findSeasonStartEndDate(month);

    DateTime seasonStart = seasonDates[0];
    DateTime seasonEnd = seasonDates[1];

    // Calculate the difference
    Duration difference = seasonEnd.difference(seasonStart);

    // Extract the number of days
    int daysDifference = difference.inDays + 1;

    String seasonKey = DateFormat('yyyy-MM-dd').format(seasonStart);

    legendData.forEach((date, details) {
      DateTime dateObj = DateTime.parse(date);
      String season =
          DateFormat('yyyy-MM-dd').format(findSeasonStartDate(dateObj));
      if (season == seasonKey) {
        seasonLegendDays.add(details);
        totalAttacks += LegendDay.countAttacksDefenses(details.attacks);
        totalDefenses += LegendDay.countAttacksDefenses(details.defenses);

        int attacksTrophies = details.attacks.isNotEmpty
            ? details.attacks.reduce((a, b) => a + b)
            : 0;
        int defensesTrophies = details.defenses.isNotEmpty
            ? details.defenses.reduce((a, b) => a + b)
            : 0;

        for (int attack in details.attacks) {
          switch (attack) {
            case (80):
              percentageThreeStarsAttacks += 2;
              break;
            case (> 40 && < 80):
              percentageTwoStarsAttacks += 2;
              break;
            case (40):
              percentageThreeStarsAttacks += 1;
              break;
            case (<= 15 && >= 5):
              percentageOneStarsAttacks += 1;
              break;
            case (<= 4):
              percentageNoStarsAttacks += 1;
              break;
            default:
              percentageTwoStarsAttacks += 1;
              break;
          }
        }

        for (int defense in details.defenses) {
          switch (defense) {
            case (80):
              percentageThreeStarsDefenses += 2;
              break;
            case (> 40 && < 80):
              percentageTwoStarsDefenses += 2;
              break;
            case (40):
              percentageThreeStarsDefenses += 1;
              break;
            case (<= 32 && >= 16):
              percentageTwoStarsDefenses += 1;
              break;
            case (<= 15 && >= 5):
              percentageOneStarsDefenses += 1;
              break;
            case (<= 4):
              percentageNoStarsDefenses += 1;
              break;
            default:
          }
        }

        totalAttacksTrophies += attacksTrophies;
        totalDefensesTrophies += defensesTrophies;

        // Keep track of the last legend day within the season
        lastLegendDay = details;

        daysInLegend++;
      }
    });

    // Calculate totalTrophies based on the last legend day of the season
    if (lastLegendDay != null) {
      totalTrophies = int.parse(lastLegendDay!.currentTrophies);
    }

    if (seasonEnd.isAfter(DateTime.now())) {
      totalDays = DateTime.now().difference(seasonStart).inDays + 1;
    } else {
      totalDays = daysDifference;
    }

    int averageAttacksTrophies =
        totalAttacksTrophies ~/ (totalAttacks != 0 ? totalAttacks : 1);
    int averageDefensesTrophies =
        totalDefensesTrophies ~/ (totalDefenses != 0 ? totalDefenses : 1);

    percentageThreeStarsAttacks = (percentageThreeStarsAttacks *
        100 /
        (totalAttacks != 0 ? totalAttacks : 1));
    percentageTwoStarsAttacks = (percentageTwoStarsAttacks *
        100 /
        (totalAttacks != 0 ? totalAttacks : 1));
    percentageOneStarsAttacks = (percentageOneStarsAttacks *
        100 /
        (totalAttacks != 0 ? totalAttacks : 1));
    percentageNoStarsAttacks = (percentageNoStarsAttacks *
        100 /
        (totalAttacks != 0 ? totalAttacks : 1));

    percentageThreeStarsDefenses = (percentageThreeStarsDefenses *
        100 /
        (totalDefenses != 0 ? totalDefenses : 1));
    percentageTwoStarsDefenses = (percentageTwoStarsDefenses *
        100 /
        (totalDefenses != 0 ? totalDefenses : 1));
    percentageOneStarsDefenses = (percentageOneStarsDefenses *
        100 /
        (totalDefenses != 0 ? totalDefenses : 1));
    percentageNoStarsDefenses = (percentageNoStarsDefenses *
        100 /
        (totalDefenses != 0 ? totalDefenses : 1));

    return SeasonTrophies(
        seasonStart: seasonStart,
        seasonEnd: seasonEnd,
        seasonDuration: daysDifference,
        seasonLegendDays: seasonLegendDays,
        totalAttacks: totalAttacks,
        totalDefenses: totalDefenses,
        totalAttacksTrophies: totalAttacksTrophies,
        totalDefensesTrophies: totalDefensesTrophies,
        totalTrophies: totalTrophies,
        totalDays: totalDays,
        daysInLegend : daysInLegend,
        averageAttacksTrophies: averageAttacksTrophies,
        averageDefensesTrophies: averageDefensesTrophies,
        percentageNoStarsAttacks: percentageNoStarsAttacks,
        percentageNoStarsDefenses: percentageNoStarsDefenses,
        percentageOneStarsAttacks: percentageOneStarsAttacks,
        percentageOneStarsDefenses: percentageOneStarsDefenses,
        percentageTwoStarsAttacks: percentageTwoStarsAttacks,
        percentageTwoStarsDefenses: percentageTwoStarsDefenses,
        percentageThreeStarsAttacks: percentageThreeStarsAttacks,
        percentageThreeStarsDefenses: percentageThreeStarsDefenses);
  }

  List<DateTime> findSeasonStartEndDate(DateTime currentDate) {
    DateTime seasonStart =
        findLastMondayOfMonth(currentDate.year, currentDate.month);

    DateTime seasonEnd =
        findLastMondayOfMonth(currentDate.year, currentDate.month + 1);
    if (currentDate.isBefore(seasonStart) || currentDate == seasonStart) {
      seasonStart =
          findLastMondayOfMonth(currentDate.year, currentDate.month - 1);
      seasonEnd = findLastMondayOfMonth(currentDate.year, currentDate.month)
          .subtract(Duration(days: 1));
    }
    return [seasonStart, seasonEnd];
  }
}
