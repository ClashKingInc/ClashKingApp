import 'package:clashkingapp/classes/account/accounts.dart';
import 'package:flutter/material.dart';
import 'package:clashkingapp/classes/profile/profile_info.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:clashkingapp/main_pages/dashboard_page/to_do_dashboard/to_do_page.dart';
import 'package:clashkingapp/main_pages/beta_label.dart';

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
                accounts: widget.accounts),
          ),
        );
      },
      child: Stack(
        children: [
          DefaultTextStyle(
            style: Theme.of(context).textTheme.labelLarge ?? TextStyle(),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.only(
                    left: 16, right: 16, top: 16, bottom: 8),
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
                                style:
                                    (Theme.of(context).textTheme.labelLarge)),
                            SizedBox(height: 12),
                            SizedBox(
                              height: 90,
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
                              iconToDo(widget.playerStats),
                              if (widget.playerStats.toDo != null)
                                  Row(
                                      children: [
                                        SizedBox(width: 8),
                                        Expanded(
                                          child: Container(
                                            height: 8,
                                            decoration: BoxDecoration(
                                              border: Border.all(
                                                  color: Colors.black
                                                      .withOpacity(0.2),
                                                  width: 1),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                              child: LinearProgressIndicator(
                                                value: widget.playerStats.toDo!
                                                        .percentageDone /
                                                    100,
                                                backgroundColor: Theme.of(
                                                        context)
                                                    .scaffoldBackgroundColor,
                                                valueColor:
                                                    AlwaysStoppedAnimation<
                                                        Color>(Colors.green),
                                              ),
                                            ),
                                          ),
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          '${widget.playerStats.toDo!.percentageDone}%',
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelLarge,
                                        ),
                                      ],
                                    )
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          BetaLabel()
        ],
      ),
    );
  }

  Widget iconToDo(ProfileInfo profileInfo) {
    final int lastActiveTimestamp = profileInfo.toDo!.lastActive;
    final Locale userLocale = Localizations.localeOf(context);
    String formattedDate = DateFormat.yMd(userLocale.toString())
        .format(
            DateTime.fromMillisecondsSinceEpoch(lastActiveTimestamp * 1000));

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
                        AppLocalizations.of(context)
                                ?.lastActive((formattedDate)) ??
                            'Last active: $formattedDate',
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
                          if (profileInfo.toDo!.legends != null ||
                              profileInfo.league == 'Legend League')
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
                                "${profileInfo.toDo!.legends?.numAttacks ?? 0}/8",
                                style: Theme.of(context).textTheme.labelLarge,
                              ),
                              shape: RoundedRectangleBorder(
                                side: BorderSide(
                                  color:
                                      profileInfo.toDo!.legends?.numAttacks == 8
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
                          if (profileInfo.toDo!.isInTimeFrameForClanGames)
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
                                profileInfo.toDo!.clanGames.points.toString(),
                                style: Theme.of(context).textTheme.labelLarge,
                              ),
                              shape: RoundedRectangleBorder(
                                side: BorderSide(
                                  color:
                                      profileInfo.toDo!.clanGames.points == 4000
                                          ? Colors.green
                                          : Colors.red,
                                  width: 1.0,
                                ),
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                            ),
                          if (profileInfo.toDo!.isInTimeFrameForRaid)
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
                              label: profileInfo.toDo!.raids.attackLimit == 0
                                  ? Text(
                                      '0/5',
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelLarge,
                                    )
                                  : Text(
                                      '${profileInfo.toDo! .raids.attacksDone}/${profileInfo.toDo!.raids.attackLimit}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelLarge,
                                    ),
                              shape: RoundedRectangleBorder(
                                side: BorderSide(
                                  color: (profileInfo.toDo!.raids.attacksDone ==
                                                  5 &&
                                              profileInfo.toDo!.raids
                                                      .attackLimit ==
                                                  5) ||
                                          (profileInfo.toDo!.raids
                                                      .attacksDone ==
                                                  6 &&
                                              profileInfo.toDo!.raids
                                                      .attackLimit ==
                                                  6)
                                      ? Colors.green
                                      : Colors.red,
                                  width: 1.0,
                                ),
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                            ),
                          if (widget.playerStats.toDo!.cwl.attackLimit > 0)
                              Chip(
                                  avatar: CircleAvatar(
                                    backgroundColor: Colors.transparent,
                                    child: CachedNetworkImage(
                                      imageUrl:
                                          "https://clashkingfiles.b-cdn.net/icons/Icon_DC_CWL_No_Border.png",
                                    ),
                                  ),
                                  labelPadding:
                                      EdgeInsets.only(left: 2.0, right: 2.0),
                                  label: Text(
                                    '${widget.playerStats.toDo!.cwl.attacksDone}/${widget.playerStats.toDo!.cwl.attackLimit}',
                                    style:
                                        Theme.of(context).textTheme.labelLarge,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    side: BorderSide(
                                      color: (profileInfo.toDo!.cwl.attacksDone == profileInfo.toDo!.cwl.attackLimit)
                                          ? Colors.green
                                          : Colors.red,
                                      width: 1.0,
                                    ),
                                    borderRadius: BorderRadius.circular(8.0),
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
                            labelPadding:
                                EdgeInsets.only(left: 2.0, right: 2.0),
                            label: Text(
                              profileInfo.toDo!.seasonPass.toString(),
                              style: Theme.of(context).textTheme.labelLarge,
                            ),
                            shape: RoundedRectangleBorder(
                              side: BorderSide(
                                color: profileInfo.toDo!.seasonPassRatio == 1
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
}
