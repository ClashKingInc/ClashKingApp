import 'package:clashkingapp/classes/profile/legend/spot_data.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:clashkingapp/classes/profile/legend/legend_data.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:cached_network_image/cached_network_image.dart';

class LegendMonthlyChart extends StatefulWidget {
  final PlayerLegendData playerLegendData;

  LegendMonthlyChart({required this.playerLegendData});

  @override
  _LegendMonthlyChartState createState() => _LegendMonthlyChartState();
}

class _LegendMonthlyChartState extends State<LegendMonthlyChart> {
  DateTime selectedMonth = DateTime.now();

  void incrementMonth() {
    setState(() {
      selectedMonth = DateTime(selectedMonth.year, selectedMonth.month + 1, 1);
    });
  }

  void decrementMonth() {
    setState(() {
      selectedMonth = DateTime(selectedMonth.year, selectedMonth.month - 1, 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    List<Object> seasonObject =
        widget.playerLegendData.getTrophiesBySeason(selectedMonth);

    if (seasonObject[1] is ChartData) {
      ChartData chartData = seasonObject[1] as ChartData;
      DateTime seasonStart = seasonObject[0] as DateTime;

      return SizedBox(
        width: double.infinity,
        height: 500,
        child: Card(
          margin: EdgeInsets.only(top: 8, bottom: 8, left: 16, right: 16),
          elevation: 4,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.only(
                left: 10.0, right: 20.0, top: 10.0, bottom: 10.0),
            child: Column(children: [
              Text(
                  AppLocalizations.of(context)?.trophiesByMonth ??
                      "Trophies by Month",
                  style: Theme.of(context).textTheme.bodyMedium),
              SizedBox(height: 16),
              Expanded(
                child: LineChart(
                  LineChartData(
                    gridData: FlGridData(
                      show: true,
                      drawHorizontalLine: true,
                      horizontalInterval: 20,
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 30,
                          interval: 3,
                          getTitlesWidget: (double value, TitleMeta meta) {
                            DateTime labelDate =
                                seasonStart.add(Duration(days: value.toInt()));
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(DateFormat('dd').format(labelDate),
                                  style: TextStyle(fontSize: 10)),
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
                          width: 1),
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
                        getTooltipColor: (spot) => Theme.of(context)
                            .colorScheme
                            .primary
                            .withOpacity(0.8),
                      ),
                      touchCallback: (FlTouchEvent touchEvent,
                          LineTouchResponse? touchResponse) {},
                      handleBuiltInTouches: true,
                    ),
                  ),
                  duration: Duration(milliseconds: 250),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 30,
                    height: 30,
                    child: IconButton(
                      icon: Icon(Icons.arrow_back,
                          color: Theme.of(context).colorScheme.onSurface,
                          size: 16),
                      onPressed: decrementMonth,
                    ),
                  ),
                  Text(
                      DateFormat('MMMM yyyy',
                              Localizations.localeOf(context).languageCode)
                          .format(selectedMonth),
                      style: Theme.of(context).textTheme.labelLarge),
                  SizedBox(
                    width: 30,
                    height: 30,
                    child: IconButton(
                      icon: Icon(Icons.arrow_forward,
                          color: Theme.of(context).colorScheme.onSurface,
                          size: 16),
                      onPressed: incrementMonth,
                    ),
                  ),
                ],
              ),
            ]),
          ),
        ),
      );
    } else {
      return SizedBox(
        width: double.infinity,
        height: 500,
        child: Card(
          margin: EdgeInsets.only(top: 8, bottom: 8, left: 16, right: 16),
          elevation: 4,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.only(
                left: 10.0, right: 10.0, top: 20.0, bottom: 10.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                    AppLocalizations.of(context)?.noDataAvailable ??
                        'No data available',
                    style: Theme.of(context).textTheme.bodyMedium),
                CachedNetworkImage(
                  imageUrl:
                      'https://clashkingfiles.b-cdn.net/stickers/Villager_HV_Villager_12.png',
                  height: 300,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 30,
                      height: 30,
                      child: IconButton(
                        icon: Icon(Icons.arrow_back,
                            color: Theme.of(context).colorScheme.onSurface,
                            size: 16),
                        onPressed: decrementMonth,
                      ),
                    ),
                    Text(DateFormat('MMMM yyyy').format(selectedMonth),
                        style: Theme.of(context).textTheme.labelLarge),
                    SizedBox(
                      width: 30,
                      height: 30,
                      child: IconButton(
                        icon: Icon(Icons.arrow_forward,
                            color: Theme.of(context).colorScheme.onSurface,
                            size: 16),
                        onPressed: incrementMonth,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }
  }
}
