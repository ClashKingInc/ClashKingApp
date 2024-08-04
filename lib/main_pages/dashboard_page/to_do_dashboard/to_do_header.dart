import 'package:clashkingapp/classes/account/accounts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:ui';

class ToDoHeader extends StatefulWidget {
  final Accounts accounts;

  ToDoHeader({super.key, required this.accounts});

  @override
  ToDoHeaderState createState() => ToDoHeaderState();
}

class ToDoHeaderState extends State<ToDoHeader> {
  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          height: 240,
          width: double.infinity,
          child: ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 1, sigmaY: 1),
            child: ColorFiltered(
                colorFilter: ColorFilter.mode(
                  Colors.black.withOpacity(0.7),
                  BlendMode.darken,
                ),
                child: CachedNetworkImage(
                  imageUrl:
                      "https://clashkingfiles.b-cdn.net/landscape/todo-landscape.png",
                  width: double.infinity,
                  fit: BoxFit.cover,
                )),
          ),
        ),
        Column(
          children: [
            Text(
                AppLocalizations.of(context)!
                    .numberAccounts(widget.accounts.toDoList.numberAccounts),
                style: Theme.of(context).textTheme.titleMedium),
            Text(
                AppLocalizations.of(context)!.numberActiveAccounts(
                    widget.accounts.toDoList.numberActiveAccounts),
                style: Theme.of(context).textTheme.labelLarge),
            Text(
                AppLocalizations.of(context)!.numberInactiveAccounts(
                    widget.accounts.toDoList.numberInactiveAccounts),
                style: Theme.of(context).textTheme.labelLarge),
            SizedBox(height: 16),
            Wrap(
              alignment: WrapAlignment.start,
              spacing: 7.0,
              runSpacing: -7.0,
              children: <Widget>[
                if (widget.accounts.toDoList.requiredLegendsAttacks != 0)
                  Chip(
                    avatar: CircleAvatar(
                      backgroundColor: Colors.transparent,
                      child: CachedNetworkImage(
                        imageUrl:
                            "https://clashkingfiles.b-cdn.net/icons/Icon_HV_League_Legend_3_No_Padding.png",
                      ),
                    ),
                    labelPadding: EdgeInsets.only(left: 2.0, right: 2.0),
                    label: Text(
                      "${widget.accounts.toDoList.totalLegends}/${widget.accounts.toDoList.requiredLegendsAttacks}",
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    shape: RoundedRectangleBorder(
                      side: BorderSide(
                        color: widget.accounts.toDoList.totalCwlAttacks ==
                                widget.accounts.toDoList.requiredCwlAttacks
                            ? Colors.green
                            : Colors.red,
                        width: 1.0,
                      ),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                if (widget.accounts.toDoList.requiredWarAttacks != 0)
                  Chip(
                    avatar: CircleAvatar(
                      backgroundColor: Colors.transparent,
                      child: CachedNetworkImage(
                        imageUrl:
                            "https://clashkingfiles.b-cdn.net/icons/Icon_DC_War.png",
                      ),
                    ),
                    labelPadding: EdgeInsets.only(left: 2.0, right: 2.0),
                    label: Text(
                      "${widget.accounts.toDoList.totalWarAttacks}/${widget.accounts.toDoList.requiredWarAttacks}",
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    shape: RoundedRectangleBorder(
                      side: BorderSide(
                        color: widget.accounts.toDoList.totalWarAttacks ==
                                widget.accounts.toDoList.requiredWarAttacks
                            ? Colors.green
                            : Colors.red,
                        width: 1.0,
                      ),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                if (widget.accounts.toDoList.isInTimeFrameForClanGames)
                  Chip(
                    avatar: CircleAvatar(
                      backgroundColor: Colors.transparent,
                      child: CachedNetworkImage(
                        imageUrl:
                            "https://clashkingfiles.b-cdn.net/icons/Icon_HV_Clan_Games_Medal.png",
                      ),
                    ),
                    labelPadding: EdgeInsets.only(left: 2.0, right: 2.0),
                    label: Text(
                      widget.accounts.toDoList.totalClanGamesPoints.toString(),
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    shape: RoundedRectangleBorder(
                      side: BorderSide(
                        color: widget.accounts.toDoList.totalClanGamesPoints ==
                                widget.accounts.toDoList.requiredClanGamesPoints
                            ? Colors.green
                            : Colors.red,
                        width: 1.0,
                      ),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                if (widget.accounts.toDoList.isInTimeFrameForRaid)
                  Chip(
                    avatar: CircleAvatar(
                      backgroundColor: Colors.transparent,
                      child: CachedNetworkImage(
                        imageUrl:
                            "https://clashkingfiles.b-cdn.net/icons/Icon_HV_Raid_Attack.png",
                      ),
                    ),
                    labelPadding: EdgeInsets.only(left: 2.0, right: 2.0),
                    label: widget.accounts.toDoList.requiredRaidsAttacks != 0
                        ? Text(
                            '${widget.accounts.toDoList.totalRaidsAttacks}/${widget.accounts.toDoList.requiredRaidsAttacks}',
                            style: Theme.of(context).textTheme.labelLarge,
                          )
                        : Text(
                            '0/?',
                            style: Theme.of(context).textTheme.labelLarge,
                          ),
                    shape: RoundedRectangleBorder(
                      side: BorderSide(
                        color: (widget.accounts.toDoList.totalRaidsAttacks ==
                                widget.accounts.toDoList.requiredRaidsAttacks)
                            ? Colors.green
                            : Colors.red,
                        width: 1.0,
                      ),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                if (widget.accounts.toDoList.requiredCwlAttacks > 1)
                  Chip(
                    avatar: CircleAvatar(
                      backgroundColor: Colors.transparent,
                      child: CachedNetworkImage(
                        imageUrl:
                            "https://clashkingfiles.b-cdn.net/icons/Icon_DC_CWL_No_Border.png",
                      ),
                    ),
                    labelPadding: EdgeInsets.only(left: 2.0, right: 2.0),
                    label: Text(
                      '${widget.accounts.toDoList.totalCwlAttacks}/${widget.accounts.toDoList.requiredCwlAttacks}',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    shape: RoundedRectangleBorder(
                      side: BorderSide(
                        color: (widget.accounts.toDoList.totalCwlAttacks ==
                                widget.accounts.toDoList.requiredCwlAttacks)
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
                  labelPadding: EdgeInsets.only(left: 2.0, right: 2.0),
                  label: Text(
                    widget.accounts.toDoList.totalSeasonPass.toString(),
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  shape: RoundedRectangleBorder(
                    side: BorderSide(
                      color: (widget.accounts.toDoList.totalSeasonPass ==
                              widget.accounts.toDoList.requiredSeasonPass)
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
        Positioned(
          bottom: 10,
          left: 20,
          right: 20,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Row(
                children: [
                  SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      height: 8,
                      decoration: BoxDecoration(
                        border: Border.all(
                            color: Colors.black.withOpacity(0.2), width: 1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: widget.accounts.toDoList.percentageDone / 100,
                          backgroundColor:
                              Theme.of(context).scaffoldBackgroundColor,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.green),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  Text(
                    '${widget.accounts.toDoList.percentageDone}%',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ],
              )
            ],
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
    );
  }
}
