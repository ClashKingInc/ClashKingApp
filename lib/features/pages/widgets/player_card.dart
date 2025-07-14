import 'package:clashkingapp/core/constants/image_assets.dart';
import 'package:clashkingapp/features/player/data/player_service.dart';
import 'package:clashkingapp/features/player/presentation/player/player_page.dart';
import 'package:flutter/material.dart';
import 'package:clashkingapp/features/coc_accounts/data/coc_account_service.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:clashkingapp/common/widgets/buttons/chip.dart';

class PlayerCard extends StatelessWidget {
  const PlayerCard({super.key});

  @override
  Widget build(BuildContext context) {
    final playerService = context.watch<PlayerService>();
    final cocService = context.watch<CocAccountService>();
    final player = playerService.getSelectedProfile(cocService);

    if (player == null) {
      return Center(
        child: Text(
          AppLocalizations.of(context)?.authErrorConnectionRelaunch ??
              'Error, please restart',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      );
    }

    String warPreference = player.warPreference == 'in'
        ? AppLocalizations.of(context)?.warStatusReady ?? 'Ready'
        : AppLocalizations.of(context)?.warStatusUnready ?? 'Unready';

    return DefaultTextStyle(
      style: Theme.of(context).textTheme.labelLarge ?? TextStyle(),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PlayerScreen(selectedPlayer: player),
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
                          height: 100,
                          width: 100,
                          child: CachedNetworkImage(
                              errorWidget: (context, url, error) =>
                                  Icon(Icons.error),
                              imageUrl: player.townHallPic),
                        ),
                        Text(
                          player.name,
                          style: (Theme.of(context)
                                  .textTheme
                                  .labelLarge
                                  ?.copyWith(fontWeight: FontWeight.bold)) ??
                              TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          player.tag,
                          style: Theme.of(context).textTheme.labelLarge,
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
                              if (player.clan != null)
                                ImageChip(
                            context: context,
                                  imageUrl: player.clan!.badgeUrls.small,
                                  labelPadding: 2,
                                  label: player.clan!.name,
                                  description: AppLocalizations.of(context)!
                                      .playerClanDescription(
                                          player.clan!.name, player.clan!.tag),
                                ),
                              IconChip(
                                  icon: LucideIcons.chevronsUpDown,
                                  label: player.donationRatio,
                                  color: Color.fromARGB(255, 0, 136, 255),
                                  size: 20,
                                  description: AppLocalizations.of(context)!
                                      .playerRatioDescription(
                                          player.donationRatio,
                                          player.donations.toStringAsFixed(0),
                                          player.donationsReceived
                                              .toStringAsFixed(0))),
                              ImageChip(
                            context: context,
                                imageUrl: player.warPreferenceImage,
                                label: warPreference,
                                description: AppLocalizations.of(context)!
                                    .playerWarPreferenceDescription(
                                        warPreference),
                              ),
                              ImageChip(
                            context: context,
                                  imageUrl: ImageAssets.attackStar,
                                  label: NumberFormat(
                                          '#,###',
                                          Localizations.localeOf(context)
                                              .toString())
                                      .format(int.parse(
                                          player.warStars.toString())),
                                  description: AppLocalizations.of(context)!
                                      .playerWarStarsDescription(
                                          player.warStars)),
                              ImageChip(
                            context: context,
                                  imageUrl: player.townHallPic,
                                  label: player.townHallLevel.toString(),
                                  description: AppLocalizations.of(context)!
                                      .playerTownHallLevelDescription(
                                          player.townHallLevel)),
                              ImageChip(
                            context: context,
                                  imageUrl: player.leagueUrl,
                                  label: NumberFormat(
                                          '#,###',
                                          Localizations.localeOf(context)
                                              .toString())
                                      .format(int.parse(
                                          player.trophies.toString())),
                                  description: player.league == "Unranked"
                                      ? AppLocalizations.of(context)!
                                          .playerTrophiesUnrankedDescription(
                                              player.trophies)
                                      : AppLocalizations.of(context)!
                                          .playerTrophiesDescription(
                                              player.trophies, player.league)),
                              ImageChip(
                            context: context,
                                  imageUrl: player.builderHallPic,
                                  label: player.builderHallLevel.toString(),
                                  description: AppLocalizations.of(context)!
                                      .playerBuilderBaseDescription(
                                          player.builderHallLevel,
                                          player.builderBaseTrophies)),
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
