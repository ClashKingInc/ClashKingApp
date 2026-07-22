import 'package:clashkingapp/common/widgets/buttons/info_button.dart';
import 'package:clashkingapp/common/widgets/dialogs/open_clash_dialog.dart';
import 'package:clashkingapp/common/widgets/header_widgets.dart';
import 'package:clashkingapp/common/widgets/mobile_web_image.dart';
import 'package:clashkingapp/core/constants/image_assets.dart';
import 'package:clashkingapp/core/services/bookmark_service.dart';
import 'package:clashkingapp/features/player/models/player.dart';
import 'package:clashkingapp/features/player/models/player_ranked_league.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class RankedLeagueHeaderCard extends StatelessWidget {
  const RankedLeagueHeaderCard({
    super.key,
    required this.player,
    required this.data,
  });

  final Player player;
  final RankedLeagueData data;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final isDesktopWeb = kIsWeb && media.size.width >= 900;
    final imageHeight = media.padding.top + (isDesktopWeb ? 292 : 370);
    final headerMaxWidth = isDesktopWeb ? 1120.0 : double.infinity;

    return Stack(
      children: [
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: imageHeight,
          child: Stack(
            fit: StackFit.expand,
            children: [
              ColorFiltered(
                colorFilter: ColorFilter.mode(
                  Colors.black.withValues(alpha: 0.50),
                  BlendMode.darken,
                ),
                child: MobileWebImage(
                  imageUrl: ImageAssets.homeBaseBackground,
                  fit: BoxFit.cover,
                  alignment: Alignment.bottomCenter,
                  errorWidget: (context, url, error) =>
                      ColoredBox(color: Theme.of(context).colorScheme.surface),
                ),
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: Theme.of(context).brightness == Brightness.dark
                        ? const [
                            Color.fromRGBO(0, 0, 0, 0.36),
                            Color.fromRGBO(0, 0, 0, 0.64),
                            Color.fromRGBO(0, 0, 0, 0.92),
                          ]
                        : const [
                            Color.fromRGBO(0, 0, 0, 0.20),
                            Color.fromRGBO(0, 0, 0, 0.40),
                            Color.fromRGBO(0, 0, 0, 0.65),
                          ],
                  ),
                ),
              ),
            ],
          ),
        ),
        Column(
          children: [
            SizedBox(height: media.padding.top),
            Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: headerMaxWidth),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isDesktopWeb ? 20 : 12,
                  ),
                  child: _TopActions(player: player),
                ),
              ),
            ),
            if (isDesktopWeb)
              _DesktopRankedHeaderPanel(
                player: player,
                data: data,
                maxWidth: headerMaxWidth,
              )
            else ...[
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: _RankedIdentity(
                  player: player,
                  data: data,
                  horizontal: false,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                child: _RankedQuickStats(data: data, compact: true),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _DesktopRankedHeaderPanel extends StatelessWidget {
  const _DesktopRankedHeaderPanel({
    required this.player,
    required this.data,
    required this.maxWidth,
  });

  final Player player;
  final RankedLeagueData data;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: SizedBox(
          height: 166,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      flex: 4,
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 370),
                          child: _RankedIdentity(
                            player: player,
                            data: data,
                            horizontal: true,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 52),
                    Expanded(
                      flex: 6,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 590),
                          child: _RankedLeagueTiles(data: data),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 920),
                  child: _RankedQuickStats(data: data),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TopActions extends StatelessWidget {
  const _TopActions({required this.player});

  final Player player;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        HeaderIconButton(
          icon: Icons.arrow_back_rounded,
          iconColor: Colors.white,
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          onTap: () => Navigator.of(context).pop(),
          showBackground: false,
        ),
        const Spacer(),
        HeaderIconButton(
          icon: Icons.open_in_new_rounded,
          iconColor: Colors.white,
          tooltip: AppLocalizations.of(context)!.playerOpenInGame,
          onTap: () => _openInGame(context),
          showBackground: false,
        ),
        const SizedBox(width: 8),
        Consumer<BookmarkService>(
          builder: (context, bookmarks, child) {
            final bookmarked = bookmarks.isPlayerBookmarked(player.tag);
            return HeaderIconButton(
              icon: bookmarked
                  ? Icons.bookmark_rounded
                  : Icons.bookmark_border_rounded,
              iconColor: bookmarked ? const Color(0xFF2F8CFF) : Colors.white,
              tooltip: bookmarked
                  ? AppLocalizations.of(context)!.playerBookmarkRemove
                  : AppLocalizations.of(context)!.playerBookmarkAdd,
              onTap: () => bookmarks.togglePlayer(player),
              showBackground: false,
            );
          },
        ),
        const SizedBox(width: 8),
        HeaderIconButton(
          icon: Icons.info_outline_rounded,
          iconColor: Colors.white,
          tooltip: AppLocalizations.of(context)!.rankedLeagueAbout,
          onTap: () => showInfoPopup(
            context,
            TextSpan(
              text: AppLocalizations.of(context)!.rankedLeagueAboutBody,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            AppLocalizations.of(context)!.rankedLeagueAbout,
          ),
          showBackground: false,
        ),
      ],
    );
  }

  void _openInGame(BuildContext context) {
    final languageCode = Localizations.localeOf(
      context,
    ).languageCode.toLowerCase();
    final url = Uri.https('link.clashofclans.com', '/$languageCode', {
      'action': 'OpenPlayerProfile',
      'tag': player.tag,
    });
    showDialog(
      context: context,
      builder: (context) => OpenClashDialog(url: url),
    );
  }
}

