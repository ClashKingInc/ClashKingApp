import 'package:clashking_design_system/clashking_design_system.dart';
import 'package:clashkingapp/common/widgets/empty_state.dart';
import 'package:clashkingapp/common/widgets/loading/skeleton_loading.dart';
import 'package:clashkingapp/common/widgets/mobile_web_image.dart';
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
  Widget build(BuildContext context) => FutureBuilder<PlayerCwlHistory>(
    future: _load,
    builder: (context, snapshot) {
      final loc = AppLocalizations.of(context)!;
      if (snapshot.connectionState == ConnectionState.waiting &&
          snapshot.data == null) {
        return ListView(
          primary: true,
          padding: EdgeInsets.fromLTRB(16, 12, 16, widget.bottomPadding),
          children: const [SkeletonList(itemCount: 5)],
        );
      }
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
      return RefreshIndicator(
        onRefresh: _refresh,
        child: ListView.separated(
          primary: true,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(16, 10, 16, widget.bottomPadding),
          itemCount: seasons.length,
          separatorBuilder: (_, _) => const SizedBox(height: CKSpacing.md),
          itemBuilder: (_, index) => Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1120),
              child: _CwlSeasonCard(season: seasons[index]),
            ),
          ),
        ),
      );
    },
  );
}

class _CwlSeasonCard extends StatelessWidget {
  const _CwlSeasonCard({required this.season});

  final PlayerCwlSeason season;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final leagueImage = ImageAssets.getWarLeagueImage(season.clan.leagueName);
    return CKSectionPanel(
      padding: EdgeInsets.zero,
      child: Material(
        color: Colors.transparent,
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.fromLTRB(
              CKSpacing.md,
              CKSpacing.sm,
              CKSpacing.md,
              CKSpacing.sm,
            ),
            childrenPadding: const EdgeInsets.fromLTRB(
              CKSpacing.md,
              0,
              CKSpacing.md,
              CKSpacing.md,
            ),
            leading: SizedBox.square(
              dimension: 50,
              child: MobileWebImage(
                imageUrl: season.clan.badgeUrl,
                errorWidget: (_, _, _) => const Icon(Icons.shield_outlined),
              ),
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    season.clan.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: CKTypography.of(context, CKTextRole.rowTitle),
                  ),
                ),
                const SizedBox(width: CKSpacing.sm),
                SizedBox.square(
                  dimension: 36,
                  child: MobileWebImage(
                    imageUrl: ImageAssets.townHall(season.townHallLevel),
                    errorWidget: (_, _, _) => const Icon(Icons.home_rounded),
                  ),
                ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 3),
                Text(
                  _seasonLabel(context, season.season),
                  style: CKTypography.of(
                    context,
                    CKTextRole.metadata,
                  ).copyWith(color: scheme.onSurfaceVariant),
                ),
                const SizedBox(height: CKSpacing.xs),
                Row(
                  children: [
                    SizedBox.square(
                      dimension: 22,
                      child: MobileWebImage(
                        imageUrl: leagueImage,
                        errorWidget: (_, _, _) =>
                            const Icon(Icons.military_tech_rounded),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        season.clan.leagueName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: CKTypography.of(context, CKTextRole.metadata),
                      ),
                    ),
                    if (season.clanPlacement != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        '#${season.clanPlacement}',
                        style: CKTypography.of(
                          context,
                          CKTextRole.compactLabel,
                        ).copyWith(color: CKColors.warGold),
                      ),
                    ],
                  ],
                ),
              ],
            ),
            children: [
              CKMetricChipGrid(
                columns: 3,
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
                ],
              ),
              if (season.attacks.isNotEmpty) ...[
                const SizedBox(height: CKSpacing.md),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    loc.warAttacksTitle,
                    style: CKTypography.of(context, CKTextRole.compactLabel),
                  ),
                ),
                const SizedBox(height: CKSpacing.xs),
                for (var index = 0; index < season.attacks.length; index++) ...[
                  if (index > 0)
                    Divider(
                      color: scheme.outlineVariant.withValues(alpha: 0.35),
                    ),
                  _CwlAttackRow(attack: season.attacks[index]),
                ],
              ],
            ],
          ),
        ),
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: CKSpacing.sm),
      child: Row(
        children: [
          SizedBox.square(
            dimension: 44,
            child: MobileWebImage(
              imageUrl: ImageAssets.townHall(attack.defenderTownHallLevel),
              errorWidget: (_, _, _) => const Icon(Icons.home_rounded),
            ),
          ),
          const SizedBox(width: CKSpacing.sm),
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
