import 'package:cached_network_image/cached_network_image.dart';
import 'package:clashkingapp/core/constants/image_assets.dart';
import 'package:clashkingapp/features/clan/data/clan_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ClanCompositionTab extends StatefulWidget {
  final String clanTag;

  const ClanCompositionTab({super.key, required this.clanTag});

  @override
  State<ClanCompositionTab> createState() => _ClanCompositionTabState();
}

class _ClanCompositionTabState extends State<ClanCompositionTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<ClanService>().fetchClanComposition(widget.clanTag);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final compo = context.watch<ClanService>().getClanComposition(widget.clanTag);

    if (compo == null) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final townhall = Map<String, int>.from(
      (compo['townhall'] as Map? ?? {}).map((k, v) => MapEntry(k.toString(), (v as num).toInt())),
    );
    final league = Map<String, int>.from(
      (compo['league'] as Map? ?? {}).map((k, v) => MapEntry(k.toString(), (v as num).toInt())),
    );
    final location = Map<String, int>.from(
      (compo['location'] as Map? ?? {}).map((k, v) => MapEntry(k.toString(), (v as num).toInt())),
    );
    final countryMap = Map<String, String>.from(
      (compo['country_map'] as Map? ?? {}).map((k, v) => MapEntry(k.toString(), v.toString())),
    );
    final total = (compo['total_members'] as num? ?? 1).toInt();

    final sortedTH = townhall.entries.toList()
      ..sort((a, b) {
        final ia = int.tryParse(a.key) ?? 0;
        final ib = int.tryParse(b.key) ?? 0;
        return ib.compareTo(ia);
      });

    final leagueOrder = [
      'Legend League',
      'Titan League I', 'Titan League II', 'Titan League III',
      'Champion League I', 'Champion League II', 'Champion League III',
      'Master League I', 'Master League II', 'Master League III',
      'Crystal League I', 'Crystal League II', 'Crystal League III',
      'Gold League I', 'Gold League II', 'Gold League III',
      'Silver League I', 'Silver League II', 'Silver League III',
      'Bronze League I', 'Bronze League II', 'Bronze League III',
      'Unranked',
    ];
    final sortedLeagues = league.entries.toList()
      ..sort((a, b) {
        final ia = leagueOrder.indexOf(a.key);
        final ib = leagueOrder.indexOf(b.key);
        return (ia == -1 ? 99 : ia).compareTo(ib == -1 ? 99 : ib);
      });

    final sortedCountries = location.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle('Town Hall'),
          const SizedBox(height: 6),
          ...sortedTH.map((e) => _BarRow(
            leading: CachedNetworkImage(
              imageUrl: ImageAssets.townHall(int.tryParse(e.key) ?? 1),
              width: 28,
              height: 28,
              errorWidget: (ctx, url, err) => const Icon(Icons.error, size: 20),
            ),
            label: 'TH${e.key}',
            count: e.value,
            total: total,
          )),
          const SizedBox(height: 16),
          _SectionTitle('League'),
          const SizedBox(height: 6),
          ...sortedLeagues.map((e) => _BarRow(
            leading: CachedNetworkImage(
              imageUrl: ImageAssets.getLeagueImage(e.key),
              width: 28,
              height: 28,
              errorWidget: (ctx, url, err) => const Icon(Icons.error, size: 20),
            ),
            label: e.key,
            count: e.value,
            total: total,
          )),
          if (sortedCountries.isNotEmpty) ...[
            const SizedBox(height: 16),
            _SectionTitle('Countries'),
            const SizedBox(height: 6),
            ...sortedCountries.take(15).map((e) {
              final code = e.key;
              final name = countryMap[code] ?? code;
              return _BarRow(
                leading: CachedNetworkImage(
                  imageUrl: ImageAssets.flag(code),
                  width: 28,
                  height: 20,
                  errorWidget: (ctx, url, err) =>
                      const Icon(Icons.flag, size: 20),
                ),
                label: name,
                count: e.value,
                total: total,
              );
            }),
          ],
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
    );
  }
}

class _BarRow extends StatelessWidget {
  final Widget leading;
  final String label;
  final int count;
  final int total;

  const _BarRow({
    required this.leading,
    required this.label,
    required this.count,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final fraction = total > 0 ? count / total : 0.0;
    final pct = (fraction * 100).round();
    final barColor = Theme.of(context).colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(width: 32, child: Center(child: leading)),
          const SizedBox(width: 6),
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: fraction.toDouble(),
                minHeight: 14,
                backgroundColor: barColor.withAlpha(30),
                valueColor: AlwaysStoppedAnimation<Color>(barColor),
              ),
            ),
          ),
          const SizedBox(width: 6),
          SizedBox(
            width: 42,
            child: Text(
              '$count ($pct%)',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
