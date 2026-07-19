import 'dart:async';

import 'package:clashkingapp/common/widgets/dialogs/open_clash_dialog.dart';
import 'package:clashkingapp/common/widgets/dialogs/snackbar.dart';
import 'package:clashkingapp/common/widgets/header_widgets.dart';
import 'package:clashkingapp/common/widgets/mobile_web_image.dart';
import 'package:clashkingapp/core/constants/image_assets.dart';
import 'package:clashkingapp/core/functions/functions.dart';
import 'package:clashkingapp/core/services/bookmark_service.dart';
import 'package:clashkingapp/features/clan/data/clan_service.dart';
import 'package:clashkingapp/features/clan/presentation/clan_info/clan_page.dart';
import 'package:clashkingapp/features/player/data/player_service.dart';
import 'package:clashkingapp/features/player/models/player.dart';
import 'package:clashkingapp/features/player/presentation/legend/player_legend_page.dart';
import 'package:clashkingapp/features/war_cwl/models/war_info.dart';
import 'package:clashkingapp/features/war_cwl/presentation/cwl/cwl.dart';
import 'package:clashkingapp/features/war_cwl/presentation/war/war.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class PlayerInfoHeader extends StatelessWidget {
  final int selectedTab;
  final Player player;
  final bool showTopActions;

  const PlayerInfoHeader({
    super.key,
    required this.selectedTab,
    required this.player,
    this.showTopActions = true,
  });

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final isDesktopWeb = kIsWeb && media.size.width >= 900;
    final isBuilderTab = selectedTab == 1;
    final backgroundImageUrl = isBuilderTab
        ? ImageAssets.builderBaseBackground
        : ImageAssets.homeBaseBackground;
    final hallImageUrl = isBuilderTab
        ? player.builderHallPic
        : player.townHallPic;
    final imageHeight = media.padding.top + (isDesktopWeb ? 292 : 500);
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
                  imageUrl: backgroundImageUrl,
                  fit: BoxFit.cover,
                  alignment: Alignment.bottomCenter,
                  errorWidget: (context, url, error) =>
                      ColoredBox(color: Theme.of(context).colorScheme.surface),
                ),
              ),
              // Fixed black, not colorScheme.surface: keeps darkening the
              // photo toward the bottom in both themes — surface flips to
              // near-white in light mode, which un-darkens the image.
              // Lower peak alpha in light mode: still dark enough for
              // white text, but not dark mode's near-black wash.
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
            if (showTopActions)
              Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: headerMaxWidth),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isDesktopWeb ? 20 : 12,
                    ),
                    child: PlayerInfoHeaderActions(player: player),
                  ),
                ),
              )
            else
              const SizedBox(height: 48),
            if (isDesktopWeb)
              _DesktopPlayerHeaderPanel(
                player: player,
                hallImageUrl: hallImageUrl,
                hallWeaponStars: isBuilderTab ? 0 : player.townHallWeaponLevel,
                selectedTab: selectedTab,
                maxWidth: headerMaxWidth,
              )
            else ...[
              const SizedBox(height: 6),
              Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: headerMaxWidth),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: _IdentityPanel(
                      player: player,
                      hallImageUrl: hallImageUrl,
                      hallWeaponStars: isBuilderTab
                          ? 0
                          : player.townHallWeaponLevel,
                    ),
                  ),
                ),
              ),
              Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: headerMaxWidth),
                  child: Padding(
                    padding: const EdgeInsets.only(top: 11, bottom: 8),
                    child: _PlayerHeaderStats(
                      player: player,
                      selectedTab: selectedTab,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _DesktopPlayerHeaderPanel extends StatelessWidget {
  final Player player;
  final String hallImageUrl;
  final int hallWeaponStars;
  final int selectedTab;
  final double maxWidth;

  const _DesktopPlayerHeaderPanel({
    required this.player,
    required this.hallImageUrl,
    required this.hallWeaponStars,
    required this.selectedTab,
    required this.maxWidth,
  });

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
                          child: _IdentityPanel(
                            player: player,
                            hallImageUrl: hallImageUrl,
                            hallWeaponStars: hallWeaponStars,
                            compact: true,
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
                          child: _PlayerHeaderLeagueTiles(
                            player: player,
                            selectedTab: selectedTab,
                            compact: true,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 920),
                  child: _PlayerHeaderQuickStats(
                    player: player,
                    compact: true,
                    combineRows: true,
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

class PlayerInfoHeaderActions extends StatelessWidget {
  final Player player;

  const PlayerInfoHeaderActions({super.key, required this.player});

  @override
  Widget build(BuildContext context) {
    final warAction = _currentWarAction(context, player);

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
        if (warAction != null) ...[
          HeaderIconButton(
            imageUrl: warAction.imageUrl,
            tooltip: warAction.label,
            onTap: warAction.onTap,
            showBackground: false,
          ),
          const SizedBox(width: 8),
        ],
        HeaderIconButton(
          icon: Icons.open_in_new_rounded,
          iconColor: Colors.white,
          tooltip: AppLocalizations.of(context)!.playerOpenInGame,
          onTap: () => _showOpenPlayerDialog(context, player),
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
      ],
    );
  }
}

class _IdentityPanel extends StatelessWidget {
  final Player player;
  final String hallImageUrl;
  final int hallWeaponStars;
  final bool compact;
  final bool horizontal;

  const _IdentityPanel({
    required this.player,
    required this.hallImageUrl,
    required this.hallWeaponStars,
    this.compact = false,
    this.horizontal = false,
  });

  @override
  Widget build(BuildContext context) {
    final role = PlayerService().getRoleText(player.role, context);
    final desktopHorizontal = compact && horizontal;
    final badge = _HallBadge(
      imageUrl: hallImageUrl,
      stars: hallWeaponStars,
      size: desktopHorizontal ? 104 : (compact ? 82 : 104),
      imageSize: desktopHorizontal ? 96 : (compact ? 76 : 94),
    );
    final name = Text(
      player.name,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textAlign: horizontal ? TextAlign.start : TextAlign.center,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
        color: Colors.white,
        fontSize: desktopHorizontal ? 26 : (compact ? 24 : 26),
        fontWeight: FontWeight.w700,
        height: 1.02,
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (horizontal) {
          return SizedBox(
            height: desktopHorizontal ? 104 : null,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                badge,
                SizedBox(width: desktopHorizontal ? 18 : 16),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      name,
                      const SizedBox(height: 3),
                      _CopyablePlayerTag(
                        tag: player.tag,
                        alignment: TextAlign.start,
                      ),
                      _PlayerClanIdentityLine(
                        player: player,
                        role: role,
                        alignment: MainAxisAlignment.start,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: constraints.maxWidth),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                badge,
                const SizedBox(height: 2),
                name,
                const SizedBox(height: 2),
                _CopyablePlayerTag(tag: player.tag),
                _PlayerClanIdentityLine(player: player, role: role),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PlayerHeaderStats extends StatelessWidget {
  final Player player;
  final int selectedTab;

  const _PlayerHeaderStats({required this.player, required this.selectedTab});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.max,
      children: [
        _PlayerHeaderLeagueTiles(player: player, selectedTab: selectedTab),
        const SizedBox(height: 8),
        _PlayerHeaderQuickStats(player: player),
      ],
    );
  }
}

class _PlayerHeaderLeagueTiles extends StatelessWidget {
  final Player player;
  final int selectedTab;
  final bool compact;

  const _PlayerHeaderLeagueTiles({
    required this.player,
    required this.selectedTab,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat(
      '#,###',
      Localizations.localeOf(context).toString(),
    );
    final isBuilderTab = selectedTab == 1;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: compact ? 0 : 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: CompactLeagueTile(
              leagueName: isBuilderTab
                  ? _compactLeagueName(player.builderBaseLeague)
                  : _compactLeagueName(player.league),
              subtitle: formatter.format(
                isBuilderTab ? player.builderBaseTrophies : player.trophies,
              ),
              subtitleIconUrl: isBuilderTab
                  ? ImageAssets.builderBaseTrophy
                  : ImageAssets.trophies,
              leagueUrl: isBuilderTab
                  ? _leagueIcon(player.builderBaseLeagueUrl)
                  : _leagueIcon(player.leagueUrl),
              onTap: isBuilderTab ? null : () => _openLegend(context),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: CompactLeagueTile(
              leagueName: isBuilderTab
                  ? _compactLeagueName(player.league)
                  : _compactLeagueName(player.builderBaseLeague),
              subtitle: formatter.format(
                isBuilderTab ? player.trophies : player.builderBaseTrophies,
              ),
              subtitleIconUrl: isBuilderTab
                  ? ImageAssets.trophies
                  : ImageAssets.builderBaseTrophy,
              leagueUrl: isBuilderTab
                  ? _leagueIcon(player.leagueUrl)
                  : _leagueIcon(player.builderBaseLeagueUrl),
              onTap: isBuilderTab ? () => _openLegend(context) : null,
            ),
          ),
        ],
      ),
    );
  }

  void _openLegend(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PlayerLegendScreen(player: player),
      ),
    );
  }

  String _compactLeagueName(String leagueName) {
    final compact = leagueName.replaceAll(' League', '').trim();
    return compact.isEmpty ? 'Unranked' : compact;
  }

  String _leagueIcon(String url) => url.isEmpty ? ImageAssets.trophies : url;
}

class _PlayerHeaderQuickStats extends StatelessWidget {
  final Player player;
  final bool compact;
  final bool combineRows;

  const _PlayerHeaderQuickStats({
    required this.player,
    this.compact = false,
    this.combineRows = false,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final formatter = NumberFormat(
      '#,###',
      Localizations.localeOf(context).toString(),
    );
    final warPreferenceLabel = player.warPreference == 'in'
        ? loc.warStatusReady
        : loc.warStatusUnready;
    final primaryChips = [
      _PlayerQuickChip(
        value: formatter.format(player.warStars),
        imageUrl: ImageAssets.attackStar,
        tooltip: loc.playerWarStarsTitle,
      ),
      _PlayerQuickChip(
        value: warPreferenceLabel,
        imageUrl: player.warPreferenceImage,
        tooltip: loc.playerWarPreferenceTitle,
      ),
      _PlayerQuickChip(
        value: formatter.format(player.donations),
        icon: Icons.arrow_upward_rounded,
        tooltip: loc.playerDonatedTitle,
      ),
      _PlayerQuickChip(
        value: formatter.format(player.donationsReceived),
        icon: Icons.arrow_downward_rounded,
        tooltip: loc.playerReceivedTitle,
      ),
    ];
    final secondaryChips = [
      _PlayerQuickChip(
        value: formatter.format(player.clanCapitalContributions),
        imageUrl: ImageAssets.capitalGold,
        tooltip: loc.playerCapitalTitle,
      ),
      _PlayerQuickChip(
        value: player.expLevel.toString(),
        imageUrl: ImageAssets.xp,
        tooltip: loc.playerExpLevelTitle,
      ),
      _PlayerQuickChip(
        value: formatter.format(player.bestTrophies),
        imageUrl: ImageAssets.bestTrophies,
        tooltip: loc.playerBestTrophies,
      ),
    ];

    if (combineRows) {
      return Wrap(
        alignment: WrapAlignment.center,
        spacing: 7,
        runSpacing: 7,
        children: [...primaryChips, ...secondaryChips],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: compact ? 0 : 16),
          child: _PlayerChipRows(children: primaryChips),
        ),
        SizedBox(height: compact ? 8 : 8),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: compact ? 0 : 16),
          child: _PlayerChipRows(children: secondaryChips),
        ),
      ],
    );
  }
}

