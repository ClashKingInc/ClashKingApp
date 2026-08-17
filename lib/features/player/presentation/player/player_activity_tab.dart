import 'package:clashking_design_system/clashking_design_system.dart';
import 'package:clashkingapp/common/theme/app_tokens.dart';
import 'package:clashkingapp/common/widgets/empty_state.dart';
import 'package:clashkingapp/common/widgets/loading/skeleton_loading.dart';
import 'package:clashkingapp/common/widgets/mobile_web_image.dart';
import 'package:clashkingapp/common/widgets/responsive_card_grid.dart';
import 'package:clashkingapp/core/constants/image_assets.dart';
import 'package:clashkingapp/features/coc_accounts/data/coc_account_service.dart';
import 'package:clashkingapp/features/player/data/player_service.dart';
import 'package:clashkingapp/features/player/models/player_activity.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class PlayerActivityTab extends StatefulWidget {
  const PlayerActivityTab({
    super.key,
    required this.playerTag,
    required this.bottomPadding,
  });

  final String playerTag;
  final double bottomPadding;

  @override
  State<PlayerActivityTab> createState() => _PlayerActivityTabState();
}

class _PlayerActivityTabState extends State<PlayerActivityTab> {
  late Future<PlayerActivityFeed> _load;

  @override
  void initState() {
    super.initState();
    _load = context.read<PlayerService>().loadPlayerActivity(widget.playerTag);
  }

  Future<void> _refresh() async {
    final next = context.read<PlayerService>().loadPlayerActivity(
      widget.playerTag,
      forceRefresh: true,
    );
    setState(() => _load = next);
    await next;
  }

  @override
  Widget build(BuildContext context) {
    final normalizedTag = _normalizeTag(widget.playerTag);
    final verified = context.select<CocAccountService, bool>(
      (service) => service.verifiedAccounts.any(
        (account) =>
            _normalizeTag(account['player_tag']?.toString() ?? '') ==
            normalizedTag,
      ),
    );
    return FutureBuilder<PlayerActivityFeed>(
      future: _load,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            snapshot.data == null) {
          return ListView(
            primary: true,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(16, 12, 16, widget.bottomPadding),
            children: const [SkeletonList(itemCount: 5)],
          );
        }
        if (snapshot.hasError && snapshot.data == null) {
          final loc = AppLocalizations.of(context)!;
          return ListView(
            primary: true,
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              AppEmptyState(
                icon: Icons.cloud_off_rounded,
                title: loc.playerActivityLoadError,
                body: loc.generalTryAgain,
                actionLabel: loc.generalRetry,
                onAction: _refresh,
              ),
            ],
          );
        }
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
                  child: _ActivityContent(
                    feed: snapshot.data!,
                    verifiedTracking: verified,
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

String _normalizeTag(String tag) =>
    tag.replaceAll('#', '').trim().toUpperCase();

class _ActivityContent extends StatelessWidget {
  const _ActivityContent({
    required this.feed,
    required this.verifiedTracking,
  });

  final PlayerActivityFeed feed;
  final bool verifiedTracking;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _TrackingCoverage(verifiedTracking: verifiedTracking),
        const SizedBox(height: CKSpacing.md),
        if (feed.items.isEmpty)
          AppEmptyState(
            icon: Icons.history_toggle_off_rounded,
            title: loc.playerActivityNoEventsTitle,
            body: loc.playerActivityNoEventsBody,
            padding: EdgeInsets.zero,
          )
        else
          ResponsiveCardGrid(
            itemCount: feed.items.length,
            minItemWidth: 430,
            maxColumns: 2,
            spacing: CKSpacing.md,
            itemBuilder: (_, index) => _ActivityRow(event: feed.items[index]),
          ),
      ],
    );
  }
}

class _TrackingCoverage extends StatelessWidget {
  const _TrackingCoverage({required this.verifiedTracking});

