part of '../side_tabs_pages.dart';

class _SidePageScaffold extends StatelessWidget {
  const _SidePageScaffold({
    required this.title,
    required this.subtitle,
    required this.child,
    this.bottom,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final PreferredSizeWidget? bottom;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title),
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
        bottom: bottom,
      ),
      body: child,
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class _PopularSummaryChips extends StatelessWidget {
  const _PopularSummaryChips({
    required this.playerCount,
    required this.clanCount,
    required this.warCount,
  });

  final int playerCount;
  final int clanCount;
  final int warCount;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        MetricChip(
          label: 'Players',
          value: '$playerCount',
          icon: Icons.person_rounded,
          color: colorScheme.primary,
        ),
        MetricChip(
          label: 'Clans',
          value: '$clanCount',
          icon: Icons.shield_rounded,
          color: colorScheme.secondary,
        ),
        MetricChip(
          label: 'Wars & CWL',
          value: '$warCount',
          icon: Icons.sports_martial_arts_rounded,
          color: StatColors.warStarGold,
        ),
      ],
    );
  }
}

class _PopularSection extends StatelessWidget {
  const _PopularSection({
    required this.icon,
    required this.title,
    required this.count,
    required this.children,
  });

  final IconData icon;
  final String title;
  final int count;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(2, 0, 2, 6),
          child: Row(
            children: [
              Icon(icon, size: 20, color: colorScheme.onSurfaceVariant),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                '$count',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        ...children,
      ],
    );
  }
}

class _PopularRow extends StatelessWidget {
  const _PopularRow({required this.item});

  final _PopularItem item;

  factory _PopularRow.player(_PopularItem item) => _PopularRow(item: item);
  factory _PopularRow.clan(_PopularItem item) => _PopularRow(item: item);
  factory _PopularRow.war(_PopularItem item) => _PopularRow(item: item);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final cardColor = Theme.of(context).cardTheme.color ?? colorScheme.surface;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 3),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.32),
        ),
      ),
      child: Row(
        children: [
          SizedBox.square(
            dimension: 40,
            child: MobileWebImage(imageUrl: item.imageUrl, fit: BoxFit.contain),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 1),
                Text(
                  item.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          _PopularMiniStat(
            imageUrl: item.metricImageUrl,
            icon: item.metricIcon,
            value: item.metricLabel == 'active' || item.metricLabel == 'tracked'
                ? item.metricLabel
                : _formatInt(item.displayMetric ?? item.metric),
          ),
        ],
      ),
    );
  }
}

class _PopularMiniStat extends StatelessWidget {
  const _PopularMiniStat({this.imageUrl, this.icon, required this.value});

  final String? imageUrl;
  final IconData? icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (imageUrl != null)
            MobileWebImage(imageUrl: imageUrl!, width: 18, height: 18)
          else
            Icon(icon ?? Icons.trending_up_rounded, size: 18),
          const SizedBox(width: 5),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 74),
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w800,
                height: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RankingRow extends StatelessWidget {
  const _RankingRow({required this.entry});

  final _RankingEntry entry;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final cardColor = Theme.of(context).cardTheme.color ?? colorScheme.surface;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 3),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.32),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 38,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '#${entry.rank}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
                if (entry.movement != '=') ...[
                  const SizedBox(height: 3),
                  Text(
                    entry.movement,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: entry.movement.startsWith('+')
                          ? StatColors.win
                          : StatColors.loss,
                      fontWeight: FontWeight.w800,
                      height: 1,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox.square(
            dimension: 40,
            child: MobileWebImage(
              imageUrl: entry.imageUrl,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  entry.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 1),
                Text(
                  entry.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          _PopularMiniStat(
            imageUrl: entry.metricImageUrl,
            value: _formatInt(entry.score),
          ),
        ],
      ),
    );
  }
}

class _RankingTitle extends StatelessWidget {
  const _RankingTitle({required this.type});

