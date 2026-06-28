import 'package:clashkingapp/common/widgets/mobile_web_image.dart';
import 'package:clashkingapp/core/constants/image_assets.dart';
import 'package:clashkingapp/features/war_cwl/data/war_cwl_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class CwlRankingHistoryTab extends StatefulWidget {
  final String clanTag;

  const CwlRankingHistoryTab({super.key, required this.clanTag});

  @override
  State<CwlRankingHistoryTab> createState() => _CwlRankingHistoryTabState();
}

class _CwlRankingHistoryTabState extends State<CwlRankingHistoryTab> {
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final service = context.read<WarCwlService>();
    if (service.getCwlRankingHistory(widget.clanTag) != null) return;
    setState(() { _loading = true; _error = null; });
    try {
      await service.fetchCwlRankingHistory(widget.clanTag);
    } catch (_) {
      if (mounted) setState(() => _error = 'Failed to load CWL history');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.all(32),
        child: Center(child: Text(_error!, style: Theme.of(context).textTheme.bodyMedium)),
      );
    }

    final history = context
        .watch<WarCwlService>()
        .getCwlRankingHistory(widget.clanTag);

    if (history == null || history.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Text(
            'No CWL history available',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: history.length,
      separatorBuilder: (context, i) => Divider(
        height: 1,
        color: Theme.of(context).colorScheme.onSurface.withAlpha(30),
      ),
      itemBuilder: (context, i) => _SeasonRow(entry: history[i]),
    );
  }
}

class _SeasonRow extends StatelessWidget {
  final Map<String, dynamic> entry;
  const _SeasonRow({required this.entry});

  @override
  Widget build(BuildContext context) {
    final season = entry['season'] as String? ?? '';
    final leagueName = entry['league'] as String? ?? 'Unranked';
    final rank = entry['rank'] as int?;
    final stars = entry['stars'] as int?;
    final roundsWon = entry['rounds_won'] as int?;
    final roundsLost = entry['rounds_lost'] as int?;

    // Format "2024-06" → "June 2024"
    String seasonLabel = season;
    try {
      final parts = season.split('-');
      if (parts.length == 2) {
        final dt = DateTime(int.parse(parts[0]), int.parse(parts[1]));
        seasonLabel = DateFormat('MMM yyyy').format(dt);
      }
    } catch (_) {}

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          SizedBox(
            width: 36,
            height: 36,
            child: MobileWebImage(
              imageUrl: ImageAssets.getLeagueImage(leagueName),
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(seasonLabel, style: Theme.of(context).textTheme.bodyMedium),
                Text(
                  leagueName,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withAlpha(160),
                  ),
                ),
              ],
            ),
          ),
          if (rank != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '#$rank',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          if (stars != null) ...[
            const SizedBox(width: 10),
            Row(
              children: [
                Icon(Icons.star, size: 14, color: Colors.amber),
                const SizedBox(width: 2),
                Text('$stars', style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ],
          if (roundsWon != null && roundsLost != null) ...[
            const SizedBox(width: 10),
            Text(
              '$roundsWon-$roundsLost',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withAlpha(160),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