  final bool verifiedTracking;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final color = verifiedTracking ? StatColors.win : CKColors.capitalOrange;
    final title = verifiedTracking
        ? loc.playerActivityTrackingActive
        : loc.playerActivityTrackingUnknown;
    final body = verifiedTracking
        ? loc.playerActivityTrackingActiveBody
        : loc.playerActivityTrackingUnknownBody;
    return CKSectionPanel(
      child: Semantics(
        label: '$title. $body',
        excludeSemantics: true,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.14),
                shape: BoxShape.circle,
              ),
              child: SizedBox.square(
                dimension: 42,
                child: Icon(
                  verifiedTracking
                      ? Icons.radar_rounded
                      : Icons.info_outline_rounded,
                  color: color,
                ),
              ),
            ),
            const SizedBox(width: CKSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: CKTypography.of(context, CKTextRole.rowTitle),
                  ),
                  const SizedBox(height: CKSpacing.xs),
                  Text(
                    body,
                    style: CKTypography.of(
                      context,
                      CKTextRole.metadata,
                    ).copyWith(color: scheme.onSurfaceVariant),
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

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({required this.event});

  final PlayerActivityEvent event;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final locale = Localizations.localeOf(context).toString();
    final date = DateFormat.yMMMd(locale).add_jm().format(event.time.toLocal());
    final title = switch (event.kind) {
      PlayerActivityKind.townHallUpgrade => loc.playerActivityTownHallUpgraded,
      PlayerActivityKind.superTroopBoost =>
        loc.playerActivitySuperTroopBoosted(event.name),
      PlayerActivityKind.itemUnlocked =>
        loc.playerActivityItemUnlocked(event.name),
      PlayerActivityKind.nameChange => loc.playerActivityNameChanged,
      _ => loc.playerActivityItemUpgraded(event.name),
    };
    final detail = switch (event.kind) {
      PlayerActivityKind.nameChange => loc.playerActivityNameChangeDetail(
        event.previousValue ?? '',
        event.currentValue ?? event.name,
      ),
      PlayerActivityKind.itemUnlocked => loc.playerActivityUnlockedAtLevel(
        event.currentLevel ?? 0,
      ),
      PlayerActivityKind.superTroopBoost => loc.playerActivityBoostedAtLevel(
        event.currentLevel ?? 0,
      ),
      _ => loc.playerActivityLevelChange(
        event.previousLevel ?? 0,
        event.currentLevel ?? 0,
      ),
    };
    final artwork = _eventArtwork(event);
    final accent = _eventAccent(event);
    return CKSectionPanel(
      padding: const EdgeInsets.all(CKSpacing.md),
      child: Semantics(
        label: '$title. $detail. $date',
        excludeSemantics: true,
        child: Row(
          children: [
            SizedBox.square(
              dimension: 48,
              child: artwork == null
                  ? DecoratedBox(
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.14),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.edit_rounded, color: accent),
                    )
                  : MobileWebImage(imageUrl: artwork),
            ),
            const SizedBox(width: CKSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: CKTypography.of(context, CKTextRole.rowTitle),
                  ),
                  const SizedBox(height: CKSpacing.xs),
                  Text(
                    detail,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: CKTypography.of(
                      context,
                      CKTextRole.metadata,
                    ).copyWith(color: accent),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    date,
                    style: CKTypography.of(
                      context,
                      CKTextRole.metadata,
                    ).copyWith(color: scheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String? _eventArtwork(PlayerActivityEvent event) => switch (event.itemType) {
    PlayerActivityItemType.townHall =>
      ImageAssets.townHall(event.currentLevel ?? 1),
    PlayerActivityItemType.troop => ImageAssets.getTroopImage(event.name),
    PlayerActivityItemType.hero => ImageAssets.getHeroImage(event.name),
    PlayerActivityItemType.spell => ImageAssets.getSpellImage(event.name),
    PlayerActivityItemType.equipment => ImageAssets.getGearImage(event.name),
    PlayerActivityItemType.profile => null,
  };

  Color _eventAccent(PlayerActivityEvent event) => switch (event.kind) {
    PlayerActivityKind.superTroopBoost => CKColors.capitalPurple,
    PlayerActivityKind.townHallUpgrade => CKColors.warGold,
    PlayerActivityKind.nameChange => CKColors.builderBlue,
    PlayerActivityKind.itemUnlocked => CKColors.donationGreen,
    _ => CKColors.legendBlue,
  };
}
