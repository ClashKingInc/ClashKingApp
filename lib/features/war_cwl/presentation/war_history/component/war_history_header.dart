import 'dart:ui';
import 'package:clashkingapp/common/widgets/buttons/chip.dart';
import 'package:clashkingapp/features/clan/models/clan.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';

class WarHistoryHeader extends StatelessWidget {
  const WarHistoryHeader({
    super.key,
    required this.clan,
  });

  final Clan clan;

  @override
  Widget build(BuildContext context) {
    final warLogStats = clan.clanWarLog!.warLogStats;
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.bottomCenter,
      children: <Widget>[
        SizedBox(
          height: 200,
          child: ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 1, sigmaY: 1),
            child: ColorFiltered(
              colorFilter: ColorFilter.mode(
                Colors.black.withValues(alpha: 0.5),
                BlendMode.darken,
              ),
              child: CachedNetworkImage(
                errorWidget: (context, url, error) => Icon(Icons.error),
                imageUrl:
                    "https://assets.clashk.ing/landscape/war-landscape.jpg",
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
        Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  height: 60,
                  width: 60,
                  child: CachedNetworkImage(
                      errorWidget: (context, url, error) => Icon(Icons.error),
                      imageUrl: clan.badgeUrls.medium),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      clan.name,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(color: Colors.white),
                    ),
                    Text(
                      clan.tag,
                      style: Theme.of(context)
                          .textTheme
                          .labelLarge
                          ?.copyWith(color: Colors.white),
                    ),
                  ],
                ),
              ],
            ),
            Wrap(
              alignment: WrapAlignment.start,
              spacing: 7.0,
              runSpacing: -7.0,
              children: <Widget>[
                ImageChip(
                            context: context,
                    textColor: Colors.white,
                    imageUrl:
                        "https://assets.clashk.ing/icons/Icon_HV_Clan_War.png",
                    label: warLogStats.totalWars.toString()),
                IconChip(
                    icon: Icons.circle,
                    color: Colors.green,
                    textColor: Colors.white,
                    size: 16,
                    labelPadding: 2,
                    label: warLogStats.totalWins.toString(),
                    description: AppLocalizations.of(context)!
                        .warHistoryWinsDescription(
                            warLogStats.totalWins, warLogStats.winPercentage)),
                IconChip(
                    icon: Icons.circle,
                    color: Colors.red,
                    textColor: Colors.white,
                    size: 16,
                    labelPadding: 2,
                    label: warLogStats.totalLosses.toString(),
                    description: AppLocalizations.of(context)!
                        .warHistoryLossesDescription(warLogStats.totalLosses,
                            warLogStats.lossPercentage)),
                IconChip(
                    icon: Icons.circle,
                    color: Colors.blue,
                    textColor: Colors.white,
                    size: 16,
                    labelPadding: 2,
                    label: warLogStats.totalTies.toString(),
                    description: AppLocalizations.of(context)!
                        .warHistoryDrawsDescription(
                            warLogStats.totalTies, warLogStats.tiePercentage)),
              ],
            ),
            SizedBox(height: 24),
          ],
        ),
        Positioned(
          top: 40,
          left: 10,
          child: IconButton(
            icon: Icon(Icons.arrow_back,
                color: Theme.of(context).colorScheme.onPrimary, size: 32),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
      ],
    );
  }
}
