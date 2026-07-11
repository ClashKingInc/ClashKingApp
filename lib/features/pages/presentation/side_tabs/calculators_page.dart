part of '../side_tabs_pages.dart';

class CalculatorsPage extends StatefulWidget {
  const CalculatorsPage({super.key});

  @override
  State<CalculatorsPage> createState() => _CalculatorsPageState();
}

class _CalculatorsPageState extends State<CalculatorsPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (mounted && _selectedTab != _tabController.index) {
        setState(() => _selectedTab = _tabController.index);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _SidePageScaffold(
      title: 'Calculators',
      subtitle: 'Ore, zap quake, and fireball quake.',
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
          child: LiquidGlassSegmentedControl<int>(
            values: const [0, 1, 2],
            labels: const ['Ore', 'Zap quake', 'Fireball'],
            selected: _selectedTab,
            height: 44,
            onChanged: (index) {
              setState(() => _selectedTab = index);
              _tabController.animateTo(index);
            },
          ),
        ),
      ),
      child: TabBarView(
        controller: _tabController,
        children: const [
          _OreCalculator(),
          _ZapQuakeCalculator(),
          _FireballQuakeCalculator(),
        ],
      ),
    );
  }
}

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
    final players = context.watch<PlayerService>().profiles;
    final selected = _selectedPlayer(players);
    final summary = selected == null ? null : _UpgradeAccountSummary(selected);

    return _SidePageScaffold(
      title: 'Upgrade Tracker',
      subtitle: selected == null
          ? 'Remaining upgrade cost and time.'
          : '${selected.name} · TH${selected.townHallLevel}',
      child: ListView(
        padding: _pagePadding,
        children: [
          if (players.isNotEmpty)
            DropdownButtonFormField<String>(
              initialValue: selected?.tag,
              decoration: const InputDecoration(labelText: 'Linked account'),
              items: players
                  .map(
                    (player) => DropdownMenuItem(
                      value: player.tag,
                      child: Text('${player.name} · TH${player.townHallLevel}'),
                    ),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _selectedTag = value),
            )
          else
            const _EmptyState(
              icon: Icons.construction_rounded,
              title: 'No linked players loaded',
              body: 'Add or refresh linked accounts to see upgrade totals.',
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

  _UpgradeAccountSummary(this.player) {
    sections = [
      _UpgradeSectionSummary(
        title: 'Heroes',
        icon: Icons.person_rounded,
        items: player.heroes,
        townHallLevel: player.townHallLevel,
      ),
      _UpgradeSectionSummary(
        title: 'Troops',
        icon: Icons.groups_rounded,
        items: player.troops,
        townHallLevel: player.townHallLevel,
      ),
      _UpgradeSectionSummary(
        title: 'Spells',
        icon: Icons.auto_fix_high_rounded,
        items: player.spells,
        townHallLevel: player.townHallLevel,
      ),
      _UpgradeSectionSummary(
        title: 'Pets',
        icon: Icons.pets_rounded,
        items: player.pets,
        townHallLevel: player.townHallLevel,
      ),
      _UpgradeSectionSummary(
        title: 'Equipment',
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
