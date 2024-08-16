import 'package:clashkingapp/classes/profile/legend/legend_day.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:clashkingapp/classes/profile/legend/legend_data.dart';
import 'package:clashkingapp/classes/profile/profile_info.dart';
import 'package:intl/intl.dart';
import 'package:clashkingapp/main_pages/dashboard_page/legend_dashboard/components/legends_by_day/legend_offense_defense_card.dart';
import 'package:clashkingapp/main_pages/dashboard_page/legend_dashboard/components/legends_by_day/legend_trophies_start_end_card.dart';
import 'package:clashkingapp/main_pages/dashboard_page/legend_dashboard/components/legends_by_day/legend_used_gear_card.dart';



class LegendByDayTab extends StatefulWidget {
  final PlayerLegendData playerLegendData;
  final ProfileInfo playerStats;

  const LegendByDayTab({
    Key? key,
    required this.playerLegendData,
    required this.playerStats,
  }) : super(key: key);

  @override
  _LegendByDayTabState createState() => _LegendByDayTabState();
}

class _LegendByDayTabState extends State<LegendByDayTab> {
  DateTime selectedDate = DateTime.now();

  void incrementDate() {
    setState(() {
      selectedDate = selectedDate.add(Duration(days: 1));
    });
  }

  void decrementDate() {
    setState(() {
      selectedDate = selectedDate.subtract(Duration(days: 1));
    });
  }

  @override
  Widget build(BuildContext context) {
    String date = DateFormat('yyyy-MM-dd').format(selectedDate);
    LegendDay? legendDay = widget.playerLegendData.legendData[date];
    return Column(
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            SizedBox(width: 16),
            IconButton(
              icon: Icon(Icons.calendar_today,
                  color: Theme.of(context).colorScheme.onSurface, size: 16),
              onPressed: () async {
                DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: selectedDate,
                  firstDate: DateTime(2018, 8),
                  lastDate: DateTime(2200),
                );
                if (picked != null && picked != selectedDate) {
                  setState(() {
                    selectedDate = picked;
                  });
                }
              },
            ),
            Spacer(),
            SizedBox(
              width: 30,
              height: 30,
              child: IconButton(
                icon: Icon(Icons.arrow_back,
                    color: Theme.of(context).colorScheme.onSurface, size: 16),
                onPressed: decrementDate,
              ),
            ),
            Text(
              DateFormat('dd MMMM yyyy',
                      Localizations.localeOf(context).languageCode)
                  .format(selectedDate),
              style: Theme.of(context).textTheme.labelLarge,
            ),
            SizedBox(
              width: 30,
              height: 30,
              child: IconButton(
                icon: Icon(Icons.arrow_forward,
                    color: Theme.of(context).colorScheme.onSurface, size: 16),
                onPressed: incrementDate,
              ),
            ),
            SizedBox(width: 16)
          ],
        ),
        if (legendDay != null && (
            legendDay.attacksList.isNotEmpty ||
            legendDay.defensesList.isNotEmpty))
          Padding(
            padding: const EdgeInsets.only(bottom: 8, left: 8, right: 8),
            child: Column(
              children: [
                LegendTrophiesStartEndCard(
                    context: context,
                    startTrophies: legendDay.startTrophies.toString(),
                    currentTrophies: legendDay.currentTrophies),
                Container(
                  margin: EdgeInsets.only(top: 0, bottom: 0, left: 5, right: 5),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: LegendOffenseDefenseCard(
                            title: AppLocalizations.of(context)?.attacks ??
                                "Attacks",
                            list: legendDay.attacksList,
                            context: context,
                            stats: legendDay.attacksStats,
                            plusMinus: "+",
                            icon:
                                "https://assets.clashk.ing/icons/Icon_HV_Sword.png"),
                      ),
                      Expanded(
                        child: LegendOffenseDefenseCard(
                            title: AppLocalizations.of(context)?.defenses ??
                                "Defenses",
                            list: legendDay.defensesList,
                            context: context,
                            stats: legendDay.defensesStats,
                            plusMinus: "-",
                            icon:
                                "https://assets.clashk.ing/icons/Icon_HV_Shield_Arrow.png"),
                      ),
                    ],
                  ),
                ),
                if (legendDay.attacksList.isNotEmpty)
                  LegendUsedGearCard(
                      context: context,
                      gearCounts: legendDay.gearCount,
                      heroes: widget.playerStats.heroes,
                      gears: widget.playerStats.equipments),
              ],
            ),
          )
        else
          Column(
            children: [
              Card(
                  margin: EdgeInsets.only(bottom: 8, left: 16, right: 16),
                  child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                          AppLocalizations.of(context)?.noDataAvailable ??
                              'No data available'))),
              SizedBox(height: 10),
              CachedNetworkImage(
                imageUrl:
                    'https://assets.clashk.ing/stickers/Villager_HV_Villager_7.png',
                height: 350,
                width: 200,
              )
            ],
          ),
      ],
    );
  }
}
