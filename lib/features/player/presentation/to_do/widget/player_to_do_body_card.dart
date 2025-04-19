import 'package:clashkingapp/common/widgets/mobile_web_image.dart';
import 'package:clashkingapp/core/functions.dart';
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
                                Chip(
                                  avatar: CircleAvatar(
                                    backgroundColor: Colors.transparent,
                                    child: MobileWebImage(
                                        imageUrl:
                                            ImageAssets.legendBlazonNoPadding),
                                  ),
                                  labelPadding:
                                      EdgeInsets.symmetric(horizontal: 4.0),
                                  label: Text(
                                    "${player.currentLegendSeason?.currentDay?.totalAttacks ?? 0}/8",
                                    style:
                                        Theme.of(context).textTheme.labelLarge,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    side: BorderSide(
                                      color: (player
                                                      .currentLegendSeason
                                                      ?.currentDay
                                                      ?.totalAttacks ??
                                                  0) ==
                                              8
                                          ? Colors.green
                                          : Colors.red,
                                    ),
                                    borderRadius: BorderRadius.circular(8.0),
                                  ),
                                ),
                              if (isInTimeFrameForClanGames())
                                Chip(
                                  avatar: CircleAvatar(
                                    backgroundColor: Colors.transparent,
                                    child: MobileWebImage(
                                        imageUrl: ImageAssets.clanGamesMedals),
                                  ),
                                  labelPadding:
                                      EdgeInsets.symmetric(horizontal: 4.0),
                                  label: Text(
                                    NumberFormat('#,###', locale)
                                        .format(player.currentClanGamesPoints),
                                    style:
                                        Theme.of(context).textTheme.labelLarge,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    side: BorderSide(
                                      color:
                                          player.currentClanGamesPoints == 4000
                                              ? Colors.green
                                              : Colors.red,
                                    ),
                                    borderRadius: BorderRadius.circular(8.0),
                                  ),
                                ),
                              if (isInTimeFrameForCwl() &&
                                  member.attacksAvailable > 0)
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
                                    '${member.attacksDone}/${member.attacksAvailable}',
                                    style:
                                        Theme.of(context).textTheme.labelLarge,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    side: BorderSide(
                                      color: (member.attacksDone ==
                                              member.attacksAvailable)
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
                                    style:
                                        Theme.of(context).textTheme.labelLarge,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    side: BorderSide(
                                      color: (player.raids?.attackDone == 5 &&
                                                  player.raids?.attackLimit ==
                                                      5) ||
                                              (player.raids?.attackDone == 6 &&
                                                  player.raids?.attackLimit ==
                                                      6)
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
                                  child: MobileWebImage(
                                      imageUrl: ImageAssets.iconGoldPass),
                                ),
                                labelPadding:
                                    EdgeInsets.symmetric(horizontal: 4.0),
                                label: Text(
                                  NumberFormat('#,###', locale)
                                      .format(player.currentSeasonPoints),
                                  style: Theme.of(context).textTheme.labelLarge,
                                ),
                                shape: RoundedRectangleBorder(
                                  side: BorderSide(
                                    color: player.seasonPassRatio >= 1
                                        ? Colors.green
                                        : Colors.red,
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
            const SizedBox(height: 8),
            Row(
              children: [
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    height: 8,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.black.withValues(alpha: 0.2)),
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
