import 'package:clashkingapp/features/player/presentation/player/player_super_troop_section.dart';
import 'package:clashkingapp/common/widgets/mobile_web_image.dart';
import 'package:clashkingapp/common/widgets/liquid_glass.dart';
import 'package:clashkingapp/core/constants/image_assets.dart';
import 'package:flutter/material.dart';
import 'package:clashkingapp/features/player/models/player.dart';
import 'package:clashkingapp/features/player/models/player_achievement.dart';
import 'package:clashkingapp/features/player/presentation/player/player_header.dart';
import 'package:clashkingapp/features/player/presentation/player/player_item_section.dart';
import 'package:clashkingapp/features/player/presentation/war_stats/player_war_stats_profile_tab.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

class PlayerScreen extends StatefulWidget {
  final Player selectedPlayer;
  final int initialTab;

  const PlayerScreen({
    super.key,
    required this.selectedPlayer,
    this.initialTab = 0,
  });

  @override
  PlayerScreenState createState() => PlayerScreenState();
}

class PlayerScreenState extends State<PlayerScreen> {
  late int selectedTab = widget.initialTab;

  @override
  Widget build(BuildContext context) {
    final bottomPadding = 16 + MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onHorizontalDragEnd: _handleTabSwipe,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: PlayerInfoHeader(
                selectedTab: selectedTab,
                player: widget.selectedPlayer,
              ),
            ),
            SliverToBoxAdapter(
              child: _PlayerProfileTabs(
                player: widget.selectedPlayer,
                selectedIndex: selectedTab,
                onTabSelected: _selectTab,
              ),
            ),
            ...switch (selectedTab) {
              0 => _buildPlayerSlivers(widget.selectedPlayer),
              1 => _buildBuilderSlivers(widget.selectedPlayer),
              2 => [
                SliverToBoxAdapter(
                  child: PlayerWarStatsProfileTab(
                    player: widget.selectedPlayer,
                  ),
                ),
              ],
              _ => [
                SliverToBoxAdapter(
                  child: _buildAchievementContent(widget.selectedPlayer),
                ),
              ],
            },
            SliverToBoxAdapter(child: SizedBox(height: bottomPadding)),
          ],
        ),
      ),
    );
  }

  void _selectTab(int index) {
    final clampedIndex = index > 3 ? 3 : index;
    final boundedIndex = index < 0 ? 0 : clampedIndex;
    if (boundedIndex == selectedTab) return;
    setState(() => selectedTab = boundedIndex);
  }

  void _handleTabSwipe(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    if (velocity.abs() < 240) return;
    if (velocity < 0) {
      _selectTab(selectedTab + 1);
    } else {
      _selectTab(selectedTab - 1);
    }
  }

  List<Widget> _buildPlayerSlivers(Player player) {
    final loc = AppLocalizations.of(context)!;
    final builders = <Widget Function()>[
      () => const SizedBox(height: 10),
      () => PlayerSuperTroopSection(superTroops: player.superTroops),
      () => PlayerItemSection(
        title: loc.gameHeroes,
        items: player.heroes,
        townHallLevel: player.townHallLevel,
        initiallyExpanded: true,
      ),
      () => PlayerItemSection(
        title: loc.gameEquipment,
        items: player.equipments,
        townHallLevel: player.townHallLevel,
        initiallyExpanded: true,
      ),
      () => PlayerItemSection(
        title: loc.gameTroops,
        items: player.troops,
        townHallLevel: player.townHallLevel,
      ),
      () => PlayerItemSection(
        title: loc.gameSpells,
        items: player.spells,
        townHallLevel: player.townHallLevel,
      ),
      () => PlayerItemSection(
        title: loc.gameSiegeMachines,
        items: player.siegeMachines,
        townHallLevel: player.townHallLevel,
      ),
      () => PlayerItemSection(
        title: loc.gamePets,
        items: player.pets,
        townHallLevel: player.townHallLevel,
      ),
      () => const SizedBox(height: 10),
    ];
    return [
      SliverList.builder(
        itemCount: builders.length,
        itemBuilder: (_, index) => builders[index](),
      ),
    ];
  }

  List<Widget> _buildBuilderSlivers(Player player) {
    final loc = AppLocalizations.of(context)!;
    final builders = <Widget Function()>[
      () => const SizedBox(height: 10),
      () => PlayerItemSection(
        title: loc.gameHeroes,
        items: player.bbHeroes,
        townHallLevel: player.builderHallLevel,
        initiallyExpanded: true,
      ),
      () => PlayerItemSection(
        title: loc.gameTroops,
        items: player.bbTroops,
        townHallLevel: player.builderHallLevel,
      ),
      () => const SizedBox(height: 10),
    ];
    return [
      SliverList.builder(
        itemCount: builders.length,
        itemBuilder: (_, index) => builders[index](),
      ),
    ];
  }

  Widget _buildAchievementContent(Player player) {
    return _AchievementsTab(player: player);
  }
}