class _PlayerChipRows extends StatelessWidget {
  final List<_PlayerQuickChip> children;

  const _PlayerChipRows({required this.children});

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final spacing = 7.0;
        final widths = children
            .map((child) => child.estimatedWidth(context))
            .toList(growable: false);
        final rowPlans = _candidatePlans(children.length);

        for (final plan in rowPlans) {
          if (_planFits(plan, widths, spacing, constraints.maxWidth)) {
            return Column(children: _buildRows(plan, spacing));
          }
        }

        return Wrap(
          alignment: WrapAlignment.center,
          spacing: spacing,
          runSpacing: 7,
          children: children,
        );
      },
    );
  }

  List<List<int>> _candidatePlans(int count) {
    return switch (count) {
      7 => const [
        [4, 3],
        [3, 4],
        [3, 2, 2],
        [2, 3, 2],
      ],
      6 => const [
        [4, 2],
        [3, 3],
        [2, 2, 2],
      ],
      5 => const [
        [3, 2],
        [2, 3],
      ],
      4 => const [
        [4],
        [2, 2],
      ],
      3 => const [
        [3],
      ],
      2 => const [
        [2],
      ],
      _ => [
        [count],
      ],
    };
  }

  bool _planFits(
    List<int> plan,
    List<double> widths,
    double spacing,
    double maxWidth,
  ) {
    var start = 0;
    for (final rowLength in plan) {
      final rowWidth =
          widths.skip(start).take(rowLength).fold<double>(0, (a, b) => a + b) +
          spacing * (rowLength - 1);
      if (rowWidth > maxWidth) return false;
      start += rowLength;
    }
    return start == widths.length;
  }

  List<Widget> _buildRows(List<int> plan, double spacing) {
    final rows = <Widget>[];
    var start = 0;

    for (var i = 0; i < plan.length; i++) {
      final rowLength = plan[i];
      rows.add(
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: children.skip(start).take(rowLength).expand((child) sync* {
            if (child != children[start]) {
              yield SizedBox(width: spacing);
            }
            yield child;
          }).toList(),
        ),
      );
      if (i != plan.length - 1) {
        rows.add(const SizedBox(height: 7));
      }
      start += rowLength;
    }

    return rows;
  }
}

