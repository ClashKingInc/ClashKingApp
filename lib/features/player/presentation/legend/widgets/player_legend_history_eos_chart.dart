import 'package:clashkingapp/features/player/models/player_legend_ranking.dart';
import 'package:clashkingapp/features/player/models/player_legend_spot_data.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class PlayerLegendHistoryEosChart extends StatelessWidget {
  final List<PlayerLegendRanking> rankings;

  const PlayerLegendHistoryEosChart({super.key, required this.rankings});

  @override
  Widget build(BuildContext context) {
    if (rankings.isEmpty) {
      return const SizedBox.shrink();
    }

    try {
      final chartData = SpotData.fromLegendRankings(rankings);
      final locale = Localizations.localeOf(context);
      final dateFormat = DateFormat.yMMMM(locale.toString());

      return SizedBox(
        width: double.infinity,
        height: 500,
        child: Card(
          margin: const EdgeInsets.only(top: 8, bottom: 8, left: 16, right: 16),
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            child: Column(
              children: [
                Text(
                  AppLocalizations.of(context)?.eosTrophies ?? "EOS Trophies",
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawHorizontalLine: true,
                        horizontalInterval: 30,
                      ),
                      titlesData: FlTitlesData(
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: chartData.rangeX * 2,
                            reservedSize: 50,
                            getTitlesWidget: (value, meta) {
                              final date = DateTime.fromMillisecondsSinceEpoch(
                                  value.toInt());
                              return Padding(
                                padding: const EdgeInsets.only(top: 10.0),
                                child: Transform.rotate(
                                  angle: -0.5,
                                  child: Text(
                                    DateFormat('MM/yy').format(date),
                                    style:
                                        Theme.of(context).textTheme.labelSmall,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 50,
                            interval: SpotData.getYAxisInterval(
                                chartData.minY, chartData.maxY),
                            getTitlesWidget: (value, meta) {
                              return Text(
                                NumberFormat('#,###', locale.toString())
                                    .format(value.toInt()),
                                style: Theme.of(context).textTheme.bodySmall,
                              );
                            },
                          ),
                        ),
                        rightTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: AxisTitles(
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
                      lineBarsData: [
                        LineChartBarData(
                          spots: chartData.spots,
                          color: Theme.of(context).colorScheme.primary,
                          isCurved: false,
                          barWidth: 2,
                          isStrokeCapRound: true,
                          dotData: FlDotData(show: true),
                          belowBarData: BarAreaData(
                            show: true,
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withValues(alpha: 0.2),
                          ),
                        ),
                      ],
                      minX: chartData.minX,
                      maxX: chartData.maxX,
                      minY: chartData.minY,
                      maxY: SpotData.roundUpToNext100(chartData.maxY),
                      lineTouchData: LineTouchData(
                        touchTooltipData: LineTouchTooltipData(
                          getTooltipColor: (spot) =>
                              Theme.of(context).colorScheme.primary,
                          getTooltipItems: (spots) => spots.map((spot) {
                            final date = DateTime.fromMillisecondsSinceEpoch(
                                spot.x.toInt());
                            return LineTooltipItem(
                              '${dateFormat.format(date)} : ${spot.y.toInt()}',
                              const TextStyle(color: Colors.white),
                            );
                          }).toList(),
                        ),
                        handleBuiltInTouches: true,
                      ),
                    ),
                    duration: const Duration(milliseconds: 250),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } catch (_) {
      return const SizedBox.shrink();
    }
  }
}
