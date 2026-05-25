import 'package:clashkingapp/common/widgets/mobile_web_image.dart';
import 'package:clashkingapp/core/constants/image_assets.dart';
import 'package:clashkingapp/features/coc_accounts/data/coc_account_service.dart';
import 'package:clashkingapp/features/player/data/player_service.dart';
import 'package:clashkingapp/features/player/models/player_legend_day.dart';
import 'package:clashkingapp/features/player/models/player_legend_season.dart';
import 'package:clashkingapp/features/player/models/player_rankings.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';
import 'package:clashkingapp/common/widgets/buttons/chip.dart';
import 'package:provider/provider.dart';

const String _numberFormat = '#,###';

Widget? _buildLocalRankChip(BuildContext context, PlayerRankings? rankings, int trophies) {
  if (rankings?.countryCode == null || rankings?.countryCode == '') return null;

  final localizations = AppLocalizations.of(context)!;
  final locale = Localizations.localeOf(context).toString();
  final localRank = rankings?.localRank ?? 0;
  final countryName = rankings?.countryName ?? '';
  late final String label;
  late final String description;

  if (localRank != 0) {
    label = NumberFormat(_numberFormat, locale).format(localRank);
    description = localizations.legendsRankLocalDescription(
      localRank,
      countryName,
      trophies,
    );
  } else {
    label = localizations.legendsNoRank;
    description = localizations.legendsNoRankLocalDescription(
      countryName,
      trophies,
    );
  }

  return ImageChip(
    context: context,
    imageUrl: ImageAssets.flag(rankings?.countryCode ?? ''),
    label: label,
    description: description,
  );
}

Widget? _buildGlobalRankChip(BuildContext context, PlayerRankings? rankings, int trophies) {
  if (rankings?.countryCode == null ||
      rankings?.countryCode == '' ||
      rankings?.globalRank == null ||
      rankings?.globalRank == 0) {
    return null;
  }

  final locale = Localizations.localeOf(context).toString();
  final globalRank = rankings?.globalRank ?? 0;

  return ImageChip(
    context: context,
    imageUrl: ImageAssets.planet,
    label: NumberFormat(_numberFormat, locale).format(globalRank),
    description: AppLocalizations.of(context)!.legendsGlobalRankDescription(
      globalRank,
      trophies,
    ),
  );
}

Widget _buildTrophiesTotalChip(BuildContext context, int trophiesTotal) {
  final localizations = AppLocalizations.of(context)!;
  final isGain = trophiesTotal >= 0;
  final icon = isGain ? LucideIcons.chevronUp : LucideIcons.chevronDown;
  final color = isGain ? Colors.green : Colors.red;
  final labelPrefix = isGain ? '+' : '';
  final description = isGain
      ? localizations.legendsGainDescription(trophiesTotal)
      : localizations.legendsLossDescription(-trophiesTotal);

  return IconChip(
    icon: icon,
    color: color,
    size: 16,
    label: '$labelPrefix$trophiesTotal',
    description: description,
  );
}

class PlayerLegendCard extends StatelessWidget {
  const PlayerLegendCard({super.key});

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

    final localRankChip = _buildLocalRankChip(
      context,
      player.rankings,
      player.trophies,
    );
    final globalRankChip = _buildGlobalRankChip(
      context,
      player.rankings,
      player.trophies,
    );

