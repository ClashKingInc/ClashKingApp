import 'dart:ui';

import 'package:clashkingapp/common/widgets/mobile_web_image.dart';
import 'package:clashkingapp/core/constants/image_assets.dart';
import 'package:flutter/material.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';

class PlayerWarStatsHeader extends StatelessWidget {
  final String name;
  final String tag;
  final String picture;
  final bool isCWLChecked;
  final bool isRandomChecked;
  final bool isFriendlyChecked;
  final VoidCallback onCWLChanged;
  final VoidCallback onRandomChanged;
  final VoidCallback onFriendlyChanged;
  final VoidCallback onBack;
  final VoidCallback onFilter;
  final VoidCallback onExport;
  final bool hasActiveFilters;

  PlayerWarStatsHeader({
    super.key,
    required this.name,
    required this.tag,
    required this.picture,
    required this.isCWLChecked,
    required this.isRandomChecked,
    required this.isFriendlyChecked,
    required this.onCWLChanged,
    required this.onRandomChanged,
    required this.onFriendlyChanged,
    required this.onBack,
    required this.onFilter,
    required this.onExport,
    this.hasActiveFilters = false,
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
                  Colors.black.withValues(alpha: 0.7),
                  BlendMode.darken,
                ),
                child: MobileWebImage(
                  imageUrl: ImageAssets.playerWarStatsPageBackground,
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
                    MobileWebImage(
                      imageUrl: picture,
                      width: 50,
                    ),
                    SizedBox(height: 8),
                    Text(
                      name,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(color: Colors.white),
                    ),
                    Text(
                      tag,
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
                          label: Text(AppLocalizations.of(context)!.cwlTitle,
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
                          label: Text(
                              AppLocalizations.of(context)!.warFiltersRandom,
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
                          label: Text(
                              AppLocalizations.of(context)!.warFiltersFriendly,
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
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Export button
              IconButton(
                icon: Icon(Icons.download_outlined, color: Colors.white),
                onPressed: onExport,
                tooltip:
                    AppLocalizations.of(context)?.generalExport ?? 'Export',
              ),
            ],
          ),
        ),
      ],
    );
  }
}