  final _OfficialRankingType type;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox.square(
          dimension: 48,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.32,
              ),
              shape: BoxShape.circle,
            ),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: MobileWebImage(
                imageUrl: type.iconUrl,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                type.heading,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 3),
              Text(
                'Official Clash leaderboard',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RankingControlRow extends StatelessWidget {
  const _RankingControlRow({
    required this.location,
    required this.townHall,
    required this.townHallEnabled,
    required this.onLocationChanged,
    required this.onTownHallChanged,
  });

  final _LocationOption location;
  final int townHall;
  final bool townHallEnabled;
  final ValueChanged<_LocationOption> onLocationChanged;
  final ValueChanged<int> onTownHallChanged;

  @override
  Widget build(BuildContext context) {
    final locationPanel = _DropdownPanel<_LocationOption>(
      icon: Icons.public_rounded,
      value: location,
      values: _locations,
      labelBuilder: (value) => value.name,
      onChanged: onLocationChanged,
    );
    final townHallPanel = _DropdownPanel<int>(
      icon: Icons.home_work_outlined,
      value: townHallEnabled ? townHall : 0,
      values: townHallEnabled ? _townHallFilters : const [0],
      labelBuilder: (value) => value == 0 ? 'All town halls' : 'TH$value',
      onChanged: townHallEnabled ? onTownHallChanged : (_) {},
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 430) {
          return Column(
            children: [
              locationPanel,
              const SizedBox(height: 10),
              townHallPanel,
            ],
          );
        }
        return Row(
          children: [
            Expanded(child: locationPanel),
            const SizedBox(width: 10),
            Expanded(child: townHallPanel),
          ],
        );
      },
    );
  }
}

class _DropdownPanel<T> extends StatelessWidget {
  const _DropdownPanel({
    required this.icon,
    required this.value,
    required this.values,
    required this.labelBuilder,
    required this.onChanged,
  });

  final IconData icon;
  final T value;
  final List<T> values;
  final String Function(T value) labelBuilder;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<T>(
            value: value,
            isExpanded: true,
            icon: const Icon(Icons.keyboard_arrow_down_rounded),
            items: values
                .map(
                  (entry) => DropdownMenuItem<T>(
                    value: entry,
                    child: Row(
                      children: [
                        Icon(icon, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            labelBuilder(entry),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
            onChanged: (next) {
              if (next != null) onChanged(next);
            },
          ),
        ),
      ),
    );
  }
}

class _LeaderboardMeta extends StatelessWidget {
  const _LeaderboardMeta({
    required this.count,
    required this.type,
    required this.location,
    required this.townHall,
    required this.onRefresh,
  });

  final int count;
  final _OfficialRankingType type;
  final _LocationOption location;
  final int townHall;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              MetricChip(
                label: type.label,
                value: 'Top ${math.min(count, 200)}',
                imageUrl: type.iconUrl,
              ),
              MetricChip(
                label: 'Location',
                value: location.name,
                icon: Icons.public_rounded,
              ),
              MetricChip(
                label: 'Filter',
                value: townHall > 0 ? 'TH$townHall' : 'All TH',
                icon: Icons.home_work_outlined,
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          tooltip: 'Refresh',
          onPressed: onRefresh,
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
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

class _HorizontalSelector<T> extends StatelessWidget {
  const _HorizontalSelector({
    required this.values,
    required this.selected,
    required this.labelBuilder,
    required this.onSelected,
  });

  final List<T> values;
  final T selected;
  final String Function(T value) labelBuilder;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: values.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final value = values[index];
          final isSelected = value == selected;
          return ChoiceChip(
            label: Text(labelBuilder(value)),
            selected: isSelected,
            onSelected: (_) => onSelected(value),
            showCheckmark: false,
            selectedColor: colorScheme.primaryContainer,
            labelStyle: TextStyle(
              color: isSelected
                  ? colorScheme.onPrimaryContainer
                  : colorScheme.onSurface,
              fontWeight: FontWeight.w700,
            ),
          );
        },
      ),
    );
  }
}

class _EndpointPreview extends StatelessWidget {
  const _EndpointPreview({required this.option});

  final _EndpointOption option;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final cardColor = Theme.of(context).cardTheme.color ?? colorScheme.surface;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 3),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.32),
        ),
      ),
      child: Row(
        children: [
          SizedBox.square(
            dimension: 40,
            child: MobileWebImage(
              imageUrl: option.iconUrl,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  option.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 1),
                Text(
                  option.preview,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          _PopularMiniStat(icon: option.stateIcon, value: option.state),
        ],
      ),
    );
  }
}

class _EndpointMockupSummary extends StatelessWidget {
  const _EndpointMockupSummary();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: const [
        MetricChip(
          label: 'Source',
          value: 'ClashKing',
          icon: Icons.query_stats_rounded,
        ),
        MetricChip(
          label: 'Mode',
          value: 'Preview',
          icon: Icons.visibility_rounded,
        ),
        MetricChip(
          label: 'Rows',
          value: '5 mockups',
          icon: Icons.view_list_rounded,
        ),
      ],
    );
  }
}

