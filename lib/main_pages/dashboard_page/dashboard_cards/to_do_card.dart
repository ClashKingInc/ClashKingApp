import 'package:clashkingapp/classes/account/accounts.dart';
import 'package:flutter/material.dart';
import 'package:clashkingapp/classes/profile/profile_info.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:clashkingapp/classes/profile/todo/to_do_list.dart';
import 'package:intl/intl.dart';
import 'package:clashkingapp/main_pages/dashboard_page/to_do_dashboard/to_do_page.dart';

class ToDoCard extends StatefulWidget {
  const ToDoCard({
    super.key,
    required this.playerStats,
    required this.tags,
    required this.accounts,
  });

  final ProfileInfo playerStats;
  final List<String> tags;
  final Accounts accounts;

  @override
  ToDoCardState createState() => ToDoCardState();
}

class ToDoCardState extends State<ToDoCard> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ToDoScreen(
                playerStats: widget.playerStats,
                tags: widget.tags,
                isInTimeFrameForRaid: widget.accounts.toDoList.isInTimeFrameForRaid,
                isInTimeFrameForClanGames: widget.accounts.toDoList.isInTimeFrameForClanGames,
                data: widget.accounts.toDoList,
                accounts: widget.accounts),
          ),
        );
      },
      child: DefaultTextStyle(
        style: Theme.of(context).textTheme.labelLarge ?? TextStyle(),
        child: Card(
          child: Padding(
            padding:
                const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Column(
                      children: <Widget>[
                        Text(
                          AppLocalizations.of(context)?.toDoList ??
                              'To Do List',
                          style: (Theme.of(context)
                                  .textTheme
                                  .labelLarge)
                        ),
                        SizedBox(height: 12),
                        SizedBox(
                          height: 100,
                          width: 100,
                          child: CachedNetworkImage(
                              imageUrl:
                                  'https://clashkingfiles.b-cdn.net/icons/Magic_Item_Builder_Potion.png'),
                        ),
                      ],
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: <Widget>[
                          iconToDo(widget.accounts.toDoList, widget.accounts.toDoList.isInTimeFrameForRaid,
                              widget.accounts.toDoList.isInTimeFrameForClanGames)
                        ],
                      ),
                    ),
                  ],
                ),
                //Row(
                //  children: [
                //    SizedBox(width: 8),
                //    Container(
                //      width: MediaQuery.of(context).size.width - 104,
                //      height: 8,
                //      decoration: BoxDecoration(
                //        border: Border.all(
                //          color: Colors.black.withOpacity(0.2),
                //          width: 1),
                //        borderRadius: BorderRadius.circular(4),
                //      ),
                //      child: ClipRRect(
                //        borderRadius: BorderRadius.circular(4),
                //        child: LinearProgressIndicator(
                //          value: totalDone / totalEvent,
                //          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                //          valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                //        ),
                //      ),
                //    ),
                //    SizedBox(width: 8),
                //    Text(
                //      '${((totalDone / totalEvent) * 100).toStringAsFixed(0).padLeft(3, ' ')}%',
                //      style: Theme.of(context).textTheme.labelLarge,
                //    ),
                //  ],
                //),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget iconToDo(ToDoList data, bool isInTimeFrameForRaid,
      bool isInTimeFrameForClanGames) {
    for (var playerData in data.items
        .where((item) => item.playerTag == widget.playerStats.tag)) {
      Account? currentAccount =
          widget.accounts.findAccountByTag(playerData.playerTag);

      //Legend compléted
      //if (playerData.legends != null) {
      //  totalEvent++;
      //  if (playerData.legends!.numAttacks == 8) {
      //    totalDone++;
      //  }
      //}

      //clan games completed
      //if (isInTimeFrameForClanGames) {
      //  totalEvent++;
      //  if (playerData.clanGames.points >= 4000) {
      //    totalDone++;
      //  }
      //}

      //raids completed
      //if (isInTimeFrameForRaid) {
      //  totalEvent++;
      //  if ((playerData.raids.attacksDone == 5 && playerData.raids.attackLimit == 5) || (playerData.raids.attacksDone == 6 && playerData.raids.attackLimit == 6)) {
      //    totalDone++;
      //  }
      //}

      //season pass completed
      //totalEvent++;
      //if (playerData.seasonPass >= 2600) {
      //  totalDone++;
      //}

      return Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Column(
                      children: <Widget>[
                        Text(
                          AppLocalizations.of(context)?.lastActive(
                                  (DateFormat('dd/MM/yy HH:mm').format(
                                          DateTime.fromMillisecondsSinceEpoch(
                                              playerData.lastActive * 1000)))
                                      .toString()) ??
                              'Last active: ${DateFormat('dd/MM/yy HH:mm').format(DateTime.fromMillisecondsSinceEpoch(playerData.lastActive * 1000)).toString()}',
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
                            if (playerData.legends != null ||
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
                                labelPadding:
                                    EdgeInsets.only(left: 2.0, right: 2.0),
                                label: Text(
                                  "${playerData.legends?.numAttacks ?? 0}/8",
                                  style: Theme.of(context).textTheme.labelLarge,
                                ),
                                shape: RoundedRectangleBorder(
                                  side: BorderSide(
                                    color: playerData.legends?.numAttacks == 8
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
                            //    "2/2",
                            //    style: Theme.of(context).textTheme.labelLarge,
                            //  ),
                            //),
                            if (isInTimeFrameForClanGames)
                              Chip(
                                avatar: CircleAvatar(
                                  backgroundColor: Colors.transparent,
                                  child: CachedNetworkImage(
                                    imageUrl:
                                        "https://clashkingfiles.b-cdn.net/icons/Icon_HV_Clan_Games_Medal.png",
                                  ),
                                ),
                                labelPadding:
                                    EdgeInsets.only(left: 2.0, right: 2.0),
                                label: Text(
                                  playerData.clanGames.points.toString(),
                                  style: Theme.of(context).textTheme.labelLarge,
                                ),
                                shape: RoundedRectangleBorder(
                                  side: BorderSide(
                                    color: playerData.clanGames.points == 4000
                                        ? Colors.green
                                        : Colors.red,
                                    width: 1.0,
                                  ),
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                              ),
                            if (isInTimeFrameForRaid)
                              Chip(
                                avatar: CircleAvatar(
                                  backgroundColor: Colors.transparent,
                                  child: CachedNetworkImage(
                                    imageUrl:
                                        "https://clashkingfiles.b-cdn.net/icons/Icon_HV_Raid_Attack.png",
                                  ),
                                ),
                                labelPadding:
                                    EdgeInsets.only(left: 2.0, right: 2.0),
                                label: playerData.raids.attackLimit == 0
                                    ? Text(
                                        '0/5',
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelLarge,
                                      )
                                    : Text(
                                        '${playerData.raids.attacksDone}/${playerData.raids.attackLimit}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelLarge,
                                      ),
                                shape: RoundedRectangleBorder(
                                  side: BorderSide(
                                    color: (playerData.raids.attacksDone == 5 &&
                                                playerData.raids.attackLimit ==
                                                    5) ||
                                            (playerData.raids.attacksDone ==
                                                    6 &&
                                                playerData.raids.attackLimit ==
                                                    6)
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
                                    imageUrl:
                                        "https://clashkingfiles.b-cdn.net/icons/Icon_HV_Gold_Pass.png",
                                  ),
                                ),
                              ),
                              labelPadding:
                                  EdgeInsets.only(left: 2.0, right: 2.0),
                              label: Text(
                                playerData.seasonPass.toString(),
                                style: Theme.of(context).textTheme.labelLarge,
                              ),
                              shape: RoundedRectangleBorder(
                                side: BorderSide(
                                  color: playerData.seasonPass >= 2600
                                      ? Colors.green
                                      : Colors.red,
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
        ],
      );
    }
    return SizedBox.shrink();
  }
}
