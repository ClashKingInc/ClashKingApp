import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:clashkingapp/classes/profile/legend/spot_data.dart';
import 'package:clashkingapp/classes/profile/legend/legend_season.dart';
import 'package:flutter/material.dart';

class LegendHistoryChart extends StatelessWidget {
  final List<LegendSeason> legendSeasons;

  LegendHistoryChart({required this.legendSeasons});

  @override
  Widget build(BuildContext context) {
    if (legendSeasons.isEmpty) {
      return SizedBox.shrink();
    } else {
      ChartData chartData = ChartData.fromLegendSeasons(legendSeasons);

      return SizedBox(
        width: double.infinity,
        height: 500,
        child: Card(
          margin: EdgeInsets.only(top: 8, bottom: 8, left: 16, right: 16),
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.only(left: 10.0, right: 20.0, top: 10.0, bottom: 10.0),
            child: Column(
              children: [
                Text(
                  AppLocalizations.of(context)?.eosTrophies ?? "EOS Trophies",
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                SizedBox(height: 16),
                Expanded(
                  child: LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawHorizontalLine: true,
                        horizontalInterval: 30,
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 30,
                            getTitlesWidget: (value, meta) {
                              DateTime date = DateTime.fromMillisecondsSinceEpoch(value.toInt());
                              return Padding(
                                padding: const EdgeInsets.only(top: 10.0),
                                child: Text(
                                  DateFormat('M/yy').format(date),
                                  style: Theme.of(context).textTheme.labelSmall,
                                ),
                              );
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            interval: chartData.rangeY + 1,
                            getTitlesWidget: (double value, TitleMeta meta) {
                              return Text('${value.toInt()}');
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
                          isCurved: true,
                          barWidth: 2,
                          isStrokeCapRound: true,
                          dotData: FlDotData(
                            show: true,
                          ),
                          belowBarData: BarAreaData(
                            show: true,
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                          ),
                        ),
                      ],
                      minX: chartData.minX,
                      maxX: chartData.maxX,
                      minY: chartData.minY,
                      maxY: chartData.maxY,
                      lineTouchData: LineTouchData(
                        touchTooltipData: LineTouchTooltipData(
                          getTooltipColor: (spot) => Theme.of(context).colorScheme.primary.withOpacity(0.8),
                        ),
                        touchCallback: (FlTouchEvent touchEvent, LineTouchResponse? touchResponse) {},
                        handleBuiltInTouches: true,
                      ),
                    ),
                    duration: Duration(milliseconds: 250),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }
}