class _AchievementsTab extends StatefulWidget {
  final Player player;

  const _AchievementsTab({required this.player});

  @override
  State<_AchievementsTab> createState() => _AchievementsTabState();
}

class _AchievementsTabState extends State<_AchievementsTab> {
  int _group = 0;

  @override
  Widget build(BuildContext context) {
    final achievements = widget.player.achievements
        .where((achievement) => achievement.name != 'Keep Your Account Safe!')
        .toList();
    final home = achievements
        .where((achievement) => achievement.village == 'home')
        .toList();
    final others = achievements
        .where(
          (achievement) =>
              achievement.village == 'builderBase' ||
              achievement.village == 'clanCapital',
        )
        .toList();
    final isHome = _group == 0;
    final homeDone = home.where(_isAchievementComplete).length;
    final othersDone = others.where(_isAchievementComplete).length;
    final homeLabel = AppLocalizations.of(context)?.gameBaseHome ?? 'Home Base';
    final othersLabel = AppLocalizations.of(context)?.generalOthers ?? 'Others';

    return Column(
      children: [
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: LiquidGlassSegmentedControl<int>(
            values: const [0, 1],
            labels: [
              '$homeLabel · $homeDone/${home.length}',
              '$othersLabel · $othersDone/${others.length}',
            ],
            selected: _group,
            onChanged: (value) => setState(() => _group = value),
            height: 44,
          ),
        ),
        const SizedBox(height: 6),
        _AchievementSection(
          key: ValueKey(isHome),
          title: isHome ? homeLabel : othersLabel,
          imageUrl: isHome
              ? ImageAssets.townHall(widget.player.townHallLevel)
              : ImageAssets.builderHall(widget.player.builderHallLevel),
          achievements: isHome ? home : others,
          initiallyExpanded: true,
          collapsible: false,
          showHeader: false,
        ),
        const SizedBox(height: 10),
      ],
    );
  }
}

class _PlayerProfileTabs extends StatefulWidget {
  final Player player;
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;

  const _PlayerProfileTabs({
    required this.player,
    required this.selectedIndex,
    required this.onTabSelected,
  });

  @override
  State<_PlayerProfileTabs> createState() => _PlayerProfileTabsState();
}

