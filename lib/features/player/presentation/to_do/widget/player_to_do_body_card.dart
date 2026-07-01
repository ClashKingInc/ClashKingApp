import 'package:cached_network_image/cached_network_image.dart';
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
    final colorScheme = Theme.of(context).colorScheme;
    final ratio = player.getTodoProgressRatio(memberCwl: member);
    final percent = (ratio * 100).toInt();

    return Card(
      margin: const EdgeInsets.only(top: 8),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                SizedBox.square(
                  dimension: 62,
                  child: MobileWebImage(imageUrl: player.townHallPic),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        player.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      Text(
                        player.tag,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        player.lastOnline == DateTime.utc(1970, 1, 1)
                            ? AppLocalizations.of(context)!.playerNotTracked
                            : AppLocalizations.of(context)!.playerLastActive(
                                player.getLastOnlineText(context)),
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: Wrap(
                spacing: 7,
                runSpacing: 7,
                children: <Widget>[
                  if (player.league == 'Legend League' &&
                      player.currentLegendSeason?.currentDay != null)
                    _StatusChip(
                      imageUrl: ImageAssets.legendBlazonNoPadding,
                      label:
                          "${player.currentLegendSeason?.currentDay?.totalAttacks ?? 0}/8",
                      done: (player.currentLegendSeason?.currentDay
                                  ?.totalAttacks ??
                              0) ==
                          8,
                    ),
                  if (player.warData != null &&
                      player.warData!.state == 'inWar')
                    _StatusChip(
                      imageUrl: ImageAssets.war,
                      label:
                          "${player.warData?.getAttacksDoneByPlayer(player.tag, player.clanTag)}/${player.warData?.attacksPerMember}",
                      done: player.warData!.getAttacksDoneByPlayer(
                              player.tag, player.clanTag) ==
                          player.warData!.attacksPerMember,
                    ),
                  if (player.clan != null &&
                      player.clan!.warCwl != null &&
                      player.clan!.warCwl!.warInfo.state == 'inWar' &&
                      player.clan!.warCwl!.warInfo
                          .isPlayerInWar(player.tag, player.clanTag))
                    _StatusChip(
                      imageUrl: ImageAssets.war,
                      label:
                          "${player.clan?.warCwl!.warInfo.getAttacksDoneByPlayer(player.tag, player.clanTag)}/${player.clan?.warCwl!.warInfo.attacksPerMember}",
                      done: player.clan?.warCwl!.warInfo
                              .getAttacksDoneByPlayer(
                                  player.tag, player.clanTag) ==
                          player.clan?.warCwl!.warInfo.attacksPerMember,
                    ),
                  if (isInTimeFrameForClanGames())
                    _StatusChip(
                      imageUrl: ImageAssets.clanGamesMedals,
                      label: NumberFormat('#,###', locale)
                          .format(player.currentClanGamesPoints),
                      done: player.clanGamesRatio == 1,
                    ),
                  if (isInTimeFrameForCwl() && member.attacksAvailable > 0)
                    _StatusChip(
                      imageUrl: ImageAssets.cwlSwordsNoBorder,
                      label: '${member.attacksDone}/${member.attacksAvailable}',
                      done: member.attacksDone == member.attacksAvailable,
                    ),
                  if (isInTimeFrameForRaid())
                    _StatusChip(
                      imageUrl: ImageAssets.raidAttacks,
                      label:
                          '${player.raids?.attackDone}/${player.raids?.attackLimit}',
                      done: (player.raids?.attackDone == 5 &&
                              player.raids?.attackLimit == 5) ||
                          (player.raids?.attackDone == 6 &&
                              player.raids?.attackLimit == 6),
                    ),
                  _StatusChip(
                    imageUrl: ImageAssets.iconGoldPass,
                    label: NumberFormat('#,###', locale)
                        .format(player.currentSeasonPoints),
                    done: player.seasonPassRatio >= 1,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: ratio,
                      minHeight: 8,
                      backgroundColor: colorScheme.surfaceContainerHighest,
                      valueColor:
                          const AlwaysStoppedAnimation<Color>(Colors.green),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '$percent%',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Borderless pill chip — green when done, theme primary when pending.
class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.imageUrl,
    required this.label,
    required this.done,
  });

  final String imageUrl;
  final String label;
  final bool done;

  @override
  Widget build(BuildContext context) {
    final color =
        done ? Colors.green : Theme.of(context).colorScheme.primary;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox.square(
              dimension: 16,
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.contain,
                errorWidget: (context, url, error) =>
                    Icon(Icons.help_outline, size: 14, color: color),
              ),
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
