import 'package:cached_network_image/cached_network_image.dart';
import 'package:clashkingapp/common/widgets/header_widgets.dart';
import 'package:clashkingapp/features/clan/models/clan.dart';
import 'package:flutter/material.dart';
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

  const WarHistoryPlayersStatsHeader({
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final imageHeight = MediaQuery.of(context).padding.top + 220;

    return Stack(
      children: [
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: imageHeight,
          child: Stack(
            fit: StackFit.expand,
            children: [
              CachedNetworkImage(
                imageUrl: "https://assets.clashk.ing/landscape/war-stats.png",
                fit: BoxFit.cover,
                errorWidget: (context, url, error) =>
                    ColoredBox(color: colorScheme.surface),
              ),
              ColoredBox(color: Colors.black.withValues(alpha: 0.6)),
            ],
          ),
        ),
        Column(
          children: [
            SizedBox(height: MediaQuery.of(context).padding.top + 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  HeaderIconButton(
                    icon: Icons.arrow_back_rounded,
                    tooltip: MaterialLocalizations.of(
                      context,
                    ).backButtonTooltip,
                    onTap: onBack,
                  ),
                  const Spacer(),
                  HeaderIconButton(
                    icon: Icons.filter_list_rounded,
                    tooltip: 'Filter',
                    onTap: onFilter,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 56,
                    height: 56,
                    child: CachedNetworkImage(
                      imageUrl: clan.badgeUrls.medium,
                      errorWidget: (context, url, error) =>
                          const Icon(Icons.error),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          AppLocalizations.of(context)!.warStats,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: Colors.white.withValues(alpha: 0.75),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          clan.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          clan.tag,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withValues(alpha: 0.75),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: (theme.cardTheme.color ?? colorScheme.surface)
                      .withValues(alpha: 0.94),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.32),
                  ),
                ),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilterChip(
                      visualDensity: VisualDensity.compact,
                      label: Text(AppLocalizations.of(context)!.cwlTitle),
                      selected: isCWLChecked,
                      onSelected: (selected) => onCWLChanged(),
                    ),
                    FilterChip(
                      visualDensity: VisualDensity.compact,
                      label: Text(
                        AppLocalizations.of(context)!.warFiltersRandom,
                      ),
                      selected: isRandomChecked,
                      onSelected: (selected) => onRandomChanged(),
                    ),
                    FilterChip(
                      visualDensity: VisualDensity.compact,
                      label: Text(
                        AppLocalizations.of(context)!.warFiltersFriendly,
                      ),
                      selected: isFriendlyChecked,
                      onSelected: (selected) => onFriendlyChanged(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
