import 'package:clashking_design_system/clashking_design_system.dart';
import 'package:clashkingapp/common/widgets/empty_state.dart';
import 'package:clashkingapp/common/widgets/loading/skeleton_loading.dart';
import 'package:clashkingapp/common/widgets/mobile_web_image.dart';
import 'package:clashkingapp/common/widgets/responsive_card_grid.dart';
import 'package:clashkingapp/core/constants/image_assets.dart';
import 'package:clashkingapp/features/player/data/player_service.dart';
import 'package:clashkingapp/features/player/models/player_cwl_history.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class PlayerCwlHistoryTab extends StatefulWidget {
  const PlayerCwlHistoryTab({
    super.key,
    required this.playerTag,
    required this.bottomPadding,
  });

  final String playerTag;
  final double bottomPadding;

  @override
  State<PlayerCwlHistoryTab> createState() => _PlayerCwlHistoryTabState();
}

class _PlayerCwlHistoryTabState extends State<PlayerCwlHistoryTab> {
  late Future<PlayerCwlHistory> _load;
  String? _selectedSeason;

  @override
  void initState() {
    super.initState();
    _load = _loadHistory();
  }

  Future<PlayerCwlHistory> _loadHistory({bool forceRefresh = false}) => context
      .read<PlayerService>()
      .loadPlayerCwlHistory(widget.playerTag, forceRefresh: forceRefresh);

