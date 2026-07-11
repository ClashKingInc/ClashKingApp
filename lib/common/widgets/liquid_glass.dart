import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart' as lgw;

/// UIKit platform-view glass is intentionally avoided. Keeping every surface
/// in Flutter's compositor avoids platform-view tearing during iOS navigation
/// and gives every supported platform the same rendering behavior.
/// Shared floating glass surface — used as a background for buttons, search
/// fields, header panels and tab bars.
class LiquidGlassBar extends StatelessWidget {
  const LiquidGlassBar({
    super.key,
    required this.height,
    this.cornerRadius = 28,
    this.opacity = 0.74,
    this.borderOpacity,
    this.shadowOpacity,
    this.interactive = false,
    this.selected = false,
  });

  final double height;
  final double cornerRadius;
  final double opacity;
  final double? borderOpacity;
  final double? shadowOpacity;
  final bool interactive;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final colorScheme = Theme.of(context).colorScheme;
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final effectiveBorderOpacity = borderOpacity ?? (isDark ? 0.22 : 0.34);
        final effectiveShadowOpacity = shadowOpacity ?? (isDark ? 0.35 : 0.16);
        final resolvedHeight =
            constraints.hasBoundedHeight && constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : height;
        final resolvedWidth =
            constraints.hasBoundedWidth && constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : null;

        // Use a stable theme tint so glass remains legible over mixed content.
        final glassTint = isDark
            ? colorScheme.surface
            : colorScheme.surfaceContainerHighest;

