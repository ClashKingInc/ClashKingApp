import 'package:clashkingapp/common/widgets/icons/build_stars.dart';
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
                  textScaler: TextScaler.linear(0.8),
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
    final theme = Theme.of(context);
    TextStyle style = theme.textTheme.bodyLarge ?? const TextStyle();

    Widget withImageIcon(String value, String imageUrl, String tooltip) {
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

    Widget withIcon(String value, Icon icon, String tooltip) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value, style: style),
          const SizedBox(width: 4),
          Tooltip(
            message: tooltip,
            child: icon,
          ),
        ],
      );
    }

    switch (sortBy) {
      case 'stars':
        return withImageIcon(
            "${attack?.stars ?? 0}", ImageAssets.attackStar, "Stars");

      case 'percentage':
        return withImageIcon(
          (attack?.totalDestruction ?? 0).toStringAsFixed(0),
          ImageAssets.hitrate,
          "Destruction %",
        );

      case 'averageStars':
        return withImageIcon(
          "${attack?.averageStars?.toStringAsFixed(1) ?? '0.0'}",
          ImageAssets.attackStar,
          "Avg Stars",
        );

      case 'averagePercentage':
        return withImageIcon(
          "${attack?.averageDestruction?.toStringAsFixed(1) ?? '0.0'}",
          ImageAssets.hitrate,
          "Avg %",
        );

      case 'attackCount':
        return withImageIcon(
          "${attack?.attackCount ?? 0}",
          ImageAssets.sword,
          "Attacks",
        );

      case 'missedAttacks':
        return withImageIcon(
          "${attack?.missedAttacks ?? 0}",
          ImageAssets.brokenSword,
          "Missed Attacks",
        );

      case '0stars':
        return withImageIcon(
            "${member.zeroStar}", ImageAssets.attackStar, "0 Star");

      case '1stars':
        return withImageIcon(
            "${member.oneStar}", ImageAssets.attackStar, "1 Star");

      case '2stars':
        return withImageIcon(
            "${member.twoStars}", ImageAssets.attackStar, "2 Stars");

      case '3stars':
        return withImageIcon(
            "${member.threeStars}", ImageAssets.attackStar, "3 Stars");

      case 'attackLowerTH':
        return withImageIcon(
          member.attackLowerTHLevel?.toStringAsFixed(0) ?? '0',
          ImageAssets.townHall(1),
          "Lower TH Attacks",
        );

      case 'attackUpperTH':
        return withImageIcon(
          member.attackUpperTHLevel?.toStringAsFixed(0) ?? '0',
          ImageAssets.townHall(1),
          "Upper TH Attacks",
        );

      // --- Défense ---
      case 'defStars':
        return withImageIcon(
            "${defense?.stars ?? 0}", ImageAssets.attackStar, "Def Stars");

      case 'defDestruction':
        return withImageIcon(
            (defense?.totalDestruction ?? 0).toStringAsFixed(0),
            ImageAssets.hitrate,
            "Def %");

      case 'defAverageStars':
        return withImageIcon(
            "${defense?.averageStars?.toStringAsFixed(1) ?? '0.0'}",
            ImageAssets.attackStar,
            "Avg Def Stars");

      case 'defAverageDestruction':
        return withImageIcon(
            "${defense?.averageDestruction?.toStringAsFixed(1) ?? '0.0'}",
            ImageAssets.hitrate,
            "Avg Def %");

      case 'def0stars':
        return withImageIcon(
            "${member.zeroStarDef}", ImageAssets.attackStar, "0 Star Def");

      case 'def1stars':
        return withImageIcon(
            "${member.oneStarDef}", ImageAssets.attackStar, "1 Star Def");

      case 'def2stars':
        return withImageIcon(
            "${member.twoStarsDef}", ImageAssets.attackStar, "2 Stars Def");

      case 'def3stars':
        return withImageIcon(
            "${member.threeStarsDef}", ImageAssets.attackStar, "3 Stars Def");

      case 'defenseLowerTH':
        return withImageIcon(
          member.defenseLowerTHLevel?.toStringAsFixed(0) ?? '0',
          ImageAssets.townHall(1),
          "Lower TH Def",
        );

      case 'defenseUpperTH':
        return withImageIcon(
          member.defenseUpperTHLevel?.toStringAsFixed(0) ?? '0',
          ImageAssets.townHall(1),
          "Upper TH Def",
        );
      case 'zeroStars':
        return withImageIcon(
            "${member.zeroStar}", ImageAssets.attackStar, "0 Stars");

      case 'oneStar':
        return withImageIcon(
            "${member.oneStar}", ImageAssets.attackStar, "1 Star");

      case 'twoStars':
        return withImageIcon(
            "${member.twoStars}", ImageAssets.attackStar, "2 Stars");

      case 'threeStars':
        return withImageIcon(
            "${member.threeStars}", ImageAssets.attackStar, "3 Stars");

      case 'attackOrder':
        return withImageIcon(member.avgAttackOrder?.toStringAsFixed(1) ?? "-",
            ImageAssets.iconClock, "Attack Order");

      case 'opponentPosition':
        return withIcon(member.avgOpponentPosition?.toStringAsFixed(1) ?? "-",
            Icon(Icons.location_pin), "Opponent Position");

      case 'opponentTH':
        return withImageIcon(
            member.avgOpponentTownHallLevel?.toStringAsFixed(1) ?? "-",
            ImageAssets.townHall(member.avgOpponentTownHallLevel?.round() ?? 1),
            "Opponent TH Level");

      case 'defenseOrder':
        return withImageIcon(member.avgDefenseOrder?.toStringAsFixed(1) ?? "-",
            ImageAssets.iconClock, "Defense Order");

      case 'attackerPosition':
        return withIcon(member.avgAttackerPosition?.toStringAsFixed(1) ?? "-",
            Icon(Icons.location_pin), "Attacker Position");

      case 'attackerTH':
        return withImageIcon(
            member.avgAttackerTownHallLevel?.toStringAsFixed(1) ?? "-",
            ImageAssets.townHall(member.avgAttackerTownHallLevel?.round() ?? 1),
            "Attacker TH Level");
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
                Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Icon(Icons.location_pin,
                            size: 16, color: Colors.redAccent),
                        Text(
                            member.avgOpponentPosition?.toStringAsFixed(1) ??
                                "-",
                            style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                    const SizedBox(height: 4),
                    MobileWebImage(
                      imageUrl: ImageAssets.townHall(member.townhallLevel),
                      width: 36,
                      height: 36,
                    ),
                  ],
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
                          await PlayerService().getPlayerAndClanData(member.tag);
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
                      label: AppLocalizations.of(context)!.attacks,
                      value: '${attack.attackCount}',
                      icon: MobileWebImage(
                          imageUrl: ImageAssets.sword, width: 16, height: 16)),
                  StatTile(
                      label: AppLocalizations.of(context)!.missed,
                      value: '${attack.missedAttacks}',
                      icon: MobileWebImage(
                          imageUrl: ImageAssets.brokenSword,
                          width: 16,
                          height: 16)),
                  StatTile(
                      label: AppLocalizations.of(context)!.total,
                      value: '${attack.stars}',
                      icon: MobileWebImage(
                          imageUrl: ImageAssets.attackStar,
                          width: 16,
                          height: 16)),
                  StatTile(
                      label: AppLocalizations.of(context)!.avg,
                      value:
                          '${attack.averageStars?.toStringAsFixed(1) ?? "0.0"}',
                      icon: MobileWebImage(
                          imageUrl: ImageAssets.attackStar,
                          width: 16,
                          height: 16)),
                  StatTile(
                      label: AppLocalizations.of(context)!.threeStars,
                      value: '${member.threeStars}',
                      icon: buildStarsIcon(3)),
                  StatTile(
                      label: AppLocalizations.of(context)!.twoStars,
                      value: '${member.twoStars}',
                      icon: buildStarsIcon(2)),
                  StatTile(
                      label: AppLocalizations.of(context)!.oneStar,
                      value: '${member.oneStar}',
                      icon: buildStarsIcon(1)),
                  StatTile(
                      label: AppLocalizations.of(context)!.zeroStar,
                      value: '${member.zeroStar}',
                      icon: buildStarsIcon(0)),
                  StatTile(
                      label: AppLocalizations.of(context)!.destruction,
                      value: '${attack.totalDestruction.toStringAsFixed(1)}%',
                      icon: MobileWebImage(
                          imageUrl: ImageAssets.hitrate,
                          width: 16,
                          height: 16)),
                  StatTile(
                      label: AppLocalizations.of(context)!.avgPercentage,
                      value:
                          '${attack.averageDestruction?.toStringAsFixed(1) ?? "0.0"}',
                      icon: MobileWebImage(
                          imageUrl: ImageAssets.hitrate,
                          width: 16,
                          height: 16)),
                  StatTile(
                      label: AppLocalizations.of(context)!.order,
                      value: member.avgAttackOrder?.toStringAsFixed(1) ?? "-",
                      icon: MobileWebImage(
                          imageUrl: ImageAssets.iconClock,
                          width: 16,
                          height: 16)),
                  StatTile(
                      label: AppLocalizations.of(context)!.pos,
                      value:
                          member.avgOpponentPosition?.toStringAsFixed(1) ?? "-",
                      icon: const Icon(Icons.location_pin,
                          size: 16, color: Colors.redAccent)),
                  StatTile(
                      label: AppLocalizations.of(context)!.oppTownhall,
                      value:
                          member.avgOpponentTownHallLevel?.toStringAsFixed(1) ??
                              "-",
                      icon: MobileWebImage(
                          imageUrl: ImageAssets.townHall(
                              member.avgOpponentTownHallLevel?.round() ?? 1),
                          width: 16,
                          height: 16)),
                  StatTile(
                      label: AppLocalizations.of(context)!.lowerTownhall,
                      value:
                          member.attackLowerTHLevel?.toStringAsFixed(0) ?? "-",
                      icon: Icon(Icons.keyboard_double_arrow_down,
                          size: 16,
                          color: Theme.of(context).colorScheme.primary)),
                  StatTile(
                      label: AppLocalizations.of(context)!.upperTownhall,
                      value:
                          member.attackUpperTHLevel?.toStringAsFixed(0) ?? "-",
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
                      label: AppLocalizations.of(context)!.defenses,
                      value: '${defense.defenseCount}',
                      icon: MobileWebImage(
                          imageUrl: ImageAssets.shieldWithArrow,
                          width: 16,
                          height: 16)),
                  StatTile(
                      label: AppLocalizations.of(context)!.missed,
                      value: '${defense.missedDefenses}',
                      icon: MobileWebImage(
                          imageUrl: ImageAssets.shield, width: 16, height: 16)),
                  StatTile(
                      label: AppLocalizations.of(context)!.total,
                      value: '${defense.stars}',
                      icon: MobileWebImage(
                          imageUrl: ImageAssets.attackStar,
                          width: 16,
                          height: 16)),
                  StatTile(
                      label: AppLocalizations.of(context)!.avg,
                      value:
                          '${defense.averageStars?.toStringAsFixed(1) ?? "0.0"}',
                      icon: MobileWebImage(
                          imageUrl: ImageAssets.attackStar,
                          width: 16,
                          height: 16)),
                  StatTile(
                      label: AppLocalizations.of(context)!.threeStars,
                      value: '${member.threeStarsDef}',
                      icon: buildStarsIcon(3)),
                  StatTile(
                      label: AppLocalizations.of(context)!.twoStars,
                      value: '${member.twoStarsDef}',
                      icon: buildStarsIcon(2)),
                  StatTile(
                      label: AppLocalizations.of(context)!.oneStar,
                      value: '${member.oneStarDef}',
                      icon: buildStarsIcon(1)),
                  StatTile(
                      label: AppLocalizations.of(context)!.zeroStar,
                      value: '${member.zeroStarDef}',
                      icon: buildStarsIcon(0)),
                  StatTile(
                      label: AppLocalizations.of(context)!.destruction,
                      value: '${defense.totalDestruction.toStringAsFixed(1)}%',
                      icon: MobileWebImage(
                          imageUrl: ImageAssets.hitrate,
                          width: 16,
                          height: 16)),
                  StatTile(
                      label: AppLocalizations.of(context)!.avgPercentage,
                      value:
                          '${defense.averageDestruction?.toStringAsFixed(1) ?? "0.0"}',
                      icon: MobileWebImage(
                          imageUrl: ImageAssets.hitrate,
                          width: 16,
                          height: 16)),
                  StatTile(
                      label: AppLocalizations.of(context)!.order,
                      value: member.avgDefenseOrder?.toStringAsFixed(1) ?? "-",
                      icon: MobileWebImage(
                          imageUrl: ImageAssets.iconClock,
                          width: 16,
                          height: 16)),
                  StatTile(
                      label: AppLocalizations.of(context)!.pos,
                      value:
                          member.avgAttackerPosition?.toStringAsFixed(1) ?? "-",
                      icon: const Icon(Icons.location_pin,
                          size: 16, color: Colors.redAccent)),
                  StatTile(
                      label: AppLocalizations.of(context)!.oppTownhall,
                      value:
                          member.avgAttackerTownHallLevel?.toStringAsFixed(1) ??
                              "-",
                      icon: MobileWebImage(
                          imageUrl: ImageAssets.townHall(
                              member.avgAttackerTownHallLevel?.round() ?? 1),
                          width: 16,
                          height: 16)),
                  StatTile(
                      label: AppLocalizations.of(context)!.lowerTownhall,
                      value:
                          member.defenseLowerTHLevel?.toStringAsFixed(0) ?? "-",
                      icon: Icon(Icons.keyboard_double_arrow_down,
                          size: 16,
                          color: Theme.of(context).colorScheme.primary)),
                  StatTile(
                      label: AppLocalizations.of(context)!.upperTownhall,
                      value:
                          member.defenseUpperTHLevel?.toStringAsFixed(0) ?? "-",
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
}
