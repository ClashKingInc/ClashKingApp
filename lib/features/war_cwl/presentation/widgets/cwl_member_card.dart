import 'package:clashkingapp/common/widgets/shapes/stat_tile.dart';
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
        return withIcon((attack?.totalDestruction ?? 0).toStringAsFixed(0),
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
        return withIcon((defense?.totalDestruction ?? 0).toStringAsFixed(0),
            ImageAssets.hitrate, "Def %");
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

  Widget statWithTextIcon(BuildContext context, String label, String value,
      IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text("$label: $value", style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }

  Widget statWithIcon(
      BuildContext context, String label, String value, String imageUrl) {
    return Row(
      children: [
        MobileWebImage(imageUrl: imageUrl, width: 16, height: 16),
        const SizedBox(width: 4),
        Text("$label: $value", style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
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
          children: [
            Row(
              children: [
                Text("${index + 1}.",
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(width: 8),
                MobileWebImage(
                  imageUrl: ImageAssets.townHall(member.townhallLevel),
                  width: 36,
                  height: 36,
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
                            style: Theme.of(context).textTheme.titleSmall),
                        Text(member.tag,
                            style: Theme.of(context).textTheme.labelMedium),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      getStatFromSortKey(context) ?? const SizedBox.shrink(),
                      if (attack != null || defense != null) ...[
                        GestureDetector(
                          onTap: onToggleFullStats,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Icon(
                                  showFullStats
                                      ? Icons.expand_less
                                      : Icons.expand_more,
                                  size: 16,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withValues(alpha: 0.7)),
                              const SizedBox(width: 4),
                              Text(AppLocalizations.of(context)!.fullStats,
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelLarge
                                      ?.copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                              .withValues(alpha: 0.7))),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            if (showFullStats) ...[
              const SizedBox(height: 8),
              _buildStatsSection(context, attack, defense)
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSection(BuildContext context, attack, defense) {
    final attack = member.attackStats;
    final defense = member.defenseStats;

    return Column(
      children: [
        if (attack != null)
          Column(
            children: [
              Text(AppLocalizations.of(context)!.attacks,
                  style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 12),
              Wrap(
                spacing: 16,
                runAlignment: WrapAlignment.center,
                runSpacing: 16,
                children: [
                  StatTile(
                      label: 'Attacks',
                      value: '${attack.attackCount}',
                      icon: MobileWebImage(
                          imageUrl: ImageAssets.sword, width: 16, height: 16)),
                  StatTile(
                      label: 'Missed',
                      value: '${attack.missedAttacks}',
                      icon: MobileWebImage(
                          imageUrl: ImageAssets.brokenSword,
                          width: 16,
                          height: 16)),
                  StatTile(
                      label: 'Total',
                      value: '${attack.stars}',
                      icon: MobileWebImage(
                          imageUrl: ImageAssets.attackStar,
                          width: 16,
                          height: 16)),
                  StatTile(
                      label: 'Avg',
                      value:
                          '${attack.averageStars?.toStringAsFixed(1) ?? "0.0"}',
                      icon: MobileWebImage(
                          imageUrl: ImageAssets.attackStar,
                          width: 16,
                          height: 16)),
                  StatTile(
                      label: '0 Star',
                      value: '${member.zeroStar}',
                      icon: buildStarsIcon(0)),
                  StatTile(
                      label: '1 Star',
                      value: '${member.oneStar}',
                      icon: buildStarsIcon(1)),
                  StatTile(
                      label: '2 Stars',
                      value: '${member.twoStars}',
                      icon: buildStarsIcon(2)),
                  StatTile(
                      label: '3 Stars',
                      value: '${member.threeStars}',
                      icon: buildStarsIcon(3)),
                  StatTile(
                      label: 'Destruction',
                      value: '${attack.totalDestruction.toStringAsFixed(1)}%',
                      icon: MobileWebImage(
                          imageUrl: ImageAssets.hitrate,
                          width: 16,
                          height: 16)),
                  StatTile(
                      label: 'Avg %',
                      value:
                          '${attack.averageDestruction?.toStringAsFixed(1) ?? "0.0"}',
                      icon: MobileWebImage(
                          imageUrl: ImageAssets.hitrate,
                          width: 16,
                          height: 16)),
                  StatTile(
                      label: 'Order',
                      value: member.avgAttackOrder?.toStringAsFixed(1) ?? "-",
                      icon: MobileWebImage(
                          imageUrl: ImageAssets.clock, width: 16, height: 16)),
                  StatTile(
                      label: 'Pos',
                      value: member.avgMapPosition?.toStringAsFixed(1) ?? "-",
                      icon: const Icon(Icons.location_pin,
                          size: 16, color: Colors.redAccent)),
                  StatTile(
                      label: 'Opp TH',
                      value:
                          member.avgOpponentTownHallLevel?.toStringAsFixed(1) ??
                              "-",
                      icon: MobileWebImage(
                          imageUrl: ImageAssets.townHall(
                              member.avgOpponentTownHallLevel?.round() ?? 1),
                          width: 16,
                          height: 16)),
                  StatTile(
                      label: 'Lower TH',
                      value: member.attackLowerTHLevel?.toStringAsFixed(0) ?? "-",
                      icon: Icon(Icons.keyboard_double_arrow_down,
                          size: 16,
                          color: Theme.of(context).colorScheme.primary)),
                  StatTile(
                      label: 'Upper TH',
                      value: member.attackUpperTHLevel?.toStringAsFixed(0) ?? "-",
                      icon: Icon(Icons.keyboard_double_arrow_up,
                          size: 16,
                          color: Theme.of(context).colorScheme.secondary)),
                ],
              ),
            ],
          ),
        if (defense != null)
          Column(
            children: [
              const SizedBox(height: 18),
              Text(AppLocalizations.of(context)!.defenses,
                  style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 12),
              Wrap(
                spacing: 16,
                runAlignment: WrapAlignment.center,
                runSpacing: 16,
                children: [
                  StatTile(
                      label: 'Defenses',
                      value: '${defense.defenseCount}',
                      icon: MobileWebImage(
                          imageUrl: ImageAssets.shieldWithArrow,
                          width: 16,
                          height: 16)),
                  StatTile(
                      label: 'Missed',
                      value: '${defense.missedDefenses}',
                      icon: MobileWebImage(
                          imageUrl: ImageAssets.shield, width: 16, height: 16)),
                  StatTile(
                      label: 'Total',
                      value: '${defense.stars}',
                      icon: MobileWebImage(
                          imageUrl: ImageAssets.attackStar,
                          width: 16,
                          height: 16)),
                  StatTile(
                      label: 'Avg',
                      value:
                          '${defense.averageStars?.toStringAsFixed(1) ?? "0.0"}',
                      icon: MobileWebImage(
                          imageUrl: ImageAssets.attackStar,
                          width: 16,
                          height: 16)),
                  StatTile(
                      label: '0 Star',
                      value: '${member.zeroStarDef}',
                      icon: buildStarsIcon(0)),
                  StatTile(
                      label: '1 Star',
                      value: '${member.oneStarDef}',
                      icon: buildStarsIcon(1)),
                  StatTile(
                      label: '2 Stars',
                      value: '${member.twoStarsDef}',
                      icon: buildStarsIcon(2)),
                  StatTile(
                      label: '3 Stars',
                      value: '${member.threeStarsDef}',
                      icon: buildStarsIcon(3)),
                  StatTile(
                      label: 'Destruction',
                      value: '${defense.totalDestruction.toStringAsFixed(1)}%',
                      icon: MobileWebImage(
                          imageUrl: ImageAssets.hitrate,
                          width: 16,
                          height: 16)),
                  StatTile(
                      label: 'Avg %',
                      value:
                          '${defense.averageDestruction?.toStringAsFixed(1) ?? "0.0"}',
                      icon: MobileWebImage(
                          imageUrl: ImageAssets.hitrate,
                          width: 16,
                          height: 16)),
                  StatTile(
                      label: 'Order',
                      value: member.avgDefenseOrder?.toStringAsFixed(1) ?? "-",
                      icon: MobileWebImage(
                          imageUrl: ImageAssets.clock, width: 16, height: 16)),
                  StatTile(
                      label: 'Pos',
                      value:
                          member.avgAttackerPosition?.toStringAsFixed(1) ?? "-",
                      icon: const Icon(Icons.location_pin,
                          size: 16, color: Colors.redAccent)),
                  StatTile(
                      label: 'Opp TH',
                      value:
                          member.avgAttackerTownHallLevel?.toStringAsFixed(1) ??
                              "-",
                      icon: MobileWebImage(
                          imageUrl: ImageAssets.townHall(
                              member.avgAttackerTownHallLevel?.round() ?? 1),
                          width: 16,
                          height: 16)),
                  StatTile(
                      label: 'Lower TH',
                      value: member.defenseLowerTHLevel?.toStringAsFixed(0) ?? "-",
                      icon: Icon(Icons.keyboard_double_arrow_down,
                          size: 16,
                          color: Theme.of(context).colorScheme.primary)),
                  StatTile(
                      label: 'Upper TH',
                      value: member.defenseUpperTHLevel?.toStringAsFixed(0) ?? "-",
                      icon: Icon(Icons.keyboard_double_arrow_up,
                          size: 16,
                          color: Theme.of(context).colorScheme.secondary)),
                ],
              ),
            ],
          ),
      ],
    );
  }

  Widget buildStatCategory(String title, List<StatTile> stats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(title,
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: stats,
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget buildStarsIcon(int filledStars) {
    List<Widget> stars = [];
    for (int i = 0; i < 3; i++) {
      stars.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 1),
          child: i < filledStars
              ? MobileWebImage(
                  imageUrl: ImageAssets.attackStar, width: 12, height: 12)
              : const Icon(Icons.star_border, size: 14),
        ),
      );
    }
    return Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: stars,
        ));
  }
}
