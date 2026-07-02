import 'dart:async';
import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:clipboard/clipboard.dart';
import 'package:clashkingapp/common/widgets/dialogs/open_clash_dialog.dart';
import 'package:clashkingapp/common/widgets/dialogs/snackbar.dart';
import 'package:clashkingapp/common/widgets/header_widgets.dart';
import 'package:clashkingapp/common/widgets/mobile_web_image.dart';
import 'package:clashkingapp/common/widgets/native_liquid_glass.dart';
import 'package:clashkingapp/core/constants/image_assets.dart';
import 'package:clashkingapp/core/functions/functions.dart';
import 'package:clashkingapp/core/services/bookmark_service.dart';
import 'package:clashkingapp/features/clan/data/clan_service.dart';
import 'package:clashkingapp/features/clan/presentation/clan_info/clan_page.dart';
import 'package:clashkingapp/features/player/data/player_service.dart';
import 'package:clashkingapp/features/player/models/player.dart';
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
    final warAction = _currentWarAction(context, player);

    return Stack(
      children: [
        Positioned.fill(
          child: ColorFiltered(
            colorFilter: ColorFilter.mode(
              Colors.black.withValues(alpha: 0.50),
              BlendMode.darken,
            ),
            child: CachedNetworkImage(
              imageUrl: backgroundImageUrl,
              fit: BoxFit.cover,
              alignment: Alignment.bottomCenter,
              errorWidget: (context, url, error) =>
                  ColoredBox(color: Theme.of(context).colorScheme.surface),
            ),
          ),
        ),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Theme.of(context).colorScheme.surface.withValues(alpha: 0.36),
                  Theme.of(context).colorScheme.surface.withValues(alpha: 0.64),
                  Theme.of(context).colorScheme.surface.withValues(alpha: 0.92),
                ],
              ),
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
                    tooltip: MaterialLocalizations.of(
                      context,
                    ).backButtonTooltip,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                  const Spacer(),
                  if (warAction != null) ...[
                    _HeaderImageButton(
                      imageUrl: warAction.imageUrl,
                      tooltip: warAction.label,
                      backgroundColor: const Color(0xFFE0302B),
                      onTap: warAction.onTap,
                    ),
                    const SizedBox(width: 8),
                  ],
                  _HeaderIconButton(
                    icon: Icons.open_in_new_rounded,
                    tooltip: 'Open in game',
                    onTap: () => _showOpenPlayerDialog(context, player),
                  ),
                  const SizedBox(width: 8),
                  Consumer<BookmarkService>(
                    builder: (context, bookmarks, child) {
                      final bookmarked = bookmarks.isPlayerBookmarked(
                        player.tag,
                      );
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
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: _IdentityPanel(
                player: player,
                hallImageUrl: hallImageUrl,
                selectedTab: selectedTab,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
              child: _HomeBaseStats(player: player, isBuilderTab: isBuilderTab),
            ),
          ],
        ),
      ],
    );
  }
}

class _HeaderImageButton extends StatelessWidget {
  final String imageUrl;
  final String tooltip;
  final Color backgroundColor;
  final VoidCallback onTap;

  const _HeaderImageButton({
    required this.imageUrl,
    required this.tooltip,
    required this.backgroundColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return _HeaderGlassButton(
      tooltip: tooltip,
      onTap: onTap,
      tint: backgroundColor,
      child: Center(
        child: MobileWebImage(imageUrl: imageUrl, width: 25, height: 25),
      ),
    );
  }
}

class _GlassPanel extends StatelessWidget {
  final Widget child;
  final double? width;
  final double height;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? tint;

