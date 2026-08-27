import 'package:clashking_design_system/clashking_design_system.dart';
import 'package:clashkingapp/common/widgets/empty_state.dart';
import 'package:clashkingapp/common/widgets/loading/skeleton_loading.dart';
import 'package:clashkingapp/common/widgets/mobile_web_image.dart';
import 'package:clashkingapp/common/widgets/responsive_card_grid.dart';
import 'package:clashkingapp/core/constants/image_assets.dart';
import 'package:clashkingapp/features/clan/data/clan_service.dart';
import 'package:clashkingapp/features/clan/models/clan_history.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class ClanLeaderboardHistoryTab extends StatefulWidget {
  const ClanLeaderboardHistoryTab({super.key, required this.clanTag});

  final String clanTag;

  @override
  State<ClanLeaderboardHistoryTab> createState() =>
      _ClanLeaderboardHistoryTabState();
}

class _ClanLeaderboardHistoryTabState extends State<ClanLeaderboardHistoryTab> {
  ClanLeaderboardType _type = ClanLeaderboardType.homeVillage;
  late Future<ClanLeaderboardHistory> _load;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  void _loadHistory() {
    _load = context.read<ClanService>().getClanLeaderboardHistory(
      widget.clanTag,
      _type,
    );
  }

  Future<void> _refresh() async {
    setState(_loadHistory);
    await _load;
  }

  void _selectType(ClanLeaderboardType type) {
    if (type == _type) return;
    setState(() {
      _type = type;
      _loadHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return _HistoryTabFrame<ClanLeaderboardHistory>(
      future: _load,
      onRefresh: _refresh,
      isEmpty: (history) => history.items.isEmpty,
      content: (context, history) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CKSegmentedControl<ClanLeaderboardType>(
            values: ClanLeaderboardType.values,
            labels: [
              loc.gameBaseHome,
              loc.gameBaseBuilder,
              loc.gameClanCapital,
            ],
            selected: _type,
            onChanged: _selectType,
            density: CKControlDensity.compact,
          ),
          const SizedBox(height: CKSpacing.md),
          ResponsiveCardGrid(
            itemCount: history.items.length,
            minItemWidth: 430,
            maxColumns: 2,
            spacing: CKSpacing.md,
            itemBuilder: (_, index) => _LeaderboardHistoryRow(
              entry: history.items[index],
              type: _type,
            ),
          ),
        ],
      ),
    );
  }
}

class ClanLegendHistoryTab extends StatefulWidget {
  const ClanLegendHistoryTab({super.key, required this.clanTag});

  final String clanTag;

  @override
  State<ClanLegendHistoryTab> createState() => _ClanLegendHistoryTabState();
}

class _ClanLegendHistoryTabState extends State<ClanLegendHistoryTab> {
  late Future<ClanLegendHistory> _load;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  void _loadHistory() {
    _load = context.read<ClanService>().getClanLegendHistory(widget.clanTag);
  }

  Future<void> _refresh() async {
    setState(_loadHistory);
    await _load;
  }

  @override
  Widget build(BuildContext context) {
    return _HistoryTabFrame<ClanLegendHistory>(
      future: _load,
      onRefresh: _refresh,
      isEmpty: (history) => history.items.isEmpty,
      content: (context, history) => ResponsiveCardGrid(
        itemCount: history.items.length,
        minItemWidth: 430,
        maxColumns: 2,
        spacing: CKSpacing.md,
        itemBuilder: (_, index) =>
            _LegendHistoryRow(entry: history.items[index]),
      ),
    );
  }
}

class ClanRecordsTab extends StatefulWidget {
  const ClanRecordsTab({super.key, required this.clanTag});

  final String clanTag;

  @override
  State<ClanRecordsTab> createState() => _ClanRecordsTabState();
}

class _ClanRecordsTabState extends State<ClanRecordsTab> {
  late Future<ClanRecords> _load;

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  void _loadRecords() {
    _load = context.read<ClanService>().getClanRecords(widget.clanTag);
  }

