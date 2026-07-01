import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:liquid_glass_easy/liquid_glass_easy.dart' as lge;
import 'package:native_liquid_glass/native_liquid_glass.dart' as glass;

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

        if (_supportsNativeLiquidGlass) {
          return glass.LiquidGlassContainer(
            height: height,
            config: glass.LiquidGlassConfig(
              effect: selected
                  ? glass.LiquidGlassEffect.regular
                  : glass.LiquidGlassEffect.clear,
              shape: cornerRadius >= resolvedHeight / 2
                  ? glass.LiquidGlassEffectShape.capsule
                  : glass.LiquidGlassEffectShape.rect,
              cornerRadius: cornerRadius,
              tint: colorScheme.surface.withValues(alpha: opacity * 0.7),
              backgroundColor: colorScheme.surface.withValues(
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

        return _FallbackLiquidGlassBar(
          cornerRadius: cornerRadius,
          opacity: opacity,
          borderOpacity: effectiveBorderOpacity,
          shadowOpacity: effectiveShadowOpacity,
          selected: selected,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveBorderOpacity = borderOpacity ?? (isDark ? 0.22 : 0.34);
    final effectiveShadowOpacity = shadowOpacity ?? (isDark ? 0.5 : 0.18);

    if (_supportsNativeLiquidGlass &&
        items != null &&
        items!.length == itemCount &&
        selectedIndex >= 0 &&
        selectedIndex < itemCount &&
        onTabSelected != null) {
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

    return _FallbackLiquidGlassTabBar(
      height: height,
      itemCount: itemCount,
      selectedIndex: selectedIndex,
      cornerRadius: cornerRadius,
      selectedCornerRadius: selectedCornerRadius,
      inset: inset,
      borderOpacity: effectiveBorderOpacity,
      shadowOpacity: effectiveShadowOpacity,
    );
  }
}

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
    final iconColor =
        tint ?? (selected ? colorScheme.primary : colorScheme.onSurface);

    if (_supportsNativeLiquidGlass) {
      return glass.LiquidGlassButton.icon(
        size: size,
        iconSize: 30,
        icon: glass.NativeLiquidGlassIcon.iconData(icon),
        iconColor: iconColor,
        tint: colorScheme.surface.withValues(alpha: selected ? 0.72 : 0.58),
        onPressed: onPressed,
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        NativeLiquidGlassBar(
          height: size,
          cornerRadius: size / 2,
          interactive: true,
          selected: selected,
          borderOpacity: selected ? 0.44 : null,
        ),
        Material(
          color: Colors.transparent,
          child: Theme(
            data: Theme.of(context).copyWith(
              splashFactory: NoSplash.splashFactory,
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
            ),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onPressed,
              child: Icon(icon, size: 30, color: iconColor),
            ),
          ),
        ),
      ],
    );
  }
}

class NativeLiquidGlassSegmentedControl<T> extends StatelessWidget {
  const NativeLiquidGlassSegmentedControl({
    super.key,
    required this.values,
    required this.labels,
    required this.selected,
    required this.onChanged,
    this.height = 52,
    this.color,
    // Kept for API compat but no longer used — the built-in glass fallback
    // is shown on non-iOS instead.
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
    final resolvedColor = color ?? Theme.of(context).colorScheme.primary;

    if (_supportsNativeLiquidGlass && selectedIndex >= 0) {
      return glass.LiquidGlassSegmentedControl(
        labels: labels,
        selectedIndex: selectedIndex,
        height: height,
        color: resolvedColor,
        onValueChanged: (index) => onChanged(values[index]),
      );
    }

    if (selectedIndex >= 0) {
      return _FallbackLiquidGlassSegmentedControl(
        labels: labels,
        selectedIndex: selectedIndex,
        height: height,
        color: resolvedColor,
        onValueChanged: (index) => onChanged(values[index]),
      );
    }

    return fallbackBuilder?.call(context) ?? const SizedBox.shrink();
  }
}

class _FallbackLiquidGlassBar extends StatelessWidget {
  const _FallbackLiquidGlassBar({
    required this.cornerRadius,
    required this.opacity,
    required this.borderOpacity,
    required this.shadowOpacity,
    required this.selected,
  });

  final double cornerRadius;
  final double opacity;
  final double borderOpacity;
  final double shadowOpacity;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    // Match the cards' background so the glass bars read as the same
    // material family as the rest of the UI.
    final surfaceColor =
        theme.cardTheme.color ?? theme.colorScheme.surfaceContainer;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(cornerRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: shadowOpacity),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: lge.LiquidGlassLens(
        style: lge.LiquidGlassStyle(
          shape: lge.LiquidGlassShape.continuousRoundedRectangle(
            cornerRadius: cornerRadius,
            lightDirection: 90,
            lightIntensity: isDark ? 0.08 : 0.22,
            lightColor: Colors.white.withValues(alpha: isDark ? 0.14 : 0.30),
            borderType: const lge.OpticalBorder(ambientIntensity: 0.10),
          ),
          appearance: lge.LiquidGlassAppearance(
            color: surfaceColor.withValues(
              alpha: opacity * (selected ? 0.55 : 0.42),
            ),
            blur: const lge.LiquidGlassBlur(sigmaX: 4, sigmaY: 4),
          ),
          refraction: const lge.LiquidGlassRefraction(
            distortion: 0.08,
            distortionWidth: 32,
            chromaticAberration: 0.002,
          ),
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _FallbackLiquidGlassTabBar extends StatelessWidget {
  const _FallbackLiquidGlassTabBar({
    required this.height,
    required this.itemCount,
    required this.selectedIndex,
    required this.cornerRadius,
    required this.selectedCornerRadius,
    required this.inset,
    required this.borderOpacity,
    required this.shadowOpacity,
  });

  final double height;
  final int itemCount;
  final int selectedIndex;
  final double cornerRadius;
  final double selectedCornerRadius;
  final double inset;
  final double borderOpacity;
  final double shadowOpacity;

  @override
  Widget build(BuildContext context) {
    final selectedVisible = selectedIndex >= 0 && selectedIndex < itemCount;

    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = constraints.maxWidth / itemCount;
        return Stack(
          fit: StackFit.expand,
          children: [
            NativeLiquidGlassBar(
              height: height,
              cornerRadius: cornerRadius,
              opacity: 1,
              borderOpacity: borderOpacity,
              shadowOpacity: shadowOpacity,
              selected: false,
            ),
            if (selectedVisible)
              AnimatedPositioned(
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutCubic,
                left: itemWidth * selectedIndex + inset,
                top: inset,
                width: itemWidth - inset * 2,
                height: height - inset * 2,
                child: Builder(
                  builder: (context) {
                    final cs = Theme.of(context).colorScheme;
                    final isDark =
                        Theme.of(context).brightness == Brightness.dark;
                    return DecoratedBox(
                      decoration: BoxDecoration(
                        // Neutral overlay like the iOS glass pill — the
                        // theme's surfaceContainer tints read too warm here.
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.14)
                            : cs.surfaceContainerHigh.withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(selectedCornerRadius),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(
                              alpha: isDark ? 0.20 : 0.07,
                            ),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Glass-style segmented control for non-iOS platforms. Mirrors the layout of
/// [glass.LiquidGlassSegmentedControl]: frosted glass background + animated
/// bright pill for the selected item + colored label.
class _FallbackLiquidGlassSegmentedControl extends StatelessWidget {
  const _FallbackLiquidGlassSegmentedControl({
    required this.labels,
    required this.selectedIndex,
    required this.onValueChanged,
    required this.height,
    required this.color,
  });

  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onValueChanged;
  final double height;
  final Color color;

  static const double _inset = 5.0;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pillRadius = (height - _inset * 2) / 2;

    return SizedBox(
      height: height,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final itemWidth = constraints.maxWidth / labels.length;
          return Stack(
            fit: StackFit.expand,
            children: [
              // Frosted glass background
              NativeLiquidGlassBar(
                height: height,
                cornerRadius: height / 2,
                opacity: 1.0,
              ),
              // Animated selected pill
              AnimatedPositioned(
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutCubic,
                left: itemWidth * selectedIndex + _inset,
                top: _inset,
                width: itemWidth - _inset * 2,
                height: height - _inset * 2,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.14)
                        : colorScheme.surfaceContainerHigh
                            .withValues(alpha: 0.90),
                    borderRadius: BorderRadius.circular(pillRadius),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: isDark ? 0.18 : 0.06,
                        ),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
              // Tap targets + labels
              Row(
                children: List.generate(labels.length, (i) {
                  final isSelected = i == selectedIndex;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => onValueChanged(i),
                      behavior: HitTestBehavior.opaque,
                      child: Center(
                        child: Text(
                          labels[i],
                          style:
                              Theme.of(context).textTheme.labelLarge?.copyWith(
                                    color: isSelected
                                        ? color
                                        : colorScheme.onSurfaceVariant,
                                    fontWeight: isSelected
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                  ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          );
        },
      ),
    );
  }
}

bool get supportsNativeLiquidGlass =>
    !kIsWeb && glass.NativeLiquidGlassUtils.supportsLiquidGlass;

bool get _supportsNativeLiquidGlass => supportsNativeLiquidGlass;
