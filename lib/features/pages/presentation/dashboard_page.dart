import 'dart:math' as math;

import 'package:clashking_design_system/clashking_design_system.dart';
import 'package:clashkingapp/common/theme/app_tokens.dart';
import 'package:clashkingapp/common/widgets/mobile_web_image.dart';
import 'package:clashkingapp/core/app/my_app_state.dart';
import 'package:clashkingapp/core/config/app_feature_flags.dart';
import 'package:clashkingapp/core/constants/image_assets.dart';
import 'package:clashkingapp/core/services/player_card_preferences_service.dart';
import 'package:clashkingapp/features/auth/data/auth_service.dart';
import 'package:clashkingapp/features/coc_accounts/data/coc_account_service.dart';
import 'package:clashkingapp/features/coc_accounts/presentation/coc_account_management_page.dart';
import 'package:clashkingapp/features/pages/widgets/home_todo_card.dart';
import 'package:clashkingapp/features/player/data/player_service.dart';
import 'package:clashkingapp/features/player/models/player.dart';
import 'package:clashkingapp/features/player/models/player_ranked_league.dart';
import 'package:clashkingapp/features/player/presentation/ranked/player_ranked_league_page.dart';
import 'package:clashkingapp/features/upgrade_tracker/data/upgrade_tracker_repository.dart';
import 'package:clashkingapp/features/upgrade_tracker/models/upgrade_tracker_models.dart';
import 'package:clashkingapp/features/upgrade_tracker/presentation/upgrade_tracker_page.dart';
import 'package:clashkingapp/common/widgets/empty_state.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

void _animateHomeCardPagerTo(
  BuildContext context,
  PageController controller,
  int page,
) {
  if (!controller.hasClients) return;
  if (CKMotion.animationsDisabled(context)) {
    controller.jumpToPage(page);
    return;
  }
  controller.animateToPage(
    page,
    duration: CKMotion.fast,
    curve: CKMotion.standardCurve,
  );
}

/// Same dot-pager language as the home to-do card, so swipeable Ranked and
/// Upgrade Tracker cards read as part of the same family.
class _HomeCardPageDots extends StatelessWidget {
  const _HomeCardPageDots({
    required this.count,
    required this.index,
    this.onDotTap,
  });

  final int count;
  final int index;
  final ValueChanged<int>? onDotTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(count, (dotIndex) {
        final selected = dotIndex == index;
        final dot = AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: selected ? 18 : 7,
          height: 7,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: selected
                ? colorScheme.onSurface
                : colorScheme.onSurface.withValues(alpha: 0.24),
            borderRadius: BorderRadius.circular(999),
          ),
        );
        if (onDotTap == null) return dot;
        return InkResponse(
          radius: 14,
          onTap: () => onDotTap!(dotIndex),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 1, vertical: 8),
            child: dot,
          ),
        );
      }),
    );
  }
}

/// Flat bordered shell for a non-paginated (loading/empty) home card state.
class _HomeCardFrame extends StatelessWidget {
  const _HomeCardFrame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 1),
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.32),
          ),
        ),
        padding: const EdgeInsets.all(14),
        child: child,
      ),
    );
  }
}

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final playerService = context.watch<PlayerService>();
    final cocService = context.watch<CocAccountService>();
    final cardPrefs = context.watch<PlayerCardPreferencesService>();
    final appState = context.watch<MyAppState>();
    final upgradeTrackerEnabled = appState.isFeatureEnabled(
      AppFeatureFlags.upgradeTracker,
    );
    final players = playerService.profiles;
    final linkedTags = cocService.verifiedAccounts
        .map(
          (account) => _normalizeTag(account['player_tag']?.toString() ?? ''),
        )
        .where((tag) => tag.isNotEmpty)
        .toSet();
    final linkedPlayers = players
        .where((player) => linkedTags.contains(_normalizeTag(player.tag)))
        .toList(growable: false);
    // "Show on to-do page" also controls whether an account's card shows up
    // on the home to-do pager — only allPlayers (used to build the full
    // to-do screen) keeps every linked account, since that screen applies
    // its own copy of this same filter.
    final todoPlayers = linkedPlayers
        .where((player) => cardPrefs.isShownInTodoPage(player.tag))
        .toList(growable: false);
    final upgradePlayers = upgradeTrackerEnabled
        ? linkedPlayers
              .where(
                (player) => cardPrefs.isUpgradeTrackerShownOnHome(player.tag),
              )
              .toList(growable: false)
        : const <Player>[];
    final rankedPlayers = linkedPlayers
        .where((player) => cardPrefs.isRankedShownOnHome(player.tag))
        .toList(growable: false);
    final isDesktopWeb = kIsWeb && MediaQuery.sizeOf(context).width >= 900;
    final bottomPadding = isDesktopWeb
        ? 32.0
        : MediaQuery.paddingOf(context).bottom + 96;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final maxContentWidth = isDesktopWeb ? 1320.0 : 840.0;
            final horizontalPadding =
                ((constraints.maxWidth - maxContentWidth) / 2)
                    .clamp(16.0, double.infinity)
                    .toDouble();

            return ListView(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                12,
                horizontalPadding,
                bottomPadding,
              ),
              children: [
                const HomeEventBanner(),
                SizedBox(height: isDesktopWeb ? 24 : 16),
                if (playerService.isLoading && linkedPlayers.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 48),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (linkedPlayers.isEmpty)
                  _EmptyDashboard(
                    title: AppLocalizations.of(
                      context,
                    )!.dashboardNoLinkedAccountsTitle,
                    message: AppLocalizations.of(
                      context,
                    )!.dashboardNoLinkedAccountsBody,
                    icon: Icons.account_circle_outlined,
                    actionLabel: AppLocalizations.of(
                      context,
                    )!.drawerManageAccounts,
                    onAction: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) =>
                            const AddCocAccountPage(refreshOnExit: false),
                      ),
                    ),
                  )
                else if (todoPlayers.isEmpty &&
                    upgradePlayers.isEmpty &&
                    rankedPlayers.isEmpty)
                  _EmptyDashboard(
                    title: AppLocalizations.of(
                      context,
                    )!.dashboardTodoHiddenTitle,
                    message: AppLocalizations.of(
                      context,
                    )!.dashboardTodoHiddenBody,
                    icon: Icons.visibility_off_outlined,
                  )
                else ...[
                  if (todoPlayers.isNotEmpty)
                    HomeTodoCard(
                      players: todoPlayers,
                      allPlayers: linkedPlayers,
                    ),
                  if (todoPlayers.isNotEmpty && rankedPlayers.isNotEmpty)
                    SizedBox(height: isDesktopWeb ? 16 : 12),
                  if (rankedPlayers.isNotEmpty)
                    HomeRankedCard(players: rankedPlayers),
                  if ((todoPlayers.isNotEmpty || rankedPlayers.isNotEmpty) &&
                      upgradePlayers.isNotEmpty)
                    SizedBox(height: isDesktopWeb ? 16 : 12),
                  if (upgradePlayers.isNotEmpty)
                    HomeUpgradeTrackerCard(players: upgradePlayers),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  static String _normalizeTag(String tag) =>
      tag.replaceAll('#', '').trim().toUpperCase();
}

