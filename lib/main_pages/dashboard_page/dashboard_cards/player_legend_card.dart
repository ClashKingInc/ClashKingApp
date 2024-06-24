import 'package:clashkingapp/classes/profile/legend/legend_league.dart';
import 'package:flutter/material.dart';
import 'package:clashkingapp/main_pages/dashboard_page/legend_dashboard/player_legend_page.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
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
    DateTime selectedDate = DateTime.now().toUtc().subtract(Duration(hours: 5));
    String date = DateFormat('yyyy-MM-dd').format(selectedDate);
    if (!playerLegendData.legendData.containsKey(date)) {
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
                                AppLocalizations.of(context)?.legendLeague ??
                                    "Legend League",
                                style: Theme.of(context).textTheme.labelLarge,
                              ),
                              SizedBox(
                                height: 100,
                                width: 100,
                                child: CachedNetworkImage(
                                    imageUrl:
                                        "https://clashkingfiles.b-cdn.net/icons/Icon_HV_League_Legend_3.png"),
                              ),
                            ],
                          ),
                          if (playerStats.league == "Legend League")
                            Positioned(
                              right: 30,
                              bottom: 42,
                              child: Text(
                                playerStats.trophies.toString(),
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
                          AppLocalizations.of(context)?.noLegendData ??
                              "No Legend Data found for today",
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
                              children: <Widget>[
                                CachedNetworkImage(
                                  imageUrl:
                                      "https://clashkingfiles.b-cdn.net/icons/Icon_HV_League_Legend_3.png",
                                ),
                                Positioned(
                                  right: 30,
                                  top: 32,
                                  child: Text(
                                    playerStats.trophies.toString(),
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
                                      "https://clashkingfiles.b-cdn.net/icons/Icon_HV_Start_Flag.png",
                                  label: playerLegendData.firstTrophies,
                                  description: AppLocalizations.of(context)!
                                      .legendStartDescription(
                                          playerLegendData.firstTrophies),
                                ),
                                if (playerLegendData
                                        .legendRanking['country_code'] !=
                                    null)
                                  ImageChip(
                                    labelPadding: 4,
                                    imageUrl:
                                        "https://clashkingfiles.b-cdn.net/country-flags/${(playerLegendData.legendRanking['country_code'] ?? 'uk').toLowerCase()}.png",
                                    label: playerLegendData
                                                .legendRanking['local_rank'] ==
                                            null
                                        ? '200+'
                                        : '${playerLegendData.legendRanking['local_rank']}',
                                    description: playerLegendData
                                                .legendRanking['local_rank'] ==
                                            null
                                        ? AppLocalizations.of(context)
                                                ?.legendNoRankLocalDescription(
                                                    playerLegendData
                                                            .legendRanking[
                                                        'country_name'],
                                                    playerStats.trophies) ??
                                            "No local rank."
                                        : AppLocalizations.of(context)
                                                ?.legendRankLocalDescription(
                                                    playerLegendData
                                                            .legendRanking[
                                                        'country_name'],
                                                    playerLegendData
                                                            .legendRanking[
                                                        'local_rank'],
                                                    playerStats.trophies) ??
                                            'No infos on local rank.',
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
                                      "${playerLegendData.diffTrophies >= 0 ? '+' : ''}${playerLegendData.diffTrophies.toString()}",
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
                                      "https://clashkingfiles.b-cdn.net/icons/Icon_HV_Planet.png",
                                  label: playerLegendData
                                              .legendRanking['global_rank'] ==
                                          null
                                      ? AppLocalizations.of(context)?.noRank ??
                                          'No Rank'
                                      : NumberFormat('#,###', 'fr_FR').format(
                                          playerLegendData
                                              .legendRanking['global_rank']),
                                  description: playerLegendData
                                              .legendRanking['global_rank'] ==
                                          null
                                      ? AppLocalizations.of(context)
                                              ?.legendNoGlobalRankDescription(
                                                  playerStats.trophies) ??
                                          'No global rank.'
                                      : AppLocalizations.of(context)
                                              ?.legendGlobalRankDescription(
                                                  playerLegendData
                                                          .legendRanking[
                                                      'global_rank'],
                                                  playerStats.trophies) ??
                                          'No infos on global rank.',
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
