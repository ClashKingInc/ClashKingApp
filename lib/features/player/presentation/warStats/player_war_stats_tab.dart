import 'package:cached_network_image/cached_network_image.dart';
import 'package:clashkingapp/common/widgets/mobile_web_image.dart';
import 'package:clashkingapp/core/constants/image_assets.dart';
import 'package:clashkingapp/features/player/models/player.dart';
import 'package:clashkingapp/features/player/models/player_war_stats.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';

class WarStatsView extends StatelessWidget {
  final Player player;
  final List<String> filterTypes;
  final DateTime currentSeasonDate;
  final int warDataLimit;

  const WarStatsView({
    super.key,
    required this.player,
    required this.filterTypes,
    required this.currentSeasonDate,
    required this.warDataLimit,
  });

  @override
  Widget build(BuildContext context) {
    final stats = player.warStats?.getStatsForTypes(filterTypes);

    final Locale userLocale = Localizations.localeOf(context);
    String formattedStartDate = DateFormat.yMd(userLocale.toString())
        .format(DateTime.fromMillisecondsSinceEpoch(1000));
    String formattedEndDate = DateFormat.yMd(userLocale.toString())
        .format(DateTime.fromMillisecondsSinceEpoch(1000));

    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                  Text(AppLocalizations.of(context)!.allTownHalls,
                      style: Theme.of(context).textTheme.titleSmall),
                  if (filterTypes.contains("dateRange"))
                    Text("($formattedStartDate - $formattedEndDate)",
                        style: Theme.of(context).textTheme.bodyMedium),
                  if (filterTypes.contains("lastXWars"))
                    Text(AppLocalizations.of(context)!.lastXwars(warDataLimit),
                        style: Theme.of(context).textTheme.bodyMedium),
                  if (filterTypes.contains("season"))
                    Text(
                        AppLocalizations.of(context)!.seasonDate(
                            DateFormat.yMMMM(userLocale.toString())
                                .format(currentSeasonDate)),
                        style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 16),
                  _buildStatRows(context, stats!),
                ],
              ),
            ),
          ),
        ),
        ...stats.byEnemyTownhall.entries.map(
          (entry) {
            final thLevel = entry.key;
            final attackStats = entry.value;
            final defenseStats = stats.byEnemyTownhallDef[thLevel];

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CachedNetworkImage(
                            imageUrl:
                                "https://assets.clashk.ing/home-base/town-hall-pics/town-hall-$thLevel.png",
                            width: 30,
                            height: 30,
                            errorWidget: (context, url, error) =>
                                Icon(Icons.error),
                          ),
                          SizedBox(width: 8),
                          Text(AppLocalizations.of(context)!
                              .townHallLevelLevel(int.parse(thLevel))),
                        ],
                      ),
                      SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildColumn(
                              context,
                              AppLocalizations.of(context)!.attacks,
                              attackStats.averageStars,
                              attackStats.averageDestruction,
                              attackStats.count,
                              -1,
                              isAttack: true),
                          if (defenseStats != null)
                            _buildColumn(
                                context,
                                AppLocalizations.of(context)!.defenses,
                                defenseStats.averageStars,
                                defenseStats.averageDestruction,
                                defenseStats.count,
                                -1,
                                isAttack: false)
                          else
                            Text(AppLocalizations.of(context)!.noDefenseYet),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildStatRows(BuildContext context, PlayerWarTypeStats stats) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildColumn(
          context,
          AppLocalizations.of(context)!.attacks,
          stats.averageStars,
          stats.averageDestruction,
          stats.totalAttacks,
          stats.missedAttacks,
          isAttack: true,
        ),
        _buildColumn(
          context,
          AppLocalizations.of(context)!.defenses,
          stats.averageStarsDef,
          stats.averageDestructionDef,
          stats.totalDefenses,
          stats.missedDefenses,
          isAttack: false,
        ),
      ],
    );
  }

  Widget _buildColumn(BuildContext context, String title, double avgStars,
      double avgPct, int count, int missing,
      {required bool isAttack}) {
    return Column(
      children: [
        Text(title),
        Row(children: [
          CachedNetworkImage(
              errorWidget: (context, url, error) => const Icon(Icons.error),
              imageUrl:
                  "https://assets.clashk.ing/icons/Icon_HV_Attack_Star.png",
              width: 16,
              height: 16,
              fit: BoxFit.cover),
          const SizedBox(width: 8),
          Text(avgStars.toStringAsFixed(2))
        ]),
        Row(children: [
          CachedNetworkImage(
              errorWidget: (context, url, error) => const Icon(Icons.error),
              imageUrl: "https://assets.clashk.ing/icons/Icon_DC_Hitrate.png",
              width: 16,
              height: 16,
              fit: BoxFit.cover),
          const SizedBox(width: 8),
          Text(avgPct.toStringAsFixed(2))
        ]),
        Row(children: [
          CachedNetworkImage(
              errorWidget: (context, url, error) => const Icon(Icons.error),
              imageUrl: isAttack
                  ? ImageAssets.sword
                  : ImageAssets.shieldWithArrow,
              width: 16,
              height: 16,
              fit: BoxFit.cover),
          const SizedBox(width: 8),
          Text(count.toString())
        ]),
        if (missing != -1)
          Row(
            children: [
              MobileWebImage(
                  imageUrl: isAttack
                      ? ImageAssets.brokenSword
                      : ImageAssets.shield,
                  width: 16),
              const SizedBox(width: 8),
              Text(missing.toString()),
            ],
          ),
      ],
    );
  }
}
