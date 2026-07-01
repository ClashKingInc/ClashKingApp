import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:clipboard/clipboard.dart';
import 'package:clashkingapp/common/widgets/dialogs/open_clash_dialog.dart';
import 'package:clashkingapp/common/widgets/dialogs/snackbar.dart';
import 'package:clashkingapp/common/widgets/mobile_web_image.dart';
import 'package:clashkingapp/common/widgets/native_liquid_glass.dart';
import 'package:clashkingapp/core/constants/image_assets.dart';
import 'package:clashkingapp/core/services/bookmark_service.dart';
import 'package:clashkingapp/features/clan/presentation/clan_info/clan_page.dart';
import 'package:clashkingapp/features/player/data/player_service.dart';
import 'package:clashkingapp/features/player/models/player.dart';
import 'package:clashkingapp/features/player/presentation/war_stats/player_war_stats_page.dart';
import 'package:clashkingapp/features/war_cwl/models/war_info.dart';
import 'package:clashkingapp/features/war_cwl/presentation/cwl/cwl.dart';
import 'package:clashkingapp/features/war_cwl/presentation/war/war.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class PlayerInfoHeader extends StatelessWidget {
  final int selectedTab;
  final Player player;

  const PlayerInfoHeader({
    super.key,
    required this.selectedTab,
    required this.player,
  });

  @override
  Widget build(BuildContext context) {
    final isBuilderTab = selectedTab == 1;
    final backgroundImageUrl = isBuilderTab
        ? ImageAssets.builderBaseBackground
        : ImageAssets.homeBaseBackground;
    final hallImageUrl = isBuilderTab
        ? player.builderHallPic
        : player.townHallPic;

    // The backdrop fills the whole header; the glass stats panel straddles
    // its bottom edge, same pattern as the to-do page header.
    const panelOverlap = 46.0;

    return Stack(
      children: [
        Positioned.fill(
          bottom: panelOverlap,
          child: ColorFiltered(
            colorFilter: ColorFilter.mode(
              Colors.black.withValues(alpha: 0.62),
              BlendMode.darken,
            ),
            child: CachedNetworkImage(
              imageUrl: backgroundImageUrl,
              fit: BoxFit.cover,
              errorWidget: (context, url, error) =>
                  ColoredBox(color: Theme.of(context).colorScheme.surface),
            ),
          ),
        ),
        Column(
          children: [
            SizedBox(height: MediaQuery.of(context).padding.top + 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  _HeaderIconButton(
                    icon: Icons.arrow_back_rounded,
                    tooltip:
                        MaterialLocalizations.of(context).backButtonTooltip,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                  const Spacer(),
                  _HeaderIconButton(
                    icon: Icons.open_in_new_rounded,
                    tooltip: 'Open in game',
                    onTap: () => _showOpenPlayerDialog(context, player),
                  ),
                  const SizedBox(width: 8),
                  Consumer<BookmarkService>(
                    builder: (context, bookmarks, child) {
                      final bookmarked =
                          bookmarks.isPlayerBookmarked(player.tag);
                      return _HeaderIconButton(
                        icon: bookmarked
                            ? Icons.bookmark_rounded
                            : Icons.bookmark_border_rounded,
                        tooltip: bookmarked
                            ? 'Remove player bookmark'
                            : 'Bookmark player',
                        onTap: () => bookmarks.togglePlayer(player),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
              child: _IdentityPanel(
                player: player,
                hallImageUrl: hallImageUrl,
                selectedTab: selectedTab,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: isBuilderTab
                  ? _BuilderBaseStats(player: player)
                  : _HomeBaseStats(player: player),
            ),
          ],
        ),
      ],
    );
  }
}

class _IdentityPanel extends StatelessWidget {
  final Player player;
  final String hallImageUrl;
  final int selectedTab;

  const _IdentityPanel({
    required this.player,
    required this.hallImageUrl,
    required this.selectedTab,
  });

  @override
  Widget build(BuildContext context) {
    final role = PlayerService().getRoleText(player.role, context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _HallBadge(
            imageUrl: hallImageUrl,
            xpLevel: player.expLevel,
            stars: selectedTab == 1 ? 0 : player.townHallWeaponLevel,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  player.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  // Always white: the identity row sits on the darkened
                  // backdrop image in both themes.
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Row(
                  children: [
                    Expanded(child: _CopyablePlayerTag(tag: player.tag)),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: _WarPreferenceChip(player: player),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                if (player.clanTag.isNotEmpty)
                  Row(
                    children: [
                      Expanded(
                        child: _ClanRoleChip(player: player, role: role),
                      ),
                    ],
                  )
                else
                  _PlainInfoChip(label: 'Role', value: role),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeBaseStats extends StatelessWidget {
  final Player player;

  const _HomeBaseStats({required this.player});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final locale = Localizations.localeOf(context).toString();
    final formatter = NumberFormat('#,###', locale);

    return _StatsPanel(
      height: 178,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.5,
                  ),
                  shape: BoxShape.circle,
                ),
                child: SizedBox.square(
                  dimension: 36,
                  child: Padding(
                    padding: const EdgeInsets.all(5),
                    child: MobileWebImage(imageUrl: player.leagueUrl),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      player.league,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      formatter.format(player.trophies),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        height: 1,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Text(
                DateFormat('MMMM yyyy').format(DateTime.now()),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _StatBar(
                  label: 'War Stars',
                  value: formatter.format(player.warStars),
                  imageUrl: ImageAssets.attackStar,
                  color: const Color(0xFFE8A524),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          PlayerWarStatsScreen(player: player),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: _StatBar(
                  label: 'Donations',
                  value:
                      '${formatter.format(player.donations)}/${formatter.format(player.donationsReceived)}',
                  icon: Icons.swap_vert_rounded,
                  color: const Color(0xFF14A37F),
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Row(
            children: [
              Expanded(
                child: _StatBar(
                  label: 'Attacks won',
                  value: formatter.format(player.attackWins),
                  imageUrl: ImageAssets.sword,
                  color: const Color(0xFFE35D4F),
                ),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: _StatBar(
                  label: 'Defenses won',
                  value: formatter.format(player.defenseWins),
                  imageUrl: ImageAssets.shield,
                  color: const Color(0xFF4E7DF2),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Liquid glass stats panel straddling the header backdrop edge — the
/// image shows through its top half, same pattern as the to-do header.
class _StatsPanel extends StatelessWidget {
  final Widget child;
  final double height;

  const _StatsPanel({required this.child, required this.height});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          NativeLiquidGlassBar(height: height, cornerRadius: 28),
          Padding(padding: const EdgeInsets.all(14), child: child),
        ],
      ),
    );
  }
}

/// Tinted metric bar, same language as the home to-do card metrics.
class _StatBar extends StatelessWidget {
  final String label;
  final String value;
  final String? imageUrl;
  final IconData? icon;
  final Color color;
  final VoidCallback? onTap;

  const _StatBar({
    required this.label,
    required this.value,
    required this.color,
    this.imageUrl,
    this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      height: 46,
      child: Material(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 9),
            child: Row(
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: colorScheme.surface.withValues(alpha: 0.72),
                    shape: BoxShape.circle,
                  ),
                  child: SizedBox.square(
                    dimension: 34,
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: imageUrl != null
                          ? MobileWebImage(imageUrl: imageUrl!)
                          : Icon(icon, size: 19, color: color),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Stacked label/value so neither fights the other for
                // horizontal space — labels no longer get truncated.
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: color,
                          fontWeight: FontWeight.w900,
                          height: 1.1,
                        ),
                      ),
                    ],
                  ),
                ),
                if (onTap != null)
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: colorScheme.onSurfaceVariant,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class PlayerProfileFloatingActions extends StatelessWidget {
  final Player player;

  const PlayerProfileFloatingActions({super.key, required this.player});

  @override
  Widget build(BuildContext context) {
    final warAction = _currentWarAction(context, player);

    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(14, 0, 14, 6),
      child: SizedBox(
        height: 62,
        child: Align(
          alignment: Alignment.topCenter,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (warAction != null) ...[
                SizedBox(
                  width: 124,
                  child: _FloatingProfileAction(
                    imageUrl: warAction.imageUrl,
                    label: warAction.label,
                    emphasized: true,
                    onTap: warAction.onTap,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _FloatingProfileAction extends StatelessWidget {
  final String? imageUrl;
  final String label;
  final bool emphasized;
  final VoidCallback onTap;

  const _FloatingProfileAction({
    this.imageUrl,
    required this.label,
    this.emphasized = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const red = Color(0xFFE0302B);
    final colorScheme = Theme.of(context).colorScheme;
    final foreground = emphasized ? Colors.white : colorScheme.onSurface;

    // The Android glass fallback is far more translucent than the iOS
    // native glass — give it a more solid fill so the button stays
    // readable over scrolling content.
    final native = supportsNativeLiquidGlass;

    return SizedBox(
      height: 62,
      child: Stack(
        fit: StackFit.expand,
        children: [
          NativeLiquidGlassBar(
            height: 62,
            cornerRadius: 31,
            opacity: native ? (emphasized ? 0.62 : 0.68) : 1.0,
            borderOpacity: emphasized ? 0.44 : 0.3,
            shadowOpacity: 0.22,
            interactive: true,
          ),
          if (emphasized)
            DecoratedBox(
              decoration: BoxDecoration(
                color: red.withValues(alpha: native ? 0.22 : 0.38),
                borderRadius: BorderRadius.circular(31),
                border: Border.all(color: red.withValues(alpha: 0.5)),
              ),
            ),
          Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(31),
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(31),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (imageUrl != null)
                      MobileWebImage(
                        imageUrl: imageUrl!,
                        width: 24,
                        height: 24,
                      ),
                    const SizedBox(height: 3),
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: foreground,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

_WarActionInfo? _currentWarAction(BuildContext context, Player player) {
  if (player.warData != null) {
    return _WarActionInfo(
      imageUrl: ImageAssets.war,
      label: 'Ongoing War',
      onTap: () => _openWar(context, player.warData!),
    );
  }

  final cwl = player.clan?.warCwl;
  if (cwl != null && cwl.isInWar) {
    return _WarActionInfo(
      imageUrl: ImageAssets.war,
      label: 'Ongoing War',
      onTap: () => _openWar(context, cwl.warInfo),
    );
  }

  if (cwl != null && cwl.isInCwl) {
    return _WarActionInfo(
      imageUrl: ImageAssets.cwlSwordsNoBorder,
      label: 'Ongoing CWL',
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
      builder: (context) =>
          CwlScreen(warCwl: warCwl, clanTag: clanTag, clanInfo: clanInfo),
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

class _BuilderBaseStats extends StatelessWidget {
  final Player player;

  const _BuilderBaseStats({required this.player});

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    final formatter = NumberFormat('#,###', locale);

    return _StatsPanel(
      height: 128,
      child: Column(
        children: [
          _StatBar(
            label: 'Builder Trophies',
            value: formatter.format(player.builderBaseTrophies),
            imageUrl: ImageAssets.trophies,
            color: const Color(0xFFE8A524),
          ),
          const SizedBox(height: 7),
          Row(
            children: [
              Expanded(
                child: _StatBar(
                  label: 'Attacks won',
                  value: formatter.format(player.attackWins),
                  imageUrl: ImageAssets.sword,
                  color: const Color(0xFFE35D4F),
                ),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: _StatBar(
                  label: 'Defenses won',
                  value: formatter.format(player.defenseWins),
                  imageUrl: ImageAssets.shield,
                  color: const Color(0xFF4E7DF2),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HallBadge extends StatelessWidget {
  final String imageUrl;
  final int xpLevel;
  final int stars;

  const _HallBadge({
    required this.imageUrl,
    required this.xpLevel,
    required this.stars,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 82,
      child: Column(
        children: [
          SizedBox(
            height: 76,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CachedNetworkImage(
                  imageUrl: imageUrl,
                  width: 76,
                  fit: BoxFit.contain,
                  errorWidget: (context, url, error) => const Icon(Icons.error),
                ),
              ],
            ),
          ),
          if (stars > 0) ...[
            const SizedBox(height: 3),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 1,
              children: List.generate(
                stars,
                (_) => CachedNetworkImage(
                  imageUrl: ImageAssets.builderBaseStar,
                  width: 9,
                  height: 9,
                  errorWidget: (context, url, error) =>
                      const Icon(Icons.star, size: 10),
                ),
              ),
            ),
          ],
          const SizedBox(height: 5),
          _XpPill(level: xpLevel),
        ],
      ),
    );
  }
}

class _ClanRoleChip extends StatelessWidget {
  final Player player;
  final String role;

  const _ClanRoleChip({required this.player, required this.role});

  @override
  Widget build(BuildContext context) {
    // Sits on the darkened backdrop image: liquid glass chrome + white text.
    return SizedBox(
      height: 46,
      child: Stack(
        fit: StackFit.expand,
        children: [
          const NativeLiquidGlassBar(height: 46, cornerRadius: 14),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: player.clan == null
                  ? null
                  : () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            ClanInfoScreen(clanInfo: player.clan!),
                      ),
                    ),
              borderRadius: BorderRadius.circular(14),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Row(
                  children: [
                    MobileWebImage(
                      imageUrl: player.clanOverview.badgeUrls.small,
                      width: 26,
                      height: 26,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Clan • $role',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color:
                                      Colors.white.withValues(alpha: 0.72),
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          Text(
                            player.clanOverview.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .labelLarge
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ],
                      ),
                    ),
                    if (player.clan != null)
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 18,
                        color: Colors.white.withValues(alpha: 0.65),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WarPreferenceChip extends StatelessWidget {
  final Player player;

  const _WarPreferenceChip({required this.player});

  @override
  Widget build(BuildContext context) {
    final inWar = player.warPreference == 'in';
    final label = inWar
        ? AppLocalizations.of(context)!.warStatusReady
        : AppLocalizations.of(context)!.warStatusUnready;
    final color =
        inWar ? Colors.green : Theme.of(context).colorScheme.primary;

    return Container(
      constraints: const BoxConstraints(maxWidth: 144),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        // Solid enough to stay readable over the backdrop image.
        color: color.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          MobileWebImage(
            imageUrl: player.warPreferenceImage,
            width: 15,
            height: 15,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlainInfoChip extends StatelessWidget {
  final String label;
  final String value;

  const _PlainInfoChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$label: $value',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(
          context,
        ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _XpPill extends StatelessWidget {
  final int level;

  const _XpPill({required this.level});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.86),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const MobileWebImage(imageUrl: ImageAssets.xp, width: 16, height: 16),
          const SizedBox(width: 4),
          Text(
            'Level $level',
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _HeaderIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const size = 42.0;
    const radius = 19.0;

    return Tooltip(
      message: tooltip,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Material(
            color: Theme.of(
              context,
            ).colorScheme.surface.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(radius),
            child: InkWell(
              borderRadius: BorderRadius.circular(radius),
              onTap: onTap,
              child: SizedBox(
                height: size,
                width: size,
                child: Icon(icon, size: 25),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CopyablePlayerTag extends StatelessWidget {
  final String tag;

  const _CopyablePlayerTag({required this.tag});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(6),
      onTap: () {
        FlutterClipboard.copy(tag).then((_) {
          if (context.mounted) {
            showClipboardSnackbar(
              context,
              AppLocalizations.of(context)!.generalCopiedToClipboard,
            );
          }
        });
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Text(
          tag,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.white.withValues(alpha: 0.75),
            fontWeight: FontWeight.w700,
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