  const _GlassPanel({
    required this.child,
    this.width,
    required this.height,
    required this.borderRadius,
    required this.padding,
    this.onTap,
    this.tint,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Stack(
          children: [
            Positioned.fill(
              child: NativeLiquidGlassBar(
                height: height,
                cornerRadius: borderRadius,
                opacity: 0.72,
                interactive: onTap != null,
                borderOpacity: Theme.of(context).brightness == Brightness.dark
                    ? 0.22
                    : 0.32,
                shadowOpacity: Theme.of(context).brightness == Brightness.dark
                    ? 0.24
                    : 0.08,
              ),
            ),
            if (tint != null)
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(borderRadius),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        tint!.withValues(alpha: 0.24),
                        tint!.withValues(alpha: 0.08),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(borderRadius),
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(borderRadius),
                splashFactory: NoSplash.splashFactory,
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
                child: Padding(padding: padding, child: child),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderGlassButton extends StatelessWidget {
  final Widget child;
  final String tooltip;
  final VoidCallback onTap;
  final Color? tint;

  const _HeaderGlassButton({
    required this.child,
    required this.tooltip,
    required this.onTap,
    this.tint,
  });

  @override
  Widget build(BuildContext context) {
    const size = 42.0;
    const radius = 19.0;

    return Tooltip(
      message: tooltip,
      child: SizedBox(
        height: size,
        width: size,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: Stack(
            fit: StackFit.expand,
            children: [
              const NativeLiquidGlassBar(
                height: size,
                cornerRadius: radius,
                opacity: 0.72,
                interactive: true,
              ),
              if (tint != null)
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: tint!.withValues(alpha: 0.58),
                    borderRadius: BorderRadius.circular(radius),
                  ),
                ),
              Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(radius),
                child: InkWell(
                  borderRadius: BorderRadius.circular(radius),
                  splashFactory: NoSplash.splashFactory,
                  splashColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                  onTap: onTap,
                  child: child,
                ),
              ),
            ],
          ),
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
          _HallBadge(imageUrl: hallImageUrl, stars: player.townHallWeaponLevel),
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
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(
                  height: 27,
                  child: Row(
                    children: [
                      Expanded(child: _CopyablePlayerTag(tag: player.tag)),
                    ],
                  ),
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
  final bool isBuilderTab;

  const _HomeBaseStats({required this.player, required this.isBuilderTab});

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    final formatter = NumberFormat('#,###', locale);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        isBuilderTab
            ? _LeagueSummaryTile(
                leagueName: player.builderBaseLeague,
                trophies: formatter.format(player.builderBaseTrophies),
                leagueUrl: player.builderBaseLeagueUrl,
                seasonName: DateFormat('MMMM yyyy').format(DateTime.now()),
                bestTrophies: formatter.format(player.bestBuilderBaseTrophies),
              )
            : _LeagueSummaryTile(
                leagueName: player.league,
                trophies: formatter.format(player.trophies),
                leagueUrl: player.leagueUrl,
                seasonName: DateFormat('MMMM yyyy').format(DateTime.now()),
                attackWins: formatter.format(player.attackWins),
                defenseWins: formatter.format(player.defenseWins),
              ),
        const SizedBox(height: 6),
        _PlayerQuickStats(player: player),
      ],
    );
  }
}

class _PlayerQuickStats extends StatelessWidget {
  final Player player;

  const _PlayerQuickStats({required this.player});

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    final formatter = NumberFormat('#,###', locale);
    final warPreferenceLabel = player.warPreference == 'in'
        ? AppLocalizations.of(context)!.warStatusReady
        : AppLocalizations.of(context)!.warStatusUnready;

    final loc = AppLocalizations.of(context)!;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: MetricChip(
                label: loc.playerWarStarsTitle,
                value: formatter.format(player.warStars),
                imageUrl: ImageAssets.attackStar,
                color: const Color(0xFFE8A524),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: MetricChip(
                label: loc.playerWarPreferenceTitle,
                value: warPreferenceLabel,
                imageUrl: player.warPreferenceImage,
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: MetricChip(
                label: loc.playerDonatedTitle,
                value: formatter.format(player.donations),
                icon: Icons.arrow_upward_rounded,
                color: const Color(0xFF14A37F),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: MetricChip(
                label: loc.playerReceivedTitle,
                value: formatter.format(player.donationsReceived),
                icon: Icons.arrow_downward_rounded,
                color: const Color(0xFFE35D4F),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: MetricChip(
                label: loc.playerCapitalTitle,
                value: formatter.format(player.clanCapitalContributions),
                imageUrl: ImageAssets.capitalGold,
                color: const Color(0xFF8D63D9),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: MetricChip(
                label: loc.playerExpLevelTitle,
                value: player.expLevel.toString(),
                imageUrl: ImageAssets.xp,
              ),
            ),
          ],
        ),
      ],
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

class _LeagueSummaryTile extends StatefulWidget {
  final String leagueName;
  final String trophies;
  final String leagueUrl;
  final String seasonName;
  final String? attackWins;
  final String? defenseWins;
  final String? bestTrophies;

  const _LeagueSummaryTile({
    required this.leagueName,
    required this.trophies,
    required this.leagueUrl,
    required this.seasonName,
    this.attackWins,
    this.defenseWins,
    this.bestTrophies,
  });

  @override
  State<_LeagueSummaryTile> createState() => _LeagueSummaryTileState();
}

class _LeagueSummaryTileState extends State<_LeagueSummaryTile> {
  static final Map<String, Color> _tintCache = {};
  Color? _tint;

  @override
  void initState() {
    super.initState();
    _loadTint();
  }

  @override
  void didUpdateWidget(covariant _LeagueSummaryTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.leagueUrl != widget.leagueUrl) {
      _loadTint();
    }
  }

  Future<void> _loadTint() async {
    final leagueUrl = widget.leagueUrl;
    if (leagueUrl.isEmpty) {
      if (mounted) setState(() => _tint = null);
      return;
    }

    final cachedTint = _tintCache[leagueUrl];
    if (cachedTint != null) {
      if (mounted) setState(() => _tint = cachedTint);
      return;
    }

    if (mounted) setState(() => _tint = null);

    try {
      final provider = CachedNetworkImageProvider(leagueUrl);
      final stream = provider.resolve(ImageConfiguration.empty);
      late final ImageStreamListener listener;
      final completer = Completer<ImageInfo>();

      listener = ImageStreamListener(
        (imageInfo, synchronousCall) {
          if (!completer.isCompleted) completer.complete(imageInfo);
          stream.removeListener(listener);
        },
        onError: (error, stackTrace) {
          if (!completer.isCompleted) {
            completer.completeError(error, stackTrace);
          }
          stream.removeListener(listener);
        },
      );
      stream.addListener(listener);

      final imageInfo = await completer.future;
      final tint = await _dominantTint(imageInfo.image);
      if (tint == null) return;

      _tintCache[leagueUrl] = tint;
      if (mounted && widget.leagueUrl == leagueUrl) {
        setState(() => _tint = tint);
      }
    } catch (_) {
      // Keep the glass neutral if the remote badge cannot be sampled.
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return _GlassPanel(
      width: double.infinity,
      height: 75,
      borderRadius: 16,
      padding: const EdgeInsets.all(12),
      tint: _tint,
      child: Row(
        children: [
          MobileWebImage(imageUrl: widget.leagueUrl, width: 46, height: 46),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.leagueName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.trophies,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
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
                    widget.seasonName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.72),
                      fontWeight: FontWeight.w600,
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
              if (widget.attackWins != null && widget.defenseWins != null)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _MiniMetric(
                      stat: _MetricSubStat(
                        imageUrl: ImageAssets.sword,
                        value: widget.attackWins!,
                      ),
                    ),
                    const SizedBox(width: 10),
                    _MiniMetric(
                      stat: _MetricSubStat(
                        imageUrl: ImageAssets.shield,
                        value: widget.defenseWins!,
                      ),
                    ),
                  ],
                )
              else if (widget.bestTrophies != null)
                _MiniMetric(
                  stat: _MetricSubStat(
                    imageUrl: ImageAssets.bestTrophies,
                    value: widget.bestTrophies!,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

Future<Color?> _dominantTint(ui.Image image) async {
  final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  if (data == null) return null;

  final buckets = <int, _ColorBucket>{};
  const sampleStride = 4;
  for (var y = 0; y < image.height; y += sampleStride) {
    for (var x = 0; x < image.width; x += sampleStride) {
      final index = (y * image.width + x) * 4;
      final r = data.getUint8(index);
      final g = data.getUint8(index + 1);
      final b = data.getUint8(index + 2);
      final a = data.getUint8(index + 3);
      if (a < 96) continue;

      final color = Color.fromARGB(a, r, g, b);
      final hsl = HSLColor.fromColor(color);
      if (hsl.lightness < 0.12 || hsl.lightness > 0.92) continue;
      if (hsl.saturation < 0.24) continue;

      final key = (r ~/ 24) << 16 | (g ~/ 24) << 8 | (b ~/ 24);
      final bucket = buckets.putIfAbsent(key, _ColorBucket.new);
      bucket
        ..count += 1
        ..red += r
        ..green += g
        ..blue += b
        ..score += hsl.saturation * (1 - (hsl.lightness - 0.55).abs());
    }
  }

  if (buckets.isEmpty) return null;
  final best = buckets.values.reduce(
    (a, b) => a.weightedScore >= b.weightedScore ? a : b,
  );
  return Color.fromARGB(
    255,
    best.red ~/ best.count,
    best.green ~/ best.count,
    best.blue ~/ best.count,
  );
}

class _ColorBucket {
  int count = 0;
  int red = 0;
  int green = 0;
  int blue = 0;
  double score = 0;

  double get weightedScore => count * score;
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
            ).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

class _HallBadge extends StatelessWidget {
  final String imageUrl;
  final int stars;

  const _HallBadge({required this.imageUrl, required this.stars});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 104,
      child: Column(
        children: [
          SizedBox(
            height: 104,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CachedNetworkImage(
                  imageUrl: imageUrl,
                  width: 104,
                  fit: BoxFit.contain,
                  errorWidget: (context, url, error) => const Icon(Icons.error),
                ),
              ],
            ),
          ),
          if (stars > 0) ...[
            const SizedBox(height: 2),
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
        ],
      ),
    );
  }
}

class _ClanRoleChip extends StatefulWidget {
  final Player player;
  final String role;

  const _ClanRoleChip({required this.player, required this.role});

  @override
  State<_ClanRoleChip> createState() => _ClanRoleChipState();
}

class _ClanRoleChipState extends State<_ClanRoleChip> {
  String? _cachedClanTag;

  Player get player => widget.player;
  String get role => widget.role;

  @override
  void initState() {
    super.initState();
    _loadCachedClanTag();
  }

  @override
  void didUpdateWidget(covariant _ClanRoleChip oldWidget) {
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
    final canOpenClan = clanTag.isNotEmpty;

    return _GlassPanel(
      width: double.infinity,
      height: 50,
      borderRadius: 16,
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      onTap: canOpenClan ? () => _openClan(context, clanTag) : null,
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
                  role,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.6),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  player.clanOverview.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          if (canOpenClan)
            Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.48),
            ),
        ],
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to load clan.')));
    }
  }
}

class _PlainInfoChip extends StatelessWidget {
  final String label;
  final String value;

  const _PlainInfoChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return _GlassPanel(
      height: 34,
      borderRadius: 16,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      child: Text(
        '$label: $value',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(
          context,
        ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
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
    return _HeaderGlassButton(
      tooltip: tooltip,
      onTap: onTap,
      child: Icon(icon, size: 25),
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
            fontWeight: FontWeight.w500,
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
