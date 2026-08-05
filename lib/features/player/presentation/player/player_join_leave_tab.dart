import 'package:clashkingapp/common/theme/app_tokens.dart';
import 'package:clashkingapp/common/widgets/inputs/filter_dropdown.dart';
import 'package:clashkingapp/common/widgets/loading/skeleton_loading.dart';
import 'package:clashkingapp/common/widgets/mobile_web_image.dart';
import 'package:clashkingapp/common/widgets/summary_chips.dart';
import 'package:clashkingapp/features/clan/models/clan_join_leave.dart';
import 'package:clashkingapp/features/player/data/player_service.dart';
import 'package:clashkingapp/features/player/models/player_join_leave.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class PlayerJoinLeaveTab extends StatefulWidget {
  final String playerTag;
  final double bottomPadding;
  final Key? scrollViewKey;

  const PlayerJoinLeaveTab({
    super.key,
    required this.playerTag,
    this.bottomPadding = 16,
    this.scrollViewKey,
  });

  @override
  State<PlayerJoinLeaveTab> createState() => _PlayerJoinLeaveTabState();
}

enum _PlayerJoinLeaveView { history, totals }

enum _ClanTotalsSort { timeSpent, visits }

class _PlayerJoinLeaveTabState extends State<PlayerJoinLeaveTab> {
  final _service = PlayerService();
  final List<JoinLeaveEvent> _events = [];
  List<PlayerJoinLeaveTotal> _totals = const [];
  int _available = 0;
  _PlayerJoinLeaveView _selectedView = _PlayerJoinLeaveView.history;
  _ClanTotalsSort _totalsSort = _ClanTotalsSort.timeSpent;
  String _selectedMovement = 'all';
  bool _loading = true;
  bool _loadingMore = false;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  List<JoinLeaveEvent> get _filteredEvents {
    switch (_selectedMovement) {
      case 'joined':
        return _events
            .where((event) => event.type.toLowerCase().contains('join'))
            .toList(growable: false);
      case 'left':
        return _events
            .where((event) => !event.type.toLowerCase().contains('join'))
            .toList(growable: false);
      default:
        return _events;
    }
  }

  List<PlayerJoinLeaveTotal> get _sortedTotals {
    final totals = [..._totals];
    totals.sort((left, right) {
      final primary = _totalsSort == _ClanTotalsSort.timeSpent
          ? right.minutes.compareTo(left.minutes)
          : right.visits.compareTo(left.visits);
      if (primary != 0) return primary;
      final secondary = _totalsSort == _ClanTotalsSort.timeSpent
          ? right.visits.compareTo(left.visits)
          : right.minutes.compareTo(left.minutes);
      if (secondary != 0) return secondary;
      return left.clan.name.compareTo(right.clan.name);
    });
    return totals;
  }

