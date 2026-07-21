import 'dart:async';

import 'package:clashkingapp/common/theme/app_tokens.dart';
import 'package:clashkingapp/common/widgets/header_widgets.dart';
import 'package:clashkingapp/common/widgets/info_profile_tabs.dart';
import 'package:clashkingapp/common/widgets/liquid_glass.dart';
import 'package:clashkingapp/common/widgets/mobile_web_image.dart';
import 'package:clashkingapp/core/constants/image_assets.dart';
import 'package:clashkingapp/features/clan/data/clan_service.dart';
import 'package:clashkingapp/features/clan/presentation/clan_info/clan_page.dart';
import 'package:clashkingapp/features/pages/presentation/side_page_components.dart';
import 'package:clashkingapp/features/player/data/player_service.dart';
import 'package:clashkingapp/features/player/presentation/player/player_page.dart';
import 'package:clashkingapp/features/rankings/data/rankings_provider.dart';
import 'package:clashkingapp/features/rankings/models/ranking_models.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class RankingsPage extends StatefulWidget {
  const RankingsPage({super.key, this.provider});

  final RankingsProvider? provider;

  @override
  State<RankingsPage> createState() => _RankingsPageState();
}

class _RankingsPageState extends State<RankingsPage> {
  late final RankingsProvider _provider;
  late final bool _ownsProvider;

  @override
  void initState() {
    super.initState();
    _ownsProvider = widget.provider == null;
    _provider = widget.provider ?? RankingsProvider();
    unawaited(_provider.initialize());
  }

