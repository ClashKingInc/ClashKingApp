import 'package:clashkingapp/common/widgets/buttons/chip.dart';
import 'package:clashkingapp/common/widgets/mobile_web_image.dart';
import 'package:clashkingapp/core/functions/functions.dart';
import 'package:clashkingapp/features/player/models/player.dart';
import 'package:clashkingapp/features/war_cwl/models/war_member_presence.dart';
import 'package:flutter/material.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:clashkingapp/core/constants/image_assets.dart';

class PlayerToDoBodyCard extends StatelessWidget {
  final Player player;
  final WarMemberPresence member;

  const PlayerToDoBodyCard({
    super.key,
    required this.player,
    required this.member,
  });

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    final ratio = player.getTodoProgressRatio(memberCwl: member);
    final percent = (ratio * 100).toInt();

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
                      child: MobileWebImage(
                        imageUrl: player.townHallPic,
                      ),
                    ),
                    Text(
                      player.name,
                      style: Theme.of(context)
                          .textTheme
                          .labelLarge
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      player.tag,
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
                          player.lastOnline == DateTime.utc(1970, 1, 1)
                              ? Text(
                                  AppLocalizations.of(context)!
                                      .playerNotTracked,
                                  style: Theme.of(context).textTheme.labelLarge,
                                  textAlign: TextAlign.center,
                                )
                              : Text(
                                  AppLocalizations.of(context)!.lastActive(
                                      player.getLastOnlineText(context)),
                                  style: Theme.of(context).textTheme.labelLarge,
                                  textAlign: TextAlign.center,
                                ),
                          const SizedBox(height: 8),
                          Wrap(
                            alignment: WrapAlignment.start,
                            spacing: 7.0,
                            runSpacing: -7.0,
                            children: <Widget>[
                              if (player.league == 'Legend League' &&
                                  player.currentLegendSeason?.currentDay !=
                                      null)
                                ImageChip(
                                  imageUrl: ImageAssets.legendBlazonNoPadding,
                                  labelPadding: 4.0,
                                  label:
                                      "${player.currentLegendSeason?.currentDay?.totalAttacks ?? 0}/8",
                                  edgeColor: (player.currentLegendSeason
                                                  ?.currentDay?.totalAttacks ??
                                              0) ==
                                          8
                                      ? Colors.green
                                      : Colors.red,
                                ),
                              if (player.clan != null &&
                                  player.clan!.warCwl != null &&
                                  player.clan!.warCwl!.warInfo.state ==
                                      'inWar' &&
                                  player.clan!.warCwl!.warInfo.isPlayerInWar(
                                      player.tag, player.clanTag))
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
                                  labelPadding: 4.0,
                                  label: NumberFormat('#,###', locale)
                                      .format(player.currentClanGamesPoints),
                                  edgeColor:
                                      player.clanGamesRatio == 1
                                          ? Colors.green
                                          : Colors.red,
                                ),
                              if (isInTimeFrameForCwl() &&
                                  member.attacksAvailable > 0)
                                ImageChip(
                                  imageUrl: ImageAssets.cwlSwordsNoBorder,
                                  labelPadding: 2.0,
                                  label:
                                      '${member.attacksDone}/${member.attacksAvailable}',
                                  edgeColor: (member.attacksDone ==
                                          member.attacksAvailable)
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
                              ImageChip(
                                imageUrl: ImageAssets.iconGoldPass,
                                labelPadding: 4.0,
                                label: NumberFormat('#,###', locale)
                                    .format(player.currentSeasonPoints),
                                edgeColor: player.seasonPassRatio >= 1
                                    ? Colors.green
                                    : Colors.red,
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
            const SizedBox(height: 8),
            Row(
              children: [
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    height: 8,
                    decoration: BoxDecoration(
                      border: Border.all(
                          color: Colors.black.withValues(alpha: 0.2)),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: ratio,
                        backgroundColor:
                            Theme.of(context).scaffoldBackgroundColor,
                        valueColor:
                            const AlwaysStoppedAnimation<Color>(Colors.green),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '$percent%',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
