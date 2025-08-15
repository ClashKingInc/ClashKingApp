import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';
import 'package:clashkingapp/classes/profile/legend/legend_season.dart';

class LegendStatsHistoryCard extends StatelessWidget {
  const LegendStatsHistoryCard({
    super.key,
    required this.legendSeasons,
  });

  final List<LegendSeason> legendSeasons;

  LegendSeason getBestTrophiesSeason() {
    return legendSeasons.reduce((a, b) => a.trophies > b.trophies ? a : b);
  }

  LegendSeason getBestGlobalRankSeason() {
    return legendSeasons.reduce((a, b) => a.rank < b.rank ? a : b);
  }

  LegendSeason getLastSeason() {
    return legendSeasons.first;
  }

  LegendSeason getBestAttackWinsSeason() {
    return legendSeasons.reduce((a, b) => a.attackWins > b.attackWins ? a : b);
  }

  String capitalize(String s) => s[0].toUpperCase() + s.substring(1);

  Widget buildSeasonInfo(
      LegendSeason legendsSeason, BuildContext context, String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          title,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        Text(
          capitalize(
            DateFormat(
                    'MMMM yyyy', Localizations.localeOf(context).languageCode)
                .format(
              DateTime(
                int.parse(legendsSeason.season.split('-')[0]),
                int.parse(legendsSeason.season.split('-')[1]),
              ),
            ),
          ),
          style: Theme.of(context).textTheme.labelMedium,
        ),
        SizedBox(height: 8),
        Row(
          children: <Widget>[
            SizedBox(
              height: 60,
              width: 60,
              child: Stack(
                children: <Widget>[
                  Center(
                    child: CachedNetworkImage(
                      imageUrl:
                          "https://assets.clashk.ing/icons/Icon_HV_League_Legend_3_No_Padding.png",
                      height: 80,
                    ),
                  ),
                  Align(
                    alignment: Alignment(0, -0.1),
                    child: Text(
                      NumberFormat('#,###',
                              Localizations.localeOf(context).toString())
                          .format(legendsSeason.rank),
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
            SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: [
                    CachedNetworkImage(
                      imageUrl:
                          "https://assets.clashk.ing/icons/Icon_HV_Trophy_Best.png",
                      height: 20,
                    ),
                    SizedBox(width: 4),
                    Text(
                      NumberFormat('#,###',
                              Localizations.localeOf(context).toString())
                          .format(legendsSeason.trophies),
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                  ],
                ),
                Row(
                  children: [
                    CachedNetworkImage(
                      imageUrl:
                          "https://assets.clashk.ing/icons/Icon_HV_Sword.png",
                      height: 20,
                    ),
                    SizedBox(width: 4),
                    Text(
                      NumberFormat('#,###',
                              Localizations.localeOf(context).toString())
                          .format(legendsSeason.attackWins),
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                    child: buildSeasonInfo(
                        getLastSeason(),
                        context,
                        AppLocalizations.of(context)?.lastSeason ??
                            "Last Season")),
                SizedBox(width: 16),
                Expanded(
                    child: buildSeasonInfo(
                        getBestGlobalRankSeason(),
                        context,
                        AppLocalizations.of(context)?.bestRank ??
                            "Best Global Rank")),
              ],
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                    child: buildSeasonInfo(
                        getBestTrophiesSeason(),
                        context,
                        AppLocalizations.of(context)?.bestTrophies ??
                            "Best Trophies")),
                SizedBox(width: 16),
                Expanded(
                    child: buildSeasonInfo(
                        getBestAttackWinsSeason(),
                        context,
                        AppLocalizations.of(context)?.mostAttacks ??
                            "Most Attacks")),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
