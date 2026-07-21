import 'dart:async';
import 'dart:math' as math;

import 'package:clashkingapp/common/widgets/empty_state.dart';
import 'package:clashkingapp/core/services/api_service.dart';
import 'package:clashkingapp/features/auth/data/auth_service.dart';
import 'package:clashkingapp/features/coc_accounts/data/coc_account_service.dart';
import 'package:clashkingapp/features/coc_accounts/presentation/coc_account_management_page.dart';
import 'package:clashkingapp/features/home/data/home_dashboard_controller.dart';
import 'package:clashkingapp/features/home/models/home_dashboard_models.dart';
import 'package:clashkingapp/features/player/data/player_service.dart';
import 'package:clashkingapp/features/player/models/player.dart';
import 'package:clashkingapp/features/player/models/player_war_stats.dart';
import 'package:clashkingapp/features/war_cwl/data/war_cwl_service.dart';
import 'package:clashkingapp/features/war_cwl/models/war_member_presence.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int? _loadFingerprint;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final accountId = context.read<AuthService>().currentUser?.userId;
    final accounts = context.read<CocAccountService>().verifiedAccounts;
    final players = context.read<PlayerService>().profiles;
    if (accountId == null || accounts.isEmpty) return;

    final fingerprint = Object.hash(
      accountId,
      Object.hashAll(
        accounts.map(
          (account) => Object.hash(
            account['player_tag'],
            account['last_login'],
            account['is_verified'],
          ),
        ),
      ),
      Object.hashAll(
        players.map((player) => Object.hash(player.tag, player.clanTag)),
      ),
    );
    if (_loadFingerprint == fingerprint) return;
    _loadFingerprint = fingerprint;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_loadHome(accountId));
    });
  }

  Future<void> _loadHome(String accountId) async {
    final accounts = context.read<CocAccountService>().cocAccounts;
    final players = context.read<PlayerService>();
    final verifiedTags = context
        .read<CocAccountService>()
        .verifiedAccounts
        .map((account) => account['player_tag']?.toString() ?? '')
        .where((tag) => tag.isNotEmpty)
        .toList(growable: false);
    await context.read<HomeDashboardController>().load(
      accountId: accountId,
      linkedAccounts: accounts,
      players: players.profiles,
    );
    if (verifiedTags.isNotEmpty) {
      unawaited(players.loadPlayerWarStats(verifiedTags));
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final cocAccounts = context.watch<CocAccountService>();
    final players = context.watch<PlayerService>().profiles;
    final warService = context.watch<WarCwlService>();
    final controller = context.watch<HomeDashboardController>();
    final verified = cocAccounts.verifiedAccounts;
    final verifiedTags = verified
        .map(
          (account) => _normalizeTag(account['player_tag']?.toString() ?? ''),
        )
        .toSet();
    final verifiedPlayers = players
        .where((player) => verifiedTags.contains(_normalizeTag(player.tag)))
        .toList(growable: false);
    final missingAccounts = verified
        .where(
          (account) => !verifiedPlayers.any(
            (player) =>
                _normalizeTag(player.tag) ==
                _normalizeTag(account['player_tag']?.toString() ?? ''),
          ),
        )
        .toList(growable: false);
    final isDesktopWeb = kIsWeb && MediaQuery.sizeOf(context).width >= 900;
    final bottomPadding = isDesktopWeb
        ? 32.0
        : MediaQuery.paddingOf(context).bottom + 96;

    if (verified.isEmpty) {
      return _NoVerifiedAccounts(
        onManage: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => const AddCocAccountPage(refreshOnExit: false),
          ),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final maxContentWidth = isDesktopWeb ? 980.0 : 840.0;
            final horizontalPadding =
                ((constraints.maxWidth - maxContentWidth) / 2)
                    .clamp(16.0, double.infinity)
                    .toDouble();
            if (controller.loading && !controller.loaded) {
              return const Center(child: CircularProgressIndicator());
            }
            if (controller.error != null && !controller.loaded) {
              return AppEmptyState(
                title: loc.homeCouldNotLoadTitle,
                body: ApiService.getErrorMessage(controller.error),
                icon: Icons.cloud_off_outlined,
                actionLabel: loc.generalTryAgain,
                onAction: () {
                  final accountId = context
                      .read<AuthService>()
                      .currentUser
                      ?.userId;
                  if (accountId != null) unawaited(_loadHome(accountId));
                },
              );
            }

            return RefreshIndicator(
              onRefresh: () async {
                final accountId = context
                    .read<AuthService>()
                    .currentUser
                    ?.userId;
                if (accountId != null) await _loadHome(accountId);
              },
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  12,
                  horizontalPadding,
                  bottomPadding,
                ),
                children: [
                  _UpcomingSection(
                    players: verifiedPlayers,
                    accounts: verified,
                    controller: controller,
                    warService: warService,
                  ),
                  const SizedBox(height: 16),
                  _TodoSection(
                    players: verifiedPlayers,
                    missingAccounts: missingAccounts,
                    controller: controller,
                    warService: warService,
                  ),
                  const SizedBox(height: 16),
                  _SinceAwaySection(controller: controller),
                  const SizedBox(height: 16),
                  _PulseSection(players: verifiedPlayers),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _NoVerifiedAccounts extends StatelessWidget {
  const _NoVerifiedAccounts({required this.onManage});

  final VoidCallback onManage;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      body: SafeArea(
        child: AppEmptyState(
          title: loc.homeVerifiedAccountRequiredTitle,
          body: loc.homeVerifiedAccountRequiredBody,
          icon: Icons.verified_user_outlined,
          actionLabel: loc.homeVerifyAccountAction,
          onAction: onManage,
        ),
      ),
    );
  }
}

class _UpcomingSection extends StatefulWidget {
  const _UpcomingSection({
    required this.players,
    required this.accounts,
    required this.controller,
    required this.warService,
  });

  final List<Player> players;
  final List<Map<String, dynamic>> accounts;
  final HomeDashboardController controller;
  final WarCwlService warService;

  @override
  State<_UpcomingSection> createState() => _UpcomingSectionState();
}

class _UpcomingSectionState extends State<_UpcomingSection> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final now = DateTime.now();
    final items = _upcomingItems(
      players: widget.players,
      accounts: widget.accounts,
      controller: widget.controller,
      warService: widget.warService,
      now: now,
      loc: loc,
    );
    return _SectionShell(
      title: loc.homeUpcomingTitle,
      subtitle: loc.homeUpcomingSubtitle,
      trailing: IconButton(
        tooltip: _expanded ? loc.homeCollapseSection : loc.homeExpandSection,
        onPressed: () => setState(() => _expanded = !_expanded),
        icon: Icon(
          _expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
        ),
      ),
      child: AnimatedCrossFade(
        duration: const Duration(milliseconds: 180),
        crossFadeState: _expanded
            ? CrossFadeState.showFirst
            : CrossFadeState.showSecond,
        firstChild: items.isEmpty
            ? _InlineEmpty(
                icon: Icons.event_available_outlined,
                text: loc.homeUpcomingEmpty,
              )
            : Column(
                children: [
                  for (var index = 0; index < items.length; index++) ...[
                    if (index > 0) const Divider(height: 20),
                    _UpcomingRow(item: items[index]),
                  ],
                ],
              ),
        secondChild: const SizedBox(width: double.infinity),
      ),
    );
  }
}