class _RankedIdentity extends StatelessWidget {
  const _RankedIdentity({
    required this.player,
    required this.data,
    required this.horizontal,
  });

  final Player player;
  final RankedLeagueData data;
  final bool horizontal;

  @override
  Widget build(BuildContext context) {
    const imageDimension = 104.0;
    final tier = data.currentTier;
    final tierIcon = tier?.smallIconUrl.isNotEmpty == true
        ? tier!.smallIconUrl
        : tier?.largeIconUrl ?? '';
    final colors = Theme.of(context).colorScheme;
    final image = SizedBox.square(
      dimension: imageDimension,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: MobileWebImage(
              imageUrl: player.townHallPic,
              fit: BoxFit.contain,
            ),
          ),
          if (tierIcon.isNotEmpty)
            Positioned(
              right: -2,
              bottom: 0,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Theme.of(context).cardTheme.color ?? colors.surface,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: colors.outlineVariant.withValues(alpha: 0.4),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(3),
                  child: MobileWebImage(
                    imageUrl: tierIcon,
                    width: 30,
                    height: 30,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
    final details = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: horizontal
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.center,
      children: [
        Text(
          player.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: horizontal ? TextAlign.start : TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: colors.onSurface,
            fontSize: 26,
            fontWeight: FontWeight.w700,
            height: 1.02,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          player.tag,
          maxLines: 1,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: colors.onSurface.withValues(alpha: 0.72),
            fontWeight: FontWeight.w700,
          ),
        ),
        _ClanLine(player: player, centered: !horizontal),
      ],
    );

    if (horizontal) {
      return SizedBox(
        height: imageDimension,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            image,
            const SizedBox(width: 18),
            Expanded(child: details),
          ],
        ),
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [image, const SizedBox(height: 2), details],
    );
  }
}

class _ClanLine extends StatelessWidget {
  const _ClanLine({required this.player, required this.centered});

  final Player player;
  final bool centered;

