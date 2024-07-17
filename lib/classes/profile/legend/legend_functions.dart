import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:clashkingapp/classes/profile/legend/legend_attack.dart';
import 'package:clashkingapp/classes/profile/legend/legend_defense.dart';


String convertToTimeAgo(int timestamp, context) {
  DateTime now = DateTime.now();
  DateTime date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
  Duration diff = now.difference(date);

  if (diff.inDays >= 1) {
    return '${diff.inDays == 1 ? AppLocalizations.of(context)?.dayAgo(diff.inDays) : AppLocalizations.of(context)?.daysAgo(diff.inDays)}';
  } else if (diff.inHours >= 1) {
    return '${diff.inHours == 1 ? AppLocalizations.of(context)?.hourAgo(diff.inHours) : AppLocalizations.of(context)?.hoursAgo(diff.inHours)}';
  } else if (diff.inMinutes >= 1) {
    return '${diff.inMinutes == 1 ? AppLocalizations.of(context)?.minuteAgo(diff.inMinutes) : AppLocalizations.of(context)?.minutesAgo(diff.inMinutes)}';
  } else {
    return AppLocalizations.of(context)?.justNow ?? "Just now";
  }
}

Map<String, dynamic> calculateStats(List<dynamic> list) {
  int sum = 0;
  int count = 0;
  double average = 0;
  int remaining = 320;
  int bestPossibleTrophies = 0;

  if (list.isNotEmpty) {
    var filteredList =
        list.where((item) => item is Attack || item is Defense).toList();
    if (filteredList.isNotEmpty) {
      sum = filteredList
          .map((item) =>
              (item is Attack ? item.change : (item as Defense).change))
          .reduce((value, element) => value + element);
      count = filteredList.length +
          filteredList
              .where((item) =>
                  (item is Attack ? item.change : (item as Defense).change) >
                  40)
              .length;
      average = sum / count;
      remaining = 320 - count * 40;
      bestPossibleTrophies = remaining + sum;
    }
  }

  return {
    'sum': sum,
    'count': count,
    'average': average,
    'remaining': remaining,
    'bestPossibleTrophies': bestPossibleTrophies,
  };
}

DateTime findSeasonStartDate(DateTime date) {
  int year = date.year;
  int month = date.month;

  DateTime firstDayCurrentMonth = DateTime(year, month, 1);
  DateTime lastDayCurrentMonth =
      DateTime(year, month + 1, 1).subtract(Duration(days: 1));

  int daysToLastMondayOfCurrentMonth =
      (lastDayCurrentMonth.weekday - DateTime.monday) % 7;
  DateTime lastMondayOfCurrentMonth = lastDayCurrentMonth
      .subtract(Duration(days: daysToLastMondayOfCurrentMonth));

  // Si la date est avant le dernier lundi, alors il faut aller chercher le dernier lundi du mois précédent
  if (date.isBefore(lastMondayOfCurrentMonth)) {
    DateTime lastDayPreviousMonth =
        firstDayCurrentMonth.subtract(Duration(days: 1));
    int daysToLastMondayOfPreviousMonth =
        (lastDayPreviousMonth.weekday - DateTime.monday) % 7;
    return lastDayPreviousMonth
        .subtract(Duration(days: daysToLastMondayOfPreviousMonth));
  }

  return lastMondayOfCurrentMonth;
}

List<FlSpot> convertToContinuousScale(
    Map<String, String> seasonData, DateTime seasonStart) {
  List<FlSpot> spots = [];

  int index = 0;
  seasonData.forEach((day, trophies) {
    while (seasonStart.add(Duration(days: index)).day != int.parse(day) &&
        seasonStart.day <= 32) {
      index++;
    }

    spots.add(FlSpot(index.toDouble(), double.parse(trophies)));
    index++;
  });

  return spots;
}

DateTime findCurrentSeasonMonth(currentDate) {
  DateTime selectedMonth = DateTime.now().toUtc().subtract(Duration(hours: 5));

  DateTime firstDaySelectedMonth =
      DateTime(selectedMonth.year, selectedMonth.month, 1);
  DateTime lastDayPreviousMonth =
      firstDaySelectedMonth.subtract(Duration(days: 1));

  while (lastDayPreviousMonth.weekday != DateTime.monday) {
    lastDayPreviousMonth = lastDayPreviousMonth.subtract(Duration(days: 1));
  }

  // If selectedMonth is after the last Monday of the previous month, move to the next month
  if (selectedMonth.isAfter(lastDayPreviousMonth)) {
    selectedMonth = DateTime(selectedMonth.year, selectedMonth.month + 1, 1);
  }

  return selectedMonth;
}
