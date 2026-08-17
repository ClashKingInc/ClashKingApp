import 'package:clashking_design_system/clashking_design_system.dart';
import 'package:clashkingapp/common/theme/app_tokens.dart';
import 'package:clashkingapp/common/widgets/empty_state.dart';
import 'package:clashkingapp/common/widgets/inputs/filter_dropdown.dart';
import 'package:clashkingapp/common/widgets/loading/skeleton_loading.dart';
import 'package:clashkingapp/common/widgets/mobile_web_image.dart';
import 'package:clashkingapp/common/widgets/responsive_card_grid.dart';
import 'package:clashkingapp/core/constants/image_assets.dart';
import 'package:clashkingapp/features/player/data/player_service.dart';
import 'package:clashkingapp/features/player/models/player_battlelog.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class PlayerBattlelogTab extends StatefulWidget {
  const PlayerBattlelogTab({
    super.key,
    required this.playerTag,
    required this.bottomPadding,
  });

  final String playerTag;
  final double bottomPadding;

  @override
  State<PlayerBattlelogTab> createState() => _PlayerBattlelogTabState();
}

enum _BattleDirection { all, attacks, defenses }

class _PlayerBattlelogTabState extends State<PlayerBattlelogTab> {
  PlayerBattlelogMode _mode = PlayerBattlelogMode.ranked;
  _BattleDirection _direction = _BattleDirection.all;
  late Future<PlayerBattlelogData> _load;

  @override
  void initState() {
    super.initState();
    _load = context.read<PlayerService>().loadPlayerBattlelog(widget.playerTag);
  }

  Future<void> _refresh() async {
    final next = context.read<PlayerService>().loadPlayerBattlelog(
      widget.playerTag,
      forceRefresh: true,
    );
    setState(() => _load = next);
    await next;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PlayerBattlelogData>(
      future: _load,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            snapshot.data == null) {
          return ListView(
            primary: true,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(16, 12, 16, widget.bottomPadding),
            children: const [SkeletonList(itemCount: 5)],
          );
        }
        if (snapshot.hasError && snapshot.data == null) {
          final loc = AppLocalizations.of(context)!;
          return ListView(
            primary: true,
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              AppEmptyState(
                icon: Icons.cloud_off_rounded,
                title: loc.playerBattlelogLoadError,
                body: loc.generalTryAgain,
                actionLabel: loc.generalRetry,
                onAction: _refresh,
              ),
            ],
          );
        }

