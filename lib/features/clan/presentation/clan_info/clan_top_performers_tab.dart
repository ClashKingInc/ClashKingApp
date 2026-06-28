import 'package:cached_network_image/cached_network_image.dart';
import 'package:clashkingapp/core/constants/image_assets.dart';
import 'package:clashkingapp/features/clan/data/clan_service.dart';
import 'package:clashkingapp/features/clan/models/clan.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

List<String> _recentSeasons({int count = 6}) {
  final now = DateTime.now().toUtc();
  return List.generate(count, (i) {
    final dt = DateTime(now.year, now.month - i, 1);
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}';
  });
}

const _baseUrl = ImageAssets.baseUrl;

// Category display config: label, icon asset URL
const _categories = [
  _CatInfo('donated', 'Donations', ImageAssets.sword),
  _CatInfo('received', 'Donations Received', ImageAssets.sword),
  _CatInfo('capital_donated', 'Capital Gold Donated', ImageAssets.capitalGold),
  _CatInfo('capital_raided', 'Capital Gold Raided', ImageAssets.capitalGold),
  _CatInfo('war_stars', 'War Stars', ImageAssets.builderBaseStar),
  _CatInfo('gold', 'Gold Looted', '$_baseUrl/resources/gold.webp'),
  _CatInfo('elixir', 'Elixir Looted', '$_baseUrl/resources/elixir.webp'),
  _CatInfo('dark_elixir', 'Dark Elixir Looted', '$_baseUrl/resources/dark_elixir.webp'),
  _CatInfo('attack_wins', 'Attack Wins', ImageAssets.attacks),
  _CatInfo('activity', 'Activity', ImageAssets.hitrate),
];

class _CatInfo {
  final String key;
  final String label;
  final String imageUrl;
  const _CatInfo(this.key, this.label, this.imageUrl);
}

class ClanTopPerformersTab extends StatefulWidget {
  final Clan clanInfo;

  const ClanTopPerformersTab({super.key, required this.clanInfo});

  @override
  State<ClanTopPerformersTab> createState() => _ClanTopPerformersTabState();
}

class _ClanTopPerformersTabState extends State<ClanTopPerformersTab> {
  late String _selectedSeason;
  final _seasons = _recentSeasons();

  @override
  void initState() {
    super.initState();
    _selectedSeason = _seasons.first;
    _fetch(_selectedSeason);
  }

  void _fetch(String season) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final tags = widget.clanInfo.memberList.map((m) => m.tag).toList();
      context.read<ClanService>().fetchSeasonTopPerformers(
            widget.clanInfo.tag,
            season,
            tags,
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    final data = context
        .watch<ClanService>()
        .getSeasonTopPerformers(widget.clanInfo.tag, _selectedSeason);

    final nameByTag = {
      for (final m in widget.clanInfo.memberList) m.tag: m.name,
    };

    return Column(
      children: [
        const SizedBox(height: 8),
        _SeasonSelector(
          seasons: _seasons,
          selected: _selectedSeason,
          onChanged: (s) {
            setState(() => _selectedSeason = s);
            _fetch(s);
          },
        ),
        const SizedBox(height: 8),
        if (data == null)
          const Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: CircularProgressIndicator()),
          )
        else
          ..._categories.map((cat) {
            final items = data[cat.key] as List<dynamic>? ?? [];
            if (items.isEmpty) return const SizedBox.shrink();
            return _CategoryCard(
              cat: cat,
              items: items,
              nameByTag: nameByTag,
            );
          }),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _SeasonSelector extends StatelessWidget {
  final List<String> seasons;
  final String selected;
  final void Function(String) onChanged;

  const _SeasonSelector({
    required this.seasons,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 32,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: seasons.length,
        separatorBuilder: (context, i) => const SizedBox(width: 6),
        itemBuilder: (context, i) {
          final season = seasons[i];
          final parts = season.split('-');
          final label = parts.length == 2
              ? DateFormat('MMM yy')
                  .format(DateTime(int.parse(parts[0]), int.parse(parts[1])))
              : season;
          final isSelected = selected == season;
          return ChoiceChip(
            label: Text(label),
            selected: isSelected,
            onSelected: (_) => onChanged(season),
            labelStyle: TextStyle(
              fontSize: 11,
              color: isSelected
                  ? Theme.of(context).colorScheme.onPrimary
                  : Theme.of(context).colorScheme.onSurface,
            ),
          );
        },
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final _CatInfo cat;
  final List<dynamic> items;
  final Map<String, String> nameByTag;

  const _CategoryCard({
    required this.cat,
    required this.items,
    required this.nameByTag,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CachedNetworkImage(
                  imageUrl: cat.imageUrl,
                  width: 20,
                  height: 20,
                  errorWidget: (ctx, url, err) =>
                      const Icon(Icons.star, size: 20),
                ),
                const SizedBox(width: 8),
                Text(
                  cat.label,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...items.asMap().entries.map((e) {
              final rank = e.key + 1;
              final item = e.value as Map<String, dynamic>;
              final tag = item['tag'] as String? ?? '';
              final value = item['value'] as num? ?? 0;
              final name = nameByTag[tag] ?? tag;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    SizedBox(
                      width: 20,
                      child: Text(
                        '$rank.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: rank == 1
                                  ? Colors.amber
                                  : rank == 2
                                      ? Colors.grey[400]
                                      : rank == 3
                                          ? Colors.brown[300]
                                          : null,
                              fontWeight: rank <= 3 ? FontWeight.bold : null,
                            ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        name,
                        style: Theme.of(context).textTheme.bodySmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      NumberFormat('#,###').format(value),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
