import 'package:cached_network_image/cached_network_image.dart';
import 'package:clashkingapp/core/constants/image_assets.dart';
import 'package:flutter/material.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:clashkingapp/features/player/models/player_legend_ranking.dart';

class PlayerLegendHistory extends StatelessWidget {
  const PlayerLegendHistory({
    super.key,
    required this.rankings,
  });

  final List<PlayerLegendRanking> rankings;

  PlayerLegendRanking getBestTrophiesSeason() {
    return rankings.reduce((a, b) => a.trophies > b.trophies ? a : b);
  }

  PlayerLegendRanking getBestGlobalRankSeason() {
    return rankings.reduce((a, b) => a.rank < b.rank ? a : b);
  }

  PlayerLegendRanking getLastSeason() {
    return rankings.first;
  }

  PlayerLegendRanking getBestAttackWinsSeason() {
    return rankings.reduce((a, b) => a.attackWins > b.attackWins ? a : b);
  }

  String capitalize(String s) => s[0].toUpperCase() + s.substring(1);

  Widget buildSeasonInfo(
      PlayerLegendRanking season, BuildContext context, String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Text(
          title,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        Text(
          capitalize(
            DateFormat('MMMM yyyy', Localizations.localeOf(context).languageCode)
                .format(
              DateTime(
                int.parse(season.season.split('-')[0]),
                int.parse(season.season.split('-')[1]),
              ),
            ),
          ),
          style: Theme.of(context).textTheme.labelMedium,
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            SizedBox(
              height: 60,
              width: 60,
              child: Stack(
                children: <Widget>[
                  Center(
                    child: CachedNetworkImage(
                      imageUrl: ImageAssets.legendBlazonBordersNoPadding,
                      height: 80,
                    ),
                  ),
                  Align(
                    alignment: const Alignment(0, -0.1),
                    child: Text(
                      NumberFormat('#,###', Localizations.localeOf(context).toString())
                          .format(season.rank),
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
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: [
                    CachedNetworkImage(
                      imageUrl: ImageAssets.bestTrophies,
                      height: 20,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      NumberFormat('#,###', Localizations.localeOf(context).toString())
                          .format(season.trophies),
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                  ],
                ),
                Row(
                  children: [
                    CachedNetworkImage(
                      imageUrl: ImageAssets.sword,
                      height: 20,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      NumberFormat('#,###', Localizations.localeOf(context).toString())
                          .format(season.attackWins),
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
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
                const SizedBox(width: 16),
                Expanded(
                    child: buildSeasonInfo(
                        getBestGlobalRankSeason(),
                        context,
                        AppLocalizations.of(context)?.bestRank ??
                            "Best Global Rank")),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                    child: buildSeasonInfo(
                        getBestTrophiesSeason(),
                        context,
                        AppLocalizations.of(context)?.bestTrophies ??
                            "Best Trophies")),
                const SizedBox(width: 16),
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