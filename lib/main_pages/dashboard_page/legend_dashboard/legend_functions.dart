import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:fl_chart/fl_chart.dart';

String convertToTimeAgo(int timestamp, context) {
  DateTime now = DateTime.now();
  DateTime date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
  Duration diff = now.difference(date);

  if (diff.inDays >= 1) {
    return '${diff.inDays} ${diff.inDays == 1 ? AppLocalizations.of(context)?.dayAgo : AppLocalizations.of(context)?.daysAgo}';
  } else if (diff.inHours >= 1) {
    return '${diff.inHours} ${diff.inHours == 1 ? AppLocalizations.of(context)?.hourAgo : AppLocalizations.of(context)?.hoursAgo}';
  } else if (diff.inMinutes >= 1) {
    return '${diff.inMinutes} ${diff.inMinutes == 1 ? AppLocalizations.of(context)?.minuteAgo : AppLocalizations.of(context)?.minutesAgo}';
  } else {
    return AppLocalizations.of(context)?.justNow ?? "Just now";
  }
}

Map<String, dynamic> calculateStats(List<dynamic> list) {
  int sum = 0;
  if (list.isNotEmpty) {
    sum = list
        .whereType<Map>()
        .map((item) => item['change'])
        .reduce((value, element) => value + element);
  }
  int count = list.whereType<Map>().length +
      list.whereType<Map>().where((item) => item['change'] > 40).length;
  double average = count == 0 ? 0 : sum / count;
  int remaining = 320 - count * 40;
  int bestPossibleTrophies = remaining + sum;

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

  DateTime firstDayNextMonth = DateTime(year, month + 1, 1);
  DateTime lastDayCurrentMonth = firstDayNextMonth.subtract(Duration(days: 1));

  int daysToLastMondayOfThisMonth =
      (lastDayCurrentMonth.weekday - DateTime.monday);
  if (daysToLastMondayOfThisMonth < 0) {
    daysToLastMondayOfThisMonth += 7; // Ensure non-negative result
  }
  DateTime lastMondayOfThisMonth =
      lastDayCurrentMonth.subtract(Duration(days: daysToLastMondayOfThisMonth));
  if (date.isAfter(lastMondayOfThisMonth) ||
      date.isAtSameMomentAs(lastMondayOfThisMonth)) {
    return lastMondayOfThisMonth;
  } else {
    // Find the first day of the current month
    DateTime firstDayCurrentMonth = DateTime(year, month, 1);

    // Subtract one day to get the last day of the previous month
    DateTime lastDayPreviousMonth =
        firstDayCurrentMonth.subtract(Duration(days: 1));

    // Calculate the weekday of the last day of the previous month
    int daysToLastMonday = (lastDayPreviousMonth.weekday - DateTime.monday);
    if (daysToLastMonday < 0) {
      daysToLastMonday += 7; // Ensure non-negative result
    }

    // Get the last Monday of the previous month by subtracting the days calculated
    DateTime lastMonday =
        lastDayPreviousMonth.subtract(Duration(days: daysToLastMonday));

    return lastMonday;
  }
}

List<FlSpot> convertToContinuousScale(
    Map<String, String> seasonData, DateTime seasonStart) {
  List<FlSpot> spots = [];
  List<String> labels = []; // This will hold the labels for the x-axis

  int index = 0;
  seasonData.forEach((day, trophies) {
    spots.add(FlSpot(index.toDouble(), double.parse(trophies)));
    print(day);
    labels.add(
        day); // Assuming 'day' is a String like '25', '26', ..., '01', '02', etc.
    index++;
  });
  
  return spots;
}