  Future<void> _refresh() async {
    setState(_loadRecords);
    await _load;
  }

  @override
  Widget build(BuildContext context) {
    return _HistoryTabFrame<ClanRecords>(
      future: _load,
      onRefresh: _refresh,
      isEmpty: (records) => records.isEmpty,
      content: (context, records) {
        final items = <Widget>[
          if (records.clanPoints case final record?)
            _RecordPanel(
              label: AppLocalizations.of(context)!.clanPointsTitle,
              record: record,
              imageUrl: ImageAssets.bestTrophies,
              accent: CKColors.legendBlue,
            ),
          if (records.warWinStreak case final record?)
            _RecordPanel(
              label: AppLocalizations.of(context)!.rankingsWinStreak,
              record: record,
              imageUrl: ImageAssets.war,
              accent: CKColors.warGold,
            ),
        ];
        return ResponsiveCardGrid(
          itemCount: items.length,
          minItemWidth: 360,
          maxColumns: 2,
          spacing: CKSpacing.md,
          itemBuilder: (_, index) => items[index],
        );
      },
    );
  }
}

class ClanProfileHistoryTab extends StatefulWidget {
  const ClanProfileHistoryTab({super.key, required this.clanTag});

  final String clanTag;

  @override
  State<ClanProfileHistoryTab> createState() => _ClanProfileHistoryTabState();
}

class _ClanProfileHistoryTabState extends State<ClanProfileHistoryTab> {
  late Future<ClanProfileHistory> _load;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  void _loadHistory() {
    _load = context.read<ClanService>().getClanProfileHistory(widget.clanTag);
  }

  Future<void> _refresh() async {
    setState(_loadHistory);
    await _load;
  }

  @override
  Widget build(BuildContext context) {
    return _HistoryTabFrame<ClanProfileHistory>(
      future: _load,
      onRefresh: _refresh,
      isEmpty: (history) => history.items.isEmpty,
      content: (context, history) => ResponsiveCardGrid(
        itemCount: history.items.length,
        minItemWidth: 430,
        maxColumns: 2,
        spacing: CKSpacing.md,
        itemBuilder: (_, index) =>
            _ProfileChangeRow(change: history.items[index]),
      ),
    );
  }
}

class _HistoryTabFrame<T> extends StatelessWidget {
  const _HistoryTabFrame({
    required this.future,
    required this.onRefresh,
    required this.isEmpty,
    required this.content,
  });

  final Future<T> future;
  final Future<void> Function() onRefresh;
  final bool Function(T data) isEmpty;
  final Widget Function(BuildContext context, T data) content;

  @override
  Widget build(BuildContext context) {
    final bottomPadding = 16 + MediaQuery.paddingOf(context).bottom;
    return FutureBuilder<T>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            snapshot.data == null) {
          return ListView(
            primary: true,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(16, 12, 16, bottomPadding),
            children: const [SkeletonList(itemCount: 5)],
          );
        }