        final data = snapshot.data!;
        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            primary: true,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(16, 10, 16, widget.bottomPadding),
            children: [
              Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1120),
                  child: _BattlelogContent(
                    data: data,
                    mode: _mode,
                    direction: _direction,
                    onModeChanged: (mode) => setState(() => _mode = mode),
                    onDirectionChanged: (direction) =>
                        setState(() => _direction = direction),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _BattlelogContent extends StatelessWidget {
  const _BattlelogContent({
    required this.data,
    required this.mode,
    required this.direction,
    required this.onModeChanged,
    required this.onDirectionChanged,
  });

  final PlayerBattlelogData data;
  final PlayerBattlelogMode mode;
  final _BattleDirection direction;
  final ValueChanged<PlayerBattlelogMode> onModeChanged;
  final ValueChanged<_BattleDirection> onDirectionChanged;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final battles = data.forMode(mode);
    final popularAttacks = data.popularTroops(mode, limit: 5);
    final popularDefenses = data.popularTroops(mode, limit: 5, attack: false);
    final visibleBattles = switch (direction) {
      _BattleDirection.all => battles,
      _BattleDirection.attacks =>
        battles.where((battle) => battle.attack).toList(growable: false),
      _BattleDirection.defenses =>
        battles.where((battle) => !battle.attack).toList(growable: false),
    };
    final directionOptions = <String, String>{
      loc.generalAll: _BattleDirection.all.name,
      loc.warAttacksTitle: _BattleDirection.attacks.name,
      loc.warDefensesTitle: _BattleDirection.defenses.name,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CKSegmentedControl<PlayerBattlelogMode>(
          values: const [
            PlayerBattlelogMode.ranked,
            PlayerBattlelogMode.farming,
          ],
          labels: [loc.playerBattlelogRanked, loc.playerBattlelogFarming],
          selected: mode,
          onChanged: onModeChanged,
          density: CKControlDensity.compact,
        ),
        if (!data.historyAvailable || !data.officialAvailable) ...[
          const SizedBox(height: CKSpacing.md),
          _AvailabilityNotice(
            message: data.historyAvailable
                ? loc.playerBattlelogOfficialUnavailable
                : loc.playerBattlelogHistoryUnavailable,
          ),
        ],
        const SizedBox(height: CKSpacing.md),
        _BattleSummary(
          mode: mode,
          battles: battles,
          popularAttacks: popularAttacks,
          popularDefenses: popularDefenses,
        ),
        const SizedBox(height: CKSpacing.lg),
        Row(
          children: [
            Expanded(
              child: Text(
                loc.playerBattlelogRecentBattles,
                style: CKTypography.of(context, CKTextRole.sectionTitle),
              ),
            ),
            const SizedBox(width: CKSpacing.sm),
            FilterDropdown(
              key: const ValueKey('battle-direction-filter'),
              sortBy: direction.name,
              updateSortBy: (value) =>
                  onDirectionChanged(_BattleDirection.values.byName(value)),
              sortByOptions: directionOptions,
              maxWidth: 132,
              height: 40,
              leadingIcon: Icons.filter_list_rounded,
            ),
          ],
        ),
        const SizedBox(height: CKSpacing.sm),
        if (battles.isEmpty)
          AppEmptyState(
            icon: Icons.history_toggle_off_rounded,
            title: loc.playerBattlelogNoBattlesTitle,
            body: loc.playerBattlelogNoBattlesBody,
            padding: EdgeInsets.zero,
          )
        else if (visibleBattles.isEmpty)
          AppEmptyState(
            icon: Icons.filter_alt_off_rounded,
            title: loc.generalNoFilteredResults,
            body: loc.generalAdjustFilters,
            padding: EdgeInsets.zero,
          )
        else
          ResponsiveCardGrid(
            itemCount: visibleBattles.length,
            minItemWidth: 430,
            maxColumns: 2,
            spacing: CKSpacing.md,
            itemBuilder: (_, index) =>
                _BattleRow(battle: visibleBattles[index]),
          ),
      ],
    );
  }
}