class _UpcomingRow extends StatelessWidget {
  const _UpcomingRow({required this.item});

  final _UpcomingItem item;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: item.color.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(item.icon, color: item.color, size: 21),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      item.title,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  if (item.completed)
                    _StatusPill(
                      label: AppLocalizations.of(
                        context,
                      )!.homeRecentlyCompleted,
                      color: Colors.green,
                    ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                item.detail,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
              if (item.when != null) ...[
                const SizedBox(height: 3),
                Text(
                  _fullTime(item.when!),
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: item.color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _TodoSection extends StatelessWidget {
  const _TodoSection({
    required this.players,
    required this.missingAccounts,
    required this.controller,
    required this.warService,
  });

  final List<Player> players;
  final List<Map<String, dynamic>> missingAccounts;
  final HomeDashboardController controller;
  final WarCwlService warService;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final ordered = [...players]
      ..sort((a, b) {
        final aUrgency = _accountUrgency(a, warService);
        final bUrgency = _accountUrgency(b, warService);
        return bUrgency.compareTo(aUrgency);
      });
    return _SectionShell(
      title: loc.homeTodoTitle,
      subtitle: loc.homeTodoSubtitle,
      child: Column(
        children: [
          for (var index = 0; index < ordered.length; index++) ...[
            if (index > 0) const SizedBox(height: 10),
            _AccountAttentionCard(
              player: ordered[index],
              controller: controller,
              warService: warService,
            ),
          ],
          for (final account in missingAccounts) ...[
            if (ordered.isNotEmpty || account != missingAccounts.first)
              const SizedBox(height: 10),
            _MissingAccountCard(account: account),
          ],
          if (ordered.isEmpty && missingAccounts.isEmpty)
            _InlineEmpty(icon: Icons.task_alt_rounded, text: loc.homeTodoEmpty),
        ],
      ),
    );
  }
}

class _AccountAttentionCard extends StatelessWidget {
  const _AccountAttentionCard({
    required this.player,
    required this.controller,
    required this.warService,
  });

  final Player player;
  final HomeDashboardController controller;
  final WarCwlService warService;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final metrics = _availableMetrics(player, warService);
    final upgrade = controller.upgrades[_normalizeTag(player.tag)];
    final timers = upgrade?.timers() ?? const <HomeUpgradeTimer>[];
    final activeTimers = timers
        .where((timer) => timer.finishesAt.isAfter(DateTime.now()))
        .length;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.32),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: scheme.primaryContainer,
                foregroundColor: scheme.onPrimaryContainer,
                child: Text('${player.townHallLevel}'),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      player.name,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      [
                        'TH${player.townHallLevel}',
                        if (player.clanOverview.name.isNotEmpty)
                          player.clanOverview.name
                        else
                          loc.homeClanless,
                        player.tag,
                      ].join(' · '),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              _StatusPill(
                label: metrics.any((metric) => metric.remaining > 0)
                    ? loc.homeNeedsAttention
                    : loc.homeCaughtUp,
                color: metrics.any((metric) => metric.remaining > 0)
                    ? scheme.primary
                    : Colors.green,
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (metrics.isEmpty)
            Text(
              loc.homeTrackingDataPending,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
            )
          else
            for (var index = 0; index < metrics.length; index++) ...[
              if (index > 0) const SizedBox(height: 8),
              _MetricRow(metric: metrics[index]),
            ],
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.construction_rounded,
                  size: 18,
                  color: scheme.secondary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    upgrade == null
                        ? controller.upgradeFailures.contains(
                                _normalizeTag(player.tag),
                              )
                              ? loc.homeUpgradeUnavailable
                              : loc.homeUpgradeNotImported
                        : upgrade.data.isEmpty
                        ? loc.homeUpgradeNotImported
                        : activeTimers > 0
                        ? loc.homeUpgradeActiveCount(activeTimers)
                        : loc.homeUpgradeIdle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  const _MetricRow({required this.metric});

  final _HomeMetric metric;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final ratio = metric.total <= 0
        ? 1.0
        : (metric.done / metric.total).clamp(0.0, 1.0);
    return Row(
      children: [
        Icon(metric.icon, size: 19, color: metric.color),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      metric.label,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    metric.remaining == 0
                        ? AppLocalizations.of(context)!.homeDone
                        : AppLocalizations.of(
                            context,
                          )!.homeRemainingCount(metric.remaining),
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: metric.remaining == 0
                          ? Colors.green
                          : metric.color,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              LinearProgressIndicator(
                value: ratio,
                minHeight: 6,
                borderRadius: BorderRadius.circular(99),
                backgroundColor: scheme.surfaceContainerHighest,
                color: metric.remaining == 0 ? Colors.green : metric.color,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MissingAccountCard extends StatelessWidget {
  const _MissingAccountCard({required this.account});

  final Map<String, dynamic> account;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(Icons.sync_problem_rounded, color: scheme.secondary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  account['player_tag']?.toString() ?? '',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                Text(
                  AppLocalizations.of(context)!.homeVerifiedPlayerDataMissing,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SinceAwaySection extends StatelessWidget {
  const _SinceAwaySection({required this.controller});

  final HomeDashboardController controller;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final groups = <String, List<HomeActivityItem>>{};
    for (final item in controller.activity) {
      groups
          .putIfAbsent(_activityGroup(item.timestamp, loc), () => [])
          .add(item);
    }
    return _SectionShell(
      title: loc.homeSinceAwayTitle,
      subtitle: controller.priorLastLogin == null
          ? loc.homeSinceAwayFirstVisit
          : loc.homeSinceAwaySubtitle(_fullTime(controller.priorLastLogin!)),
      child: controller.activity.isEmpty
          ? _InlineEmpty(
              icon: Icons.history_rounded,
              text: loc.homeSinceAwayEmpty,
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final entry in groups.entries) ...[
                  Text(
                    entry.key,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  for (var index = 0; index < entry.value.length; index++) ...[
                    if (index > 0) const Divider(height: 18),
                    _ActivityRow(
                      item: entry.value[index],
                      isNew: entry.value[index].isNewSince(
                        controller.priorLastLogin,
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                ],
              ],
            ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({required this.item, required this.isNew});

  final HomeActivityItem item;
  final bool isNew;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          item.type == 'join_leave'
              ? Icons.group_outlined
              : Icons.trending_up_rounded,
          color: scheme.secondary,
          size: 21,
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
                      _activityTitle(item, AppLocalizations.of(context)!),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (isNew)
                    _StatusPill(
                      label: AppLocalizations.of(context)!.homeNewMarker,
                      color: scheme.primary,
                    ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                '${DateFormat.jm().format(item.timestamp.toLocal())} · ${item.playerTag}',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PulseSection extends StatelessWidget {
  const _PulseSection({required this.players});

  final List<Player> players;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final pulse = _buildPulse(players, loc);
    return _SectionShell(
      title: loc.homePulseTitle,
      subtitle: loc.homePulseSubtitle,
      child: pulse.isEmpty
          ? _InlineEmpty(
              icon: Icons.monitor_heart_outlined,
              text: loc.homePulseEmpty,
            )
          : Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final metric in pulse) _PulseMetricCard(metric: metric),
              ],
            ),
    );
  }
}

class _PulseMetricCard extends StatelessWidget {
  const _PulseMetricCard({required this.metric});

  final _PulseMetric metric;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 150, maxWidth: 230),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(metric.icon, color: scheme.secondary, size: 20),
            const SizedBox(height: 8),
            Text(
              metric.value,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            Text(
              metric.label,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionShell extends StatelessWidget {
  const _SectionShell({
    required this.title,
    required this.subtitle,
    required this.child,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.32),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              ?trailing,
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _InlineEmpty extends StatelessWidget {
  const _InlineEmpty({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: scheme.onSurfaceVariant),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.14),
      borderRadius: BorderRadius.circular(99),
    ),
    child: Text(
      label,
      style: Theme.of(context).textTheme.labelMedium?.copyWith(
        color: color,
        fontWeight: FontWeight.w900,
      ),
    ),
  );
}

class _UpcomingItem {
  const _UpcomingItem({
    required this.title,
    required this.detail,
    required this.icon,
    required this.color,
    this.when,
    this.completed = false,
  });

  final String title;
  final String detail;
  final IconData icon;
  final Color color;
  final DateTime? when;
  final bool completed;
}

class _HomeMetric {
  const _HomeMetric({
    required this.label,
    required this.done,
    required this.total,
    required this.icon,
    required this.color,
    this.deadline,
  });

  final String label;
  final int done;
  final int total;
  final IconData icon;
  final Color color;
  final DateTime? deadline;

  int get remaining => math.max(total - done, 0);
}

class _PulseMetric {
  const _PulseMetric(this.label, this.value, this.icon);

  final String label;
  final String value;
  final IconData icon;
}

List<_UpcomingItem> _upcomingItems({
  required List<Player> players,
  required List<Map<String, dynamic>> accounts,
  required HomeDashboardController controller,
  required WarCwlService warService,
  required DateTime now,
  required AppLocalizations loc,
}) {
  final items = <_UpcomingItem>[];
  for (final player in players) {
    for (final metric in _availableMetrics(player, warService)) {
      if (metric.remaining <= 0 ||
          !const {
            'war_attacks',
            'cwl_attacks',
            'legend_attacks',
            'raid_attacks',
          }.contains(metric.label)) {
        continue;
      }
      items.add(
        _UpcomingItem(
          title: _metricLabel(metric.label, loc),
          detail: loc.homeUpcomingAccountDetail(player.name, metric.remaining),
          when: metric.deadline,
          icon: metric.icon,
          color: metric.color,
        ),
      );
    }
  }

  final playersByTag = {
    for (final player in players) _normalizeTag(player.tag): player,
  };
  for (final account in accounts) {
    final tag = account['player_tag']?.toString() ?? '';
    final player = playersByTag[_normalizeTag(tag)];
    final name = player?.name ?? tag;
    final upgrade = controller.upgrades[_normalizeTag(tag)];
    if (upgrade == null || upgrade.data.isEmpty) {
      items.add(
        _UpcomingItem(
          title: loc.homeUpgradeDataNeeded,
          detail: loc.homeUpgradeDataNeededDetail(name),
          icon: Icons.upload_file_rounded,
          color: Colors.orange,
        ),
      );
      continue;
    }
    final timers = upgrade.timers();
    final visible = timers.where(
      (timer) =>
          timer.finishesAt.isAfter(now) || timer.isRecentlyCompleted(now),
    );
    if (visible.isEmpty) {
      items.add(
        _UpcomingItem(
          title: loc.homeUpgradeIdleTitle,
          detail: loc.homeUpgradeIdleDetail(name),
          icon: Icons.construction_rounded,
          color: Colors.blueGrey,
        ),
      );
    } else {
      for (final timer in visible.take(4)) {
        items.add(
          _UpcomingItem(
            title: timer.name,
            detail: loc.homeUpgradeAccountDetail(name),
            when: timer.finishesAt,
            completed: timer.isRecentlyCompleted(now),
            icon: Icons.construction_rounded,
            color: timer.isRecentlyCompleted(now) ? Colors.green : Colors.blue,
          ),
        );
      }
    }
  }

  for (final activity in controller.activity.where(
    (item) =>
        item.type == 'player_history' &&
        item.eventType.toLowerCase().contains('upgrade') &&
        now.difference(item.timestamp.toLocal()).abs() <=
            const Duration(minutes: 15),
  )) {
    items.add(
      _UpcomingItem(
        title: _titleCase(activity.eventType),
        detail: activity.playerName ?? activity.playerTag,
        when: activity.timestamp,
        completed: true,
        icon: Icons.check_circle_outline_rounded,
        color: Colors.green,
      ),
    );
  }

  items.sort((a, b) {
    if (a.completed != b.completed) return a.completed ? 1 : -1;
    if (a.when == null && b.when == null) return a.title.compareTo(b.title);
    if (a.when == null) return 1;
    if (b.when == null) return -1;
    return a.when!.compareTo(b.when!);
  });
  return items;
}

List<_HomeMetric> _availableMetrics(Player player, WarCwlService warService) {
  final locIndependent = player.getTodoProgressMetrics(
    memberCwl: _memberPresence(player, warService),
  );
  final now = DateTime.now();
  return locIndependent
      .where((metric) {
        return switch (metric.label) {
          'legend_attacks' => player.currentLegendSeason?.currentDay != null,
          'war_attacks' => player.warData != null,
          'cwl_attacks' =>
            player.clan?.warCwl != null ||
                _memberPresence(player, warService).isInWar,
          'raid_attacks' => player.raids != null,
          'clan_games' => player.clanGamesPoint.isNotEmpty,
          'season_pass' => player.seasonPass.isNotEmpty,
          _ => true,
        };
      })
      .map(
        (metric) => _HomeMetric(
          label: metric.label,
          done: metric.done,
          total: metric.total,
          icon: _metricIcon(metric.label),
          color: _metricColor(metric.label),
          deadline: _metricDeadline(metric.label, player, now),
        ),
      )
      .toList(growable: false);
}

DateTime? _metricDeadline(String label, Player player, DateTime now) {
  switch (label) {
    case 'war_attacks':
      return player.warData?.endTime;
    case 'cwl_attacks':
      return player.clan?.warCwl?.warInfo.endTime;
    case 'legend_attacks':
      final utc = now.toUtc();
      return DateTime.utc(utc.year, utc.month, utc.day + 1, 5).toLocal();
    case 'raid_attacks':
      var end = DateTime.utc(now.year, now.month, now.day, 7);
      while (end.weekday != DateTime.monday || !end.isAfter(now.toUtc())) {
        end = end.add(const Duration(days: 1));
      }
      return end.toLocal();
    default:
      return null;
  }
}

double _accountUrgency(Player player, WarCwlService warService) {
  var urgency = 0.0;
  for (final metric in _availableMetrics(player, warService)) {
    if (metric.remaining <= 0) continue;
    final ratio = metric.total <= 0 ? 0 : metric.remaining / metric.total;
    final priority = switch (metric.label) {
      'war_attacks' || 'cwl_attacks' => 5.0,
      'legend_attacks' => 4.0,
      'raid_attacks' => 3.0,
      _ => 1.0,
    };
    urgency = math.max(urgency, priority + ratio);
  }
  return urgency;
}

WarMemberPresence _memberPresence(Player player, WarCwlService service) {
  final clanTag = player.clan?.tag ?? player.clanTag;
  if (clanTag.isEmpty) return WarMemberPresence.empty();
  return service
          .getWarCwlByTag(clanTag)
          ?.getMemberPresence(player.tag, clanTag) ??
      WarMemberPresence.empty();
}

List<_PulseMetric> _buildPulse(List<Player> players, AppLocalizations loc) {
  final result = <_PulseMetric>[];
  final cutoff = DateTime.now().subtract(const Duration(days: 30));
  var regularAttacks = 0;
  var regularStars = 0;
  var cwlAttacks = 0;
  var cwlStars = 0;
  var rankedAttacks = 0;
  var rankedTrophies = 0;
  int? bestGlobalRank;

  for (final player in players) {
    for (final war in player.warStats?.wars ?? const <PlayerWarStatsData>[]) {
      final endedAt = war.warDetails.endTime;
      if (endedAt == null || endedAt.isBefore(cutoff)) continue;
      final attacks = war.memberData.attacks;
      final stars = attacks.fold<int>(0, (sum, attack) => sum + attack.stars);
      if (war.warDetails.isClanWarLeague) {
        cwlAttacks += attacks.length;
        cwlStars += stars;
      } else {
        regularAttacks += attacks.length;
        regularStars += stars;
      }
    }
    final legendSeasons = player.legendsBySeason?.allSeasons;
    if (legendSeasons != null) {
      for (final season in legendSeasons) {
        for (final entry in season.days.entries) {
          final day = DateTime.tryParse(entry.key);
          if (day == null || day.isBefore(cutoff)) continue;
          rankedAttacks += entry.value.totalAttacks;
          rankedTrophies +=
              entry.value.trophiesGainedTotal - entry.value.trophiesLostTotal;
        }
      }
    }
    final globalRank = player.rankings?.globalRank;
    if (globalRank != null && globalRank > 0) {
      bestGlobalRank = bestGlobalRank == null
          ? globalRank
          : math.min(bestGlobalRank, globalRank);
    }
  }

  if (regularAttacks > 0) {
    result.add(
      _PulseMetric(
        loc.homePulseWarAverage,
        '${(regularStars / regularAttacks).toStringAsFixed(2)} ★',
        Icons.sports_martial_arts_rounded,
      ),
    );
  }
  if (cwlAttacks > 0) {
    result.add(
      _PulseMetric(
        loc.homePulseCwlAverage,
        '${(cwlStars / cwlAttacks).toStringAsFixed(2)} ★',
        Icons.military_tech_rounded,
      ),
    );
  }
  if (rankedAttacks > 0) {
    result.add(
      _PulseMetric(
        loc.homePulseRankedToday,
        loc.homePulseRankedValue(
          rankedAttacks,
          '${rankedTrophies >= 0 ? '+' : ''}$rankedTrophies',
        ),
        Icons.emoji_events_outlined,
      ),
    );
  }
  if (bestGlobalRank != null) {
    result.add(
      _PulseMetric(
        loc.homePulseBestGlobalRank,
        '#${NumberFormat.decimalPattern().format(bestGlobalRank)}',
        Icons.public_rounded,
      ),
    );
  }
  return result;
}

String _metricLabel(String label, AppLocalizations loc) => switch (label) {
  'legend_attacks' => loc.homeRankedAttacks,
  'war_attacks' => loc.todoWarAttacks,
  'cwl_attacks' => loc.todoCwlAttacks,
  'raid_attacks' => loc.todoRaidAttacks,
  'clan_games' => loc.todoEventClanGames,
  'season_pass' => loc.homeSeasonPass,
  _ => _titleCase(label),
};

IconData _metricIcon(String label) => switch (label) {
  'legend_attacks' => Icons.emoji_events_outlined,
  'war_attacks' => Icons.sports_martial_arts_rounded,
  'cwl_attacks' => Icons.military_tech_rounded,
  'raid_attacks' => Icons.forest_outlined,
  'clan_games' => Icons.sports_esports_outlined,
  'season_pass' => Icons.stars_outlined,
  _ => Icons.task_alt_rounded,
};

Color _metricColor(String label) => switch (label) {
  'war_attacks' => Colors.red,
  'cwl_attacks' => Colors.deepPurple,
  'legend_attacks' => Colors.orange,
  'raid_attacks' => Colors.green,
  'clan_games' => Colors.blue,
  'season_pass' => Colors.amber.shade700,
  _ => Colors.blueGrey,
};

String _activityGroup(DateTime timestamp, AppLocalizations loc) {
  final local = timestamp.toLocal();
  final now = DateTime.now();
  final date = DateTime(local.year, local.month, local.day);
  final today = DateTime(now.year, now.month, now.day);
  if (date == today) return loc.homeToday;
  if (date == today.subtract(const Duration(days: 1))) {
    return loc.homeYesterday;
  }
  return loc.homeEarlier;
}

String _activityTitle(HomeActivityItem item, AppLocalizations loc) {
  final player = item.playerName ?? item.playerTag;
  final clan = item.clanName ?? item.clanTag;
  if (item.type == 'join_leave') {
    final action = item.eventType.toLowerCase().contains('leave')
        ? loc.homeActivityLeft
        : loc.homeActivityJoined;
    return clan == null
        ? '$player $action ${loc.homeActivityAClan}'
        : '$player $action $clan';
  }
  final value = item.value == null ? '' : ' · ${item.value}';
  return '$player · ${_titleCase(item.eventType)}$value';
}

String _fullTime(DateTime value) =>
    DateFormat('EEE, MMM d · h:mm a').format(value.toLocal());

String _titleCase(String value) => value
    .replaceAll('_', ' ')
    .split(' ')
    .where((part) => part.isNotEmpty)
    .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
    .join(' ');

String _normalizeTag(String value) =>
    value.replaceAll('#', '').trim().toUpperCase();
