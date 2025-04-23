import 'package:clashkingapp/features/player/models/player.dart';
import 'package:clashkingapp/features/player/presentation/legend/player_legend_by_day.dart';
import 'package:clashkingapp/features/player/presentation/legend/player_legend_history.dart';
import 'package:clashkingapp/features/player/presentation/legend/player_legend_season.dart';
import 'package:clashkingapp/features/player/presentation/legend/player_legend_header.dart';
import 'package:clashkingapp/features/player/presentation/legend/widgets/player_legend_history_eos_chart.dart';
import 'package:clashkingapp/features/player/presentation/legend/widgets/player_legend_history_eos_list.dart';
import 'package:clashkingapp/features/player/presentation/legend/widgets/player_legend_season_chart.dart';
import 'package:clashkingapp/features/player/presentation/legend/widgets/player_legend_season_list.dart';
import 'package:flutter/material.dart';
import 'package:scrollable_tab_view/scrollable_tab_view.dart';
import 'package:intl/intl.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';
import 'package:clashkingapp/core/functions/legend_functions.dart';

class PlayerLegendScreen extends StatefulWidget {
  final Player player;
  const PlayerLegendScreen({super.key, required this.player});

  @override
  State<PlayerLegendScreen> createState() => _PlayerLegendScreenState();
}

class _PlayerLegendScreenState extends State<PlayerLegendScreen>
    with SingleTickerProviderStateMixin {
  late TabController tabController;
  DateTime selectedDate =
      DateTime.now().toUtc().subtract(const Duration(hours: 5));
  DateTime selectedMonth =
      DateTime.now().toUtc().subtract(const Duration(hours: 5));
  bool showBySeasonTable = false;
  bool showHistoryTable = false;

  @override
  void initState() {
    super.initState();
    tabController = TabController(length: 3, vsync: this);
    selectedMonth = findCurrentSeasonMonth(selectedMonth);
  }

  @override
  void dispose() {
    tabController.dispose();
    super.dispose();
  }

  void incrementDate() =>
      setState(() => selectedDate = selectedDate.add(const Duration(days: 1)));
  void decrementDate() => setState(
      () => selectedDate = selectedDate.subtract(const Duration(days: 1)));

  void incrementMonth() =>
      setState(() => selectedMonth = selectedMonth.month == 12
          ? DateTime(selectedMonth.year + 1, 1, 1)
          : DateTime(selectedMonth.year, selectedMonth.month + 1, 1));

  void decrementMonth() =>
      setState(() => selectedMonth = selectedMonth.month == 1
          ? DateTime(selectedMonth.year - 1, 12, 1)
          : DateTime(selectedMonth.year, selectedMonth.month - 1, 1));

  void toggleBySeasonView() =>
      setState(() => showBySeasonTable = !showBySeasonTable);
  void toggleHistoryView() =>
      setState(() => showHistoryTable = !showHistoryTable);

  @override
  Widget build(BuildContext context) {

    final legends = widget.player.legendsBySeason;
    if (legends == null) {
      return Center(
        child: Text(AppLocalizations.of(context)?.noDataAvailable ??
            'No data available'),
      );
    }

    return Scaffold(
      body: RefreshIndicator(
        backgroundColor: Theme.of(context).colorScheme.surface,
        onRefresh: () => Future.value(),
        child: SingleChildScrollView(
          child: Column(
            children: [
              LegendHeaderCard(player: widget.player),
              ScrollableTab(
                tabBarDecoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                ),
                labelColor: Theme.of(context).colorScheme.onSurface,
                labelPadding: EdgeInsets.zero,
                labelStyle: Theme.of(context).textTheme.bodyLarge,
                unselectedLabelColor: Theme.of(context).colorScheme.onSurface,
                onTap: (_) => setState(() {}),
                tabs: [
                  Tab(text: AppLocalizations.of(context)?.byDay ?? "By Day"),
                  Tab(
                      text: AppLocalizations.of(context)?.bySeason ??
                          "By Season"),
                  Tab(text: AppLocalizations.of(context)?.history ?? "History"),
                ],
                children: [
                  LegendByDayTab(player: widget.player),
                  Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const SizedBox(width: 16),
                              IconButton(
                                icon: Icon(
                                  showBySeasonTable
                                      ? Icons.bar_chart
                                      : Icons.table_chart,
                                  color:
                                      Theme.of(context).colorScheme.onSurface,
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
                                  icon: Icon(Icons.arrow_back,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface,
                                      size: 16),
                                  onPressed: decrementMonth,
                                ),
                              ),
                              Text(
                                DateFormat(
                                        'MMMM yyyy',
                                        Localizations.localeOf(context)
                                            .languageCode)
                                    .format(selectedMonth),
                                style: Theme.of(context).textTheme.labelLarge,
                              ),
                              SizedBox(
                                width: 30,
                                height: 30,
                                child: IconButton(
                                  icon: Icon(Icons.arrow_forward,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface,
                                      size: 16),
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
                          season: legends.getSpecificSeason(selectedMonth)),
                      showBySeasonTable
                          ? PlayerLegendSeasonList(
                              player: widget.player,
                              season: legends.getSpecificSeason(selectedMonth))
                          : LegendSeasonChart(
                              season: legends.getSpecificSeason(selectedMonth))
                    ],
                  ),
                  Column(
                    children: [
                      Row(
                        children: [
                          const SizedBox(width: 16),
                          IconButton(
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
                              rankings: widget.player.legendRanking)
                          : PlayerLegendHistoryEosChart(
                              rankings: widget.player.legendRanking),
                    ],
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