class HomeRankedCard extends StatefulWidget {
  const HomeRankedCard({super.key, required this.players});

  final List<Player> players;

  @override
  State<HomeRankedCard> createState() => _HomeRankedCardState();
}

class _HomeRankedCardState extends State<HomeRankedCard> {
  Future<_RankedHomeSummary>? _load;
  String _signature = '';
  late final PageController _controller;
  int _index = 0;
  bool _showLoadingIndicator = false;

  @override
  void initState() {
    super.initState();
    _controller = PageController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reloadIfNeeded();
  }

  @override
  void didUpdateWidget(covariant HomeRankedCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    _reloadIfNeeded();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _reloadIfNeeded() {
    final signature = widget.players.map((player) => player.tag).join('|');
    if (_load != null && signature == _signature) return;
    _signature = signature;
    _showLoadingIndicator = false;
    final load = _loadSummary();
    _load = load;
    // Only surface the spinner once a load is genuinely slow, so a fast
    // (typically cached) response never flashes a loading state at all.
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted && _load == load) {
        setState(() => _showLoadingIndicator = true);
      }
    });
  }

  Future<_RankedHomeSummary> _loadSummary() async {
    final playerService = context.read<PlayerService>();
    final accounts = <_RankedHomeAccount>[];
    for (final player in widget.players) {
      try {
        final data = await playerService.loadRankedLeagueData(player.tag);
        if (data.currentTier == null && data.history.isEmpty) continue;
        accounts.add(_RankedHomeAccount.fromData(data, player: player));
      } catch (_) {
        // Keep Home resilient; the full Ranked League page surfaces errors.
      }
    }
    return _RankedHomeSummary(
      configuredCount: widget.players.length,
      accounts: accounts,
    );
  }

  void _openRankedLeague(Player player) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PlayerRankedLeagueScreen(player: player),
      ),
    );
  }

  void _showPage(int count, int page) {
    if (count <= 0) return;
    final next = page % count;
    setState(() => _index = next);
    _animateHomeCardPagerTo(context, _controller, next);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_RankedHomeSummary>(
      future: _load,
      builder: (context, snapshot) {
        final summary = snapshot.data;
        final loading = snapshot.connectionState == ConnectionState.waiting;
        if (loading) {
          if (!_showLoadingIndicator) return const SizedBox.shrink();
          return const _HomeCardFrame(child: _RankedHomeLoading());
        }
        if (summary == null || summary.accounts.isEmpty) {
          return _HomeCardFrame(
            child: _RankedHomeEmpty(configuredCount: widget.players.length),
          );
        }

        // A combined "all accounts" page leads when several accounts are
        // pinned, matching the home to-do card's pattern.
        final hasSummaryPage = summary.accounts.length > 1;
        final itemCount = summary.accounts.length + (hasSummaryPage ? 1 : 0);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 158,
              child: PageView.builder(
                controller: _controller,
                onPageChanged: (index) => setState(() => _index = index),
                itemCount: itemCount,
                itemBuilder: (context, index) {
                  if (hasSummaryPage && index == 0) {
                    return _RankedAllAccountsPanel(
                      summary: summary,
                      onTap: () =>
                          _openRankedLeague(summary.accounts.first.player),
                    );
                  }
                  final account =
                      summary.accounts[index - (hasSummaryPage ? 1 : 0)];
                  return _RankedAccountPanel(
                    account: account,
                    onTap: () => _openRankedLeague(account.player),
                  );
                },
              ),
            ),
            if (itemCount > 1) ...[
              const SizedBox(height: 8),
              Center(
                child: _HomeCardPageDots(
                  count: itemCount,
                  index: _index,
                  onDotTap: (index) => _showPage(itemCount, index),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _RankedAccountPanel extends StatelessWidget {
  const _RankedAccountPanel({required this.account, required this.onTap});

  final _RankedHomeAccount account;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final locale = Localizations.localeOf(context).toString();
    final formatter = NumberFormat('#,###', locale);
    final rankText = account.rank == null
        ? loc.rankedLeagueNoGroup
        : '${loc.rankedLeagueGroupRank} #${formatter.format(account.rank)}';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 1),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(28),
          child: Ink(
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: colorScheme.outlineVariant.withValues(alpha: 0.32),
              ),
            ),
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    SizedBox.square(
                      dimension: 46,
                      child: account.tierIconUrl.isEmpty
                          ? const Icon(Icons.emoji_events_rounded)
                          : MobileWebImage(
                              imageUrl: account.tierIconUrl,
                              fit: BoxFit.contain,
                              errorWidget: (_, _, _) =>
                                  const Icon(Icons.emoji_events_rounded),
                            ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            loc.rankedLeagueTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(fontWeight: FontWeight.w900),
                          ),
                          Text(
                            account.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.labelLarge
                                ?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ],
                      ),
                    ),
                    _RankedTrophyPill(
                      value: formatter.format(account.trophies),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        rankText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 22,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _RankedHomeMetricBars(
                  metrics: [
                    _RankedHomeMetricData(
                      imageUrl: ImageAssets.sword,
                      fallbackIcon: Icons.sports_kabaddi_rounded,
                      label: loc.rankedLeagueAttacks,
                      done: account.attacksDone,
                      total:
                          account.maxBattles ??
                          math.max(account.attacksDone, 1),
                      color: CKColors.lossRed,
                    ),
                    _RankedHomeMetricData(
                      imageUrl: ImageAssets.shieldWithArrow,
                      fallbackIcon: Icons.shield_rounded,
                      label: loc.rankedLeagueDefenses,
                      done: account.defensesDone,
                      total:
                          account.maxBattles ??
                          math.max(account.defensesDone, 1),
                      color: CKColors.legendBlue,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Leading page when several accounts are pinned: combined attack/defense
/// totals across all of them, same recipe as the home to-do card's summary.
class _RankedAllAccountsPanel extends StatelessWidget {
  const _RankedAllAccountsPanel({required this.summary, required this.onTap});

  final _RankedHomeSummary summary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 1),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(28),
          child: Ink(
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: colorScheme.outlineVariant.withValues(alpha: 0.32),
              ),
            ),
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    SizedBox.square(
                      dimension: 46,
                      child: MobileWebImage(
                        imageUrl: ImageAssets.shieldWithArrow,
                        fit: BoxFit.contain,
                        errorWidget: (_, _, _) =>
                            const Icon(Icons.emoji_events_rounded),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            loc.rankedLeagueTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(fontWeight: FontWeight.w900),
                          ),
                          Text(
                            _rankedSummarySubtitle(context, summary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.labelLarge
                                ?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ],
                      ),
                    ),
                    if (summary.bestRank != null)
                      _RankedBestRankPill(rank: summary.bestRank!),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _rankedSummaryStatus(context, summary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 22,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _RankedHomeMetricBars(
                  metrics: [
                    _RankedHomeMetricData(
                      imageUrl: ImageAssets.sword,
                      fallbackIcon: Icons.sports_kabaddi_rounded,
                      label: loc.rankedLeagueAttacks,
                      done: summary.totalAttacksDone,
                      total: summary.totalAttacksMax,
                      color: CKColors.lossRed,
                    ),
                    _RankedHomeMetricData(
                      imageUrl: ImageAssets.shieldWithArrow,
                      fallbackIcon: Icons.shield_rounded,
                      label: loc.rankedLeagueDefenses,
                      done: summary.totalDefensesDone,
                      total: summary.totalDefensesMax,
                      color: CKColors.legendBlue,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RankedHomeEmpty extends StatelessWidget {
  const _RankedHomeEmpty({required this.configuredCount});

  final int configuredCount;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        SizedBox.square(
          dimension: 46,
          child: MobileWebImage(
            imageUrl: ImageAssets.shieldWithArrow,
            fit: BoxFit.contain,
            errorWidget: (_, _, _) => const Icon(Icons.emoji_events_rounded),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                loc.rankedLeagueTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
              Text(
                loc.dashboardRankedNoData,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
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

class _RankedHomeLoading extends StatelessWidget {
  const _RankedHomeLoading();

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Row(
      children: [
        const SizedBox.square(
          dimension: 42,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            loc.rankedLeagueTitle,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
        ),
      ],
    );
  }
}

class _RankedTrophyPill extends StatelessWidget {
  const _RankedTrophyPill({required this.value});

  final String value;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.48),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox.square(
              dimension: 18,
              child: MobileWebImage(
                imageUrl: ImageAssets.trophies,
                fit: BoxFit.contain,
                errorWidget: (_, _, _) => Icon(
                  Icons.emoji_events_rounded,
                  size: 16,
                  color: CKColors.warGold,
                ),
              ),
            ),
            const SizedBox(width: 5),
            Text(
              value,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RankedBestRankPill extends StatelessWidget {
  const _RankedBestRankPill({required this.rank});

  final int rank;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: CKColors.warGold.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.leaderboard_rounded, size: 16, color: CKColors.warGold),
            const SizedBox(width: 5),
            Text(
              '${loc.rankedLeagueBestGroupRank} #$rank',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RankedHomeMetricData {
  const _RankedHomeMetricData({
    required this.imageUrl,
    required this.fallbackIcon,
    required this.label,
    required this.done,
    required this.total,
    required this.color,
  });

  final String imageUrl;
  final IconData fallbackIcon;
  final String label;
  final int done;
  final int total;
  final Color color;

  double get ratio => total <= 0 ? 0 : (done / total).clamp(0.0, 1.0);
}

class _RankedHomeMetricBars extends StatelessWidget {
  const _RankedHomeMetricBars({required this.metrics});

  final List<_RankedHomeMetricData> metrics;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < metrics.length; i += 2) {
      if (i + 1 < metrics.length) {
        rows.add(
          Row(
            children: [
              Expanded(child: _RankedHomeMetricBar(metric: metrics[i])),
              const SizedBox(width: 7),
              Expanded(child: _RankedHomeMetricBar(metric: metrics[i + 1])),
            ],
          ),
        );
      } else {
        rows.add(_RankedHomeMetricBar(metric: metrics[i]));
      }
    }

    return Column(
      children: [
        for (var i = 0; i < rows.length; i++) ...[
          if (i > 0) const SizedBox(height: 7),
          rows[i],
        ],
      ],
    );
  }
}

class _RankedHomeMetricBar extends StatelessWidget {
  const _RankedHomeMetricBar({required this.metric});

  final _RankedHomeMetricData metric;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fillColor = metric.done >= metric.total ? Colors.green : metric.color;

    return SizedBox(
      height: 38,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: fillColor.withValues(alpha: isDark ? 0.28 : 0.34),
          borderRadius: BorderRadius.circular(AppRadius.control),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.control),
          child: Stack(
            fit: StackFit.expand,
            children: [
              FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: metric.ratio,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: fillColor.withValues(alpha: isDark ? 0.38 : 0.48),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 9),
                child: Row(
                  children: [
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: colorScheme.surface.withValues(alpha: 0.72),
                        shape: BoxShape.circle,
                      ),
                      child: SizedBox.square(
                        dimension: 26,
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: MobileWebImage(
                            imageUrl: metric.imageUrl,
                            fit: BoxFit.contain,
                            errorWidget: (context, url, error) => Icon(
                              metric.fallbackIcon,
                              size: 18,
                              color: metric.color,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Semantics(
                        label:
                            '${metric.label}, ${metric.done}/${metric.total}',
                        child: ExcludeSemantics(
                          child: Text(
                            metric.label,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.labelLarge
                                ?.copyWith(
                                  color: colorScheme.onSurface,
                                  fontWeight: FontWeight.w900,
                                  height: 1.1,
                                ),
                          ),
                        ),
                      ),
                    ),
                    Text(
                      '${metric.done}/${metric.total}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: fillColor,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RankedHomeSummary {
  const _RankedHomeSummary({
    required this.configuredCount,
    required this.accounts,
  });

  final int configuredCount;
  final List<_RankedHomeAccount> accounts;

  int get totalAttacksDone =>
      accounts.fold(0, (sum, account) => sum + account.attacksDone);

  int get totalAttacksMax => accounts.fold(
    0,
    (sum, account) =>
        sum + (account.maxBattles ?? math.max(account.attacksDone, 1)),
  );

  int get totalDefensesDone =>
      accounts.fold(0, (sum, account) => sum + account.defensesDone);

  int get totalDefensesMax => accounts.fold(
    0,
    (sum, account) =>
        sum + (account.maxBattles ?? math.max(account.defensesDone, 1)),
  );

  /// The best rank currently held among your accounts (not an all-time
  /// record), since that's what's actionable from a home recap card.
  int? get bestRank {
    int? best;
    for (final account in accounts) {
      final rank = account.rank;
      if (rank == null) continue;
      if (best == null || rank < best) best = rank;
    }
    return best;
  }
}

class _RankedHomeAccount {
  const _RankedHomeAccount({
    required this.player,
    required this.name,
    required this.tierIconUrl,
    required this.trophies,
    required this.rank,
    required this.attacksDone,
    required this.defensesDone,
    required this.maxBattles,
  });

  final Player player;
  final String name;
  final String tierIconUrl;
  final int trophies;
  final int? rank;
  final int attacksDone;
  final int defensesDone;
  final int? maxBattles;

  factory _RankedHomeAccount.fromData(
    RankedLeagueData data, {
    required Player player,
  }) {
    final tier = data.currentTier;
    final member = data.currentMember;
    return _RankedHomeAccount(
      player: player,
      name: data.playerName,
      tierIconUrl: tier?.smallIconUrl.isNotEmpty == true
          ? tier!.smallIconUrl
          : tier?.largeIconUrl ?? '',
      trophies: member?.leagueTrophies ?? data.trophies,
      rank: data.currentRank,
      attacksDone: member == null
          ? 0
          : member.attackWinCount + member.attackLoseCount,
      defensesDone: member == null
          ? 0
          : member.defenseWinCount + member.defenseLoseCount,
      maxBattles: data.currentMaxBattles,
    );
  }
}

String _rankedSummarySubtitle(
  BuildContext context,
  _RankedHomeSummary summary,
) {
  final loc = AppLocalizations.of(context)!;
  return loc.todoAccountsNumber(summary.accounts.length);
}

/// Names the accounts that still have ranked attacks left today, falling
/// back to a generic combined label once every account is caught up.
String _rankedSummaryStatus(BuildContext context, _RankedHomeSummary summary) {
  final loc = AppLocalizations.of(context)!;
  final incomplete = summary.accounts
      .where((account) {
        final maxBattles = account.maxBattles;
        if (maxBattles == null) return false;
        return account.attacksDone < maxBattles;
      })
      .toList(growable: false);
  if (incomplete.isEmpty) return loc.dashboardRankedCombinedAcrossAccounts;

  final visibleNames = incomplete
      .take(3)
      .map((account) => account.name.trim())
      .where((name) => name.isNotEmpty)
      .toList(growable: false);
  final remaining = incomplete.length - visibleNames.length;
  final suffix = remaining > 0 ? ', +$remaining' : '';
  final subject = visibleNames.isEmpty
      ? loc.todoAccountsNumber(incomplete.length)
      : '${visibleNames.join(', ')}$suffix';
  return loc.dashboardRankedAccountsHaveAttacksLeft(subject, incomplete.length);
}

class HomeUpgradeTrackerCard extends StatefulWidget {
  const HomeUpgradeTrackerCard({super.key, required this.players});

  final List<Player> players;

  @override
  State<HomeUpgradeTrackerCard> createState() => _HomeUpgradeTrackerCardState();
}

class _HomeUpgradeTrackerCardState extends State<HomeUpgradeTrackerCard> {
  final _repository = UpgradeTrackerRepository();
  Future<_UpgradeHomeSummary>? _load;
  String _signature = '';
  late final PageController _controller;
  int _index = 0;
  bool _showLoadingIndicator = false;

  @override
  void initState() {
    super.initState();
    _controller = PageController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reloadIfNeeded();
  }

  @override
  void didUpdateWidget(covariant HomeUpgradeTrackerCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    _reloadIfNeeded();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _reloadIfNeeded() {
    final signature = widget.players
        .map((player) => UpgradeTrackerRepository.normalizeTag(player.tag))
        .join('|');
    if (_load != null && signature == _signature) return;
    _signature = signature;
    _showLoadingIndicator = false;
    final load = _loadSummary();
    _load = load;
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted && _load == load) {
        setState(() => _showLoadingIndicator = true);
      }
    });
  }

  Future<_UpgradeHomeSummary> _loadSummary() async {
    final cocService = context.read<CocAccountService>();
    _repository.configureRemote(
      accountId: context.read<AuthService>().currentUser?.userId,
      verifiedPlayerTags: cocService.verifiedAccounts.map(
        (account) => account['player_tag']?.toString() ?? '',
      ),
    );

    final accounts = <_UpgradeHomeAccount>[];
    final missingAccounts = <Player>[];
    for (final player in widget.players) {
      try {
        final snapshot = await _repository.load(player.tag);
        if (snapshot == null) {
          missingAccounts.add(player);
          continue;
        }
        accounts.add(_UpgradeHomeAccount.fromSnapshot(snapshot));
      } catch (_) {
        // Surfaced as a "needs import" page instead of being dropped silently.
        missingAccounts.add(player);
      }
    }
    return _UpgradeHomeSummary(
      configuredCount: widget.players.length,
      accounts: accounts,
      missingAccounts: missingAccounts,
    );
  }

  void _openTracker() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const UpgradeTrackerPage()));
  }

  void _showPage(int count, int page) {
    if (count <= 0) return;
    final next = page % count;
    setState(() => _index = next);
    _animateHomeCardPagerTo(context, _controller, next);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_UpgradeHomeSummary>(
      future: _load,
      builder: (context, snapshot) {
        final summary = snapshot.data;
        final loading = snapshot.connectionState == ConnectionState.waiting;
        if (loading) {
          if (!_showLoadingIndicator) return const SizedBox.shrink();
          return const _HomeCardFrame(child: _UpgradeHomeLoading());
        }
        if (summary == null) {
          return _HomeCardFrame(
            child: _UpgradeHomeEmpty(configuredCount: widget.players.length),
          );
        }

        // A combined "all accounts" page leads when several accounts have
        // imported data, matching the home to-do card's pattern. Accounts
        // without imported data still get their own page, prompting import
        // instead of silently disappearing from the pager.
        final hasSummaryPage = summary.accounts.length > 1;
        final accountCount = summary.accounts.length;
        final missingCount = summary.missingAccounts.length;
        final itemCount =
            accountCount + missingCount + (hasSummaryPage ? 1 : 0);
        final offset = hasSummaryPage ? 1 : 0;
        if (itemCount == 0) {
          return _HomeCardFrame(
            child: _UpgradeHomeEmpty(configuredCount: widget.players.length),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 220,
              child: PageView.builder(
                controller: _controller,
                onPageChanged: (index) => setState(() => _index = index),
                itemCount: itemCount,
                itemBuilder: (context, index) {
                  if (hasSummaryPage && index == 0) {
                    return _UpgradeAllAccountsPanel(
                      summary: summary,
                      onTap: _openTracker,
                    );
                  }
                  final localIndex = index - offset;
                  if (localIndex < accountCount) {
                    return _UpgradeAccountPanel(
                      account: summary.accounts[localIndex],
                      onTap: _openTracker,
                    );
                  }
                  return _UpgradeMissingDataPanel(
                    player: summary.missingAccounts[localIndex - accountCount],
                    onTap: _openTracker,
                  );
                },
              ),
            ),
            if (itemCount > 1) ...[
              const SizedBox(height: 8),
              Center(
                child: _HomeCardPageDots(
                  count: itemCount,
                  index: _index,
                  onDotTap: (index) => _showPage(itemCount, index),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _UpgradeAccountPanel extends StatelessWidget {
  const _UpgradeAccountPanel({required this.account, required this.onTap});

  final _UpgradeHomeAccount account;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final progress = '${(account.completion * 100).round()}%';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 1),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(28),
          child: Ink(
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: colorScheme.outlineVariant.withValues(alpha: 0.32),
              ),
            ),
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    SizedBox.square(
                      dimension: 46,
                      child: MobileWebImage(
                        imageUrl: account.hallImageUrl,
                        fit: BoxFit.contain,
                        errorWidget: (_, _, _) =>
                            const Icon(Icons.construction_rounded),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            loc.drawerUpgradeTracker,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(fontWeight: FontWeight.w900),
                          ),
                          Text(
                            account.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.labelLarge
                                ?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ],
                      ),
                    ),
                    _UpgradeProgressRing(
                      value: account.completion,
                      label: progress,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _upgradeSnapshotAgeLabel(context, account.capturedAt),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 22,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _UpgradeHomeMetricBars(
                  metrics: [
                    _UpgradeHomeMetricData(
                      icon: Icons.construction_rounded,
                      label: loc.dashboardUpgradeTrackerBuilders,
                      description: _formatDuration(
                        account.builderProjectedSeconds,
                      ),
                      value: _formatUpgradeQueueProgress(
                        account.activeBuilders,
                        account.totalBuilders,
                      ),
                      color: CKColors.donationGreen,
                    ),
                    _UpgradeHomeMetricData(
                      icon: Icons.science_rounded,
                      label: loc.dashboardUpgradeTrackerLab,
                      description: _formatDuration(account.labProjectedSeconds),
                      value: _formatUpgradeQueueProgress(
                        account.labActive ? 1 : 0,
                        account.hasLab ? 1 : 0,
                      ),
                      color: CKColors.warGold,
                    ),
                    if (account.hasPets)
                      _UpgradeHomeMetricData(
                        icon: Icons.pets_rounded,
                        label: loc.dashboardUpgradeTrackerPets,
                        description: _formatDuration(
                          account.petProjectedSeconds,
                        ),
                        value: _formatUpgradeQueueProgress(
                          account.petsActive ? 1 : 0,
                          1,
                        ),
                        color: CKColors.capitalPurple,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Page shown for a configured account that has no imported Upgrade Tracker
/// data yet, instead of silently dropping it from the pager.
class _UpgradeMissingDataPanel extends StatelessWidget {
  const _UpgradeMissingDataPanel({required this.player, required this.onTap});

  final Player player;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 1),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(28),
          child: Ink(
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: colorScheme.outlineVariant.withValues(alpha: 0.32),
              ),
            ),
            padding: const EdgeInsets.all(14),
            child: _UpgradeEmptyContent(
              imageUrl: ImageAssets.townHall(player.townHallLevel),
              title: loc.drawerUpgradeTracker,
              subtitle: player.name,
              status: loc.dashboardUpgradeTrackerNoData,
              trailing: const _UpgradeProgressRing(value: 0, label: '0%'),
            ),
          ),
        ),
      ),
    );
  }
}

/// Leading page when several accounts are pinned: combined completion,
/// builders, lab and pets across all of them.
class _UpgradeAllAccountsPanel extends StatelessWidget {
  const _UpgradeAllAccountsPanel({required this.summary, required this.onTap});

  final _UpgradeHomeSummary summary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final progress = '${(summary.completion * 100).round()}%';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 1),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(28),
          child: Ink(
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: colorScheme.outlineVariant.withValues(alpha: 0.32),
              ),
            ),
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const SizedBox.square(
                      dimension: 46,
                      child: Icon(Icons.construction_rounded, size: 28),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            loc.drawerUpgradeTracker,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(fontWeight: FontWeight.w900),
                          ),
                          Text(
                            loc.todoAccountsNumber(summary.accounts.length),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.labelLarge
                                ?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ],
                      ),
                    ),
                    _UpgradeProgressRing(
                      value: summary.completion,
                      label: progress,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _upgradeSummaryStatus(context, summary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 22,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _UpgradeHomeMetricBars(
                  metrics: [
                    _UpgradeHomeMetricData(
                      icon: Icons.construction_rounded,
                      label: loc.dashboardUpgradeTrackerBuilders,
                      description: _formatDuration(
                        summary.builderProjectedSeconds,
                      ),
                      value: _formatUpgradeQueueProgress(
                        summary.activeBuilders,
                        summary.totalBuilders,
                      ),
                      color: CKColors.donationGreen,
                    ),
                    _UpgradeHomeMetricData(
                      icon: Icons.science_rounded,
                      label: loc.dashboardUpgradeTrackerLab,
                      description: _formatDuration(summary.labProjectedSeconds),
                      value: _formatUpgradeQueueProgress(
                        summary.activeLabs,
                        summary.totalLabs,
                      ),
                      color: CKColors.warGold,
                    ),
                    if (summary.hasPets)
                      _UpgradeHomeMetricData(
                        icon: Icons.pets_rounded,
                        label: loc.dashboardUpgradeTrackerPets,
                        description: _formatDuration(
                          summary.petProjectedSeconds,
                        ),
                        value: _formatUpgradeQueueProgress(
                          summary.activePets,
                          summary.totalPets,
                        ),
                        color: CKColors.capitalPurple,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _UpgradeHomeEmpty extends StatelessWidget {
  const _UpgradeHomeEmpty({required this.configuredCount});

  final int configuredCount;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return _UpgradeEmptyContent(
      title: loc.drawerUpgradeTracker,
      subtitle: configuredCount > 0
          ? loc.todoAccountsNumber(configuredCount)
          : loc.upgradeTrackerSubtitle,
      status: loc.dashboardUpgradeTrackerNoData,
      trailing: const _UpgradeProgressRing(value: 0, label: '0%'),
    );
  }
}

class _UpgradeEmptyContent extends StatelessWidget {
  const _UpgradeEmptyContent({
    this.imageUrl,
    required this.title,
    required this.subtitle,
    required this.status,
    required this.trailing,
  });

  final String? imageUrl;
  final String title;
  final String subtitle;
  final String status;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            SizedBox.square(
              dimension: 46,
              child: imageUrl == null
                  ? const Icon(Icons.construction_rounded, size: 28)
                  : MobileWebImage(
                      imageUrl: imageUrl!,
                      fit: BoxFit.contain,
                      errorWidget: (_, _, _) =>
                          const Icon(Icons.construction_rounded),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            trailing,
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: Text(
                status,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 22,
              color: colorScheme.onSurfaceVariant,
            ),
          ],
        ),
        const SizedBox(height: 8),
        _UpgradeHomeMetricBars(
          metrics: [
            _UpgradeHomeMetricData(
              icon: Icons.construction_rounded,
              label: loc.dashboardUpgradeTrackerBuilders,
              value: '-',
              color: CKColors.donationGreen,
            ),
            _UpgradeHomeMetricData(
              icon: Icons.science_rounded,
              label: loc.dashboardUpgradeTrackerLab,
              value: '-',
              color: CKColors.warGold,
            ),
            _UpgradeHomeMetricData(
              icon: Icons.pets_rounded,
              label: loc.dashboardUpgradeTrackerPets,
              value: '-',
              color: CKColors.capitalPurple,
            ),
          ],
        ),
      ],
    );
  }
}

class _UpgradeHomeLoading extends StatelessWidget {
  const _UpgradeHomeLoading();

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Row(
      children: [
        const SizedBox.square(
          dimension: 42,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            loc.drawerUpgradeTracker,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
        ),
      ],
    );
  }
}

class _UpgradeHomeMetricData {
  const _UpgradeHomeMetricData({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.description,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final String? description;
}

class _UpgradeHomeMetricBars extends StatelessWidget {
  const _UpgradeHomeMetricBars({required this.metrics});

  final List<_UpgradeHomeMetricData> metrics;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < metrics.length; i += 2) {
      if (i + 1 < metrics.length) {
        rows.add(
          Row(
            children: [
              Expanded(child: _UpgradeHomeMetricBar(metric: metrics[i])),
              const SizedBox(width: 7),
              Expanded(child: _UpgradeHomeMetricBar(metric: metrics[i + 1])),
            ],
          ),
        );
      } else {
        rows.add(_UpgradeHomeMetricBar(metric: metrics[i]));
      }
    }

    return Column(
      children: [
        for (var i = 0; i < rows.length; i++) ...[
          if (i > 0) const SizedBox(height: 7),
          rows[i],
        ],
      ],
    );
  }
}

class _UpgradeHomeMetricBar extends StatelessWidget {
  const _UpgradeHomeMetricBar({required this.metric});

  final _UpgradeHomeMetricData metric;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      height: 46,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: metric.color.withValues(alpha: isDark ? 0.28 : 0.34),
          borderRadius: BorderRadius.circular(AppRadius.control),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 9),
          child: Row(
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: colorScheme.surface.withValues(alpha: 0.72),
                  shape: BoxShape.circle,
                ),
                child: SizedBox.square(
                  dimension: 26,
                  child: Icon(metric.icon, size: 18, color: metric.color),
                ),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      metric.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w900,
                        height: 1.05,
                      ),
                    ),
                    if (metric.description != null) ...[
                      const SizedBox(height: 1),
                      Text(
                        metric.description!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w700,
                          height: 1,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                metric.value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: metric.color,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UpgradeProgressRing extends StatelessWidget {
  const _UpgradeProgressRing({required this.value, required this.label});

  final double value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SizedBox.square(
      dimension: 54,
      child: CustomPaint(
        painter: _UpgradeRingPainter(
          value: value,
          color: CKColors.donationGreen,
          trackColor: colorScheme.surfaceContainerHighest,
        ),
        child: Center(
          child: Text(
            label,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontSize: 54 * 0.26,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}

class _UpgradeRingPainter extends CustomPainter {
  const _UpgradeRingPainter({
    required this.value,
    required this.color,
    required this.trackColor,
  });

  final double value;
  final Color color;
  final Color trackColor;

  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = size.width * 0.15;
    final rect =
        Offset(strokeWidth / 2, strokeWidth / 2) &
        Size(size.width - strokeWidth, size.height - strokeWidth);
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth;
    final valuePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth;

    canvas.drawArc(rect, -math.pi / 2, math.pi * 2, false, trackPaint);
    canvas.drawArc(
      rect,
      -math.pi / 2,
      math.pi * 2 * value.clamp(0, 1),
      false,
      valuePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _UpgradeRingPainter oldDelegate) {
    return oldDelegate.value != value ||
        oldDelegate.color != color ||
        oldDelegate.trackColor != trackColor;
  }
}

class _UpgradeHomeSummary {
  const _UpgradeHomeSummary({
    required this.configuredCount,
    required this.accounts,
    required this.missingAccounts,
  });

  final int configuredCount;
  final List<_UpgradeHomeAccount> accounts;
  final List<Player> missingAccounts;

  double get completion {
    if (accounts.isEmpty) return 0;
    final total = accounts.fold<double>(
      0,
      (sum, account) => sum + account.completion,
    );
    return (total / accounts.length).clamp(0.0, 1.0);
  }

  int get projectedSeconds => accounts.fold(
    0,
    (max, account) =>
        account.projectedSeconds > max ? account.projectedSeconds : max,
  );

  int get builderProjectedSeconds => accounts.fold(
    0,
    (max, account) => account.builderProjectedSeconds > max
        ? account.builderProjectedSeconds
        : max,
  );

  int get labProjectedSeconds => accounts.fold(
    0,
    (max, account) =>
        account.labProjectedSeconds > max ? account.labProjectedSeconds : max,
  );

  int get petProjectedSeconds => accounts.fold(
    0,
    (max, account) =>
        account.petProjectedSeconds > max ? account.petProjectedSeconds : max,
  );

  int get activeBuilders =>
      accounts.fold(0, (sum, account) => sum + account.activeBuilders);

  int get totalBuilders =>
      accounts.fold(0, (sum, account) => sum + account.totalBuilders);

  int get activeLabs => accounts.where((account) => account.labActive).length;

  int get totalLabs => accounts.where((account) => account.hasLab).length;

  bool get hasPets => accounts.any((account) => account.hasPets);

  int get activePets => accounts.where((account) => account.petsActive).length;

  int get totalPets => accounts.where((account) => account.hasPets).length;

  /// The least-fresh import across all accounts, shown as a staleness
  /// warning for the combined recap page.
  DateTime get oldestCapturedAt => accounts
      .map((account) => account.capturedAt)
      .reduce((a, b) => a.isBefore(b) ? a : b);
}

class _UpgradeHomeAccount {
  const _UpgradeHomeAccount({
    required this.name,
    required this.hallImageUrl,
    required this.completion,
    required this.projectedSeconds,
    required this.builderProjectedSeconds,
    required this.labProjectedSeconds,
    required this.petProjectedSeconds,
    required this.activeBuilders,
    required this.totalBuilders,
    required this.labActive,
    required this.hasLab,
    required this.petsActive,
    required this.hasPets,
    required this.capturedAt,
  });

  final String name;
  final String hallImageUrl;
  final double completion;
  final int projectedSeconds;
  final int builderProjectedSeconds;
  final int labProjectedSeconds;
  final int petProjectedSeconds;
  final DateTime capturedAt;

  /// Home-village builders only — the laboratory and pet house are each a
  /// single separate slot, shown in their own chip instead of folded in
  /// here, so this never mixes Builder Base counts into the Home Village
  /// builder count.
  final int activeBuilders;
  final int totalBuilders;

  final bool labActive;
  final bool hasLab;

  /// Whether the pet house is unlocked for this account — hides the Pets
  /// chip entirely rather than showing a misleading "0/0" for accounts too
  /// low level to have one.
  final bool petsActive;
  final bool hasPets;

  factory _UpgradeHomeAccount.fromSnapshot(UpgradeTrackerSnapshot snapshot) {
    final now = DateTime.now();
    final home = snapshot.overallSummary(village: UpgradeVillage.home);
    int projectedFor(UpgradeQueue queue) {
      final finish = snapshot
          .buildPlan(
            queue: queue,
            strategy: UpgradePlanStrategy.balanced,
            village: UpgradeVillage.home,
            startsAt: now,
          )
          .map((lane) => lane.finishesAt)
          .whereType<DateTime>()
          .fold<DateTime?>(null, (latest, value) {
            if (latest == null || value.isAfter(latest)) return value;
            return latest;
          });
      return finish == null
          ? 0
          : finish.difference(now).inSeconds.clamp(0, 1 << 31).toInt();
    }

    final builderProjectedSeconds = projectedFor(UpgradeQueue.builders);
    final labProjectedSeconds = projectedFor(UpgradeQueue.laboratory);
    final petProjectedSeconds = projectedFor(UpgradeQueue.pets);
    final projectedSeconds = math.max(
      builderProjectedSeconds,
      math.max(labProjectedSeconds, petProjectedSeconds),
    );

    final builderItems = snapshot.itemsFor(
      village: UpgradeVillage.home,
      queue: UpgradeQueue.builders,
    );
    final activeBuilders = builderItems
        .where((item) => snapshot.remainingActiveSeconds(item, now: now) > 0)
        .length;

    bool isActive(UpgradeQueue queue) => snapshot
        .itemsFor(village: UpgradeVillage.home, queue: queue)
        .any((item) => snapshot.remainingActiveSeconds(item, now: now) > 0);

    final labItems = snapshot.itemsFor(
      village: UpgradeVillage.home,
      queue: UpgradeQueue.laboratory,
    );
    final petItems = snapshot.itemsFor(
      village: UpgradeVillage.home,
      queue: UpgradeQueue.pets,
    );

    return _UpgradeHomeAccount(
      name: snapshot.name,
      hallImageUrl: ImageAssets.townHall(snapshot.townHallLevel),
      completion: home.completion.clamp(0.0, 1.0),
      projectedSeconds: projectedSeconds,
      builderProjectedSeconds: builderProjectedSeconds,
      labProjectedSeconds: labProjectedSeconds,
      petProjectedSeconds: petProjectedSeconds,
      activeBuilders: activeBuilders,
      totalBuilders: snapshot.buildersFor(UpgradeVillage.home),
      labActive: isActive(UpgradeQueue.laboratory),
      hasLab: labItems.isNotEmpty,
      petsActive: isActive(UpgradeQueue.pets),
      hasPets: petItems.isNotEmpty,
      capturedAt: snapshot.capturedAt,
    );
  }
}

String _formatUpgradeQueueProgress(int active, int total) =>
    total <= 0 ? '-' : '$active/$total';

String _upgradeSummaryStatus(
  BuildContext context,
  _UpgradeHomeSummary summary,
) {
  final loc = AppLocalizations.of(context)!;
  if (summary.missingAccounts.isEmpty) {
    return loc.dashboardUpgradeTrackerCombinedAcrossAccounts;
  }

  final visibleNames = summary.missingAccounts
      .take(3)
      .map((player) => player.name.trim())
      .where((name) => name.isNotEmpty)
      .toList(growable: false);
  final remaining = summary.missingAccounts.length - visibleNames.length;
  final suffix = remaining > 0 ? ', +$remaining' : '';
  final subject = visibleNames.isEmpty
      ? loc.todoAccountsNumber(summary.missingAccounts.length)
      : '${visibleNames.join(', ')}$suffix';
  return loc.dashboardUpgradeTrackerNeedsUpdate(
    subject,
    summary.missingAccounts.length,
  );
}

String _formatDuration(int seconds) {
  if (seconds <= 0) return 'Done';
  final duration = Duration(seconds: seconds);
  if (duration.inDays >= 1) return '${duration.inDays}d';
  if (duration.inHours >= 1) return '${duration.inHours}h';
  return '${duration.inMinutes.clamp(1, 59)}m';
}

String _upgradeSnapshotAgeLabel(BuildContext context, DateTime capturedAt) {
  final loc = AppLocalizations.of(context)!;
  final age = DateTime.now().difference(capturedAt);
  if (age.isNegative || age.inMinutes < 1) {
    return loc.upgradeTrackerUpdatedJustNow;
  }
  if (age.inHours < 1) {
    return loc.upgradeTrackerUpdatedMinutesAgo(age.inMinutes);
  }
  if (age.inHours < 24) {
    return loc.upgradeTrackerUpdatedHoursAgo(age.inHours);
  }
  final locale = Localizations.localeOf(context).toString();
  return loc.upgradeTrackerUpdatedOn(
    DateFormat.yMMMd(locale).add_jm().format(capturedAt),
  );
}

class _EmptyDashboard extends StatelessWidget {
  const _EmptyDashboard({
    required this.title,
    required this.message,
    required this.icon,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String message;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return AppEmptyState(
      title: title,
      body: message,
      icon: icon,
      actionLabel: actionLabel,
      onAction: onAction,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 52),
    );
  }
}
