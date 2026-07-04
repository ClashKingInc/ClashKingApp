import 'dart:async';

import 'package:clashkingapp/common/widgets/error/error_page.dart';
import 'package:clashkingapp/common/widgets/indicators/last_refresh_indicator.dart';
import 'package:clashkingapp/common/widgets/mobile_web_image.dart';
import 'package:clashkingapp/core/constants/image_assets.dart';
import 'package:clashkingapp/core/services/bookmark_service.dart';
import 'package:clashkingapp/core/services/player_card_preferences_service.dart';
import 'package:clashkingapp/core/utils/network_error_utils.dart';
import 'package:clashkingapp/features/clan/data/clan_service.dart';
import 'package:clashkingapp/features/clan/models/clan.dart';
import 'package:clashkingapp/features/coc_accounts/data/coc_account_service.dart';
import 'package:clashkingapp/features/pages/widgets/war_access_denied_card.dart';
import 'package:clashkingapp/features/pages/widgets/war_card.dart';
import 'package:clashkingapp/features/pages/widgets/war_not_in_war_card.dart';
import 'package:clashkingapp/features/player/data/player_service.dart';
import 'package:clashkingapp/features/player/models/player.dart';
import 'package:clashkingapp/features/war_cwl/data/war_cwl_service.dart';
import 'package:clashkingapp/features/war_cwl/models/war_cwl.dart';
import 'package:clashkingapp/features/war_cwl/models/war_info.dart';
import 'package:clashkingapp/features/war_cwl/presentation/cwl/cwl.dart';
import 'package:clashkingapp/features/war_cwl/presentation/war/war.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class WarCwlPage extends StatefulWidget {
  const WarCwlPage({super.key});

  @override
  State<WarCwlPage> createState() => _WarCwlPageState();
}

class _WarCwlPageState extends State<WarCwlPage> {
  final Set<String> _requestedBookmarkWarTags = {};