class _AvailabilityNotice extends StatelessWidget {
  const _AvailabilityNotice({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      container: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest.withValues(alpha: 0.30),
          borderRadius: BorderRadius.circular(CKRadius.tile),
        ),
        child: Padding(
          padding: const EdgeInsets.all(CKSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: 20,
                color: scheme.onSurfaceVariant,
              ),
              const SizedBox(width: CKSpacing.sm),
              Expanded(
                child: Text(
                  message,
                  style: CKTypography.of(
                    context,
                    CKTextRole.metadata,
                  ).copyWith(color: scheme.onSurfaceVariant),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BattleSummary extends StatelessWidget {
  const _BattleSummary({
    required this.mode,
    required this.battles,
    required this.popularAttacks,
    required this.popularDefenses,
  });

  final PlayerBattlelogMode mode;
  final List<PlayerBattlelogEntry> battles;
  final List<PlayerPopularArmyItem> popularAttacks;
  final List<PlayerPopularArmyItem> popularDefenses;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final attacks = battles.where((battle) => battle.attack).toList();
    final defenses = battles.where((battle) => !battle.attack).toList();
    final attackAverageDestruction = _average(
      attacks.map((battle) => battle.destructionPercentage),
    );
    final attackAverageStars = _average(attacks.map((battle) => battle.stars));
    final attackTripleRate = attacks.isEmpty
        ? 0.0
        : attacks.where((battle) => battle.stars == 3).length / attacks.length;
    final averageLoot = _average(attacks.map((battle) => battle.totalLoot));
    final defenseAverageDestruction = _average(
      defenses.map((battle) => battle.destructionPercentage),
    );
    final defenseAverageStars = _average(
      defenses.map((battle) => battle.stars),
    );
    final defenseTripleRate = defenses.isEmpty
        ? 0.0
        : defenses.where((battle) => battle.stars == 3).length /
              defenses.length;
    final formatter = NumberFormat.compact(
      locale: Localizations.localeOf(context).toString(),
    );
    final attackMetrics = mode == PlayerBattlelogMode.farming
        ? <(String, String, String)>[
            (
              ImageAssets.attacksNoShield,
              loc.generalTotal,
              '${attacks.length}',
            ),
            (
              ImageAssets.attackStar,
              loc.warAbbreviationAvg,
              attackAverageStars.toStringAsFixed(2),
            ),
            (
              ImageAssets.hitrate,
              loc.warAbbreviationAvgPercentage,
              '${attackAverageDestruction.toStringAsFixed(1)}%',
            ),
            (
              ImageAssets.lootCart,
              loc.generalAverage,
              formatter.format(averageLoot.round()),
            ),
          ]
        : <(String, String, String)>[
            (
              ImageAssets.attacksNoShield,
              loc.generalTotal,
              '${attacks.length}',
            ),
            (
              ImageAssets.attackStar,
              loc.warAbbreviationAvg,
              attackAverageStars.toStringAsFixed(2),
            ),
            (
              ImageAssets.hitrate,
              loc.warAbbreviationAvgPercentage,
              '${attackAverageDestruction.toStringAsFixed(1)}%',
            ),
            (
              ImageAssets.attackStar,
              loc.warStarsThree,
              '${(attackTripleRate * 100).toStringAsFixed(1)}%',
            ),
          ];
    final defenseMetrics = <(String, String, String)>[
      (ImageAssets.shieldWithArrow, loc.generalTotal, '${defenses.length}'),
      (
        ImageAssets.attackStar,
        loc.warAbbreviationAvg,
        defenseAverageStars.toStringAsFixed(2),
      ),
      (
        ImageAssets.hitrate,
        loc.warAbbreviationAvgPercentage,
        '${defenseAverageDestruction.toStringAsFixed(1)}%',
      ),
      (
        ImageAssets.attackStar,
        loc.warStarsThree,
        '${(defenseTripleRate * 100).toStringAsFixed(1)}%',
      ),
    ];

    return CKSectionPanel(
      key: const ValueKey('player-battle-summary'),
      padding: const EdgeInsets.all(CKSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  mode == PlayerBattlelogMode.farming
                      ? loc.playerBattlelogFarmingOverview
                      : loc.playerBattlelogRankedOverview,
                  style: CKTypography.of(context, CKTextRole.rowTitle),
                ),
              ),
              const SizedBox(width: CKSpacing.sm),
              Text(
                loc.playerBattlelogBattleCount(battles.length),
                style: CKTypography.of(context, CKTextRole.metadata).copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: CKSpacing.md),
          _BattleOverviewBand(
            direction: _BattleDirection.attacks,
            title: loc.warAttacksTitle,
            imageUrl: ImageAssets.sword,
            metrics: attackMetrics,
            popularTroopsLabel: loc.playerBattlelogPopularTroops,
            popularTroops: popularAttacks,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: CKSpacing.md),
            child: Divider(
              height: 1,
              color: Theme.of(
                context,
              ).colorScheme.outlineVariant.withValues(alpha: 0.36),
            ),
          ),
          _BattleOverviewBand(
            direction: _BattleDirection.defenses,
            title: loc.warDefensesTitle,
            imageUrl: ImageAssets.shieldWithArrow,
            metrics: defenseMetrics,
            popularTroopsLabel: loc.playerBattlelogPopularTroops,
            popularTroops: popularDefenses,
          ),
        ],
      ),
    );
  }
}

double _average(Iterable<int> values) {
  if (values.isEmpty) return 0;
  return values.reduce((a, b) => a + b) / values.length;
}

