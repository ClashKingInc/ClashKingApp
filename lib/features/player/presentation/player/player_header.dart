import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:clipboard/clipboard.dart';
import 'package:clashkingapp/common/widgets/dialogs/open_clash_dialog.dart';
import 'package:clashkingapp/common/widgets/dialogs/snackbar.dart';
import 'package:clashkingapp/common/widgets/mobile_web_image.dart';
import 'package:clashkingapp/common/widgets/native_liquid_glass.dart';
import 'package:clashkingapp/core/constants/image_assets.dart';
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

    return ColoredBox(
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        children: [
          Stack(
            children: [
              _HeaderBackdrop(imageUrl: backgroundImageUrl),
              Positioned(
                left: 12,
                bottom: 10,
                child: _HeaderIconButton(
                  icon: Icons.arrow_back_rounded,
                  tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                  onTap: () => Navigator.of(context).pop(),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: _IdentityPanel(
              player: player,
              hallImageUrl: hallImageUrl,
              selectedTab: selectedTab,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: isBuilderTab
                ? _BuilderBaseStats(player: player)
                : _HomeBaseStats(player: player),
          ),
        ],
      ),
    );
  }
}

class _HeaderBackdrop extends StatelessWidget {
  final String imageUrl;

  const _HeaderBackdrop({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 62 + MediaQuery.of(context).padding.top,
      width: double.infinity,
      child: ColorFiltered(
        colorFilter: ColorFilter.mode(
          Colors.black.withValues(alpha: 0.28),
          BlendMode.darken,
        ),
        child: CachedNetworkImage(
          imageUrl: imageUrl,
          fit: BoxFit.cover,
          errorWidget: (context, url, error) => const Icon(Icons.error),
        ),
      ),
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
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        player.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    _HeaderIconButton(
                      icon: Icons.open_in_new_rounded,
                      tooltip: 'Open in game',
                      compact: true,
                      onTap: () => _showOpenPlayerDialog(context, player),
                    ),
                  ],
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
    final locale = Localizations.localeOf(context).toString();
    final formatter = NumberFormat('#,###', locale);

    return Column(
      children: [
        _LeagueSummaryTile(
          leagueName: player.league,
          trophies: formatter.format(player.trophies),
          leagueUrl: player.leagueUrl,
          seasonName: DateFormat('MMMM yyyy').format(DateTime.now()),
          attackWins: formatter.format(player.attackWins),
          defenseWins: formatter.format(player.defenseWins),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _DetailStatTile(
                label: 'War Stars',
                value: formatter.format(player.warStars),
                imageUrl: ImageAssets.attackStar,
                showChevron: true,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PlayerWarStatsScreen(player: player),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _DetailStatTile(
                label: 'Donations',
                value:
                    '${formatter.format(player.donations)} / ${formatter.format(player.donationsReceived)}',
                icon: Icons.swap_vert_rounded,
              ),
            ),
          ],
        ),
      ],
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

    return SizedBox(
      height: 62,
      child: Stack(
        fit: StackFit.expand,
        children: [
          NativeLiquidGlassBar(
            height: 62,
            cornerRadius: 31,
            opacity: emphasized ? 0.62 : 0.68,
            borderOpacity: emphasized ? 0.44 : 0.3,
            shadowOpacity: 0.22,
            interactive: true,
          ),
          if (emphasized)
            DecoratedBox(
              decoration: BoxDecoration(
                color: red.withValues(alpha: 0.22),
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
      builder: (context) => CwlScreen(
        warCwl: warCwl,
        clanTag: clanTag,
        clanInfo: clanInfo,
      ),
    ),
  );
}

class _LeagueSummaryTile extends StatelessWidget {
  final String leagueName;
  final String trophies;
  final String leagueUrl;
  final String seasonName;
  final String attackWins;
  final String defenseWins;

  const _LeagueSummaryTile({
    required this.leagueName,
    required this.trophies,
    required this.leagueUrl,
    required this.seasonName,
    required this.attackWins,
    required this.defenseWins,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.38),
        ),
      ),
      child: Row(
        children: [
          MobileWebImage(imageUrl: leagueUrl, width: 46, height: 46),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  leagueName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  trophies,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    seasonName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: colorScheme.onSurface.withValues(alpha: 0.58),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _MiniMetric(
                    stat: _MetricSubStat(
                      imageUrl: ImageAssets.sword,
                      value: attackWins,
                    ),
                  ),
                  const SizedBox(width: 10),
                  _MiniMetric(
                    stat: _MetricSubStat(
                      imageUrl: ImageAssets.shield,
                      value: defenseWins,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DetailStatTile extends StatelessWidget {
  final String label;
  final String value;
  final String? imageUrl;
  final IconData? icon;
  final bool showChevron;
  final VoidCallback? onTap;

  const _DetailStatTile({
    required this.label,
    required this.value,
    this.imageUrl,
    this.icon,
    this.showChevron = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.42),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 70,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.38),
            ),
          ),
          child: Row(
            children: [
              if (imageUrl != null)
                MobileWebImage(imageUrl: imageUrl!, width: 28, height: 28)
              else
                Icon(icon, size: 24, color: colorScheme.onSurface),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.62),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              if (showChevron)
                Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: colorScheme.onSurface.withValues(alpha: 0.48),
                ),
            ],
          ),
        ),
      ),
    );
  }
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

    return _MetricGrid(
      metrics: [
        _MetricData(
          label: 'Builder Trophies',
          value: formatter.format(player.builderBaseTrophies),
          imageUrl: ImageAssets.trophies,
          subStats: [
            _MetricSubStat(
              imageUrl: ImageAssets.sword,
              value: formatter.format(player.attackWins),
            ),
            _MetricSubStat(
              imageUrl: ImageAssets.shield,
              value: formatter.format(player.defenseWins),
            ),
          ],
        ),
      ],
    );
  }
}

