import 'package:clashkingapp/common/theme/app_tokens.dart';
import 'package:clashkingapp/common/widgets/mobile_web_image.dart';
import 'package:clashkingapp/core/constants/image_assets.dart';
import 'package:clashkingapp/core/services/game_data_service.dart';
import 'package:clashkingapp/features/player/data/player_item_utils.dart';
import 'package:clashkingapp/features/player/data/player_service.dart';
import 'package:clashkingapp/features/player/models/player.dart';
import 'package:clashkingapp/features/player/models/player_item.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'side_page_components.dart';

export 'calculators_page.dart';
export 'game_assets_page.dart';
export 'rankings_page.dart';
export 'stats_page.dart';

class UpgradeTrackerTeasePage extends StatefulWidget {
  const UpgradeTrackerTeasePage({super.key});

  @override
  State<UpgradeTrackerTeasePage> createState() =>
      _UpgradeTrackerTeasePageState();
}

class _UpgradeTrackerTeasePageState extends State<UpgradeTrackerTeasePage> {
  String? _selectedTag;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final players = context.watch<PlayerService>().profiles;
    final selected = _selectedPlayer(players);
    final summary = selected == null
        ? null
        : _UpgradeAccountSummary(selected, loc);

    return SidePageScaffold(
      title: loc.upgradeTrackerTitle,
      subtitle: selected == null
          ? loc.upgradeTrackerSubtitle
          : '${selected.name} · TH${selected.townHallLevel}',
      child: ListView(
        padding: sidePagePadding,
        children: [
          if (players.isNotEmpty)
            DropdownButtonFormField<String>(
              initialValue: selected?.tag,
              decoration: InputDecoration(labelText: loc.linkedAccountLabel),
              items: players
                  .map(
                    (player) => DropdownMenuItem(
                      value: player.tag,
                      child: Text(
                        '${player.name} · ${loc.gameTownHallShortLevel(player.townHallLevel)}',
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _selectedTag = value),
            )
          else
            SidePageEmptyState(
              icon: Icons.construction_rounded,
              title: loc.noLinkedPlayersLoadedTitle,
              body: loc.noLinkedPlayersLoadedBody,
            ),
          if (summary != null) ...[
            const SizedBox(height: 16),
            _UpgradeSummaryPanel(summary: summary),
            const SizedBox(height: 18),
            for (final section in summary.sections) ...[
              _UpgradeTrackerSection(section: section),
              const SizedBox(height: 14),
            ],
          ],
        ],
      ),
    );
  }

  Player? _selectedPlayer(List<Player> players) {
    if (players.isEmpty) return null;
    if (_selectedTag == null) return players.first;
    return players.firstWhere(
      (player) => player.tag == _selectedTag,
      orElse: () => players.first,
    );
  }
}

class _UpgradeAccountSummary {
  final Player player;
  late final List<_UpgradeSectionSummary> sections;

  _UpgradeAccountSummary(this.player, AppLocalizations loc) {
    sections = [
      _UpgradeSectionSummary(
        title: loc.upgradeSectionHeroes,
        icon: Icons.person_rounded,
        items: player.heroes,
        townHallLevel: player.townHallLevel,
      ),
      _UpgradeSectionSummary(
        title: loc.upgradeSectionTroops,
        icon: Icons.groups_rounded,
        items: player.troops,
        townHallLevel: player.townHallLevel,
      ),
      _UpgradeSectionSummary(
        title: loc.upgradeSectionSpells,
        icon: Icons.auto_fix_high_rounded,
        items: player.spells,
        townHallLevel: player.townHallLevel,
      ),
      _UpgradeSectionSummary(
        title: loc.upgradeSectionPets,
        icon: Icons.pets_rounded,
        items: player.pets,
        townHallLevel: player.townHallLevel,
      ),
      _UpgradeSectionSummary(
        title: loc.upgradeSectionEquipment,
        icon: Icons.diamond_rounded,
        items: player.equipments,
        townHallLevel: player.townHallLevel,
      ),
    ];
  }

  int get totalLevels =>
      sections.fold(0, (total, section) => total + section.levelsRemaining);

  int get totalSeconds =>
      sections.fold(0, (total, section) => total + section.seconds);

  List<UpgradeResourceAmount> get totalResources {
    final totals = <String, num>{};
    for (final section in sections) {
      for (final resource in section.resources) {
        totals[resource.key] = (totals[resource.key] ?? 0) + resource.amount;
      }
    }
    return totals.entries
        .map((entry) => UpgradeResourceAmount(entry.key, entry.value))
        .toList()
      ..sort(
        (a, b) =>
            resourceSortWeight(a.key).compareTo(resourceSortWeight(b.key)),
      );
  }
}

class _UpgradeSectionSummary {
  final String title;
  final IconData icon;
  final List<PlayerItem> items;
  final int townHallLevel;
  late final List<_UpgradeItemSummary> itemSummaries;

