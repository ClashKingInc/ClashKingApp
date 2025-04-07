import 'package:clashkingapp/features/player/data/player_service.dart';
import 'package:clashkingapp/features/player/presentation/player/player_page.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:clashkingapp/features/war_cwl/models/cwl_member.dart';
import 'package:clashkingapp/common/widgets/mobile_web_image.dart';
import 'package:clashkingapp/core/constants/image_assets.dart';

class MembersCard extends StatelessWidget {
  final CwlMember member;
  final int index;
  final String sortBy;
  final bool showFullStats;
  final VoidCallback onToggleFullStats;

  const MembersCard({
    super.key,
    required this.member,
    required this.index,
    required this.sortBy,
    required this.showFullStats,
    required this.onToggleFullStats,
  });

  Widget formatStatWithAverage(
      BuildContext context, String value, String? average) {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(text: value, style: Theme.of(context).textTheme.bodyMedium),
          if (average != null)
            WidgetSpan(
              child: Transform.translate(
                offset: const Offset(2, -8),
                child: Text(
                  "($average)",
                  textScaleFactor: 0.8,
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget? getStatFromSortKey(BuildContext context) {
    final attack = member.attackStats;
    final defense = member.defenseStats;
    TextStyle style =
        Theme.of(context).textTheme.bodyLarge ?? const TextStyle();

    Widget withIcon(String value, String imageUrl, String tooltip) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value, style: style),
          const SizedBox(width: 4),
          Tooltip(
            message: tooltip,
            child: MobileWebImage(imageUrl: imageUrl, width: 16, height: 16),
          ),
        ],
      );
    }

    switch (sortBy) {
      case 'stars':
        return withIcon(
            "${attack?.stars ?? 0}", ImageAssets.attackStar, "Stars");
      case 'percentage':
        return withIcon("${(attack?.totalDestruction ?? 0).toStringAsFixed(0)}",
            ImageAssets.hitrate, "Destruction %");
      case 'averageStars':
        return withIcon("${attack?.averageStars?.toStringAsFixed(1) ?? '0.0'}",
            ImageAssets.attackStar, "Avg Stars");
      case 'averagePercentage':
        return withIcon(
            "${attack?.averageDestruction?.toStringAsFixed(1) ?? '0.0'}",
            ImageAssets.hitrate,
            "Avg %");
      case 'attackCount':
        return withIcon(
            "${attack?.attackCount ?? 0}", ImageAssets.sword, "Attacks");
      case 'missedAttacks':
        return withIcon("${attack?.missedAttacks ?? 0}",
            ImageAssets.brokenSword, "Missed Attacks");
      case 'defStars':
        return withIcon(
            "${defense?.stars ?? 0}", ImageAssets.attackStar, "Def Stars");
      case 'defDestruction':
        return withIcon(
            "${(defense?.totalDestruction ?? 0).toStringAsFixed(0)}",
            ImageAssets.hitrate,
            "Def %");
      case 'defAverageStars':
        return withIcon("${defense?.averageStars?.toStringAsFixed(1) ?? '0.0'}",
            ImageAssets.attackStar, "Avg Def Stars");
      case 'defAverageDestruction':
        return withIcon(
            "${defense?.averageDestruction?.toStringAsFixed(1) ?? '0.0'}",
            ImageAssets.hitrate,
            "Avg Def %");
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final attack = member.attackStats;
    final defense = member.defenseStats;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text("${index + 1}.",
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(width: 8),
                MobileWebImage(
                  imageUrl: ImageAssets.townHall(member.townhallLevel),
                  width: 28,
                  height: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      final navigator = Navigator.of(context);
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (_) =>
                            const Center(child: CircularProgressIndicator()),
                      );
                      final player =
                          await PlayerService().getPlayerData(member.tag);
                      navigator.pop();
                      navigator.push(
                        MaterialPageRoute(
                          builder: (_) => PlayerScreen(selectedPlayer: player),
                        ),
                      );
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(member.name,
                            style: Theme.of(context).textTheme.titleMedium),
                        Text(member.tag,
                            style: Theme.of(context).textTheme.labelSmall),
                      ],
                    ),
                  ),
                ),
                getStatFromSortKey(context) ?? const SizedBox.shrink(),
              ],
            ),
            const SizedBox(height: 12),
            if (attack != null || defense != null) ...[
              GestureDetector(
                onTap: onToggleFullStats,
                child: Row(
                  children: [
                    Icon(showFullStats ? Icons.expand_less : Icons.expand_more,
                        size: 16),
                    const SizedBox(width: 4),
                    Text(AppLocalizations.of(context)!.fullStats,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface)),
                  ],
                ),
              ),
              if (showFullStats)
                Container(
                  padding: const EdgeInsets.all(8),
                  margin: const EdgeInsets.only(top: 8),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .surfaceVariant
                        .withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (attack != null) ...[
                              Text(AppLocalizations.of(context)!.attacks,
                                  style:
                                      Theme.of(context).textTheme.bodyMedium),
                              const SizedBox(height: 8),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Stars
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _buildStarBreakdown(
                                          context, attack.threeStars, 3),
                                      const SizedBox(height: 4),
                                      _buildStarBreakdown(
                                          context, attack.twoStars, 2),
                                      const SizedBox(height: 4),
                                      _buildStarBreakdown(
                                          context, attack.oneStar, 1),
                                      const SizedBox(height: 4),
                                      _buildStarBreakdown(
                                          context, attack.zeroStar, 0),
                                    ],
                                  ),
                                  const SizedBox(width: 16),
                                  // Other stats
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          MobileWebImage(
                                              imageUrl: ImageAssets.sword,
                                              width: 16,
                                              height: 16),
                                          const SizedBox(width: 4),
                                          Text("${attack.attackCount}",
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodyMedium),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          MobileWebImage(
                                              imageUrl: ImageAssets.brokenSword,
                                              width: 16,
                                              height: 16),
                                          const SizedBox(width: 4),
                                          Text("${attack.missedAttacks}",
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodyMedium),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          MobileWebImage(
                                              imageUrl: ImageAssets.attackStar,
                                              width: 16,
                                              height: 16),
                                          const SizedBox(width: 4),
                                          formatStatWithAverage(
                                              context,
                                              "${attack.stars}",
                                              attack.averageStars
                                                  ?.toStringAsFixed(1)),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          MobileWebImage(
                                              imageUrl: ImageAssets.hitrate,
                                              width: 16,
                                              height: 16),
                                          const SizedBox(width: 4),
                                          formatStatWithAverage(
                                              context,
                                              attack.totalDestruction
                                                  .toStringAsFixed(0),
                                              attack.averageDestruction
                                                  ?.toStringAsFixed(0)),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ]
                          ],
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 100,
                        color: Theme.of(context).dividerColor.withOpacity(0.2),
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            if (defense != null) ...[
                              Text(AppLocalizations.of(context)!.defenses,
                                  style:
                                      Theme.of(context).textTheme.bodyMedium),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Text("${defense.defenseCount}",
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium),
                                  const SizedBox(width: 4),
                                  MobileWebImage(
                                      imageUrl: ImageAssets.shieldWithArrow,
                                      width: 16,
                                      height: 16),
                                ],
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  formatStatWithAverage(
                                      context,
                                      "${defense.stars}",
                                      defense.averageStars?.toStringAsFixed(1)),
                                  const SizedBox(width: 8),
                                  MobileWebImage(
                                      imageUrl: ImageAssets.attackStar,
                                      width: 16,
                                      height: 16),
                                  const SizedBox(width: 8),
                                  Text(" | ",
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium),
                                  const SizedBox(width: 8),
                                  formatStatWithAverage(
                                      context,
                                      defense.totalDestruction
                                          .toStringAsFixed(0),
                                      defense.averageDestruction
                                          ?.toStringAsFixed(0)),
                                  const SizedBox(width: 4),
                                  MobileWebImage(
                                      imageUrl: ImageAssets.hitrate,
                                      width: 16,
                                      height: 16),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Wrap(
                                spacing: 12,
                                runSpacing: 4,
                                children: [
                                  _buildStarBreakdown(
                                      context, defense.threeStars, 3,
                                      alignRight: true),
                                  _buildStarBreakdown(
                                      context, defense.twoStars, 2,
                                      alignRight: true),
                                  _buildStarBreakdown(
                                      context, defense.oneStar, 1,
                                      alignRight: true),
                                  _buildStarBreakdown(
                                      context, defense.zeroStar, 0,
                                      alignRight: true),
                                ],
                              )
                            ]
                          ],
                        ),
                      )
                    ],
                  ),
                )
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStarBreakdown(BuildContext context, int count, int stars,
      {bool alignRight = false}) {
    List<Widget> starIcons = [];

    // Add filled stars (attackStar)
    for (int i = 0; i < stars; i++) {
      starIcons.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: MobileWebImage(
            imageUrl: ImageAssets.attackStar,
            width: 14,
            height: 14,
          ),
        ),
      );
    }

    // Add empty stars (star_border)
    for (int i = stars; i < 3; i++) {
      starIcons.add(
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 1),
          child: Icon(Icons.star_border, size: 16),
        ),
      );
    }

    return Row(
      mainAxisAlignment:
          alignRight ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [
        Text("$count"),
        const SizedBox(width: 4),
        ...starIcons,
      ],
    );
  }
}
