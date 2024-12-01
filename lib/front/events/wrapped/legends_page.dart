import 'package:clashkingapp/classes/events/wrapped/clash_wrapped.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class LegendsPage extends StatelessWidget {
  final PlayerInfo data;

  LegendsPage({required this.data});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            "Vos performances en Légendes",
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          SizedBox(height: 20),
          Text(
            "Trophées : ${data.player['trophies']}",
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          SizedBox(height: 20),
          Container(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                barGroups: [
                  BarChartGroupData(
                    x: 0,
                    barRods: [
                      BarChartRodData(
                        toY: data.player['hits_done'].toDouble(),
                        color: Colors.orange,
                      )
                    ],
                  ),
                  BarChartGroupData(
                    x: 1,
                    barRods: [
                      BarChartRodData(
                        toY: data.player['avg_offense'].toDouble(),
                        color: Colors.blue,
                      )
                    ],
                  ),
                  BarChartGroupData(
                    x: 2,
                    barRods: [
                      BarChartRodData(
                        toY: data.player['avg_defense'].toDouble(),
                        color: Colors.red,
                      )
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
