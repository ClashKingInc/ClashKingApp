import 'package:clashking_design_system/clashking_design_system.dart';
import 'package:clashkingapp/common/widgets/empty_state.dart';
import 'package:clashkingapp/common/widgets/inputs/filter_dropdown.dart';
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
  PlayerHistoryType _type = PlayerHistoryType.troopLevel;
  late Future<PlayerActivityFeed> _load;

  @override
  void initState() {
    super.initState();
    _load = _loadActivity();
  }

  Future<PlayerActivityFeed> _loadActivity({bool forceRefresh = false}) =>
      context.read<PlayerService>().loadPlayerActivity(
        widget.playerTag,
        type: _type,
        forceRefresh: forceRefresh,
      );

  Future<void> _refresh() async {
    final next = _loadActivity(forceRefresh: true);
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
                    type: _type,
                    onTypeChanged: (type) {
                      if (type == _type) return;
                      setState(() {
                        _type = type;
                        _load = _loadActivity();
                      });
                    },
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
    required this.type,
    required this.onTypeChanged,
  });

  final PlayerActivityFeed feed;
  final bool verifiedTracking;
  final PlayerHistoryType type;
  final ValueChanged<PlayerHistoryType> onTypeChanged;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: FilterDropdown(
                sortBy: type.apiValue,
                fillWidth: true,
                leadingIcon: Icons.filter_list_rounded,
                sortByOptions: {
                  for (final option in PlayerHistoryType.values)
                    _historyTypeLabel(option, loc): option.apiValue,
                },
                updateSortBy: (value) => onTypeChanged(
                  PlayerHistoryType.values.firstWhere(
                    (option) => option.apiValue == value,
                  ),
                ),
              ),
            ),
            const SizedBox(width: CKSpacing.sm),
            _TrackingCoverage(verifiedTracking: verifiedTracking),
          ],
        ),
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
    final title = verifiedTracking
        ? loc.playerActivityTrackingActive
        : loc.playerActivityTrackingUnknown;
    final body = verifiedTracking
        ? loc.playerActivityTrackingActiveBody
        : loc.playerActivityTrackingUnknownBody;
    return Semantics(
      button: true,
      label: '$title. $body',
      child: Tooltip(
        message: title,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => showDialog<void>(
            context: context,
            builder: (context) => AlertDialog(
              icon: Icon(
                verifiedTracking
                    ? Icons.track_changes_rounded
                    : Icons.info_outline_rounded,
              ),
              title: Text(title),
              content: Text(body),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    MaterialLocalizations.of(context).closeButtonLabel,
                  ),
                ),
              ],
            ),
          ),
          child: Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 11),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: scheme.outlineVariant.withValues(alpha: 0.32),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  verifiedTracking
                      ? Icons.track_changes_rounded
                      : Icons.info_outline_rounded,
                  size: 18,
                  color: scheme.onSurface,
                ),
                const SizedBox(width: 6),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 116),
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: CKTypography.of(context, CKTextRole.compactLabel),
                  ),
                ),
              ],
            ),
          ),
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
    final localTime = event.time.toLocal();
    final locale = Localizations.localeOf(context).toString();
    final datePart = DateFormat.yMMMd(locale).format(localTime);
    final timePart = MaterialLocalizations.of(context).formatTimeOfDay(
      TimeOfDay.fromDateTime(localTime),
      alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
    );
    final date = '$datePart · $timePart';
    final title = switch (event.kind) {
      PlayerActivityKind.townHallUpgrade => loc.playerActivityTownHallUpgraded,
      PlayerActivityKind.superTroopBoost => loc.playerActivitySuperTroopBoosted(
        event.name,
      ),
      PlayerActivityKind.itemUnlocked => loc.playerActivityItemUnlocked(
        event.name,
      ),
      PlayerActivityKind.experienceLevelChange => loc.gameExpLevel,
      PlayerActivityKind.trophyRecord => loc.playerBestTrophies,
      PlayerActivityKind.builderTrophyRecord =>
        '${loc.playerBestTrophies} · ${loc.gameBaseBuilder}',
      PlayerActivityKind.warPreferenceChange => loc.playerWarPreferenceTitle,
      _ => loc.playerActivityItemUpgraded(event.name),
    };
    final detail = switch (event.kind) {
      PlayerActivityKind.experienceLevelChange ||
      PlayerActivityKind.trophyRecord ||
      PlayerActivityKind.builderTrophyRecord ||
      PlayerActivityKind.warPreferenceChange =>
        loc.playerActivityNameChangeDetail(
          event.previousValue ?? '',
          event.currentValue ?? '',
        ),
      PlayerActivityKind.itemUnlocked => loc.playerActivityUnlockedAtLevel(
        event.currentLevel ?? 0,
      ),
      PlayerActivityKind.superTroopBoost => null,
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
        label: [title, detail, date].whereType<String>().join('. '),
        excludeSemantics: true,
        child: Row(
          children: [
            SizedBox.square(
              dimension: 48,
              child: MobileWebImage(imageUrl: artwork),
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
                  if (detail != null) ...[
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
                  ],
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

  String _eventArtwork(PlayerActivityEvent event) {
    if (event.kind == PlayerActivityKind.experienceLevelChange) {
      return ImageAssets.xp;
    }
    if (event.kind == PlayerActivityKind.warPreferenceChange) {
      final value = event.currentValue?.toLowerCase();
      final optedIn = value == 'true' || value == 'in' || value == '1';
      return optedIn
          ? ImageAssets.warPreferenceIn
          : ImageAssets.warPreferenceOut;
    }
    return switch (event.itemType) {
      PlayerActivityItemType.townHall => ImageAssets.townHall(
        event.currentLevel ?? 1,
      ),
      PlayerActivityItemType.troop => ImageAssets.getTroopImage(event.name),
      PlayerActivityItemType.hero => ImageAssets.getHeroImage(event.name),
      PlayerActivityItemType.spell => ImageAssets.getSpellImage(event.name),
      PlayerActivityItemType.pet => ImageAssets.getPetImage(event.name),
      PlayerActivityItemType.equipment => ImageAssets.getGearImage(event.name),
      PlayerActivityItemType.trophy =>
        event.kind == PlayerActivityKind.builderTrophyRecord
            ? ImageAssets.builderBaseTrophy
            : ImageAssets.trophies,
      PlayerActivityItemType.profile => ImageAssets.defaultProfile,
    };
  }

  Color _eventAccent(PlayerActivityEvent event) => switch (event.kind) {
    PlayerActivityKind.superTroopBoost => CKColors.capitalPurple,
    PlayerActivityKind.townHallUpgrade => CKColors.warGold,
    PlayerActivityKind.experienceLevelChange => CKColors.builderBlue,
    PlayerActivityKind.trophyRecord => CKColors.legendBlue,
    PlayerActivityKind.builderTrophyRecord => CKColors.builderBlue,
    PlayerActivityKind.warPreferenceChange => CKColors.capitalPurple,
    PlayerActivityKind.itemUnlocked => CKColors.donationGreen,
    _ => CKColors.legendBlue,
  };
}

String _historyTypeLabel(PlayerHistoryType type, AppLocalizations loc) =>
    switch (type) {
      PlayerHistoryType.troopLevel => loc.gameTroops,
      PlayerHistoryType.superTroopBoost => loc.gameActiveSuperTroops,
      PlayerHistoryType.heroLevel => loc.gameHeroes,
      PlayerHistoryType.spellLevel => loc.gameSpells,
      PlayerHistoryType.petLevel => loc.gamePets,
      PlayerHistoryType.equipmentLevel => loc.gameEquipment,
      PlayerHistoryType.townHallLevel => loc.gameTownHallLevel,
      PlayerHistoryType.experienceLevel => loc.gameExpLevel,
      PlayerHistoryType.bestTrophies => loc.playerBestTrophies,
      PlayerHistoryType.bestBuilderBaseTrophies =>
        '${loc.playerBestTrophies} · ${loc.gameBaseBuilder}',
      PlayerHistoryType.warPreference => loc.playerWarPreferenceTitle,
    };
