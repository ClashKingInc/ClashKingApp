import 'dart:async';

import 'package:clashkingapp/common/theme/app_tokens.dart';
import 'package:clashkingapp/common/widgets/empty_state.dart';
import 'package:clashkingapp/common/widgets/header_widgets.dart';
import 'package:clashkingapp/common/widgets/info_profile_tabs.dart';
import 'package:clashkingapp/common/widgets/inputs/filter_dropdown.dart';
import 'package:clashkingapp/common/widgets/liquid_glass.dart';
import 'package:clashkingapp/common/widgets/loading/skeleton_loading.dart';
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
        final l10n = AppLocalizations.of(context)!;
        final selectedAudienceIndex = RankingAudience.values
            .indexOf(_provider.audience)
            .clamp(0, RankingAudience.values.length - 1);
        return Scaffold(
          resizeToAvoidBottomInset: false,
          body: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onHorizontalDragEnd: _handleAudienceSwipe,
            child: NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) => [
                SliverToBoxAdapter(child: _RankingsHeader(provider: _provider)),
                SliverToBoxAdapter(
                  child: InfoProfileTabs(
                    selectedIndex: selectedAudienceIndex,
                    onTabSelected: (index) => unawaited(
                      _provider.selectAudience(RankingAudience.values[index]),
                    ),
                    tabs: [
                      InfoProfileTabData(
                        label: l10n.searchTabPlayers,
                        imageUrl: ImageAssets.getTroopImage('Barbarian'),
                      ),
                      InfoProfileTabData(
                        label: l10n.searchTabClans,
                        imageUrl: ImageAssets.clanCastle,
                      ),
                    ],
                  ),
                ),
              ],
              body: _RankingsBody(
                provider: _provider,
                onOpenHistoryDatePicker: _openHistoryDatePicker,
                onOpenEntry: _openEntry,
              ),
            ),
          ),
        );
      },
    );
  }

  void _handleAudienceSwipe(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    if (velocity.abs() < 240) return;
    final selectedIndex = RankingAudience.values.indexOf(_provider.audience);
    final next = velocity < 0 ? selectedIndex + 1 : selectedIndex - 1;
    if (next >= 0 && next < RankingAudience.values.length) {
      unawaited(_provider.selectAudience(RankingAudience.values[next]));
    }
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
  const _RankingsHeader({required this.provider});

  final RankingsProvider provider;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDesktop = kIsWeb && MediaQuery.sizeOf(context).width >= 900;
    final height = MediaQuery.paddingOf(context).top + (isDesktop ? 184 : 216);
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
    required this.onOpenHistoryDatePicker,
    required this.onOpenEntry,
  });

  final RankingsProvider provider;
  final VoidCallback onOpenHistoryDatePicker;
  final ValueChanged<RankingEntry> onOpenEntry;

  @override
  Widget build(BuildContext context) {
    final entries = provider.result?.entries ?? const <RankingEntry>[];
    final hasFilters =
        provider.board.supportsLocation ||
        provider.board.supportsHistory ||
        provider.board == RankingBoard.playerTownHall ||
        provider.board == RankingBoard.playerRanked;
    return CustomScrollView(
      key: PageStorageKey(provider.board),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
          sliver: SliverToBoxAdapter(
            child: _RankingControls(
              provider: provider,
              onOpenHistoryDatePicker: onOpenHistoryDatePicker,
            ),
          ),
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
        else if (provider.isLoading && entries.isEmpty)
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              16,
              hasFilters ? 0 : 12,
              16,
              24 + MediaQuery.paddingOf(context).bottom,
            ),
            sliver: const SliverList(
              delegate: SliverChildBuilderDelegate(
                _buildRankingSkeletonRow,
                childCount: 8,
              ),
            ),
          )
        else if (!provider.isLoading && entries.isEmpty)
          SliverPadding(
            padding: EdgeInsets.only(
              bottom: 24 + MediaQuery.paddingOf(context).bottom,
            ),
            sliver: SliverToBoxAdapter(
              child: _RankingEmptyState(provider: provider),
            ),
          )
        else ...[
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              16,
              hasFilters ? 0 : 12,
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

class _BoardFilterDropdown extends StatelessWidget {
  const _BoardFilterDropdown({required this.provider});

  final RankingsProvider provider;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final boards = provider.boards;
    final options = <dynamic, String>{
      for (final board in boards)
        _imageDropdownLabel(board.iconUrl, board.labelOf(l10n)): board.name,
    };

    return FilterDropdown(
      key: const Key('rankings-board-dropdown'),
      sortBy: provider.board.name,
      updateSortBy: (value) {
        for (final board in boards) {
          if (board.name == value) {
            unawaited(provider.selectBoard(board));
            return;
          }
        }
      },
      sortByOptions: options,
      height: 46,
      fillWidth: true,
    );
  }
}

class _LocationFilterDropdown extends StatelessWidget {
  const _LocationFilterDropdown({super.key, required this.provider});

