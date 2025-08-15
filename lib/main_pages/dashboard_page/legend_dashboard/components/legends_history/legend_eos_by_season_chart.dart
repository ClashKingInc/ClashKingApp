import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';
import 'package:clashkingapp/classes/profile/legend/spot_data.dart';
import 'package:clashkingapp/classes/profile/legend/legend_season.dart';
import 'package:flutter/material.dart';

class LegendEosBySeasonChart extends StatelessWidget {
  final List<LegendSeason> legendSeasons;

  LegendEosBySeasonChart({required this.legendSeasons});

  @override
  Widget build(BuildContext context) {
    if (legendSeasons.isEmpty) {
      return SizedBox.shrink();
    } else {
      try {
        ChartData chartData = ChartData.fromLegendSeasons(legendSeasons);
        Locale locale = Localizations.localeOf(context);
        DateFormat dateFormat = DateFormat.yMMMM(locale.toString());

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
              padding: const EdgeInsets.only(
                  left: 10.0, right: 20.0, top: 10.0, bottom: 10.0),
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
                              interval: chartData.rangeX,
                              reservedSize: 40,
                              getTitlesWidget: (value, meta) {
                                DateTime date =
                                    DateTime.fromMillisecondsSinceEpoch(
                                        value.toInt());
                                return Padding(
                                  padding: const EdgeInsets.only(top: 10.0),
                                  child: Text(
                                    DateFormat('MM/yy').format(date),
                                    style:
                                        Theme.of(context).textTheme.labelMedium,
                                  ),
                                );
                              },
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 40,
                              interval: chartData.rangeY,
                              getTitlesWidget: (double value, TitleMeta meta) {
                                return Text(
                                    NumberFormat(
                                            '#,###',
                                            Localizations.localeOf(context)
                                                .toString())
                                        .format(value.toInt()),
                                    style:
                                        Theme.of(context).textTheme.bodySmall);
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
                              color: Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withOpacity(0.2),
                            ),
                          ),
                        ],
                        minX: chartData.minX,
                        maxX: chartData.maxX,
                        minY: chartData.minY,
                        maxY: chartData.maxY,
                        lineTouchData: LineTouchData(
                          touchTooltipData: LineTouchTooltipData(
                            getTooltipColor: (LineBarSpot touchedSpot) =>
                                Theme.of(context).colorScheme.primary,
                            getTooltipItems: (List<LineBarSpot> touchedSpots) {
                              return touchedSpots.map((touchedSpot) {
                                DateTime date =
                                    DateTime.fromMillisecondsSinceEpoch(
                                        touchedSpot.x.toInt());

                                return LineTooltipItem(
                                  '${dateFormat.format(date)} : ${touchedSpot.y.toInt()}',
                                  TextStyle(color: Colors.white),
                                );
                              }).toList();
                            },
                          ),
                          touchCallback: (FlTouchEvent touchEvent,
                              LineTouchResponse? touchResponse) {},
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
      } catch (exception) {
        return SizedBox.shrink();
      }
    }
  }
}