  @override
  void dispose() {
    if (_ownsProvider) _provider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _provider,
      builder: (context, _) {
        final boards = _provider.boards;
        final selectedIndex = boards
            .indexOf(_provider.board)
            .clamp(0, boards.length - 1);
        return Scaffold(
          resizeToAvoidBottomInset: false,
          body: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onHorizontalDragEnd: (details) =>
                _handleBoardSwipe(details, boards, selectedIndex),
            child: NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) => [
                SliverToBoxAdapter(
                  child: _RankingsHeader(
                    provider: _provider,
                    onAudienceChanged: _provider.selectAudience,
                  ),
                ),
                SliverToBoxAdapter(
                  child: InfoProfileTabs(
                    selectedIndex: selectedIndex,
                    onTabSelected: (index) =>
                        _provider.selectBoard(boards[index]),
                    tabs: boards
                        .map(
                          (board) => InfoProfileTabData(
                            label: board.labelOf(AppLocalizations.of(context)!),
                            imageUrl: board.iconUrl,
                          ),
                        )
                        .toList(growable: false),
                  ),
                ),
              ],
              body: _RankingsBody(
                provider: _provider,
                onOpenLocationPicker: _openLocationPicker,
                onOpenTownHallPicker: _openTownHallPicker,
                onOpenLeaguePicker: _openLeaguePicker,
                onOpenHistoryDatePicker: _openHistoryDatePicker,
                onOpenEntry: _openEntry,
              ),
            ),
          ),
        );
      },
    );
  }

  void _handleBoardSwipe(
    DragEndDetails details,
    List<RankingBoard> boards,
    int selectedIndex,
  ) {
    final velocity = details.primaryVelocity ?? 0;
    if (velocity.abs() < 240) return;
    final next = velocity < 0 ? selectedIndex + 1 : selectedIndex - 1;
    if (next >= 0 && next < boards.length) {
      unawaited(_provider.selectBoard(boards[next]));
    }
  }

  Future<void> _openLocationPicker() async {
    final selected = await showRankingLocationPicker(
      context,
      locations: _provider.locations,
      selected: _provider.location,
      allowWorldwide: _provider.board.supportsWorldwide,
    );
    if (selected != null) await _provider.selectLocation(selected);
  }

  Future<void> _openTownHallPicker() async {
    final selected = await _showChoiceSheet<int>(
      title: AppLocalizations.of(context)!.rankingsTownHall,
      values: List<int>.generate(12, (index) => 18 - index),
      selected: _provider.townHallLevel,
      label: (value) => 'TH$value',
      leading: (value) => MobileWebImage(
        imageUrl: ImageAssets.townHall(value),
        width: 36,
        height: 36,
      ),
    );
    if (selected != null) await _provider.selectTownHall(selected);
  }

  Future<void> _openLeaguePicker() async {
    final selected = await _showChoiceSheet<RankingLeagueOption>(
      title: AppLocalizations.of(context)!.rankingsRankedLeague,
      values: _provider.leagueOptions,
      selected: _provider.selectedLeague,
      label: (value) => value.name,
      leading: (value) =>
          MobileWebImage(imageUrl: value.iconUrl, width: 36, height: 36),
      matches: (a, b) => a.id == b.id,
    );
    if (selected != null) await _provider.selectLeague(selected);
  }

  Future<T?> _showChoiceSheet<T>({
    required String title,
    required List<T> values,
    required T selected,
    required String Function(T) label,
    required Widget Function(T) leading,
    bool Function(T, T)? matches,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return showModalBottomSheet<T>(
      context: context,
      showDragHandle: true,
      backgroundColor: scheme.surface,
      constraints: const BoxConstraints(maxWidth: 640),
      builder: (context) => SafeArea(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 520),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                  itemCount: values.length,
                  itemBuilder: (context, index) {
                    final value = values[index];
                    final isSelected =
                        matches?.call(value, selected) ?? value == selected;
                    return ListTile(
                      leading: leading(value),
                      title: Text(label(value)),
                      trailing: isSelected
                          ? Icon(Icons.check_rounded, color: scheme.primary)
                          : null,
                      selected: isSelected,
                      selectedTileColor: scheme.primaryContainer.withValues(
                        alpha: 0.36,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      onTap: () => Navigator.pop(context, value),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openHistoryDatePicker() async {
    final now = DateTime.now();
    final lastDate = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(const Duration(days: 1));
    final selected = await showDatePicker(
      context: context,
      initialDate: _provider.historyDate.isAfter(lastDate)
          ? lastDate
          : _provider.historyDate,
      firstDate: DateTime(lastDate.year - 3, lastDate.month, lastDate.day),
      lastDate: lastDate,
    );
    if (selected != null) await _provider.selectHistoryDate(selected);
  }

  Future<void> _openEntry(RankingEntry entry) async {
    final navigator = Navigator.of(context);
    showDialog<void>(
      context: context,
      useRootNavigator: false,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );
    try {
      if (entry.audience == RankingAudience.players) {
        final player = await context.read<PlayerService>().getPlayerAndClanData(
          entry.tag,
        );
        navigator.pop();
        if (!mounted) return;
        await navigator.push(
          MaterialPageRoute(
            builder: (context) => PlayerScreen(selectedPlayer: player),
          ),
        );
      } else {
        final clan = await context.read<ClanService>().getClanAndWarData(
          entry.tag,
        );
        navigator.pop();
        if (!mounted) return;
        await navigator.push(
          MaterialPageRoute(
            builder: (context) => ClanInfoScreen(clanInfo: clan),
          ),
        );
      }
    } catch (_) {
      navigator.pop();
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            entry.audience == RankingAudience.players
                ? l10n.rankingsPlayerLoadFailed
                : l10n.rankingsClanLoadFailed,
          ),
        ),
      );
    }
  }
}

class _RankingsHeader extends StatelessWidget {
  const _RankingsHeader({
    required this.provider,
    required this.onAudienceChanged,
  });

  final RankingsProvider provider;
  final ValueChanged<RankingAudience> onAudienceChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDesktop = kIsWeb && MediaQuery.sizeOf(context).width >= 900;
    final height = MediaQuery.paddingOf(context).top + (isDesktop ? 210 : 246);
    return Stack(
      children: [
        Positioned.fill(
          child: InfoHeroBackdrop(
            imageUrl: ImageAssets.legendPageBackground,
            height: height,
          ),
        ),
        SizedBox(
          height: height,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                isDesktop ? 24 : 12,
                0,
                isDesktop ? 24 : 12,
                14,
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      HeaderIconButton(
                        icon: Icons.arrow_back_rounded,
                        iconColor: Colors.white,
                        tooltip: MaterialLocalizations.of(
                          context,
                        ).backButtonTooltip,
                        onTap: () => Navigator.of(context).pop(),
                        showBackground: false,
                      ),
                      const Spacer(),
                      HeaderIconButton(
                        icon: Icons.refresh_rounded,
                        iconColor: Colors.white,
                        tooltip: l10n.sideRefresh,
                        onTap: provider.reload,
                        showBackground: false,
                      ),
                    ],
                  ),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        MobileWebImage(
                          imageUrl: provider.board.iconUrl,
                          width: 58,
                          height: 58,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.sideRankingsTitle,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        Text(
                          l10n.sideRankingsSubtitle,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Colors.white.withValues(alpha: 0.78),
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ),
                  ),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: LiquidGlassSegmentedControl<RankingAudience>(
                      height: 46,
                      values: RankingAudience.values,
                      labels: [l10n.searchTabPlayers, l10n.searchTabClans],
                      selected: provider.audience,
                      color: Colors.white,
                      onChanged: onAudienceChanged,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _RankingsBody extends StatelessWidget {
  const _RankingsBody({
    required this.provider,
    required this.onOpenLocationPicker,
    required this.onOpenTownHallPicker,
    required this.onOpenLeaguePicker,
    required this.onOpenHistoryDatePicker,
    required this.onOpenEntry,
  });

  final RankingsProvider provider;
  final VoidCallback onOpenLocationPicker;
  final VoidCallback onOpenTownHallPicker;
  final VoidCallback onOpenLeaguePicker;
  final VoidCallback onOpenHistoryDatePicker;
  final ValueChanged<RankingEntry> onOpenEntry;

  @override
  Widget build(BuildContext context) {
    final entries = provider.result?.entries ?? const <RankingEntry>[];
    return CustomScrollView(
      key: PageStorageKey(provider.board),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
          sliver: SliverToBoxAdapter(
            child: _RankingControls(
              provider: provider,
              onOpenLocationPicker: onOpenLocationPicker,
              onOpenTownHallPicker: onOpenTownHallPicker,
              onOpenLeaguePicker: onOpenLeaguePicker,
              onOpenHistoryDatePicker: onOpenHistoryDatePicker,
            ),
          ),
        ),
        if (provider.isLoading)
          const SliverToBoxAdapter(
            child: LinearProgressIndicator(minHeight: 2),
          ),
        if (provider.error != null)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
            sliver: SliverToBoxAdapter(
              child: SidePageErrorPanel(
                message: AppLocalizations.of(context)!.sideRankingsLoadError,
                detail: provider.error.toString(),
                onRetry: provider.reload,
              ),
            ),
          )
        else if (!provider.isLoading && entries.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: _RankingEmptyState(provider: provider),
          )
        else ...[
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            sliver: SliverToBoxAdapter(
              child: _RankingResultMeta(provider: provider),
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              16,
              0,
              16,
              24 + MediaQuery.paddingOf(context).bottom,
            ),
            sliver: SliverList.builder(
              itemCount: entries.length,
              itemBuilder: (context, index) => RankingRow(
                key: ValueKey('${provider.board.name}-${entries[index].tag}'),
                entry: entries[index],
                onTap: () => onOpenEntry(entries[index]),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _RankingControls extends StatelessWidget {
  const _RankingControls({
    required this.provider,
    required this.onOpenLocationPicker,
    required this.onOpenTownHallPicker,
    required this.onOpenLeaguePicker,
    required this.onOpenHistoryDatePicker,
  });

  final RankingsProvider provider;
  final VoidCallback onOpenLocationPicker;
  final VoidCallback onOpenTownHallPicker;
  final VoidCallback onOpenLeaguePicker;
  final VoidCallback onOpenHistoryDatePicker;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final controls = <Widget>[];
    if (provider.board.supportsLocation) {
      controls.add(
        _OpaqueFilterButton(
          key: const Key('rankings-location-button'),
          label: l10n.sideLocation,
          value: provider.location.isWorldwide
              ? l10n.rankingsWorldwide
              : provider.location.name,
          icon: Icons.public_rounded,
          imageUrl: provider.location.hasValidCountryCode
              ? ImageAssets.flag(provider.location.countryCode!)
              : null,
          enabled: !provider.isLoadingLocations,
          onTap: onOpenLocationPicker,
        ),
      );
    }
    if (provider.board == RankingBoard.playerTownHall) {
      controls.add(
        _OpaqueFilterButton(
          label: l10n.rankingsTownHall,
          value: 'TH${provider.townHallLevel}',
          imageUrl: ImageAssets.townHall(provider.townHallLevel),
          icon: Icons.home_work_outlined,
          onTap: onOpenTownHallPicker,
        ),
      );
    }
    if (provider.board == RankingBoard.playerRanked) {
      controls.add(
        _OpaqueFilterButton(
          label: l10n.rankingsRankedLeague,
          value: provider.selectedLeague.name,
          imageUrl: provider.selectedLeague.iconUrl,
          icon: Icons.emoji_events_outlined,
          onTap: onOpenLeaguePicker,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (provider.board.supportsHistory) ...[
          LiquidGlassSegmentedControl<RankingPeriod>(
            key: const Key('rankings-period-control'),
            height: 44,
            values: RankingPeriod.values,
            labels: [l10n.rankingsCurrent, l10n.generalHistory],
            selected: provider.period,
            onChanged: provider.selectPeriod,
          ),
          const SizedBox(height: 10),
        ],
        if (provider.period == RankingPeriod.history) ...[
          _OpaqueFilterButton(
            key: const Key('rankings-history-date-button'),
            label: l10n.rankingsSnapshotDate,
            value: DateFormat.yMMMd(
              Localizations.localeOf(context).toLanguageTag(),
            ).format(provider.historyDate),
            icon: Icons.calendar_month_rounded,
            onTap: onOpenHistoryDatePicker,
          ),
          const SizedBox(height: 10),
        ],
        if (controls.isNotEmpty)
          LayoutBuilder(
            builder: (context, constraints) {
              if (controls.length == 1 || constraints.maxWidth < 520) {
                return Column(
                  children: [
                    for (var index = 0; index < controls.length; index++) ...[
                      controls[index],
                      if (index < controls.length - 1)
                        const SizedBox(height: 10),
                    ],
                  ],
                );
              }
              return Row(
                children: [
                  for (var index = 0; index < controls.length; index++) ...[
                    if (index > 0) const SizedBox(width: 10),
                    Expanded(child: controls[index]),
                  ],
                ],
              );
            },
          ),
        if (provider.locationError != null && provider.board.supportsLocation)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              l10n.rankingsLocationsLoadFailed,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }
}

class _OpaqueFilterButton extends StatelessWidget {
  const _OpaqueFilterButton({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
    this.imageUrl,
    this.enabled = true,
  });

  final String label;
  final String value;
  final IconData icon;
  final String? imageUrl;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      enabled: enabled,
      label: '$label: $value',
      child: Material(
        color: scheme.surfaceContainerHigh,
        surfaceTintColor: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            height: 58,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: scheme.outlineVariant.withValues(alpha: 0.48),
              ),
            ),
            child: Row(
              children: [
                if (imageUrl != null)
                  MobileWebImage(imageUrl: imageUrl!, width: 24, height: 24)
                else
                  Icon(icon, size: 23, color: scheme.primary),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.expand_more_rounded),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RankingResultMeta extends StatelessWidget {
  const _RankingResultMeta({required this.provider});

  final RankingsProvider provider;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final result = provider.result!;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        MetricChip(
          label: l10n.rankingsSource,
          value: result.source == RankingSource.official
              ? l10n.rankingsOfficialSource
              : 'ClashKing',
          icon: result.source == RankingSource.official
              ? Icons.verified_rounded
              : Icons.query_stats_rounded,
        ),
        MetricChip(
          label: l10n.rankingsResults,
          value: l10n.rankingsTopCount(result.entries.length),
          icon: Icons.format_list_numbered_rounded,
        ),
        if (provider.board == RankingBoard.playerHome &&
            provider.period == RankingPeriod.current)
          MetricChip(
            label: l10n.sideFilter,
            value: 'TH18 · Legend I',
            imageUrl: ImageAssets.townHall(18),
          ),
        if (provider.period == RankingPeriod.history)
          MetricChip(
            label: l10n.rankingsSnapshotDate,
            value: DateFormat.yMMMd(
              Localizations.localeOf(context).toLanguageTag(),
            ).format(provider.historyDate),
            icon: Icons.history_rounded,
          ),
      ],
    );
  }
}

class _RankingEmptyState extends StatelessWidget {
  const _RankingEmptyState({required this.provider});

  final RankingsProvider provider;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final history = provider.period == RankingPeriod.history;
    return SidePageEmptyState(
      icon: history
          ? Icons.history_toggle_off_rounded
          : Icons.leaderboard_outlined,
      title: history
          ? l10n.rankingsNoSnapshotTitle
          : l10n.sideRankingsEmptyTitle,
      body: history
          ? l10n.rankingsNoSnapshotBody(
              DateFormat.yMMMd(
                Localizations.localeOf(context).toLanguageTag(),
              ).format(provider.historyDate),
            )
          : l10n.sideRankingsEmptyBody,
    );
  }
}

class RankingRow extends StatelessWidget {
  const RankingRow({super.key, required this.entry, required this.onTap});

  final RankingEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final cardColor = Theme.of(context).cardTheme.color ?? scheme.surface;
    final number = NumberFormat.decimalPattern(
      Localizations.localeOf(context).toLanguageTag(),
    );
    return Semantics(
      button: true,
      label: '${entry.rank}. ${entry.name}, ${number.format(entry.score)}',
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 4),
        color: cardColor,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: 0.32),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              children: [
                SizedBox(
                  width: 42,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '#${entry.rank}',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: scheme.onSurfaceVariant,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      if (entry.movement != '=')
                        Text(
                          entry.movement,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: entry.movement.startsWith('+')
                                    ? StatColors.win
                                    : StatColors.loss,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                    ],
                  ),
                ),
                SizedBox.square(
                  dimension: 42,
                  child: MobileWebImage(
                    imageUrl: entry.imageUrl,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (entry.subtitle.isNotEmpty)
                        Text(
                          entry.subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                MobileWebImage(
                  imageUrl: entry.metricImageUrl,
                  width: 19,
                  height: 19,
                ),
                const SizedBox(width: 5),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 74),
                  child: Text(
                    number.format(entry.score),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 2),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: scheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Future<RankingLocation?> showRankingLocationPicker(
  BuildContext context, {
  required List<RankingLocation> locations,
  required RankingLocation selected,
  required bool allowWorldwide,
}) async {
  final controller = TextEditingController();
  final scheme = Theme.of(context).colorScheme;
  final result = await showModalBottomSheet<RankingLocation>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: scheme.surface,
    constraints: const BoxConstraints(maxWidth: 720),
    builder: (context) => StatefulBuilder(
      builder: (context, setState) {
        final query = controller.text.trim().toLowerCase();
        final filtered = locations
            .where((location) {
              if (query.isEmpty || location.isWorldwide) return true;
              return location.name.toLowerCase().contains(query) ||
                  (location.countryCode?.toLowerCase().contains(query) ??
                      false);
            })
            .toList(growable: false);
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.82,
          minChildSize: 0.5,
          maxChildSize: 0.96,
          builder: (context, scrollController) => Column(
            children: [
              const SizedBox(height: 8),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: scheme.onSurfaceVariant.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.rankingsSelectLocation,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      key: const Key('rankings-location-search'),
                      controller: controller,
                      autofocus: true,
                      textInputAction: TextInputAction.search,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: AppLocalizations.of(
                          context,
                        )!.rankingsSearchLocations,
                        prefixIcon: const Icon(Icons.search_rounded),
                        suffixIcon: controller.text.isEmpty
                            ? null
                            : IconButton(
                                tooltip: AppLocalizations.of(
                                  context,
                                )!.searchClear,
                                onPressed: () {
                                  controller.clear();
                                  setState(() {});
                                },
                                icon: const Icon(Icons.clear_rounded),
                              ),
                        filled: true,
                        fillColor: scheme.surfaceContainerHigh,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Text(
                          AppLocalizations.of(
                            context,
                          )!.generalNoFilteredResults,
                        ),
                      )
                    : ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final location = filtered[index];
                          final disabled =
                              location.isWorldwide && !allowWorldwide;
                          final isSelected = location == selected;
                          return Semantics(
                            button: true,
                            selected: isSelected,
                            enabled: !disabled,
                            child: ListTile(
                              key: ValueKey(
                                'ranking-location-${location.apiPath}',
                              ),
                              leading: SizedBox.square(
                                dimension: 32,
                                child: location.hasValidCountryCode
                                    ? MobileWebImage(
                                        imageUrl: ImageAssets.flag(
                                          location.countryCode!,
                                        ),
                                        fit: BoxFit.contain,
                                        errorWidget: (context, url, error) =>
                                            const Icon(Icons.public_rounded),
                                      )
                                    : const Icon(Icons.public_rounded),
                              ),
                              title: Text(
                                location.isWorldwide
                                    ? AppLocalizations.of(
                                        context,
                                      )!.rankingsWorldwide
                                    : location.name,
                              ),
                              subtitle: disabled
                                  ? Text(
                                      AppLocalizations.of(
                                        context,
                                      )!.rankingsWorldwideUnavailable,
                                    )
                                  : null,
                              trailing: isSelected
                                  ? Icon(
                                      Icons.check_rounded,
                                      color: scheme.primary,
                                    )
                                  : null,
                              selected: isSelected,
                              enabled: !disabled,
                              selectedTileColor: scheme.primaryContainer
                                  .withValues(alpha: 0.36),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              onTap: disabled
                                  ? null
                                  : () => Navigator.pop(context, location),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    ),
  );
  controller.dispose();
  return result;
}

extension RankingBoardLabels on RankingBoard {
  String labelOf(AppLocalizations l10n) => switch (this) {
    RankingBoard.playerHome ||
    RankingBoard.clanHome => l10n.rankingsHomeVillage,
    RankingBoard.playerBuilder ||
    RankingBoard.clanBuilder => l10n.rankingsBuilderBase,
    RankingBoard.playerTownHall => l10n.rankingsTownHall,
    RankingBoard.playerRanked => l10n.rankingsRankedLeague,
    RankingBoard.clanCapital => l10n.rankingsClanCapital,
    RankingBoard.clanDonations => l10n.rankingsDonations,
    RankingBoard.clanWarWins => l10n.rankingsWarWins,
    RankingBoard.clanWinStreak => l10n.rankingsWinStreak,
  };
}
