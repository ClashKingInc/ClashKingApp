import 'dart:async';

import 'package:clashkingapp/common/widgets/mobile_web_image.dart';
import 'package:clashkingapp/common/widgets/error/error_page.dart';
import 'package:clashkingapp/common/widgets/indicators/last_refresh_indicator.dart';
import 'package:clashkingapp/common/widgets/responsive_card_grid.dart';
import 'package:clashkingapp/core/constants/image_assets.dart';
import 'package:clashkingapp/core/services/bookmark_service.dart';
import 'package:clashkingapp/core/utils/network_error_utils.dart';
import 'package:clashkingapp/features/clan/data/clan_service.dart';
import 'package:clashkingapp/features/clan/models/clan.dart';
import 'package:clashkingapp/features/clan/presentation/clan_info/clan_page.dart';
import 'package:clashkingapp/features/coc_accounts/data/coc_account_service.dart';
import 'package:clashkingapp/features/pages/widgets/clan_no_clan_card.dart';
import 'package:clashkingapp/features/player/data/player_service.dart';
import 'package:clashkingapp/features/war_cwl/data/war_cwl_service.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollCacheExtent;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class ClanPage extends StatefulWidget {
  const ClanPage({super.key});

  @override
  State<ClanPage> createState() => _ClanPageState();
}

String clanMemberCapacityLabel(int members) => '$members/50';

class _ClanPageState extends State<ClanPage> {
  final Set<String> _requestedBookmarkClanTags = {};

  @override
  Widget build(BuildContext context) {
    final cocService = context.watch<CocAccountService>();
    final clanService = context.watch<ClanService>();
    final playerService = context.watch<PlayerService>();
    final warCwlService = context.read<WarCwlService>();
    final bookmarkService = context.watch<BookmarkService>();
    final players = playerService.profiles;
    final linkedClans = {
      for (final player in players)
        if (player.clan != null && player.clan!.tag.isNotEmpty)
          player.clan!.tag: player.clan!,
    };
    final linkedCards = linkedClans.values.map((clan) {
      final accountCount = players
          .where((player) => player.clanTag == clan.tag)
          .length;
      return _ClanListItem.linked(clan: clan, accountCount: accountCount);
    });
    final missingBookmarkClanTags = bookmarkService.clans
        .where(
          (bookmark) =>
              !linkedClans.containsKey(bookmark.tag) &&
              !_requestedBookmarkClanTags.contains(bookmark.tag) &&
              clanService.getClanByTag(bookmark.tag) == null,
        )
        .map((bookmark) => bookmark.tag)
        .toList(growable: false);
    if (missingBookmarkClanTags.isNotEmpty) {
      _requestedBookmarkClanTags.addAll(missingBookmarkClanTags);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        unawaited(
          clanService.loadAllClanData(missingBookmarkClanTags, notify: true),
        );
      });
    }
    final bookmarkCards = bookmarkService.clans
        .where((bookmark) => !linkedClans.containsKey(bookmark.tag))
        .map(
          (bookmark) => _ClanListItem.bookmarked(
            bookmark,
            hydratedClan: clanService.getClanByTag(bookmark.tag),
          ),
        );
    final clans = [...linkedCards, ...bookmarkCards];
    final isDesktopWeb = kIsWeb && MediaQuery.sizeOf(context).width >= 900;
    final bottomPadding = isDesktopWeb
        ? 32.0
        : MediaQuery.paddingOf(context).bottom + 96;

    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontalPadding =
            ((constraints.maxWidth - (isDesktopWeb ? 1320.0 : 840.0)) / 2)
                .clamp(16.0, double.infinity)
                .toDouble();

        return Scaffold(
          body: RefreshIndicator(
            backgroundColor: Theme.of(context).colorScheme.surface,
            onRefresh: () => _refresh(
              context,
              cocService,
              playerService,
              clanService,
              warCwlService,
            ),
            child: CustomScrollView(
              scrollCacheExtent: const ScrollCacheExtent.pixels(800),
              slivers: [
                SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                  sliver: SliverToBoxAdapter(
                    child: LastRefreshIndicator(
                      lastRefresh: cocService.lastRefresh,
                    ),
                  ),
                ),
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    8,
                    horizontalPadding,
                    bottomPadding,
                  ),
                  sliver: clans.isEmpty
                      ? SliverToBoxAdapter(child: Card(child: NoClanCard()))
                      : isDesktopWeb
                      ? SliverToBoxAdapter(
                          child: ResponsiveCardGrid(
                            itemCount: clans.length,
                            itemBuilder: (context, index) {
                              final item = clans[index];
                              return _ClanCard(
                                item: item,
                                onOpen: () =>
                                    _openClan(context, clanService, item),
                              );
                            },
                          ),
                        )
                      : SliverList.separated(
                          itemCount: clans.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final item = clans[index];
                            return _ClanCard(
                              item: item,
                              onOpen: () =>
                                  _openClan(context, clanService, item),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _openClan(
    BuildContext context,
    ClanService clanService,
    _ClanListItem item,
  ) async {
    if (item.clan != null) {
      if (!context.mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ClanInfoScreen(clanInfo: item.clan!),
        ),
      );
      return;
    }

    try {
      final loadedClan = await clanService.getClanAndWarData(item.tag);
      if (!context.mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ClanInfoScreen(clanInfo: loadedClan),
        ),
      );
    } catch (_) {
      if (!context.mounted || item.clan == null) return;
      if (!context.mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ClanInfoScreen(clanInfo: item.clan!),
        ),
      );
    }
  }

  Future<void> _refresh(
    BuildContext context,
    CocAccountService cocService,
    PlayerService playerService,
    ClanService clanService,
    WarCwlService warCwlService,
  ) async {
    try {
      final playerTags = cocService.getAccountTags();
      if (playerTags.isNotEmpty) {
        await cocService.refreshPageData(
          playerTags,
          playerService,
          clanService,
          warCwlService,
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      if (isNetworkError(e)) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ErrorPage(
              isNetworkError: true,
              onRetry: () async {
                await cocService.refreshPageData(
                  cocService.getAccountTags(),
                  playerService,
                  clanService,
                  warCwlService,
                );
                if (context.mounted) Navigator.of(context).pop();
              },
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.generalRefreshFailed(e.toString()),
            ),
          ),
        );
      }
    }
  }
}

