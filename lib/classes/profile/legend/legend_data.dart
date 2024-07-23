import 'package:intl/intl.dart';
import 'package:clashkingapp/classes/profile/legend/legend_ranking.dart';
import 'package:clashkingapp/classes/profile/legend/legend_day.dart';
import 'package:clashkingapp/classes/profile/legend/legend_season.dart';
import 'package:clashkingapp/classes/profile/legend/legend_functions.dart';
import 'package:clashkingapp/classes/profile/legend/spot_data.dart';

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
        .map((key, value) => MapEntry(key, LegendDay.fromJson(value)));
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

  List<Object> getTrophiesBySeason(DateTime month) {
    print("month: $month");
    Map<String, String> trophiesByDay = {};
    DateTime firstDaySelectedMonth = DateTime(month.year, month.month, 1);
    DateTime lastDayPreviousMonth =
        firstDaySelectedMonth.subtract(Duration(days: 1));

    while (lastDayPreviousMonth.weekday != DateTime.monday) {
      lastDayPreviousMonth = lastDayPreviousMonth.subtract(Duration(days: 1));
    }

    DateTime seasonStart = lastDayPreviousMonth;
    String seasonKey = DateFormat('yyyy-MM-dd').format(seasonStart);
    print("legendData: $legendData");

    legendData.forEach((date, details) {
      DateTime dateObj = DateTime.parse(date);
      String season =
          DateFormat('yyyy-MM-dd').format(findSeasonStartDate(dateObj));
      if (season == seasonKey) {
        String day = DateFormat('MM-dd').format(dateObj);
        String dailyTrophies =
            details.currentTrophies.isNotEmpty ? details.currentTrophies : "0";
        trophiesByDay[day] = dailyTrophies;
      }
    });

    if (trophiesByDay.isNotEmpty) {
      ChartData chartData =
          ChartData.fromSeasonTrophies(trophiesByDay, seasonStart);

      print('spots: ${chartData.spots}');
      return [seasonStart, chartData];
    } else {
      return [seasonStart, {}];
    }
  }
}
