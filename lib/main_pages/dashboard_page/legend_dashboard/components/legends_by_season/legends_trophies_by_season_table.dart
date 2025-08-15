import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';
import 'package:clashkingapp/classes/profile/legend/legend_data.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:clashkingapp/classes/profile/legend/legend_day.dart';
import 'package:clashkingapp/main_pages/dashboard_page/legend_dashboard/components/legends_by_season/legends_offense_defense.dart';
import 'package:clashkingapp/main_pages/dashboard_page/legend_dashboard/components/legends_by_season/legends_used_gear.dart';
import 'package:clashkingapp/classes/profile/profile_info.dart';
import 'package:clashkingapp/classes/profile/legend/legends_season_trophies.dart';

class LegendsTrophiesBySeasonTable extends StatefulWidget {
  final PlayerLegendData playerLegendData;
  final DateTime selectedMonth;
  final SeasonTrophies seasonObject;
  final ProfileInfo playerStats;

  LegendsTrophiesBySeasonTable(
      {required this.playerLegendData,
      required this.selectedMonth,
      required this.seasonObject,
      required this.playerStats});

  @override
  LegendsTrophiesBySeasonTableState createState() =>
      LegendsTrophiesBySeasonTableState();
}

class LegendsTrophiesBySeasonTableState
    extends State<LegendsTrophiesBySeasonTable> {
  String _sortCriterion = 'date';
  bool _isAscending = true;
  LegendDay? _selectedLegendDay;

  void _toggleSort(String criterion) {
    setState(() {
      if (_sortCriterion == criterion) {
        _isAscending = !_isAscending;
      } else {
        _sortCriterion = criterion;
        _isAscending = true;
      }
      _sortData();
    });
  }

  void _sortData() {
    widget.seasonObject.seasonLegendDays.sort((a, b) {
      int compare;
      switch (_sortCriterion) {
        case 'date':
          compare = a.date.compareTo(b.date);
          break;
        case 'attacks':
          compare = a.attacksStats.sum.compareTo(b.attacksStats.sum);
          break;
        case 'defenses':
          compare = a.defensesStats.sum.compareTo(b.defensesStats.sum);
          break;
        case 'trophies':
          compare = a.currentTrophies.compareTo(b.currentTrophies);
          break;
        default:
          compare = 0;
      }
      return _isAscending ? compare : -compare;
    });
  }

  IconData getSortIcon(String criterion) {
    if (_sortCriterion == criterion) {
      return _isAscending ? LucideIcons.chevronDown : LucideIcons.chevronUp;
    } else {
      return LucideIcons.chevronsUpDown;
    }
  }

  Color getSortIconColor(String criterion) {
    return _sortCriterion == criterion
        ? Colors.blue
        : Theme.of(context).colorScheme.onSurface;
  }

  @override
  void initState() {
    super.initState();
    _sortData();
  }

  @override
  Widget build(BuildContext context) {
    Locale locale = Localizations.localeOf(context);
    DateFormat displayDateFormat = DateFormat.MMMd(locale.toString());

    if (widget.seasonObject.seasonLegendDays.isNotEmpty) {
      return SizedBox(
        width: double.infinity,
        child: Card(
          margin: EdgeInsets.only(top: 4, bottom: 4, left: 16, right: 16),
          elevation: 4,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildSortButton('date', Icons.calendar_today, 'Date'),
                      _buildSortButton(
                          'attacks',
                          "https://assets.clashk.ing/icons/Icon_HV_Sword.png",
                          'Attaques'),
                      _buildSortButton(
                          'defenses',
                          "https://assets.clashk.ing/icons/Icon_HV_Shield_Arrow.png",
                          'Défenses'),
                      _buildSortButton(
                          'trophies',
                          "https://assets.clashk.ing/icons/Icon_HV_League_Legend_3_Border_No_Padding.png",
                          'Trophées'),
                    ],
                  ),
                ),
                for (var legendDay in widget.seasonObject.seasonLegendDays)
                  Column(
                    children: [
                      Divider(thickness: 1),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedLegendDay = _selectedLegendDay == legendDay
                                ? null
                                : legendDay;
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Center(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        displayDateFormat.format(DateTime.parse(
                                            '${legendDay.date}')),
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium,
                                      ),
                                      if (_selectedLegendDay == legendDay)
                                        Icon(Icons.expand_less, size: 16),
                                      if (_selectedLegendDay != legendDay)
                                        Icon(Icons.expand_more, size: 16),
                                    ],
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Center(
                                  child: Text.rich(
                                    TextSpan(
                                      children: [
                                        TextSpan(
                                          text:
                                              "+${legendDay.attacksStats.sum.toString()} ",
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium,
                                        ),
                                        WidgetSpan(
                                          child: Transform.translate(
                                            offset: const Offset(0, -6),
                                            child: Text(
                                              "(${legendDay.attacksStats.count.toString()})",
                                              textScaleFactor: 0.7,
                                              style: (legendDay
                                                          .attacksStats.count ==
                                                      8)
                                                  ? Theme.of(context)
                                                      .textTheme
                                                      .bodyMedium
                                                      ?.copyWith(
                                                          color: Colors.blue)
                                                  : Theme.of(context)
                                                      .textTheme
                                                      .bodyMedium,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Center(
                                  child: Text.rich(
                                    TextSpan(
                                      children: [
                                        TextSpan(
                                          text:
                                              "-${legendDay.defensesStats.sum.toString()} ",
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium,
                                        ),
                                        WidgetSpan(
                                          child: Transform.translate(
                                            offset: const Offset(0, -6),
                                            child: Text(
                                              "(${legendDay.defensesStats.count.toString()})",
                                              textScaleFactor: 0.7,
                                              style: (legendDay.defensesStats
                                                          .count ==
                                                      8)
                                                  ? Theme.of(context)
                                                      .textTheme
                                                      .bodyMedium
                                                      ?.copyWith(
                                                          color: Colors.blue)
                                                  : Theme.of(context)
                                                      .textTheme
                                                      .bodyMedium,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Center(
                                  child: Text.rich(
                                    TextSpan(
                                      children: [
                                        TextSpan(
                                            text: NumberFormat(
                                                    '#,###',
                                                    Localizations.localeOf(
                                                            context)
                                                        .toString())
                                                .format(int.parse(
                                                    legendDay.currentTrophies)),
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyMedium),
                                        WidgetSpan(
                                          child: Transform.translate(
                                            offset: const Offset(0, -6),
                                            child: Text(
                                                legendDay.diffTrophies > 0
                                                    ? "(+${legendDay.diffTrophies.toString()})"
                                                    : legendDay.diffTrophies < 0
                                                        ? "(${legendDay.diffTrophies})"
                                                            .toString()
                                                        : "",
                                                textScaleFactor: 0.7,
                                                style: (legendDay.diffTrophies <
                                                        0)
                                                    ? Theme.of(context)
                                                        .textTheme
                                                        .bodyMedium
                                                        ?.copyWith(
                                                            color: Colors.red)
                                                    : Theme.of(context)
                                                        .textTheme
                                                        .bodyMedium
                                                        ?.copyWith(
                                                            color:
                                                                Colors.green)),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      AnimatedCrossFade(
                        firstChild: Container(),
                        secondChild: _buildLegendDayDetails(
                            legendDay, displayDateFormat),
                        crossFadeState: _selectedLegendDay == legendDay
                            ? CrossFadeState.showSecond
                            : CrossFadeState.showFirst,
                        duration: Duration(milliseconds: 300),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      );
    } else {
      return SizedBox.shrink();
    }
  }

  Widget _buildSortButton(String criterion, dynamic icon, String label) {
    return Expanded(
      child: InkWell(
        onTap: () => _toggleSort(criterion),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon is IconData)
              Icon(icon)
            else if (icon is String)
              CachedNetworkImage(imageUrl: icon, height: 24),
            SizedBox(width: 4),
            Icon(getSortIcon(criterion),
                size: 16, color: getSortIconColor(criterion)),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendDayDetails(
      LegendDay legendDay, DateFormat displayDateFormat) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            Column(
              children: [
                Text(AppLocalizations.of(context)?.started ?? "Started",
                    style: Theme.of(context).textTheme.bodySmall),
                Text(
                    NumberFormat(
                            '#,###', Localizations.localeOf(context).toString())
                        .format(legendDay.startTrophies),
                    style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
            CachedNetworkImage(
              imageUrl:
                  "https://assets.clashk.ing/icons/Icon_HV_League_Legend_3_Border.png",
              width: 40,
            ),
            Column(children: [
              Text(AppLocalizations.of(context)?.ended ?? "Ended",
                  style: Theme.of(context).textTheme.bodySmall),
              Text(
                  NumberFormat(
                          '#,###', Localizations.localeOf(context).toString())
                      .format(int.parse(legendDay.currentTrophies)),
                  style: Theme.of(context).textTheme.bodyMedium),
            ]),
          ]),
          SizedBox(height: 12),
          Divider(height: 1, indent: 16, endIndent: 16),
          SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                  child: LegendOffenseDefense(
                      title: AppLocalizations.of(context)?.attacks ?? "Attacks",
                      list: legendDay.attacksList,
                      context: context,
                      stats: legendDay.attacksStats,
                      plusMinus: "+",
                      icon:
                          "https://assets.clashk.ing/icons/Icon_HV_Sword.png")),
              Expanded(
                child: LegendOffenseDefense(
                    title: AppLocalizations.of(context)?.defenses ?? "Defenses",
                    list: legendDay.defensesList,
                    context: context,
                    stats: legendDay.defensesStats,
                    plusMinus: "-",
                    icon:
                        "https://assets.clashk.ing/icons/Icon_HV_Shield_Arrow.png"),
              ),
            ],
          ),
          SizedBox(height: 12),
          Divider(height: 1, indent: 16, endIndent: 16),
          SizedBox(height: 12),
          if (legendDay.attacksList.isNotEmpty)
            LegendUsedGear(
                context: context,
                gearCounts: legendDay.gearCount,
                heroes: widget.playerStats.heroes,
                gears: widget.playerStats.equipments),
        ],
      ),
    );
  }
}
