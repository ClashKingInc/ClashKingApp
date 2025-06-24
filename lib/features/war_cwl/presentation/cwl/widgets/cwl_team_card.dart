import 'package:clashkingapp/common/widgets/icons/build_stars.dart';
import 'package:clashkingapp/common/widgets/mobile_web_image.dart';
import 'package:clashkingapp/common/widgets/shapes/stat_tile.dart';
import 'package:clashkingapp/core/constants/image_assets.dart';
import 'package:clashkingapp/features/clan/data/clan_service.dart';
import 'package:clashkingapp/features/clan/models/clan.dart';
import 'package:clashkingapp/features/clan/presentation/clan_info/clan_page.dart';
import 'package:clashkingapp/features/war_cwl/models/cwl_clan.dart';
import 'package:clashkingapp/features/war_cwl/models/war_cwl.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';

class CwlTeamCard extends StatelessWidget {
  final CwlClan clan;
  final WarCwl warCwl;
  final bool showFullStats;
  final VoidCallback onToggleFullStats;

  const CwlTeamCard({
    super.key,
    required this.clan,
    required this.warCwl,
    required this.showFullStats,
    required this.onToggleFullStats,
  });

  @override
  Widget build(BuildContext context) {
    final sortedTownHalls = clan.townHallLevels.entries.toList();
    sortedTownHalls
        .sort((a, b) => int.parse(b.key).compareTo(int.parse(a.key)));

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: () async {
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) =>
                      const Center(child: CircularProgressIndicator()),
                );
                final Clan clanInfo =
                    await ClanService().loadClanData(clan.tag);
                if (context.mounted) {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ClanInfoScreen(
                        clanInfo: clanInfo,
                      ),
                    ),
                  );
                }
              },
              child: Row(
                children: [
                  CachedNetworkImage(
                    imageUrl: clan.badgeUrls.medium,
                    width: 40,
                    height: 40,
                    errorWidget: (context, url, error) => Icon(Icons.error),
                  ),
                  SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(clan.name,
                          style: Theme.of(context).textTheme.titleMedium),
                      Text(clan.tag,
                          style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                  Spacer(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        children: [
                          Text("${clan.stars}  "),
                          SizedBox(
                            child: MobileWebImage(
                              imageUrl: ImageAssets.attackStar,
                              width: 15,
                              height: 15,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Text(
                              "${NumberFormat('#,###', Localizations.localeOf(context).toString()).format(clan.destructionPercentageInflicted)}  "),
                          SizedBox(
                            child: MobileWebImage(
                              imageUrl: ImageAssets.hitrate,
                              width: 15,
                              height: 15,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 8),
            Wrap(
              alignment: WrapAlignment.center,
              children: sortedTownHalls.map((entry) {
                return Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      MobileWebImage(
                        imageUrl: ImageAssets.townHall(int.parse(entry.key)),
                        width: 20,
                        height: 20,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'x${entry.value}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
            GestureDetector(
              onTap: onToggleFullStats,
              child: Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(showFullStats ? Icons.expand_less : Icons.expand_more,
                        size: 16,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.7)),
                    const SizedBox(width: 4),
                    Text(AppLocalizations.of(context)!.generalFullStats,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.7))),
                  ],
                ),
              ),
            ),
            if (showFullStats)
              Padding(
                padding: const EdgeInsets.only(top: 12.0),
                child: Column(
                  children: [
                    Column(
                      children: [
                        Text(AppLocalizations.of(context)!.warAttacksTitle,
                            style: Theme.of(context).textTheme.titleSmall),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 16,
                          runAlignment: WrapAlignment.center,
                          runSpacing: 16,
                          children: [
                            StatTile(
                                label: AppLocalizations.of(context)!.warAttacksTitle,
                                value: '${clan.attackCount}',
                                icon: MobileWebImage(
                                    imageUrl: ImageAssets.sword,
                                    width: 16,
                                    height: 16)),
                            StatTile(
                                label: AppLocalizations.of(context)!.warStatusMissed,
                                value: '${clan.missedAttacks}',
                                icon: MobileWebImage(
                                    imageUrl: ImageAssets.brokenSword,
                                    width: 16,
                                    height: 16)),
                            StatTile(
                                label: AppLocalizations.of(context)!.generalTotal,
                                value: '${clan.stars}',
                                icon: MobileWebImage(
                                    imageUrl: ImageAssets.attackStar,
                                    width: 16,
                                    height: 16)),
                            StatTile(
                                label: AppLocalizations.of(context)!.warAbbreviationAvg,
                                value: clan.averageStars.toStringAsFixed(1),
                                icon: MobileWebImage(
                                    imageUrl: ImageAssets.attackStar,
                                    width: 16,
                                    height: 16)),
                            StatTile(
                                label: AppLocalizations.of(context)!.warStarsThree,
                                value: '${clan.threeStars}',
                                icon: buildStarsIcon(3)),
                            StatTile(
                                label: AppLocalizations.of(context)!.warStarsTwo,
                                value: '${clan.twoStars}',
                                icon: buildStarsIcon(2)),
                            StatTile(
                                label: AppLocalizations.of(context)!.warStarsOne,
                                value: '${clan.oneStar}',
                                icon: buildStarsIcon(1)),
                            StatTile(
                                label: AppLocalizations.of(context)!.warStarsZero,
                                value: '${clan.zeroStar}',
                                icon: buildStarsIcon(0)),
                            StatTile(
                                label:
                                    AppLocalizations.of(context)!.warDestructionTitle,
                                value:
                                    '${clan.destructionPercentageInflicted.toStringAsFixed(1)}%',
                                icon: MobileWebImage(
                                    imageUrl: ImageAssets.hitrate,
                                    width: 16,
                                    height: 16)),
                            StatTile(
                                label:
                                    AppLocalizations.of(context)!.warAbbreviationAvgPercentage,
                                value:
                                    clan.averageDestruction.toStringAsFixed(1),
                                icon: MobileWebImage(
                                    imageUrl: ImageAssets.hitrate,
                                    width: 16,
                                    height: 16)),
                          ],
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        const SizedBox(height: 18),
                        Text(AppLocalizations.of(context)!.warDefensesTitle,
                            style: Theme.of(context).textTheme.titleSmall),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 16,
                          runAlignment: WrapAlignment.center,
                          runSpacing: 16,
                          children: [
                            StatTile(
                                label: AppLocalizations.of(context)!.warDefensesTitle,
                                value: '${clan.defenseCount}',
                                icon: MobileWebImage(
                                    imageUrl: ImageAssets.shieldWithArrow,
                                    width: 16,
                                    height: 16)),
                            StatTile(
                                label: AppLocalizations.of(context)!.warStatusMissed,
                                value: '${clan.missedDefenses}',
                                icon: MobileWebImage(
                                    imageUrl: ImageAssets.shield,
                                    width: 16,
                                    height: 16)),
                            StatTile(
                                label: AppLocalizations.of(context)!.generalTotal,
                                value: '${clan.defStars}',
                                icon: MobileWebImage(
                                    imageUrl: ImageAssets.attackStar,
                                    width: 16,
                                    height: 16)),
                            StatTile(
                                label: AppLocalizations.of(context)!.warAbbreviationAvg,
                                value: clan.defAverageStars.toStringAsFixed(1),
                                icon: MobileWebImage(
                                    imageUrl: ImageAssets.attackStar,
                                    width: 16,
                                    height: 16)),
                            StatTile(
                                label: AppLocalizations.of(context)!.warStarsThree,
                                value: '${clan.threeStarsDef}',
                                icon: buildStarsIcon(3)),
                            StatTile(
                                label: AppLocalizations.of(context)!.warStarsTwo,
                                value: '${clan.twoStarsDef}',
                                icon: buildStarsIcon(2)),
                            StatTile(
                                label: AppLocalizations.of(context)!.warStarsOne,
                                value: '${clan.oneStarDef}',
                                icon: buildStarsIcon(1)),
                            StatTile(
                                label: AppLocalizations.of(context)!.warStarsZero,
                                value: '${clan.zeroStarDef}',
                                icon: buildStarsIcon(0)),
                            StatTile(
                                label:
                                    AppLocalizations.of(context)!.warDestructionTitle,
                                value:
                                    '${clan.destructionPercentage.toStringAsFixed(1)}%',
                                icon: MobileWebImage(
                                    imageUrl: ImageAssets.hitrate,
                                    width: 16,
                                    height: 16)),
                            StatTile(
                                label:
                                    AppLocalizations.of(context)!.warAbbreviationAvgPercentage,
                                value: clan.defAverageDestruction.toStringAsFixed(1),
                                icon: MobileWebImage(
                                    imageUrl: ImageAssets.hitrate,
                                    width: 16,
                                    height: 16)),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