class _MetricPanel extends StatelessWidget {
  const _MetricPanel({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
          ],
        ),
      ),
    );
  }
}

class _CalculatorResult extends StatelessWidget {
  const _CalculatorResult({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onPrimaryContainer.withValues(alpha: 0.78),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NumberRow extends StatelessWidget {
  const _NumberRow({
    required this.label,
    required this.owned,
    required this.target,
    required this.daily,
    required this.onOwnedChanged,
    required this.onTargetChanged,
  });

  final String label;
  final int owned;
  final int target;
  final int daily;
  final ValueChanged<int> onOwnedChanged;
  final ValueChanged<int> onTargetChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              Text('daily ${_formatInt(daily)}'),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _SmallNumberField(
                  label: 'Owned',
                  value: owned,
                  onChanged: onOwnedChanged,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SmallNumberField(
                  label: 'Target',
                  value: target,
                  onChanged: onTargetChanged,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SmallNumberField extends StatelessWidget {
  const _SmallNumberField({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: value.toString(),
      keyboardType: TextInputType.number,
      decoration: InputDecoration(labelText: label),
      onChanged: (raw) => onChanged(int.tryParse(raw) ?? 0),
    );
  }
}

class _CompactStepper extends StatelessWidget {
  const _CompactStepper({
    required this.label,
    required this.value,
    required this.onChanged,
    this.step = 1,
    this.min = 0,
  });

  final String label;
  final int value;
  final int step;
  final int min;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          IconButton(
            tooltip: 'Decrease',
            onPressed: value <= min
                ? null
                : () => onChanged(math.max(min, value - step)),
            icon: const Icon(Icons.remove_circle_outline_rounded),
          ),
          SizedBox(
            width: 72,
            child: Text(
              _formatInt(value),
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
          IconButton(
            tooltip: 'Increase',
            onPressed: () => onChanged(value + step),
            icon: const Icon(Icons.add_circle_outline_rounded),
          ),
        ],
      ),
    );
  }
}

class _LevelSelector extends StatelessWidget {
  const _LevelSelector({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  final String label;
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          DropdownButton<int>(
            value: value,
            items: [
              for (var level = min; level <= max; level++)
                DropdownMenuItem(value: level, child: Text('Level $level')),
            ],
            onChanged: (next) {
              if (next != null) onChanged(next);
            },
          ),
        ],
      ),
    );
  }
}

class _AssetTile extends StatelessWidget {
  const _AssetTile({required this.entry});

  final _AssetEntry entry;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.34),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Center(
                child: MobileWebImage(imageUrl: entry.url, fit: BoxFit.contain),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              entry.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            Text(
              entry.folder,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 36),
      child: Column(
        children: [
          Icon(icon, size: 42, color: colorScheme.onSurfaceVariant),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorPanel extends StatelessWidget {
  const _ErrorPanel({
    required this.message,
    required this.detail,
    required this.onRetry,
  });

  final String message;
  final String detail;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.errorContainer.withValues(alpha: 0.46),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: colorScheme.onErrorContainer,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              detail,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onErrorContainer.withValues(alpha: 0.75),
              ),
            ),
            const SizedBox(height: 10),
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingRows extends StatelessWidget {
  const _LoadingRows();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        8,
        (index) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: LinearProgressIndicator(
            minHeight: 6,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
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

class _PopularItem {
  const _PopularItem({
    required this.title,
    required this.subtitle,
    required this.metric,
    required this.metricLabel,
    required this.imageUrl,
    this.displayMetric,
    this.metricImageUrl,
    this.metricIcon,
  });

  final String title;
  final String subtitle;
  final int metric;
  final String metricLabel;
  final String imageUrl;
  final int? displayMetric;
  final String? metricImageUrl;
  final IconData? metricIcon;
}

class _RankingEntry {
  const _RankingEntry({
    required this.rank,
    required this.previousRank,
    required this.name,
    required this.subtitle,
    required this.score,
    required this.imageUrl,
    required this.metricImageUrl,
    required this.townHallLevel,
  });

  final int rank;
  final int previousRank;
  final String name;
  final String subtitle;
  final int score;
  final String imageUrl;
  final String metricImageUrl;
  final int townHallLevel;

  String get movement {
    if (previousRank <= 0 || rank <= 0) return '=';
    final delta = previousRank - rank;
    if (delta == 0) return '=';
    return delta > 0 ? '+$delta' : '$delta';
  }

  factory _RankingEntry.fromJson(
    Map<String, dynamic> json,
    _OfficialRankingType type,
  ) {
    final isClan = type.isClan;
    final badgeUrls = json['badgeUrls'];
    final league = json['league'];
    final leagueUrl =
        _nestedString(league, 'iconUrls.small') ??
        _nestedString(league, 'iconUrls.medium');
    final imageUrl = isClan
        ? _nestedString(badgeUrls, 'medium') ?? ImageAssets.clanCastle
        : ImageAssets.townHall(_asInt(json['townHallLevel'], fallback: 1));
    final metricImageUrl = isClan ? type.iconUrl : leagueUrl ?? type.iconUrl;
    final score = type.scoreKey
        .map((key) => _asInt(json[key]))
        .firstWhere((value) => value > 0, orElse: () => 0);
    final tag = json['tag']?.toString() ?? '';
    final clanName =
        _nestedString(json['clan'], 'name') ??
        json['clanName']?.toString() ??
        '';
    final subtitle = clanName.isEmpty ? tag : '$clanName · $tag';
    return _RankingEntry(
      rank: _asInt(json['rank']),
      previousRank: _asInt(json['previousRank']),
      name: json['name']?.toString() ?? tag,
      subtitle: subtitle,
      score: score,
      imageUrl: imageUrl,
      metricImageUrl: metricImageUrl,
      townHallLevel: _asInt(json['townHallLevel']),
    );
  }
}

class _LocationOption {
  const _LocationOption(this.id, this.name);

  final int id;
  final String name;
}

enum _OfficialRankingType {
  playerTrophies(
    label: 'Player trophies',
    heading: 'Players Trophies Ranking',
    path: 'players',
    isClan: false,
    scoreKey: ['trophies'],
    iconUrl: ImageAssets.trophies,
    supportsTownHallFilter: true,
  ),
  playerBuilder(
    label: 'Player builder',
    heading: 'Players Builder Base Ranking',
    path: 'players-builder-base',
    isClan: false,
    scoreKey: ['builderBaseTrophies', 'trophies'],
    iconUrl: ImageAssets.builderBaseStar,
    supportsTownHallFilter: false,
  ),
  clanTrophies(
    label: 'Clan trophies',
    heading: 'Clans Trophies Ranking',
    path: 'clans',
    isClan: true,
    scoreKey: ['clanPoints', 'clanPoints'],
    iconUrl: ImageAssets.trophies,
    supportsTownHallFilter: false,
  ),
  clanBuilder(
    label: 'Clan builder',
    heading: 'Clans Builder Base Ranking',
    path: 'clans-builder-base',
    isClan: true,
    scoreKey: ['clanBuilderBasePoints', 'clanPoints'],
    iconUrl: ImageAssets.builderBaseStar,
    supportsTownHallFilter: false,
  ),
  clanCapital(
    label: 'Clan capital',
    heading: 'Clan Capital Ranking',
    path: 'capitals',
    isClan: true,
    scoreKey: ['clanCapitalPoints', 'capitalPoints'],
    iconUrl: ImageAssets.capitalTrophy,
    supportsTownHallFilter: false,
  );

  const _OfficialRankingType({
    required this.label,
    required this.heading,
    required this.path,
    required this.isClan,
    required this.scoreKey,
    required this.iconUrl,
    required this.supportsTownHallFilter,
  });

  final String label;
  final String heading;
  final String path;
  final bool isClan;
  final List<String> scoreKey;
  final String iconUrl;
  final bool supportsTownHallFilter;
}

class _EndpointOption {
  const _EndpointOption({
    required this.title,
    required this.preview,
    required this.iconUrl,
    required this.state,
    required this.stateIcon,
  });

  final String title;
  final String preview;
  final String iconUrl;
  final String state;
  final IconData stateIcon;
}

class _OreBonus {
  const _OreBonus(this.shiny, this.glowy, this.starry);

  final int shiny;
  final int glowy;
  final int starry;

  static _OreBonus forLeague(String league) {
    final normalized = league.toLowerCase();
    if (normalized.contains('legend')) return const _OreBonus(1000, 54, 6);
    if (normalized.contains('titan')) return const _OreBonus(925, 50, 5);
    if (normalized.contains('champion')) return const _OreBonus(810, 46, 4);
    if (normalized.contains('master')) return const _OreBonus(700, 38, 3);
    if (normalized.contains('crystal')) return const _OreBonus(560, 30, 2);
    if (normalized.contains('gold')) return const _OreBonus(420, 24, 1);
    if (normalized.contains('silver')) return const _OreBonus(320, 14, 0);
    return const _OreBonus(220, 10, 0);
  }
}

class _AssetEntry {
  const _AssetEntry({
    required this.name,
    required this.folder,
    required this.url,
  });

  final String name;
  final String folder;
  final String url;
}

const _locations = [
  _LocationOption(32000000, 'Worldwide'),
  _LocationOption(32000006, 'United States'),
  _LocationOption(32000249, 'International'),
];

const _townHallFilters = [0, 17, 16, 15, 14, 13, 12, 11, 10, 9];

final _clashKingLeaderboardOptions = [
  _EndpointOption(
    title: 'League top 200',
    preview: 'Legend League · 5,742 trophies',
    iconUrl: ImageAssets.legendBlazon,
    state: 'Top 200',
    stateIcon: Icons.emoji_events_rounded,
  ),
  _EndpointOption(
    title: 'Townhall top 200',
    preview: 'TH17 · Global player board',
    iconUrl: ImageAssets.townHall(17),
    state: 'TH17',
    stateIcon: Icons.home_work_outlined,
  ),
  _EndpointOption(
    title: 'Clan donations',
    preview: 'United States · weekly clan totals',
    iconUrl: ImageAssets.clanGamesMedals,
    state: 'Weekly',
    stateIcon: Icons.volunteer_activism_rounded,
  ),
  _EndpointOption(
    title: 'Clan war wins',
    preview: 'International · all-time war wins',
    iconUrl: ImageAssets.war,
    state: 'Wins',
    stateIcon: Icons.military_tech_rounded,
  ),
  _EndpointOption(
    title: 'Top 200 army usage',
    preview: 'Battle logs · troop and spell usage',
    iconUrl: ImageAssets.sword,
    state: 'Usage',
    stateIcon: Icons.analytics_rounded,
  ),
];

const _assetFolders = [
  'troops',
  'spells',
  'heroes',
  'equipment',
  'leagues',
  'resources',
  'stickers',
];

const _staticAssetCatalog = [
  _AssetEntry(name: 'Villager', folder: 'stickers', url: ImageAssets.villager),
  _AssetEntry(
    name: 'Builder',
    folder: 'stickers',
    url: ImageAssets.builderWave,
  ),
  _AssetEntry(name: 'Goblin', folder: 'stickers', url: ImageAssets.goblin),
  _AssetEntry(
    name: 'Thinking Barbarian King',
    folder: 'stickers',
    url: ImageAssets.thinkingBarbarianKing,
  ),
  _AssetEntry(
    name: 'Legend League',
    folder: 'leagues',
    url: ImageAssets.legendBlazon,
  ),
  _AssetEntry(name: 'Clan War', folder: 'resources', url: ImageAssets.warClan),
  _AssetEntry(name: 'Trophy', folder: 'resources', url: ImageAssets.trophies),
  _AssetEntry(
    name: 'Capital Trophy',
    folder: 'resources',
    url: ImageAssets.capitalTrophy,
  ),
];

const _lightningDamage = {
  1: 150,
  2: 180,
  3: 210,
  4: 240,
  5: 270,
  6: 320,
  7: 400,
  8: 480,
  9: 560,
  10: 600,
  11: 640,
  12: 680,
};

const _quakePercent = {1: 14, 2: 17, 3: 21, 4: 25, 5: 29};

int _fireballDamage(int level) {
  return 900 + ((level - 1) * 65);
}

int _asInt(Object? value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

String? _nestedString(Object? raw, String path) {
  Object? current = raw;
  for (final segment in path.split('.')) {
    if (current is! Map) return null;
    current = current[segment];
  }
  return current?.toString();
}

String _formatInt(int value) {
  final raw = value.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < raw.length; i++) {
    final indexFromEnd = raw.length - i;
    buffer.write(raw[i]);
    if (indexFromEnd > 1 && indexFromEnd % 3 == 1) {
      buffer.write(',');
    }
  }
  return buffer.toString();
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

String _assetFolderLabel(String folder) {
  return folder
      .split('-')
      .map(
        (word) => word.isEmpty
            ? word
            : '${word[0].toUpperCase()}${word.substring(1)}',
      )
      .join(' ');
}
