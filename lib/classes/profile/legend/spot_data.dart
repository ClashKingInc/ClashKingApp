import 'package:fl_chart/fl_chart.dart';
import 'package:clashkingapp/classes/profile/legend/legend_season.dart';
import 'package:clashkingapp/classes/profile/legend/legend_day.dart';

class SpotData {
  final double x;
  final double y;

  SpotData({required this.x, required this.y});
}

class ChartData {
  final double minX;
  final double maxX;
  final double minY;
  final double maxY;
  final double rangeY;
  final double rangeX;
  final List<FlSpot> spots;

  ChartData({
    required this.minX,
    required this.maxX,
    required this.minY,
    required this.maxY,
    required this.rangeY,
    required this.rangeX,
    required this.spots,
  });

  factory ChartData.fromLegendSeasons(List<LegendSeason> legendSeasons) {
    List<SpotData> spotDataList =
        legendSeasons.map((season) => season.toSpotData()).toList();

    // Sort by the timestamp in ascending order (from the earliest date to the latest)
    spotDataList.sort((a, b) => a.x.compareTo(b.x));

    List<FlSpot> spots =
        spotDataList.map((spot) => FlSpot(spot.x, spot.y)).toList();
    double maxY = spots.map((spot) => spot.y).reduce((a, b) => a > b ? a : b);
    double minY = spots.map((spot) => spot.y).reduce((a, b) => a < b ? a : b);

    int hundredsMaxY = (maxY / 100).floor();
    if (maxY % 100 < 20) {
      hundredsMaxY += 1;
    }
    maxY = (hundredsMaxY + 1) * 100.0;

    int hundredsMinY = (minY / 100).floor();
    minY = (hundredsMinY) * 100.0;

    double minX = spots.first.x;
    double maxX = spots.last.x;
    double rangeY = 100;
    if (rangeY == 0) rangeY = 1;

    double rangeX = (maxX - minX) / 60 * 60 * 24 * 30 * 1000;

    if (rangeX == 0) rangeX = 1;

    if (minY == maxY) {
      maxY += 100;
    }

    return ChartData(
      minX: minX,
      maxX: maxX,
      minY: minY,
      maxY: maxY,
      rangeY: rangeY,
      rangeX: rangeX,
      spots: spots,
    );
  }

  factory ChartData.fromSeasonTrophies(
      List<LegendDay> seasonData, DateTime seasonStart) {
    List<FlSpot> spots = [];
    int index = 0;
    seasonStart = DateTime(
        seasonStart.year, seasonStart.month, seasonStart.day, 0, 0, 0, 0, 0);

    DateTime currentDate = seasonStart;
    DateTime lastDayOfMonth = getLastDayOfMonth(seasonStart);

    for (var legendDay in seasonData) {
      DateTime dateObj = legendDay.date;
      String trophies = legendDay.currentTrophies;

      while (currentDate.isBefore(dateObj)) {
        spots.add(FlSpot(index.toDouble(), 4900.0));
        index++;
        currentDate = currentDate.add(Duration(days: 1));

        // Arrêter la boucle si le jour actuel dépasse le nombre de jours dans le mois
        if (currentDate.isAfter(lastDayOfMonth)) {
          // Transition vers le mois suivant
          seasonStart = DateTime(currentDate.year, currentDate.month + 1, 1);
          currentDate = seasonStart;
          lastDayOfMonth = getLastDayOfMonth(seasonStart);
        }
      }

      double trophyValue = double.parse(trophies);
      spots.add(FlSpot(index.toDouble(), trophyValue > 4900 ? trophyValue : 4900.0));
      index++;
      currentDate = currentDate.add(Duration(days: 1));
    }

    double minY = spots.map((spot) => spot.y).reduce((a, b) => a < b ? a : b);
    double maxY = spots.map((spot) => spot.y).reduce((a, b) => a > b ? a : b);

    int hundredsMaxY = (maxY / 100).floor();
    if (maxY % 100 < 20) {
      hundredsMaxY += 1;
    }
    maxY = (hundredsMaxY + 1) * 100.0;

    int hundredsMinY = (minY / 100).floor();
    minY = (hundredsMinY) * 100.0;

    if (minY == maxY) {
      maxY += 100;
    }

    double minX = spots.first.x;
    double maxX = spots.last.x;
    double rangeY = 100;
    if (rangeY == 0) rangeY = 1;

    double rangeX = (maxX - minX) / 10;
    if (rangeX == 0) rangeX = 1;

    return ChartData(
      minX: minX,
      maxX: maxX,
      minY: minY,
      maxY: maxY,
      rangeX: rangeX,
      rangeY: rangeY,
      spots: spots,
    );
  }
}


DateTime getLastDayOfMonth(DateTime date) {
  // Crée une nouvelle date pour le premier jour du mois suivant
  var firstDayOfNextMonth = (date.month < 12)
      ? DateTime.utc(date.year, date.month + 1, 1)
      : DateTime.utc(date.year + 1, 1, 1);

  // Soustrait un jour pour obtenir le dernier jour du mois actuel
  return firstDayOfNextMonth.subtract(Duration(days: 1));
}
