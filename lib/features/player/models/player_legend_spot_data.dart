import 'package:fl_chart/fl_chart.dart';
import 'package:clashkingapp/features/player/models/player_legend_ranking.dart';

class SpotData {
  final List<FlSpot> spots;
  final double minX;
  final double maxX;
  final double minY;
  final double maxY;
  final double rangeX;
  final double rangeY;

  SpotData({
    required this.spots,
    required this.minX,
    required this.maxX,
    required this.minY,
    required this.maxY,
    required this.rangeX,
    required this.rangeY,
  });

  /// Builds SpotData from a list of PlayerLegendRanking
  static SpotData fromLegendRankings(List<PlayerLegendRanking> rankings) {
    if (rankings.isEmpty) {
      return SpotData(
        spots: [],
        minX: 0,
        maxX: 0,
        minY: 0,
        maxY: 0,
        rangeX: 1,
        rangeY: 1,
      );
    }

    final spots = rankings.map((ranking) {
      final seasonDate = DateTime.parse('${ranking.season}-01');
      return FlSpot(seasonDate.millisecondsSinceEpoch.toDouble(),
          ranking.trophies.toDouble());
    }).toList()
      ..sort((a, b) => a.x.compareTo(b.x));

    final minX = spots.first.x;
    final maxX = spots.last.x;
    final minY = spots.map((s) => s.y).reduce((a, b) => a < b ? a : b);
    final maxY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);

    final double rangeX = ((maxX - minX) / 5).clamp(1, double.infinity);
    final double rangeY = ((maxY - minY) / 5).clamp(1, double.infinity);

    return SpotData(
      spots: spots,
      minX: minX,
      maxX: maxX,
      minY: minY,
      maxY: maxY,
      rangeX: rangeX,
      rangeY: rangeY,
    );
  }

  static double getYAxisInterval(double minY, double maxY) {
    final range = maxY - minY;
    if (range < 50) return 10;
    if (range < 100) return 20;
    if (range < 200) return 50;
    return 100;
  }

  static double roundUpToNext100(double value) {
    return (value / 100).ceil() * 100;
  }
}
