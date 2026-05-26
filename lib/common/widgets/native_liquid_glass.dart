import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class NativeLiquidGlassBar extends StatefulWidget {
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
  State<NativeLiquidGlassBar> createState() => _NativeLiquidGlassBarState();
}

class _NativeLiquidGlassBarState extends State<NativeLiquidGlassBar> {
  MethodChannel? _channel;

  @override
  void didUpdateWidget(covariant NativeLiquidGlassBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    WidgetsBinding.instance.addPostFrameCallback((_) => _sendUpdate());
  }

  Map<String, Object?> _params() {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveBorderOpacity =
        widget.borderOpacity ?? (isDark ? 0.22 : 0.34);
    final effectiveShadowOpacity =
        widget.shadowOpacity ?? (isDark ? 0.35 : 0.16);

    return {
      'cornerRadius': widget.cornerRadius,
      'opacity': widget.opacity,
      'borderColor': colorScheme.outlineVariant.toARGB32(),
      'borderOpacity': effectiveBorderOpacity,
      'shadowOpacity': effectiveShadowOpacity,
      'isDark': isDark,
      'interactive': widget.interactive,
      'selected': widget.selected,
    };
  }

  void _sendUpdate() {
    if (!mounted || _channel == null) return;
    _channel!.invokeMethod<void>('update', _params());
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveBorderOpacity =
        widget.borderOpacity ?? (isDark ? 0.22 : 0.34);
    final effectiveShadowOpacity =
        widget.shadowOpacity ?? (isDark ? 0.35 : 0.16);

    if (kIsWeb || !Platform.isIOS) {
      return DecoratedBox(
        decoration: BoxDecoration(
          color:
              (widget.selected
                      ? colorScheme.surfaceContainerHighest
                      : colorScheme.surface)
                  .withValues(alpha: widget.opacity),
          borderRadius: BorderRadius.circular(widget.cornerRadius),
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(
              alpha: effectiveBorderOpacity,
            ),
            width: 0.8,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: effectiveShadowOpacity),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
      );
    }

    return IgnorePointer(
      child: UiKitView(
        viewType: 'clashking/liquid_glass_bar',
        creationParams: _params(),
        creationParamsCodec: const StandardMessageCodec(),
        onPlatformViewCreated: (id) {
          _channel = MethodChannel('clashking/liquid_glass_bar_$id');
          _sendUpdate();
        },
      ),
    );
  }
}

class NativeLiquidGlassTabBar extends StatefulWidget {
  const NativeLiquidGlassTabBar({
    super.key,
    required this.height,
    required this.itemCount,
    required this.selectedIndex,
    this.cornerRadius = 28,
    this.selectedCornerRadius = 20,
    this.inset = 7,
    this.borderOpacity,
    this.shadowOpacity,
  });

  final double height;
  final int itemCount;
  final int selectedIndex;
  final double cornerRadius;
  final double selectedCornerRadius;
  final double inset;
  final double? borderOpacity;
  final double? shadowOpacity;

  @override
  State<NativeLiquidGlassTabBar> createState() =>
      _NativeLiquidGlassTabBarState();
}

class _NativeLiquidGlassTabBarState extends State<NativeLiquidGlassTabBar> {
  MethodChannel? _channel;

  @override
  void didUpdateWidget(covariant NativeLiquidGlassTabBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    WidgetsBinding.instance.addPostFrameCallback((_) => _sendUpdate());
  }

  Map<String, Object?> _params() {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveBorderOpacity =
        widget.borderOpacity ?? (isDark ? 0.22 : 0.34);
    final effectiveShadowOpacity =
        widget.shadowOpacity ?? (isDark ? 0.5 : 0.18);

    return {
      'itemCount': widget.itemCount,
      'selectedIndex': widget.selectedIndex,
      'cornerRadius': widget.cornerRadius,
      'selectedCornerRadius': widget.selectedCornerRadius,
      'inset': widget.inset,
      'borderColor': colorScheme.outlineVariant.toARGB32(),
      'borderOpacity': effectiveBorderOpacity,
      'shadowOpacity': effectiveShadowOpacity,
      'isDark': isDark,
    };
  }

  void _sendUpdate() {
    if (!mounted || _channel == null) return;
    _channel!.invokeMethod<void>('update', _params());
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveBorderOpacity =
        widget.borderOpacity ?? (isDark ? 0.22 : 0.34);
    final effectiveShadowOpacity =
        widget.shadowOpacity ?? (isDark ? 0.5 : 0.18);

    if (kIsWeb || !Platform.isIOS) {
      final selectedVisible =
          widget.selectedIndex >= 0 && widget.selectedIndex < widget.itemCount;
      return LayoutBuilder(
        builder: (context, constraints) {
          final itemWidth = constraints.maxWidth / widget.itemCount;
          return Stack(
            fit: StackFit.expand,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: colorScheme.surface.withValues(alpha: 0.74),
                  borderRadius: BorderRadius.circular(widget.cornerRadius),
                  border: Border.all(
                    color: colorScheme.outlineVariant.withValues(
                      alpha: effectiveBorderOpacity,
                    ),
                    width: 0.8,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: effectiveShadowOpacity,
                      ),
                      blurRadius: 24,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
              ),
              if (selectedVisible)
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 260),
                  curve: Curves.easeOutCubic,
                  left: itemWidth * widget.selectedIndex + widget.inset,
                  top: widget.inset,
                  width: itemWidth - widget.inset * 2,
                  height: widget.height - widget.inset * 2,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest.withValues(
                        alpha: 0.8,
                      ),
                      borderRadius: BorderRadius.circular(
                        widget.selectedCornerRadius,
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      );
    }

    return IgnorePointer(
      child: UiKitView(
        viewType: 'clashking/liquid_glass_tab_bar',
        creationParams: _params(),
        creationParamsCodec: const StandardMessageCodec(),
        onPlatformViewCreated: (id) {
          _channel = MethodChannel('clashking/liquid_glass_tab_bar_$id');
          _sendUpdate();
        },
      ),
    );
  }
}