class _BattleOverviewBand extends StatelessWidget {
  const _BattleOverviewBand({
    required this.direction,
    required this.title,
    required this.imageUrl,
    required this.metrics,
    required this.popularTroopsLabel,
    required this.popularTroops,
  });

  final _BattleDirection direction;
  final String title;
  final String imageUrl;
  final List<(String, String, String)> metrics;
  final String popularTroopsLabel;
  final List<PlayerPopularArmyItem> popularTroops;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            MobileWebImage(imageUrl: imageUrl, width: 18, height: 18),
            const SizedBox(width: CKSpacing.xs),
            Text(
              title,
              style: CKTypography.of(context, CKTextRole.compactLabel),
            ),
          ],
        ),
        const SizedBox(height: CKSpacing.sm),
        Row(
          children: [
            for (final metric in metrics)
              Expanded(
                child: _BattleSummaryStat(
                  imageUrl: metric.$1,
                  label: metric.$2,
                  value: metric.$3,
                ),
              ),
          ],
        ),
        if (popularTroops.isNotEmpty) ...[
          const SizedBox(height: CKSpacing.sm),
          Text(
            popularTroopsLabel,
            textAlign: TextAlign.center,
            style: CKTypography.of(
              context,
              CKTextRole.compactLabel,
            ).copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: CKSpacing.xs),
          _PopularTroopRow(direction: direction, items: popularTroops),
        ],
      ],
    );
  }
}

class _BattleSummaryStat extends StatelessWidget {
  const _BattleSummaryStat({
    required this.imageUrl,
    required this.label,
    required this.value,
  });

  final String imageUrl;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      label: '$label: $value',
      excludeSemantics: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          MobileWebImage(imageUrl: imageUrl, width: 20, height: 20),
          const SizedBox(height: CKSpacing.xs),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: CKTypography.of(
              context,
              CKTextRole.compactLabel,
            ).copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: CKTypography.of(context, CKTextRole.rowTitle),
          ),
        ],
      ),
    );
  }
}

class _PopularTroopRow extends StatelessWidget {
  const _PopularTroopRow({required this.direction, required this.items});

  final _BattleDirection direction;
  final List<PlayerPopularArmyItem> items;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var index = 0; index < items.length; index++) ...[
            if (index > 0) const SizedBox(width: CKSpacing.xs),
            Expanded(
              child: _PopularTroop(direction: direction, item: items[index]),
            ),
          ],
        ],
      ),
    );
  }
}

class _PopularTroop extends StatelessWidget {
  const _PopularTroop({required this.direction, required this.item});

