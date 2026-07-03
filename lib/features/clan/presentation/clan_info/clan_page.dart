import 'package:clashkingapp/common/theme/app_tokens.dart';
import 'package:clashkingapp/common/widgets/mobile_web_image.dart';
import 'package:clashkingapp/common/widgets/native_liquid_glass.dart';
import 'package:flutter/foundation.dart';
import 'package:clashkingapp/core/constants/image_assets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:clashkingapp/features/clan/data/clan_service.dart';
import 'package:clashkingapp/features/clan/models/clan.dart';
import 'package:clashkingapp/features/clan/models/cwl_ranking_history.dart';
import 'package:clashkingapp/features/clan/presentation/clan_info/clan_header.dart';
import 'package:clashkingapp/features/clan/presentation/clan_info/clan_members.dart';
import 'package:clashkingapp/features/player/models/player_war_stats.dart';
import 'package:clashkingapp/features/war_cwl/presentation/war_stats/clan_war_log.dart';
import 'package:clashkingapp/features/war_cwl/presentation/war_stats/war_stats_players.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Clan detail screen: hero header + tabs for Members / War Log /
/// Statistics / CWL History — content that used to live behind a
/// separate pushed screen (`ClanWarStatsScreen`) is now embedded here,
/// mirroring the player profile's tab pattern.
class ClanInfoScreen extends StatefulWidget {
  final Clan clanInfo;
  final int initialTab;

  const ClanInfoScreen({
    super.key,
    required this.clanInfo,
    this.initialTab = 0,
  });

  @override
  State<ClanInfoScreen> createState() => _ClanInfoScreenState();
}

class _ClanInfoScreenState extends State<ClanInfoScreen> {
  static const int _tabCount = 4;
  late int selectedTab;

  // Shared between the War Log and Statistics tabs so toggling a war
  // type in one is reflected in the other instead of each tab keeping
  // its own independent copy.
  bool isCWLChecked = true;
  bool isRandomChecked = true;
  bool isFriendlyChecked = true;

  List<String> get _selectedWarTypes => [
    if (isCWLChecked) 'cwl',
    if (isRandomChecked) 'random',
    if (isFriendlyChecked) 'friendly',
  ];

  @override
  void initState() {
    super.initState();
    selectedTab = widget.initialTab.clamp(0, _tabCount - 1);
  }