class _PlayerQuickChip extends StatelessWidget {
  final String value;
  final String? imageUrl;
  final IconData? icon;
  final String? tooltip;

  const _PlayerQuickChip({
    required this.value,
    this.imageUrl,
    this.icon,
    this.tooltip,
  });

  double estimatedWidth(BuildContext context) {
    final textStyle = Theme.of(
      context,
    ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700, height: 1);
    final painter = TextPainter(
      text: TextSpan(text: value, style: textStyle),
      maxLines: 1,
      textDirection: Directionality.of(context),
    )..layout();
    return 20 + 19 + 5 + painter.width;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final foreground = colorScheme.onSurface;

    final chipBody = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.58),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (imageUrl != null && imageUrl!.isNotEmpty)
            MobileWebImage(imageUrl: imageUrl!, width: 19, height: 19)
          else
            Icon(icon ?? Icons.info_rounded, size: 19, color: foreground),
          const SizedBox(width: 5),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 132),
            child: Text(
              value,
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: foreground,
                fontWeight: FontWeight.w700,
                height: 1,
              ),
            ),
          ),
        ],
      ),
    );

    if (tooltip == null || tooltip!.isEmpty) return chipBody;
    return Tooltip(message: tooltip!, child: chipBody);
  }
}

_WarActionInfo? _currentWarAction(BuildContext context, Player player) {
  if (player.warData != null) {
    return _WarActionInfo(
      imageUrl: ImageAssets.war,
      label: AppLocalizations.of(context)!.warOngoing,
      onTap: () => _openWar(context, player.warData!),
    );
  }

  final cwl = player.clan?.warCwl;
  if (cwl != null && cwl.isInWar) {
    return _WarActionInfo(
      imageUrl: ImageAssets.war,
      label: AppLocalizations.of(context)!.warOngoing,
      onTap: () => _openWar(context, cwl.warInfo),
    );
  }

  if (cwl != null && cwl.isInCwl) {
    return _WarActionInfo(
      imageUrl: ImageAssets.cwlSwordsNoBorder,
      label: AppLocalizations.of(context)!.cwlOngoing,
      onTap: () => _openCwl(context, player),
    );
  }

  return null;
}