  _UpgradeSectionSummary({
    required this.title,
    required this.icon,
    required this.items,
    required this.townHallLevel,
  }) {
    itemSummaries =
        items
            .where((item) => item.isUnlocked && item.meta != null)
            .map((item) {
              final thMax = maxLevelForItemAtTH(item, townHallLevel);
              final targetLevel = thMax > 0 ? thMax : item.maxLevel;
              return _UpgradeItemSummary(
                item: item,
                summary: calculateRemainingUpgradeSummary(
                  item,
                  targetLevel: targetLevel,
                ),
              );
            })
            .where((entry) => entry.summary.levelsRemaining > 0)
            .toList()
          ..sort((a, b) {
            final timeCompare = b.summary.seconds.compareTo(a.summary.seconds);
            if (timeCompare != 0) return timeCompare;
            return b.summary.levelsRemaining.compareTo(
              a.summary.levelsRemaining,
            );
          });
  }

  int get levelsRemaining => itemSummaries.fold(
    0,
    (total, item) => total + item.summary.levelsRemaining,
  );

  int get seconds =>
      itemSummaries.fold(0, (total, item) => total + item.summary.seconds);

  List<UpgradeResourceAmount> get resources {
    final totals = <String, num>{};
    for (final item in itemSummaries) {
      for (final resource in item.summary.resources) {
        totals[resource.key] = (totals[resource.key] ?? 0) + resource.amount;
      }
    }
    return totals.entries
        .map((entry) => UpgradeResourceAmount(entry.key, entry.value))
        .toList()
      ..sort(
        (a, b) =>
            resourceSortWeight(a.key).compareTo(resourceSortWeight(b.key)),
      );
  }
}

class _UpgradeItemSummary {
  final PlayerItem item;
  final UpgradeRemainingSummary summary;

  const _UpgradeItemSummary({required this.item, required this.summary});
}

class _UpgradeSummaryPanel extends StatelessWidget {
  final _UpgradeAccountSummary summary;

  const _UpgradeSummaryPanel({required this.summary});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.68),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              summary.totalLevels == 0
                  ? 'TH${summary.player.townHallLevel} maxed'
                  : '${summary.totalLevels} levels left',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              summary.totalSeconds == 0
                  ? 'No tracked upgrades remaining for this Town Hall.'
                  : '${_formatUpgradeDuration(summary.totalSeconds)} remaining upgrade time',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onPrimaryContainer.withValues(alpha: 0.78),
                fontWeight: FontWeight.w600,
              ),
            ),
            if (summary.totalResources.isNotEmpty) ...[
              const SizedBox(height: 12),
              _UpgradeResourceWrap(resources: summary.totalResources),
            ],
          ],
        ),
      ),
    );
  }
}

class _UpgradeTrackerSection extends StatelessWidget {
  final _UpgradeSectionSummary section;

  const _UpgradeTrackerSection({required this.section});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.32),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(section.icon, size: 20, color: colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    section.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                _UpgradeTextPill(
                  text: section.levelsRemaining == 0
                      ? 'Maxed'
                      : '${section.levelsRemaining} levels',
                  color: section.levelsRemaining == 0
                      ? StatColors.win
                      : StatColors.warStarGold,
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (section.levelsRemaining == 0)
              Text(
                'Nothing left to upgrade for this Town Hall.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              )
            else ...[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _UpgradeTextPill(
                    text: _formatUpgradeDuration(section.seconds),
                    color: colorScheme.primary,
                    icon: Icons.schedule_rounded,
                  ),
                  ...section.resources.map(
                    (resource) => _UpgradeResourcePill(resource: resource),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              for (final item in section.itemSummaries.take(4)) ...[
                _UpgradeItemLine(item: item),
                if (item != section.itemSummaries.take(4).last)
                  const SizedBox(height: 8),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _UpgradeItemLine extends StatelessWidget {
  final _UpgradeItemSummary item;

  const _UpgradeItemLine({required this.item});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        MobileWebImage(imageUrl: item.item.imageUrl, width: 34, height: 34),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                GameDataService.localizedNameForItem(item.item.meta),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  height: 1.08,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Lvl ${item.item.level} → ${item.summary.targetLevel}',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        _UpgradeTextPill(
          text: _formatUpgradeDuration(item.summary.seconds),
          color: colorScheme.secondary,
        ),
      ],
    );
  }
}

class _UpgradeResourceWrap extends StatelessWidget {
  final List<UpgradeResourceAmount> resources;

  const _UpgradeResourceWrap({required this.resources});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: resources
          .map((resource) => _UpgradeResourcePill(resource: resource))
          .toList(),
    );
  }
}

class _UpgradeResourcePill extends StatelessWidget {
  final UpgradeResourceAmount resource;

  const _UpgradeResourcePill({required this.resource});