  void _selectTab(int index) {
    final bounded = index.clamp(0, _tabCount - 1);
    if (bounded == selectedTab) return;
    setState(() => selectedTab = bounded);
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

  void _resetWarTypeFilters() {
    setState(() {
      isCWLChecked = true;
      isRandomChecked = true;
      isFriendlyChecked = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onHorizontalDragEnd: _handleTabSwipe,
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            bottom: 16 + MediaQuery.of(context).padding.bottom,
          ),
          child: Column(
            children: [
              ClanInfoHeaderCard(
                clanInfo: widget.clanInfo,
                onOpenStats: () => _selectTab(1),
              ),
              const SizedBox(height: 10),
              _ClanProfileTabs(
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
                    0 => ClanMembers(clanInfo: widget.clanInfo),
                    1 => _ClanWarLogTab(
                      clan: widget.clanInfo,
                      isCWLChecked: isCWLChecked,
                      isRandomChecked: isRandomChecked,
                      isFriendlyChecked: isFriendlyChecked,
                      selectedTypes: _selectedWarTypes,
                      onCWLChanged: () =>
                          setState(() => isCWLChecked = !isCWLChecked),
                      onRandomChanged: () =>
                          setState(() => isRandomChecked = !isRandomChecked),
                      onFriendlyChanged: () => setState(
                        () => isFriendlyChecked = !isFriendlyChecked,
                      ),
                    ),
                    2 => _ClanStatisticsTab(
                      clan: widget.clanInfo,
                      isCWLChecked: isCWLChecked,
                      isRandomChecked: isRandomChecked,
                      isFriendlyChecked: isFriendlyChecked,
                      selectedTypes: _selectedWarTypes,
                      onCWLChanged: () =>
                          setState(() => isCWLChecked = !isCWLChecked),
                      onRandomChanged: () =>
                          setState(() => isRandomChecked = !isRandomChecked),
                      onFriendlyChanged: () => setState(
                        () => isFriendlyChecked = !isFriendlyChecked,
                      ),
                      onResetWarTypes: _resetWarTypeFilters,
                    ),
                    _ => _ClanCwlHistoryTab(clan: widget.clanInfo),
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ClanProfileTabs extends StatefulWidget {
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;

  const _ClanProfileTabs({
    required this.selectedIndex,
    required this.onTabSelected,
  });

  @override
  State<_ClanProfileTabs> createState() => _ClanProfileTabsState();
}

class _ClanProfileTabsState extends State<_ClanProfileTabs>
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
  void didUpdateWidget(covariant _ClanProfileTabs oldWidget) {
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
    final loc = AppLocalizations.of(context)!;

    return SizedBox(
      height: 48,
      child: Stack(
        fit: StackFit.expand,
        children: [
          const NativeLiquidGlassBar(
            height: 48,
            cornerRadius: 0,
            opacity: 0.85,
          ),
          TabBar(
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
              _ClanTab(
                label: loc.clanMembers,
                icon: Icons.groups_rounded,
                selected: widget.selectedIndex == 0,
              ),
              _ClanTab(
                label: loc.warLog,
                imageUrl: ImageAssets.war,
                selected: widget.selectedIndex == 1,
              ),
              _ClanTab(
                label: loc.navigationStatistics,
                icon: Icons.bar_chart_rounded,
                selected: widget.selectedIndex == 2,
              ),
              _ClanTab(
                label: loc.cwlHistoryTitle,
                icon: Icons.emoji_events_rounded,
                selected: widget.selectedIndex == 3,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ClanTab extends StatelessWidget {
  final String label;
  final String? imageUrl;
  final IconData? icon;
  final bool selected;

  const _ClanTab({
    required this.label,
    this.imageUrl,
    this.icon,
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
          imageUrl != null
              ? MobileWebImage(imageUrl: imageUrl!, width: 18, height: 18)
              : Icon(icon, size: 18, color: foreground),
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

/// Compact CWL/Random/Friendly war-type filter, shared visual recipe
/// used by both the War Log and Statistics tabs (each owns its own
/// copy of this small state independently).
class _WarTypeFilterRow extends StatelessWidget {
  final bool isCWLChecked;
  final bool isRandomChecked;
  final bool isFriendlyChecked;
  final VoidCallback onCWLChanged;
  final VoidCallback onRandomChanged;
  final VoidCallback onFriendlyChanged;

  const _WarTypeFilterRow({
    required this.isCWLChecked,
    required this.isRandomChecked,
    required this.isFriendlyChecked,
    required this.onCWLChanged,
    required this.onRandomChanged,
    required this.onFriendlyChanged,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _FilterPill(
            label: loc.cwlTitle,
            imageUrl: ImageAssets.cwlSwordsNoBorder,
            selected: isCWLChecked,
            onTap: onCWLChanged,
          ),
          _FilterPill(
            label: loc.warFiltersRandom,
            icon: LucideIcons.shuffle,
            selected: isRandomChecked,
            onTap: onRandomChanged,
          ),
          _FilterPill(
            label: loc.warFiltersFriendly,
            icon: LucideIcons.handshake,
            selected: isFriendlyChecked,
            onTap: onFriendlyChanged,
          ),
        ],
      ),
    );
  }
}

/// Small glass toggle pill — icon-in-circle + label, same visual family
/// as MetricChip/the reskinned chip.dart, tinted with the theme primary
/// when selected instead of Material's default checkmark FilterChip.
class _FilterPill extends StatelessWidget {
  final String label;
  final IconData? icon;
  final String? imageUrl;
  final bool selected;
  final VoidCallback onTap;

  const _FilterPill({
    required this.label,
    this.icon,
    this.imageUrl,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final tint = selected ? colorScheme.primary : null;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.chip),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.chip),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(6, 5, 12, 5),
          decoration: BoxDecoration(
            color: tint != null
                ? tint.withValues(alpha: 0.14)
                : colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(AppRadius.chip),
            border: Border.all(
              color:
                  tint?.withValues(alpha: 0.4) ??
                  colorScheme.outlineVariant.withValues(alpha: 0.32),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: colorScheme.surface.withValues(alpha: 0.72),
                  shape: BoxShape.circle,
                ),
                child: SizedBox.square(
                  dimension: 22,
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: imageUrl != null
                        ? MobileWebImage(imageUrl: imageUrl!)
                        : Icon(
                            icon,
                            size: 14,
                            color: tint ?? colorScheme.onSurfaceVariant,
                          ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: tint ?? colorScheme.onSurface,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ClanWarLogTab extends StatelessWidget {
  final Clan clan;
  final bool isCWLChecked;
  final bool isRandomChecked;
  final bool isFriendlyChecked;
  final List<String> selectedTypes;
  final VoidCallback onCWLChanged;
  final VoidCallback onRandomChanged;
  final VoidCallback onFriendlyChanged;

  const _ClanWarLogTab({
    required this.clan,
    required this.isCWLChecked,
    required this.isRandomChecked,
    required this.isFriendlyChecked,
    required this.selectedTypes,
    required this.onCWLChanged,
    required this.onRandomChanged,
    required this.onFriendlyChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _WarTypeFilterRow(
          isCWLChecked: isCWLChecked,
          isRandomChecked: isRandomChecked,
          isFriendlyChecked: isFriendlyChecked,
          onCWLChanged: onCWLChanged,
          onRandomChanged: onRandomChanged,
          onFriendlyChanged: onFriendlyChanged,
        ),
        Padding(
          padding: const EdgeInsets.all(8),
          child: ClanWarLog(clan: clan, selectedTypes: selectedTypes),
        ),
      ],
    );
  }
}

class _ClanStatisticsTab extends StatefulWidget {
  final Clan clan;
  final bool isCWLChecked;
  final bool isRandomChecked;
  final bool isFriendlyChecked;
  final List<String> selectedTypes;
  final VoidCallback onCWLChanged;
  final VoidCallback onRandomChanged;
  final VoidCallback onFriendlyChanged;
  final VoidCallback onResetWarTypes;

  const _ClanStatisticsTab({
    required this.clan,
    required this.isCWLChecked,
    required this.isRandomChecked,
    required this.isFriendlyChecked,
    required this.selectedTypes,
    required this.onCWLChanged,
    required this.onRandomChanged,
    required this.onFriendlyChanged,
    required this.onResetWarTypes,
  });

  @override
  State<_ClanStatisticsTab> createState() => _ClanStatisticsTabState();
}

class _ClanStatisticsTabState extends State<_ClanStatisticsTab> {
  String _sortBy = 'Three Stars Attacks';
  bool showUppedTownHall = true;
  bool _isLoadingStats = false;
  late List<PlayerWarStats> filteredPlayers;

  @override
  void initState() {
    super.initState();
    filteredPlayers = widget.clan.clanWarStats?.players ?? [];
    if (widget.clan.clanWarStats == null) {
      _loadStats();
    }
  }

  @override
  void didUpdateWidget(covariant _ClanStatisticsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    // The war-type filter lives in the parent (shared with the War Log
    // tab); react to it changing instead of assuming setState above
    // synchronously updates our own widget.selectedTypes.
    if (!listEquals(oldWidget.selectedTypes, widget.selectedTypes)) {
      setState(_sortMembers);
    }
  }

  Future<void> _loadStats() async {
    setState(() => _isLoadingStats = true);
    try {
      final clanService = context.read<ClanService>();
      await clanService.loadClanWarStatsData([widget.clan.tag]);
      clanService.linkWarStatsToClans();
    } catch (_) {
      // Keep showing the (possibly empty) stats we already have.
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingStats = false;
          filteredPlayers = widget.clan.clanWarStats?.players ?? [];
        });
      }
    }
  }

  void _toggleTownHallVisibility() {
    setState(() => showUppedTownHall = !showUppedTownHall);
  }

  void _updateSortBy(String newValue) {
    setState(() {
      _sortBy = newValue;
      _sortMembers();
    });
  }

  void _resetFilters() {
    widget.onResetWarTypes();
    setState(() {
      showUppedTownHall = true;
      filteredPlayers = widget.clan.clanWarStats?.players ?? [];
    });
  }

  void _sortMembers() {
    final selectedTypes = widget.selectedTypes;
    final allPlayers = widget.clan.clanWarStats?.players ?? [];
    final playersByTag = {
      for (var player in filteredPlayers) player.tag: player,
    };

    filteredPlayers = allPlayers
        .where((member) => playersByTag.containsKey(member.tag))
        .toList();

    double statFor(PlayerWarStats player) {
      final stats = player.getStatsForTypes(selectedTypes);
      return switch (_sortBy) {
        'Average Destruction' => stats.averageDestruction,
        'Average Stars' => stats.averageStars,
        'No Star Attacks' => (stats.starsCount['0'] ?? 0).toDouble(),
        'One Star Attacks' => (stats.starsCount['1'] ?? 0).toDouble(),
        'Two Stars Attacks' => (stats.starsCount['2'] ?? 0).toDouble(),
        'Three Stars Attacks' => (stats.starsCount['3'] ?? 0).toDouble(),
        'War Participation' => stats.warsCounts.toDouble(),
        'Missed Attacks' => stats.missedAttacks.toDouble(),
        _ => 0.0,
      };
    }

    filteredPlayers.sort((a, b) => statFor(b).compareTo(statFor(a)));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _WarTypeFilterRow(
          isCWLChecked: widget.isCWLChecked,
          isRandomChecked: widget.isRandomChecked,
          isFriendlyChecked: widget.isFriendlyChecked,
          onCWLChanged: widget.onCWLChanged,
          onRandomChanged: widget.onRandomChanged,
          onFriendlyChanged: widget.onFriendlyChanged,
        ),
        if (_isLoadingStats)
          const Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: CircularProgressIndicator()),
          )
        else
          Padding(
            padding: const EdgeInsets.all(8),
            child: ClanWarStatsPlayers(
              clan: widget.clan,
              showUppedTownHall: showUppedTownHall,
              sortBy: _sortBy,
              selectedTypes: widget.selectedTypes,
              filteredPlayers: filteredPlayers,
              allPlayers: (widget.clan.clanWarStats?.players ?? [])
                  .map((player) => player.tag)
                  .toList(),
              toggleTownHallVisibility: _toggleTownHallVisibility,
              updateSortBy: _updateSortBy,
              resetFilters: _resetFilters,
              attackerThFilter: const [],
              defenderThFilter: const [],
              equalThSelected: false,
            ),
          ),
      ],
    );
  }
}

class _ClanCwlHistoryTab extends StatefulWidget {
  final Clan clan;

  const _ClanCwlHistoryTab({required this.clan});

  @override
  State<_ClanCwlHistoryTab> createState() => _ClanCwlHistoryTabState();
}

class _ClanCwlHistoryTabState extends State<_ClanCwlHistoryTab> {
  late final Future<List<CwlRankingHistoryEntry>> _future;

  @override
  void initState() {
    super.initState();
    _future = context.read<ClanService>().getCwlRankingHistory(widget.clan.tag);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: FutureBuilder<List<CwlRankingHistoryEntry>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final entries = snapshot.data ?? [];
          if (entries.isEmpty) {
            return _EmptyCwlHistory();
          }

          return Column(
            children: entries
                .map((entry) => _CwlHistoryCard(entry: entry))
                .toList(),
          );
        },
      ),
    );
  }
}

class _EmptyCwlHistory extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final loc = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
      child: Column(
        children: [
          Icon(
            Icons.emoji_events_outlined,
            size: 40,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 10),
          Text(
            loc.cwlHistoryEmptyTitle,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            loc.cwlHistoryEmptyBody,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _CwlHistoryCard extends StatelessWidget {
  final CwlRankingHistoryEntry entry;

  const _CwlHistoryCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.32),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              '#${entry.rank}',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.season,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                if (entry.league != null && entry.league!.isNotEmpty) ...[
                  const SizedBox(height: 1),
                  Text(
                    entry.league!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${entry.roundsWon}W · ${entry.roundsTied}T · ${entry.roundsLost}L',
                style: Theme.of(
                  context,
                ).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 3),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.star_rounded,
                    size: 13,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    '${entry.stars}',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${entry.destruction.toStringAsFixed(1)}%',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