  @override
  Widget build(BuildContext context) {
    final cocService = context.watch<CocAccountService>();
    final clanService = context.watch<ClanService>();
    final playerService = context.watch<PlayerService>();
    final warCwlService = context.watch<WarCwlService>();
    final bookmarkService = context.watch<BookmarkService>();
    final playerCardPrefs = context.watch<PlayerCardPreferencesService>();
    // playerService.profiles also holds bookmarked players hydrated for
    // the Players tab — restrict to actually-linked tags so a bookmarked
    // player's clan isn't mistaken for one of "your" clans.
    final ownedTags = cocService.getAccountTags().toSet();
    // Accounts opted out of the War tab (per-player "Show in War tab"
    // toggle on the Players page) don't contribute to a clan card here -
    // if that leaves a clan with no visible accounts, it simply won't
    // appear below.
    final players = playerService.profiles
        .where(
          (player) =>
              ownedTags.contains(player.tag) &&
              playerCardPrefs.isShownInWarTab(player.tag),
        )
        .toList(growable: false);
    final linkedClans = {
      for (final profile in players)
        if (profile.clan != null && profile.clan!.tag.isNotEmpty)
          profile.clan!.tag: profile.clan!,
    };
    final bookmarkedClanTags = bookmarkService.clans
        .where((clan) => !linkedClans.containsKey(clan.tag))
        .map((clan) => clan.tag)
        .toList(growable: false);
    final missingBookmarkWarTags = bookmarkedClanTags
        .where(
          (tag) =>
              !_requestedBookmarkWarTags.contains(tag) &&
              warCwlService.getWarCwlByTag(tag) == null,
        )
        .toList(growable: false);
    if (missingBookmarkWarTags.isNotEmpty) {
      _requestedBookmarkWarTags.addAll(missingBookmarkWarTags);
      unawaited(_loadBookmarkedWarData(warCwlService, missingBookmarkWarTags));
    }
    final items = [
      for (final clan in linkedClans.values)
        _WarListItem.linked(
          clan: clan,
          accounts: players
              .where((player) => player.clanTag == clan.tag)
              .toList(growable: false),
          summary: warCwlService.getWarCwlByTag(clan.tag),
        ),
      for (final clan in bookmarkService.clans)
        if (!linkedClans.containsKey(clan.tag))
          _WarListItem.bookmarked(
            clan,
            summary: warCwlService.getWarCwlByTag(clan.tag),
          ),
    ]..sort((a, b) => a.sortWeight.compareTo(b.sortWeight));

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
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            16,
            0,
            16,
            MediaQuery.paddingOf(context).bottom + 96,
          ),
          children: [
            LastRefreshIndicator(lastRefresh: cocService.lastRefresh),
            const SizedBox(height: 8),
            if (items.isEmpty)
              const _EmptyWarMessage()
            else
              ...items.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _WarListCard(item: item),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _loadBookmarkedWarData(
    WarCwlService warCwlService,
    List<String> clanTags,
  ) async {
    await warCwlService.loadAllWarData(clanTags, notify: true);
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

class _WarListItem {
  const _WarListItem({
    required this.name,
    required this.tag,
    required this.badgeUrl,
    required this.bookmarked,
    required this.accounts,
    this.clan,
    this.summary,
  });

  final String name;
  final String tag;
  final String badgeUrl;
  final bool bookmarked;
  final List<Player> accounts;
  final Clan? clan;
  final WarCwl? summary;

  factory _WarListItem.linked({
    required Clan clan,
    required List<Player> accounts,
    required WarCwl? summary,
  }) {
    return _WarListItem(
      name: clan.name,
      tag: clan.tag,
      badgeUrl: clan.badgeUrls.large,
      bookmarked: false,
      accounts: accounts,
      clan: clan,
      summary: summary,
    );
  }

  factory _WarListItem.bookmarked(BookmarkedClan clan, {WarCwl? summary}) {
    return _WarListItem(
      name: clan.name,
      tag: clan.tag,
      badgeUrl: clan.badgeUrl,
      bookmarked: true,
      accounts: const [],
      summary: summary,
    );
  }

  WarInfo? get displayWar {
    final warCwl = summary;
    if (warCwl == null) return null;
    if (warCwl.isInWar) return warCwl.warInfo;
    if (warCwl.isInCwl) return warCwl.getActiveWarByTag(tag);
    return null;
  }

  /// Round number for the currently displayed war, when it's a CWL round
  /// war (i.e. displayWar came from the isInCwl branch above, not a
  /// regular war) — used to show a "CWL — Round N" banner on the card.
  int? get cwlRoundNumber {
    final warCwl = summary;
    final war = displayWar;
    if (warCwl == null || war == null || !warCwl.isInCwl || warCwl.isInWar) {
      return null;
    }
    for (final round in warCwl.leagueInfo?.rounds ?? const []) {
      if (round.containsWar(war.tag)) return round.roundNumber;
    }
    return null;
  }

  /// Current CWL standing for this clan, shown alongside the round
  /// number in the banner.
  int? get cwlRank {
    if (cwlRoundNumber == null) return null;
    return summary?.leagueInfo?.getClanDetails(tag)?.rank;
  }

  int get sortWeight {
    final war = displayWar;
    final linked = accounts.isNotEmpty && !bookmarked;
    final inWarLineup = war != null && hasLineupAccount(war);
    final warActive =
        war != null &&
        war.state != 'notInWar' &&
        war.state != 'unknown' &&
        war.state != 'accessDenied';

    if (linked && inWarLineup && war.state == 'inWar') return 0;
    if (linked && inWarLineup && war.state == 'preparation') return 1;
    if (linked && warActive) return 2;
    if (bookmarked && warActive) return 3;
    if (linked) return 4;
    if (bookmarked) return 5;
    return 6;
  }

  List<_AccountWarStatus> accountStatuses(WarInfo war) {
    return accounts
        .map((player) => _AccountWarStatus.fromWar(player, war, tag))
        .toList(growable: false);
  }

  bool hasLineupAccount(WarInfo war) {
    return accountStatuses(war).any((status) => status.inWar);
  }
}

class _WarListCard extends StatelessWidget {
  const _WarListCard({required this.item});

  final _WarListItem item;

  @override
  Widget build(BuildContext context) {
    final war = item.displayWar;
    final summary = item.summary;
    final accountStatuses = war == null
        ? const <_AccountWarStatus>[]
        : item.accountStatuses(war);
    final lineupStatuses = accountStatuses
        .where((status) => status.inWar)
        .toList(growable: false);
    final allSpectators =
        item.accounts.isNotEmpty &&
        accountStatuses.isNotEmpty &&
        lineupStatuses.isEmpty;

    if (war != null && war.state != 'notInWar' && war.state != 'unknown') {
      final canOpenCwl =
          summary?.isInCwl == true &&
          summary?.leagueInfo?.getClanDetails(item.tag) != null;

      void openCwl() {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CwlScreen(
              clanTag: item.tag,
              warCwl: summary!,
              clanInfo: summary.leagueInfo!.getClanDetails(item.tag)!,
              warLeagueName: item.clan?.warLeague?.name,
            ),
          ),
        );
      }

      void openWar() {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                WarScreen(war: war, cwlRoundNumber: item.cwlRoundNumber),
          ),
        );
      }

      return WarCard(
        currentWarInfo: war,
        clanTag: item.tag,
        centerHeader: allSpectators
            ? const _SpectatorPill()
            : item.bookmarked
            ? const _BookmarkedPill()
            : null,
        footer: lineupStatuses.isEmpty
            ? null
            : _WarAttackFooter(
                statuses: lineupStatuses,
                attacksPerMember: war.attacksPerMember ?? 1,
              ),
        cwlBanner: item.cwlRoundNumber == null
            ? null
            : _CwlRoundBanner(
                roundNumber: item.cwlRoundNumber!,
                rank: item.cwlRank,
              ),
        onTapBanner: canOpenCwl ? openCwl : null,
        onTap: openWar,
      );
    }