  int get _totalMinutes =>
      _totals.fold(0, (total, clan) => total + clan.minutes);

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait([
        _service.loadPlayerJoinLeave(widget.playerTag),
        _service.loadPlayerJoinLeaveTotals(widget.playerTag),
      ]);
      final page = results[0] as PlayerJoinLeavePage;
      if (!mounted) return;
      setState(() {
        _events.addAll(page.items);
        _available = page.available;
        _totals = results[1] as List<PlayerJoinLeaveTotal>;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error;
        _loading = false;
      });
    }
  }

  Future<void> _loadMoreIfNeeded(ScrollMetrics metrics) async {
    if (_selectedView != _PlayerJoinLeaveView.history ||
        metrics.extentAfter > 500 ||
        _loadingMore ||
        _events.isEmpty ||
        _events.length >= _available) {
      return;
    }
    setState(() => _loadingMore = true);
    try {
      final cursor = _events.last.time.toUtc().subtract(
        const Duration(microseconds: 1),
      );
      final page = await _service.loadPlayerJoinLeave(
        widget.playerTag,
        before: cursor,
      );
      final seen = _events
          .map((event) => '${event.time}|${event.type}|${event.clan?.tag}')
          .toSet();
      if (!mounted) return;
      setState(() {
        _events.addAll(
          page.items.where(
            (event) =>
                seen.add('${event.time}|${event.type}|${event.clan?.tag}'),
          ),
        );
        _available = page.available;
      });
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    if (_loading) {
      return CustomScrollView(
        key: widget.scrollViewKey,
        primary: true,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: const [
          SliverFillRemaining(
            child: SkeletonPage(itemCount: 5, includeHeader: false),
          ),
        ],
      );
    }
    if (_error != null) {
      return CustomScrollView(
        key: widget.scrollViewKey,
        primary: true,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverFillRemaining(
            child: Center(
              child: TextButton.icon(
                onPressed: () {
                  setState(() {
                    _loading = true;
                    _error = null;
                  });
                  _load();
                },
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Could not load join / leave history'),
              ),
            ),
          ),
        ],
      );
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification.metrics.axis == Axis.vertical) {
          _loadMoreIfNeeded(notification.metrics);
        }
        return false;
      },
      child: ListView(
        key: widget.scrollViewKey,
        primary: true,
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        padding: EdgeInsets.fromLTRB(16, 10, 16, widget.bottomPadding),
        children: [
          _PlayerJoinLeaveFilterBar(
            leading: FilterDropdown(
              sortBy: _selectedView.name,
              updateSortBy: (view) => setState(
                () => _selectedView = _PlayerJoinLeaveView.values.byName(view),
              ),
              sortByOptions: const {
                'History': 'history',
                'Clan totals': 'totals',
              },
              maxWidth: 126,
              leadingIcon: Icons.swap_horiz_rounded,
            ),
            middle: _selectedView == _PlayerJoinLeaveView.history
                ? _historySummary()
                : _totalsSummary(),
            chips: _selectedView == _PlayerJoinLeaveView.history
                ? _historyFilters(loc)
                : _totalsFilters(),
          ),
          const SizedBox(height: 12),
          if (_selectedView == _PlayerJoinLeaveView.history)
            ..._buildHistory(loc)
          else
            ..._buildClanTotals(),
        ],
      ),
    );
  }

  Widget _historySummary() => CKSummaryChipRail(
    padding: EdgeInsets.zero,
    children: [
      CKSummaryChip(
        icon: Icons.swap_horiz_rounded,
        value: _available.toString(),
        label: 'Events',
      ),
      CKSummaryChip(
        icon: Icons.shield_rounded,
        value: _totals.length.toString(),
        label: 'Clans',
      ),
    ],
  );

  List<Widget> _historyFilters(AppLocalizations? loc) => [
    CKFilterChip(
      icon: Icons.all_inclusive_rounded,
      label: loc?.generalAll ?? 'All',
      selected: _selectedMovement == 'all',
      onTap: () => setState(() => _selectedMovement = 'all'),
    ),
    CKFilterChip(
      icon: Icons.login_rounded,
      label: loc?.joinLeaveJoin ?? 'Join',
      selected: _selectedMovement == 'joined',
      color: Colors.green,
      onTap: () => setState(() => _selectedMovement = 'joined'),
    ),
    CKFilterChip(
      icon: Icons.logout_rounded,
      label: loc?.joinLeaveLeave ?? 'Leave',
      selected: _selectedMovement == 'left',
      color: Colors.redAccent,
      onTap: () => setState(() => _selectedMovement = 'left'),
    ),
  ];

  List<Widget> _buildHistory(AppLocalizations? loc) => [
    if (_filteredEvents.isEmpty)
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Center(
          child: Text(
            _selectedMovement == 'all'
                ? 'No join / leave history available'
                : loc?.generalNoFilteredResults ??
                      'No results match your filters',
          ),
        ),
      )
    else
      ..._filteredEvents.map((event) => _PlayerEventCard(event: event)),
    if (_loadingMore)
      const Padding(
        padding: EdgeInsets.all(16),
        child: SkeletonList(itemCount: 1),
      ),
  ];

  Widget _totalsSummary() => CKSummaryChipRail(
    padding: EdgeInsets.zero,
    children: [
      CKSummaryChip(
        icon: Icons.shield_rounded,
        value: _totals.length.toString(),
        label: 'Clans',
      ),
      CKSummaryChip(
        icon: Icons.schedule_rounded,
        value: _duration(_totalMinutes),
        label: 'Time',
        color: Colors.teal,
      ),
    ],
  );

  List<Widget> _totalsFilters() => [
    CKFilterChip(
      icon: Icons.schedule_rounded,
      label: 'Time spent',
      selected: _totalsSort == _ClanTotalsSort.timeSpent,
      color: Colors.teal,
      onTap: () => setState(() => _totalsSort = _ClanTotalsSort.timeSpent),
    ),
    CKFilterChip(
      icon: Icons.repeat_rounded,
      label: 'Visits',
      selected: _totalsSort == _ClanTotalsSort.visits,
      onTap: () => setState(() => _totalsSort = _ClanTotalsSort.visits),
    ),
  ];

  List<Widget> _buildClanTotals() => [
    if (_sortedTotals.isEmpty)
      const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(child: Text('No clan totals available')),
      )
    else
      ..._sortedTotals.map((total) => _TotalCard(total: total)),
  ];
}

