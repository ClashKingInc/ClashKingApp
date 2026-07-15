import 'package:clashkingapp/features/player/models/player.dart';
import 'package:clashkingapp/common/widgets/empty_state.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';
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
    _selectedSeason = _availableSeasons.isNotEmpty
        ? _availableSeasons.first
        : '';
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
      return AppEmptyState(
        title: AppLocalizations.of(context)!.generalNoDataAvailable,
        icon: Icons.history_toggle_off_rounded,
        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
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
        _SeasonStatsGrid(season: _selectedSeason, player: widget.player),
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
    final theme = Theme.of(context);
    final surfaceColor = theme.cardTheme.color ?? theme.colorScheme.surface;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.32),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            children: [
              Icon(
                Icons.calendar_month_rounded,
                size: 18,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButton<String>(
                  value: selected,
                  isExpanded: true,
                  underline: const SizedBox.shrink(),
                  borderRadius: BorderRadius.circular(16),
                  // The theme's canvasColor is transparent (for the glass
                  // nav bar), which DropdownButton uses for its menu —
                  // give the menu an explicit opaque background.
                  dropdownColor: surfaceColor,
                  icon: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  items: seasons
                      .map(
                        (s) => DropdownMenuItem(
                          value: s,
                          child: Text(
                            formatSeason(s),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (v) {
                    if (v != null) onChanged(v);
                  },
                ),
              ),
            ],
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
    final loc = AppLocalizations.of(context)!;
    final donations = player.donationsBySeason[season];
    final given = donations?['donated'] ?? 0;
    final received = donations?['received'] ?? 0;

    // Same metric palette as the home to-do card and player header bars.
    final stats = [
      _StatItem(
        icon: Icons.wb_sunny_rounded,
        color: const Color(0xFFE8A524),
        label: loc.seasonStatsGoldGrabbed,
        value: _fmt(player.goldBySeason[season] ?? 0),
      ),
      _StatItem(
        icon: Icons.water_drop_rounded,
        color: const Color(0xFF8D63D9),
        label: loc.resourceDarkElixir,
        value: _fmt(player.darkElixirBySeason[season] ?? 0),
      ),
      _StatItem(
        icon: Icons.bolt_rounded,
        color: const Color(0xFF2A9FD6),
        label: loc.seasonStatsActivity,
        value: _fmt(player.activityBySeason[season] ?? 0),
      ),
      _StatItem(
        icon: Icons.military_tech_rounded,
        color: const Color(0xFFE35D4F),
        label: loc.seasonStatsAttackWins,
        value: _fmt(player.attackWinsBySeason[season] ?? 0),
      ),
      _StatItem(
        icon: Icons.emoji_events_rounded,
        color: const Color(0xFFE07B39),
        label: loc.seasonStatsTrophies,
        value: _fmt(player.seasonTrophiesBySeason[season] ?? 0),
      ),
      _StatItem(
        icon: Icons.card_giftcard_rounded,
        color: const Color(0xFF14A37F),
        label: loc.playerDonatedTitle,
        value: _fmt(given),
      ),
      _StatItem(
        icon: Icons.move_to_inbox_rounded,
        color: const Color(0xFF00BCD4),
        label: loc.playerReceivedTitle,
        value: _fmt(received),
      ),
    ];

    // Two columns; an odd trailing item spans the full row, like the
    // home to-do card metrics.
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        children: [
          for (var i = 0; i < stats.length; i += 2)
            Padding(
              padding: EdgeInsets.only(top: i == 0 ? 0 : 8),
              child: Row(
                children: [
                  Expanded(child: _StatCard(stat: stats[i])),
                  if (i + 1 < stats.length) ...[
                    const SizedBox(width: 8),
                    Expanded(child: _StatCard(stat: stats[i + 1])),
                  ],
                ],
              ),
            ),
        ],
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

    // Same tinted metric bar as the player header stats.
    return SizedBox(
      height: 46,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: stat.color.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 9),
          child: Row(
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: cs.surface.withValues(alpha: 0.72),
                  shape: BoxShape.circle,
                ),
                child: SizedBox.square(
                  dimension: 30,
                  child: Icon(stat.icon, color: stat.color, size: 17),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stat.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: cs.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      stat.value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: stat.color,
                        fontWeight: FontWeight.w900,
                        height: 1.1,
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