  Future<void> _refresh() async {
    final load = _loadHistory(forceRefresh: true);
    setState(() => _load = load);
    await load;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PlayerCwlHistory>(
      future: _load,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            snapshot.data == null) {
          return ListView(
            primary: true,
            padding: EdgeInsets.fromLTRB(16, 12, 16, widget.bottomPadding),
            children: const [SkeletonList(itemCount: 5)],
          );
        }
        final loc = AppLocalizations.of(context)!;
        if (snapshot.hasError && snapshot.data == null) {
          return ListView(
            primary: true,
            children: [
              AppEmptyState(
                icon: Icons.cloud_off_rounded,
                title: loc.generalError,
                body: loc.generalTryAgain,
                actionLabel: loc.generalRetry,
                onAction: _refresh,
              ),
            ],
          );
        }
        final seasons = snapshot.data?.items ?? const <PlayerCwlSeason>[];
        if (seasons.isEmpty) {
          return ListView(
            primary: true,
            children: [
              AppEmptyState(
                icon: Icons.emoji_events_outlined,
                title: loc.cwlHistoryEmptyTitle,
                body: loc.cwlHistoryEmptyBody,
              ),
            ],
          );
        }
        final selected = seasons.firstWhere(
          (season) => season.season == _selectedSeason,
          orElse: () => seasons.first,
        );
        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            primary: true,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(16, 10, 16, widget.bottomPadding),
            children: [
              Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      DropdownButtonFormField<String>(
                        initialValue: selected.season,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: loc.warStatsSelectSeason,
                          prefixIcon: const Icon(Icons.calendar_month_rounded),
                        ),
                        items: [
                          for (final season in seasons)
                            DropdownMenuItem(
                              value: season.season,
                              child: Text(
                                _seasonLabel(context, season.season),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                        onChanged: (value) =>
                            setState(() => _selectedSeason = value),
                      ),
                      const SizedBox(height: CKSpacing.md),
                      _SeasonSummary(season: selected),
                      const SizedBox(height: CKSpacing.md),
                      Text(
                        loc.warAttacksTitle,
                        style: CKTypography.of(
                          context,
                          CKTextRole.sectionTitle,
                        ),
                      ),
                      const SizedBox(height: CKSpacing.sm),
                      ResponsiveCardGrid(
                        itemCount: selected.attacks.length,
                        minItemWidth: 430,
                        maxColumns: 2,
                        spacing: CKSpacing.md,
                        itemBuilder: (_, index) =>
                            _CwlAttackRow(attack: selected.attacks[index]),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SeasonSummary extends StatelessWidget {
  const _SeasonSummary({required this.season});

  final PlayerCwlSeason season;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final leagueImage = ImageAssets.getWarLeagueImage(season.clan.leagueName);
    return CKSectionPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              SizedBox.square(
                dimension: 58,
                child: MobileWebImage(imageUrl: season.clan.badgeUrl),
              ),
              const SizedBox(width: CKSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      season.clan.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: CKTypography.of(context, CKTextRole.sectionTitle),
                    ),
                    const SizedBox(height: CKSpacing.xs),
                    Row(
                      children: [
                        SizedBox.square(
                          dimension: 24,
                          child: MobileWebImage(imageUrl: leagueImage),
                        ),
                        const SizedBox(width: CKSpacing.xs),
                        Expanded(
                          child: Text(
                            season.clan.leagueName,
                            overflow: TextOverflow.ellipsis,
                            style: CKTypography.of(
                              context,
                              CKTextRole.metadata,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox.square(
                dimension: 46,
                child: MobileWebImage(
                  imageUrl: ImageAssets.townHall(season.townHallLevel),
                ),
              ),
            ],
          ),
          const SizedBox(height: CKSpacing.md),
          CKMetricChipGrid(
            columns: MediaQuery.sizeOf(context).width < 420 ? 2 : 3,
            chips: [
              CKMetricChip(
                label: loc.warStarsTitle,
                value: '${season.stars}',
                iconData: Icons.star_rounded,
              ),
              CKMetricChip(
                label: loc.warAttacksTitle,
                value: '${season.attacks.length}',
                iconData: Icons.gps_fixed_rounded,
              ),
              CKMetricChip(
                label: loc.warAttacksMissedShort,
                value: '${season.missedAttacks}',
                iconData: Icons.remove_circle_outline_rounded,
              ),
              CKMetricChip(
                label: loc.cwlRankTitle,
                value: '#${season.clanPlacement ?? '-'}',
                iconData: Icons.emoji_events_rounded,
              ),
              CKMetricChip(
                label: loc.cwlWarsPlayedTitle,
                value:
                    '${season.clan.won}-${season.clan.lost}-${season.clan.tied}',
                iconData: Icons.military_tech_rounded,
              ),
              CKMetricChip(
                label: loc.generalTotal,
                value: '${season.clan.totalStars ?? '-'}',
                iconData: Icons.auto_awesome_rounded,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CwlAttackRow extends StatelessWidget {
  const _CwlAttackRow({required this.attack});

  final PlayerCwlAttack attack;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    return CKSectionPanel(
      padding: const EdgeInsets.all(CKSpacing.md),
      child: Row(
        children: [
          SizedBox.square(
            dimension: 48,
            child: MobileWebImage(
              imageUrl: ImageAssets.townHall(attack.defenderTownHallLevel),
            ),
          ),
          const SizedBox(width: CKSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  attack.defenderName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: CKTypography.of(context, CKTextRole.rowTitle),
                ),
                const SizedBox(height: CKSpacing.xs),
                Text(
                  '${attack.opponentName} · ${loc.cwlRoundShort(attack.round)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: CKTypography.of(
                    context,
                    CKTextRole.metadata,
                  ).copyWith(color: scheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          const SizedBox(width: CKSpacing.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                List.filled(attack.stars, '★').join(),
                style: CKTypography.of(
                  context,
                  CKTextRole.rowTitle,
                ).copyWith(color: CKColors.warGold),
              ),
              Text(
                '${attack.destructionPercentage}%',
                style: CKTypography.of(context, CKTextRole.metadata),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

String _seasonLabel(BuildContext context, String raw) {
  final parsed = DateTime.tryParse(raw);
  if (parsed == null) return raw;
  return DateFormat.yMMMM(
    Localizations.localeOf(context).toString(),
  ).format(parsed);
}