  @override
  Widget build(BuildContext context) {
    final visual = _UpgradeResourceVisual.forKey(resource.key);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.58),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          MobileWebImage(imageUrl: visual.imageUrl, width: 18, height: 18),
          const SizedBox(width: 5),
          Text(
            _formatCompactNumber(resource.amount),
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _UpgradeTextPill extends StatelessWidget {
  final String text;
  final Color color;
  final IconData? icon;

  const _UpgradeTextPill({required this.text, required this.color, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 15, color: color),
            const SizedBox(width: 5),
          ],
          Text(
            text,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class BasesArmiesPage extends StatelessWidget {
  const BasesArmiesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return SidePageScaffold(
      title: loc.sideBasesArmiesTitle,
      subtitle: loc.sideBasesArmiesSubtitle,
      child: ListView(
        padding: sidePagePadding,
        children: [
          _TeasePanel(
            icon: Icons.grid_view_rounded,
            title: loc.sideBotSyncTarget,
            body: loc.sideBotSyncTargetBody,
          ),
          const SizedBox(height: 18),
          SidePageSectionHeader(title: loc.sideSavedBases),
          _SavedLinkPlaceholder(
            title: loc.sideWarBaseSlots,
            body: loc.sideWarBaseSlotsBody,
          ),
          _SavedLinkPlaceholder(
            title: loc.sideLegendBaseSlots,
            body: loc.sideLegendBaseSlotsBody,
          ),
          const SizedBox(height: 18),
          SidePageSectionHeader(title: loc.sideSavedArmies),
          _SavedLinkPlaceholder(
            title: loc.sideArmyLinks,
            body: loc.sideArmyLinksBody,
          ),
        ],
      ),
    );
  }
}

class _ListLine extends StatelessWidget {
  const _ListLine({
    required this.title,
    required this.subtitle,
    this.imageUrl,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final String? imageUrl;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          if (imageUrl != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: ColoredBox(
                color: colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.5,
                ),
                child: MobileWebImage(
                  imageUrl: imageUrl!,
                  width: 40,
                  height: 40,
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 8),
            Text(
              trailing!,
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
          ],
        ],
      ),
    );
  }
}

class _TeasePanel extends StatelessWidget {
  const _TeasePanel({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.36),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 30),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    body,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
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

class _SavedLinkPlaceholder extends StatelessWidget {
  const _SavedLinkPlaceholder({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return _ListLine(
      imageUrl: ImageAssets.clanCastle,
      title: title,
      subtitle: body,
      trailing: 'sync',
    );
  }
}

String _formatCompactNumber(num value) {
  if (value >= 1000000) {
    final formatted = (value / 1000000).toStringAsFixed(1);
    return '${formatted.endsWith('.0') ? formatted.replaceAll('.0', '') : formatted}M';
  }
  if (value >= 1000) {
    final formatted = (value / 1000).toStringAsFixed(1);
    return '${formatted.endsWith('.0') ? formatted.replaceAll('.0', '') : formatted}K';
  }
  return value.toInt().toString();
}

String _formatUpgradeDuration(int seconds) {
  if (seconds <= 0) return '0d';
  final days = seconds ~/ 86400;
  final hours = (seconds % 86400) ~/ 3600;
  if (days > 0) return hours > 0 ? '${days}d ${hours}h' : '${days}d';
  return hours > 0 ? '${hours}h' : '<1h';
}

class _UpgradeResourceVisual {
  final String imageUrl;

  const _UpgradeResourceVisual({required this.imageUrl});

  factory _UpgradeResourceVisual.forKey(String key) {
    if (key.contains('dark')) {
      return const _UpgradeResourceVisual(
        imageUrl: '${ImageAssets.baseUrl}/resources/dark_elixir.webp',
      );
    }
    if (key.contains('builder') && key.contains('elixir')) {
      return const _UpgradeResourceVisual(
        imageUrl: '${ImageAssets.baseUrl}/resources/builder_elixir.webp',
      );
    }
    if (key.contains('builder') && key.contains('gold')) {
      return const _UpgradeResourceVisual(
        imageUrl: '${ImageAssets.baseUrl}/resources/builder_gold.webp',
      );
    }
    if (key.contains('elixir')) {
      return const _UpgradeResourceVisual(
        imageUrl: '${ImageAssets.baseUrl}/resources/elixir.webp',
      );
    }
    if (key.contains('gold')) {
      return const _UpgradeResourceVisual(
        imageUrl: '${ImageAssets.baseUrl}/resources/gold.webp',
      );
    }
    if (key.contains('glowy')) {
      return const _UpgradeResourceVisual(
        imageUrl: '${ImageAssets.baseUrl}/resources/glowy_ore.webp',
      );
    }
    if (key.contains('starry')) {
      return const _UpgradeResourceVisual(
        imageUrl: '${ImageAssets.baseUrl}/resources/starry_ore.webp',
      );
    }
    if (key.contains('shiny')) {
      return const _UpgradeResourceVisual(
        imageUrl: '${ImageAssets.baseUrl}/resources/shiny_ore.webp',
      );
    }
    return const _UpgradeResourceVisual(imageUrl: ImageAssets.defaultImage);
  }
}
