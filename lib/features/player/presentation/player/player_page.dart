import 'package:clashkingapp/features/player/presentation/player/player_season_stats_tab.dart';
import 'package:clashkingapp/features/player/presentation/player/player_super_troop_section.dart';
import 'package:clashkingapp/common/widgets/mobile_web_image.dart';
import 'package:clashkingapp/common/widgets/native_liquid_glass.dart';
import 'package:clashkingapp/core/constants/image_assets.dart';
import 'package:flutter/material.dart';
import 'package:clashkingapp/features/player/models/player.dart';
import 'package:clashkingapp/features/player/models/player_achievement.dart';
import 'package:clashkingapp/features/player/presentation/player/player_header.dart';
import 'package:clashkingapp/features/player/presentation/player/player_item_section.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

class PlayerScreen extends StatefulWidget {
  final Player selectedPlayer;

  const PlayerScreen({super.key, required this.selectedPlayer});

  @override
  PlayerScreenState createState() => PlayerScreenState();
}

class PlayerScreenState extends State<PlayerScreen> {
  int selectedTab = 0;
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = 16 + MediaQuery.of(context).padding.bottom;

    // NestedScrollView + PageView: the swipe between tabs tracks the
    // finger (like the app's main pages) while the header scrolls away
    // with the content.
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverToBoxAdapter(
            child: Column(
              children: [
                PlayerInfoHeader(
                  selectedTab: selectedTab,
                  player: widget.selectedPlayer,
                ),
                _PlayerProfileTabs(
                  player: widget.selectedPlayer,
                  selectedIndex: selectedTab,
                  onTabSelected: _selectTab,
                ),
              ],
            ),
          ),
        ],
        body: PageView(
          controller: _pageController,
          onPageChanged: (index) => setState(() => selectedTab = index),
          children: [
            SingleChildScrollView(
              padding: EdgeInsets.only(bottom: bottomPadding),
              child: _buildPlayerContent(widget.selectedPlayer),
            ),
            SingleChildScrollView(
              padding: EdgeInsets.only(bottom: bottomPadding),
              child: _buildBuilderContent(widget.selectedPlayer),
            ),
            SingleChildScrollView(
              padding: EdgeInsets.only(bottom: bottomPadding),
              child: _buildAchievementContent(widget.selectedPlayer),
            ),
            SingleChildScrollView(
              padding: EdgeInsets.only(bottom: bottomPadding),
              child: PlayerSeasonStatsTab(player: widget.selectedPlayer),
            ),
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
    _pageController.animateToPage(
      boundedIndex,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  Widget _buildPlayerContent(Player player) {
    return Column(
      children: [
        SizedBox(height: 10),
        PlayerSuperTroopSection(superTroops: player.superTroops),
        PlayerItemSection(
          title: AppLocalizations.of(context)!.gameHeroes,
          items: player.heroes,
          townHallLevel: player.townHallLevel,
          initiallyExpanded: true,
        ),
        PlayerItemSection(
          title: AppLocalizations.of(context)!.gameEquipment,
          items: player.equipments,
          townHallLevel: player.townHallLevel,
          initiallyExpanded: true,
        ),
        PlayerItemSection(
          title: AppLocalizations.of(context)!.gameTroops,
          items: player.troops,
          townHallLevel: player.townHallLevel,
        ),
        PlayerItemSection(
          title: AppLocalizations.of(context)!.gameSpells,
          items: player.spells,
          townHallLevel: player.townHallLevel,
        ),
        PlayerItemSection(
          title: AppLocalizations.of(context)!.gameSiegeMachines,
          items: player.siegeMachines,
          townHallLevel: player.townHallLevel,
        ),
        PlayerItemSection(
          title: AppLocalizations.of(context)!.gamePets,
          items: player.pets,
          townHallLevel: player.townHallLevel,
        ),
        SizedBox(height: 10),
      ],
    );
  }

  Widget _buildBuilderContent(Player player) {
    return Column(
      children: [
        SizedBox(height: 10),
        PlayerItemSection(
          title: AppLocalizations.of(context)!.gameHeroes,
          items: player.bbHeroes,
          townHallLevel: player.builderHallLevel,
          initiallyExpanded: true,
        ),
        PlayerItemSection(
          title: AppLocalizations.of(context)!.gameTroops,
          items: player.bbTroops,
          townHallLevel: player.builderHallLevel,
        ),
        SizedBox(height: 10),
      ],
    );
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
          child: NativeLiquidGlassSegmentedControl<int>(
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

class _PlayerProfileTabs extends StatelessWidget {
  final Player player;
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;

  const _PlayerProfileTabs({
    required this.player,
    required this.selectedIndex,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Row(
        children: [
          _ProfileTab(
            label: AppLocalizations.of(context)?.gameBaseHome ?? 'Home Base',
            imageUrl: player.townHallPic,
            selected: selectedIndex == 0,
            onTap: () => onTabSelected(0),
          ),
          const SizedBox(width: 20),
          _ProfileTab(
            label:
                AppLocalizations.of(context)?.gameBaseBuilder ?? 'Builder Base',
            imageUrl: player.builderHallPic,
            selected: selectedIndex == 1,
            onTap: () => onTabSelected(1),
          ),
          const SizedBox(width: 20),
          _ProfileTab(
            label:
                AppLocalizations.of(context)?.gameAchievements ??
                'Achievements',
            icon: Icons.star_rounded,
            selected: selectedIndex == 2,
            onTap: () => onTabSelected(2),
          ),
          const SizedBox(width: 20),
          _ProfileTab(
            label: 'Season History',
            icon: Icons.bar_chart_rounded,
            selected: selectedIndex == 3,
            onTap: () => onTabSelected(3),
          ),
        ],
      ),
    );
  }
}

/// Underline-style tab: game icon + label with a red indicator bar under
/// the active tab, like the in-game profile tabs.
class _ProfileTab extends StatelessWidget {
  final String label;
  final String? imageUrl;
  final IconData? icon;
  final bool selected;
  final VoidCallback onTap;

  const _ProfileTab({
    required this.label,
    this.imageUrl,
    this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final foreground = selected
        ? colorScheme.onSurface
        : colorScheme.onSurfaceVariant;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      // IntrinsicWidth bounds the stretch: the underline matches the tab's
      // content width instead of asking for infinite width inside the
      // horizontal scroll view.
      child: IntrinsicWidth(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 7),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Opacity(
                    opacity: selected ? 1.0 : 0.55,
                    child: imageUrl != null
                        ? MobileWebImage(
                            imageUrl: imageUrl!,
                            width: 24,
                            height: 24,
                          )
                        : Icon(icon, size: 21, color: foreground),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    maxLines: 1,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: foreground,
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            AnimatedOpacity(
              duration: const Duration(milliseconds: 180),
              opacity: selected ? 1.0 : 0.0,
              child: Container(
                height: 3.5,
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
          ],
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
