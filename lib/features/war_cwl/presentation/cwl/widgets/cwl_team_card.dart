import 'package:clashkingapp/common/widgets/icons/build_stars.dart';
import 'package:clashkingapp/common/widgets/mobile_web_image.dart';
import 'package:clashkingapp/core/constants/image_assets.dart';
import 'package:clashkingapp/features/clan/data/clan_service.dart';
import 'package:clashkingapp/features/clan/models/clan.dart';
import 'package:clashkingapp/features/clan/presentation/clan_info/clan_page.dart';
import 'package:clashkingapp/features/war_cwl/models/cwl_clan.dart';
import 'package:clashkingapp/features/war_cwl/models/war_cwl.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';

class CwlTeamCard extends StatelessWidget {
  final CwlClan clan;
  final WarCwl warCwl;
  final bool showFullStats;
  final VoidCallback onToggleFullStats;

  const CwlTeamCard({
    super.key,
    required this.clan,
    required this.warCwl,
    required this.showFullStats,
    required this.onToggleFullStats,
  });

  @override
  Widget build(BuildContext context) {
    final sortedTownHalls = clan.townHallLevels.entries.toList();
    sortedTownHalls.sort(
      (a, b) => int.parse(b.key).compareTo(int.parse(a.key)),
    );

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: () async {
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) =>
                      const Center(child: CircularProgressIndicator()),
                );
                final Clan clanInfo = await ClanService().loadClanData(
                  clan.tag,
                );
                if (context.mounted) {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ClanInfoScreen(clanInfo: clanInfo),
                    ),
                  );
                }
              },
              child: Row(
                children: [
                  SizedBox(
                    width: 24,
                    child: Text(
                      '#${clan.rank}',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  CachedNetworkImage(
                    imageUrl: clan.badgeUrls.medium,
                    width: 40,
                    height: 40,
                    errorWidget: (context, url, error) => Icon(Icons.error),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          clan.name,
                          style: Theme.of(context).textTheme.titleMedium,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          clan.tag,
                          style: Theme.of(context).textTheme.bodySmall,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text("${clan.stars}  "),
                          SizedBox(
                            child: MobileWebImage(
                              imageUrl: ImageAssets.attackStar,
                              width: 15,
                              height: 15,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "${NumberFormat('#,###', Localizations.localeOf(context).toString()).format(clan.destructionPercentageInflicted)}  ",
                          ),
                          SizedBox(
                            child: MobileWebImage(
                              imageUrl: ImageAssets.hitrate,
                              width: 15,
                              height: 15,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 8),
            Wrap(
              alignment: WrapAlignment.center,
              children: sortedTownHalls.map((entry) {
                return Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      MobileWebImage(
                        imageUrl: ImageAssets.townHall(int.parse(entry.key)),
                        width: 20,
                        height: 20,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'x${entry.value}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 2),
            Align(
              alignment: Alignment.centerRight,
              child: _FullStatsToggle(
                expanded: showFullStats,
                onTap: onToggleFullStats,
              ),
            ),
            if (showFullStats)
              Padding(
                padding: const EdgeInsets.only(top: 10.0),
                child: Column(
                  children: [
                    _CwlStatsSection(
                      title: AppLocalizations.of(context)!.warAttacksTitle,
                      tiles: [
                        _MetricTile(
                          label: AppLocalizations.of(context)!.warAttacksTitle,
                          value: '${clan.attackCount}',
                          icon: MobileWebImage(
                            imageUrl: ImageAssets.sword,
                            width: 16,
                            height: 16,
                          ),
                        ),
                        _MetricTile(
                          label: AppLocalizations.of(context)!.warStatusMissed,
                          value: '${clan.missedAttacks}',
                          icon: MobileWebImage(
                            imageUrl: ImageAssets.brokenSword,
                            width: 16,
                            height: 16,
                          ),
                        ),
                        _MetricTile(
                          label: AppLocalizations.of(
                            context,
                          )!.warAbbreviationAvg,
                          value: clan.averageStars.toStringAsFixed(1),
                          icon: MobileWebImage(
                            imageUrl: ImageAssets.attackStar,
                            width: 16,
                            height: 16,
                          ),
                        ),
                        _MetricTile(
                          label: AppLocalizations.of(
                            context,
                          )!.warDestructionTitle,
                          value:
                              '${clan.destructionPercentageInflicted.toStringAsFixed(1)}%',
                          icon: MobileWebImage(
                            imageUrl: ImageAssets.hitrate,
                            width: 16,
                            height: 16,
                          ),
                        ),
                        _MetricTile(
                          label: AppLocalizations.of(
                            context,
                          )!.warAbbreviationAvgPercentage,
                          value: clan.averageDestruction.toStringAsFixed(1),
                          icon: MobileWebImage(
                            imageUrl: ImageAssets.hitrate,
                            width: 16,
                            height: 16,
                          ),
                        ),
                      ],
                      breakdown: _StarBreakdownStrip(
                        three: clan.threeStars,
                        two: clan.twoStars,
                        one: clan.oneStar,
                        zero: clan.zeroStar,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _CwlStatsSection(
                      title: AppLocalizations.of(context)!.warDefensesTitle,
                      tiles: [
                        _MetricTile(
                          label: AppLocalizations.of(context)!.warDefensesTitle,
                          value: '${clan.defenseCount}',
                          icon: MobileWebImage(
                            imageUrl: ImageAssets.shieldWithArrow,
                            width: 16,
                            height: 16,
                          ),
                        ),
                        _MetricTile(
                          label: AppLocalizations.of(context)!.warStatusMissed,
                          value: '${clan.missedDefenses}',
                          icon: MobileWebImage(
                            imageUrl: ImageAssets.shield,
                            width: 16,
                            height: 16,
                          ),
                        ),
                        _MetricTile(
                          label: AppLocalizations.of(
                            context,
                          )!.warAbbreviationAvg,
                          value: clan.defAverageStars.toStringAsFixed(1),
                          icon: MobileWebImage(
                            imageUrl: ImageAssets.attackStar,
                            width: 16,
                            height: 16,
                          ),
                        ),
                        _MetricTile(
                          label: AppLocalizations.of(
                            context,
                          )!.warDestructionTitle,
                          value:
                              '${clan.destructionPercentage.toStringAsFixed(1)}%',
                          icon: MobileWebImage(
                            imageUrl: ImageAssets.hitrate,
                            width: 16,
                            height: 16,
                          ),
                        ),
                        _MetricTile(
                          label: AppLocalizations.of(
                            context,
                          )!.warAbbreviationAvgPercentage,
                          value: clan.defAverageDestruction.toStringAsFixed(1),
                          icon: MobileWebImage(
                            imageUrl: ImageAssets.hitrate,
                            width: 16,
                            height: 16,
                          ),
                        ),
                      ],
                      breakdown: _StarBreakdownStrip(
                        three: clan.threeStarsDef,
                        two: clan.twoStarsDef,
                        one: clan.oneStarDef,
                        zero: clan.zeroStarDef,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _FullStatsToggle extends StatelessWidget {
  final bool expanded;
  final VoidCallback onTap;

  const _FullStatsToggle({required this.expanded, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Semantics(
      button: true,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 40),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    AppLocalizations.of(context)!.generalFullStats,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.85),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(width: 4),
                  AnimatedRotation(
                    turns: expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    child: Icon(
                      Icons.expand_more_rounded,
                      size: 18,
                      color: colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Attack/defense stat block — plain centered title over the metric tiles
/// and star breakdown, matching the members full-stats title style exactly.
class _CwlStatsSection extends StatelessWidget {
  final String title;
  final List<Widget> tiles;
  final Widget breakdown;

  const _CwlStatsSection({
    required this.title,
    required this.tiles,
    required this.breakdown,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(title, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 12),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (int i = 0; i < tiles.length; i++) ...[
                if (i > 0) const SizedBox(width: 6),
                Expanded(child: tiles[i]),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        breakdown,
      ],
    );
  }
}

/// Single-clan 3/2/1/0-star tally shown as one compact row instead of four
/// separate square tiles competing for space in the stat wrap.
class _StarBreakdownStrip extends StatelessWidget {
  final int three;
  final int two;
  final int one;
  final int zero;

  const _StarBreakdownStrip({
    required this.three,
    required this.two,
    required this.one,
    required this.zero,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _StarCount(stars: 3, count: three),
        _StarCount(stars: 2, count: two),
        _StarCount(stars: 1, count: one),
        _StarCount(stars: 0, count: zero),
      ],
    );
  }
}

/// Flexible-width, card-less sibling of the shared `StatTile` — no
/// background/border, just icon/label/value, so it stretches to fill an
/// `Expanded` slot in a fixed-column `Row` without reading as a boxed chip.
class _MetricTile extends StatelessWidget {
  final String label;
  final String value;
  final Widget icon;

  const _MetricTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Center(child: icon),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontSize: 9.5,
          ),
        ),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            maxLines: 1,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }
}

class _StarCount extends StatelessWidget {
  final int stars;
  final int count;

  const _StarCount({required this.stars, required this.count});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        buildStarsIcon(stars),
        const SizedBox(height: 4),
        Text(
          '$count',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w900),
        ),
      ],
    );
  }
}
