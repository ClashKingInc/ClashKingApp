// Fichier : war_stats_page.dart
import 'package:clashkingapp/common/widgets/mobile_web_image.dart';
import 'package:clashkingapp/core/constants/image_assets.dart';
import 'package:clashkingapp/core/functions/war_functions.dart';
import 'package:clashkingapp/features/player/models/player_war_stats.dart';
import 'package:clashkingapp/features/player/data/player_service.dart';
import 'package:clashkingapp/features/player/presentation/player/player_page.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:clashkingapp/features/clan/models/clan.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

class ClanWarStatsPlayers extends StatelessWidget {
  final Clan clan;
  final bool showUppedTownHall;
  final String sortBy;
  final List<int> attackerThFilter;
  final List<int> defenderThFilter;
  final List<String> selectedTypes;
  final List<PlayerWarStats> filteredPlayers;
  final List<String> allPlayers;
  final Function() resetFilters;
  final bool equalThSelected;

  const ClanWarStatsPlayers({
    super.key,
    required this.clan,
    required this.showUppedTownHall,
    required this.sortBy,
    required this.selectedTypes,
    required this.filteredPlayers,
    required this.resetFilters,
    required this.attackerThFilter,
    required this.defenderThFilter,
    required this.equalThSelected,
    required this.allPlayers,
  });

  @override
  Widget build(BuildContext context) {
    final visiblePlayers = filteredPlayers
        .where((member) {
          final memberWarStats = member.getStatsForTypes(
            selectedTypes,
            attackerThFilter: attackerThFilter,
            defenderThFilter: defenderThFilter,
            equalThSelected: equalThSelected,
          );
          final starsCount = showUppedTownHall
              ? memberWarStats.starsCount
              : memberWarStats.getStarsCountAgainstTh(member.townhallLevel);
          final totalAttacks = starsCount.values.fold<int>(
            0,
            (previousValue, element) => previousValue + element,
          );
          return totalAttacks > 0;
        })
        .toList(growable: false);

    return Column(
      children: [
        if (visiblePlayers.isNotEmpty)
          ...visiblePlayers.asMap().entries.map((entry) {
            final index = entry.key + 1;
            final member = entry.value;
            final memberWarStats = member.getStatsForTypes(
              selectedTypes,
              attackerThFilter: attackerThFilter,
              defenderThFilter: defenderThFilter,
              equalThSelected: equalThSelected,
            );

            final starsCount = showUppedTownHall
                ? memberWarStats.starsCount
                : (memberWarStats.getStarsCountAgainstTh(member.townhallLevel));

            final totalAttacks = starsCount.values.fold<int>(
              0,
              (previousValue, element) => previousValue + element,
            );

            if (totalAttacks == 0) {
              return SizedBox.shrink();
            }

            return GestureDetector(
              onTap: () async {
                final navigator = Navigator.of(context);
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) =>
                      const Center(child: CircularProgressIndicator()),
                );
                try {
                  final player = await context
                      .read<PlayerService>()
                      .getPlayerAndClanData(member.tag);
                  if (!context.mounted) return;
                  navigator.pop();
                  navigator.push(
                    MaterialPageRoute(
                      builder: (_) => PlayerScreen(selectedPlayer: player),
                    ),
                  );
                } catch (e) {
                  if (context.mounted) {
                    navigator.pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to load player data')),
                    );
                  }
                }
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color:
                      Theme.of(context).cardTheme.color ??
                      Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: Theme.of(
                      context,
                    ).colorScheme.outlineVariant.withValues(alpha: 0.28),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        SizedBox(
                          width: 20,
                          child: Text(
                            index.toString(),
                            style: Theme.of(context).textTheme.labelMedium
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                        ),
                        const SizedBox(width: 7),
                        MobileWebImage(
                          imageUrl: ImageAssets.townHall(member.townhallLevel),
                          height: 38,
                          width: 38,
                        ),
                        const SizedBox(width: 9),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                member.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(fontWeight: FontWeight.w800),
                              ),
                              const SizedBox(height: 1),
                              Text(
                                member.tag,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.labelMedium
                                    ?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            _WarStatsMiniMetric(
                              imageUrl: ImageAssets.warClan,
                              value: totalAttacks.toString(),
                            ),
                            const SizedBox(height: 5),
                            _WarStatsMiniMetric(
                              imageUrl: ImageAssets.brokenSword,
                              value: memberWarStats.missedAttacks.toString(),
                              color: Colors.redAccent,
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _WarStatsMiniMetric(
                          icon: Icons.percent_rounded,
                          value:
                              '${memberWarStats.averageDestruction.toStringAsFixed(1)}%',
                          color: Colors.teal,
                          prominent: true,
                        ),
                        _WarStatsMiniMetric(
                          icon: Icons.star_rounded,
                          value: memberWarStats.averageStars.toStringAsFixed(2),
                          color: Colors.amber.shade700,
                          prominent: true,
                        ),
                        for (var stars = 0; stars <= 3; stars++)
                          _StarRateBadge(
                            stars: stars,
                            count: starsCount[stars.toString()] ?? 0,
                            totalAttacks: totalAttacks,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          })
        else
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
            child: Column(
              children: [
                Icon(
                  LucideIcons.searchX,
                  size: 32,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: 8),
                Text(
                  AppLocalizations.of(context)!.generalNoFilteredResults,
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  AppLocalizations.of(context)!.generalAdjustFilters,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: resetFilters,
                  child: Text(
                    AppLocalizations.of(context)!.generalClearFilters,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _WarStatsMiniMetric extends StatelessWidget {
  final String value;
  final String? imageUrl;
  final IconData? icon;
  final Color? color;
  final bool prominent;

  const _WarStatsMiniMetric({
    required this.value,
    this.imageUrl,
    this.icon,
    this.color,
    this.prominent = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final accent = color ?? colorScheme.primary;

    return Container(
      height: prominent ? 30 : 26,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: prominent ? 0.12 : 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accent.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (imageUrl != null)
            MobileWebImage(imageUrl: imageUrl!, height: 16, width: 16)
          else
            Icon(icon, size: 15, color: accent),
          const SizedBox(width: 5),
          Text(
            value,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _StarRateBadge extends StatelessWidget {
  final int stars;
  final int count;
  final int totalAttacks;

  const _StarRateBadge({
    required this.stars,
    required this.count,
    required this.totalAttacks,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final percent = totalAttacks == 0 ? 0 : count / totalAttacks * 100;

    return Container(
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.34),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.22),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(children: generateStars(stars, 12)),
          const SizedBox(width: 5),
          Text(
            '$count/$totalAttacks',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '${percent.toStringAsFixed(0)}%',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}