  final RankingsProvider provider;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final supportedLocations = provider.locations
        .where(
          (location) =>
              provider.board.supportsWorldwide || !location.isWorldwide,
        )
        .toList(growable: false);
    final locations = supportedLocations.isEmpty
        ? provider.locations
        : supportedLocations;
    final selectedApiPath =
        locations.any(
          (location) => location.apiPath == provider.location.apiPath,
        )
        ? provider.location.apiPath
        : locations.first.apiPath;
    final options = <dynamic, String>{
      for (final location in locations)
        _locationDropdownLabel(context, l10n, location): location.apiPath,
    };

    return FilterDropdown(
      sortBy: selectedApiPath,
      updateSortBy: (value) {
        for (final location in locations) {
          if (location.apiPath == value) {
            unawaited(provider.selectLocation(location));
            return;
          }
        }
      },
      sortByOptions: options,
      height: 46,
      maxWidth: 132,
    );
  }
}

class _TownHallFilterDropdown extends StatelessWidget {
  const _TownHallFilterDropdown({required this.provider});

  final RankingsProvider provider;

  @override
  Widget build(BuildContext context) {
    final options = <dynamic, String>{
      for (final level in List<int>.generate(12, (index) => 18 - index))
        _imageDropdownLabel(ImageAssets.townHall(level), 'TH$level'): level
            .toString(),
    };

    return FilterDropdown(
      sortBy: provider.townHallLevel.toString(),
      updateSortBy: (value) =>
          unawaited(provider.selectTownHall(int.parse(value))),
      sortByOptions: options,
      height: 46,
      maxWidth: 132,
    );
  }
}

class _LeagueFilterDropdown extends StatelessWidget {
  const _LeagueFilterDropdown({required this.provider});

  final RankingsProvider provider;

  @override
  Widget build(BuildContext context) {
    final options = <dynamic, String>{
      for (final league in provider.leagueOptions)
        _imageDropdownLabel(league.iconUrl, league.name): league.id.toString(),
    };

    return FilterDropdown(
      sortBy: provider.selectedLeague.id.toString(),
      updateSortBy: (value) {
        final id = int.tryParse(value);
        for (final league in provider.leagueOptions) {
          if (league.id == id) {
            unawaited(provider.selectLeague(league));
            return;
          }
        }
      },
      sortByOptions: options,
      height: 46,
      maxWidth: 132,
    );
  }
}

List<Widget> _imageDropdownLabel(String imageUrl, String label) {
  return [
    MobileWebImage(imageUrl: imageUrl, width: 20, height: 20),
    const SizedBox(width: 7),
    Expanded(
      child: Text(
        label,
        maxLines: 1,
        softWrap: false,
        overflow: TextOverflow.ellipsis,
      ),
    ),
  ];
}

List<Widget> _locationDropdownLabel(
  BuildContext context,
  AppLocalizations l10n,
  RankingLocation location,
) {
  return [
    SizedBox.square(
      dimension: 20,
      child: location.hasValidCountryCode
          ? MobileWebImage(
              imageUrl: ImageAssets.flag(location.countryCode!),
              fit: BoxFit.contain,
              errorWidget: (context, url, error) =>
                  const Icon(Icons.public_rounded, size: 18),
            )
          : const Icon(Icons.public_rounded, size: 18),
    ),
    const SizedBox(width: 7),
    Expanded(
      child: Text(
        location.isWorldwide ? l10n.rankingsWorldwide : location.name,
        maxLines: 1,
        softWrap: false,
        overflow: TextOverflow.ellipsis,
      ),
    ),
  ];
}

class _RankingControls extends StatelessWidget {
  const _RankingControls({
    required this.provider,
    required this.onOpenHistoryDatePicker,
  });

  final RankingsProvider provider;
  final VoidCallback onOpenHistoryDatePicker;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final filters = <Widget>[];
    if (provider.board.supportsLocation) {
      filters.add(
        _LocationFilterDropdown(
          key: const Key('rankings-location-button'),
          provider: provider,
        ),
      );
    }
    if (provider.board == RankingBoard.playerTownHall) {
      filters.add(_TownHallFilterDropdown(provider: provider));
    }
    if (provider.board == RankingBoard.playerRanked) {
      filters.add(_LeagueFilterDropdown(provider: provider));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _BoardAndFilterRow(provider: provider, filters: filters),
        if (provider.board.supportsHistory) ...[
          const SizedBox(height: 8),
          _PeriodControls(
            provider: provider,
            onOpenHistoryDatePicker: onOpenHistoryDatePicker,
          ),
        ],
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

class _BoardAndFilterRow extends StatelessWidget {
  const _BoardAndFilterRow({required this.provider, required this.filters});

  final RankingsProvider provider;
  final List<Widget> filters;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final boardDropdown = _BoardFilterDropdown(provider: provider);
        if (filters.isEmpty) {
          return boardDropdown;
        }

        const spacing = 8.0;
        if (filters.length == 1 && constraints.maxWidth >= 320) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: boardDropdown),
              const SizedBox(width: spacing),
              SizedBox(width: 132, child: filters.single),
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            boardDropdown,
            const SizedBox(height: 8),
            if (filters.length == 1)
              filters.single
            else
              Row(
                children: [
                  for (var index = 0; index < filters.length; index++) ...[
                    if (index > 0) const SizedBox(width: 8),
                    Expanded(child: filters[index]),
                  ],
                ],
              ),
          ],
        );
      },
    );
  }
}

