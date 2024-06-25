import 'dart:ui';
import 'package:clashkingapp/classes/account/accounts.dart';
import 'package:clashkingapp/classes/profile/to_do.dart';
import 'package:clashkingapp/components/filter_dropdown.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:clashkingapp/classes/profile/profile_info.dart';

class ToDoScreen extends StatefulWidget {
  final ProfileInfo playerStats;
  final List<String> tags;
  final bool isInTimeFrameForRaid;
  final bool isInTimeFrameForClanGames;
  final PlayerToDoData data;
  final Accounts accounts;

  ToDoScreen(
      {super.key,
      required this.playerStats,
      required this.tags,
      required this.isInTimeFrameForRaid,
      required this.isInTimeFrameForClanGames,
      required this.data,
      required this.accounts});

  @override
  ToDoScreenState createState() => ToDoScreenState();
}

class ToDoScreenState extends State<ToDoScreen>
    with SingleTickerProviderStateMixin {
  String currentFilter = 'all';
  String backgroundImageUrl = 'https://clashkingfiles.b-cdn.net/landscape/Villager_HV_Builder_19.png';

  @override
  void initState() {
    super.initState();
  }

  void updateFilter(String newFilter) {
    setState(() {
      currentFilter = newFilter;
    });
  }

  Widget filterContent() {
    switch (currentFilter) {
      case 'all':
        return _contentForAll();
      case 'byEvent':
        return _contentForByEvent();
      default:
        return _contentForTag(currentFilter);
    }
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
      finalDiff += AppLocalizations.of(context)?.hoursAgo(hours) ?? "$hours hours";
      if (minutes > 0) finalDiff += ' ${minutes}m';
    } else if (minutes > 0) {
      finalDiff += AppLocalizations.of(context)?.minutesAgo(minutes) ?? "$minutes minutes";
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
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.bottomCenter,
              children: <Widget>[
                Container(
                  height: 220,
                  width: double.infinity,
                  color: Colors.black.withOpacity(0.3),
                ),
                SizedBox(
                  height: 150,
                  width: double.infinity,
                  child: ImageFiltered(
                    imageFilter: ImageFilter.blur(sigmaX: 0, sigmaY: 0),
                    child: ColorFiltered(
                      colorFilter: ColorFilter.mode(
                        Colors.black.withOpacity(0),
                        BlendMode.darken,
                      ),
                      child: CachedNetworkImage(
                        imageUrl: backgroundImageUrl,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 130,
                  child: Text(
                    AppLocalizations.of(context)?.toDoList ?? 'To Do List',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: Colors.white),
                  ),
                ),
                Positioned(
                  top: 30,
                  left: 10,
                  child: IconButton(
                    icon: Icon(
                      Icons.arrow_back,
                      color: Theme.of(context).colorScheme.onPrimary,
                      size: 32,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            FilterDropdown(
              sortBy: currentFilter,
              updateSortBy: updateFilter,
              sortByOptions: filterOptions,
            ),
            filterContent(),
            SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _contentForAll() {
    List<Widget> cards = [];

    for (var tag in widget.tags) {
      for (var playerData in widget.data.items.where((item) => item.playerTag == tag)) {
        int totalDone = 0;
        int totalEvent = 0;
        Account? currentAccount = widget.accounts.findAccountByTag(playerData.playerTag);
        //int time = playerData.lastActive;
        //String timeAgo = convertToExactTime(time, context);

        //Legend compléted
        if (playerData.legends != null) {
          totalEvent++;
          if (playerData.legends!.numAttacks == 8) {
            totalDone++;
          }
        }

        //clan games completed
        if (widget.isInTimeFrameForClanGames) {
          totalEvent++;
          if (playerData.clanGames.points >= 4000) {
            totalDone++;
          }
        }

        //raids completed
        if (widget.isInTimeFrameForRaid) {
          totalEvent++;
          if ((playerData.raids.attacksDone == 5 && playerData.raids.attackLimit == 5) || (playerData.raids.attacksDone == 6 && playerData.raids.attackLimit == 6)) {
            totalDone++;
          }
        }

        //season pass completed
        totalEvent++;
        if (playerData.seasonPass >= 2600) {
          totalDone++;
        }

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
                            child: CachedNetworkImage(imageUrl: currentAccount?.profileInfo.townHallPic ?? widget.playerStats.townHallPic),
                          ),
                          Text(
                            currentAccount?.profileInfo.name ?? widget.playerStats.name,
                            style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold) ??
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
                                  AppLocalizations.of(context)?.lastActive((DateFormat('dd/MM/yy HH:mm').format(DateTime.fromMillisecondsSinceEpoch(playerData.lastActive * 1000))).toString()) ?? 'Last active: ${DateFormat('dd/MM/yy HH:mm').format(DateTime.fromMillisecondsSinceEpoch(playerData.lastActive * 1000)).toString()}',
                                  style: Theme.of(context).textTheme.labelLarge,
                                  textAlign: TextAlign.center,
                                ),
                                //Text(timeAgo, style: Theme.of(context).textTheme.labelLarge),
                                SizedBox(height: 8),
                                Wrap(
                                  alignment: WrapAlignment.start,
                                  spacing: 7.0,
                                  runSpacing: -7.0,
                                  children: <Widget>[
                                    if (playerData.legends != null || currentAccount?.profileInfo.league == 'Legend League')
                                      Chip(
                                        avatar: CircleAvatar(
                                          backgroundColor: Colors.transparent,
                                          child: CachedNetworkImage(
                                            imageUrl: "https://clashkingfiles.b-cdn.net/icons/Icon_HV_League_Legend_3_No_Padding.png",
                                          ),
                                        ),
                                        labelPadding: EdgeInsets.only(left: 2.0, right: 2.0),
                                        label: Text(
                                          "${playerData.legends?.numAttacks ?? 0}/8",
                                          style: Theme.of(context).textTheme.labelLarge,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          side: BorderSide(
                                            color: playerData.legends?.numAttacks == 8 ? Colors.green : Colors.red,
                                            width: 1.0,
                                          ),
                                          borderRadius: BorderRadius.circular(8.0),
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
                                    if (widget.isInTimeFrameForClanGames)
                                      Chip(
                                        avatar: CircleAvatar(
                                          backgroundColor: Colors.transparent,
                                          child: CachedNetworkImage(
                                            imageUrl: "https://clashkingfiles.b-cdn.net/icons/Icon_HV_Clan_Games_Medal.png",
                                          ),
                                        ),
                                        labelPadding: EdgeInsets.only(left: 2.0, right: 2.0),
                                        label: Text(
                                          playerData.clanGames.points.toString(),
                                          style: Theme.of(context).textTheme.labelLarge,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          side: BorderSide(
                                            color: playerData.clanGames.points == 4000 ? Colors.green : Colors.red,
                                            width: 1.0,
                                          ),
                                          borderRadius: BorderRadius.circular(8.0),
                                        ),
                                      ),
                                    if (widget.isInTimeFrameForRaid)
                                      Chip(
                                        avatar: CircleAvatar(
                                          backgroundColor: Colors.transparent,
                                          child: CachedNetworkImage(
                                            imageUrl: "https://clashkingfiles.b-cdn.net/icons/Icon_HV_Raid_Attack.png",
                                          ),
                                        ),
                                        labelPadding: EdgeInsets.only(left: 2.0, right: 2.0),
                                        label: playerData.raids.attackLimit == 0
                                          ? Text(
                                              '0/5',
                                              style: Theme.of(context).textTheme.labelLarge,
                                            )
                                          : Text(
                                              '${playerData.raids.attacksDone}/${playerData.raids.attackLimit}',
                                              style: Theme.of(context).textTheme.labelLarge,
                                            ),
                                        shape: RoundedRectangleBorder(
                                          side: BorderSide(
                                            color: 
                                              (playerData.raids.attacksDone == 5 && playerData.raids.attackLimit == 5) 
                                                || (playerData.raids.attacksDone == 6 && playerData.raids.attackLimit == 6)
                                                ? Colors.green
                                                : Colors.red,
                                            width: 1.0,
                                          ),
                                          borderRadius: BorderRadius.circular(8.0),
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
                                    //    "1/1",
                                    //    style: Theme.of(context).textTheme.labelLarge,
                                    //  ),
                                    //),
                                    Chip(
                                      avatar: CircleAvatar(
                                        backgroundColor: Colors.transparent,
                                        child: Transform.scale(
                                          scale: 1.7,
                                          child: CachedNetworkImage(
                                            imageUrl: "https://clashkingfiles.b-cdn.net/icons/Icon_HV_Gold_Pass.png",
                                          ),
                                        ),
                                      ),
                                      labelPadding: EdgeInsets.only(left: 2.0, right: 2.0),
                                      label: Text(
                                        playerData.seasonPass.toString(),
                                        style: Theme.of(context).textTheme.labelLarge,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        side: BorderSide(
                                          color: playerData.seasonPass >= 2600 ? Colors.green : Colors.red,
                                          width: 1.0,
                                        ),
                                        borderRadius: BorderRadius.circular(8.0),
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
                              color: Colors.black.withOpacity(0.2),
                              width: 1), // Border color and width
                          borderRadius: BorderRadius.circular(4), 
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: totalDone / totalEvent,
                            backgroundColor:
                                Theme.of(context).scaffoldBackgroundColor,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.green),
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      Text(
                        '${((totalDone / totalEvent) * 100).toStringAsFixed(0).padLeft(3, ' ')}%',
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

    return Column(
      children: cards,
    );
  }

  Widget _contentForByEvent() {
    return Padding(
      padding: const EdgeInsets.only(top: 6, left: 8, right: 8, bottom: 16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Center(child: Text('Afficher par événement')),
        ),
      ),
    );
  }

  Widget _contentForTag(String tag) {
    return Padding(
      padding: const EdgeInsets.only(top: 6, left: 8, right: 8, bottom: 16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: Center(
              child: Text('Afficher pour le tag: $tag'),
            ),
          ),
        ),
      ),
    );
  }
}
