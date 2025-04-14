import 'package:clashkingapp/common/widgets/mobile_web_image.dart';
import 'package:clashkingapp/core/constants/image_assets.dart';
import 'package:clashkingapp/core/functions.dart';
import 'package:clashkingapp/features/coc_accounts/data/coc_account_service.dart';
import 'package:clashkingapp/features/player/data/player_service.dart';
import 'package:clashkingapp/features/player/models/player.dart';
import 'package:clashkingapp/features/player/models/player_legend_day.dart';
import 'package:clashkingapp/features/player/presentation/toDo/player_to_do_page.dart';
import 'package:clashkingapp/features/war_cwl/data/war_cwl_service.dart';
import 'package:clashkingapp/features/war_cwl/models/cwl_member.dart';
import 'package:clashkingapp/features/war_cwl/models/war_cwl.dart';
import 'package:clashkingapp/features/war_cwl/models/war_member_presence.dart';
import 'package:flutter/material.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class PlayerToDoCard extends StatefulWidget {
  const PlayerToDoCard({super.key});

  @override
  PlayerToDoCardState createState() => PlayerToDoCardState();
}

class PlayerToDoCardState extends State<PlayerToDoCard> {
  @override
  Widget build(BuildContext context) {
    final playerService = context.watch<PlayerService>();
    final cocAccountService = context.watch<CocAccountService>();
    final player = playerService.getSelectedProfile(cocAccountService);
    final warCwlService = context.watch<WarCwlService>();
    WarMemberPresence memberCwl = WarMemberPresence.empty();

    if (player == null) {
      return Center(
        child: CircularProgressIndicator(),
      );
    }
    if (player.clan != null && player.clan!.tag != '') {
      final warCwl = warCwlService.getWarCwlByTag(player.clan!.tag);
      memberCwl = warCwl?.getMemberPresence(player.tag, player.clan!.tag) ??
          WarMemberPresence.empty();
    }

    final ratio = player.getTodoProgressRatio(memberCwl: memberCwl);
    final percent = (ratio * 100).toInt();

    return GestureDetector(
      onTap: () {
        final Map<String, WarMemberPresence> memberPresenceMap = {};

        for (final player in playerService.profiles) {
          if (player.clan != null && player.clan!.tag.isNotEmpty) {
            final warCwl = warCwlService.getWarCwlByTag(player.clan!.tag);
            if (warCwl != null) {
              memberPresenceMap[player.tag] =
                  warCwl.getMemberPresence(player.tag, player.clan!.tag);
            }
          }
        }
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PlayerToDoScreen(
                players: playerService.profiles,
                memberPresenceMap: memberPresenceMap),
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
                            Text(AppLocalizations.of(context)!.toDoList,
                                style:
                                    (Theme.of(context).textTheme.labelLarge)),
                            SizedBox(height: 12),
                            SizedBox(
                              height: 90,
                              width: 100,
                              child: MobileWebImage(
                                  imageUrl: ImageAssets.iconBuilderPotion,
                                  fit: BoxFit.fitHeight),
                            ),
                          ],
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: <Widget>[
                              iconToDo(player, memberCwl),
                              Row(
                                children: [
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Container(
                                      height: 8,
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                            color: Colors.black
                                                .withValues(alpha: 0.2),
                                            width: 1),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(4),
                                        child: LinearProgressIndicator(
                                          value: ratio,
                                          backgroundColor: Theme.of(context)
                                              .scaffoldBackgroundColor,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                  Colors.green),
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    '$percent%',
                                    style:
                                        Theme.of(context).textTheme.labelLarge,
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
        ],
      ),
    );
  }

  Widget iconToDo(Player player, WarMemberPresence memberCwl) {
    final lastOnlineDate = player.lastOnline.toLocal();
    final isLegend = player.league == "Legend League";
    PlayerLegendDay? currentDay;

    if (isLegend) {
      currentDay = player.currentLegendSeason?.currentDay;
    }

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
                      lastOnlineDate == DateTime.utc(1970, 1, 1)
                          ? Text(
                              AppLocalizations.of(context)!.playerNotTracked,
                              style: Theme.of(context).textTheme.labelLarge,
                              textAlign: TextAlign.center,
                            )
                          : Text(
                              AppLocalizations.of(context)!.lastActive(
                                  (player.getLastOnlineText(context))
                                      .toString()),
                              style: Theme.of(context).textTheme.labelLarge,
                              textAlign: TextAlign.center,
                            ),
                      SizedBox(height: 8),
                      Wrap(
                        alignment: WrapAlignment.start,
                        spacing: 7.0,
                        runSpacing: -7.0,
                        children: <Widget>[
                          if (player.league == 'Legend League' ||
                              currentDay != null)
                            Chip(
                              avatar: CircleAvatar(
                                backgroundColor: Colors.transparent,
                                child: MobileWebImage(
                                    imageUrl:
                                        ImageAssets.legendBlazonNoPadding),
                              ),
                              labelPadding:
                                  EdgeInsets.only(left: 2.0, right: 2.0),
                              label: Text(
                                "${currentDay?.totalAttacks ?? 0}/8",
                                style: Theme.of(context).textTheme.labelLarge,
                              ),
                              shape: RoundedRectangleBorder(
                                side: BorderSide(
                                  color: currentDay?.totalAttacks == 8
                                      ? Colors.green
                                      : Colors.red,
                                  width: 1.0,
                                ),
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                            ),
                          /*if (player.toDo!.war != null &&
                              player.toDo!.war!.attackLimit != 0)6 66
                            Chip(
                              avatar: CircleAvatar(
                                backgroundColor: Colors.transparent,
                                child: CachedNetworkImage(
                                  errorWidget: (context, url, error) =>
                                      Icon(Icons.error),
                                  imageUrl:
                                      "https://assets.clashk.ing/icons/Icon_DC_War.png",
                                ),
                              ),
                              labelPadding:
                                  EdgeInsets.only(left: 2.0, right: 2.0),
                              label: Text(
                                "${player.toDo!.war!.attacksDone}/${player.toDo!.war!.attackLimit}",
                                style: Theme.of(context).textTheme.labelLarge,
                              ),
                              shape: RoundedRectangleBorder(
                                side: BorderSide(
                                  color: player.toDo!.war!.attacksDone ==
                                          player.toDo!.war!.attackLimit
                                      ? Colors.green
                                      : Colors.red,
                                  width: 1.0,
                                ),
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                            ),*/
                          if (isInTimeFrameForClanGames())
                            Chip(
                              avatar: CircleAvatar(
                                backgroundColor: Colors.transparent,
                                child: MobileWebImage(
                                  imageUrl: ImageAssets.clanGamesMedals,
                                ),
                              ),
                              labelPadding:
                                  EdgeInsets.only(left: 2.0, right: 2.0),
                              label: Text(
                                NumberFormat(
                                        '#,###',
                                        Localizations.localeOf(context)
                                            .toString())
                                    .format(int.parse(player
                                        .currentClanGamesPoints
                                        .toString())),
                                style: Theme.of(context).textTheme.labelLarge,
                              ),
                              shape: RoundedRectangleBorder(
                                side: BorderSide(
                                  color: player.currentClanGamesPoints == 4000
                                      ? Colors.green
                                      : Colors.red,
                                  width: 1.0,
                                ),
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                            ),
                          if (isInTimeFrameForRaid())
                            Chip(
                              avatar: CircleAvatar(
                                backgroundColor: Colors.transparent,
                                child: MobileWebImage(
                                  imageUrl: ImageAssets.raidAttacks,
                                ),
                              ),
                              labelPadding:
                                  EdgeInsets.only(left: 2.0, right: 2.0),
                              label: Text(
                                      '${player.raids?.attackDone}/${player.raids?.attackLimit}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelLarge,
                                    ),
                              shape: RoundedRectangleBorder(
                                side: BorderSide(
                                  color: (player.raids?.attackDone == 5 &&
                                              player.raids?.attackLimit == 5) ||
                                          (player.raids?.attackDone == 6 &&
                                              player.raids?.attackLimit == 6)
                                      ? Colors.green
                                      : Colors.red,
                                  width: 1.0,
                                ),
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                            ),
                          if (isInTimeFrameForCwl() &&
                              memberCwl.attacksAvailable != 0)
                            Chip(
                              avatar: CircleAvatar(
                                backgroundColor: Colors.transparent,
                                child: MobileWebImage(
                                  imageUrl: ImageAssets.cwlSwordsNoBorder,
                                ),
                              ),
                              labelPadding:
                                  EdgeInsets.only(left: 2.0, right: 2.0),
                              label: Text(
                                '${memberCwl.attacksDone}/${memberCwl.attacksAvailable}',
                                style: Theme.of(context).textTheme.labelLarge,
                              ),
                              shape: RoundedRectangleBorder(
                                side: BorderSide(
                                  color: (memberCwl.attacksDone ==
                                          memberCwl.attacksAvailable)
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
                                child: MobileWebImage(
                                  imageUrl: ImageAssets.iconGoldPass,
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
                                  .format(int.parse(
                                      player.currentSeasonPoints.toString())),
                              style: Theme.of(context).textTheme.labelLarge,
                            ),
                            shape: RoundedRectangleBorder(
                              side: BorderSide(
                                color: player.seasonPassRatio == 1
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
