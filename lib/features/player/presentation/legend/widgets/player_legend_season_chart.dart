import 'package:clashkingapp/features/player/models/player_legend_season.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

class LegendSeasonChart extends StatelessWidget {
  final PlayerLegendSeason? season;

  const LegendSeasonChart({super.key, required this.season});

  @override
  Widget build(BuildContext context) {
    if (season == null || season!.days.isEmpty) return const SizedBox();

    final locale = Localizations.localeOf(context).toString();
    final days = season!.days;

    final sortedDays = days.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    List<List<FlSpot>> separatedSpots = [];
    List<FlSpot> currentLine = [];

    int minTrophies = 10000;
    int maxTrophies = 0;

    for (int i = 0; i < sortedDays.length; i++) {
      final entry = sortedDays[i];
      final currentDay = DateTime.parse(entry.key);
      final x = currentDay.difference(season!.start).inDays.toDouble();
      final endTrophies = entry.value.endTrophies ?? 0;
      final spot = FlSpot(x, endTrophies.toDouble());

      if (currentLine.isEmpty) {
        currentLine.add(spot);
      } else {
        final prevDay = DateTime.parse(sortedDays[i - 1].key);
        final isAdjacent = currentDay.difference(prevDay).inDays == 1;
        if (isAdjacent) {
          currentLine.add(spot);
        } else {
          separatedSpots.add(currentLine);
          currentLine = [spot];
        }
      }

      if (endTrophies > maxTrophies) maxTrophies = endTrophies;
      if (endTrophies < minTrophies) minTrophies = endTrophies;
    }
    if (currentLine.isNotEmpty) separatedSpots.add(currentLine);

    final double rangeY =
        ((maxTrophies - minTrophies) / 5).ceilToDouble().clamp(20, 100);

    final lastDayKey = sortedDays.last.key;
    final maxX =
        DateTime.parse(lastDayKey).difference(season!.start).inDays.toDouble();

    final minY = ((minTrophies / 50).floor() * 50 - 50).toDouble();
    final maxY = ((maxTrophies / 50).ceil() * 50 + 50).toDouble();

    final lines = separatedSpots.map((list) {
      return LineChartBarData(
        spots: list,
        isCurved: false,
        barWidth: 2,
        isStrokeCapRound: true,
        color: Theme.of(context).colorScheme.primary,
        dotData: FlDotData(show: true),
        belowBarData: BarAreaData(
          show: true,
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
        ),
      );
    }).toList();

    return SizedBox(
      width: double.infinity,
      height: 500,
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(children: [
            Text(
              AppLocalizations.of(context)?.legendsTrophiesBySeason ?? "Trophies by Season",
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    horizontalInterval: rangeY,
                  ),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 30,
                          interval: 1,
                          getTitlesWidget: (value, meta) {
                            final date = season!.start
                                .add(Duration(days: value.toInt()));
                            if (date.day % 2 == 0) {
                              return Text(
                                DateFormat('dd').format(date),
                                style: Theme.of(context).textTheme.labelSmall,
                              );
                            } else {
                              return const SizedBox.shrink();
                            }
                          }),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        interval: rangeY,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            NumberFormat('#,###', locale).format(value.toInt()),
                            style: Theme.of(context).textTheme.bodySmall,
                          );
                        },
                      ),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(
                      color: Theme.of(context).colorScheme.primary,
                      width: 1,
                    ),
                  ),
                  lineBarsData: lines,
                  minX: 0,
                  maxX: maxX,
                  minY: minY,
                  maxY: maxY,
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipColor: (_) => Theme.of(context).colorScheme.primary,
                      getTooltipItems: (touchedSpots) => touchedSpots
                          .map((spot) => LineTooltipItem(
                                spot.y.toInt().toString(),
                                const TextStyle(color: Colors.white),
                              ))
                          .toList(),
                    ),
                    handleBuiltInTouches: true,
                  ),
                ),
                duration: const Duration(milliseconds: 250),
              ),
            )
          ]),
        ),
      ),
    );
  }
}