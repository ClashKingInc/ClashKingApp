import 'package:clashkingapp/core/functions.dart';
import 'package:clashkingapp/features/player/models/player_legend_day.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';
import 'package:fl_chart/fl_chart.dart';

String convertToTimeAgo(int timestamp, context) {
  DateTime now = DateTime.now();
  DateTime date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
  Duration diff = now.difference(date);

  if (diff.inDays >= 1) {
    return '${diff.inDays == 1 ? AppLocalizations.of(context)?.dayAgo(diff.inDays) : AppLocalizations.of(context)?.daysAgo(diff.inDays)}';
  } else if (diff.inHours >= 1) {
    return '${diff.inHours == 1 ? AppLocalizations.of(context)?.hourAgo(diff.inHours) : AppLocalizations.of(context)?.hoursAgo(diff.inHours, "")}';
  } else if (diff.inMinutes >= 1) {
    return '${diff.inMinutes == 1 ? AppLocalizations.of(context)?.minuteAgo(diff.inMinutes) : AppLocalizations.of(context)?.minutesAgo(diff.inMinutes)}';
  } else {
    return AppLocalizations.of(context)?.justNow ?? "Just now";
  }
}

DateTime findSeasonStartDate(DateTime date) {
  int year = date.year;
  int month = date.month;
  int day = date.day;
  date = DateTime.utc(year, month, day, 0, 0, 0, 0);

  DateTime lastDayCurrentMonth = (month == 12)
      ? DateTime.utc(year + 1, 1, 1).subtract(Duration(days: 1))
      : DateTime.utc(year, month + 1, 1).subtract(Duration(days: 1));

  int daysToLastMondayOfCurrentMonth =
      (lastDayCurrentMonth.weekday - DateTime.monday + 7) % 7;
  DateTime lastMondayOfCurrentMonth = lastDayCurrentMonth
      .subtract(Duration(days: daysToLastMondayOfCurrentMonth));

  // Si la date est avant le dernier lundi, alors il faut aller chercher le dernier lundi du mois précédent
  if (date.isBefore(lastMondayOfCurrentMonth)) {
    DateTime lastDayPreviousMonth = (month == 1)
        ? DateTime.utc(year - 1, 12, 31)
        : DateTime.utc(year, month - 1, 1)
            .add(Duration(days: DateTime(year, month, 0).day - 1));
    int daysToLastMondayOfPreviousMonth =
        (lastDayPreviousMonth.weekday - DateTime.monday + 7) % 7;
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

DateTime findCurrentSeasonMonth(currentDate) {
  List<DateTime> test = findSeasonStartEndDate(currentDate);
  DateTime selectedMonth = DateTime(test[1].year, test[1].month, 1);
  return selectedMonth;
}

DateTime getLastMonthWithSeasonData(Map<String, PlayerLegendDay> seasonData) {
  if (seasonData.isEmpty) {
    throw Exception("No season data available");
  }

  // Convert the keys of the map to DateTime objects
  List<DateTime> dates = seasonData.keys.map((date) {
    List<String> parts = date.split('-');
    int monthInt = int.parse(parts[0]);
    int dayInt = int.parse(parts[1]);
    return DateTime(
        DateTime.now().year, monthInt, dayInt); // Assuming current year
  }).toList();

  // Sort the dates in descending order
  dates.sort((a, b) => b.compareTo(a));

  // Get the most recent date
  DateTime mostRecentDate = dates.first;

  // Return the first day of the month for the most recent date
  return DateTime(mostRecentDate.year, mostRecentDate.month, 1);
}
