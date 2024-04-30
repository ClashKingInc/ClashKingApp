import 'package:clashkingapp/api/player_legend.dart';
import 'package:flutter/material.dart';
import 'package:clashkingapp/api/player_account_info.dart';
import 'package:clashkingapp/main_pages/dashboard_page/legend_dashboard/player_legend_page.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:cached_network_image/cached_network_image.dart';

class PlayerLegendCard extends StatelessWidget {
  const PlayerLegendCard({
    super.key,
    required this.playerStats,
    required this.playerLegendData,
  });

  final PlayerAccountInfo playerStats;
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
                  playerLegendData: playerLegendData
            )),
          );
        },
        child: DefaultTextStyle(
          style: Theme.of(context).textTheme.labelLarge ?? TextStyle(),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 16.0, bottom: 4),
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
                                child: CachedNetworkImage(imageUrl: 
                                  "https://clashkingfiles.b-cdn.net/icons/Icon_HV_League_Legend_3.png"
                                ),
                              ),
                            ],
                          ),
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
                  playerStats: playerStats,
                  playerLegendData: playerLegendData),
            ),
          );
        },
        child: DefaultTextStyle(
          style: Theme.of(context).textTheme.labelLarge ?? TextStyle(),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 16.0, bottom: 4),
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
                                CachedNetworkImage(imageUrl: 
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
                                Chip(
                                    avatar: CircleAvatar(
                                        backgroundColor: Colors.transparent,
                                        child: CachedNetworkImage(imageUrl: 
                                            "https://clashkingfiles.b-cdn.net/icons/Icon_HV_Start_Flag.png")),
                                    label: Text(playerLegendData.firstTrophies,
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelMedium)),
                                if (playerLegendData.legendRanking['country_code'] !=
                                    null) 
                                  Chip(
                                    avatar: CircleAvatar(
                                      backgroundColor: Colors.transparent,
                                      child: CachedNetworkImage(imageUrl: 
                                          "https://clashkingfiles.b-cdn.net/country-flags/${(playerLegendData.legendRanking['country_code'] ?? 'uk').toLowerCase()}.png"),
                                    ),
                                    label: Text(
                                      playerLegendData.legendRanking['local_rank'] ==
                                              null
                                          ? '200+'
                                          : '${playerLegendData.legendRanking['local_rank']}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelMedium,
                                    ),
                                  ),
                                Chip(
                                  avatar: Icon(
                                    playerLegendData.diffTrophies > 0
                                        ? LucideIcons.chevronUp
                                        : LucideIcons.chevronDown,
                                    color: playerLegendData.diffTrophies > 0
                                        ? Colors.green
                                        : Colors.red,
                                  ),
                                  label: Text(
                                    "${playerLegendData.diffTrophies >= 0 ? '+' : ''}${playerLegendData.diffTrophies.toString()}",
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelMedium
                                        ?.copyWith(
                                            color: playerLegendData.diffTrophies >= 0
                                                ? Colors.green
                                                : Colors.red),
                                  ),
                                ),
                                Chip(
                                  avatar: CircleAvatar(
                                      backgroundColor: Colors.transparent,
                                      child: CachedNetworkImage(imageUrl: 
                                          "https://clashkingfiles.b-cdn.net/icons/Icon_HV_Planet.png")),
                                  label: Text(
                                    playerLegendData.legendRanking['global_rank'] == null
                                        ? AppLocalizations.of(context)?.noRank ?? 'No Rank'
                                        : NumberFormat('#,###', 'fr_FR').format(playerLegendData.legendRanking['global_rank']),
                                    style: Theme.of(context).textTheme.labelMedium,
                                  ),
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
