import 'dart:ui';

import 'package:clashkingapp/classes/clan/clan_info.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';

class WarHistoryPlayersStatsHeader extends StatelessWidget {
  final Clan clan;
  final bool isCWLChecked;
  final bool isRandomChecked;
  final bool isFriendlyChecked;
  final VoidCallback onCWLChanged;
  final VoidCallback onRandomChanged;
  final VoidCallback onFriendlyChanged;
  final VoidCallback onBack;
  final VoidCallback onFilter;

  WarHistoryPlayersStatsHeader({
    super.key,
    required this.clan,
    required this.isCWLChecked,
    required this.isRandomChecked,
    required this.isFriendlyChecked,
    required this.onCWLChanged,
    required this.onRandomChanged,
    required this.onFriendlyChanged,
    required this.onBack,
    required this.onFilter,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        SizedBox(
          height: 280,
          width: double.infinity,
          child: ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 1, sigmaY: 1),
            child: ColorFiltered(
                colorFilter: ColorFilter.mode(
                  Colors.black.withOpacity(0.7),
                  BlendMode.darken,
                ),
                child: CachedNetworkImage(
                  imageUrl: "https://assets.clashk.ing/landscape/war-stats.png",
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
                      AppLocalizations.of(context)!.warStats,
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(color: Colors.white),
                    ),
                    SizedBox(height: 8),
                    CachedNetworkImage(
                      imageUrl: clan.badgeUrls.medium,
                      width: 50,
                    ),
                    SizedBox(height: 8),
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
                          ?.copyWith(color: Colors.grey),
                    ),
                    SizedBox(height: 8),
                    Wrap(
                      spacing: 0,
                      runSpacing: 0,
                      children: [
                        FilterChip(
                          visualDensity: VisualDensity.compact,
                          selectedColor: Theme.of(context).colorScheme.primary,
                          checkmarkColor: Colors.white,
                          label: Text(AppLocalizations.of(context)!.cwl,
                              style: Theme.of(context)
                                  .textTheme
                                  .labelMedium
                                  ?.copyWith(color: Colors.white)),
                          selected: isCWLChecked,
                          onSelected: (bool selected) => onCWLChanged(),
                        ),
                        SizedBox(width: 8),
                        FilterChip(
                          visualDensity: VisualDensity.compact,
                          selectedColor: Theme.of(context).colorScheme.primary,
                          checkmarkColor: Colors.white,
                          label: Text(AppLocalizations.of(context)!.random,
                              style: Theme.of(context)
                                  .textTheme
                                  .labelMedium
                                  ?.copyWith(color: Colors.white)),
                          selected: isRandomChecked,
                          onSelected: (bool selected) => onRandomChanged(),
                        ),
                        SizedBox(width: 8),
                        FilterChip(
                          visualDensity: VisualDensity.compact,
                          selectedColor: Theme.of(context).colorScheme.primary,
                          checkmarkColor: Colors.white,
                          label: Text(AppLocalizations.of(context)!.friendly,
                              style: Theme.of(context)
                                  .textTheme
                                  .labelMedium
                                  ?.copyWith(color: Colors.white)),
                          selected: isFriendlyChecked,
                          onSelected: (bool selected) => onFriendlyChanged(),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
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
            onPressed: onBack,
          ),
        ),
        Positioned(
          top: 40,
          right: 10,
          child: IconButton(
            icon: Icon(Icons.filter_list, color: Colors.white),
            onPressed: onFilter,
          ),
        ),
      ],
    );
  }
}