        final loc = AppLocalizations.of(context)!;
        if (snapshot.hasError || snapshot.data == null) {
          return ListView(
            primary: true,
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              AppEmptyState(
                icon: Icons.cloud_off_rounded,
                title: loc.generalError,
                body: loc.generalTryAgain,
                actionLabel: loc.generalRetry,
                onAction: onRefresh,
              ),
            ],
          );
        }

        final data = snapshot.data as T;
        return RefreshIndicator(
          onRefresh: onRefresh,
          child: ListView(
            primary: true,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(16, 10, 16, bottomPadding),
            children: [
              Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1120),
                  child: isEmpty(data)
                      ? AppEmptyState(
                          icon: Icons.history_toggle_off_rounded,
                          title: loc.generalNoDataAvailable,
                          padding: EdgeInsets.zero,
                        )
                      : content(context, data),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _LeaderboardHistoryRow extends StatelessWidget {
  const _LeaderboardHistoryRow({required this.entry, required this.type});

  final ClanLeaderboardHistoryEntry entry;
  final ClanLeaderboardType type;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    final number = NumberFormat.decimalPattern(locale);
    final pointsLabel = switch (type) {
      ClanLeaderboardType.homeVillage => loc.clanPointsTitle,
      ClanLeaderboardType.builderBase => loc.clanBuilderBasePoints,
      ClanLeaderboardType.clanCapital => loc.clanCapitalPoints,
    };
    final semantics = [
      DateFormat.yMMMd(locale).format(entry.date),
      '${loc.cwlRankTitle}: ${number.format(entry.rank)}',
      '$pointsLabel: ${number.format(entry.points)}',
      '${loc.clanMembers}: ${number.format(entry.members)}',
    ].join('. ');

    return CKSectionPanel(
      child: Semantics(
        label: semantics,
        excludeSemantics: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    DateFormat.yMMMd(locale).format(entry.date),
                    style: CKTypography.of(context, CKTextRole.rowTitle),
                  ),
                ),
                _InlineMetric(
                  icon: Icons.leaderboard_rounded,
                  value: '#${number.format(entry.rank)}',
                ),
              ],
            ),
            const SizedBox(height: CKSpacing.md),
            Row(
              children: [
                Expanded(
                  child: _ImageMetric(
                    imageUrl: _pointsImage(type),
                    label: pointsLabel,
                    value: number.format(entry.points),
                  ),
                ),
                const SizedBox(width: CKSpacing.md),
                Expanded(
                  child: _IconMetric(
                    icon: Icons.groups_rounded,
                    label: loc.clanMembers,
                    value: number.format(entry.members),
                  ),
                ),
              ],
            ),
            if (entry.location?.name case final String locationName
                when locationName.isNotEmpty) ...[
              const SizedBox(height: CKSpacing.md),
              Text(
                locationName,
                style: CKTypography.of(context, CKTextRole.metadata).copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _LegendHistoryRow extends StatelessWidget {
  const _LegendHistoryRow({required this.entry});

  final ClanLegendHistoryEntry entry;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    final number = NumberFormat.decimalPattern(locale);
    return CKSectionPanel(
      child: Semantics(
        label:
            '${entry.name}, ${entry.tag}. ${loc.clanRankingsSeason}: '
            '${_seasonLabel(entry.season, locale)}. ${loc.gameTrophies}: '
            '${number.format(entry.trophies)}. ${loc.cwlRankTitle}: '
            '${number.format(entry.rank)}',
        excludeSemantics: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                SizedBox.square(
                  dimension: 42,
                  child: MobileWebImage(imageUrl: ImageAssets.legendBlazon),
                ),
                const SizedBox(width: CKSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: CKTypography.of(context, CKTextRole.rowTitle),
                      ),
                      const SizedBox(height: CKSpacing.xs),
                      Text(
                        '${entry.tag} · ${_seasonLabel(entry.season, locale)}',
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
                _InlineMetric(
                  icon: Icons.leaderboard_rounded,
                  value: '#${number.format(entry.rank)}',
                ),
              ],
            ),
            const SizedBox(height: CKSpacing.md),
            Row(
              children: [
                Expanded(
                  child: _ImageMetric(
                    imageUrl: ImageAssets.trophies,
                    label: loc.gameTrophies,
                    value: number.format(entry.trophies),
                  ),
                ),
                const SizedBox(width: CKSpacing.sm),
                Expanded(
                  child: _ImageMetric(
                    imageUrl: ImageAssets.attacks,
                    label: loc.warAttacksTitle,
                    value: number.format(entry.attackWins),
                  ),
                ),
                const SizedBox(width: CKSpacing.sm),
                Expanded(
                  child: _ImageMetric(
                    imageUrl: ImageAssets.shield,
                    label: loc.warDefensesTitle,
                    value: number.format(entry.defenseWins),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RecordPanel extends StatelessWidget {
  const _RecordPanel({
    required this.label,
    required this.record,
    required this.imageUrl,
    required this.accent,
  });

  final String label;
  final ClanRecord record;
  final String imageUrl;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    final value = NumberFormat.decimalPattern(locale).format(record.value);
    final date = DateFormat.yMMMd(
      locale,
    ).add_jm().format(record.time.toLocal());
    return CKSectionPanel(
      child: Semantics(
        label: '$label: $value. $date',
        excludeSemantics: true,
        child: Row(
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.14),
                shape: BoxShape.circle,
              ),
              child: SizedBox.square(
                dimension: 52,
                child: Padding(
                  padding: const EdgeInsets.all(CKSpacing.md),
                  child: MobileWebImage(imageUrl: imageUrl),
                ),
              ),
            ),
            const SizedBox(width: CKSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: CKTypography.of(context, CKTextRole.metadata)
                        .copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: CKSpacing.xs),
                  Text(
                    value,
                    style: CKTypography.of(context, CKTextRole.screenTitle),
                  ),
                  const SizedBox(height: CKSpacing.xs),
                  Text(
                    date,
                    style: CKTypography.of(context, CKTextRole.metadata)
                        .copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
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

class _ProfileChangeRow extends StatelessWidget {
  const _ProfileChangeRow({required this.change});

  final ClanProfileChange change;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    final title = switch (change.type) {
      ClanProfileChangeType.clanLevel => loc.clanProfileLevelChanged,
      ClanProfileChangeType.description => loc.clanProfileDescriptionChanged,
      ClanProfileChangeType.unknown => loc.clanProfileHistoryTab,
    };
    final previous = change.previous?.toString() ?? loc.generalNotSet;
    final current = change.current?.toString() ?? loc.generalNotSet;
    return CKSectionPanel(
      child: Semantics(
        label: '$title. $previous. $current',
        excludeSemantics: true,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.36),
                shape: BoxShape.circle,
              ),
              child: SizedBox.square(
                dimension: 44,
                child: Icon(
                  change.type == ClanProfileChangeType.clanLevel
                      ? Icons.upgrade_rounded
                      : Icons.notes_rounded,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(width: CKSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: CKTypography.of(context, CKTextRole.rowTitle),
                  ),
                  const SizedBox(height: CKSpacing.xs),
                  Text(
                    DateFormat.yMMMd(
                      locale,
                    ).add_jm().format(change.time.toLocal()),
                    style: CKTypography.of(context, CKTextRole.metadata)
                        .copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: CKSpacing.md),
                  Text(
                    loc.playerActivityNameChangeDetail(previous, current),
                    style: CKTypography.of(context, CKTextRole.body),
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

class _InlineMetric extends StatelessWidget {
  const _InlineMetric({required this.icon, required this.value});

  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: CKSpacing.xs),
        Text(value, style: CKTypography.of(context, CKTextRole.rowTitle)),
      ],
    );
  }
}

class _ImageMetric extends StatelessWidget {
  const _ImageMetric({
    required this.imageUrl,
    required this.label,
    required this.value,
  });

  final String imageUrl;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return _Metric(
      leading: MobileWebImage(imageUrl: imageUrl, width: 24, height: 24),
      label: label,
      value: value,
    );
  }
}

class _IconMetric extends StatelessWidget {
  const _IconMetric({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return _Metric(
      leading: Icon(
        icon,
        size: 22,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      label: label,
      value: value,
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.leading,
    required this.label,
    required this.value,
  });

  final Widget leading;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox.square(dimension: 28, child: Center(child: leading)),
        const SizedBox(width: CKSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: CKTypography.of(context, CKTextRole.compactLabel)
                    .copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: CKTypography.of(context, CKTextRole.rowTitle),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

String _pointsImage(ClanLeaderboardType type) => switch (type) {
  ClanLeaderboardType.homeVillage => ImageAssets.trophies,
  ClanLeaderboardType.builderBase => ImageAssets.builderBaseTrophy,
  ClanLeaderboardType.clanCapital => ImageAssets.capitalTrophy,
};

String _seasonLabel(String season, String locale) {
  final parsed = DateTime.tryParse(season.length == 7 ? '$season-01' : season);
  if (parsed == null) return season;
  return DateFormat.yMMMM(locale).format(parsed);
}
