import 'package:flutter/material.dart';
import 'package:clashkingapp/main_pages/dashboard_page/legend_dashboard/player_legend_page.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:clashkingapp/classes/profile/legend/legend_data.dart';
import 'package:clashkingapp/components/info_button.dart';

class LegendHeaderCard extends StatelessWidget {
  const LegendHeaderCard({
    super.key,
    required this.widget,
    required this.legendData,
  });

  final LegendScreen widget;
  final PlayerLegendData legendData;


  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        SizedBox(
          height: 240,
          width: double.infinity,
          child: ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 1, sigmaY: 1),
            child: ColorFiltered(
                colorFilter: ColorFilter.mode(
                  Colors.black.withOpacity(0.7),
                  BlendMode.darken,
                ),
                child: CachedNetworkImage(
                  imageUrl:
                      "https://assets.clashk.ing/landscape/legend-landscape.png",
                  width: double.infinity,
                  fit: BoxFit.cover,
                )),
          ),
        ),
        Positioned(
          top: 26,
          bottom: 0,
          left: 10,
          right: 10,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Center(
                child: Column(
                  children: [
                    Text(
                      legendData.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                          ),
                    ),
                    Text(legendData.tag,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: Colors.grey,
                            )),
                    SizedBox(height: 10),
                    if (widget.playerLegendData.currentTrophies != "0")
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CachedNetworkImage(
                            imageUrl:
                                "https://assets.clashk.ing/icons/Icon_HV_League_Legend_3_Border.png",
                            width: 60,
                          ),
                          Text(widget.playerLegendData.currentTrophies,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontSize: 32,
                                  )),
                          SizedBox(width: 8),
                          Column(
                            children: [
                              Text(
                                "(${widget.playerLegendData.diffTrophies >= 0 ? '+' : ''}${widget.playerLegendData.diffTrophies.toString()})",
                                style: Theme.of(context)
                                    .textTheme
                                    .labelMedium
                                    ?.copyWith(
                                        color: widget.playerLegendData
                                                    .diffTrophies >=
                                                0
                                            ? Colors.green
                                            : Colors.red),
                              ),
                              SizedBox(height: 32),
                            ],
                          ),
                        ],
                      ),
                    if (widget.playerLegendData.currentTrophies == "0")
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CachedNetworkImage(
                            imageUrl:
                                "https://assets.clashk.ing/icons/Icon_HV_League_Legend_3_Border.png",
                            width: 60,
                          ),
                          Text(
                            AppLocalizations.of(context)!.notInLegendLeague,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: Colors.white),
                          ),
                        ],
                      ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              Wrap(
                                spacing: 8,
                                runSpacing: 0,
                                children: <Widget>[
                                  if (legendData.rankings['country_code'] !=
                                      null)
                                    Chip(
                                      avatar: CircleAvatar(
                                          backgroundColor: Colors.transparent,
                                          child: CachedNetworkImage(
                                              imageUrl:
                                                  "https://assets.clashk.ing/country-flags/${legendData.rankings['country_code']!.toLowerCase() ?? 'uk'}.png")),
                                      label: Text(
                                        legendData.rankings['country_name'] ==
                                                null
                                            ? 'No Country'
                                            : '${legendData.rankings['country_name']}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelMedium
                                            ?.copyWith(color: Colors.white),
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        side: BorderSide(
                                            color: Colors.white, width: 1),
                                      ),
                                    ),
                                  if (legendData.rankings['country_code'] !=
                                      null)
                                    Chip(
                                      avatar: CircleAvatar(
                                          backgroundColor: Colors.transparent,
                                          child: CachedNetworkImage(
                                              imageUrl:
                                                  "https://assets.clashk.ing/country-flags/${legendData.rankings['country_code']!.toLowerCase() ?? 'uk'}.png")),
                                      label: Text(
                                        legendData.rankings['local_rank'] ==
                                                null
                                            ? AppLocalizations.of(context)
                                                    ?.noRank ??
                                                'No rank'
                                            : '${legendData.rankings['local_rank']}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelMedium
                                            ?.copyWith(color: Colors.white),
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        side: BorderSide(
                                            color: Colors.white, width: 1),
                                      ),
                                    ),
                                  Chip(
                                    avatar: CircleAvatar(
                                        backgroundColor: Colors
                                            .transparent, // Set to a suitable color for your design.
                                        child: CachedNetworkImage(
                                            imageUrl:
                                                "https://assets.clashk.ing/icons/Icon_HV_Planet.png")),
                                    label: Text(
                                        legendData.rankings['global_rank'] ==
                                                null
                                            ? AppLocalizations.of(context)
                                                    ?.noRank ??
                                                'No rank'
                                            : NumberFormat('#,###', 'fr_FR')
                                                .format(legendData
                                                    .rankings['global_rank']),
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelMedium
                                            ?.copyWith(color: Colors.white)),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      side: BorderSide(
                                          color: Colors.white, width: 1),
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
            ],
          ),
        ),
        Positioned(
          top: 30,
          left: 10,
          child: IconButton(
            icon: Icon(Icons.arrow_back,
                color: Theme.of(context).colorScheme.onPrimary, size: 32),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),InfoButton(
            textSpan: TextSpan(
              children: [
                TextSpan(text: "${AppLocalizations.of(context)!.legendsExplanation_intro}\n"),
                TextSpan(text: "${AppLocalizations.of(context)!.legendsExplanation_api_delay_title}\n", style: TextStyle(fontWeight: FontWeight.bold)),
                TextSpan(text: "${AppLocalizations.of(context)!.legendsExplanation_api_delay_body}\n"),
                TextSpan(text: AppLocalizations.of(context)!.legendsExplanation_concurrent_changes_title, style: TextStyle(fontWeight: FontWeight.bold)),
                TextSpan(text: AppLocalizations.of(context)!.legendsExplanation_multiple_attacks_defenses_title, style: TextStyle(fontWeight: FontWeight.bold)),
                TextSpan(text: AppLocalizations.of(context)!.legendsExplanation_multiple_attacks_defenses_body),
                TextSpan(text: AppLocalizations.of(context)!.legendsExplanation_simultaneous_attack_defense_title, style: TextStyle(fontWeight: FontWeight.bold)),
                TextSpan(text: "${AppLocalizations.of(context)!.legendsExplanation_simultaneous_attack_defense_body}\n"),
                TextSpan(text: "${AppLocalizations.of(context)!.legendsExplanation_net_gain_loss_title}\n", style: TextStyle(fontWeight: FontWeight.bold)),
                TextSpan(text: "${AppLocalizations.of(context)!.legendsExplanation_net_gain_loss_body}\n\n"),
                TextSpan(text: AppLocalizations.of(context)!.legendsExplanation_conclusion),
              ],
            ),
            title: AppLocalizations.of(context)!.legendsTitle,
          ),
      ],
    );
  }
}
