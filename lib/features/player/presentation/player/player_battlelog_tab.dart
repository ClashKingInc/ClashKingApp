import 'dart:math' as math;

import 'package:clashking_design_system/clashking_design_system.dart';
import 'package:clashkingapp/common/theme/app_tokens.dart';
import 'package:clashkingapp/common/widgets/empty_state.dart';
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

class _PlayerBattlelogTabState extends State<PlayerBattlelogTab> {
  PlayerBattlelogMode _mode = PlayerBattlelogMode.ranked;
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
                    onModeChanged: (mode) => setState(() => _mode = mode),
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
    required this.onModeChanged,
  });

  final PlayerBattlelogData data;
  final PlayerBattlelogMode mode;
  final ValueChanged<PlayerBattlelogMode> onModeChanged;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final battles = data.forMode(mode);
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
        _BattleSummary(data: data, mode: mode, battles: battles),
        const SizedBox(height: CKSpacing.lg),
        Text(
          loc.playerBattlelogRecentBattles,
          style: CKTypography.of(context, CKTextRole.sectionTitle),
        ),
        const SizedBox(height: CKSpacing.sm),
        if (battles.isEmpty)
          AppEmptyState(
            icon: Icons.history_toggle_off_rounded,
            title: loc.playerBattlelogNoBattlesTitle,
            body: loc.playerBattlelogNoBattlesBody,
            padding: EdgeInsets.zero,
          )
        else
          ResponsiveCardGrid(
            itemCount: battles.length,
            minItemWidth: 430,
            maxColumns: 2,
            spacing: CKSpacing.md,
            itemBuilder: (_, index) => _BattleRow(battle: battles[index]),
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
    required this.data,
    required this.mode,
    required this.battles,
  });

  final PlayerBattlelogData data;
  final PlayerBattlelogMode mode;
  final List<PlayerBattlelogEntry> battles;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final attacks = battles.where((battle) => battle.attack).toList();
    final averageDestruction = _average(
      attacks.map((battle) => battle.destructionPercentage),
    );
    final averageStars = _average(attacks.map((battle) => battle.stars));
    final tripleRate = attacks.isEmpty
        ? 0.0
        : attacks.where((battle) => battle.stars == 3).length / attacks.length;
    final averageLoot = _average(attacks.map((battle) => battle.totalLoot));
    final popular = data.popularTroops(mode);
    final formatter = NumberFormat.compact(
      locale: Localizations.localeOf(context).toString(),
    );
    final metrics = mode == PlayerBattlelogMode.farming
        ? <(String, String, String)>[
            (
              ImageAssets.attacksNoShield,
              loc.playerBattlelogAttacks,
              '${attacks.length}',
            ),
            (
              ImageAssets.hitrate,
              loc.playerBattlelogAverageDestruction,
              '${averageDestruction.toStringAsFixed(1)}%',
            ),
            (
              ImageAssets.lootCart,
              loc.playerBattlelogAverageLoot,
              formatter.format(averageLoot.round()),
            ),
          ]
        : <(String, String, String)>[
            (
              ImageAssets.attacksNoShield,
              loc.playerBattlelogAttacks,
              '${attacks.length}',
            ),
            (
              ImageAssets.attackStar,
              loc.playerBattlelogAverageStars,
              averageStars.toStringAsFixed(2),
            ),
            (
              ImageAssets.hitrate,
              loc.playerBattlelogAverageDestruction,
              '${averageDestruction.toStringAsFixed(1)}%',
            ),
            (
              ImageAssets.attackStar,
              loc.playerBattlelogTripleRate,
              '${(tripleRate * 100).toStringAsFixed(1)}%',
            ),
          ];

    return CKSectionPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              MobileWebImage(
                imageUrl: mode == PlayerBattlelogMode.farming
                    ? ImageAssets.farmingLabel
                    : ImageAssets.competitiveLabel,
                width: 52,
                height: 52,
              ),
              const SizedBox(width: CKSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mode == PlayerBattlelogMode.farming
                          ? loc.playerBattlelogFarmingOverview
                          : loc.playerBattlelogRankedOverview,
                      style: CKTypography.of(context, CKTextRole.sectionTitle),
                    ),
                    const SizedBox(height: CKSpacing.xs),
                    Text(
                      loc.playerBattlelogBattleCount(battles.length),
                      style: CKTypography.of(context, CKTextRole.metadata)
                          .copyWith(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: CKSpacing.lg),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = (constraints.maxWidth - CKSpacing.md) / 2;
              return Wrap(
                spacing: CKSpacing.md,
                runSpacing: CKSpacing.lg,
                children: [
                  for (final metric in metrics)
                    SizedBox(
                      width: width,
                      child: _SummaryMetric(
                        imageUrl: metric.$1,
                        label: metric.$2,
                        value: metric.$3,
                      ),
                    ),
                ],
              );
            },
          ),
          if (popular.isNotEmpty) ...[
            const SizedBox(height: CKSpacing.xl),
            Text(
              loc.playerBattlelogPopularTroops,
              style: CKTypography.of(context, CKTextRole.rowTitle),
            ),
            const SizedBox(height: CKSpacing.md),
            Wrap(
              spacing: CKSpacing.lg,
              runSpacing: CKSpacing.md,
              children: [
                for (final troop in popular) _PopularTroop(item: troop),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

double _average(Iterable<int> values) {
  if (values.isEmpty) return 0;
  return values.reduce((a, b) => a + b) / values.length;
}

class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric({
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
      child: Row(
        children: [
          SizedBox.square(
            dimension: 40,
            child: MobileWebImage(imageUrl: imageUrl),
          ),
          const SizedBox(width: CKSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: CKTypography.of(context, CKTextRole.rowTitle),
                ),
                Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: CKTypography.of(
                    context,
                    CKTextRole.metadata,
                  ).copyWith(color: scheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PopularTroop extends StatelessWidget {
  const _PopularTroop({required this.item});

  final PlayerPopularArmyItem item;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: 150,
      child: Row(
        children: [
          MobileWebImage(imageUrl: item.item.imageUrl, width: 42, height: 42),
          const SizedBox(width: CKSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: CKTypography.of(context, CKTextRole.rowTitle),
                ),
                Text(
                  loc.playerBattlelogUsedInAttacks(item.uses),
                  maxLines: 2,
                  style: CKTypography.of(
                    context,
                    CKTextRole.metadata,
                  ).copyWith(color: scheme.onSurfaceVariant),
                ),
              ],
            ),
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
      padding: const EdgeInsets.all(CKSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
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
                      loc.playerBattlelogOpponent(
                        battle.opponentName.isEmpty
                            ? battle.opponentTag
                            : battle.opponentName,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: CKTypography.of(context, CKTextRole.rowTitle),
                    ),
                    Text(
                      [
                        battle.attack
                            ? loc.playerBattlelogAttack
                            : loc.playerBattlelogDefense,
                        if (time.isNotEmpty) time,
                      ].join(' · '),
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
              if (battle.opponentTownHall > 0)
                MobileWebImage(
                  imageUrl: ImageAssets.townHall(battle.opponentTownHall),
                  width: 38,
                  height: 38,
                ),
            ],
          ),
          const SizedBox(height: CKSpacing.md),
          Row(
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
          if (battle.totalLoot > 0) ...[
            const SizedBox(height: CKSpacing.sm),
            Wrap(
              spacing: CKSpacing.md,
              runSpacing: CKSpacing.xs,
              children: [
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
          ],
          if (army.isNotEmpty) ...[
            const SizedBox(height: CKSpacing.md),
            SizedBox(
              height: 38,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: math.min(army.length, 6),
                separatorBuilder: (_, _) => const SizedBox(width: CKSpacing.xs),
                itemBuilder: (context, index) {
                  final entry = army[index];
                  final item = PlayerBattlelogArmyCatalog.resolve(entry.key);
                  return Semantics(
                    label: '${entry.value} ${item.name}',
                    excludeSemantics: true,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        MobileWebImage(
                          imageUrl: item.imageUrl,
                          width: 36,
                          height: 36,
                        ),
                        PositionedDirectional(
                          end: -2,
                          bottom: -1,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: scheme.inverseSurface,
                              borderRadius: BorderRadius.circular(
                                CKRadius.pill,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                              ),
                              child: Text(
                                '${entry.value}',
                                style: CKTypography.of(
                                  context,
                                  CKTextRole.compactLabel,
                                ).copyWith(color: scheme.onInverseSurface),
                              ),
                            ),
                          ),
                        ),
                      ],
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
          MobileWebImage(imageUrl: imageUrl, width: 22, height: 22),
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
