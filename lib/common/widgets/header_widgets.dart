import 'dart:ui';

import 'package:clashkingapp/common/widgets/mobile_web_image.dart';
import 'package:clashkingapp/common/widgets/native_liquid_glass.dart';
import 'package:flutter/material.dart';

/// Frosted round icon button floating over a hero header image.
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
                child: imageUrl != null
                    ? Padding(
                        padding: const EdgeInsets.all(8),
                        child: MobileWebImage(imageUrl: imageUrl!),
                      )
                    : Icon(icon, size: 25),
              ),
            ),
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
