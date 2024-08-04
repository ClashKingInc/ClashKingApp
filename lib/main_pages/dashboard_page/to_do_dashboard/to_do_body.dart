import 'package:clashkingapp/classes/account/accounts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';

class ToDoBody extends StatefulWidget {
  final Accounts accounts;
  final Map<String, String> filterOptions;
  final bool active;
  final List<String> tags;

  ToDoBody(
      {super.key,
      required this.filterOptions,
      required this.active,
      required this.tags,
      required this.accounts});

  @override
  ToDoBodyState createState() => ToDoBodyState();
}

class ToDoBodyState extends State<ToDoBody> {
  @override
  Widget build(BuildContext context) {
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

        if ((widget.active && daysDiff <= 14) ||
            (!widget.active && daysDiff > 14)) {
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
                                      currentAccount!.profileInfo.townHallPic),
                            ),
                            Text(
                              currentAccount.profileInfo.name,
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
                                          currentAccount.profileInfo.league ==
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
      ...cards.isEmpty && !widget.active
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
