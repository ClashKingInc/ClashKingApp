import 'package:clashkingapp/common/widgets/buttons/chip.dart';
import 'package:clashkingapp/common/widgets/mobile_web_image.dart';
import 'package:clashkingapp/core/constants/image_assets.dart';
import 'package:clashkingapp/core/functions/functions.dart';
import 'package:clashkingapp/features/coc_accounts/data/coc_account_service.dart';
import 'package:clashkingapp/features/player/data/player_service.dart';
import 'package:clashkingapp/features/player/models/player.dart';
import 'package:clashkingapp/features/player/models/player_legend_day.dart';
import 'package:clashkingapp/features/player/presentation/to_do/player_to_do_page.dart';
import 'package:clashkingapp/features/war_cwl/data/war_cwl_service.dart';
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
                            ImageChip(
                              imageUrl: ImageAssets.legendBlazonNoPadding,
                              labelPadding: 2.0,
                              label: "${currentDay?.totalAttacks ?? 0}/8",
                              edgeColor: currentDay?.totalAttacks == 8
                                  ? Colors.green
                                  : Colors.red,
                            ),
                          if (player.warData != null &&
                              player.warData!.state == 'inWar')
                            ImageChip(
                              imageUrl: ImageAssets.war,
                              labelPadding: 2.0,
                              label:
                                  "${player.warData?.getAttacksDoneByPlayer(player.tag, player.clanTag)} / ${player.warData?.attacksPerMember}",
                              edgeColor: player.warData!.getAttacksDoneByPlayer(
                                          player.tag, player.clanTag) ==
                                      player.warData!.attacksPerMember
                                  ? Colors.green
                                  : Colors.red,
                            ),
                          if (player.clan != null &&
                              player.clan!.warCwl != null &&
                              player.clan!.warCwl!.warInfo.state == 'inWar' &&
                              player.clan!.warCwl!.warInfo
                                  .isPlayerInWar(player.tag, player.clanTag))
                            ImageChip(
                              imageUrl: ImageAssets.war,
                              labelPadding: 2.0,
                              label:
                                  "${player.clan?.warCwl!.warInfo.getAttacksDoneByPlayer(player.tag, player.clanTag)}/${player.clan?.warCwl!.warInfo.attacksPerMember}",
                              edgeColor: player.clan?.warCwl!.warInfo
                                          .getAttacksDoneByPlayer(
                                              player.tag, player.clanTag) ==
                                      player.clan?.warCwl!.warInfo
                                          .attacksPerMember
                                  ? Colors.green
                                  : Colors.red,
                            ),
                          if (isInTimeFrameForClanGames())
                            ImageChip(
                              imageUrl: ImageAssets.clanGamesMedals,
                              labelPadding: 2.0,
                              label: NumberFormat(
                                      '#,###',
                                      Localizations.localeOf(context)
                                          .toString())
                                  .format(int.parse(player
                                      .currentClanGamesPoints
                                      .toString())),
                              edgeColor: player.clanGamesRatio == 1
                                  ? Colors.green
                                  : Colors.red,
                            ),
                          if (isInTimeFrameForRaid())
                            ImageChip(
                              imageUrl: ImageAssets.raidAttacks,
                              labelPadding: 2.0,
                              label:
                                  '${player.raids?.attackDone}/${player.raids?.attackLimit}',
                              edgeColor: (player.raids?.attackDone == 5 &&
                                          player.raids?.attackLimit == 5) ||
                                      (player.raids?.attackDone == 6 &&
                                          player.raids?.attackLimit == 6)
                                  ? Colors.green
                                  : Colors.red,
                            ),
                          if (isInTimeFrameForCwl() &&
                              memberCwl.attacksAvailable != 0)
                            ImageChip(
                              imageUrl: ImageAssets.cwlSwordsNoBorder,
                              labelPadding: 2.0,
                              label:
                                  '${memberCwl.attacksDone}/${memberCwl.attacksAvailable}',
                              edgeColor: (memberCwl.attacksDone ==
                                      memberCwl.attacksAvailable)
                                  ? Colors.green
                                  : Colors.red,
                            ),
                          ImageChip(
                              imageUrl: ImageAssets.iconGoldPass,
                              labelPadding: 2.0,
                              label: NumberFormat(
                                      '#,###',
                                      Localizations.localeOf(context)
                                          .toString())
                                  .format(int.parse(
                                      player.currentSeasonPoints.toString())),
                              edgeColor: player.seasonPassRatio == 1
                                  ? Colors.green
                                  : Colors.red),
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
