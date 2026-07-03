import 'package:clashkingapp/common/widgets/mobile_web_image.dart';
import 'package:clashkingapp/common/widgets/native_liquid_glass.dart';
import 'package:flutter/material.dart';

/// Frosted round icon button floating over a hero header image — same
/// native Liquid Glass recipe as the player header's button, so every
/// hero-header screen shares one real glass button implementation.
class HeaderIconButton extends StatelessWidget {
  final IconData? icon;
  final String? imageUrl;
  final String tooltip;
  final VoidCallback onTap;

  const HeaderIconButton({
    super.key,
    this.icon,
    this.imageUrl,
    required this.tooltip,
    required this.onTap,
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
              Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(radius),
                child: InkWell(
                  borderRadius: BorderRadius.circular(radius),
                  splashFactory: NoSplash.splashFactory,
                  splashColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                  onTap: onTap,
                  child: SizedBox(
                    height: size,
                    width: size,
                    child: imageUrl != null
                        ? Padding(
                            padding: const EdgeInsets.all(8),
                            child: MobileWebImage(imageUrl: imageUrl!),
                          )
                        : Icon(icon, size: 25),
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

/// Background for hero-header panels. iOS gets the native glass; Android
/// gets a near-opaque card fill instead of the shader glass — inside
/// slivers the page body can paint before the header, and a
/// backdrop-sampling shader would wash the content below with its fill.
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
    if (supportsNativeLiquidGlass) {
      return NativeLiquidGlassBar(
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

  const MetricChip({
    super.key,
    required this.label,
    required this.value,
    this.imageUrl,
    this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(6, 5, 10, 5),
      decoration: BoxDecoration(
        color: color != null
            ? color!.withValues(alpha: 0.14)
            : colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: colorScheme.surface.withValues(alpha: 0.72),
              shape: BoxShape.circle,
            ),
            child: SizedBox.square(
              dimension: 26,
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: imageUrl != null
                    ? MobileWebImage(imageUrl: imageUrl!)
                    : Icon(
                        icon,
                        size: 14,
                        color: color ?? colorScheme.onSurfaceVariant,
                      ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Column(
              mainAxisSize: MainAxisSize.min,
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
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: color ?? colorScheme.onSurface,
                    fontWeight: FontWeight.w900,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
    if (chips.isEmpty) return const SizedBox.shrink();

    final rows = <Widget>[];
    for (var i = 0; i < chips.length; i += columns) {
      if (i > 0) rows.add(SizedBox(height: spacing));
      final rowChips = chips.skip(i).take(columns).toList();
      final rowChildren = <Widget>[];
      for (var j = 0; j < rowChips.length; j++) {
        if (j > 0) rowChildren.add(SizedBox(width: spacing));
        rowChildren.add(Expanded(child: rowChips[j]));
      }
      rows.add(Row(children: rowChildren));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: rows,
    );
  }
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

    return SizedBox(
      height: 40,
      child: Material(
        color: color.withValues(alpha: 0.16),
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
