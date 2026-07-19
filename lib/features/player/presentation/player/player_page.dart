import 'package:clashkingapp/features/player/presentation/player/player_super_troop_section.dart';
import 'package:clashkingapp/common/widgets/mobile_web_image.dart';
import 'package:clashkingapp/common/widgets/liquid_glass.dart';
import 'package:clashkingapp/common/widgets/info_profile_tabs.dart';
import 'package:clashkingapp/common/widgets/responsive_card_grid.dart';
import 'package:clashkingapp/core/constants/image_assets.dart';
import 'package:flutter/foundation.dart';
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
  static const double _desktopBreakpoint = 900;
  static const double _desktopMaxContentWidth = 1320;

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
              child: InfoProfileTabs(
                selectedIndex: selectedTab,
                onTabSelected: _selectTab,
                tabs: [
                  InfoProfileTabData(
                    label:
                        AppLocalizations.of(context)?.gameBaseHome ??
                        'Home Base',
                    imageUrl: ImageAssets.townHall(
                      widget.selectedPlayer.townHallLevel,
                    ),
                  ),
                  InfoProfileTabData(
                    label:
                        AppLocalizations.of(context)?.gameBaseBuilder ??
                        'Builder Base',
                    imageUrl: ImageAssets.builderHall(
                      widget.selectedPlayer.builderHallLevel,
                    ),
                  ),
                  InfoProfileTabData(
                    label:
                        AppLocalizations.of(context)?.warStats ?? 'War Stats',
                    imageUrl: ImageAssets.war,
                  ),
                  InfoProfileTabData(
                    label:
                        AppLocalizations.of(context)?.gameAchievements ??
                        'Achievements',
                    imageUrl: ImageAssets.attackStar,
                  ),
                ],
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
    final isDesktopWeb = _isDesktopWeb(context);
    final margin = isDesktopWeb
        ? EdgeInsets.zero
        : const EdgeInsets.symmetric(horizontal: 16, vertical: 5);
    final sections = <Widget>[
      if (player.superTroops.any((troop) => troop.superTroopIsActive))
        PlayerSuperTroopSection(
          superTroops: player.superTroops,
          margin: margin,
        ),
      if (player.heroes.isNotEmpty)
        PlayerItemSection(
          title: loc.gameHeroes,
          items: player.heroes,
          townHallLevel: player.townHallLevel,
          initiallyExpanded: true,
          margin: margin,
        ),
      if (player.equipments.isNotEmpty)
        PlayerItemSection(
          title: loc.gameEquipment,
          items: player.equipments,
          townHallLevel: player.townHallLevel,
          initiallyExpanded: true,
          margin: margin,
        ),
      if (player.troops.isNotEmpty)
        PlayerItemSection(
          title: loc.gameTroops,
          items: player.troops,
          townHallLevel: player.townHallLevel,
          margin: margin,
        ),
      if (player.spells.isNotEmpty)
        PlayerItemSection(
          title: loc.gameSpells,
          items: player.spells,
          townHallLevel: player.townHallLevel,
          margin: margin,
        ),
      if (player.siegeMachines.isNotEmpty)
        PlayerItemSection(
          title: loc.gameSiegeMachines,
          items: player.siegeMachines,
          townHallLevel: player.townHallLevel,
          margin: margin,
        ),
      if (player.pets.isNotEmpty)
        PlayerItemSection(
          title: loc.gamePets,
          items: player.pets,
          townHallLevel: player.townHallLevel,
          margin: margin,
        ),
    ];
    if (isDesktopWeb) {
      return [
        SliverToBoxAdapter(
          child: _CenteredDesktopContent(
            child: _PlayerSectionGrid(children: sections),
          ),
        ),
      ];
    }

    final builders = <Widget Function()>[
      () => const SizedBox(height: 10),
      ...sections.map(
        (section) =>
            () => section,
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
    final isDesktopWeb = _isDesktopWeb(context);
    final margin = isDesktopWeb
        ? EdgeInsets.zero
        : const EdgeInsets.symmetric(horizontal: 16, vertical: 5);
    final sections = <Widget>[
      if (player.bbHeroes.isNotEmpty)
        PlayerItemSection(
          title: loc.gameHeroes,
          items: player.bbHeroes,
          townHallLevel: player.builderHallLevel,
          initiallyExpanded: true,
          margin: margin,
        ),
      if (player.bbTroops.isNotEmpty)
        PlayerItemSection(
          title: loc.gameTroops,
          items: player.bbTroops,
          townHallLevel: player.builderHallLevel,
          margin: margin,
        ),
    ];
    if (isDesktopWeb) {
      return [
        SliverToBoxAdapter(
          child: _CenteredDesktopContent(
            child: _PlayerSectionGrid(children: sections),
          ),
        ),
      ];
    }

    final builders = <Widget Function()>[
      () => const SizedBox(height: 10),
      ...sections.map(
        (section) =>
            () => section,
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

  bool _isDesktopWeb(BuildContext context) {
    return kIsWeb && MediaQuery.sizeOf(context).width >= _desktopBreakpoint;
  }
}

class _CenteredDesktopContent extends StatelessWidget {
  const _CenteredDesktopContent({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: PlayerScreenState._desktopMaxContentWidth,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
          child: child,
        ),
      ),
    );
  }
}

class _PlayerSectionGrid extends StatelessWidget {
  const _PlayerSectionGrid({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 820 || children.length == 1) {
          return Column(
            children: [
              for (var index = 0; index < children.length; index++) ...[
                children[index],
                if (index < children.length - 1) const SizedBox(height: 12),
              ],
            ],
          );
        }

        final columns = [<Widget>[], <Widget>[]];
        for (var index = 0; index < children.length; index++) {
          columns[index.isEven ? 0 : 1].add(children[index]);
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _PlayerSectionColumn(children: columns[0])),
            const SizedBox(width: 12),
            Expanded(child: _PlayerSectionColumn(children: columns[1])),
          ],
        );
      },
    );
  }
}

