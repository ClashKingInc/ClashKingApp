import 'package:clashkingapp/features/player/models/player_legend_season.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:intl/intl.dart';

class LegendSeasonChart extends StatelessWidget {
  final PlayerLegendSeason? season;

  const LegendSeasonChart({super.key, required this.season});

  @override
  Widget build(BuildContext context) {
    if (season != null) {
      final locale = Localizations.localeOf(context).toString();
      final days = season!.days;

      if (days.isEmpty) return const SizedBox();

      final List<FlSpot> spots = [];
      int minTrophies = 10000;
      int maxTrophies = 0;

      final sortedDays = days.entries.toList()
        ..sort((a, b) => a.key.compareTo(b.key));

      for (var entry in sortedDays) {
        final dayIndex =
            DateTime.parse(entry.key).difference(season!.start).inDays;
        final endTrophies = entry.value.endTrophies ?? 0;
        spots.add(FlSpot(dayIndex.toDouble(), endTrophies.toDouble()));

        if (endTrophies > maxTrophies) maxTrophies = endTrophies;
        if (endTrophies < minTrophies) minTrophies = endTrophies;
      }

      final double rangeY =
          ((maxTrophies - minTrophies) / 5).ceilToDouble().clamp(20, 100);

      return SizedBox(
        width: double.infinity,
        height: 500,
        child: Card(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
          elevation: 4,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(children: [
              Text(
                  AppLocalizations.of(context)?.trophiesBySeason ??
                      "Trophies by Season",
                  style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 16),
              Expanded(
                child: LineChart(
                  LineChartData(
                    gridData:
                        FlGridData(show: true, horizontalInterval: rangeY),
                    titlesData: FlTitlesData(
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 30,
                          interval: 1,
                          getTitlesWidget: (double value, TitleMeta meta) {
                            final labelDate =
                                season!.start.add(Duration(days: value.toInt()));
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(DateFormat('dd').format(labelDate),
                                  style:
                                      Theme.of(context).textTheme.labelMedium),
                            );
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 40,
                          interval: rangeY,
                          getTitlesWidget: (double value, TitleMeta meta) {
                            return Text(
                              NumberFormat('#,###', locale)
                                  .format(value.toInt()),
                              style: Theme.of(context).textTheme.bodySmall,
                            );
                          },
                        ),
                      ),
                      topTitles:
                          AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles:
                          AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    borderData: FlBorderData(
                      show: true,
                      border: Border.all(
                        color: Theme.of(context).colorScheme.primary,
                        width: 1,
                      ),
                    ),
                    lineBarsData: [
                      LineChartBarData(
                        spots: spots,
                        color: Theme.of(context).colorScheme.primary,
                        isCurved: true,
                        barWidth: 2,
                        isStrokeCapRound: true,
                        dotData: FlDotData(show: true),
                        belowBarData: BarAreaData(
                          show: true,
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withOpacity(0.2),
                        ),
                      ),
                    ],
                    minX: 0,
                    maxX: (sortedDays.length - 1).toDouble(),
                    minY: (minTrophies - 40).toDouble(),
                    maxY: (maxTrophies + 40).toDouble(),
                    lineTouchData: LineTouchData(
                      touchTooltipData: LineTouchTooltipData(
                        getTooltipColor: (_) =>
                            Theme.of(context).colorScheme.primary,
                        getTooltipItems: (touchedSpots) => touchedSpots
                            .map(
                              (spot) => LineTooltipItem(
                                spot.y.toInt().toString(),
                                const TextStyle(color: Colors.white),
                              ),
                            )
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
    } else {
      return const SizedBox();
    }
  }
}
