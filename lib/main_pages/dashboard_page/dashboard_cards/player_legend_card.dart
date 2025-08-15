import 'package:clashkingapp/classes/profile/legend/legend_data.dart';
import 'package:flutter/material.dart';
import 'package:clashkingapp/main_pages/dashboard_page/legend_dashboard/player_legend_page.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:clashkingapp/classes/profile/profile_info.dart';
import 'package:clashkingapp/components/chip.dart';

class PlayerLegendCard extends StatelessWidget {
  const PlayerLegendCard({
    super.key,
    required this.playerStats,
    required this.playerLegendData,
  });

  final ProfileInfo playerStats;
  final PlayerLegendData playerLegendData;

  @override
  Widget build(BuildContext context) {
    if (!playerLegendData.isInLegend || playerLegendData.firstTrophies == "0") {
      return GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => LegendScreen(
                    playerStats: playerStats,
                    playerLegendData: playerLegendData)),
          );
        },
        child: DefaultTextStyle(
          style: Theme.of(context).textTheme.labelLarge ?? TextStyle(),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.only(
                  left: 16.0, right: 16.0, top: 16.0, bottom: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Stack(
                        alignment: Alignment.center,
                        children: <Widget>[
                          Column(
                            children: <Widget>[
                              Text(
                                AppLocalizations.of(context)!.legendLeague,
                                style: Theme.of(context).textTheme.labelLarge,
                              ),
                              SizedBox(
                                height: 100,
                                width: 100,
                                child: CachedNetworkImage(
                                    imageUrl:
                                        "https://assets.clashk.ing/icons/Icon_HV_League_Legend_3.png"),
                              ),
                            ],
                          ),
                          if (playerStats.league == "Legend League")
                            Positioned(
                              right: 30,
                              bottom: 42,
                              child: Text(
                                NumberFormat(
                                        '#,###',
                                        Localizations.localeOf(context)
                                            .toString())
                                    .format(playerStats.trophies),
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall!
                                    .copyWith(color: Colors.white),
                              ),
                            ),
                        ],
                      ),
                      SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          AppLocalizations.of(context)!.noLegendData,
                          style: Theme.of(context).textTheme.labelLarge,
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 3,
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
    } else {
      return GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => LegendScreen(
                  playerStats: playerStats, playerLegendData: playerLegendData),
            ),
          );
        },
        child: DefaultTextStyle(
          style: Theme.of(context).textTheme.labelLarge ?? TextStyle(),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.only(
                  left: 16.0, right: 16.0, top: 16.0, bottom: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Column(
                        children: <Widget>[
                          Text(
                            AppLocalizations.of(context)?.legendLeague ??
                                "Legend League",
                            style: Theme.of(context).textTheme.labelLarge,
                          ),
                          SizedBox(
                            height: 100,
                            width: 100,
                            child: Stack(
                              alignment: Alignment
                                  .center, // S'assure que les enfants soient centrés
                              children: <Widget>[
                                CachedNetworkImage(
                                  imageUrl:
                                      "https://assets.clashk.ing/icons/Icon_HV_League_Legend_3.png",
                                  width: 100,
                                  height: 100,
                                  fit: BoxFit.cover,
                                ),
                                Align(
                                  alignment: Alignment.center,
                                  child: Text(
                                    NumberFormat(
                                            '#,###',
                                            Localizations.localeOf(context)
                                                .toString())
                                        .format(playerStats.trophies),
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall!
                                        .copyWith(color: Colors.white),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: <Widget>[
                            Wrap(
                              alignment: WrapAlignment.start,
                              spacing: 7.0,
                              runSpacing: -7.0,
                              children: <Widget>[
                                ImageChip(
                                  imageUrl:
                                      "https://assets.clashk.ing/icons/Icon_HV_Start_Flag.png",
                                  label: NumberFormat(
                                          '#,###',
                                          Localizations.localeOf(context)
                                              .toString())
                                      .format(int.parse(
                                          playerLegendData.firstTrophies)),
                                  description: AppLocalizations.of(context)!
                                      .legendStartDescription(
                                          playerLegendData.firstTrophies),
                                ),
                                if (playerLegendData
                                    .legendRanking.countryCode.isNotEmpty)
                                  ImageChip(
                                    labelPadding: 4,
                                    imageUrl:
                                        "https://assets.clashk.ing/country-flags/${(playerLegendData.legendRanking.countryCode).toLowerCase()}.png",
                                    label: playerLegendData
                                        .legendRanking.localRank,
                                    description:
                                        playerLegendData
                                                .legendRanking.isRankedLocally
                                            ? AppLocalizations.of(context)
                                                    ?.legendRankLocalDescription(
                                                        playerLegendData
                                                            .legendRanking
                                                            .countryName,
                                                        playerLegendData
                                                            .legendRanking.localRank,
                                                        playerStats.trophies) ??
                                                'No infos on local rank.'
                                            : AppLocalizations.of(context)
                                                    ?.legendNoRankLocalDescription(
                                                        playerLegendData
                                                            .legendRanking
                                                            .countryName,
                                                        playerStats.trophies) ??
                                                "No local rank.",
                                  ),
                                IconChip(
                                  icon: playerLegendData.diffTrophies >= 0
                                      ? LucideIcons.chevronUp
                                      : LucideIcons.chevronDown,
                                  color: playerLegendData.diffTrophies >= 0
                                      ? Colors.green
                                      : Colors.red,
                                  size: 16,
                                  label:
                                      "${playerLegendData.diffTrophies >= 0 ? '+' : ''}${NumberFormat('#,###', Localizations.localeOf(context).toString()).format(int.parse(playerLegendData.diffTrophies.toString()))}",
                                  description: playerLegendData.diffTrophies >=
                                          0
                                      ? AppLocalizations.of(context)!
                                          .legendGainDescription(
                                              playerLegendData.diffTrophies)
                                      : AppLocalizations.of(context)!
                                          .legendLossDescription(
                                              -playerLegendData.diffTrophies),
                                ),
                                ImageChip(
                                  imageUrl:
                                      "https://assets.clashk.ing/icons/Icon_HV_Planet.png",
                                  label: playerLegendData
                                          .legendRanking.isRankedGlobally
                                      ? NumberFormat(
                                              '#,###',
                                              Localizations.localeOf(context)
                                                  .toString())
                                          .format(int.parse(playerLegendData
                                              .legendRanking.globalRank))
                                      : AppLocalizations.of(context)?.noRank ??
                                          'No Rank',
                                  description: playerLegendData
                                          .legendRanking.isRankedGlobally
                                      ? AppLocalizations.of(context)
                                              ?.legendGlobalRankDescription(
                                                  int.parse(playerLegendData
                                                      .legendRanking
                                                      .globalRank),
                                                  playerStats.trophies) ??
                                          'No infos on global rank.'
                                      : AppLocalizations.of(context)
                                              ?.legendNoGlobalRankDescription(
                                                  playerStats.trophies) ??
                                          'No global rank.',
                                ),
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
}