void _openWar(BuildContext context, WarInfo warInfo) {
  Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => WarScreen(war: warInfo)),
  );
}

void _openCwl(BuildContext context, Player player) {
  final warCwl = player.clan?.warCwl;
  final leagueInfo = warCwl?.leagueInfo;
  if (warCwl == null || leagueInfo == null || leagueInfo.clans.isEmpty) return;
  final clanTag = player.clan!.tag;
  final clanInfo = leagueInfo.clans.firstWhere(
    (clan) => clan.tag == clanTag,
    orElse: () => leagueInfo.clans.first,
  );
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => CwlScreen(
        warCwl: warCwl,
        clanTag: clanTag,
        clanInfo: clanInfo,
        warLeagueName: player.clan!.warLeague?.name,
      ),
    ),
  );
}

class _WarActionInfo {
  final String imageUrl;
  final String label;
  final VoidCallback onTap;

  const _WarActionInfo({
    required this.imageUrl,
    required this.label,
    required this.onTap,
  });
}

class _HallBadge extends StatelessWidget {
  final String imageUrl;
  final int stars;
  final double size;
  final double imageSize;

  const _HallBadge({
    required this.imageUrl,
    required this.stars,
    this.size = 104,
    this.imageSize = 94,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: stars > 0 ? null : imageSize,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: imageSize,
              child: MobileWebImage(
                imageUrl: imageUrl,
                width: imageSize,
                height: imageSize,
                fit: BoxFit.contain,
                errorWidget: (context, url, error) => const Icon(Icons.error),
              ),
            ),
            if (stars > 0) ...[
              const SizedBox(height: 2),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 1,
                children: List.generate(
                  stars,
                  (_) => MobileWebImage(
                    imageUrl: ImageAssets.builderBaseStar,
                    width: 9,
                    height: 9,
                    errorWidget: (context, url, error) =>
                        const Icon(Icons.star, size: 10),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PlayerClanIdentityLine extends StatefulWidget {
  final Player player;
  final String role;
  final MainAxisAlignment alignment;

  const _PlayerClanIdentityLine({
    required this.player,
    required this.role,
    this.alignment = MainAxisAlignment.center,
  });

  @override
  State<_PlayerClanIdentityLine> createState() =>
      _PlayerClanIdentityLineState();
}

class _PlayerClanIdentityLineState extends State<_PlayerClanIdentityLine> {
  String? _cachedClanTag;

  Player get player => widget.player;
  String get role => widget.role;
  MainAxisAlignment get alignment => widget.alignment;

  @override
  void initState() {
    super.initState();
    _loadCachedClanTag();
  }

  @override
  void didUpdateWidget(covariant _PlayerClanIdentityLine oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.player.tag != widget.player.tag) {
      _cachedClanTag = null;
      _loadCachedClanTag();
    }
  }

  Future<void> _loadCachedClanTag() async {
    final cached = await getPrefs('player_${widget.player.tag}_clan_tag');
    if (!mounted || cached == null || cached.isEmpty) return;
    setState(() => _cachedClanTag = cached);
  }

  @override
  Widget build(BuildContext context) {
    final clanTag = [
      player.clan?.tag,
      player.clanOverview.tag,
      player.clanTag,
      _cachedClanTag,
    ].whereType<String>().firstWhere((tag) => tag.isNotEmpty, orElse: () => '');
    final clanName = [player.clan?.name, player.clanOverview.name]
        .whereType<String>()
        .firstWhere((name) => name.isNotEmpty, orElse: () => '');
    final clanBadgeUrl = [
      player.clan?.badgeUrls.small,
      player.clanOverview.badgeUrls.small,
    ].whereType<String>().firstWhere((url) => url.isNotEmpty, orElse: () => '');
    final hasRole = player.role.isNotEmpty;
    final hasClan = clanName.isNotEmpty || clanTag.isNotEmpty;
    final canOpenClan = clanTag.isNotEmpty;
    final displayClanName = clanName.isNotEmpty ? clanName : clanTag;
    final textStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
      color: Colors.white,
      fontSize: 15,
      fontWeight: FontWeight.w500,
      height: 1.05,
    );

    if (!hasClan) {
      return Text(
        role,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: alignment == MainAxisAlignment.start
            ? TextAlign.start
            : TextAlign.center,
        style: textStyle,
      );
    }

    final line = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: alignment,
      children: [
        if (clanBadgeUrl.isNotEmpty) ...[
          MobileWebImage(imageUrl: clanBadgeUrl, width: 16, height: 16),
          const SizedBox(width: 4),
        ],
        if (displayClanName.isNotEmpty)
          Flexible(
            child: Text(
              displayClanName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textStyle,
            ),
          ),
        if (displayClanName.isNotEmpty && hasRole)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 7),
            child: Text(
              '|',
              style: textStyle?.copyWith(
                color: Colors.white.withValues(alpha: 0.30),
              ),
            ),
          ),
        if (hasRole)
          Flexible(
            child: Text(
              role,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textStyle,
            ),
          ),
        if (canOpenClan)
          Icon(
            Icons.chevron_right_rounded,
            size: 18,
            color: Colors.white.withValues(alpha: 0.68),
          ),
      ],
    );

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: canOpenClan
            ? InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: () => _openClan(context, clanTag),
                splashFactory: NoSplash.splashFactory,
                overlayColor: WidgetStateProperty.all(Colors.transparent),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: line,
                ),
              )
            : line,
      ),
    );
  }

  Future<void> _openClan(BuildContext context, String clanTag) async {
    final navigator = Navigator.of(context);
    if (player.clan != null) {
      navigator.push(
        MaterialPageRoute(
          builder: (context) => ClanInfoScreen(clanInfo: player.clan!),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final clan = await context.read<ClanService>().getClanAndWarData(clanTag);
      navigator.pop();
      if (!context.mounted) return;
      navigator.push(
        MaterialPageRoute(builder: (context) => ClanInfoScreen(clanInfo: clan)),
      );
    } catch (_) {
      navigator.pop();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.clanLoadFailed)),
      );
    }
  }
}

class _CopyablePlayerTag extends StatelessWidget {
  final String tag;
  final TextAlign alignment;

  const _CopyablePlayerTag({
    required this.tag,
    this.alignment = TextAlign.center,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(6),
      onTap: () {
        copyTextToClipboard(tag).then((_) {
          if (context.mounted) {
            showClipboardSnackbar(
              context,
              AppLocalizations.of(context)!.generalCopiedToClipboard,
            );
          }
        });
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 1),
        child: Text(
          tag,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: alignment,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.white.withValues(alpha: 0.62),
            fontSize: 15,
            fontWeight: FontWeight.w500,
            height: 1.05,
          ),
        ),
      ),
    );
  }
}

void _showOpenPlayerDialog(BuildContext context, Player player) {
  final languageCode = Localizations.localeOf(
    context,
  ).languageCode.toLowerCase();
  final url = Uri.https('link.clashofclans.com', '/$languageCode', {
    'action': 'OpenPlayerProfile',
    'tag': player.tag,
  });

  showDialog(
    context: context,
    builder: (BuildContext context) => OpenClashDialog(url: url),
  );
}