class _ClanListItem {
  const _ClanListItem({
    required this.tag,
    required this.name,
    required this.badgeUrl,
    required this.members,
    required this.warLeague,
    required this.clanPoints,
    required this.countryCode,
    required this.locationName,
    required this.type,
    required this.accountCount,
    required this.bookmarked,
    this.clan,
  });

  final String tag;
  final String name;
  final String badgeUrl;
  final int members;
  final String warLeague;
  final int clanPoints;
  final String countryCode;
  final String locationName;
  final String type;
  final int accountCount;
  final bool bookmarked;
  final Clan? clan;

  factory _ClanListItem.linked({
    required Clan clan,
    required int accountCount,
  }) {
    return _ClanListItem(
      tag: clan.tag,
      name: clan.name,
      badgeUrl: clan.badgeUrls.large,
      members: clan.members,
      warLeague: clan.warLeague?.name ?? 'Unranked',
      clanPoints: clan.clanPoints,
      countryCode: clan.location?.countryCode ?? '',
      locationName: clan.location?.name ?? '',
      type: clan.type,
      accountCount: accountCount,
      bookmarked: false,
      clan: clan,
    );
  }

  factory _ClanListItem.bookmarked(BookmarkedClan clan, {Clan? hydratedClan}) {
    final fullClan = hydratedClan;
    return _ClanListItem(
      tag: clan.tag,
      name: fullClan?.name ?? clan.name,
      badgeUrl: fullClan?.badgeUrls.large ?? clan.badgeUrl,
      members: fullClan?.members ?? clan.memberCount,
      warLeague: fullClan?.warLeague?.name ?? '',
      clanPoints: fullClan?.clanPoints ?? 0,
      countryCode: fullClan?.location?.countryCode ?? '',
      locationName: fullClan?.location?.name ?? '',
      type: fullClan?.type ?? '',
      accountCount: 0,
      bookmarked: true,
      clan: fullClan,
    );
  }
}

class _ClanCard extends StatelessWidget {
  const _ClanCard({required this.item, required this.onOpen});