class _PlayerSectionColumn extends StatelessWidget {
  const _PlayerSectionColumn({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var index = 0; index < children.length; index++) ...[
          children[index],
          if (index < children.length - 1) const SizedBox(height: 12),
        ],
      ],
    );
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
    final isDesktopWeb = kIsWeb && MediaQuery.sizeOf(context).width >= 900;
    final content = Column(
      children: [
        const SizedBox(height: 10),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: isDesktopWeb ? 0 : 16),
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
        const SizedBox(height: 10),
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
          margin: isDesktopWeb
              ? EdgeInsets.zero
              : const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
          gridTiles: isDesktopWeb,
        ),
        const SizedBox(height: 10),
      ],
    );

    if (!isDesktopWeb) return content;

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: PlayerScreenState._desktopMaxContentWidth,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: content,
        ),
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
  final EdgeInsetsGeometry margin;
  final bool gridTiles;

  const _AchievementSection({
    super.key,
    required this.title,
    required this.imageUrl,
    required this.achievements,
    this.initiallyExpanded = false,
    this.collapsible = true,
    this.showHeader = true,
    this.margin = const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
    this.gridTiles = false,
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
    final sortedAchievements = [
      ...widget.achievements.where((a) => !_isAchievementComplete(a)),
      ...widget.achievements.where(_isAchievementComplete),
    ];
    final achievementTiles = sortedAchievements
        .map(
          (achievement) => _AchievementTile(
            achievement: achievement,
            margin: widget.gridTiles ? EdgeInsets.zero : null,
          ),
        )
        .toList(growable: false);

    return Container(
      width: double.infinity,
      margin: widget.margin,
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
            if (widget.gridTiles)
              ResponsiveCardGrid(
                itemCount: achievementTiles.length,
                minItemWidth: 360,
                maxColumns: 3,
                spacing: 10,
                itemBuilder: (_, index) => achievementTiles[index],
              )
            else
              ...achievementTiles,
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
  final EdgeInsetsGeometry? margin;

  const _AchievementTile({required this.achievement, this.margin});

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
      margin: margin ?? const EdgeInsets.only(bottom: 8),
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
