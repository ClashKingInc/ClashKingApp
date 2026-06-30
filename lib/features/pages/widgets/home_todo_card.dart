import 'package:cached_network_image/cached_network_image.dart';
import 'package:clashkingapp/core/constants/image_assets.dart';
import 'package:clashkingapp/core/functions/functions.dart';
import 'package:clashkingapp/features/player/models/player.dart';
import 'package:clashkingapp/features/player/presentation/to_do/player_to_do_page.dart';
import 'package:clashkingapp/features/war_cwl/data/war_cwl_service.dart';
import 'package:clashkingapp/features/war_cwl/models/war_member_presence.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Recap card on the home tab.
/// - First chip row: one aggregated chip per pending category (legend/war/cwl/
///   clan games/season pass), summed across pinned accounts.
/// - Second name row: neutral pills showing which pinned accounts still have
///   something to do.
class HomeTodoCard extends StatelessWidget {
  const HomeTodoCard({
    super.key,
    required this.players,
    required this.allPlayers,
  });

  final List<Player> players;
  final List<Player> allPlayers;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final warCwlService = context.watch<WarCwlService>();

    final totals = _TodoTotals.aggregate(players, warCwlService);
    final pendingChips = totals.buildPendingChips(context);
    final accountStatuses = _accountStatuses(warCwlService);

    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _openTodo(context, warCwlService),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox.square(
                dimension: 62,
                child: CachedNetworkImage(
                  imageUrl: ImageAssets.iconBuilderPotion,
                  fit: BoxFit.contain,
                  errorWidget: (context, url, error) =>
                      const Icon(Icons.checklist_rounded, size: 36),
                ),
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
                            'To-do',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 17,
                                ),
                          ),
                        ),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ],
                    ),
                    Text(
                      players.length == 1
                          ? '1 account pinned'
                          : '${players.length} accounts pinned',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 10),
                    // Category chips (aggregated, pending only)
                    if (pendingChips.isEmpty)
                      Row(
                        children: [
                          const Icon(Icons.check_circle_outline_rounded,
                              size: 16, color: Colors.green),
                          const SizedBox(width: 6),
                          Text(
                            'All caught up!',
                            style: Theme.of(context)
                                .textTheme
                                .labelLarge
                                ?.copyWith(
                                  color: Colors.green,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ],
                      )
                    else
                      Wrap(
                        spacing: 7,
                        runSpacing: 7,
                        children: pendingChips,
                      ),
                    // Account name chips — all accounts, green if done red if pending
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: accountStatuses
                          .map((s) => _NameChip(name: s.name, done: s.done))
                          .toList(growable: false),
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

  List<({String name, bool done})> _accountStatuses(WarCwlService warCwlService) {
    return players
        .map((p) => (name: p.name, done: !_hasPending(p, warCwlService)))
        .toList(growable: false);
  }

  static bool _hasPending(Player player, WarCwlService warCwlService) {
    // Legend
    final currentDay = player.currentLegendSeason?.currentDay;
    if (player.league == 'Legend League' &&
        currentDay != null &&
        currentDay.totalAttacks < 8) {
      return true;
    }

    // Regular war
    final warData = player.warData;
    if (warData != null && warData.state == 'inWar' && !_isSameWarAsCwl(player)) {
      final done = warData.getAttacksDoneByPlayer(player.tag, player.clanTag);
      if (done < (warData.attacksPerMember ?? 1)) { return true; }
    }

    // CWL war day
    final cwlWarInfo = player.clan?.warCwl?.warInfo;
    if (cwlWarInfo != null &&
        cwlWarInfo.state == 'inWar' &&
        cwlWarInfo.isPlayerInWar(player.tag, player.clanTag)) {
      final done = cwlWarInfo.getAttacksDoneByPlayer(player.tag, player.clanTag);
      if (done < (cwlWarInfo.attacksPerMember ?? 1)) { return true; }
    }

    // CWL overall
    if (isInTimeFrameForCwl() &&
        player.clan != null &&
        player.clan!.tag.isNotEmpty) {
      final presence = warCwlService
          .getWarCwlByTag(player.clan!.tag)
          ?.getMemberPresence(player.tag, player.clan!.tag);
      if (presence != null &&
          presence.attacksAvailable > 0 &&
          presence.attacksDone < presence.attacksAvailable) {
        return true;
      }
    }

    // Clan Games
    if (isInTimeFrameForClanGames() &&
        player.currentClanGamesPoints < requiredClanGamesPoints) {
      return true;
    }

    // Season Pass
    if (player.currentSeasonPoints < requiredSeasonPassPoints) { return true; }

    return false;
  }

  static bool _isSameWarAsCwl(Player player) {
    if (player.warData == null || player.clan?.warCwl?.warInfo == null) {
      return false;
    }
    final r = player.warData!;
    final c = player.clan!.warCwl!.warInfo;
    return (r.clan?.tag == c.clan?.tag && r.opponent?.tag == c.opponent?.tag) ||
        (r.clan?.tag == c.opponent?.tag && r.opponent?.tag == c.clan?.tag);
  }

  void _openTodo(BuildContext context, WarCwlService warCwlService) {
    final accounts = allPlayers.isNotEmpty ? allPlayers : players;
    final memberPresenceMap = <String, WarMemberPresence>{};
    for (final player in accounts) {
      if (player.clan != null && player.clan!.tag.isNotEmpty) {
        final warCwl = warCwlService.getWarCwlByTag(player.clan!.tag);
        if (warCwl != null) {
          memberPresenceMap[player.tag] = warCwl.getMemberPresence(
            player.tag,
            player.clan!.tag,
          );
        }
      }
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PlayerToDoScreen(
          players: accounts,
          memberPresenceMap: memberPresenceMap,
        ),
      ),
    );
  }
}

