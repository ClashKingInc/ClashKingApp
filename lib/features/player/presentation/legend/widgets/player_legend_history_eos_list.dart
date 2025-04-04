import 'package:clashkingapp/core/constants/image_assets.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';
import 'package:clashkingapp/features/player/models/player_legend_ranking.dart';

class PlayerLegendHistoryEosList extends StatelessWidget {
  const PlayerLegendHistoryEosList({
    super.key,
    required this.rankings,
  });

  final List<PlayerLegendRanking> rankings;

  String capitalize(String s) => s[0].toUpperCase() + s.substring(1);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          AppLocalizations.of(context)!.eosDetails,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        ...rankings.map((legendSeason) {
          return Card(
            margin: const EdgeInsets.only(top: 4, bottom: 4, left: 16, right: 16),
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
                            height: 90,
                            width: 100,
                            child: Stack(
                              children: <Widget>[
                                Center(
                                  child: CachedNetworkImage(
  
  errorWidget: (context, url, error) => Icon(Icons.error),
                                    imageUrl: ImageAssets.legendBlazonBordersNoPadding,
                                    height: 80,
                                  ),
                                ),
                                Align(
                                  alignment: const Alignment(0, -0.1),
                                  child: Text(
                                    capitalize(
                                      DateFormat(
                                              'MMMM\nyyyy',
                                              Localizations.localeOf(context).languageCode)
                                          .format(DateTime.parse("${legendSeason.season}-01")),
                                    ),
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelMedium!
                                        .copyWith(color: Colors.white),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            legendSeason.clan.name.isNotEmpty
                                ? legendSeason.clan.name
                                : AppLocalizations.of(context)!.noClan,
                            style: Theme.of(context).textTheme.labelMedium,
                          ),
                        ],
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Wrap(
                              alignment: WrapAlignment.center,
                              spacing: 4.0,
                              runSpacing: 0.0,
                              children: <Widget>[
                                Chip(
                                  avatar: CircleAvatar(
                                    backgroundColor: Colors.transparent,
                                    child: CachedNetworkImage(
  
  errorWidget: (context, url, error) => Icon(Icons.error),
                                      imageUrl: ImageAssets.bestTrophies,
                                    ),
                                  ),
                                  label: Text(
                                    NumberFormat(
                                            '#,###',
                                            Localizations.localeOf(context).toString())
                                        .format(legendSeason.trophies),
                                    style: Theme.of(context).textTheme.labelLarge,
                                  ),
                                ),
                                Chip(
                                  avatar: CircleAvatar(
                                    backgroundColor: Colors.transparent,
                                    child: CachedNetworkImage(
  
  errorWidget: (context, url, error) => Icon(Icons.error),
                                        imageUrl: ImageAssets.planet),
                                  ),
                                  label: Text(
                                    NumberFormat(
                                            '#,###',
                                            Localizations.localeOf(context).toString())
                                        .format(legendSeason.rank),
                                    style: Theme.of(context).textTheme.labelLarge,
                                  ),
                                ),
                                Chip(
                                  avatar: CircleAvatar(
                                    backgroundColor: Colors.transparent,
                                    child: CachedNetworkImage(
  
  errorWidget: (context, url, error) => Icon(Icons.error),
                                      imageUrl: ImageAssets.sword,
                                    ),
                                  ),
                                  label: Text(
                                    NumberFormat(
                                            '#,###',
                                            Localizations.localeOf(context).toString())
                                        .format(legendSeason.attackWins),
                                    style: Theme.of(context).textTheme.labelLarge,
                                  ),
                                ),
                                Chip(
                                  avatar: CircleAvatar(
                                    backgroundColor: Colors.transparent,
                                    child: CachedNetworkImage(
  
  errorWidget: (context, url, error) => Icon(Icons.error),
                                      imageUrl: ImageAssets.shieldWithArrow,
                                    ),
                                  ),
                                  label: Text(
                                    NumberFormat(
                                            '#,###',
                                            Localizations.localeOf(context).toString())
                                        .format(legendSeason.defenseWins),
                                    style: Theme.of(context).textTheme.labelLarge,
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
          );
        }),
      ],
    );
  }
}
