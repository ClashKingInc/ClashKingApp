import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart' as lgw;
import 'package:native_liquid_glass/native_liquid_glass.dart' as glass;

/// iOS keeps Apple's real system Liquid Glass (`native_liquid_glass`, a true
/// `UIVisualEffectView`-backed platform view). Every other platform renders
/// via `liquid_glass_widgets` (shader-based — Impeller/Vulkan on Android,
/// lightweight shader on web/desktop) since there is no equivalent system
/// material to call into there.
bool get _isIOS => !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

/// Shared floating glass surface — used as a background for buttons, search
/// fields, header panels and tab bars.
class NativeLiquidGlassBar extends StatelessWidget {
  const NativeLiquidGlassBar({
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

        // In light mode, colorScheme.surface is near-white — tinting the
        // glass with it against typically-light page content leaves no
        // visible glass definition (reads as flat gray/blurry instead).
        // surfaceContainerHighest carries enough tone to stay visible
        // while dark mode keeps the original near-black surface tint.
        final glassTint = isDark
            ? colorScheme.surface
            : colorScheme.surfaceContainerHighest;

        if (_isIOS) {
          return glass.LiquidGlassContainer(
            height: resolvedHeight,
            config: glass.LiquidGlassConfig(
              // Always .clear ("less visual weight" per the plugin docs),
              // even when selected — selected state is already conveyed
              // by the stronger tint/border below.
              effect: glass.LiquidGlassEffect.clear,
              shape: cornerRadius >= resolvedHeight / 2
                  ? glass.LiquidGlassEffectShape.capsule
                  : glass.LiquidGlassEffectShape.rect,
              cornerRadius: cornerRadius,
              tint: glassTint.withValues(alpha: opacity * 0.7),
              backgroundColor: glassTint.withValues(
                alpha: selected ? 0.34 : 0.22,
              ),
              interactive: interactive,
              border: glass.LiquidGlassBorder(
                color: colorScheme.outlineVariant.withValues(
                  alpha: selected
                      ? effectiveBorderOpacity.clamp(0.42, 1.0)
                      : effectiveBorderOpacity,
                ),
                width: 0.8,
              ),
            ),
            child: const SizedBox.expand(),
          );
        }

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

class NativeLiquidGlassTabItem {
  const NativeLiquidGlassTabItem({
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

/// Floating bottom tab bar. iOS uses Apple's real native tab bar; other
/// platforms use `liquid_glass_widgets`' `GlassTabBar.bottom` — note that
/// widget wants to sit directly as `Scaffold.bottomNavigationBar` for
/// correct safe-area/floating-margin behavior, so most call sites (e.g. the
/// app's bottom navigation in `my_home_page.dart`) call `GlassTabBar.bottom`
/// directly for non-iOS rather than through this wrapper.
class NativeLiquidGlassTabBar extends StatelessWidget {
  const NativeLiquidGlassTabBar({
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
  final List<NativeLiquidGlassTabItem>? items;
  final NativeLiquidGlassTabItem? actionButton;
  final VoidCallback? onActionButtonPressed;
  final double cornerRadius;
  final double selectedCornerRadius;
  final double inset;
  final double? borderOpacity;
  final double? shadowOpacity;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (items == null ||
        items!.length != itemCount ||
        selectedIndex < 0 ||
        selectedIndex >= itemCount ||
        onTabSelected == null) {
      return const SizedBox.shrink();
    }

    if (_isIOS) {
      return glass.LiquidGlassTabBar(
        height: height,
        currentIndex: selectedIndex,
        onTabSelected: onTabSelected!,
        onActionButtonPressed: onActionButtonPressed,
        iosActionButton: actionButton == null
            ? null
            : glass.LiquidGlassTabItem(
                label: actionButton!.label,
                icon: glass.NativeLiquidGlassIcon.iconData(actionButton!.icon),
                selectedIcon: glass.NativeLiquidGlassIcon.iconData(
                  actionButton!.selectedIcon ?? actionButton!.icon,
                ),
                selectedItemColor:
                    actionButton!.selectedItemColor ?? colorScheme.primary,
              ),
        items: items!
            .map(
              (item) => glass.LiquidGlassTabItem(
                label: item.label,
                icon: glass.NativeLiquidGlassIcon.iconData(item.icon),
                selectedIcon: glass.NativeLiquidGlassIcon.iconData(
                  item.selectedIcon ?? item.icon,
                ),
                selectedItemColor:
                    item.selectedItemColor ?? colorScheme.primary,
              ),
            )
            .toList(growable: false),
        selectedItemColor: colorScheme.primary,
        iosItemPositioning: glass.LiquidGlassTabBarItemPositioning.fill,
        iconSize: iconSize,
        labelTextStyle: Theme.of(context).textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w600,
          height: 1.0,
        ),
      );
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
    );
  }
}

/// Frosted round/pill icon button.
class NativeLiquidGlassIconButton extends StatelessWidget {
  const NativeLiquidGlassIconButton({
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

    if (_isIOS) {
      return glass.LiquidGlassButton.icon(
        size: size,
        iconSize: 30,
        icon: glass.NativeLiquidGlassIcon.iconData(icon),
        iconColor: iconColor,
        tint: colorScheme.surface.withValues(alpha: selected ? 0.72 : 0.58),
        onPressed: onPressed,
      );
    }

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
class NativeLiquidGlassSegmentedControl<T> extends StatelessWidget {
  const NativeLiquidGlassSegmentedControl({
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

    if (_isIOS) {
      return glass.LiquidGlassSegmentedControl(
        labels: labels,
        selectedIndex: selectedIndex,
        height: height,
        color: resolvedColor,
        onValueChanged: (index) => onChanged(values[index]),
      );
    }

    return _AndroidSegmentedControl<T>(
      values: values,
      labels: labels,
      selectedIndex: selectedIndex,
      onChanged: onChanged,
      height: height,
      selectedColor: resolvedColor,
    );
  }
}

class _AndroidSegmentedControl<T> extends StatelessWidget {
  const _AndroidSegmentedControl({
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
                        child: _AndroidSegmentButton(
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

class _AndroidSegmentButton extends StatelessWidget {
  const _AndroidSegmentButton({
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
bool get supportsNativeLiquidGlass => !kIsWeb;

/// Whether the current platform renders Apple's real native Liquid Glass
/// (vs. the shader-based `liquid_glass_widgets` used elsewhere). Exposed so
/// call sites with platform-specific layout needs (e.g. the app's bottom
/// navigation bar) can branch without duplicating the platform check.
bool get usesNativeGlassPlatform => _isIOS;
