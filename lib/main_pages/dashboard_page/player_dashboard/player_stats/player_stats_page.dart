import 'package:cached_network_image/cached_network_image.dart';
import 'package:clashkingapp/classes/profile/legend/legend_data.dart';
import 'package:clashkingapp/classes/profile/stats/player_stats_service.dart';
import 'package:clashkingapp/main_pages/dashboard_page/player_dashboard/player_info_page.dart';
import 'package:clashkingapp/main_pages/dashboard_page/player_dashboard/player_stats/player_stats_header.dart';
import 'package:custom_sliding_segmented_control/custom_sliding_segmented_control.dart';
import 'package:flutter/material.dart';
import 'package:clashkingapp/classes/profile/profile_info.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';
import 'package:clashkingapp/main_pages/wars_league_page/war/war_functions.dart';
import 'package:clashkingapp/classes/profile/stats/player_war_stats.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:scrollable_tab_view/scrollable_tab_view.dart';

class PlayerStatsScreen extends StatefulWidget {
  final ProfileInfo profileInfo;
  final List<String> user;

  PlayerStatsScreen({super.key, required this.profileInfo, required this.user});

  @override
  PlayerStatsScreenState createState() => PlayerStatsScreenState();
}

class PlayerStatsScreenState extends State<PlayerStatsScreen>
    with SingleTickerProviderStateMixin {
  WarStats? warStats;
  WarStats? defaultWarStats;
  late DateTime currentSeasonDate;
  String filterType = "dateRange";
  bool isCWLChecked = true;
  bool isRandomChecked = true;
  bool isFriendlyChecked = true;
  List<String> filters = ["cwl", "random", "friendly"];
  late int warDataStartDate;
  late int warDataEndDate;
  late int warDataLimit;
  int _currentSegment = 1;

  @override
  void initState() {
    super.initState();
    currentSeasonDate = DateTime.now();
    warStats = widget.profileInfo.warStats;
    defaultWarStats = warStats;
    warDataStartDate = warStats!.timeStampsStart;
    warDataEndDate = warStats!.timeStampsEnd;
    warDataLimit = 0;
  }

  void showFilterDialog() {
    final TextEditingController textController = TextEditingController();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.filters,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleSmall),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                title: Text(AppLocalizations.of(context)!.byNumberOfWars,
                    style: Theme.of(context).textTheme.bodyMedium),
                onTap: () async {
                  Navigator.of(context).pop();
                  await showDialog(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        title: Text(
                            AppLocalizations.of(context)!.byNumberOfWars,
                            style: Theme.of(context).textTheme.bodyMedium),
                        content: TextField(
                          controller: textController,
                          decoration: InputDecoration(hintText: "e.g., 5"),
                          keyboardType:
                              TextInputType.numberWithOptions(decimal: false),
                        ),
                        actions: <Widget>[
                          TextButton(
                            child: Text(AppLocalizations.of(context)!.ok),
                            onPressed: () {
                              Navigator.of(context)
                                  .pop(); // Fermer le dialogue interne
                              int numberOfWars =
                                  int.tryParse(textController.text) ?? 0;
                              loadLastXWars(numberOfWars);
                            },
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
              ListTile(
                title: Text(AppLocalizations.of(context)!.bySeason,
                    style: Theme.of(context).textTheme.bodyMedium),
                onTap: () async {
                  Navigator.of(context).pop();
                  Map<String, int>? result = await chooseYearAndMonth(context);
                  if (result != null) {
                    int selectedYear = result['year'] ?? DateTime.now().year;
                    int selectedMonth = result['month'] ?? DateTime.now().month;
                    selectSeason(selectedYear, selectedMonth);
                  }
                },
              ),
              ListTile(
                title: Text(AppLocalizations.of(context)!.byDateRange,
                    style: Theme.of(context).textTheme.bodyMedium),
                onTap: () async {
                  Navigator.of(context).pop();
                  DateTimeRange? dateRange = await showDateRangePicker(
                    context: context,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (dateRange != null) {
                    selectDateRange(dateRange.start, dateRange.end);
                  }
                },
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: Text(AppLocalizations.of(context)!.cancel),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void loadLastXWars(int numberOfWars) async {
    warDataLimit = numberOfWars;
    warDataStartDate =
        DateTime.now().subtract(Duration(days: 30)).millisecondsSinceEpoch ~/
            1000;
    warDataEndDate = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    PlayerStatsService service = PlayerStatsService(
        playerTag: widget.profileInfo.tag, limit: warDataLimit);
    defaultWarStats = await service.fetchPlayerWarHits();
    warStats = defaultWarStats;
    filterType = "lastXWars";
    setState(() {
      applyFilters();
    });
  }

  void selectSeason(int year, int month) async {
    List<DateTime> dates = findSeasonStartEndDate(DateTime(year, month, 1));
    warDataStartDate = dates[0].millisecondsSinceEpoch ~/ 1000;
    warDataEndDate = dates[1].millisecondsSinceEpoch ~/ 1000;
    warDataLimit = 0;
    currentSeasonDate = dates[1];
    PlayerStatsService service = PlayerStatsService(
        playerTag: widget.profileInfo.tag,
        timestampStart: warDataStartDate,
        timestampEnd: warDataEndDate);
    defaultWarStats = await service.fetchPlayerWarHits();
    warStats = defaultWarStats;
    filterType = "season";
    setState(() {
      applyFilters();
    });
  }

  void selectDateRange(DateTime startDate, DateTime endDate) async {
    warDataStartDate = startDate.millisecondsSinceEpoch ~/ 1000;
    warDataEndDate = endDate.millisecondsSinceEpoch ~/ 1000;
    warDataLimit = 0;
    PlayerStatsService service = PlayerStatsService(
      playerTag: widget.profileInfo.tag,
      timestampStart: warDataStartDate,
      timestampEnd: warDataEndDate,
    );
    defaultWarStats = await service.fetchPlayerWarHits();
    warStats = defaultWarStats;
    filterType = "dateRange";
    setState(() {
      applyFilters();
    });
  }

  void applyFilters() {
    setState(() {
      List<String> activeFilters = [];
      if (isCWLChecked) activeFilters.add("cwl");
      if (isRandomChecked) activeFilters.add("random");
      if (isFriendlyChecked) activeFilters.add("friendly");

      // Utilisation du service pour filtrer les données
      if (defaultWarStats != null && activeFilters.isNotEmpty) {
        PlayerStatsService service = PlayerStatsService(
            playerTag: widget.profileInfo.tag,
            timestampStart: warDataStartDate,
            timestampEnd: warDataEndDate,
            limit: warDataLimit == 0 ? 100 : warDataLimit);

        // Mise à jour de warStats avec les résultats filtrés
        warStats = service.filterWarStats(defaultWarStats!, activeFilters);
      } else {
        // Aucun filtre n'est sélectionné ou defaultWarStats n'est pas encore chargé
        warStats = defaultWarStats; // Retour aux données non filtrées
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            PlayerStatsHeader(
              playerName: widget.profileInfo.name,
              playerTag: widget.profileInfo.tag,
              townHallPic: widget.profileInfo.townHallPic,
              isCWLChecked: isCWLChecked,
              isRandomChecked: isRandomChecked,
              isFriendlyChecked: isFriendlyChecked,
              onCWLChanged: () {
                setState(() {
                  isCWLChecked = !isCWLChecked;
                  applyFilters();
                });
              },
              onRandomChanged: () {
                setState(() {
                  isRandomChecked = !isRandomChecked;
                  applyFilters();
                });
              },
              onFriendlyChanged: () {
                setState(() {
                  isFriendlyChecked = !isFriendlyChecked;
                  applyFilters();
                });
              },
              onBack: () => Navigator.of(context).pop(),
              onFilter: showFilterDialog,
            ),
            ScrollableTab(
              tabBarDecoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
              ),
              labelColor: Theme.of(context).colorScheme.onSurface,
              labelPadding: EdgeInsets.zero,
              labelStyle: Theme.of(context).textTheme.bodyLarge,
              unselectedLabelColor: Theme.of(context).colorScheme.onSurface,
              onTap: (value) {
                setState(() {});
              },
              tabs: [
                Tab(text: AppLocalizations.of(context)!.stats),
                Tab(text: AppLocalizations.of(context)!.details),
              ],
              children: [
                Column(
                  children: [
                    warStats == null
                        ? Center(child: CircularProgressIndicator())
                        : buildWarStatsView(context),
                  ],
                ),
                Column(
                  children: [
                    SizedBox(height: 8),
                    CustomSlidingSegmentedControl<int>(
                      initialValue: _currentSegment,
                      children: {
                        1: Text(AppLocalizations.of(context)!.attacks),
                        2: Text(AppLocalizations.of(context)!.defenses),
                      },
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .tertiary
                            .withValues(alpha : 0.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      thumbDecoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha : 0.3),
                            blurRadius: 4.0,
                            spreadRadius: 1.0,
                            offset: Offset(0.0, 2.0),
                          ),
                        ],
                      ),
                      duration: Duration(milliseconds: 300),
                      curve: Curves.easeInToLinear,
                      onValueChanged: (v) {
                        setState(() {
                          _currentSegment = v;
                        });
                      },
                    ),
                    SizedBox(height: 8),
                    _currentSegment == 1
                        ? warStats == null
                            ? Center(child: CircularProgressIndicator())
                            : buildAttackDetails(context)
                        : warStats == null
                            ? Center(child: CircularProgressIndicator())
                            : buildDefenseDetails(context),
                  ],
                )
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget buildWarStatsView(BuildContext context) {
    List<int> opponentThLevels = warStats!.opponentTownhallLevels();
    List<TownhallAttackDefenseStats> thStatsList =
        opponentThLevels.map((level) {
      return warStats!.getTownhallAttackDefenseStats(level);
    }).toList();

    final Locale userLocale = Localizations.localeOf(context);
    String formattedStartDate = DateFormat.yMd(userLocale.toString()).format(
        DateTime.fromMillisecondsSinceEpoch(warStats!.timeStampsStart * 1000));
    String formattedEndDate = DateFormat.yMd(userLocale.toString()).format(
        DateTime.fromMillisecondsSinceEpoch(warStats!.timeStampsEnd * 1000));

    if (warStats!.attacks.isNotEmpty) {
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  children: [
                    Text(AppLocalizations.of(context)!.allTownHalls,
                        style: Theme.of(context).textTheme.titleSmall),
                    if (filterType == "dateRange")
                      Text("($formattedStartDate - $formattedEndDate)",
                          style: Theme.of(context).textTheme.bodyMedium),
                    if (filterType == "lastXWars")
                      Text(
                          AppLocalizations.of(context)!.lastXwars(warDataLimit),
                          style: Theme.of(context).textTheme.bodyMedium),
                    if (filterType == "season")
                      Text(
                          AppLocalizations.of(context)!.seasonDate(
                              DateFormat.yMMMM(userLocale.toString())
                                  .format(currentSeasonDate)),
                          style: Theme.of(context).textTheme.bodyMedium),
                    SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Column(
                          children: [
                            Text(AppLocalizations.of(context)!.attacks),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(children: [
                                  CachedNetworkImage(
  
  errorWidget: (context, url, error) => Icon(Icons.error),
                                      imageUrl:
                                          "https://assets.clashk.ing/icons/Icon_HV_Attack_Star.png",
                                      width: 16,
                                      height: 16,
                                      fit: BoxFit.cover),
                                  SizedBox(width: 8),
                                  Text(
                                      warStats!.averageStars.toStringAsFixed(2))
                                ]),
                                Row(
                                  children: [
                                    CachedNetworkImage(
  
  errorWidget: (context, url, error) => Icon(Icons.error),
                                        imageUrl:
                                            "https://assets.clashk.ing/icons/Icon_DC_Hitrate.png",
                                        width: 16,
                                        height: 16,
                                        fit: BoxFit.cover),
                                    SizedBox(width: 8),
                                    Text(warStats!.averageDestructionPercentage
                                        .toStringAsFixed(2))
                                  ],
                                ),
                                Row(
                                  children: [
                                    CachedNetworkImage(
  
  errorWidget: (context, url, error) => Icon(Icons.error),
                                        imageUrl:
                                            "https://assets.clashk.ing/icons/Icon_HV_Sword.png",
                                        width: 16,
                                        height: 16,
                                        fit: BoxFit.cover),
                                    SizedBox(width: 8),
                                    Text(warStats!.attacks.length.toString())
                                  ],
                                ),
                              ],
                            ),
                            SizedBox(height: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    ...generateStars(3, 16),
                                    SizedBox(width: 8),
                                    Text.rich(
                                      TextSpan(
                                        children: [
                                          TextSpan(
                                            text:
                                                "${(warStats!.numberOfStarsAttacks(3) / (warStats!.attacks.isEmpty ? 1 : warStats!.attacks.length) * 100).toStringAsFixed(0)}%",
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyMedium,
                                          ),
                                          WidgetSpan(
                                            child: Transform.translate(
                                              offset: const Offset(0, -6),
                                              child: Text(
                                                "(${warStats!.numberOfStarsAttacks(3)})",
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodySmall,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    ...generateStars(2, 16),
                                    SizedBox(width: 8),
                                    Text.rich(
                                      TextSpan(
                                        children: [
                                          TextSpan(
                                            text:
                                                "${(warStats!.numberOfStarsAttacks(2) / (warStats!.attacks.isEmpty ? 1 : warStats!.attacks.length) * 100).toStringAsFixed(0)}%",
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyMedium,
                                          ),
                                          WidgetSpan(
                                            child: Transform.translate(
                                              offset: const Offset(0, -6),
                                              child: Text(
                                                "(${warStats!.numberOfStarsAttacks(2)})",
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodySmall,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    ...generateStars(1, 16),
                                    SizedBox(width: 8),
                                    Text.rich(
                                      TextSpan(
                                        children: [
                                          TextSpan(
                                            text:
                                                "${(warStats!.numberOfStarsAttacks(1) / (warStats!.attacks.isEmpty ? 1 : warStats!.attacks.length) * 100).toStringAsFixed(0)}%",
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyMedium,
                                          ),
                                          WidgetSpan(
                                            child: Transform.translate(
                                              offset: const Offset(0, -6),
                                              child: Text(
                                                "(${warStats!.numberOfStarsAttacks(1)})",
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodySmall,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    ...generateStars(0, 16),
                                    SizedBox(width: 8),
                                    Text.rich(
                                      TextSpan(
                                        children: [
                                          TextSpan(
                                            text:
                                                "${(warStats!.numberOfStarsAttacks(0) / (warStats!.attacks.isEmpty ? 1 : warStats!.attacks.length) * 100).toStringAsFixed(0)}%",
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyMedium,
                                          ),
                                          WidgetSpan(
                                            child: Transform.translate(
                                              offset: const Offset(0, -6),
                                              child: Text(
                                                "(${warStats!.numberOfStarsAttacks(0)})",
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodySmall,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                        Column(
                          children: [
                            Text(AppLocalizations.of(context)!.defenses),
                            Row(
                              children: [
                                CachedNetworkImage(
  
  errorWidget: (context, url, error) => Icon(Icons.error),
                                    imageUrl:
                                        "https://assets.clashk.ing/icons/Icon_HV_Attack_Star.png",
                                    width: 16,
                                    height: 16,
                                    fit: BoxFit.cover),
                                SizedBox(width: 8),
                                Text(warStats!.averageDefenseStars
                                    .toStringAsFixed(2)),
                              ],
                            ),
                            Row(
                              children: [
                                CachedNetworkImage(
  
  errorWidget: (context, url, error) => Icon(Icons.error),
                                    imageUrl:
                                        "https://assets.clashk.ing/icons/Icon_DC_Hitrate.png",
                                    width: 16,
                                    height: 16,
                                    fit: BoxFit.cover),
                                SizedBox(width: 8),
                                Text(warStats!
                                    .averageDefenseDestructionPercentage
                                    .toStringAsFixed(0)),
                              ],
                            ),
                            Row(
                              children: [
                                CachedNetworkImage(
  
  errorWidget: (context, url, error) => Icon(Icons.error),
                                    imageUrl:
                                        "https://assets.clashk.ing/icons/Icon_HV_Shield.png",
                                    width: 16,
                                    height: 16,
                                    fit: BoxFit.cover),
                                SizedBox(width: 8),
                                Text(warStats!.defenses.length.toString()),
                              ],
                            ),
                            SizedBox(height: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    ...generateStars(3, 16),
                                    SizedBox(width: 8),
                                    Text.rich(
                                      TextSpan(
                                        children: [
                                          TextSpan(
                                            text:
                                                "${(warStats!.numberOfStarsDefenses(3) / (warStats!.defenses.isEmpty ? 1 : warStats!.defenses.length) * 100).toStringAsFixed(0)}%",
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyMedium,
                                          ),
                                          WidgetSpan(
                                            child: Transform.translate(
                                              offset: const Offset(0, -6),
                                              child: Text(
                                                "(${warStats!.numberOfStarsDefenses(3)})",
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodySmall,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    ...generateStars(2, 16),
                                    SizedBox(width: 8),
                                    Text.rich(
                                      TextSpan(
                                        children: [
                                          TextSpan(
                                            text:
                                                "${(warStats!.numberOfStarsDefenses(2) / (warStats!.defenses.isEmpty ? 1 : warStats!.defenses.length) * 100).toStringAsFixed(0)}%",
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyMedium,
                                          ),
                                          WidgetSpan(
                                            child: Transform.translate(
                                              offset: const Offset(0, -6),
                                              child: Text(
                                                "(${warStats!.numberOfStarsDefenses(2)})",
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodySmall,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    ...generateStars(1, 16),
                                    SizedBox(width: 8),
                                    Text.rich(
                                      TextSpan(
                                        children: [
                                          TextSpan(
                                            text:
                                                "${(warStats!.numberOfStarsDefenses(1) / (warStats!.defenses.isEmpty ? 1 : warStats!.defenses.length) * 100).toStringAsFixed(0)}%",
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyMedium,
                                          ),
                                          WidgetSpan(
                                            child: Transform.translate(
                                              offset: const Offset(0, -6),
                                              child: Text(
                                                "(${warStats!.numberOfStarsDefenses(1)})",
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodySmall,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    ...generateStars(0, 16),
                                    SizedBox(width: 8),
                                    Text.rich(
                                      TextSpan(
                                        children: [
                                          TextSpan(
                                            text:
                                                "${(warStats!.numberOfStarsDefenses(0) / (warStats!.defenses.isEmpty ? 1 : warStats!.defenses.length) * 100).toStringAsFixed(0)}%",
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyMedium,
                                          ),
                                          WidgetSpan(
                                            child: Transform.translate(
                                              offset: const Offset(0, -6),
                                              child: Text(
                                                "(${warStats!.numberOfStarsDefenses(0)})",
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodySmall,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          for (TownhallAttackDefenseStats thStats in thStatsList)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CachedNetworkImage(
  
  errorWidget: (context, url, error) => Icon(Icons.error),
                            imageUrl: thStats.townHallImageUrl,
                            width: 30,
                            height: 30,
                          ),
                          SizedBox(width: 8),
                          Text(
                              AppLocalizations.of(context)!
                                  .townHallLevelLevel(thStats.townhallLevel),
                              style: Theme.of(context).textTheme.titleSmall),
                        ],
                      ),
                      SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Column(
                            children: [
                              Text(AppLocalizations.of(context)!.attacks),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(children: [
                                    CachedNetworkImage(
  
  errorWidget: (context, url, error) => Icon(Icons.error),
                                        imageUrl:
                                            "https://assets.clashk.ing/icons/Icon_HV_Attack_Star.png",
                                        width: 16,
                                        height: 16,
                                        fit: BoxFit.cover),
                                    SizedBox(width: 8),
                                    Text(thStats.averageAttackStars
                                        .toStringAsFixed(2))
                                  ]),
                                  Row(
                                    children: [
                                      CachedNetworkImage(
  
  errorWidget: (context, url, error) => Icon(Icons.error),
                                          imageUrl:
                                              "https://assets.clashk.ing/icons/Icon_DC_Hitrate.png",
                                          width: 16,
                                          height: 16,
                                          fit: BoxFit.cover),
                                      SizedBox(width: 8),
                                      Text(thStats
                                          .averageAttackDestructionPercentage
                                          .toStringAsFixed(2))
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      CachedNetworkImage(
  
  errorWidget: (context, url, error) => Icon(Icons.error),
                                          imageUrl:
                                              "https://assets.clashk.ing/icons/Icon_HV_Sword.png",
                                          width: 16,
                                          height: 16,
                                          fit: BoxFit.cover),
                                      SizedBox(width: 8),
                                      Text(thStats.totalAttacks.toString())
                                    ],
                                  ),
                                ],
                              ),
                              SizedBox(height: 16),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      ...generateStars(3, 16),
                                      SizedBox(width: 8),
                                      Text.rich(
                                        TextSpan(
                                          children: [
                                            TextSpan(
                                              text:
                                                  "${(thStats.threeStarsAttacks / thStats.totalAttacks * 100).toStringAsFixed(0)}%",
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodyMedium,
                                            ),
                                            WidgetSpan(
                                              child: Transform.translate(
                                                offset: const Offset(0, -6),
                                                child: Text(
                                                  "(${thStats.threeStarsAttacks})",
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodySmall,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      ...generateStars(2, 16),
                                      SizedBox(width: 8),
                                      Text.rich(
                                        TextSpan(
                                          children: [
                                            TextSpan(
                                              text:
                                                  "${(thStats.twoStarsAttacks / thStats.totalAttacks * 100).toStringAsFixed(0)}%",
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodyMedium,
                                            ),
                                            WidgetSpan(
                                              child: Transform.translate(
                                                offset: const Offset(0, -6),
                                                child: Text(
                                                  "(${thStats.twoStarsAttacks})",
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodySmall,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      ...generateStars(1, 16),
                                      SizedBox(width: 8),
                                      Text.rich(
                                        TextSpan(
                                          children: [
                                            TextSpan(
                                              text:
                                                  "${(thStats.oneStarAttacks / thStats.totalAttacks * 100).toStringAsFixed(0)}%",
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodyMedium,
                                            ),
                                            WidgetSpan(
                                              child: Transform.translate(
                                                offset: const Offset(0, -6),
                                                child: Text(
                                                  "(${thStats.oneStarAttacks})",
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodySmall,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      ...generateStars(0, 16),
                                      SizedBox(width: 8),
                                      Text.rich(
                                        TextSpan(
                                          children: [
                                            TextSpan(
                                              text:
                                                  "${(thStats.zeroStarsAttacks / thStats.totalAttacks * 100).toStringAsFixed(0)}%",
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodyMedium,
                                            ),
                                            WidgetSpan(
                                              child: Transform.translate(
                                                offset: const Offset(0, -6),
                                                child: Text(
                                                  "(${thStats.zeroStarsAttacks})",
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodySmall,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Column(
                            children: [
                              Text(AppLocalizations.of(context)!.defenses),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(children: [
                                    CachedNetworkImage(
  
  errorWidget: (context, url, error) => Icon(Icons.error),
                                        imageUrl:
                                            "https://assets.clashk.ing/icons/Icon_HV_Attack_Star.png",
                                        width: 16,
                                        height: 16,
                                        fit: BoxFit.cover),
                                    SizedBox(width: 8),
                                    Text(thStats.averageDefenseStars
                                        .toStringAsFixed(2))
                                  ]),
                                  Row(
                                    children: [
                                      CachedNetworkImage(
  
  errorWidget: (context, url, error) => Icon(Icons.error),
                                          imageUrl:
                                              "https://assets.clashk.ing/icons/Icon_DC_Hitrate.png",
                                          width: 16,
                                          height: 16,
                                          fit: BoxFit.cover),
                                      SizedBox(width: 8),
                                      Text(thStats
                                          .averageDefenseDestructionPercentage
                                          .toStringAsFixed(2))
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      CachedNetworkImage(
  
  errorWidget: (context, url, error) => Icon(Icons.error),
                                          imageUrl:
                                              "https://assets.clashk.ing/icons/Icon_HV_Shield.png",
                                          width: 16,
                                          height: 16,
                                          fit: BoxFit.cover),
                                      SizedBox(width: 8),
                                      Text(thStats.totalDefenses.toString())
                                    ],
                                  ),
                                ],
                              ),
                              SizedBox(height: 16),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      ...generateStars(3, 16),
                                      SizedBox(width: 8),
                                      Text.rich(
                                        TextSpan(
                                          children: [
                                            TextSpan(
                                              text:
                                                  "${(thStats.threeStarsDefenses / (thStats.totalDefenses == 0 ? 1 : thStats.totalDefenses) * 100).toStringAsFixed(0)}%",
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodyMedium,
                                            ),
                                            WidgetSpan(
                                              child: Transform.translate(
                                                offset: const Offset(0, -6),
                                                child: Text(
                                                  "(${thStats.threeStarsDefenses})",
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodySmall,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      ...generateStars(2, 16),
                                      SizedBox(width: 8),
                                      Text.rich(
                                        TextSpan(
                                          children: [
                                            TextSpan(
                                              text:
                                                  "${(thStats.twoStarsDefenses / (thStats.totalDefenses == 0 ? 1 : thStats.totalDefenses) * 100).toStringAsFixed(0)}%",
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodyMedium,
                                            ),
                                            WidgetSpan(
                                              child: Transform.translate(
                                                offset: const Offset(0, -6),
                                                child: Text(
                                                  "(${thStats.twoStarsDefenses})",
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodySmall,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      ...generateStars(1, 16),
                                      SizedBox(width: 8),
                                      Text.rich(
                                        TextSpan(
                                          children: [
                                            TextSpan(
                                              text:
                                                  "${(thStats.oneStarDefenses / (thStats.totalDefenses == 0 ? 1 : thStats.totalDefenses) * 100).toStringAsFixed(0)}%",
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodyMedium,
                                            ),
                                            WidgetSpan(
                                              child: Transform.translate(
                                                offset: const Offset(0, -6),
                                                child: Text(
                                                  "(${thStats.oneStarDefenses})",
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodySmall,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      ...generateStars(0, 16),
                                      SizedBox(width: 8),
                                      Text.rich(
                                        TextSpan(
                                          children: [
                                            TextSpan(
                                              text:
                                                  "${(thStats.zeroStarsDefenses / (thStats.totalDefenses == 0 ? 1 : thStats.totalDefenses) * 100).toStringAsFixed(0)}%",
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodyMedium,
                                            ),
                                            WidgetSpan(
                                              child: Transform.translate(
                                                offset: const Offset(0, -6),
                                                child: Text(
                                                  "(${thStats.zeroStarsDefenses})",
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodySmall,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      );
    } else {
      return Column(
        children: [
          SizedBox(height: 16),
          Card(
              child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(AppLocalizations.of(context)?.noDataAvailable ??
                      'No data available'))),
          SizedBox(height: 32),
          CachedNetworkImage(
  
  errorWidget: (context, url, error) => Icon(Icons.error),
            imageUrl:
                'https://assets.clashk.ing/stickers/Villager_HV_Villager_7.png',
            height: 250,
            width: 200,
          ),
        ],
      );
    }
  }

  Widget buildAttackDetails(BuildContext context) {
    if (warStats!.attacks.isEmpty) {
      return Column(
        children: [
          SizedBox(height: 16),
          Card(
              child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(AppLocalizations.of(context)?.noDataAvailable ??
                      'No data available'))),
          SizedBox(height: 32),
          CachedNetworkImage(
  
  errorWidget: (context, url, error) => Icon(Icons.error),
            imageUrl:
                'https://assets.clashk.ing/stickers/Villager_HV_Villager_7.png',
            height: 250,
            width: 200,
          ),
        ],
      );
    }

    final Locale userLocale = Localizations.localeOf(context);
    return ListView.builder(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: warStats!.attacks.length,
      itemBuilder: (context, index) {
        Attack attack = warStats!.attacks[index];

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
          child: GestureDetector(
            onTap: () async {
              final navigator = Navigator.of(context);
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (BuildContext context) {
                  return Center(
                    child: CircularProgressIndicator(),
                  );
                },
              );
              ProfileInfo? playerStats = await ProfileInfoService()
                  .fetchCompleteProfileInfo(attack.defenderTag);
              navigator.pop();
              navigator.push(
                MaterialPageRoute(
                  builder: (context) => StatsScreen(
                      playerStats: playerStats!, discordUser: widget.user),
                ),
              );
            },
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                            DateFormat.yMd(userLocale.toString()).format(
                                DateTime.fromMillisecondsSinceEpoch(
                                    attack.warStartTime)),
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .tertiary)),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CachedNetworkImage(
  
  errorWidget: (context, url, error) => Icon(Icons.error),
                                  imageUrl:
                                      'https://assets.clashk.ing/home-base/town-hall-pics/town-hall-${attack.defender.townhallLevel}.png',
                                  width: 40,
                                  height: 40,
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(LucideIcons.hourglass, size: 12),
                                        SizedBox(width: 4),
                                        Text("${attack.duration}s",
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        Icon(LucideIcons.swords, size: 12),
                                        SizedBox(width: 4),
                                        Text(attack.warType,
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            SizedBox(width: 8),
                            Text(
                                "${attack.defender.mapPosition}. ${attack.defender.name}"),
                          ],
                        ),
                        Column(
                          children: [
                            Text("${attack.destructionPercentage.toString()}%"),
                            Row(
                              children: [
                                ...generateStars(attack.stars, 16),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget buildDefenseDetails(BuildContext context) {
    if (warStats!.defenses.isEmpty) {
      return Column(
        children: [
          SizedBox(height: 16),
          Card(
              child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(AppLocalizations.of(context)?.noDataAvailable ??
                      'No data available'))),
          SizedBox(height: 32),
          CachedNetworkImage(
  
  errorWidget: (context, url, error) => Icon(Icons.error),
            imageUrl:
                'https://assets.clashk.ing/stickers/Villager_HV_Villager_7.png',
            height: 250,
            width: 200,
          ),
        ],
      );
    }

    final Locale userLocale = Localizations.localeOf(context);

    return ListView.builder(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: warStats!.defenses.length,
      itemBuilder: (context, index) {
        Defense defense = warStats!.defenses[index];

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
          child: GestureDetector(
            onTap: () async {
              final navigator = Navigator.of(context);
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (BuildContext context) {
                  return Center(
                    child: CircularProgressIndicator(),
                  );
                },
              );
              ProfileInfo? playerStats = await ProfileInfoService()
                  .fetchCompleteProfileInfo(defense.attackerTag);
              navigator.pop();
              navigator.push(
                MaterialPageRoute(
                  builder: (context) => StatsScreen(
                      playerStats: playerStats!, discordUser: widget.user),
                ),
              );
            },
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                            DateFormat.yMd(userLocale.toString()).format(
                                DateTime.fromMillisecondsSinceEpoch(
                                    defense.warStartTime)),
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .tertiary)),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CachedNetworkImage(
  
  errorWidget: (context, url, error) => Icon(Icons.error),
                                  imageUrl:
                                      'https://assets.clashk.ing/home-base/town-hall-pics/town-hall-${defense.attacker.townhallLevel}.png',
                                  width: 40,
                                  height: 40,
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(LucideIcons.hourglass, size: 12),
                                        SizedBox(width: 4),
                                        Text("${defense.duration}s",
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        Icon(LucideIcons.swords, size: 12),
                                        SizedBox(width: 4),
                                        Text(defense.warType,
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            SizedBox(width: 8),
                            Text(
                                "${defense.attacker.mapPosition}. ${defense.attacker.name}"),
                          ],
                        ),
                        Column(
                          children: [
                            Text(
                                "${defense.destructionPercentage.toString()}%"),
                            Row(
                              children: [
                                ...generateStars(defense.stars, 16),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

Future<Map<String, int>?> chooseYearAndMonth(BuildContext context) async {
  int selectedYear = DateTime.now().year;
  int selectedMonth = DateTime.now().month;
  List<int> years =
      List.generate(20, (index) => DateTime.now().year - 10 + index);
  List<int> months = List.generate(12, (index) => index + 1);

  return showDialog<Map<String, int>>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(AppLocalizations.of(context)!.selectSeason),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            DropdownButtonFormField<int>(
              value: selectedYear,
              items: years.map<DropdownMenuItem<int>>((int value) {
                return DropdownMenuItem<int>(
                  value: value,
                  child: Text(value.toString()),
                );
              }).toList(),
              onChanged: (int? newValue) {
                if (newValue != null) {
                  selectedYear = newValue;
                }
              },
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.year,
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            DropdownButtonFormField<int>(
              value: selectedMonth,
              items: months.map<DropdownMenuItem<int>>((int value) {
                return DropdownMenuItem<int>(
                  value: value,
                  child: Text(DateFormat.MMMM().format(DateTime(0, value))),
                );
              }).toList(),
              onChanged: (int? newValue) {
                if (newValue != null) {
                  selectedMonth = newValue;
                }
              },
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.month,
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: <Widget>[
          TextButton(
            child: Text(AppLocalizations.of(context)!.cancel),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          TextButton(
            child: Text(AppLocalizations.of(context)!.ok),
            onPressed: () {
              Navigator.of(context).pop({
                'year': selectedYear,
                'month': selectedMonth,
              });
            },
          ),
        ],
      );
    },
  );
}