  final _ClanListItem item;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat('#,###');
    return Semantics(
      button: true,
      label: 'Open clan ${item.name}',
      child: Card(
        margin: EdgeInsets.zero,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onOpen,
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 44, 14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ClanBadgeWithMembers(item: item),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: EdgeInsets.only(
                              right: item.bookmarked ? 28 : 86,
                            ),
                            child: Text(
                              item.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 17,
                                  ),
                            ),
                          ),
                          if (item.countryCode.isNotEmpty &&
                              item.locationName.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                SizedBox.square(
                                  dimension: 13,
                                  child: MobileWebImage(
                                    imageUrl: ImageAssets.flag(
                                      item.countryCode,
                                    ),
                                    fit: BoxFit.contain,
                                    errorWidget: (context, url, error) =>
                                        const SizedBox.shrink(),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    item.locationName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelLarge
                                        ?.copyWith(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onSurfaceVariant,
                                        ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              if (item.clanPoints > 0)
                                _ClanImageChip(
                                  label: formatter.format(item.clanPoints),
                                  imageUrl: ImageAssets.trophies,
                                ),
                              if (item.warLeague.isNotEmpty)
                                _ClanImageChip(
                                  label: item.warLeague,
                                  imageUrl: ImageAssets.getWarLeagueImage(
                                    item.warLeague,
                                  ),
                                ),
                              if (item.type.isNotEmpty)
                                _ClanIconChip(
                                  label: _clanTypeLabel(context, item.type),
                                  icon: Icons.mail_rounded,
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                top: 14,
                right: 14,
                child: _ClanTrailingStatus(item: item),
              ),
              Positioned(
                right: 10,
                top: 0,
                bottom: 0,
                child: Icon(
                  Icons.chevron_right_rounded,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  size: 30,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ClanBadgeWithMembers extends StatelessWidget {
  const _ClanBadgeWithMembers({required this.item});

  final _ClanListItem item;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox.square(
          dimension: 64,
          child: MobileWebImage(
            imageUrl: item.badgeUrl,
            errorWidget: (context, url, error) =>
                const Icon(Icons.groups_rounded),
          ),
        ),
        const SizedBox(height: 6),
        _ClanIconChip(
          label: clanMemberCapacityLabel(item.members),
          icon: Icons.people_alt_rounded,
        ),
      ],
    );
  }
}

class _ClanTrailingStatus extends StatelessWidget {
  const _ClanTrailingStatus({required this.item});

  final _ClanListItem item;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (item.bookmarked) {
      return Icon(
        Icons.bookmark_rounded,
        size: 24,
        color: colorScheme.onSurfaceVariant,
      );
    }

    return _AccountCountChip(count: item.accountCount);
  }
}

class _AccountCountChip extends StatelessWidget {
  const _AccountCountChip({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.22),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
        child: Text(
          '$count ${count == 1 ? 'account' : 'accounts'}',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _ClanImageChip extends StatelessWidget {
  const _ClanImageChip({required this.label, required this.imageUrl});

  final String label;
  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return _ClanChipShell(
      label: label,
      leading: MobileWebImage(
        imageUrl: imageUrl,
        fit: BoxFit.contain,
        errorWidget: (context, url, error) =>
            const Icon(Icons.shield_outlined, size: 14),
      ),
    );
  }
}

class _ClanIconChip extends StatelessWidget {
  const _ClanIconChip({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return _ClanChipShell(
      label: label,
      leading: Icon(icon, size: 14, color: colorScheme.onSurfaceVariant),
    );
  }
}

class _ClanChipShell extends StatelessWidget {
  const _ClanChipShell({required this.label, required this.leading});

  final String label;
  final Widget leading;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.18),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox.square(dimension: 16, child: leading),
            const SizedBox(width: 5),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _clanTypeLabel(BuildContext context, String type) {
  final loc = AppLocalizations.of(context);
  switch (type) {
    case 'inviteOnly':
      return loc?.clanInviteOnly ?? 'Invite only';
    case 'open':
      return loc?.clanOpened ?? 'Open';
    case 'closed':
      return loc?.generalClosed ?? 'Closed';
    default:
      return type;
  }
}
