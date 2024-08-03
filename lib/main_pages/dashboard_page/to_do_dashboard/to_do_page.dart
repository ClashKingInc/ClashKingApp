import 'package:clashkingapp/classes/account/accounts.dart';
import 'package:clashkingapp/components/filter_dropdown.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:clashkingapp/classes/profile/profile_info.dart';
import 'package:clashkingapp/main_pages/dashboard_page/to_do_dashboard/to_do_header.dart';
import 'package:scrollable_tab_view/scrollable_tab_view.dart';

class ToDoScreen extends StatefulWidget {
  final ProfileInfo playerStats;
  final List<String> tags;
  final Accounts accounts;

  ToDoScreen(
      {super.key,
      required this.playerStats,
      required this.tags,
      required this.accounts});

  @override
  ToDoScreenState createState() => ToDoScreenState();
}

class ToDoScreenState extends State<ToDoScreen>
    with SingleTickerProviderStateMixin {
  String currentFilter = 'all';

  @override
  void initState() {
    super.initState();
  }

  void updateFilter(String newFilter) {
    setState(() {
      currentFilter = newFilter;
    });
  }

  String convertToExactTime(int timestamp, BuildContext context) {
    DateTime now = DateTime.now();
    DateTime date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    Duration diff = now.difference(date);

    int days = diff.inDays;
    int hours = diff.inHours % 24;
    int minutes = diff.inMinutes % 60;
    String finalDiff = '';

    if (days > 0) {
      finalDiff += AppLocalizations.of(context)?.daysAgo(days) ?? "$days days";
      if (hours > 0) finalDiff += ' ${hours}h';
      if (minutes > 0) finalDiff += ' ${minutes}m';
    } else if (hours > 0) {
      finalDiff +=
          AppLocalizations.of(context)?.hoursAgo(hours) ?? "$hours hours";
      if (minutes > 0) finalDiff += ' ${minutes}m';
    } else if (minutes > 0) {
      finalDiff += AppLocalizations.of(context)?.minutesAgo(minutes) ??
          "$minutes minutes";
    } else {
      return AppLocalizations.of(context)?.justNow ?? "Just now";
    }

    return finalDiff;
  }

  @override
  Widget build(BuildContext context) {
    Map<String, String> filterOptions = {
      AppLocalizations.of(context)!.all: 'all',
      //'byEvent': 'byEvent',
    };

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            ToDoHeader(accounts: widget.accounts),
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
                  Tab(text: AppLocalizations.of(context)!.activeAccounts),
                  Tab(text: AppLocalizations.of(context)!.inactiveAccounts),
                ],
                children: [
                  _contentForAll(filterOptions, true),
                  _contentForAll(filterOptions, false),
                ]),
            SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _contentForAll(filterOptions, bool active) {
    List<Widget> cards = [];
    DateTime today = DateTime.now();
    final Locale userLocale = Localizations.localeOf(context);

    for (var tag in widget.tags) {
      for (var toDo in widget.accounts.toDoList.items
          .where((item) => item.playerTag == tag)) {
        Account? currentAccount =
            widget.accounts.findAccountByTag(toDo.playerTag);
        DateTime lastActiveDate =
            DateTime.fromMillisecondsSinceEpoch(toDo.lastActive * 1000);
        int daysDiff = today.difference(lastActiveDate).inDays;

        if ((active && daysDiff <= 14) || (!active && daysDiff > 14)) {
          cards.add(
            Card(
              margin: const EdgeInsets.only(top: 8, left: 12, right: 12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Column(
                          children: <Widget>[
                            SizedBox(
                              height: 100,
                              width: 100,
                              child: CachedNetworkImage(
                                  imageUrl:
                                      currentAccount?.profileInfo.townHallPic ??
                                          widget.playerStats.townHallPic),
                            ),
                            Text(
                              currentAccount?.profileInfo.name ??
                                  widget.playerStats.name,
                              style: Theme.of(context)
                                      .textTheme
                                      .labelLarge
                                      ?.copyWith(fontWeight: FontWeight.bold) ??
                                  TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              tag,
                              style: Theme.of(context).textTheme.labelLarge,
                            ),
                          ],
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Column(
                                children: <Widget>[
                                  Text(
                                    AppLocalizations.of(context)?.lastActive(
                                            (DateFormat.yMd(
                                                        userLocale.toString())
                                                    .format(DateTime
                                                        .fromMillisecondsSinceEpoch(
                                                            toDo.lastActive *
                                                                1000)))
                                                .toString()) ??
                                        'Last active: ${DateFormat('dd/MM/yy HH:mm').format(DateTime.fromMillisecondsSinceEpoch(toDo.lastActive * 1000)).toString()}',
                                    style:
                                        Theme.of(context).textTheme.labelLarge,
                                    textAlign: TextAlign.center,
                                  ),
                                  //Text(timeAgo, style: Theme.of(context).textTheme.labelLarge),
                                  SizedBox(height: 8),
                                  Wrap(
                                    alignment: WrapAlignment.start,
                                    spacing: 7.0,
                                    runSpacing: -7.0,
                                    children: <Widget>[
                                      if (toDo.legends != null ||
                                          currentAccount?.profileInfo.league ==
                                              'Legend League')
                                        Chip(
                                          avatar: CircleAvatar(
                                            backgroundColor: Colors.transparent,
                                            child: CachedNetworkImage(
                                              imageUrl:
                                                  "https://clashkingfiles.b-cdn.net/icons/Icon_HV_League_Legend_3_No_Padding.png",
                                            ),
                                          ),
                                          labelPadding: EdgeInsets.only(
                                              left: 2.0, right: 2.0),
                                          label: Text(
                                            "${toDo.legends?.numAttacks ?? 0}/8",
                                            style: Theme.of(context)
                                                .textTheme
                                                .labelLarge,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            side: BorderSide(
                                              color:
                                                  toDo.legends?.numAttacks == 8
                                                      ? Colors.green
                                                      : Colors.red,
                                              width: 1.0,
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(8.0),
                                          ),
                                        ),
                                      //Chip(
                                      //  avatar: CircleAvatar(
                                      //    backgroundColor: Colors.transparent,
                                      //    child: CachedNetworkImage(
                                      //      imageUrl: "https://clashkingfiles.b-cdn.net/icons/Icon_DC_War.png",
                                      //    ),
                                      //  ),
                                      //  labelPadding: EdgeInsets.only(left: 2.0, right: 2.0),
                                      //  label: Text(
                                      //    "2/2",
                                      //    style: Theme.of(context).textTheme.labelLarge,
                                      //  ),
                                      //),
                                      if (widget.accounts.toDoList
                                          .isInTimeFrameForClanGames)
                                        Chip(
                                          avatar: CircleAvatar(
                                            backgroundColor: Colors.transparent,
                                            child: CachedNetworkImage(
                                              imageUrl:
                                                  "https://clashkingfiles.b-cdn.net/icons/Icon_HV_Clan_Games_Medal.png",
                                            ),
                                          ),
                                          labelPadding: EdgeInsets.only(
                                              left: 2.0, right: 2.0),
                                          label: Text(
                                            toDo.clanGames.points.toString(),
                                            style: Theme.of(context)
                                                .textTheme
                                                .labelLarge,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            side: BorderSide(
                                              color:
                                                  toDo.clanGames.points == 4000
                                                      ? Colors.green
                                                      : Colors.red,
                                              width: 1.0,
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(8.0),
                                          ),
                                        ),
                                      if (widget.accounts.toDoList
                                          .isInTimeFrameForRaid)
                                        Chip(
                                          avatar: CircleAvatar(
                                            backgroundColor: Colors.transparent,
                                            child: CachedNetworkImage(
                                              imageUrl:
                                                  "https://clashkingfiles.b-cdn.net/icons/Icon_HV_Raid_Attack.png",
                                            ),
                                          ),
                                          labelPadding: EdgeInsets.only(
                                              left: 2.0, right: 2.0),
                                          label: toDo.raids.attackLimit == 0
                                              ? Text(
                                                  '0/5',
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .labelLarge,
                                                )
                                              : Text(
                                                  '${toDo.raids.attacksDone}/${toDo.raids.attackLimit}',
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .labelLarge,
                                                ),
                                          shape: RoundedRectangleBorder(
                                            side: BorderSide(
                                              color: (toDo.raids.attacksDone ==
                                                              5 &&
                                                          toDo.raids
                                                                  .attackLimit ==
                                                              5) ||
                                                      (toDo.raids.attacksDone ==
                                                              6 &&
                                                          toDo.raids
                                                                  .attackLimit ==
                                                              6)
                                                  ? Colors.green
                                                  : Colors.red,
                                              width: 1.0,
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(8.0),
                                          ),
                                        ),
                                      if (toDo.cwl.attackLimit != 0)
                                        Chip(
                                          avatar: CircleAvatar(
                                            backgroundColor: Colors.transparent,
                                            child: CachedNetworkImage(
                                              imageUrl:
                                                  "https://clashkingfiles.b-cdn.net/icons/Icon_DC_CWL_No_Border.png",
                                            ),
                                          ),
                                          labelPadding: EdgeInsets.only(
                                              left: 2.0, right: 2.0),
                                          label: Text(
                                            "${toDo.cwl.attacksDone}/${toDo.cwl.attackLimit}",
                                            style: Theme.of(context)
                                                .textTheme
                                                .labelLarge,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            side: BorderSide(
                                              color: toDo.cwl.attacksDone ==
                                                      toDo.cwl.attackLimit
                                                  ? Colors.green
                                                  : Colors.red,
                                              width: 1.0,
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(8.0),
                                          ),
                                        ),
                                      Chip(
                                        avatar: CircleAvatar(
                                          backgroundColor: Colors.transparent,
                                          child: Transform.scale(
                                            scale: 1.7,
                                            child: CachedNetworkImage(
                                              imageUrl:
                                                  "https://clashkingfiles.b-cdn.net/icons/Icon_HV_Gold_Pass.png",
                                            ),
                                          ),
                                        ),
                                        labelPadding: EdgeInsets.only(
                                            left: 2.0, right: 2.0),
                                        label: Text(
                                          toDo.seasonPass.toString(),
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelLarge,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          side: BorderSide(
                                            color: toDo.seasonPassRatio == 1
                                                ? Colors.green
                                                : Colors.red,
                                            width: 1.0,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(8.0),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        SizedBox(width: 8),
                        Container(
                          width: MediaQuery.of(context).size.width - 104,
                          height: 8,
                          decoration: BoxDecoration(
                            border: Border.all(
                                color: Colors.black.withOpacity(0.2), width: 1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: toDo.percentageDone / 100,
                              backgroundColor:
                                  Theme.of(context).scaffoldBackgroundColor,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.green),
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        Text(
                          '${toDo.percentageDone}%',
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ),
          );
        }
      }
    }

    return Column(children: [
      SizedBox(height: 8),
      /*FilterDropdown(
        sortBy: currentFilter,
        updateSortBy: updateFilter,
        sortByOptions: filterOptions,
      ),
      SizedBox(height: 8),*/
      ...cards.isEmpty && !active
          ? [
              Container(
                width: MediaQuery.of(context)
                    .size
                    .width, // Prend toute la largeur de l'écran
                margin: EdgeInsets.only(bottom: 8, left: 16, right: 16),
                child: Card(
                  margin: EdgeInsets.only(left: 16, right: 16),
                  child: Padding(
                    padding: EdgeInsets.only(left: 8, right: 8, top: 16),
                    child: Column(
                      children: [
                        Text(AppLocalizations.of(context)!.noInactiveAccounts),
                        CachedNetworkImage(
                          imageUrl:
                              'https://clashkingfiles.b-cdn.net/stickers/Villager_BB_Master_Builder_7.png',
                          width: 200,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ]
          : cards,
    ]);
  }
}