    if (summary?.warInfo.state == 'accessDenied') {
      return WarAccessDeniedCard(
        clanName: item.name,
        clanBadgeUrl: item.badgeUrl,
      );
    }

    if (!item.bookmarked) {
      return NotInWarCard(clanName: item.name, clanBadgeUrl: item.badgeUrl);
    }

    return NotInWarCard(
      clanName: item.name,
      clanBadgeUrl: item.badgeUrl,
      bookmarked: true,
    );
  }
}

class _WarAttackFooter extends StatelessWidget {
  const _WarAttackFooter({
    required this.statuses,
    required this.attacksPerMember,
  });

  final List<_AccountWarStatus> statuses;
  final int attacksPerMember;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.20),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your accounts',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: statuses
                  .map(
                    (status) => _AttackPlayerChip(
                      status: status,
                      total: attacksPerMember,
                    ),
                  )
                  .toList(growable: false),
            ),
          ],
        ),
      ),
    );
  }
}

class _SpectatorPill extends StatelessWidget {
  const _SpectatorPill();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.visibility_outlined,
              size: 14,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 5),
            Text(
              'Spectator',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BookmarkedPill extends StatelessWidget {
  const _BookmarkedPill();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.bookmark_rounded,
              size: 14,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 5),
            Text(
              'Bookmarked',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Small tinted-glass banner attached above a war card, same recipe as
/// the war detail screen's CWL round banner — flags a listed war as a
/// CWL round instead of a regular war before the user even taps in.
/// Flat top-rounded strip (not its own fully-rounded pill) so it reads
/// as fused with the war card below it, matching the card's own radius.
class _CwlRoundBanner extends StatelessWidget {
  const _CwlRoundBanner({required this.roundNumber, this.rank});

  final int roundNumber;
  final int? rank;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    const tint = Color(0xFF8D63D9);
    final roundLabel =
        AppLocalizations.of(context)?.cwlRoundNumber(roundNumber) ??
        'Round $roundNumber';

    return DecoratedBox(
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.16),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            MobileWebImage(
              imageUrl: ImageAssets.cwlSwordsNoBorder,
              width: 14,
              height: 14,
            ),
            const SizedBox(width: 6),
            Text(
              rank == null ? 'CWL — $roundLabel' : 'CWL — $roundLabel — #$rank',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AttackPlayerChip extends StatelessWidget {
  const _AttackPlayerChip({required this.status, required this.total});

  final _AccountWarStatus status;
  final int total;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final foreground = status.left > 0 ? colorScheme.primary : Colors.green;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: foreground.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.local_fire_department_rounded,
              size: 14,
              color: foreground,
            ),
            const SizedBox(width: 5),
            Text(
              '${status.player.name} ${status.done}/$total',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: foreground,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AccountWarStatus {
  const _AccountWarStatus({
    required this.player,
    required this.inWar,
    required this.done,
    required this.left,
  });

  final Player player;
  final bool inWar;
  final int done;
  final int left;

  factory _AccountWarStatus.fromWar(
    Player player,
    WarInfo war,
    String clanTag,
  ) {
    final inWar = war.isPlayerInWar(player.tag, clanTag);
    final done = inWar ? war.getAttacksDoneByPlayer(player.tag, clanTag) : 0;
    final left = inWar ? ((war.attacksPerMember ?? 1) - done).clamp(0, 99) : 0;
    return _AccountWarStatus(
      player: player,
      inWar: inWar,
      done: done,
      left: left,
    );
  }
}

class _EmptyWarMessage extends StatelessWidget {
  const _EmptyWarMessage();

  @override
  Widget build(BuildContext context) {
    return const Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Text('No linked or bookmarked clan wars to show.'),
      ),
    );
  }
}
