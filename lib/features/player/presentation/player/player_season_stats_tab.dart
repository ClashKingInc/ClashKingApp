import 'package:clashkingapp/features/player/models/player.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PlayerSeasonStatsTab extends StatefulWidget {
  final Player player;

  const PlayerSeasonStatsTab({super.key, required this.player});

  @override
  State<PlayerSeasonStatsTab> createState() => _PlayerSeasonStatsTabState();
}

class _PlayerSeasonStatsTabState extends State<PlayerSeasonStatsTab> {
  late String _selectedSeason;
  late List<String> _availableSeasons;

  @override
  void initState() {
    super.initState();
    _availableSeasons = _buildSeasonList();
    _selectedSeason = _availableSeasons.isNotEmpty ? _availableSeasons.first : '';
  }

  List<String> _buildSeasonList() {
    final keys = <String>{
      ...widget.player.goldBySeason.keys,
      ...widget.player.darkElixirBySeason.keys,
      ...widget.player.activityBySeason.keys,
      ...widget.player.attackWinsBySeason.keys,
      ...widget.player.seasonTrophiesBySeason.keys,
      ...widget.player.donationsBySeason.keys,
    };
    final sorted = keys.toList()..sort((a, b) => b.compareTo(a));
    return sorted;
  }

  String _formatSeason(String season) {
    try {
      final parts = season.split('-');
      if (parts.length == 2) {
        final year = int.parse(parts[0]);
        final month = int.parse(parts[1]);
        return DateFormat('MMM yyyy').format(DateTime(year, month));
      }
    } catch (_) {}
    return season;
  }

  @override
  Widget build(BuildContext context) {
    if (_availableSeasons.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 48, horizontal: 24),
        child: Center(
          child: Text(
            'No season history tracked yet.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SeasonSelector(
          seasons: _availableSeasons,
          selected: _selectedSeason,
          formatSeason: _formatSeason,
          onChanged: (s) => setState(() => _selectedSeason = s),
        ),
        const SizedBox(height: 8),
        _SeasonStatsGrid(
          season: _selectedSeason,
          player: widget.player,
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _SeasonSelector extends StatelessWidget {
  final List<String> seasons;
  final String selected;
  final String Function(String) formatSeason;
  final ValueChanged<String> onChanged;

  const _SeasonSelector({
    required this.seasons,
    required this.selected,
    required this.formatSeason,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: cs.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: DropdownButton<String>(
            value: selected,
            isExpanded: true,
            underline: const SizedBox.shrink(),
            borderRadius: BorderRadius.circular(12),
            items: seasons
                .map(
                  (s) => DropdownMenuItem(
                    value: s,
                    child: Text(
                      formatSeason(s),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                )
                .toList(),
            onChanged: (v) {
              if (v != null) onChanged(v);
            },
          ),
        ),
      ),
    );
  }
}

class _SeasonStatsGrid extends StatelessWidget {
  final String season;
  final Player player;

  const _SeasonStatsGrid({required this.season, required this.player});

  @override
  Widget build(BuildContext context) {
    final donations = player.donationsBySeason[season];
    final given = donations?['donated'] ?? 0;
    final received = donations?['received'] ?? 0;

    final stats = [
      _StatItem(
        icon: Icons.wb_sunny_rounded,
        color: const Color(0xFFFFD700),
        label: 'Gold Grabbed',
        value: _fmt(player.goldBySeason[season] ?? 0),
      ),
      _StatItem(
        icon: Icons.water_drop_rounded,
        color: const Color(0xFF9C27B0),
        label: 'Dark Elixir',
        value: _fmt(player.darkElixirBySeason[season] ?? 0),
      ),
      _StatItem(
        icon: Icons.bolt_rounded,
        color: const Color(0xFF2196F3),
        label: 'Activity',
        value: _fmt(player.activityBySeason[season] ?? 0),
      ),
      _StatItem(
        icon: Icons.military_tech_rounded,
        color: const Color(0xFFF44336),
        label: 'Attack Wins',
        value: _fmt(player.attackWinsBySeason[season] ?? 0),
      ),
      _StatItem(
        icon: Icons.emoji_events_rounded,
        color: const Color(0xFFFF9800),
        label: 'Season Trophies',
        value: _fmt(player.seasonTrophiesBySeason[season] ?? 0),
      ),
      _StatItem(
        icon: Icons.card_giftcard_rounded,
        color: const Color(0xFF4CAF50),
        label: 'Donated',
        value: _fmt(given),
      ),
      _StatItem(
        icon: Icons.move_to_inbox_rounded,
        color: const Color(0xFF00BCD4),
        label: 'Received',
        value: _fmt(received),
      ),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 2.4,
        ),
        itemCount: stats.length,
        itemBuilder: (context, index) => _StatCard(stat: stats[index]),
      ),
    );
  }

  static String _fmt(int value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    }
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    }
    return value.toString();
  }
}

class _StatItem {
  final IconData icon;
  final Color color;
  final String label;
  final String value;

  const _StatItem({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });
}

class _StatCard extends StatelessWidget {
  final _StatItem stat;

  const _StatCard({required this.stat});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: stat.color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(stat.icon, color: stat.color, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    stat.value,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    stat.label,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
