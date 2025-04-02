import 'package:cached_network_image/cached_network_image.dart';
import 'package:clashkingapp/core/constants/image_assets.dart';
import 'package:clashkingapp/features/player/models/player.dart';
import 'package:clashkingapp/features/player/models/player_legend_day.dart';
import 'package:clashkingapp/features/player/models/player_legend_season.dart';
import 'package:clashkingapp/features/player/presentation/legend/widgets/player_legend_season_offense_defense.dart';
import 'package:clashkingapp/features/player/presentation/legend/widgets/player_legend_season_used_gear.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:intl/intl.dart';

class PlayerLegendSeasonList extends StatefulWidget {
  final PlayerLegendSeason? season;
  final Player player;

  const PlayerLegendSeasonList({
    super.key,
    required this.season,
    required this.player,
  });

  @override
  State<PlayerLegendSeasonList> createState() => _PlayerLegendSeasonListState();
}

class _PlayerLegendSeasonListState extends State<PlayerLegendSeasonList> {
  String _sortCriterion = 'date';
  bool _isAscending = true;
  String? _selectedDay;

  void _toggleSort(String criterion) {
    setState(() {
      if (_sortCriterion == criterion) {
        _isAscending = !_isAscending;
      } else {
        _sortCriterion = criterion;
        _isAscending = true;
      }
    });
  }

  List<MapEntry<String, PlayerLegendDay>> getSortedDays() {
    final days = widget.season!.days.entries.toList();
    days.sort((a, b) {
      int compare;
      switch (_sortCriterion) {
        case 'attacks':
          compare = a.value.trophiesGainedTotal
              .compareTo(b.value.trophiesGainedTotal);
          break;
        case 'defenses':
          compare =
              a.value.trophiesLostTotal.compareTo(b.value.trophiesLostTotal);
          break;
        case 'trophies':
          compare =
              (a.value.endTrophies ?? 0).compareTo(b.value.endTrophies ?? 0);
          break;
        case 'date':
        default:
          compare = a.key.compareTo(b.key);
      }
      return _isAscending ? compare : -compare;
    });
    return days;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.season == null) return const SizedBox();
    final locale = Localizations.localeOf(context).toString();
    final displayDateFormat = DateFormat.MMMd(locale);
    final days = getSortedDays();

    if (days.isEmpty) return const SizedBox();

    return SizedBox(
      width: double.infinity,
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildSortHeader('date', Icons.calendar_today),
                  _buildSortHeader('attacks', ImageAssets.sword),
                  _buildSortHeader('defenses', ImageAssets.shieldWithArrow),
                  _buildSortHeader(
                      'trophies', ImageAssets.legendBlazonBordersNoPadding),
                ],
              ),
              const Divider(),
              for (final entry in days)
                _buildDayRow(context, entry, displayDateFormat),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSortHeader(String criterion, dynamic icon) {
    return InkWell(
      onTap: () => _toggleSort(criterion),
      child: Row(
        children: [
          if (icon is IconData)
            Icon(icon)
          else if (icon is String)
            CachedNetworkImage(imageUrl: icon, height: 20),
          const SizedBox(width: 4),
          Icon(
            _sortCriterion == criterion
                ? (_isAscending ? Icons.expand_less : Icons.expand_more)
                : Icons.unfold_more,
            size: 16,
          )
        ],
      ),
    );
  }

  Widget _buildDayRow(BuildContext context,
      MapEntry<String, PlayerLegendDay> entry, DateFormat formatter) {
    final day = entry.value;
    final dayKey = entry.key;
    final isSelected = _selectedDay == dayKey;

    return Column(
      children: [
        InkWell(
          onTap: () =>
              setState(() => _selectedDay = isSelected ? null : dayKey),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Row(
                  children: [
                    Text(formatter.format(DateTime.parse(dayKey))),
                    Icon(isSelected ? Icons.expand_less : Icons.expand_more,
                        size: 16),
                  ],
                ),
                RichText(
                  text: TextSpan(
                    style: Theme.of(context).textTheme.bodyMedium,
                    children: [
                      TextSpan(text: "+${day.trophiesGainedTotal}"),
                      WidgetSpan(
                        child: Transform.translate(
                          offset: const Offset(2, -6),
                          child: Text("(${day.totalAttacks})",
                              textScaler: TextScaler.linear(0.7),
                              style: Theme.of(context).textTheme.labelSmall),
                        ),
                      ),
                    ],
                  ),
                ),
                RichText(
                  text: TextSpan(
                    style: Theme.of(context).textTheme.bodyMedium,
                    children: [
                      TextSpan(text: "-${day.trophiesLostTotal}"),
                      WidgetSpan(
                        child: Transform.translate(
                          offset: const Offset(2, -6),
                          child: Text("(${day.totalDefenses})",
                              textScaler: TextScaler.linear(0.7),
                              style: Theme.of(context).textTheme.labelSmall),
                        ),
                      ),
                    ],
                  ),
                ),
                RichText(
                  text: TextSpan(
                    style: Theme.of(context).textTheme.bodyMedium,
                    children: [
                      TextSpan(
                          text: NumberFormat('#,###',
                                  Localizations.localeOf(context).toString())
                              .format(day.endTrophies ?? 0)),
                      WidgetSpan(
                        child: Transform.translate(
                          offset: const Offset(2, -6),
                          child: Text(
                            day.trophiesTotal > 0
                                ? "(+${day.trophiesTotal})"
                                : "(${day.trophiesTotal})",
                            textScaler: TextScaler.linear(0.7),
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color: day.trophiesTotal > 0
                                      ? Colors.green
                                      : (day.trophiesTotal < 0
                                          ? Colors.red
                                          : null),
                                ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        AnimatedCrossFade(
          crossFadeState:
              isSelected ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 300),
          firstChild: Divider(height: 1, indent: 16, endIndent: 16),
          secondChild: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: PlayerLegendOffenseDefense(
                        title:
                            AppLocalizations.of(context)?.attacks ?? "Attacks",
                        list: day.newAttacks,
                        context: context,
                        sum: day.trophiesGainedTotal,
                        average: day.totalAttacks > 0
                            ? day.trophiesGainedTotal / day.totalAttacks
                            : 0,
                        plusMinus: "+",
                        icon: ImageAssets.sword,
                      ),
                    ),
                    Expanded(
                      child: PlayerLegendOffenseDefense(
                        title: AppLocalizations.of(context)?.defenses ??
                            "Defenses",
                        list: day.newDefenses,
                        context: context,
                        sum: day.trophiesLostTotal,
                        average: day.totalDefenses > 0
                            ? day.trophiesLostTotal / day.totalDefenses
                            : 0,
                        plusMinus: "-",
                        icon: ImageAssets.shieldWithArrow,
                      ),
                    ),
                  ],
                ),
                if (day.usageCount.isNotEmpty) ...[
                  SizedBox(height: 12),
                  Divider(height: 1, indent: 32, endIndent: 32),
                  SizedBox(height: 12),
                  PlayerLegendSeasonUsedGear(
                      context: context,
                      gears: day
                          .gearCountsFlatFromProfile(widget.player.equipments)
                          .values
                          .toList(),
                      usageCount: day.usageCount),
                ],
                SizedBox(height: 16),
                Divider(height: 1, indent: 16, endIndent: 16),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
