import 'package:clashkingapp/core/constants/image_assets.dart';
import 'package:clashkingapp/features/clan/data/clan_service.dart';
import 'package:clashkingapp/features/coc_accounts/data/coc_account_service.dart';
import 'package:clashkingapp/features/player/data/player_service.dart';
import 'package:clashkingapp/features/war_cwl/data/war_cwl_service.dart';
import 'package:flutter/material.dart';
import 'package:clashkingapp/common/widgets/buttons/chip.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

class CwlCard extends StatefulWidget {
  const CwlCard({super.key});

  @override
  CwlCardState createState() => CwlCardState();
}

class CwlCardState extends State<CwlCard> {
  @override
  Widget build(BuildContext context) {
    final cocService = context.watch<CocAccountService>();
    final warCwlService = context.watch<WarCwlService>();
    final playerService = context.watch<PlayerService>();
    final clanService = context.watch<ClanService>();

    final clanTag = playerService.getSelectedProfile(cocService)?.clanTag;
    if (clanTag == null || clanTag.isEmpty) {
      return SizedBox.shrink();
    }

    final clanWarLeague = clanService.getClanByTag(clanTag)?.warLeague?.name;
    final warCwl = warCwlService.getWarCwlByTag(clanTag);
    final clan = warCwl?.leagueInfo?.clans
        .firstWhere((element) => element.tag == clanTag);

    if (clanWarLeague == null || clan == null) {
      return SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            SizedBox(
              height: 70,
              width: 70,
              child: CachedNetworkImage(
                errorWidget: (context, url, error) => Icon(Icons.error),
                imageUrl: ImageAssets.leagues[clanWarLeague]!,
              ),
            ),
            SizedBox(width: 24),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    alignment: WrapAlignment.start,
                    spacing: 7.0,
                    runSpacing: -7.0,
                    children: [
                      ImageChip(
                            context: context,
                        imageUrl:
                            "https://assets.clashk.ing/icons/Icon_HV_Podium.png",
                        labelPadding: 4,
                        label: "Rank ${clan.rank.toString()}",
                        description:
                            AppLocalizations.of(context)!.cwlRank(clan.rank),
                      ),
                      ImageChip(
                            context: context,
                        imageUrl: ImageAssets.war,
                        labelPadding: 2,
                        label: " Round ${clan.warsPlayed.toString()}",
                        description: AppLocalizations.of(context)!
                            .cwlCurrentRound(clan.warsPlayed),
                      ),
                      ImageChip(
                            context: context,
                        imageUrl: ImageAssets.builderBaseStar,
                        labelPadding: 2,
                        label: clan.stars.toString(),
                        description:
                            AppLocalizations.of(context)!.cwlStars(clan.stars),
                      ),
                      ImageChip(
                            context: context,
                        imageUrl: ImageAssets.hitrate,
                        labelPadding: 2,
                        label: clan.destructionPercentageInflicted
                            .toStringAsFixed(0),
                        description: AppLocalizations.of(context)!
                            .cwlDestructionPercentage(
                          clan.destructionPercentageInflicted
                              .toStringAsFixed(0),
                        ),
                      ),
                      ImageChip(
                            context: context,
                        imageUrl: ImageAssets.sword,
                        labelPadding: 2,
                        label:
                            "${clan.attackCount.toString()}/${warCwl?.teamSize * clan.warsPlayed}",
                        description: AppLocalizations.of(context)!
                            .cwlTotalAttacks(clan.attackCount,
                                warCwl?.teamSize * clan.warsPlayed),
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
