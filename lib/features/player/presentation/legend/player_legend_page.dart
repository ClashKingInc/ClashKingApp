import 'package:clashkingapp/features/player/models/player.dart';
import 'package:clashkingapp/features/player/presentation/legend/player_legend_by_day.dart';
import 'package:clashkingapp/features/player/presentation/legend/player_legend_history.dart';
import 'package:clashkingapp/features/player/presentation/legend/player_legend_season.dart';
import 'package:clashkingapp/features/player/presentation/legend/player_legend_header.dart';
import 'package:clashkingapp/features/player/presentation/legend/widgets/player_legend_history_eos_chart.dart';
import 'package:clashkingapp/features/player/presentation/legend/widgets/player_legend_history_eos_list.dart';
import 'package:clashkingapp/features/player/presentation/legend/widgets/player_legend_season_chart.dart';
import 'package:clashkingapp/features/player/presentation/legend/widgets/player_legend_season_list.dart';
import 'package:clashkingapp/common/widgets/empty_state.dart';
import 'package:clashkingapp/common/widgets/info_profile_tabs.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';
import 'package:clashkingapp/core/functions/legend_functions.dart';

class PlayerLegendScreen extends StatefulWidget {
  final Player player;
  const PlayerLegendScreen({super.key, required this.player});

  @override
  State<PlayerLegendScreen> createState() => _PlayerLegendScreenState();
}

class _PlayerLegendScreenState extends State<PlayerLegendScreen> {
  int selectedTab = 0;
  DateTime selectedDate = DateTime.now().toUtc().subtract(
    const Duration(hours: 5),
  );
  DateTime selectedMonth = DateTime.now().toUtc().subtract(
    const Duration(hours: 5),
  );
  bool showBySeasonTable = false;
  bool showHistoryTable = false;

  @override
  void initState() {
    super.initState();
    selectedMonth = findCurrentSeasonMonth(selectedMonth);
  }

  void incrementDate() =>
      setState(() => selectedDate = selectedDate.add(const Duration(days: 1)));
  void decrementDate() => setState(
    () => selectedDate = selectedDate.subtract(const Duration(days: 1)),
  );

  void incrementMonth() => setState(
    () => selectedMonth = selectedMonth.month == 12
        ? DateTime(selectedMonth.year + 1, 1, 1)
        : DateTime(selectedMonth.year, selectedMonth.month + 1, 1),
  );

  void decrementMonth() => setState(
    () => selectedMonth = selectedMonth.month == 1
        ? DateTime(selectedMonth.year - 1, 12, 1)
        : DateTime(selectedMonth.year, selectedMonth.month - 1, 1),
  );

  void toggleBySeasonView() =>
      setState(() => showBySeasonTable = !showBySeasonTable);
  void toggleHistoryView() =>
      setState(() => showHistoryTable = !showHistoryTable);

  @override
  Widget build(BuildContext context) {
    final legends = widget.player.legendsBySeason;
    if (legends == null) {
      return AppEmptyState(
        title: AppLocalizations.of(context)!.generalNoDataAvailable,
        icon: Icons.history_toggle_off_rounded,
        padding: const EdgeInsets.fromLTRB(16, 48, 16, 0),
        stickerHeight: 200,
        stickerWidth: 160,
      );
    }

    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      body: RefreshIndicator(
        backgroundColor: Theme.of(context).colorScheme.surface,
        onRefresh: () => Future.value(),
        child: InfoProfileTabScaffold(
          header: LegendHeaderCard(player: widget.player),
          selectedIndex: selectedTab,
          onTabSelected: (index) => setState(() => selectedTab = index),
          tabs: [
            InfoProfileTabData(
              label: loc.statsByDay,
              icon: Icons.today_rounded,
            ),
            InfoProfileTabData(
              label: loc.statsBySeason,
              icon: Icons.calendar_month_rounded,
            ),
            InfoProfileTabData(
              label: loc.generalHistory,
              icon: Icons.history_rounded,
            ),
          ],
          pages: [
            SingleChildScrollView(
              padding: EdgeInsets.only(
                bottom: 16 + MediaQuery.paddingOf(context).bottom,
              ),
              child: LegendByDayTab(player: widget.player),
            ),
            SingleChildScrollView(
              padding: EdgeInsets.only(
                bottom: 16 + MediaQuery.paddingOf(context).bottom,
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const SizedBox(width: 16),
                          IconButton(
                            tooltip: showBySeasonTable
                                ? AppLocalizations.of(context)!.tooltipShowChart
                                : AppLocalizations.of(
                                    context,
                                  )!.tooltipShowTable,
                            icon: Icon(
                              showBySeasonTable
                                  ? Icons.bar_chart
                                  : Icons.table_chart,
                              color: Theme.of(context).colorScheme.onSurface,
                              size: 24,
                            ),
                            onPressed: toggleBySeasonView,
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          SizedBox(
                            width: 30,
                            height: 30,
                            child: IconButton(
                              tooltip: MaterialLocalizations.of(
                                context,
                              ).previousMonthTooltip,
                              icon: Icon(
                                Icons.arrow_back,
                                color: Theme.of(context).colorScheme.onSurface,
                                size: 16,
                              ),
                              onPressed: decrementMonth,
                            ),
                          ),
                          Text(
                            DateFormat(
                              'MMMM yyyy',
                              Localizations.localeOf(context).languageCode,
                            ).format(selectedMonth),
                            style: Theme.of(context).textTheme.labelLarge,
                          ),
                          SizedBox(
                            width: 30,
                            height: 30,
                            child: IconButton(
                              tooltip: MaterialLocalizations.of(
                                context,
                              ).nextMonthTooltip,
                              icon: Icon(
                                Icons.arrow_forward,
                                color: Theme.of(context).colorScheme.onSurface,
                                size: 16,
                              ),
                              onPressed: incrementMonth,
                            ),
                          ),
                          const SizedBox(width: 16),
                        ],
                      ),
                    ],
                  ),
                  LegendSeason(
                    player: widget.player,
                    season: legends.getSpecificSeason(selectedMonth),
                  ),
                  showBySeasonTable
                      ? PlayerLegendSeasonList(
                          player: widget.player,
                          season: legends.getSpecificSeason(selectedMonth),
                        )
                      : LegendSeasonChart(
                          season: legends.getSpecificSeason(selectedMonth),
                        ),
                ],
              ),
            ),
            SingleChildScrollView(
              padding: EdgeInsets.only(
                bottom: 16 + MediaQuery.paddingOf(context).bottom,
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const SizedBox(width: 16),
                      IconButton(
                        tooltip: showHistoryTable
                            ? AppLocalizations.of(context)!.tooltipShowChart
                            : AppLocalizations.of(context)!.tooltipShowTable,
                        icon: Icon(
                          showHistoryTable
                              ? Icons.bar_chart
                              : Icons.table_chart,
                          color: Theme.of(context).colorScheme.onSurface,
                          size: 24,
                        ),
                        onPressed: toggleHistoryView,
                      ),
                    ],
                  ),
                  PlayerLegendHistory(player: widget.player),
                  showHistoryTable
                      ? PlayerLegendHistoryEosList(
                          rankings: widget.player.legendRanking,
                        )
                      : PlayerLegendHistoryEosChart(
                          rankings: widget.player.legendRanking,
                        ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