class _MetricGrid extends StatelessWidget {
  final List<_MetricData> metrics;

  const _MetricGrid({required this.metrics});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final preferredCount = constraints.maxWidth >= 520 ? 4 : 3;
        final crossAxisCount = metrics.length < preferredCount
            ? metrics.length
            : preferredCount;
        const spacing = 8.0;
        final itemWidth =
            (constraints.maxWidth - spacing * (crossAxisCount - 1)) /
            crossAxisCount;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: metrics
              .map(
                (metric) => SizedBox(
                  width: itemWidth,
                  child: _MetricTile(metric: metric),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _MetricTile extends StatelessWidget {
  final _MetricData metric;

  const _MetricTile({required this.metric});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      height: 84,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.38),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Row(
              children: [
                _MetricIcon(metric: metric),
                const SizedBox(width: 7),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        metric.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.62),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        metric.value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (metric.subStats.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              children: metric.subStats
                  .map((stat) => Expanded(child: _MiniMetric(stat: stat)))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _MetricIcon extends StatelessWidget {
  final _MetricData metric;

  const _MetricIcon({required this.metric});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 28,
      width: 28,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Center(
            child: MobileWebImage(
              imageUrl: metric.imageUrl,
              width: 25,
              height: 25,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricData {
  final String label;
  final String value;
  final String imageUrl;
  final List<_MetricSubStat> subStats;

  const _MetricData({
    required this.label,
    required this.value,
    required this.imageUrl,
    this.subStats = const [],
  });
}

class _MetricSubStat {
  final String imageUrl;
  final String value;

  const _MetricSubStat({required this.imageUrl, required this.value});
}

class _MiniMetric extends StatelessWidget {
  final _MetricSubStat stat;

  const _MiniMetric({required this.stat});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        MobileWebImage(imageUrl: stat.imageUrl, width: 14, height: 14),
        const SizedBox(width: 3),
        Flexible(
          child: Text(
            stat.value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
        ),
      ],
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
    return Material(
      color: Theme.of(
        context,
      ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: player.clan == null
            ? null
            : () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ClanInfoScreen(clanInfo: player.clan!),
                ),
              ),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Theme.of(
                context,
              ).colorScheme.outlineVariant.withValues(alpha: 0.42),
            ),
          ),
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
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Clan • $role',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.6),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      player.clanOverview.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
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
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.48),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WarPreferenceChip extends StatelessWidget {
  final Player player;

  const _WarPreferenceChip({required this.player});

  @override
  Widget build(BuildContext context) {
    final label = player.warPreference == 'in'
        ? AppLocalizations.of(context)!.warStatusReady
        : AppLocalizations.of(context)!.warStatusUnready;

    return Container(
      constraints: const BoxConstraints(maxWidth: 144),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          MobileWebImage(
            imageUrl: player.warPreferenceImage,
            width: 17,
            height: 17,
          ),
          const SizedBox(width: 3),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w800),
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
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(
            context,
          ).colorScheme.outlineVariant.withValues(alpha: 0.42),
        ),
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
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.86),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(
            context,
          ).colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          MobileWebImage(imageUrl: ImageAssets.xp, width: 16, height: 16),
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
  final bool compact;

  const _HeaderIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final size = compact ? 36.0 : 42.0;
    final radius = compact ? 16.0 : 19.0;

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
                child: Icon(icon, size: compact ? 19 : 25),
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
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.62),
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