  @override
  Widget build(BuildContext context) {
    final clanName = player.clan?.name.isNotEmpty == true
        ? player.clan!.name
        : player.clanOverview.name;
    final badgeUrl = player.clan?.badgeUrls.small.isNotEmpty == true
        ? player.clan!.badgeUrls.small
        : player.clanOverview.badgeUrls.small;
    if (clanName.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: centered
            ? MainAxisAlignment.center
            : MainAxisAlignment.start,
        children: [
          if (badgeUrl.isNotEmpty) ...[
            MobileWebImage(imageUrl: badgeUrl, width: 16, height: 16),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              clanName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 15,
                fontWeight: FontWeight.w500,
                height: 1.05,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RankedLeagueTiles extends StatelessWidget {
  const _RankedLeagueTiles({required this.data});

  final RankedLeagueData data;

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat(
      '#,###',
      Localizations.localeOf(context).toString(),
    );
    final trophies = data.currentMember?.leagueTrophies ?? data.trophies;
    final tierIcon = data.currentTier?.largeIconUrl ?? '';
    final rank = data.currentRank;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: CompactLeagueTile(
            leagueName: AppLocalizations.of(context)!.rankedLeagueTrophies,
            subtitle: formatter.format(trophies),
            subtitleIconUrl: ImageAssets.trophies,
            leagueUrl: tierIcon.isEmpty ? ImageAssets.trophies : tierIcon,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: CompactLeagueTile(
            leagueName: AppLocalizations.of(context)!.rankedLeagueGroupRank,
            subtitle: rank == null
                ? AppLocalizations.of(context)!.legendsNoRank
                : '#${formatter.format(rank)}',
            leagueUrl: ImageAssets.trophies,
          ),
        ),
      ],
    );
  }
}

class _RankedQuickStats extends StatelessWidget {
  const _RankedQuickStats({required this.data, this.compact = false});

  final RankedLeagueData data;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat(
      '#,###',
      Localizations.localeOf(context).toString(),
    );
    final member = data.currentMember;
    final maxBattles = data.currentMaxBattles;
    final attackCount = member == null
        ? 0
        : member.attackWinCount + member.attackLoseCount;
    final defenseCount = member == null
        ? 0
        : member.defenseWinCount + member.defenseLoseCount;
    final groupSize = data.currentGroup?.members.length ?? 0;
    final rank = data.currentRank;
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 7,
      runSpacing: 7,
      children: [
        if (compact)
          _RankedQuickChip(
            value: rank == null
                ? AppLocalizations.of(context)!.legendsNoRank
                : '#${formatter.format(rank)}',
            icon: Icons.leaderboard_rounded,
            tooltip: AppLocalizations.of(context)!.rankedLeagueGroupRank,
          ),
        if (!compact)
          _RankedQuickChip(
            value: formatter.format(data.bestTrophies),
            imageUrl: ImageAssets.bestTrophies,
            tooltip: AppLocalizations.of(context)!.playerBestTrophies,
          ),
        _RankedQuickChip(
          value: maxBattles == null
              ? '$attackCount'
              : '$attackCount/$maxBattles',
          imageUrl: ImageAssets.sword,
          tooltip: AppLocalizations.of(context)!.rankedLeagueAttacks,
        ),
        _RankedQuickChip(
          value: maxBattles == null
              ? '$defenseCount'
              : '$defenseCount/$maxBattles',
          imageUrl: ImageAssets.shieldWithArrow,
          tooltip: AppLocalizations.of(context)!.rankedLeagueDefenses,
        ),
        if (!compact && groupSize > 0)
          _RankedQuickChip(
            value: AppLocalizations.of(context)!.rankedLeaguePlayers(groupSize),
            icon: Icons.groups_rounded,
            tooltip: AppLocalizations.of(context)!.rankedLeagueGroupRanking,
          ),
      ],
    );
  }
}

class _RankedQuickChip extends StatelessWidget {
  const _RankedQuickChip({
    required this.value,
    required this.tooltip,
    this.imageUrl,
    this.icon,
  });

  final String value;
  final String tooltip;
  final String? imageUrl;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: 0.58),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (imageUrl?.isNotEmpty == true)
            MobileWebImage(imageUrl: imageUrl!, width: 19, height: 19)
          else
            Icon(icon ?? Icons.info_rounded, size: 19),
          const SizedBox(width: 5),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 132),
            child: Text(
              value,
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
                height: 1,
              ),
            ),
          ),
        ],
      ),
    );
    return Tooltip(message: tooltip, child: chip);
  }
}