class _PlayerJoinLeaveFilterBar extends StatefulWidget {
  final List<Widget> chips;
  final Widget leading;
  final Widget middle;

  const _PlayerJoinLeaveFilterBar({
    required this.chips,
    required this.leading,
    required this.middle,
  });

  @override
  State<_PlayerJoinLeaveFilterBar> createState() =>
      _PlayerJoinLeaveFilterBarState();
}

class _PlayerJoinLeaveFilterBarState extends State<_PlayerJoinLeaveFilterBar> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            widget.leading,
            const SizedBox(width: 8),
            Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(AppRadius.chip),
              child: InkWell(
                borderRadius: BorderRadius.circular(AppRadius.chip),
                onTap: () => setState(() => _expanded = !_expanded),
                child: Container(
                  height: 40,
                  width: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _expanded
                        ? colorScheme.primary.withValues(alpha: 0.14)
                        : colorScheme.surfaceContainerHighest.withValues(
                            alpha: 0.45,
                          ),
                    borderRadius: BorderRadius.circular(AppRadius.chip),
                    border: Border.all(
                      color: _expanded
                          ? colorScheme.primary.withValues(alpha: 0.4)
                          : colorScheme.outlineVariant.withValues(alpha: 0.32),
                    ),
                  ),
                  child: Icon(
                    Icons.filter_list_rounded,
                    size: 18,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: widget.middle,
              ),
            ),
          ],
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topLeft,
          child: _expanded
              ? Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: widget.chips,
                  ),
                )
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }
}

class _TotalCard extends StatelessWidget {
  final PlayerJoinLeaveTotal total;
  const _TotalCard({required this.total});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 7),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.chip),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.32),
        ),
      ),
      child: Row(
        children: [
          SizedBox.square(
            dimension: 44,
            child: total.clan.badge.isEmpty
                ? Icon(
                    Icons.shield_rounded,
                    color: colorScheme.onSurfaceVariant,
                  )
                : MobileWebImage(
                    imageUrl: total.clan.badge,
                    width: 44,
                    height: 44,
                  ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  total.clan.name.isEmpty ? total.clan.tag : total.clan.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.schedule_rounded,
                      size: 15,
                      color: Colors.teal,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      _duration(total.minutes),
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: Colors.teal,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        'time spent',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          CKSummaryChip(
            icon: Icons.repeat_rounded,
            value: total.visits.toString(),
            label: 'Visits',
          ),
        ],
      ),
    );
  }
}

class _PlayerEventCard extends StatelessWidget {
  final JoinLeaveEvent event;
  const _PlayerEventCard({required this.event});

  @override
  Widget build(BuildContext context) {
    final clan = event.clan;
    final joined = event.type.toLowerCase().contains('join');
    return Card(
      child: ListTile(
        leading: clan == null || clan.badge.isEmpty
            ? const Icon(Icons.shield_rounded)
            : MobileWebImage(imageUrl: clan.badge, width: 42, height: 42),
        title: Text(
          clan?.name.isNotEmpty == true ? clan!.name : clan?.tag ?? '',
        ),
        subtitle: Text(_relativeTime(event.time)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              joined ? Icons.login_rounded : Icons.logout_rounded,
              color: joined ? Colors.green : Colors.redAccent,
            ),
            const SizedBox(width: 4),
            Text(joined ? 'Joined' : 'Left'),
          ],
        ),
      ),
    );
  }
}

String _duration(int minutes) {
  final days = minutes ~/ 1440;
  if (days >= 365) {
    final years = days ~/ 365;
    final months = (days % 365) ~/ 30;
    return months > 0 ? '${years}y ${months}mo' : '${years}y';
  }
  if (days >= 30) {
    final months = days ~/ 30;
    final remainingDays = days % 30;
    return remainingDays > 0 ? '${months}mo ${remainingDays}d' : '${months}mo';
  }
  if (days > 0) return '${days}d';
  final hours = minutes ~/ 60;
  if (hours > 0) return '${hours}h';
  return '${minutes}m';
}

String _relativeTime(DateTime time) {
  final difference = DateTime.now().difference(time);
  if (difference.inDays > 0) return '${difference.inDays}d ago';
  if (difference.inHours > 0) return '${difference.inHours}h ago';
  return '${difference.inMinutes.clamp(1, 59)}m ago';
}
