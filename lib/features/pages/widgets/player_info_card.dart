import 'package:clashkingapp/features/player/data/player_service.dart';
import 'package:flutter/material.dart';
import 'package:clashkingapp/features/coc_accounts/data/coc_account_service.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:clashkingapp/common/widgets/buttons/chip.dart';
import 'package:provider/provider.dart';

class PlayerInfosCard extends StatelessWidget {
  const PlayerInfosCard({super.key});

  @override
  Widget build(BuildContext context) {
    final playerService = context.watch<PlayerService>();
    final cocAccountService = context.watch<CocAccountService>();
    final selectedProfile = playerService.getSelectedProfile(cocAccountService);

    if (selectedProfile == null) {
      return Center(
        child: CircularProgressIndicator(),
      );
    }

    double ratioDonation = selectedProfile.donations /
        (selectedProfile.donationsReceived == 0
            ? 1
            : selectedProfile.donationsReceived);

    String imageOptInOut = selectedProfile.warPreference == 'in'
        ? "https://assets.clashk.ing/icons/Icon_HV_In.png"
        : 'https://assets.clashk.ing/icons/Icon_HV_Out.png';

    String warPreference = selectedProfile.warPreference == 'in'
        ? AppLocalizations.of(context)?.ready ?? 'Ready'
        : AppLocalizations.of(context)?.unready ?? 'Unready';

    return GestureDetector(
      onTap: () {
        /*
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => StatsScreen(
              playerStats: selectedProfile,
              discordUser: cocService.getAccountTags(), // Liste des tags
            ),
          ),
        );*/
      },
      child: DefaultTextStyle(
        style: Theme.of(context).textTheme.labelLarge ?? TextStyle(),
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
                              imageUrl: selectedProfile.townHallPic),
                        ),
                        Text(
                          selectedProfile.name,
                          style: Theme.of(context)
                                  .textTheme
                                  .labelLarge
                                  ?.copyWith(fontWeight: FontWeight.bold) ??
                              TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          selectedProfile.tag,
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
                              /*if (selectedProfile.clan != null)
                                ImageChip(
                                  imageUrl: selectedProfile.clan!.badgeUrls.small,
                                  labelPadding: 2,
                                  label: selectedProfile.clan!.name,
                                  description: AppLocalizations.of(context)!
                                      .playerClanDescription(
                                          selectedProfile.clan!.name,
                                          selectedProfile.clan!.tag),
                                ),*/
                              IconChip(
                                  icon: LucideIcons.chevronsUpDown,
                                  label: ratioDonation.toStringAsFixed(2),
                                  color: Color.fromARGB(255, 0, 136, 255),
                                  size: 20,
                                  description: AppLocalizations.of(context)!
                                      .playerRatioDescription(
                                          ratioDonation.toStringAsFixed(2),
                                          selectedProfile.donations
                                              .toStringAsFixed(0),
                                          selectedProfile.donationsReceived
                                              .toStringAsFixed(0))),
                              ImageChip(
                                imageUrl: imageOptInOut,
                                label: warPreference,
                                description: AppLocalizations.of(context)!
                                    .playerWarPreferenceDescription(
                                        warPreference),
                              ),
                              ImageChip(
                                  imageUrl:
                                      "https://assets.clashk.ing/icons/Icon_HV_Attack_Star.png",
                                  label: NumberFormat(
                                          '#,###',
                                          Localizations.localeOf(context)
                                              .toString())
                                      .format(int.parse(
                                          selectedProfile.warStars.toString())),
                                  description: AppLocalizations.of(context)!
                                      .playerWarStarsDescription(
                                          selectedProfile.warStars)),
                              ImageChip(
                                  imageUrl: selectedProfile.townHallPic,
                                  label:
                                      selectedProfile.townHallLevel.toString(),
                                  description: AppLocalizations.of(context)!
                                      .playerTownHallLevelDescription(
                                          selectedProfile.townHallLevel)),
                              ImageChip(
                                  imageUrl: selectedProfile.leagueUrl,
                                  label: NumberFormat(
                                          '#,###',
                                          Localizations.localeOf(context)
                                              .toString())
                                      .format(int.parse(
                                          selectedProfile.trophies.toString())),
                                  description: AppLocalizations.of(context)!
                                      .playerTrophiesDescription(
                                          selectedProfile.trophies,
                                          selectedProfile.league)),
                              ImageChip(
                                  imageUrl: selectedProfile.builderHallPic,
                                  label: selectedProfile.builderHallLevel
                                      .toString(),
                                  description: AppLocalizations.of(context)!
                                      .playerBuilderBaseDescription(
                                          selectedProfile.builderHallLevel,
                                          selectedProfile.builderBaseTrophies)),
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
