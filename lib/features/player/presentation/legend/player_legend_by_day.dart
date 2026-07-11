import 'package:clashkingapp/core/constants/image_assets.dart';
import 'package:clashkingapp/features/player/models/player.dart';
import 'package:clashkingapp/features/player/presentation/legend/widgets/player_legend_day_trophies_start_end_card.dart';
import 'package:clashkingapp/features/player/presentation/legend/widgets/player_legend_day_offense_defense_card.dart';
import 'package:clashkingapp/features/player/presentation/legend/widgets/player_legend_day_used_gear_card.dart';
import 'package:clashkingapp/common/widgets/empty_state.dart';
import 'package:flutter/material.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

class LegendByDayTab extends StatefulWidget {
  final Player player;

  const LegendByDayTab({super.key, required this.player});

  @override
  State<LegendByDayTab> createState() => _LegendByDayTabState();
}

class _LegendByDayTabState extends State<LegendByDayTab> {
  DateTime selectedDate = DateTime.now().toUtc().subtract(
    const Duration(hours: 5),
  );

  void incrementDate() =>
      setState(() => selectedDate = selectedDate.add(const Duration(days: 1)));
  void decrementDate() => setState(
    () => selectedDate = selectedDate.subtract(const Duration(days: 1)),
  );

  @override
  Widget build(BuildContext context) {
    final dateKey = DateFormat('yyyy-MM-dd').format(selectedDate);
    final legendDay = widget.player.legendsBySeason
        ?.getSpecificSeason(DateTime.parse(dateKey))
        ?.days[dateKey];

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            const SizedBox(width: 16),
            IconButton(
              tooltip: MaterialLocalizations.of(context).datePickerHelpText,
              icon: Icon(
                Icons.calendar_today,
                color: Theme.of(context).colorScheme.onSurface,
                size: 24,
              ),
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: selectedDate,
                  firstDate: DateTime(2018, 8),
                  lastDate: DateTime(2200),
                );
                if (picked != null && picked != selectedDate) {
                  setState(() => selectedDate = picked);
                }
              },
            ),
            const Spacer(),
            SizedBox(
              width: 30,
              height: 30,
              child: IconButton(
                tooltip: MaterialLocalizations.of(context).previousMonthTooltip,
                icon: Icon(
                  Icons.arrow_back,
                  color: Theme.of(context).colorScheme.onSurface,
                  size: 16,
                ),
                onPressed: decrementDate,
              ),
            ),
            Text(
              DateFormat(
                'dd MMMM yyyy',
                Localizations.localeOf(context).languageCode,
              ).format(selectedDate),
              style: Theme.of(context).textTheme.labelLarge,
            ),
            SizedBox(
              width: 30,
              height: 30,
              child: IconButton(
                tooltip: MaterialLocalizations.of(context).nextMonthTooltip,
                icon: Icon(
                  Icons.arrow_forward,
                  color: Theme.of(context).colorScheme.onSurface,
                  size: 16,
                ),
                onPressed: incrementDate,
              ),
            ),
            const SizedBox(width: 16),
          ],
        ),
        if (legendDay != null &&
            (legendDay.attacks.isNotEmpty || legendDay.defenses.isNotEmpty))
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Column(
              children: [
                LegendTrophiesStartEndCard(
                  context: context,
                  startTrophies: legendDay.startTrophies.toString(),
                  currentTrophies: legendDay.endTrophies.toString(),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: LegendOffenseDefenseCard(
                        title:
                            AppLocalizations.of(context)?.warAttacksTitle ??
                            "Attacks",
                        list: legendDay.attacks,
                        context: context,
                        totalCount: legendDay.totalAttacks,
                        totalTrophies: legendDay.trophiesGainedTotal,
                        plusMinus: "+",
                        icon: ImageAssets.sword,
                      ),
                    ),
                    Expanded(
                      child: LegendOffenseDefenseCard(
                        title:
                            AppLocalizations.of(context)?.warDefensesTitle ??
                            "Defenses",
                        list: legendDay.defenses,
                        context: context,
                        totalCount: legendDay.totalDefenses,
                        totalTrophies: legendDay.trophiesLostTotal,
                        plusMinus: "-",
                        icon: ImageAssets.shieldWithArrow,
                      ),
                    ),
                  ],
                ),
                if (legendDay.attacks.isNotEmpty)
                  LegendUsedGearCard(
                    context: context,
                    gears: legendDay
                        .gearCountsFlatFromProfile(widget.player.equipments)
                        .values
                        .toList(),
                    usageCount: legendDay.usageCount,
                  ),
              ],
            ),
          )
        else
          AppEmptyState(
            title: AppLocalizations.of(context)!.generalNoDataAvailable,
            icon: Icons.history_toggle_off_rounded,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            stickerHeight: 350,
            stickerWidth: 200,
          ),
      ],
    );
  }
}
