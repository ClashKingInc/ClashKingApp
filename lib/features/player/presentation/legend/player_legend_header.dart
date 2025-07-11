import 'package:clashkingapp/common/widgets/mobile_web_image.dart';
import 'package:clashkingapp/core/constants/image_assets.dart';
import 'package:clashkingapp/features/player/models/player.dart';
import 'package:flutter/material.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'dart:ui';
import 'package:clashkingapp/common/widgets/buttons/info_button.dart';

class LegendHeaderCard extends StatefulWidget {
  final Player player;

  const LegendHeaderCard({super.key, required this.player});

  @override
  State<LegendHeaderCard> createState() => _LegendHeaderCardState();
}

class _LegendHeaderCardState extends State<LegendHeaderCard> {
  @override
  Widget build(BuildContext context) {
    final currentSeason = widget.player.legendsBySeason?.currentSeason;
    int currentTrophies = 0;
    currentSeason != null
        ? currentTrophies = currentSeason.endTrophies
        : widget.player.trophies;

    final diffTrophies = currentTrophies - 5000;

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
                Colors.black.withValues(alpha: 0.7),
                BlendMode.darken,
              ),
              child: MobileWebImage(
                imageUrl: ImageAssets.legendPageBackground,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
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
                      widget.player.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                          ),
                    ),
                    Text(widget.player.tag,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: Colors.grey,
                            )),
                    SizedBox(height: 10),
                    if (currentTrophies > 0)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          MobileWebImage(
                            imageUrl: ImageAssets.legendBlazon,
                            width: 60,
                          ),
                          Text(
                              NumberFormat(
                                      '#,###',
                                      Localizations.localeOf(context)
                                          .toString())
                                  .format(currentTrophies),
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
                                "(${diffTrophies >= 0 ? '+' : ''}$diffTrophies)",
                                style: Theme.of(context)
                                    .textTheme
                                    .labelMedium
                                    ?.copyWith(
                                        color: diffTrophies >= 0
                                            ? Colors.green
                                            : Colors.red),
                              ),
                              SizedBox(height: 32),
                            ],
                          ),
                        ],
                      )
                    else
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          MobileWebImage(
                            imageUrl: ImageAssets.legendBlazonBorders,
                            width: 60,
                          ),
                          Text(
                            AppLocalizations.of(context)!.legendsNotInLeague,
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
                                  if (widget.player.rankings?.countryCode != "")
                                    Chip(
                                      avatar: CircleAvatar(
                                          backgroundColor: Colors.transparent,
                                          child: MobileWebImage(
                                              imageUrl: ImageAssets.flag(widget
                                                      .player
                                                      .rankings
                                                      ?.countryCode ??
                                                  ''))),
                                      label: Text(
                                        widget.player.rankings?.countryName ??
                                            'No Country',
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
                                  if (widget.player.rankings?.countryCode != "")
                                    Chip(
                                      avatar: CircleAvatar(
                                          backgroundColor: Colors.transparent,
                                          child: MobileWebImage(
                                              imageUrl: ImageAssets.flag(widget
                                                      .player
                                                      .rankings
                                                      ?.countryCode ??
                                                  ''))),
                                      label: widget
                                                  .player.rankings?.localRank !=
                                              0
                                          ? Text(
                                              widget.player.rankings?.localRank
                                                      ?.toString() ??
                                                  AppLocalizations.of(context)
                                                      ?.legendsNoRank ??
                                                  'No rank',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .labelMedium
                                                  ?.copyWith(
                                                      color: Colors.white),
                                            )
                                          : Text(
                                              AppLocalizations.of(context)
                                                      ?.legendsNoRank ??
                                                  'No rank',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .labelMedium
                                                  ?.copyWith(
                                                      color: Colors.white),
                                            ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        side: BorderSide(
                                            color: Colors.white, width: 1),
                                      ),
                                    ),
                                  Chip(
                                    avatar: CircleAvatar(
                                      backgroundColor: Colors.transparent,
                                      child: MobileWebImage(
                                          imageUrl: ImageAssets.planet),
                                    ),
                                    label: Text(
                                        widget.player.rankings?.globalRank != 0
                                            ? NumberFormat(
                                                    '#,###',
                                                    Localizations.localeOf(
                                                            context)
                                                        .toString())
                                                .format(widget.player.rankings
                                                    ?.globalRank)
                                            : AppLocalizations.of(context)
                                                    ?.legendsNoRank ??
                                                'No rank',
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
          top: 40,
          left: 10,
          child: IconButton(
            icon: Icon(Icons.arrow_back,
                color: Theme.of(context).colorScheme.onPrimary, size: 32),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        InfoButton(
          textSpan: TextSpan(
            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
            children: [
              TextSpan(
                  text:
                      "${AppLocalizations.of(context)!.legendsInaccurateIntro}\n"),
              TextSpan(
                  text:
                      "${AppLocalizations.of(context)!.legendsInaccurateApiDelayTitle}\n",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              TextSpan(
                  text:
                      "${AppLocalizations.of(context)!.legendsInaccurateApiDelayBody}\n"),
              TextSpan(
                  text: AppLocalizations.of(context)!
                      .legendsInaccurateConcurrentTitle,
                  style: TextStyle(fontWeight: FontWeight.bold)),
              TextSpan(
                  text: AppLocalizations.of(context)!
                      .legendsInaccurateMultipleAttacksTitle,
                  style: TextStyle(fontWeight: FontWeight.bold)),
              TextSpan(
                  text: AppLocalizations.of(context)!
                      .legendsInaccurateMultipleAttacksBody),
              TextSpan(
                  text: AppLocalizations.of(context)!
                      .legendsInaccurateSimultaneousTitle,
                  style: TextStyle(fontWeight: FontWeight.bold)),
              TextSpan(
                  text:
                      "${AppLocalizations.of(context)!.legendsInaccurateSimultaneousBody}\n"),
              TextSpan(
                  text:
                      "${AppLocalizations.of(context)!.legendsInaccurateNetGainTitle}\n",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              TextSpan(
                  text:
                      "${AppLocalizations.of(context)!.legendsInaccurateNetGainBody}\n\n"),
              TextSpan(
                  text: AppLocalizations.of(context)!
                      .legendsInaccurateConclusion),
            ],
          ),
          title: AppLocalizations.of(context)!.legendsInaccurateTitle,
        ),
      ],
    );
  }
}