/// Aggregates to-do totals across all pinned players, mirroring
/// [PlayerToDoHeader]'s logic.
class _TodoTotals {
  const _TodoTotals({
    required this.totalLegend,
    required this.requiredLegend,
    required this.totalWar,
    required this.requiredWar,
    required this.totalCwl,
    required this.requiredCwl,
    required this.totalClanGames,
    required this.requiredClanGames,
    required this.totalSeasonPass,
    required this.requiredSeasonPass,
  });

  final int totalLegend;
  final int requiredLegend;
  final int totalWar;
  final int requiredWar;
  final int totalCwl;
  final int requiredCwl;
  final int totalClanGames;
  final int requiredClanGames;
  final int totalSeasonPass;
  final int requiredSeasonPass;

  factory _TodoTotals.aggregate(
    List<Player> players,
    WarCwlService warCwlService,
  ) {
    var totalLegend = 0;
    var requiredLegend = 0;
    var totalWar = 0;
    var requiredWar = 0;
    var totalCwl = 0;
    var requiredCwl = 0;
    var totalClanGames = 0;
    var totalSeasonPass = 0;

    for (final player in players) {
      totalClanGames += player.currentClanGamesPoints;
      totalSeasonPass += player.currentSeasonPoints;

      if (player.league == 'Legend League' &&
          player.currentLegendSeason?.currentDay != null) {
        requiredLegend += 8;
        totalLegend +=
            player.currentLegendSeason?.currentDay?.totalAttacks ?? 0;
      }

      // Regular war
      final warData = player.warData;
      if (warData != null &&
          warData.state == 'inWar' &&
          !HomeTodoCard._isSameWarAsCwl(player)) {
        requiredWar += warData.attacksPerMember ?? 0;
        totalWar +=
            warData.getAttacksDoneByPlayer(player.tag, player.clanTag);
      }

      // CWL war day
      final cwlWarInfo = player.clan?.warCwl?.warInfo;
      if (cwlWarInfo != null &&
          cwlWarInfo.state == 'inWar' &&
          cwlWarInfo.isPlayerInWar(player.tag, player.clanTag)) {
        requiredCwl += cwlWarInfo.attacksPerMember ?? 1;
        totalCwl +=
            cwlWarInfo.getAttacksDoneByPlayer(player.tag, player.clanTag);
      } else if (isInTimeFrameForCwl() &&
          player.clan != null &&
          player.clan!.tag.isNotEmpty) {
        // CWL overall fallback
        final presence = warCwlService
            .getWarCwlByTag(player.clan!.tag)
            ?.getMemberPresence(player.tag, player.clan!.tag);
        if (presence != null && presence.attacksAvailable > 0) {
          requiredCwl += presence.attacksAvailable;
          totalCwl += presence.attacksDone;
        }
      }
    }

    return _TodoTotals(
      totalLegend: totalLegend,
      requiredLegend: requiredLegend,
      totalWar: totalWar,
      requiredWar: requiredWar,
      totalCwl: totalCwl,
      requiredCwl: requiredCwl,
      totalClanGames: totalClanGames,
      requiredClanGames: players.length * requiredClanGamesPoints,
      totalSeasonPass: totalSeasonPass,
      requiredSeasonPass: players.length * requiredSeasonPassPoints,
    );
  }

  /// Only chips for categories that are not yet completed.
  List<Widget> buildPendingChips(BuildContext context) {
    return [
      if (requiredLegend > 0 && totalLegend < requiredLegend)
        _TodoChip(
          imageUrl: ImageAssets.legendBlazonNoPadding,
          label: '$totalLegend/$requiredLegend',
        ),
      if (requiredWar > 0 && totalWar < requiredWar)
        _TodoChip(
          imageUrl: ImageAssets.war,
          label: '$totalWar/$requiredWar',
        ),
      if (requiredCwl > 0 && totalCwl < requiredCwl)
        _TodoChip(
          imageUrl: ImageAssets.cwlSwordsNoBorder,
          label: '$totalCwl/$requiredCwl',
        ),
      if (isInTimeFrameForClanGames() && totalClanGames < requiredClanGames)
        _TodoChip(
          imageUrl: ImageAssets.clanGamesMedals,
          label: '$totalClanGames/$requiredClanGames',
        ),
      if (totalSeasonPass < requiredSeasonPass)
        _TodoChip(
          imageUrl: ImageAssets.iconGoldPass,
          label: '$totalSeasonPass/$requiredSeasonPass',
        ),
    ];
  }
}

/// Pill chip for a pending category — always red (only shown when not done).
class _TodoChip extends StatelessWidget {
  const _TodoChip({required this.imageUrl, required this.label});

  final String imageUrl;
  final String label;

  @override
  Widget build(BuildContext context) {
    const color = Colors.red;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.6)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox.square(
              dimension: 16,
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.contain,
                errorWidget: (context, url, error) =>
                    const Icon(Icons.help_outline, size: 14, color: color),
              ),
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Account name pill in the style of [_AttackPlayerChip] from war_cwl_page:
/// colored background at 14% alpha, no border, green if done / red if pending.
class _NameChip extends StatelessWidget {
  const _NameChip({required this.name, required this.done});

  final String name;
  final bool done;

  @override
  Widget build(BuildContext context) {
    final color = done ? Colors.green : Colors.red;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        child: Text(
          name,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
        ),
      ),
    );
  }
}
