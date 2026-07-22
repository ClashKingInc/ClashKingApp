import 'dart:async';
import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:clashking_design_system/clashking_design_system.dart';
import 'package:clashkingapp/common/widgets/mobile_web_image.dart';
import 'package:clashkingapp/common/widgets/liquid_glass.dart';
import 'package:clashkingapp/core/constants/image_assets.dart';
import 'package:flutter/material.dart';

/// Shared scenic backdrop and contrast gradient for detail-page hero headers.
class InfoHeroBackdrop extends StatelessWidget {
  const InfoHeroBackdrop({
    super.key,
    required this.imageUrl,
    required this.height,
    this.additionalDarken = 0,
  });

  final String imageUrl;
  final double height;

  /// Extra flat black darken (0-1) applied under the gradient, for hero
  /// images bright enough that the gradient alone doesn't give white
  /// overlay content enough contrast.
  final double additionalDarken;

  @override
  Widget build(BuildContext context) {
    Widget image = MobileWebImage(
      imageUrl: imageUrl,
      fit: BoxFit.cover,
      alignment: Alignment.bottomCenter,
      errorWidget: (context, url, error) =>
          ColoredBox(color: Theme.of(context).colorScheme.surface),
    );
    if (additionalDarken > 0) {
      image = ColorFiltered(
        colorFilter: ColorFilter.mode(
          Colors.black.withValues(alpha: additionalDarken),
          BlendMode.darken,
        ),
        child: image,
      );
    }
    return ClipRect(
      child: RepaintBoundary(
        child: SizedBox(
          height: height,
          child: Stack(
            fit: StackFit.expand,
            children: [
              image,
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: Theme.of(context).brightness == Brightness.dark
                        ? const [
                            Color.fromRGBO(0, 0, 0, 0.50),
                            Color.fromRGBO(0, 0, 0, 0.72),
                            Color.fromRGBO(0, 0, 0, 0.94),
                          ]
                        : const [
                            Color.fromRGBO(0, 0, 0, 0.34),
                            Color.fromRGBO(0, 0, 0, 0.52),
                            Color.fromRGBO(0, 0, 0, 0.72),
                          ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Frosted round icon button floating over a hero header image. Every
/// hero-header screen shares the same Flutter-composited glass implementation.
class HeaderIconButton extends StatelessWidget {
  final IconData? icon;
  final String? imageUrl;
  final Color? iconColor;
  final String tooltip;
  final VoidCallback onTap;
  final bool showBackground;

  const HeaderIconButton({
    super.key,
    this.icon,
    this.imageUrl,
    this.iconColor,
    required this.tooltip,
    required this.onTap,
    this.showBackground = true,
  });

  @override
  Widget build(BuildContext context) {
    const size = 48.0;
    const radius = 20.0;
    final colorScheme = Theme.of(context).colorScheme;

    return Tooltip(
      message: tooltip,
      child: SizedBox.square(
        dimension: size,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (showBackground)
              const LiquidGlassBar(
                height: size,
                cornerRadius: radius,
                opacity: 0.70,
                interactive: true,
              ),
            Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(radius),
              child: InkWell(
                borderRadius: BorderRadius.circular(radius),
                onTap: onTap,
                child: imageUrl != null
                    ? Padding(
                        padding: const EdgeInsets.all(8),
                        child: MobileWebImage(imageUrl: imageUrl!),
                      )
                    : Icon(
                        icon,
                        size: 25,
                        color: iconColor ?? colorScheme.onSurface,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Background for hero-header panels. Flutter mobile platforms get the shared
/// shader glass; web gets a near-opaque card fill because backdrop sampling in
/// slivers can wash the content below with the panel fill.
class HeaderPanelBackground extends StatelessWidget {
  final double height;
  final double cornerRadius;

  const HeaderPanelBackground({
    super.key,
    required this.height,
    required this.cornerRadius,
  });

  @override
  Widget build(BuildContext context) {
    if (supportsLiquidGlass) {
      return LiquidGlassBar(
        height: height,
        cornerRadius: cornerRadius,
        opacity: 0.95,
      );
    }

    final theme = Theme.of(context);
    final surfaceColor = theme.cardTheme.color ?? theme.colorScheme.surface;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: surfaceColor.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(cornerRadius),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.32),
        ),
      ),
    );
  }
}

/// Compact metric chip: icon in a circle + small label above a bold
/// colored value — the metric-bar language, sized to its content so
/// chips flow freely in a wrap. Without [color] the chip is neutral
/// (plain info rather than a colored stat).
class MetricChip extends StatelessWidget {
  final String label;
  final String value;
  final String? imageUrl;
  final IconData? icon;
  final Color? color;
  final String? semanticLabel;

  const MetricChip({
    super.key,
    required this.label,
    required this.value,
    this.imageUrl,
    this.icon,
    this.color,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return CKMetricChip(
      label: label,
      value: value,
      color: color,
      semanticLabel: semanticLabel,
      icon: imageUrl != null
          ? MobileWebImage(imageUrl: imageUrl!)
          : Icon(icon, size: 14, color: color ?? colorScheme.onSurfaceVariant),
    );
  }
}

/// Lays out chips N per row (default 2) at equal width, a short last row
/// sharing the same width split — keeps a variable-length chip list (e.g.
/// clan stats, some conditional) from wrapping into a ragged, unpredictable
/// number of lines. Same grid language as the player header's quick stats.
class MetricChipGrid extends StatelessWidget {
  final List<Widget> chips;
  final double spacing;
  final int columns;

  const MetricChipGrid({
    super.key,
    required this.chips,
    this.spacing = 6,
    this.columns = 2,
  });

  @override
  Widget build(BuildContext context) {
    return CKMetricChipGrid(chips: chips, spacing: spacing, columns: columns);
  }
}

/// Small glass card — the same floating-tile recipe used for the
/// player header's league summary and clan-role chip, now shared so
/// other hero headers (e.g. the clan header) can build their own
/// featured tiles instead of hand-rolling the glass/tint/tap chrome.
class GlassPanel extends StatelessWidget {
  final Widget child;
  final double? width;
  final double height;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? tint;
  final double? borderOpacity;
  final double? shadowOpacity;

  const GlassPanel({
    super.key,
    required this.child,
    this.width,
    required this.height,
    required this.borderRadius,
    required this.padding,
    this.onTap,
    this.tint,
    this.borderOpacity,
    this.shadowOpacity,
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
              child: LiquidGlassBar(
                height: height,
                cornerRadius: borderRadius,
                opacity: 0.72,
                interactive: onTap != null,
                borderOpacity:
                    borderOpacity ??
                    (Theme.of(context).brightness == Brightness.dark
                        ? 0.22
                        : 0.32),
                shadowOpacity:
                    shadowOpacity ??
                    (Theme.of(context).brightness == Brightness.dark
                        ? 0.24
                        : 0.08),
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

/// Samples a remote badge/icon image and picks a dominant, reasonably
/// saturated color from it — used to tint a [GlassPanel] so a featured
/// tile (league badge, war league badge, ...) picks up that badge's
/// color instead of staying neutral.
Future<Color?> dominantTintFromImage(ui.Image image) async {
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

/// Tinted metric bar, same language as the home to-do card metrics:
/// colored pill with an icon in a circle, small label above a bold
/// colored value.
class MetricBar extends StatelessWidget {
  final String label;
  final String? value;
  final Widget? valueWidget;
  final String? imageUrl;
  final IconData? icon;
  final Color color;
  final VoidCallback? onTap;

  const MetricBar({
    super.key,
    required this.label,
    this.value,
    this.valueWidget,
    required this.color,
    this.imageUrl,
    this.icon,
    this.onTap,
  }) : assert(value != null || valueWidget != null);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      height: 40,
      child: Material(
        color: color.withValues(alpha: isDark ? 0.26 : 0.34),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: colorScheme.surface.withValues(alpha: 0.72),
                    shape: BoxShape.circle,
                  ),
                  child: SizedBox.square(
                    dimension: 29,
                    child: Padding(
                      padding: const EdgeInsets.all(5),
                      child: imageUrl != null
                          ? MobileWebImage(imageUrl: imageUrl!)
                          : Icon(icon, size: 16, color: color),
                    ),
                  ),
                ),
                const SizedBox(width: 7),
                // Stacked label/value so neither fights the other for
                // horizontal space — labels don't get truncated.
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
                      valueWidget ??
                          Text(
                            value!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
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
                    size: 16,
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

/// Full-width league summary card — icon, league name, big trophy count,
/// season label and a secondary attack/defense or best-trophies row.
/// Tint is sampled from the league badge image so the glass panel picks
/// up that league's color. Originally the player header's hero league
/// tile; shared so other headers (e.g. the clan header) can reuse it.
/// Samples a dominant tint color from a league badge image and hands it
/// to [builder] once resolved (null until then/on failure). Shared by
/// [LeagueSummaryTile] and [CompactLeagueTile] so both stay in sync with
/// a single cache instead of duplicating the async image-sampling logic.
class LeagueTint extends StatefulWidget {
  final String leagueUrl;
  final Widget Function(BuildContext context, Color? tint) builder;

  const LeagueTint({super.key, required this.leagueUrl, required this.builder});

  @override
  State<LeagueTint> createState() => _LeagueTintState();
}

class _LeagueTintState extends State<LeagueTint> {
  static final Map<String, Color> _tintCache = {};
  Color? _tint;

  @override
  void initState() {
    super.initState();
    _loadTint();
  }

  @override
  void didUpdateWidget(covariant LeagueTint oldWidget) {
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
      final tint = await dominantTintFromImage(imageInfo.image);
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
  Widget build(BuildContext context) => widget.builder(context, _tint);
}

class LeagueSummaryTile extends StatelessWidget {
  final String leagueName;
  final String trophies;
  final String leagueUrl;
  final String seasonName;
  final String? attackWins;
  final String? defenseWins;
  final String? bestTrophies;
  final VoidCallback? onTap;

  const LeagueSummaryTile({
    super.key,
    required this.leagueName,
    required this.trophies,
    required this.leagueUrl,
    required this.seasonName,
    this.attackWins,
    this.defenseWins,
    this.bestTrophies,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return LeagueTint(
      leagueUrl: leagueUrl,
      builder: (context, tint) => GlassPanel(
        width: double.infinity,
        height: 75,
        borderRadius: 16,
        padding: const EdgeInsets.all(12),
        tint: tint,
        onTap: onTap,
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
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    trophies,
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
                      seasonName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.72),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (onTap != null) ...[
                      const SizedBox(width: 2),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 18,
                        color: colorScheme.onSurface.withValues(alpha: 0.58),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                if (attackWins != null && defenseWins != null)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _MiniMetric(
                        stat: _MetricSubStat(
                          imageUrl: ImageAssets.sword,
                          value: attackWins!,
                        ),
                      ),
                      const SizedBox(width: 10),
                      _MiniMetric(
                        stat: _MetricSubStat(
                          imageUrl: ImageAssets.shield,
                          value: defenseWins!,
                        ),
                      ),
                    ],
                  )
                else if (bestTrophies != null)
                  _MiniMetric(
                    stat: _MetricSubStat(
                      imageUrl: ImageAssets.bestTrophies,
                      value: bestTrophies!,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Compact league chip — icon, league name, and a short subtitle (e.g.
/// "CWL" or a point count), with an optional chevron. Two of these sit
/// side by side in headers (e.g. clan) that don't have room for the
/// full-size [LeagueSummaryTile].
class CompactLeagueTile extends StatelessWidget {
  final String leagueName;
  final String subtitle;
  final String? subtitleIconUrl;
  final String leagueUrl;
  final VoidCallback? onTap;

  const CompactLeagueTile({
    super.key,
    required this.leagueName,
    required this.subtitle,
    this.subtitleIconUrl,
    required this.leagueUrl,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final content = Container(
      width: double.infinity,
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.58),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          MobileWebImage(imageUrl: leagueUrl, width: 34, height: 34),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  leagueName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (subtitleIconUrl != null) ...[
                      MobileWebImage(
                        imageUrl: subtitleIconUrl!,
                        width: 14,
                        height: 14,
                      ),
                      const SizedBox(width: 3),
                    ],
                    Flexible(
                      child: Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (onTap != null) ...[
            const SizedBox(width: 4),
            Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: colorScheme.onSurfaceVariant,
            ),
          ],
        ],
      ),
    );

    if (onTap == null) return content;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: content,
      ),
    );
  }
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