class _PeriodControls extends StatelessWidget {
  const _PeriodControls({
    required this.provider,
    required this.onOpenHistoryDatePicker,
  });

  final RankingsProvider provider;
  final VoidCallback onOpenHistoryDatePicker;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppFilterSegmentedControl<RankingPeriod>(
          key: const Key('rankings-period-control'),
          values: const [RankingPeriod.current, RankingPeriod.history],
          labels: [l10n.rankingsCurrent, l10n.generalHistory],
          iconWidgets: [
            _segmentAssetIcon(ImageAssets.trophies),
            _segmentAssetIcon(ImageAssets.iconClock),
          ],
          selected: provider.period,
          onChanged: (value) => unawaited(provider.selectPeriod(value)),
        ),
        if (provider.period == RankingPeriod.history) ...[
          const SizedBox(height: 8),
          _OpaqueFilterButton(
            key: const Key('rankings-history-date-button'),
            label: l10n.rankingsSnapshotDate,
            value: DateFormat.yMMMd(
              Localizations.localeOf(context).toLanguageTag(),
            ).format(provider.historyDate),
            icon: Icons.calendar_month_rounded,
            onTap: onOpenHistoryDatePicker,
            height: 52,
          ),
        ],
      ],
    );
  }
}

Widget _segmentAssetIcon(String imageUrl) {
  return MobileWebImage(imageUrl: imageUrl, width: 18, height: 18);
}

class _OpaqueFilterButton extends StatelessWidget {
  const _OpaqueFilterButton({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
    this.height = 52,
  });

  final String label;
  final String value;
  final IconData icon;
  final VoidCallback onTap;
  final double height;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      label: '$label: $value',
      child: Material(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.45),
        surfaceTintColor: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.chip),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.chip),
          child: Container(
            height: height,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.chip),
              border: Border.all(
                color: scheme.outlineVariant.withValues(alpha: 0.32),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, size: 21, color: scheme.primary),
                const SizedBox(width: 10),
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

class _RankingEmptyState extends StatelessWidget {
  const _RankingEmptyState({required this.provider});

  final RankingsProvider provider;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final history = provider.period == RankingPeriod.history;
    return AppEmptyState(
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

Widget _buildRankingSkeletonRow(BuildContext context, int index) {
  return const _RankingSkeletonRow();
}

class _RankingSkeletonRow extends StatelessWidget {
  const _RankingSkeletonRow();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final cardColor = Theme.of(context).cardTheme.color ?? scheme.surface;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      color: cardColor,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.chip),
        side: BorderSide(
          color: scheme.outlineVariant.withValues(alpha: AppOpacity.border),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        child: Row(
          children: [
            SizedBox(
              width: 40,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonLoader(
                    width: 24,
                    height: 14,
                    borderRadius: BorderRadius.circular(7),
                  ),
                  const SizedBox(height: 5),
                  SkeletonLoader(
                    width: 18,
                    height: 10,
                    borderRadius: BorderRadius.circular(5),
                  ),
                ],
              ),
            ),
            SkeletonLoader(
              width: 40,
              height: 40,
              borderRadius: BorderRadius.circular(10),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FractionallySizedBox(
                    widthFactor: 0.68,
                    child: SkeletonLoader(
                      height: 16,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(height: 7),
                  FractionallySizedBox(
                    widthFactor: 0.46,
                    child: SkeletonLoader(
                      height: 12,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            SkeletonLoader(
              width: 19,
              height: 19,
              borderRadius: BorderRadius.circular(5),
            ),
            const SizedBox(width: 6),
            SkeletonLoader(
              width: 50,
              height: 16,
              borderRadius: BorderRadius.circular(8),
            ),
            const SizedBox(width: 22),
          ],
        ),
      ),
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
          borderRadius: BorderRadius.circular(AppRadius.chip),
          side: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: AppOpacity.border),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            child: Row(
              children: [
                SizedBox(
                  width: 40,
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
                    children: [
                      Text(
                        entry.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (entry.subtitle.isNotEmpty ||
                          entry.clanBadgeUrl.isNotEmpty)
                        Row(
                          children: [
                            if (entry.clanBadgeUrl.isNotEmpty) ...[
                              MobileWebImage(
                                imageUrl: entry.clanBadgeUrl,
                                width: 17,
                                height: 17,
                                fit: BoxFit.contain,
                              ),
                              const SizedBox(width: 5),
                            ],
                            if (entry.subtitle.isNotEmpty)
                              Expanded(
                                child: Text(
                                  entry.subtitle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.labelMedium
                                      ?.copyWith(
                                        color: scheme.onSurfaceVariant,
                                      ),
                                ),
                              ),
                          ],
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
            .where(
              (location) =>
                  location.isWorldwide || location.hasValidCountryCode,
            )
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
                      autofocus: false,
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
