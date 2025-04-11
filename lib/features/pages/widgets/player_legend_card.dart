import 'package:clashkingapp/common/widgets/mobile_web_image.dart';
import 'package:clashkingapp/core/constants/image_assets.dart';
import 'package:clashkingapp/features/coc_accounts/data/coc_account_service.dart';
import 'package:clashkingapp/features/player/data/player_service.dart';
import 'package:clashkingapp/features/player/models/player_legend_day.dart';
import 'package:clashkingapp/features/player/models/player_legend_season.dart';
import 'package:clashkingapp/features/player/presentation/legend/player_legend_page.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';
import 'package:clashkingapp/common/widgets/buttons/chip.dart';
import 'package:provider/provider.dart';

class PlayerLegendCard extends StatelessWidget {
  const PlayerLegendCard({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final playerService = context.watch<PlayerService>();
    final cocService = context.watch<CocAccountService>();
    final player = playerService.getSelectedProfile(cocService);
    final isLegend = player!.league == "Legend League";
    PlayerLegendSeason? currentSeason;
    PlayerLegendDay? currentDay;

    if (isLegend) {
      currentSeason = player.currentLegendSeason;
      currentDay = currentSeason?.currentDay;
    }

    return GestureDetector(
      onTap: () {
        if (player.legendsBySeason != null &&
            player.legendsBySeason!.allSeasons.isNotEmpty) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => LegendScreen(),
            ),
          );
        }
      },
      child: player.legendsBySeason != null &&
              player.legendsBySeason!.allSeasons.isNotEmpty
          ? Card(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: [
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            Column(
                              children: [
                                Text(
                                  AppLocalizations.of(context)!.legendLeague,
                                  style: Theme.of(context).textTheme.labelLarge,
                                ),
                                MobileWebImage(
                                  imageUrl: ImageAssets.legendBlazon,
                                  width: 100,
                                  height: 100,
                                ),
                              ],
                            ),
                            if (isLegend)
                              Positioned(
                                bottom: 40,
                                child: Text(
                                  NumberFormat(
                                          '#,###',
                                          Localizations.localeOf(context)
                                              .toString())
                                      .format(player.trophies),
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleSmall
                                      ?.copyWith(color: Colors.white),
                                ),
                              ),
                          ],
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: currentDay != null
                              ? Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: -6,
                                        runAlignment: WrapAlignment.center,
                                        children: [
                                          if (player.rankings?.countryCode != null && player.rankings?.countryCode != "")
                                            ImageChip(
                                                imageUrl: ImageAssets.flag(
                                                    player.rankings?.countryCode ??
                                                        ""),
                                                label: player.rankings?.localRank != 0
                                                    ? NumberFormat('#,###', Localizations.localeOf(context).toString())
                                                        .format(player.rankings
                                                            ?.localRank)
                                                    : AppLocalizations.of(context)!
                                                        .noRank,
                                                description: player.rankings?.localRank != 0
                                                    ? AppLocalizations.of(context)!
                                                        .legendRankLocalDescription(
                                                            player.rankings!.countryName ?? "",
                                                            "${player.rankings?.localRank}",
                                                            "${player.trophies}")
                                                    : AppLocalizations.of(context)!.legendNoRankLocalDescription(player.rankings!.countryName ?? "", player.trophies)),
                                          if (player.rankings?.countryCode != null &&
                                              player.rankings?.countryCode !=
                                                  "" &&
                                              player.rankings?.globalRank != 0)
                                            ImageChip(
                                                imageUrl: ImageAssets.planet,
                                                label: player.rankings?.globalRank != null
                                                    ? NumberFormat('#,###', Localizations.localeOf(context).toString())
                                                        .format(player.rankings
                                                            ?.globalRank)
                                                    : "N/A",
                                                description: player.rankings?.globalRank != null
                                                    ? AppLocalizations.of(context)!
                                                        .legendGlobalRankDescription(
                                                            player.rankings?.globalRank ??
                                                                0,
                                                            "${player.trophies}")
                                                    : AppLocalizations.of(context)!
                                                        .legendNoGlobalRankDescription(player.trophies)),
                                          ImageChip(
                                            imageUrl:
                                                ImageAssets.legendStartFlag,
                                            label: NumberFormat(
                                                    '#,###',
                                                    Localizations.localeOf(
                                                            context)
                                                        .toString())
                                                .format(
                                                    currentDay.startTrophies ??
                                                        0),
                                            description: AppLocalizations.of(
                                                    context)!
                                                .legendStartDescription(
                                                    "${currentDay.startTrophies ?? 0}"),
                                          ),
                                          ImageChip(
                                            imageUrl: ImageAssets.sword,
                                            labelWidget: RichText(
                                              text: TextSpan(
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .labelLarge,
                                                children: [
                                                  TextSpan(
                                                      text:
                                                          "${currentDay.totalAttacks}"),
                                                  WidgetSpan(
                                                    child: Transform.translate(
                                                      offset:
                                                          const Offset(2, -6),
                                                      child: Text(
                                                        "(+${currentDay.trophiesGainedTotal})",
                                                        style: Theme.of(context)
                                                            .textTheme
                                                            .labelSmall,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            description: "",
                                          ),
                                          ImageChip(
                                            imageUrl:
                                                ImageAssets.shieldWithArrow,
                                            labelWidget: RichText(
                                              text: TextSpan(
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .labelLarge,
                                                children: [
                                                  TextSpan(
                                                      text:
                                                          "${currentDay.totalDefenses}"),
                                                  WidgetSpan(
                                                    child: Transform.translate(
                                                      offset:
                                                          const Offset(2, -6),
                                                      child: Text(
                                                        "(-${currentDay.trophiesLostTotal})",
                                                        style: Theme.of(context)
                                                            .textTheme
                                                            .labelSmall,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            description: "",
                                          ),
                                          IconChip(
                                            icon: currentDay.trophiesTotal >= 0
                                                ? LucideIcons.chevronUp
                                                : LucideIcons.chevronDown,
                                            color: currentDay.trophiesTotal >= 0
                                                ? Colors.green
                                                : Colors.red,
                                            size: 16,
                                            label:
                                                "${currentDay.trophiesTotal >= 0 ? '+' : ''}${currentDay.trophiesTotal}",
                                            description: currentDay
                                                        .trophiesTotal >=
                                                    0
                                                ? AppLocalizations.of(context)!
                                                    .legendGainDescription(
                                                        currentDay
                                                            .trophiesTotal)
                                                : AppLocalizations.of(context)!
                                                    .legendLossDescription(
                                                        -currentDay
                                                            .trophiesTotal),
                                          ),
                                        ],
                                      )
                                    ])
                              : isLegend
                                  ? Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                          Wrap(
                                            spacing: 8,
                                            runSpacing: -6,
                                            runAlignment: WrapAlignment.center,
                                            children: [
                                              if (player.rankings?.countryCode != null && player.rankings?.countryCode != "")
                                                ImageChip(
                                                    imageUrl: ImageAssets.flag(
                                                        player.rankings?.countryCode ??
                                                            ""),
                                                    label: player.rankings?.localRank != 0
                                                        ? NumberFormat('#,###', Localizations.localeOf(context).toString())
                                                            .format(player
                                                                .rankings
                                                                ?.localRank)
                                                        : AppLocalizations.of(context)!
                                                            .noRank,
                                                    description: player.rankings?.localRank != 0
                                                        ? AppLocalizations.of(context)!
                                                            .legendRankLocalDescription(
                                                                player.rankings!.countryName ?? "",
                                                                "${player.rankings?.localRank}",
                                                                "${player.trophies}")
                                                        : AppLocalizations.of(context)!.legendNoRankLocalDescription(player.rankings!.countryName ?? "", player.trophies)),
                                              if (player.rankings?.countryCode != null &&
                                                  player.rankings?.countryCode !=
                                                      "" &&
                                                  player.rankings?.globalRank !=
                                                      0)
                                                ImageChip(
                                                    imageUrl:
                                                        ImageAssets.planet,
                                                    label: player.rankings?.globalRank != null
                                                        ? NumberFormat('#,###', Localizations.localeOf(context).toString())
                                                            .format(player
                                                                .rankings
                                                                ?.globalRank)
                                                        : "N/A",
                                                    description: player.rankings?.globalRank != null
                                                        ? AppLocalizations.of(context)!
                                                            .legendGlobalRankDescription(
                                                                player.rankings?.globalRank ?? 0,
                                                                "${player.trophies}")
                                                        : AppLocalizations.of(context)!.legendNoGlobalRankDescription(player.trophies)),
                                              ImageChip(
                                                imageUrl:
                                                    ImageAssets.legendStartFlag,
                                                label: NumberFormat(
                                                        '#,###',
                                                        Localizations.localeOf(
                                                                context)
                                                            .toString())
                                                    .format(player.trophies),
                                                description: AppLocalizations
                                                        .of(context)!
                                                    .legendStartDescription(
                                                        "${player.trophies}"),
                                              ),
                                              ImageChip(
                                                imageUrl: ImageAssets.sword,
                                                labelWidget: RichText(
                                                  text: TextSpan(
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .labelLarge,
                                                    children: [
                                                      TextSpan(text: "0"),
                                                      WidgetSpan(
                                                        child:
                                                            Transform.translate(
                                                          offset: const Offset(
                                                              2, -6),
                                                          child: Text(
                                                            "(+0)",
                                                            style: Theme.of(
                                                                    context)
                                                                .textTheme
                                                                .labelSmall,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                description: "",
                                              ),
                                              ImageChip(
                                                imageUrl:
                                                    ImageAssets.shieldWithArrow,
                                                labelWidget: RichText(
                                                  text: TextSpan(
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .labelLarge,
                                                    children: [
                                                      TextSpan(text: "0"),
                                                      WidgetSpan(
                                                        child:
                                                            Transform.translate(
                                                          offset: const Offset(
                                                              2, -6),
                                                          child: Text(
                                                            "(-0)",
                                                            style: Theme.of(
                                                                    context)
                                                                .textTheme
                                                                .labelSmall,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                description: "",
                                              ),
                                              IconChip(
                                                  icon: LucideIcons.equal,
                                                  color: Colors.blue,
                                                  size: 16,
                                                  label: "0",
                                                  description: AppLocalizations
                                                          .of(context)!
                                                      .legendGainDescription(
                                                          0)),
                                            ],
                                          )
                                        ])
                                  : Text(
                                      AppLocalizations.of(context)!
                                          .noLegendsDataToday,
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelLarge),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            )
          : SizedBox.shrink(),
    );
  }
}