    return Column(
      children: [
        player.legendsBySeason != null &&
                player.legendsBySeason!.allSeasons.isNotEmpty
            ? Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
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
                                    AppLocalizations.of(context)!.legendsTitle,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.labelLarge,
                                  ),
                                  const MobileWebImage(
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
                                      _numberFormat,
                                      Localizations.localeOf(
                                        context,
                                      ).toString(),
                                    ).format(player.trophies),
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(color: Colors.white),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(width: 12),
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
                                          if (localRankChip != null)
                                            localRankChip,
                                          if (globalRankChip != null)
                                            globalRankChip,
                                          ImageChip(
                                            context: context,
                                            imageUrl:
                                                ImageAssets.legendStartFlag,
                                            label:
                                                NumberFormat(
                                                  _numberFormat,
                                                  Localizations.localeOf(
                                                    context,
                                                  ).toString(),
                                                ).format(
                                                  currentDay.startTrophies ?? 0,
                                                ),
                                            description:
                                                AppLocalizations.of(
                                                  context,
                                                )!.legendsStartDescription(
                                                  "${currentDay.startTrophies ?? 0}",
                                                ),
                                          ),
                                          ImageChip(
                                            context: context,
                                            imageUrl: ImageAssets.sword,
                                            labelWidget: RichText(
                                              text: TextSpan(
                                                style: Theme.of(
                                                  context,
                                                ).textTheme.labelLarge,
                                                children: [
                                                  TextSpan(
                                                    text:
                                                        "${currentDay.totalAttacks}",
                                                  ),
                                                  WidgetSpan(
                                                    child: Transform.translate(
                                                      offset: const Offset(
                                                        2,
                                                        -6,
                                                      ),
                                                      child: Text(
                                                        "(+${currentDay.trophiesGainedTotal})",
                                                        style: Theme.of(
                                                          context,
                                                        ).textTheme.labelSmall,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            description:
                                                AppLocalizations.of(
                                                  context,
                                                )!.todoAttacksLeftDescription(
                                                  (8 - currentDay.totalAttacks),
                                                  AppLocalizations.of(
                                                    context,
                                                  )!.legendsTitle,
                                                ),
                                          ),
                                          ImageChip(
                                            context: context,
                                            imageUrl:
                                                ImageAssets.shieldWithArrow,
                                            labelWidget: RichText(
                                              text: TextSpan(
                                                style: Theme.of(
                                                  context,
                                                ).textTheme.labelLarge,
                                                children: [
                                                  TextSpan(
                                                    text:
                                                        "${currentDay.totalDefenses}",
                                                  ),
                                                  WidgetSpan(
                                                    child: Transform.translate(
                                                      offset: const Offset(
                                                        2,
                                                        -6,
                                                      ),
                                                      child: Text(
                                                        "(-${currentDay.trophiesLostTotal})",
                                                        style: Theme.of(
                                                          context,
                                                        ).textTheme.labelSmall,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            description:
                                                AppLocalizations.of(
                                                  context,
                                                )!.todoDefensesLeftDescription(
                                                  (8 -
                                                      currentDay.totalDefenses),
                                                  AppLocalizations.of(
                                                    context,
                                                  )!.legendsTitle,
                                                ),
                                          ),
                                          _buildTrophiesTotalChip(
                                            context,
                                            currentDay.trophiesTotal,
                                          ),
                                        ],
                                      ),
                                    ],
                                  )
                                : isLegend
                                ? Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: -6,
                                        runAlignment: WrapAlignment.center,
                                        children: [
                                          if (localRankChip != null)
                                            localRankChip,
                                          if (globalRankChip != null)
                                            globalRankChip,
                                          ImageChip(
                                            context: context,
                                            imageUrl:
                                                ImageAssets.legendStartFlag,
                                            label: NumberFormat(
                                              _numberFormat,
                                              Localizations.localeOf(
                                                context,
                                              ).toString(),
                                            ).format(player.trophies),
                                            description:
                                                AppLocalizations.of(
                                                  context,
                                                )!.legendsStartDescription(
                                                  "${player.trophies}",
                                                ),
                                          ),
                                          ImageChip(
                                            context: context,
                                            imageUrl: ImageAssets.sword,
                                            labelWidget: RichText(
                                              text: TextSpan(
                                                style: Theme.of(
                                                  context,
                                                ).textTheme.labelLarge,
                                                children: [
                                                  const TextSpan(text: "0"),
                                                  WidgetSpan(
                                                    child: Transform.translate(
                                                      offset: const Offset(
                                                        2,
                                                        -6,
                                                      ),
                                                      child: Text(
                                                        "(+0)",
                                                        style: Theme.of(
                                                          context,
                                                        ).textTheme.labelSmall,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            description: "",
                                          ),
                                          ImageChip(
                                            context: context,
                                            imageUrl:
                                                ImageAssets.shieldWithArrow,
                                            labelWidget: RichText(
                                              text: TextSpan(
                                                style: Theme.of(
                                                  context,
                                                ).textTheme.labelLarge,
                                                children: [
                                                  const TextSpan(text: "0"),
                                                  WidgetSpan(
                                                    child: Transform.translate(
                                                      offset: const Offset(
                                                        2,
                                                        -6,
                                                      ),
                                                      child: Text(
                                                        "(-0)",
                                                        style: Theme.of(
                                                          context,
                                                        ).textTheme.labelSmall,
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
                                            description: AppLocalizations.of(
                                              context,
                                            )!.legendsGainDescription(0),
                                          ),
                                        ],
                                      ),
                                    ],
                                  )
                                : Text(
                                    AppLocalizations.of(
                                      context,
                                    )!.legendsNoDataToday,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.labelLarge,
                                  ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              )
            : const SizedBox.shrink(),
      ],
    );
  }
}
