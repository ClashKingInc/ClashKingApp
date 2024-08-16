import 'package:clashkingapp/classes/profile/profile_info.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:clashkingapp/classes/profile/todo/to_do.dart';

class ToDoBodyCard extends StatefulWidget {
  final ProfileInfo profileInfo;
  final ToDo toDo;
  final String tag;

  ToDoBodyCard(
      {super.key,
      required this.tag,
      required this.profileInfo,
      required this.toDo});

  @override
  ToDoBodyCardState createState() => ToDoBodyCardState();
}

class ToDoBodyCardState extends State<ToDoBodyCard> {
  @override
  Widget build(BuildContext context) {
    final Locale userLocale = Localizations.localeOf(context);
    return Card(
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
                          imageUrl: widget.profileInfo.townHallPic),
                    ),
                    Text(
                      widget.profileInfo.name,
                      style: Theme.of(context)
                              .textTheme
                              .labelLarge
                              ?.copyWith(fontWeight: FontWeight.bold) ??
                          TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      widget.tag,
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
                            AppLocalizations.of(context)?.lastActive((DateFormat
                                            .yMd(userLocale.toString())
                                        .format(
                                            DateTime.fromMillisecondsSinceEpoch(
                                                widget.toDo.lastActive * 1000)))
                                    .toString()) ??
                                'Last active: ${DateFormat('dd/MM/yy HH:mm').format(DateTime.fromMillisecondsSinceEpoch(widget.toDo.lastActive * 1000)).toString()}',
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
                              if (widget.toDo.legends != null ||
                                  widget.profileInfo.league == 'Legend League')
                                Chip(
                                  avatar: CircleAvatar(
                                    backgroundColor: Colors.transparent,
                                    child: CachedNetworkImage(
                                      imageUrl:
                                          "https://assets.clashk.ing/icons/Icon_HV_League_Legend_3_No_Padding.png",
                                    ),
                                  ),
                                  labelPadding:
                                      EdgeInsets.only(left: 2.0, right: 2.0),
                                  label: Text(
                                    "${widget.toDo.legends?.numAttacks ?? 0}/8",
                                    style:
                                        Theme.of(context).textTheme.labelLarge,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    side: BorderSide(
                                      color:
                                          widget.toDo.legends?.numAttacks == 8
                                              ? Colors.green
                                              : Colors.red,
                                      width: 1.0,
                                    ),
                                    borderRadius: BorderRadius.circular(8.0),
                                  ),
                                ),
                              if (widget.toDo.war != null &&
                                  widget.toDo.war!.attackLimit != 0)
                                Chip(
                                  avatar: CircleAvatar(
                                    backgroundColor: Colors.transparent,
                                    child: CachedNetworkImage(
                                      imageUrl:
                                          "https://assets.clashk.ing/icons/Icon_DC_War.png",
                                    ),
                                  ),
                                  labelPadding:
                                      EdgeInsets.only(left: 2.0, right: 2.0),
                                  label: Text(
                                    "${widget.toDo.war!.attacksDone}/${widget.toDo.war!.attackLimit}",
                                    style:
                                        Theme.of(context).textTheme.labelLarge,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    side: BorderSide(
                                      color: widget.toDo.war!.attackLimit ==
                                              widget.toDo.war!.attacksDone
                                          ? Colors.green
                                          : Colors.red,
                                      width: 1.0,
                                    ),
                                    borderRadius: BorderRadius.circular(8.0),
                                  ),
                                ),
                              if (widget.toDo.isInTimeFrameForClanGames)
                                Chip(
                                  avatar: CircleAvatar(
                                    backgroundColor: Colors.transparent,
                                    child: CachedNetworkImage(
                                      imageUrl:
                                          "https://assets.clashk.ing/icons/Icon_HV_Clan_Games_Medal.png",
                                    ),
                                  ),
                                  labelPadding:
                                      EdgeInsets.only(left: 2.0, right: 2.0),
                                  label: Text(
                                    NumberFormat(
                                            '#,###',
                                            Localizations.localeOf(context)
                                                .toString())
                                        .format(widget.toDo.clanGames.points),
                                    style:
                                        Theme.of(context).textTheme.labelLarge,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    side: BorderSide(
                                      color:
                                          widget.toDo.clanGames.points == 4000
                                              ? Colors.green
                                              : Colors.red,
                                      width: 1.0,
                                    ),
                                    borderRadius: BorderRadius.circular(8.0),
                                  ),
                                ),
                              if (widget.toDo.isInTimeFrameForRaid)
                                Chip(
                                  avatar: CircleAvatar(
                                    backgroundColor: Colors.transparent,
                                    child: CachedNetworkImage(
                                      imageUrl:
                                          "https://assets.clashk.ing/icons/Icon_HV_Raid_Attack.png",
                                    ),
                                  ),
                                  labelPadding:
                                      EdgeInsets.only(left: 2.0, right: 2.0),
                                  label: widget.toDo.raids.attackLimit == 0
                                      ? Text(
                                          '0/5',
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelLarge,
                                        )
                                      : Text(
                                          '${widget.toDo.raids.attacksDone}/${widget.toDo.raids.attackLimit}',
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelLarge,
                                        ),
                                  shape: RoundedRectangleBorder(
                                    side: BorderSide(
                                      color: (widget.toDo.raids.attacksDone ==
                                                      5 &&
                                                  widget.toDo.raids
                                                          .attackLimit ==
                                                      5) ||
                                              (widget.toDo.raids.attacksDone ==
                                                      6 &&
                                                  widget.toDo.raids
                                                          .attackLimit ==
                                                      6)
                                          ? Colors.green
                                          : Colors.red,
                                      width: 1.0,
                                    ),
                                    borderRadius: BorderRadius.circular(8.0),
                                  ),
                                ),
                              if (widget.toDo.cwl.attackLimit != 0)
                                Chip(
                                  avatar: CircleAvatar(
                                    backgroundColor: Colors.transparent,
                                    child: CachedNetworkImage(
                                      imageUrl:
                                          "https://assets.clashk.ing/icons/Icon_DC_CWL_No_Border.png",
                                    ),
                                  ),
                                  labelPadding:
                                      EdgeInsets.only(left: 2.0, right: 2.0),
                                  label: Text(
                                    "${widget.toDo.cwl.attacksDone}/${widget.toDo.cwl.attackLimit}",
                                    style:
                                        Theme.of(context).textTheme.labelLarge,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    side: BorderSide(
                                      color: widget.toDo.cwl.attacksDone ==
                                              widget.toDo.cwl.attackLimit
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
                                          "https://assets.clashk.ing/icons/Icon_HV_Gold_Pass.png",
                                    ),
                                  ),
                                ),
                                labelPadding:
                                    EdgeInsets.only(left: 2.0, right: 2.0),
                                label: Text(
                                  NumberFormat(
                                          '#,###',
                                          Localizations.localeOf(context)
                                              .toString())
                                      .format(widget.toDo.seasonPass),
                                  style: Theme.of(context).textTheme.labelLarge,
                                ),
                                shape: RoundedRectangleBorder(
                                  side: BorderSide(
                                    color: widget.toDo.seasonPassRatio == 1
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
            Row(
              children: [
                SizedBox(width: 8),
                Container(
                  width: MediaQuery.of(context).size.width - 116,
                  height: 8,
                  decoration: BoxDecoration(
                    border: Border.all(
                        color: Colors.black.withOpacity(0.2), width: 1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: widget.toDo.percentageDone / 100,
                      backgroundColor:
                          Theme.of(context).scaffoldBackgroundColor,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Text(
                  '${widget.toDo.percentageDone}%',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
