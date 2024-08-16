import 'package:flutter/material.dart';
import 'package:clashkingapp/classes/profile/profile_info.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:clashkingapp/main_pages/dashboard_page/player_dashboard/player_info_page.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:clashkingapp/components/chip.dart';

class PlayerInfosCard extends StatelessWidget {
  const PlayerInfosCard({
    super.key,
    required this.playerStats,
    required this.discordUser,
  });

  final ProfileInfo playerStats;
  final List<String> discordUser;

  @override
  Widget build(BuildContext context) {
    double ratioDonation = playerStats.donations /
        (playerStats.donationsReceived == 0
            ? 1
            : playerStats.donationsReceived);
    String imageOptInOut = playerStats.warPreference == 'in'
        ? "https://assets.clashk.ing/icons/Icon_HV_In.png"
        : 'https://assets.clashk.ing/icons/Icon_HV_Out.png';
    String warPreference = playerStats.warPreference == 'in'
        ? AppLocalizations.of(context)?.ready ?? 'Ready'
        : AppLocalizations.of(context)?.unready ?? 'Unready';
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                StatsScreen(playerStats: playerStats, discordUser: discordUser),
          ),
        );
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
                              imageUrl: playerStats.townHallPic),
                        ),
                        Text(
                          playerStats.name,
                          style: (Theme.of(context)
                                  .textTheme
                                  .labelLarge
                                  ?.copyWith(fontWeight: FontWeight.bold)) ??
                              TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          playerStats.tag,
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
                              if (playerStats.clan != null)
                                ImageChip(
                                  imageUrl: playerStats.clan!.badgeUrls.small,
                                  labelPadding: 2,
                                  label: playerStats.clan!.name,
                                  description: AppLocalizations.of(context)!
                                      .playerClanDescription(
                                          playerStats.clan!.name,
                                          playerStats.clan!.tag),
                                ),
                              IconChip(
                                  icon: LucideIcons.chevronsUpDown,
                                  label: ratioDonation.toStringAsFixed(2),
                                  color: Color.fromARGB(255, 0, 136, 255),
                                  size: 20,
                                  description: AppLocalizations.of(context)!
                                      .playerRatioDescription(
                                          ratioDonation.toStringAsFixed(2),
                                          playerStats.donations
                                              .toStringAsFixed(0),
                                          playerStats.donationsReceived
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
                                  label: playerStats.warStars.toString(),
                                  description: AppLocalizations.of(context)!
                                      .playerWarStarsDescription(
                                          playerStats.warStars)),
                              ImageChip(
                                  imageUrl: playerStats.townHallPic,
                                  label: playerStats.townHallLevel.toString(),
                                  description: AppLocalizations.of(context)!
                                      .playerTownHallLevelDescription(
                                          playerStats.townHallLevel)),
                              ImageChip(
                                  imageUrl: playerStats.leagueUrl,
                                  label: playerStats.trophies.toString(),
                                  description: AppLocalizations.of(context)!
                                      .playerTrophiesDescription(
                                          playerStats.trophies,
                                          playerStats.league)),
                              ImageChip(
                                  imageUrl: playerStats.builderHallPic,
                                  label:
                                      playerStats.builderHallLevel.toString(),
                                  description: AppLocalizations.of(context)!
                                      .playerBuilderBaseDescription(
                                          playerStats.builderHallLevel, playerStats.builderBaseTrophies)),
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
