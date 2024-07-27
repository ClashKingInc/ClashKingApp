import 'package:intl/intl.dart';
import 'package:clashkingapp/classes/profile/legend/legend_ranking.dart';
import 'package:clashkingapp/classes/profile/legend/legend_day.dart';
import 'package:clashkingapp/classes/profile/legend/legend_season.dart';
import 'package:clashkingapp/classes/profile/legend/legend_functions.dart';

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
    String date = DateFormat('yyyy-MM-dd').format(selectedDate);

    return PlayerLegendData(
        legendData: legendDataMap,
        legendRanking: LegendRanking.fromJson(json['rankings'] ?? {}),
        name: json['name'] ?? '',
        tag: json['tag'] ?? '',
        townHallLevel: json['townhall'] ?? 0,
        rankings: json['rankings'] ?? {},
        streak: json['streak'] ?? 0,
        isInLegend:
            legendDataMap.isNotEmpty && legendDataMap.containsKey(date));
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

  SeasonTrophies getTrophiesBySeason(DateTime month) {
    int totalAttacks = 0;
    int totalDefenses = 0;
    int totalAttacksTrophies = 0;
    int totalDefensesTrophies = 0;
    int totalTrophies = 0;
    int totalDays = 0;

    List<LegendDay> seasonLegendDays = [];
    LegendDay? lastLegendDay;

    DateTime seasonStart = findSeasonStartEndDate(month);

    DateTime monthEnd = month.add(Duration(days: 31));

    DateTime seasonEnd =
        findSeasonStartEndDate(monthEnd).subtract(Duration(days: 1));

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
        totalAttacks += details.numAttacks;
        totalDefenses += details.defenses.length;

        int attacksTrophies = details.attacks.isNotEmpty
            ? details.attacks.reduce((a, b) => a + b)
            : 0;
        int defensesTrophies = details.defenses.isNotEmpty
            ? details.defenses.reduce((a, b) => a + b)
            : 0;

        totalAttacksTrophies += attacksTrophies;
        totalDefensesTrophies += defensesTrophies;

        totalDays++;

        // Keep track of the last legend day within the season
        lastLegendDay = details;
      }
    });

    // Calculate totalTrophies based on the last legend day of the season
    if (lastLegendDay != null) {
      totalTrophies = int.parse(lastLegendDay!.currentTrophies);
    }

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
        totalDays: totalDays);
  }

  DateTime findSeasonStartEndDate(DateTime month) {
    DateTime firstDaySelectedMonth = DateTime(month.year, month.month, 1);
    DateTime lastDayPreviousMonth =
        firstDaySelectedMonth.subtract(Duration(days: 1));

    while (lastDayPreviousMonth.weekday != DateTime.monday) {
      lastDayPreviousMonth = lastDayPreviousMonth.subtract(Duration(days: 1));
    }
    return lastDayPreviousMonth;
  }
}

class SeasonTrophies {
  final DateTime seasonStart;
  final DateTime seasonEnd;
  final List<LegendDay> seasonLegendDays;
  final int totalAttacks;
  final int totalDefenses;
  final int totalAttacksTrophies;
  final int totalDefensesTrophies;
  final int totalTrophies;
  final int totalDays;
  final int seasonDuration;

  SeasonTrophies(
      {required this.seasonStart,
      required this.seasonEnd,
      required this.seasonDuration,
      required this.seasonLegendDays,
      required this.totalAttacks,
      required this.totalDefenses,
      required this.totalAttacksTrophies,
      required this.totalDefensesTrophies,
      required this.totalTrophies,
      required this.totalDays});

  bool get isEmpty => seasonLegendDays.isEmpty;

  @override
  String toString() =>
      'SeasonTrophies(seasonStart: $seasonStart, seasonLegendDays: $seasonLegendDays, totalAttacks: $totalAttacks, totalDefenses: $totalDefenses, totalAttacksTrophies: $totalAttacksTrophies, totalDefensesTrophies: $totalDefensesTrophies, totalTrophies: $totalTrophies)';
}
