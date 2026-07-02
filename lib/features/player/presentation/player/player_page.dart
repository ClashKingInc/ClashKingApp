import 'package:clashkingapp/features/player/presentation/player/player_super_troop_section.dart';
import 'package:clashkingapp/common/widgets/mobile_web_image.dart';
import 'package:clashkingapp/core/constants/image_assets.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:clashkingapp/features/player/models/player.dart';
import 'package:clashkingapp/features/player/models/player_achievement.dart';
import 'package:clashkingapp/features/player/data/player_service.dart';
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await context.read<PlayerService>().refreshOfficialPlayerSummary(
        widget.selectedPlayer,
      );
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onHorizontalDragEnd: _handleTabSwipe,
        child: SingleChildScrollView(
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
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeOutCubic,
                child: KeyedSubtree(
                  key: ValueKey(selectedTab),
                  child: switch (selectedTab) {
                    0 => _buildPlayerContent(widget.selectedPlayer),
                    1 => _buildBuilderContent(widget.selectedPlayer),
                    _ => _buildAchievementContent(widget.selectedPlayer),
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _selectTab(int index) {
    final clampedIndex = index > 2 ? 2 : index;
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
    final achievements = player.achievements
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

    return Column(
      children: [
        const SizedBox(height: 10),
        _AchievementSection(
          title: AppLocalizations.of(context)?.gameBaseHome ?? 'Home Base',
          imageUrl: ImageAssets.townHall(player.townHallLevel),
          achievements: home,
          initiallyExpanded: true,
        ),
        _AchievementSection(
          title: AppLocalizations.of(context)?.generalOthers ?? 'Others',
          imageUrl: ImageAssets.builderHall(player.builderHallLevel),
          achievements: others,
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
      length: 3,
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
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.42),
          ),
        ),
      ),
      child: SizedBox(
        height: 48,
        child: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          labelPadding: const EdgeInsets.symmetric(horizontal: 16),
          indicatorColor: colorScheme.primary,
          indicatorWeight: 3,
          indicatorSize: TabBarIndicatorSize.tab,
          indicatorPadding: const EdgeInsets.symmetric(horizontal: 8),
          dividerColor: Colors.transparent,
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
              label:
                  AppLocalizations.of(context)?.gameAchievements ??
                  'Achievements',
              imageUrl: ImageAssets.attackStar,
              selected: widget.selectedIndex == 2,
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
        : colorScheme.onSurface.withValues(alpha: 0.58);

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

  const _AchievementSection({
    required this.title,
    required this.imageUrl,
    required this.achievements,
    this.initiallyExpanded = false,
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

    final completed = widget.achievements.where(_isAchievementComplete).length;
    final ratio = completed / widget.achievements.length;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.38),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(
            context,
          ).colorScheme.outlineVariant.withValues(alpha: 0.42),
        ),
      ),
      child: Column(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  AnimatedRotation(
                    turns: _expanded ? 0.25 : 0,
                    duration: const Duration(milliseconds: 160),
                    child: Icon(
                      Icons.chevron_right_rounded,
                      size: 22,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.72),
                    ),
                  ),
                  const SizedBox(width: 4),
                  MobileWebImage(
                    imageUrl: widget.imageUrl,
                    width: 26,
                    height: 26,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    '$completed/${widget.achievements.length}',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 6,
              backgroundColor: Theme.of(
                context,
              ).colorScheme.outlineVariant.withValues(alpha: 0.25),
            ),
          ),
          if (_expanded) ...[
            const SizedBox(height: 12),
            ...widget.achievements.map(
              (achievement) => _AchievementTile(achievement: achievement),
            ),
          ],
        ],
      ),
    );
  }

  bool _isAchievementComplete(PlayerAchievement achievement) {
    if ((achievement.name == 'Dragon Slayer' ||
            achievement.name == 'Ungrateful Child') &&
        achievement.value >= 1) {
      return true;
    }
    return achievement.value >= achievement.target && achievement.stars == 3;
  }
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

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: complete
              ? const Color(0xFFFFD75E).withValues(alpha: 0.68)
              : Theme.of(
                  context,
                ).colorScheme.outlineVariant.withValues(alpha: 0.34),
        ),
      ),
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
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(width: 8),
              _AchievementStars(stars: _effectiveStars),
            ],
          ),
          if (achievement.info.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              achievement.info.replaceAll(RegExp('000000 '), 'M '),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.62),
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
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.outlineVariant.withValues(alpha: 0.24),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      complete
                          ? const Color(0xFFFFD75E)
                          : Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                progress,
                style: Theme.of(
                  context,
                ).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
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
