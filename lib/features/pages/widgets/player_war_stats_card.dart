import 'package:clashkingapp/common/widgets/mobile_web_image.dart';
import 'package:clashkingapp/core/constants/image_assets.dart';
import 'package:clashkingapp/features/player/data/player_service.dart';
import 'package:clashkingapp/features/player/presentation/war_stats/war_stats_page.dart';
import 'package:flutter/material.dart';
import 'package:clashkingapp/features/coc_accounts/data/coc_account_service.dart';
import 'package:provider/provider.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';
import 'package:clashkingapp/common/widgets/buttons/chip.dart';

class PlayerWarStatsCard extends StatelessWidget {
  const PlayerWarStatsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final playerService = context.watch<PlayerService>();
    final cocService = context.watch<CocAccountService>();
    final player = playerService.getSelectedProfile(cocService);
    final warStats = player?.warStats;
    final allStats = warStats?.statsByType["all"];

    return DefaultTextStyle(
      style: Theme.of(context).textTheme.labelLarge ?? TextStyle(),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PlayerWarStatsScreen(
                player: player!,
              ),
            ),
          );
        },
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Column(
                      children: <Widget>[
                        SizedBox(
                          width: 100,
                          child: Text(
                            AppLocalizations.of(context)!.warStats,
                            style: Theme.of(context).textTheme.labelLarge,
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.visible,
                            softWrap: true,
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 60,
                          width: 60,
                          child: MobileWebImage(imageUrl: ImageAssets.war),
                        ),
                      ],
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: <Widget>[
                          Text(
                            AppLocalizations.of(context)!
                                .lastXwars(allStats?.warsCounts ?? 0),
                            style: Theme.of(context).textTheme.labelLarge,
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.visible,
                            softWrap: true,
                          ),
                          const SizedBox(height: 4),
                          Wrap(
                            alignment: WrapAlignment.start,
                            spacing: 7.0,
                            runSpacing: -7.0,
                            children: <Widget>[
                              if (warStats != null) ...[
                                ImageChip(
                                  context: context,
                                  imageUrl: ImageAssets.sword,
                                  label: "${allStats?.totalAttacks}",
                                  description: AppLocalizations.of(context)!
                                      .warAttacksNumber(
                                          allStats?.totalAttacks ?? 0, 50),
                                ),
                                ImageChip(
                                  context: context,
                                  imageUrl: ImageAssets.attackStar,
                                  label: allStats?.averageStars
                                          .toStringAsFixed(2) ??
                                      "",
                                  description: AppLocalizations.of(context)!
                                      .warAverageStars(allStats?.averageStars
                                              .toStringAsFixed(2) ??
                                          "?"),
                                ),
                                ImageChip(
                                  context: context,
                                  imageUrl: ImageAssets.hitrate,
                                  label:
                                      "${allStats?.averageDestruction.toStringAsFixed(1)}%",
                                  description: AppLocalizations.of(context)!
                                      .warAverageDestruction(allStats
                                              ?.averageDestruction
                                              .toStringAsFixed(1) ??
                                          "?"),
                                ),
                                ImageChip(
                                  context: context,
                                  imageUrl: ImageAssets.shieldWithArrow,
                                  label: "${allStats?.totalDefenses}",
                                  description: AppLocalizations.of(context)!
                                      .warDefensesNumber(
                                          allStats?.totalDefenses ?? 0, 50),
                                ),
                                ImageChip(
                                  context: context,
                                  imageUrl: ImageAssets.attackStar,
                                  label: allStats?.averageStarsDef
                                          .toStringAsFixed(2) ??
                                      "",
                                  description: AppLocalizations.of(context)!
                                      .warAverageStarsDefense(
                                          allStats?.averageStarsDef ?? 0),
                                ),
                                ImageChip(
                                  context: context,
                                  imageUrl: ImageAssets.hitrate,
                                  label:
                                      "${allStats?.averageDestructionDef.toStringAsFixed(1)}%",
                                  description: AppLocalizations.of(context)!
                                      .warAverageDestructionDefense(allStats
                                              ?.averageDestructionDef
                                              .toStringAsFixed(1) ??
                                          "?"),
                                ),
                              ]
                            ],
                          ),
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
    );
  }
}
