import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
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

        // Keep light glass bright rather than tinting every floating control
        // gray. Its outline and shadow provide definition against the page.
        final glassTint = colorScheme.surface;

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

        // The shader's backdrop layer can escape its clip on mobile browsers
        // and blur the entire route below the app header.
        if (kIsWeb) {
          return DecoratedBox(
            decoration: BoxDecoration(
              color: glassTint.withValues(alpha: isDark ? 0.94 : 0.90),
              borderRadius: BorderRadius.circular(cornerRadius),
              border: Border.all(
                color: colorScheme.outlineVariant.withValues(
                  alpha: selected
                      ? effectiveBorderOpacity.clamp(0.42, 1.0)
                      : effectiveBorderOpacity,
                ),
                width: 0.8,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: effectiveShadowOpacity),
                  blurRadius: 12,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: SizedBox(width: resolvedWidth, height: resolvedHeight),
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

/// Thin, cross-platform segmented control styled after the native iOS 26
/// `UISegmentedControl`.
///
/// Its material follows the quieter painted treatment from
/// `CKSegmentedControl`, while this wrapper supplies the native proportions and
/// a continuous, critically damped slide. Keeping shader glass out of this
/// control avoids the bright rims and lensing that overpower small capsules.
class AppGlassSegmentedControl<T> extends StatefulWidget {
  const AppGlassSegmentedControl({
    super.key,
    required this.values,
    required this.labels,
    required this.selected,
    required this.onChanged,
    this.height = 52,
    this.foregroundColor,
  }) : assert(values.length == labels.length);

  final List<T> values;
  final List<String> labels;
  final T selected;
  final ValueChanged<T> onChanged;
  final double height;
  final Color? foregroundColor;

  @override
  State<AppGlassSegmentedControl<T>> createState() =>
      _AppGlassSegmentedControlState<T>();
}

class _AppGlassSegmentedControlState<T>
    extends State<AppGlassSegmentedControl<T>>
    with SingleTickerProviderStateMixin {
  static const _spring = SpringDescription(
    mass: 1,
    stiffness: 420,
    damping: 41,
  );
  static const _trackKey = Key('app-glass-segmented-track');
  static const _indicatorKey = Key('app-glass-segmented-indicator');

  late final AnimationController _position;
  late int _lastReportedIndex;
  bool _disableAnimations = false;

  int get _selectedIndex => widget.values.indexOf(widget.selected);

  @override
  void initState() {
    super.initState();
    final initialIndex = _selectedIndex;
    _lastReportedIndex = math.max(0, initialIndex);
    _position = AnimationController.unbounded(
      vsync: this,
      value: math.max(0, initialIndex).toDouble(),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _disableAnimations = MediaQuery.disableAnimationsOf(context);
  }

  @override
  void didUpdateWidget(covariant AppGlassSegmentedControl<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nextIndex = _selectedIndex;
    if (nextIndex < 0) return;

    _lastReportedIndex = nextIndex;
    if ((_position.value - nextIndex).abs() > 0.001) {
      _animateTo(nextIndex);
    }
  }

  @override
  void dispose() {
    _position.dispose();
    super.dispose();
  }

  void _animateTo(int index, {double? velocity}) {
    final target = index.toDouble();
    if (_disableAnimations) {
      _position.value = target;
      return;
    }

    final inheritedVelocity =
        velocity ?? (_position.isAnimating ? _position.velocity : 0.0);
    _position.animateWith(
      SpringSimulation(
        _spring,
        _position.value,
        target,
        inheritedVelocity.clamp(-4.0, 4.0),
        snapToEnd: true,
      ),
    );
  }

  void _selectIndex(int index, {double? velocity}) {
    _animateTo(index, velocity: velocity);
    if (index == _lastReportedIndex) return;
    _lastReportedIndex = index;
    widget.onChanged(widget.values[index]);
  }

  void _handleDragUpdate(
    DragUpdateDetails details,
    double segmentWidth,
    TextDirection direction,
  ) {
    _position.stop();
    final directionalDelta =
        (details.primaryDelta ?? 0) * (direction == TextDirection.ltr ? 1 : -1);
    _position.value = (_position.value + directionalDelta / segmentWidth).clamp(
      0.0,
      widget.values.length - 1.0,
    );
  }

  void _handleDragEnd(
    DragEndDetails details,
    double segmentWidth,
    TextDirection direction,
  ) {
    final directionalVelocity =
        details.velocity.pixelsPerSecond.dx *
        (direction == TextDirection.ltr ? 1 : -1);
    final segmentVelocity = directionalVelocity / segmentWidth;
    final projectedPosition = _position.value + segmentVelocity * 0.08;
    final target = projectedPosition.round().clamp(0, widget.values.length - 1);
    _selectIndex(target, velocity: segmentVelocity);
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _selectedIndex;
    if (selectedIndex < 0 || widget.labels.length < 2) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final onColoredSurface = widget.foregroundColor != null;
    final labelColor = widget.foregroundColor ?? scheme.onSurface;
    const labelStyle = TextStyle(fontSize: 13, fontWeight: FontWeight.w600);
    final desiredWidth = _segmentedControlWidth(
      context,
      widget.labels,
      labelStyle,
    );
    const controlHeight = 32.0;
    final layoutHeight = math.max(widget.height, controlHeight);
    final trackBorderColor = scheme.outlineVariant.withValues(
      alpha: onColoredSurface ? 0.22 : 0.32,
    );
    final trackFill = scheme.surfaceContainerHighest.withValues(
      alpha: onColoredSurface ? 0.38 : 0.45,
    );
    final indicatorFill = scheme.surfaceContainerHighest.withValues(
      alpha: onColoredSurface ? 0.72 : 0.74,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final resolvedWidth = constraints.hasBoundedWidth
            ? constraints.maxWidth
            : desiredWidth + 32;
        final trackWidth = math.max(0.0, resolvedWidth - 32);
        return Align(
          alignment: Alignment.center,
          child: SizedBox(
            width: resolvedWidth,
            height: layoutHeight,
            child: Center(
              child: SizedBox(
                width: trackWidth,
                height: controlHeight,
                child: LayoutBuilder(
                  builder: (context, controlConstraints) {
                    const indicatorInset = 2.0;
                    final direction = Directionality.of(context);
                    final innerWidth =
                        controlConstraints.maxWidth - indicatorInset * 2;
                    final segmentWidth = innerWidth / widget.values.length;
                    final maxIndex = widget.values.length - 1.0;

                    return GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onHorizontalDragStart: (_) => _position.stop(),
                      onHorizontalDragUpdate: (details) =>
                          _handleDragUpdate(details, segmentWidth, direction),
                      onHorizontalDragEnd: (details) =>
                          _handleDragEnd(details, segmentWidth, direction),
                      onHorizontalDragCancel: () => _animateTo(selectedIndex),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Positioned.fill(
                            child: IgnorePointer(
                              child: DecoratedBox(
                                key: _trackKey,
                                decoration: BoxDecoration(
                                  color: trackFill,
                                  borderRadius: BorderRadius.circular(
                                    controlHeight / 2,
                                  ),
                                  border: Border.all(
                                    color: trackBorderColor,
                                    width: 0.8,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            left: indicatorInset,
                            top: indicatorInset,
                            width: segmentWidth,
                            height: controlHeight - indicatorInset * 2,
                            child: AnimatedBuilder(
                              animation: _position,
                              child: IgnorePointer(
                                child: DecoratedBox(
                                  key: _indicatorKey,
                                  decoration: BoxDecoration(
                                    color: indicatorFill,
                                    borderRadius: BorderRadius.circular(
                                      controlHeight / 2,
                                    ),
                                  ),
                                ),
                              ),
                              builder: (context, child) {
                                final logicalPosition = _position.value.clamp(
                                  0.0,
                                  maxIndex,
                                );
                                final physicalPosition =
                                    direction == TextDirection.ltr
                                    ? logicalPosition
                                    : maxIndex - logicalPosition;
                                return Transform.translate(
                                  offset: Offset(
                                    physicalPosition * segmentWidth,
                                    0,
                                  ),
                                  child: child,
                                );
                              },
                            ),
                          ),
                          Positioned.fill(
                            child: Row(
                              children: [
                                for (
                                  var index = 0;
                                  index < widget.labels.length;
                                  index++
                                )
                                  Expanded(
                                    child: Semantics(
                                      button: true,
                                      selected: selectedIndex == index,
                                      label: widget.labels[index],
                                      child: GestureDetector(
                                        behavior: HitTestBehavior.opaque,
                                        onTap: () => _selectIndex(index),
                                        child: Center(
                                          child: AnimatedDefaultTextStyle(
                                            duration: const Duration(
                                              milliseconds: 180,
                                            ),
                                            curve: Curves.easeOutCubic,
                                            style: labelStyle.copyWith(
                                              color: selectedIndex == index
                                                  ? labelColor
                                                  : labelColor.withValues(
                                                      alpha: 0.67,
                                                    ),
                                              fontWeight: selectedIndex == index
                                                  ? FontWeight.w600
                                                  : FontWeight.w500,
                                            ),
                                            child: Text(
                                              widget.labels[index],
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

double _segmentedControlWidth(
  BuildContext context,
  List<String> labels,
  TextStyle style,
) {
  final direction = Directionality.of(context);
  final scaler = MediaQuery.textScalerOf(context);
  var longestLabel = 0.0;
  for (final label in labels) {
    final painter = TextPainter(
      text: TextSpan(text: label, style: style),
      textDirection: direction,
      textScaler: scaler,
      maxLines: 1,
    )..layout();
    longestLabel = math.max(longestLabel, painter.width);
  }

  final segmentWidth = (longestLabel + 40).clamp(112.0, 180.0);
  return segmentWidth * labels.length;
}

/// Whether glass surfaces should render at all. Header panels inside slivers
/// rely on this flag to fall back to an opaque fill — see
/// [HeaderPanelBackground] in header_widgets.dart for the
/// backdrop-sampling-in-slivers rationale.
bool get supportsNativeLiquidGlass => !kIsWeb;

typedef LiquidGlassBar = NativeLiquidGlassBar;
typedef LiquidGlassTabItem = NativeLiquidGlassTabItem;
typedef LiquidGlassTabBar = NativeLiquidGlassTabBar;
typedef LiquidGlassIconButton = NativeLiquidGlassIconButton;

bool get supportsLiquidGlass => supportsNativeLiquidGlass;

/// Whether the current platform renders Apple's real native Liquid Glass
/// (vs. the shader-based `liquid_glass_widgets` used elsewhere). Exposed so
/// call sites with platform-specific layout needs (e.g. the app's bottom
/// navigation bar) can branch without duplicating the platform check.
bool get usesNativeGlassPlatform => _isIOS;