        return DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(cornerRadius),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: effectiveShadowOpacity),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: SizedBox(
            width: resolvedWidth,
            height: resolvedHeight,
            child: Stack(
              fit: StackFit.expand,
              children: [
                lgw.GlassContainer(
                  useOwnLayer: true,
                  shape: lgw.LiquidRoundedSuperellipse(
                    borderRadius: cornerRadius,
                  ),
                  settings: lgw.LiquidGlassSettings(
                    glassColor: glassTint.withValues(
                      alpha: opacity * (selected ? 0.6 : 0.46),
                    ),
                    blur: 6,
                    thickness: 16,
                    chromaticAberration: 0.002,
                    lightIntensity: 0.16,
                    saturation: 1.05,
                    glowIntensity: 0.10,
                    shadowElevation: 0.35,
                  ),
                ),
                IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(cornerRadius),
                      border: Border.all(
                        color: colorScheme.outlineVariant.withValues(
                          alpha: selected
                              ? effectiveBorderOpacity.clamp(0.42, 1.0)
                              : effectiveBorderOpacity,
                        ),
                        width: 0.8,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class LiquidGlassTabItem {
  const LiquidGlassTabItem({
    required this.icon,
    required this.label,
    this.selectedIcon,
    this.selectedItemColor,
  });

  final IconData icon;
  final IconData? selectedIcon;
  final String label;
  final Color? selectedItemColor;
}

/// Flutter-composited floating bottom tab bar for every platform.
class LiquidGlassTabBar extends StatelessWidget {
  const LiquidGlassTabBar({
    super.key,
    required this.height,
    required this.itemCount,
    required this.selectedIndex,
    this.onTabSelected,
    this.items,
    this.actionButton,
    this.onActionButtonPressed,
    this.cornerRadius = 28,
    this.selectedCornerRadius = 20,
    this.inset = 7,
    this.borderOpacity,
    this.shadowOpacity,
    this.iconSize = 22,
  });

  final double height;
  final int itemCount;
  final int selectedIndex;
  final ValueChanged<int>? onTabSelected;
  final List<LiquidGlassTabItem>? items;
  final LiquidGlassTabItem? actionButton;
  final VoidCallback? onActionButtonPressed;
  final double cornerRadius;
  final double selectedCornerRadius;
  final double inset;
  final double? borderOpacity;
  final double? shadowOpacity;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    if (items == null ||
        items!.length != itemCount ||
        selectedIndex < 0 ||
        selectedIndex >= itemCount ||
        onTabSelected == null) {
      return const SizedBox.shrink();
    }

    return lgw.GlassTabBar.bottom(
      tabs: items!
          .map(
            (item) => lgw.GlassTab(
              icon: Icon(item.icon),
              activeIcon: Icon(item.selectedIcon ?? item.icon),
              label: item.label,
            ),
          )
          .toList(growable: false),
      selectedIndex: selectedIndex,
      onTabSelected: onTabSelected!,
      barHeight: height,
      selectedIconColor: items![selectedIndex].selectedItemColor,
      selectedLabelColor: items![selectedIndex].selectedItemColor,
      iconSize: iconSize,
      settings: lgw.LiquidGlassSettings(
        glassColor: (isDark ? const Color(0xFF080809) : Colors.white)
            .withValues(alpha: isDark ? 0.72 : 0.56),
        blur: 7,
        thickness: 16,
        chromaticAberration: 0.002,
        lightIntensity: 0.14,
        saturation: 1.0,
        glowIntensity: 0.08,
        shadowElevation: 0.4,
      ),
      indicatorColor:
          (isDark ? colorScheme.surfaceContainerHighest : colorScheme.surface)
              .withValues(alpha: isDark ? 0.72 : 0.68),
      unselectedIconColor: colorScheme.onSurface.withValues(alpha: 0.82),
      unselectedLabelColor: colorScheme.onSurface.withValues(alpha: 0.82),
      glowOpacity: 0.14,
    );
  }
}

/// Frosted round/pill icon button.
class LiquidGlassIconButton extends StatelessWidget {
  const LiquidGlassIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.size = 62,
    this.tint,
    this.selected = false,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final double size;
  final Color? tint;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconColor =
        tint ?? (selected ? colorScheme.primary : colorScheme.onSurface);

    final glassTint = isDark
        ? colorScheme.surface
        : colorScheme.surfaceContainerHighest;

    return lgw.GlassIconButton(
      icon: Icon(icon, color: iconColor),
      onPressed: onPressed,
      size: size,
      iconSize: size * 0.48,
      useOwnLayer: true,
      settings: lgw.LiquidGlassSettings(
        glassColor: glassTint.withValues(alpha: selected ? 0.5 : 0.38),
        blur: 6,
        thickness: 16,
      ),
    );
  }
}

/// Glass-style segmented control — filter/mode toggles throughout the app.
class LiquidGlassSegmentedControl<T> extends StatelessWidget {
  const LiquidGlassSegmentedControl({
    super.key,
    required this.values,
    required this.labels,
    required this.selected,
    required this.onChanged,
    this.height = 52,
    this.color,
    // Kept for API compat — used only when fewer than 2 valid segments are
    // resolved (both backends require at least 2).
    this.fallbackBuilder,
  }) : assert(values.length == labels.length);

  final List<T> values;
  final List<String> labels;
  final T selected;
  final ValueChanged<T> onChanged;
  final double height;
  final Color? color;
  final WidgetBuilder? fallbackBuilder;

  @override
  Widget build(BuildContext context) {
    final selectedIndex = values.indexOf(selected);
    if (selectedIndex < 0 || labels.length < 2) {
      return fallbackBuilder?.call(context) ?? const SizedBox.shrink();
    }

    final resolvedColor = color ?? Theme.of(context).colorScheme.primary;

    return _FallbackSegmentedControl<T>(
      values: values,
      labels: labels,
      selectedIndex: selectedIndex,
      onChanged: onChanged,
      height: height,
      selectedColor: resolvedColor,
    );
  }
}

class _FallbackSegmentedControl<T> extends StatelessWidget {
  const _FallbackSegmentedControl({
    required this.values,
    required this.labels,
    required this.selectedIndex,
    required this.onChanged,
    required this.height,
    required this.selectedColor,
  });

  final List<T> values;
  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<T> onChanged;
  final double height;
  final Color selectedColor;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final radius = BorderRadius.circular(height / 2);
    final disableAnimations = MediaQuery.disableAnimationsOf(context);
    final indicatorDuration = disableAnimations
        ? Duration.zero
        : const Duration(milliseconds: 220);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: isDark
            ? Colors.black.withValues(alpha: 0.90)
            : colorScheme.surface.withValues(alpha: 0.94),
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.22 : 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SizedBox(
        height: height,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final segmentWidth = constraints.maxWidth / labels.length;
            final inset = 5.0;
            return Stack(
              children: [
                AnimatedPositioned(
                  duration: indicatorDuration,
                  curve: Curves.easeOutCubic,
                  left: selectedIndex * segmentWidth + inset,
                  top: inset,
                  bottom: inset,
                  width: segmentWidth - inset * 2,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest.withValues(
                        alpha: 0.58,
                      ),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                Row(
                  children: [
                    for (var index = 0; index < labels.length; index++)
                      Expanded(
                        child: _GlassSegmentButton(
                          label: labels[index],
                          selected: index == selectedIndex,
                          selectedColor: selectedColor,
                          onTap: () => onChanged(values[index]),
                        ),
                      ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _GlassSegmentButton extends StatelessWidget {
  const _GlassSegmentButton({
    required this.label,
    required this.selected,
    required this.selectedColor,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color selectedColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Semantics(
      button: true,
      selected: selected,
      child: Padding(
        padding: const EdgeInsets.all(5),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          child: InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: onTap,
            child: Center(
              child: AnimatedDefaultTextStyle(
                duration: MediaQuery.disableAnimationsOf(context)
                    ? Duration.zero
                    : const Duration(milliseconds: 160),
                curve: Curves.easeOutCubic,
                style:
                    Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: selected
                          ? selectedColor
                          : colorScheme.onSurface.withValues(alpha: 0.76),
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                      height: 1,
                    ) ??
                    TextStyle(
                      color: selected
                          ? selectedColor
                          : colorScheme.onSurface.withValues(alpha: 0.76),
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                      height: 1,
                    ),
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Whether glass surfaces should render at all. Header panels inside slivers
/// rely on this flag to fall back to an opaque fill — see
/// [HeaderPanelBackground] in header_widgets.dart for the
/// backdrop-sampling-in-slivers rationale.
bool get supportsLiquidGlass => !kIsWeb;
