import 'package:cached_network_image/cached_network_image.dart';
import 'package:clashkingapp/core/constants/image_assets.dart';
import 'package:clashkingapp/features/clan/data/clan_service.dart';
import 'package:clashkingapp/features/clan/models/clan.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

List<String> _recentGameSeasons({int count = 6}) {
  final now = DateTime.now().toUtc();
  return List.generate(count, (i) {
    final dt = DateTime(now.year, now.month - i, 1);
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}';
  });
}

class ClanGamesTab extends StatefulWidget {
  final Clan clanInfo;

  const ClanGamesTab({super.key, required this.clanInfo});

  @override
  State<ClanGamesTab> createState() => _ClanGamesTabState();
}

class _ClanGamesTabState extends State<ClanGamesTab> {
  late String _selectedSeason;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now().toUtc();
    _selectedSeason =
        '${now.year}-${now.month.toString().padLeft(2, '0')}';
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context
            .read<ClanService>()
            .fetchClanGames(widget.clanInfo.tag, _selectedSeason);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final clanService = context.watch<ClanService>();
    final gamesData =
        clanService.getClanGames(widget.clanInfo.tag, _selectedSeason);

    final nameMap = {
      for (final m in widget.clanInfo.memberList) m.tag: m.name,
    };
    final thMap = {
      for (final m in widget.clanInfo.memberList) m.tag: m.townHallLevel,
    };

    final seasons = _recentGameSeasons();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Season selector
        Padding(
          padding: const EdgeInsets.fromLTRB(0, 8, 0, 0),
          child: SizedBox(
            height: 32,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: seasons.length,
              separatorBuilder: (ctx, i) => const SizedBox(width: 6),
              itemBuilder: (context, i) {
                final season = seasons[i];
                final parts = season.split('-');
                final label = parts.length == 2
                    ? DateFormat('MMM yy').format(
                        DateTime(
                            int.parse(parts[0]), int.parse(parts[1])))
                    : season;
                final isSelected = _selectedSeason == season;
                return ChoiceChip(
                  label: Text(label),
                  selected: isSelected,
                  onSelected: (_) {
                    if (!isSelected) {
                      setState(() => _selectedSeason = season);
                      context
                          .read<ClanService>()
                          .fetchClanGames(widget.clanInfo.tag, season);
                    }
                  },
                  labelStyle: TextStyle(
                    fontSize: 11,
                    color: isSelected
                        ? Theme.of(context).colorScheme.onPrimary
                        : Theme.of(context).colorScheme.onSurface,
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 8),
        _buildBody(context, gamesData, nameMap, thMap),
      ],
    );
  }

  Widget _buildBody(
    BuildContext context,
    Map<String, dynamic>? gamesData,
    Map<String, String> nameMap,
    Map<String, int> thMap,
  ) {
    if (gamesData == null) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final tracked = gamesData['tracked'] as bool? ?? false;
    if (!tracked) {
      return Padding(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Text(
            'Clan Games not tracked for this clan yet',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final items = (gamesData['items'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();

    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Text(
            'No Clan Games data for $_selectedSeason',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final maxPoints = items
        .map((e) => (e['points'] as num? ?? 0).toInt())
        .reduce((a, b) => a > b ? a : b);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        children: items.asMap().entries.map((entry) {
          final i = entry.key;
          final e = entry.value;
          final tag = e['tag'] as String? ?? '';
          final points = (e['points'] as num? ?? 0).toInt();
          final name = nameMap[tag] ?? tag;
          final th = thMap[tag] ?? 0;
          final fraction = maxPoints > 0 ? points / maxPoints : 0.0;

          return Card(
            margin: const EdgeInsets.only(bottom: 6),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  SizedBox(
                    width: 24,
                    child: Text(
                      '${i + 1}',
                      style: Theme.of(context).textTheme.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 4),
                  if (th > 0)
                    CachedNetworkImage(
                      imageUrl: ImageAssets.townHall(th),
                      width: 32,
                      height: 32,
                      errorWidget: (ctx, url, err) =>
                          const SizedBox(width: 32),
                    )
                  else
                    const SizedBox(width: 32),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style:
                              Theme.of(context).textTheme.bodyMedium,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: fraction.toDouble(),
                            minHeight: 8,
                            backgroundColor: Theme.of(context)
                                .colorScheme
                                .primary
                                .withValues(alpha: 0.2),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _formatPoints(points),
                    style:
                        Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  String _formatPoints(int pts) =>
      pts >= 1000 ? '${(pts / 1000).toStringAsFixed(1)}k' : '$pts';
}
