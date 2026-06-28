import 'package:cached_network_image/cached_network_image.dart';
import 'package:clashkingapp/core/constants/image_assets.dart';
import 'package:clashkingapp/features/clan/data/clan_service.dart';
import 'package:clashkingapp/features/clan/models/clan.dart';
import 'package:clashkingapp/features/clan/models/clan_member.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class ClanLegendTab extends StatefulWidget {
  final Clan clanInfo;

  const ClanLegendTab({super.key, required this.clanInfo});

  @override
  State<ClanLegendTab> createState() => _ClanLegendTabState();
}

class _ClanLegendTabState extends State<ClanLegendTab> {
  late final String _todayKey;
  late final List<ClanMember> _legendMembers;

  @override
  void initState() {
    super.initState();
    // CoC legend day resets at 05:00 UTC
    final cocNow = DateTime.now().toUtc().subtract(const Duration(hours: 5));
    _todayKey = DateFormat('yyyy-MM-dd').format(cocNow);

    _legendMembers = widget.clanInfo.memberList
        .where((m) => m.league.name == 'Legend League')
        .toList()
      ..sort((a, b) => b.trophies.compareTo(a.trophies));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _legendMembers.isNotEmpty) {
        context.read<ClanService>().fetchClanLegendDay(
              widget.clanInfo.tag,
              _todayKey,
              _legendMembers.map((m) => m.tag).toList(),
            );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_legendMembers.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CachedNetworkImage(
                imageUrl: ImageAssets.legendBlazon,
                width: 64,
                height: 64,
                errorWidget: (ctx, url, err) => const Icon(Icons.emoji_events, size: 64),
              ),
              const SizedBox(height: 16),
              Text(
                'No Legend League players in this clan',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    final clanService = context.watch<ClanService>();
    final dayData = clanService.getClanLegendDay(widget.clanInfo.tag, _todayKey);

    // Build lookup: tag → today's day stats
    final Map<String, Map<String, dynamic>> statsMap = {};
    if (dayData != null) {
      for (final player in dayData) {
        final tag = player['tag'] as String? ?? '';
        final legends = player['legends'] as Map<String, dynamic>? ?? {};
        final todayStats = legends[_todayKey] as Map<String, dynamic>?;
        if (tag.isNotEmpty && todayStats != null) {
          statsMap[tag] = todayStats;
        }
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CachedNetworkImage(
                imageUrl: ImageAssets.legendBlazon,
                width: 24,
                height: 24,
                errorWidget: (ctx, url, err) => const Icon(Icons.emoji_events, size: 24),
              ),
              const SizedBox(width: 8),
              Text(
                'Legend League — ${_legendMembers.length} player${_legendMembers.length == 1 ? '' : 's'}',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            _todayKey,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.5),
                ),
          ),
          const SizedBox(height: 12),
          if (dayData == null)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              ),
            )
          else
            ..._legendMembers.asMap().entries.map((entry) {
              final rank = entry.key + 1;
              final member = entry.value;
              final stats = statsMap[member.tag];
              return _LegendPlayerCard(
                rank: rank,
                member: member,
                stats: stats,
              );
            }),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _LegendPlayerCard extends StatelessWidget {
  final int rank;
  final ClanMember member;
  final Map<String, dynamic>? stats;

  const _LegendPlayerCard({
    required this.rank,
    required this.member,
    required this.stats,
  });

  int _countAttacks() {
    if (stats == null) return 0;
    final atks = stats!['attacks'] as List?;
    if (atks != null) return atks.length;
    final n = stats!['num_attacks'] as num?;
    return n?.toInt() ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final attacksDone = _countAttacks();
    final hasData = stats != null;

    final gained = hasData
        ? (stats!['trophies_gained_total'] as num? ?? 0).toInt()
        : null;
    final lost = hasData
        ? (stats!['trophies_lost_total'] as num? ?? 0).toInt()
        : null;
    final net = (gained != null && lost != null) ? gained - lost : null;

    final netStr = net == null
        ? null
        : net >= 0
            ? '+$net'
            : '$net';
    final netColor = net == null
        ? Colors.grey
        : net > 0
            ? Colors.green
            : net < 0
                ? Colors.red
                : Colors.grey;

    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            SizedBox(
              width: 24,
              child: Text(
                '$rank',
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(width: 4),
            CachedNetworkImage(
              imageUrl: ImageAssets.townHall(member.townHallLevel),
              width: 32,
              height: 32,
              errorWidget: (ctx, url, err) =>
                  const Icon(Icons.error, size: 20),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    member.name,
                    style: Theme.of(context).textTheme.bodyMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  // 8 attack dots
                  Row(
                    children: List.generate(8, (i) {
                      final filled = i < attacksDone;
                      return Container(
                        width: 9,
                        height: 9,
                        margin: const EdgeInsets.only(right: 2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: filled
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withValues(alpha: 0.2),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CachedNetworkImage(
                      imageUrl: ImageAssets.trophies,
                      width: 14,
                      height: 14,
                      errorWidget: (ctx, url, err) =>
                          const SizedBox(width: 14),
                    ),
                    const SizedBox(width: 2),
                    Text(
                      '${member.trophies}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
                if (netStr != null)
                  Text(
                    netStr,
                    style:
                        Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: netColor,
                              fontWeight: FontWeight.bold,
                            ),
                  ),
                Text(
                  '$attacksDone/8 atk',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.6),
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