  final _BattleDirection direction;
  final PlayerPopularArmyItem item;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      label: '${item.item.name}, ×${item.uses}',
      excludeSemantics: true,
      child: Column(
        children: [
          SizedBox.square(
            dimension: 48,
            child: CKGameItemTile(
              key: ValueKey(
                'popular-troop-${direction.name}-${item.item.code}',
              ),
              artwork: MobileWebImage(
                imageUrl: item.item.imageUrl,
                fit: BoxFit.cover,
              ),
              semanticLabel: item.item.name,
              borderColor: scheme.onSurface.withValues(alpha: 0.82),
            ),
          ),
          const SizedBox(height: CKSpacing.xs),
          Text(
            item.item.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: CKTypography.of(context, CKTextRole.compactLabel),
          ),
          Text(
            '×${item.uses}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: CKTypography.of(
              context,
              CKTextRole.compactLabel,
            ).copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _BattleRow extends StatelessWidget {
  const _BattleRow({required this.battle});

  final PlayerBattlelogEntry battle;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final locale = Localizations.localeOf(context).toString();
    final time = battle.timestamp == null
        ? ''
        : DateFormat.yMMMd(locale).add_jm().format(battle.timestamp!.toLocal());
    final army = battle.armyCounts.entries.take(6).toList(growable: false);
    final formatter = NumberFormat.compact(locale: locale);
    final accent = battle.attack ? StatColors.win : CKColors.builderBlue;
    return CKSectionPanel(
      key: ValueKey(
        'player-battle-${battle.id.isEmpty ? battle.mergeKey : battle.id}',
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: CKSpacing.md,
        vertical: CKSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (battle.opponentTownHall > 0)
                MobileWebImage(
                  key: ValueKey('battle-townhall-${battle.mergeKey}'),
                  imageUrl: ImageAssets.townHall(battle.opponentTownHall),
                  width: 42,
                  height: 42,
                )
              else
                MobileWebImage(
                  imageUrl: battle.attack
                      ? ImageAssets.attacks
                      : ImageAssets.shield,
                  width: 34,
                  height: 34,
                ),
              const SizedBox(width: CKSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      battle.opponentName.isEmpty
                          ? battle.opponentTag
                          : battle.opponentName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: CKTypography.of(context, CKTextRole.rowTitle),
                    ),
                    if (time.isNotEmpty)
                      Text(
                        time,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: CKTypography.of(
                          context,
                          CKTextRole.metadata,
                        ).copyWith(color: scheme.onSurfaceVariant),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: CKSpacing.sm),
              MobileWebImage(
                key: ValueKey('battle-direction-icon-${battle.mergeKey}'),
                imageUrl: battle.attack
                    ? ImageAssets.sword
                    : ImageAssets.shieldWithArrow,
                width: 20,
                height: 20,
              ),
            ],
          ),
          const SizedBox(height: CKSpacing.sm),
          Wrap(
            spacing: CKSpacing.md,
            runSpacing: CKSpacing.sm,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var index = 0; index < 3; index++) ...[
                    MobileWebImage(
                      imageUrl: index < battle.stars
                          ? ImageAssets.attackStar
                          : ImageAssets.emptyStar,
                      width: 19,
                      height: 19,
                    ),
                    if (index < 2) const SizedBox(width: 2),
                  ],
                  const SizedBox(width: CKSpacing.sm),
                  Text(
                    '${battle.destructionPercentage}%',
                    style: CKTypography.of(
                      context,
                      CKTextRole.rowTitle,
                    ).copyWith(color: accent),
                  ),
                ],
              ),
              if (battle.gold > 0)
                _LootValue(
                  imageUrl: ImageAssets.gold,
                  label: loc.resourceGold,
                  value: formatter.format(battle.gold),
                ),
              if (battle.elixir > 0)
                _LootValue(
                  imageUrl: ImageAssets.elixir,
                  label: loc.resourceElixir,
                  value: formatter.format(battle.elixir),
                ),
              if (battle.darkElixir > 0)
                _LootValue(
                  imageUrl: ImageAssets.darkElixir,
                  label: loc.resourceDarkElixir,
                  value: formatter.format(battle.darkElixir),
                ),
            ],
          ),
          if (army.isNotEmpty) ...[
            const SizedBox(height: CKSpacing.sm),
            SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: army.length,
                separatorBuilder: (_, _) => const SizedBox(width: CKSpacing.xs),
                itemBuilder: (context, index) {
                  final entry = army[index];
                  final item = PlayerBattlelogArmyCatalog.resolve(entry.key);
                  return SizedBox.square(
                    dimension: 44,
                    child: CKGameItemTile(
                      key: ValueKey(
                        'battle-army-${battle.mergeKey}-${item.code}',
                      ),
                      artwork: MobileWebImage(
                        imageUrl: item.imageUrl,
                        fit: BoxFit.cover,
                      ),
                      badge: '×${entry.value}',
                      badgeDensity: CKGameItemBadgeDensity.compact,
                      badgeColor: scheme.scrim.withValues(alpha: 0.88),
                      semanticLabel: '${entry.value} ${item.name}',
                      borderColor: scheme.onSurface.withValues(alpha: 0.82),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _LootValue extends StatelessWidget {
  const _LootValue({
    required this.imageUrl,
    required this.label,
    required this.value,
  });

  final String imageUrl;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$label: $value',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          MobileWebImage(imageUrl: imageUrl, width: 18, height: 18),
          const SizedBox(width: CKSpacing.xs),
          Text(
            value,
            style: CKTypography.of(
              context,
              CKTextRole.metadata,
            ).copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