class _PlayerProfileTabsState extends State<_PlayerProfileTabs>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 4,
      vsync: this,
      initialIndex: widget.selectedIndex,
    );
  }

  @override
  void didUpdateWidget(covariant _PlayerProfileTabs oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedIndex != widget.selectedIndex &&
        _tabController.index != widget.selectedIndex) {
      _tabController.animateTo(
        widget.selectedIndex,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(color: colorScheme.surface),
      child: SizedBox(
        height: 50,
        child: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          labelPadding: const EdgeInsets.symmetric(horizontal: 10),
          labelColor: colorScheme.onSurface,
          unselectedLabelColor: colorScheme.onSurface,
          indicatorColor: colorScheme.primary,
          indicatorWeight: 2.5,
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: colorScheme.outlineVariant.withValues(alpha: 0.35),
          splashFactory: NoSplash.splashFactory,
          overlayColor: WidgetStateProperty.all(Colors.transparent),
          onTap: widget.onTabSelected,
          tabs: [
            _ProfileTab(
              label: AppLocalizations.of(context)?.gameBaseHome ?? 'Home Base',
              imageUrl: ImageAssets.townHall(widget.player.townHallLevel),
              selected: widget.selectedIndex == 0,
            ),
            _ProfileTab(
              label:
                  AppLocalizations.of(context)?.gameBaseBuilder ??
                  'Builder Base',
              imageUrl: ImageAssets.builderHall(widget.player.builderHallLevel),
              selected: widget.selectedIndex == 1,
            ),
            _ProfileTab(
              label: AppLocalizations.of(context)?.warStats ?? 'War Stats',
              imageUrl: ImageAssets.war,
              selected: widget.selectedIndex == 2,
            ),
            _ProfileTab(
              label:
                  AppLocalizations.of(context)?.gameAchievements ??
                  'Achievements',
              imageUrl: ImageAssets.attackStar,
              selected: widget.selectedIndex == 3,
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileTab extends StatelessWidget {
  final String label;
  final String imageUrl;
  final bool selected;

  const _ProfileTab({
    required this.label,
    required this.imageUrl,
    required this.selected,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final foreground = selected
        ? colorScheme.onSurface
        : colorScheme.onSurface.withValues(alpha: 0.68);

    return Tab(
      height: 48,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          MobileWebImage(imageUrl: imageUrl, width: 18, height: 18),
          const SizedBox(width: 5),
          Text(
            label,
            maxLines: 1,
            softWrap: false,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: foreground,
              fontSize: 13,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _AchievementSection extends StatefulWidget {
  final String title;
  final String imageUrl;
  final List<PlayerAchievement> achievements;
  final bool initiallyExpanded;
  final bool collapsible;
  final bool showHeader;

  const _AchievementSection({
    super.key,
    required this.title,
    required this.imageUrl,
    required this.achievements,
    this.initiallyExpanded = false,
    this.collapsible = true,
    this.showHeader = true,
  });

  @override
  State<_AchievementSection> createState() => _AchievementSectionState();
}

class _AchievementSectionState extends State<_AchievementSection> {
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.achievements.isEmpty) return const SizedBox.shrink();

    const gold = Color(0xFFFFD75E);
    final colorScheme = Theme.of(context).colorScheme;
    final completed = widget.achievements.where(_isAchievementComplete).length;
    final total = widget.achievements.length;
    final ratio = completed / total;
    final allComplete = completed >= total;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? colorScheme.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.32),
        ),
      ),
      child: Column(
        children: [
          if (widget.showHeader)
            InkWell(
              borderRadius: BorderRadius.circular(28),
              onTap: widget.collapsible
                  ? () => setState(() => _expanded = !_expanded)
                  : null,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    if (widget.collapsible) ...[
                      AnimatedRotation(
                        turns: _expanded ? 0.25 : 0,
                        duration: const Duration(milliseconds: 160),
                        child: Icon(
                          Icons.chevron_right_rounded,
                          size: 22,
                          color: colorScheme.onSurface.withValues(alpha: 0.72),
                        ),
                      ),
                      const SizedBox(width: 4),
                    ],
                    MobileWebImage(
                      imageUrl: widget.imageUrl,
                      width: 26,
                      height: 26,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.title,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ),
                    // Ring badge, same language as the item section % badge.
                    Container(
                      padding: const EdgeInsets.fromLTRB(8, 5, 10, 5),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        color: allComplete
                            ? gold.withValues(alpha: 0.14)
                            : colorScheme.surfaceContainerHighest.withValues(
                                alpha: 0.55,
                              ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox.square(
                            dimension: 15,
                            child: allComplete
                                ? const Icon(
                                    Icons.check_circle_rounded,
                                    size: 15,
                                    color: gold,
                                  )
                                : CircularProgressIndicator(
                                    value: ratio,
                                    strokeWidth: 2.4,
                                    strokeCap: StrokeCap.round,
                                    backgroundColor: colorScheme.outlineVariant
                                        .withValues(alpha: 0.45),
                                    valueColor: AlwaysStoppedAnimation(
                                      colorScheme.primary,
                                    ),
                                  ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '$completed/$total',
                            style: Theme.of(context).textTheme.labelMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  color: allComplete
                                      ? gold
                                      : colorScheme.onSurface,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (_expanded) ...[
            if (widget.showHeader) const SizedBox(height: 12),
            // Pending achievements first, completed ones at the bottom.
            ...widget.achievements
                .where((a) => !_isAchievementComplete(a))
                .map(
                  (achievement) => _AchievementTile(achievement: achievement),
                ),
            ...widget.achievements
                .where(_isAchievementComplete)
                .map(
                  (achievement) => _AchievementTile(achievement: achievement),
                ),
          ],
        ],
      ),
    );
  }
}

bool _isAchievementComplete(PlayerAchievement achievement) {
  if ((achievement.name == 'Dragon Slayer' ||
          achievement.name == 'Ungrateful Child') &&
      achievement.value >= 1) {
    return true;
  }
  return achievement.value >= achievement.target && achievement.stars == 3;
}

class _AchievementTile extends StatelessWidget {
  final PlayerAchievement achievement;

  const _AchievementTile({required this.achievement});

  @override
  Widget build(BuildContext context) {
    final ratio = achievement.target <= 0
        ? 0.0
        : (achievement.value / achievement.target).clamp(0.0, 1.0);
    final complete = ratio >= 1.0;
    final progress = _formatAchievementProgress(context);

    const gold = Color(0xFFFFD75E);
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: complete
            ? gold.withValues(alpha: 0.08)
            : colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(14),
        border: complete
            ? Border.all(color: gold.withValues(alpha: 0.5))
            : null,
      ),
      child: Row(
        children: [
          // Leading badge: gold trophy once done, muted star otherwise.
          DecoratedBox(
            decoration: BoxDecoration(
              color: complete
                  ? gold.withValues(alpha: 0.16)
                  : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              shape: BoxShape.circle,
            ),
            child: SizedBox.square(
              dimension: 36,
              child: Icon(
                complete ? Icons.emoji_events_rounded : Icons.star_rounded,
                size: 19,
                color: complete ? gold : colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        achievement.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _AchievementStars(stars: _effectiveStars),
                  ],
                ),
                if (achievement.info.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    achievement.info.replaceAll(RegExp('000000 '), 'M '),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.62),
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: ratio,
                          minHeight: 6,
                          backgroundColor: colorScheme.surfaceContainerHighest,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            complete ? gold : colorScheme.primary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest.withValues(
                          alpha: 0.55,
                        ),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        progress,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: complete ? gold : colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  int get _effectiveStars {
    if ((achievement.name == 'Dragon Slayer' ||
            achievement.name == 'Ungrateful Child') &&
        achievement.value >= 1) {
      return 3;
    }
    return achievement.stars;
  }

  String _formatAchievementProgress(BuildContext context) {
    final formatter = NumberFormat.compact(
      locale: Localizations.localeOf(context).toString(),
    );
    return '${formatter.format(achievement.value)} / ${formatter.format(achievement.target)}';
  }
}

class _AchievementStars extends StatelessWidget {
  final int stars;

  const _AchievementStars({required this.stars});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        final filled = index < stars;
        return Icon(
          Icons.star_rounded,
          size: 15,
          color: filled
              ? const Color(0xFFFFD75E)
              : Theme.of(context).colorScheme.outlineVariant,
        );
      }),
    );
  }
}
