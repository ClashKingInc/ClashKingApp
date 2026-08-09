import 'dart:math' as math;

import 'package:clashking_design_system/clashking_design_system.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// Desktop Home comparison layout.
///
/// The combined account summary stays visible at the leading edge while the
/// individual accounts share one horizontal rail. All cards use the same
/// footprint, so the summary reads as another comparison subject instead of a
/// separate section. Mobile keeps using each feature's existing pager.
class HomeAccountComparisonGrid extends StatefulWidget {
  const HomeAccountComparisonGrid({
    super.key,
    required this.itemCount,
    required this.hasSummaryItem,
    required this.itemHeight,
    required this.itemBuilder,
  });

  final int itemCount;
  final bool hasSummaryItem;
  final double itemHeight;
  final IndexedWidgetBuilder itemBuilder;

  @override
  State<HomeAccountComparisonGrid> createState() =>
      _HomeAccountComparisonGridState();
}

class _HomeAccountComparisonGridState extends State<HomeAccountComparisonGrid> {
  static const double _gap = CKSpacing.md;
  static const double _minimumCardWidth = 270;
  static const double _overflowCardWidth = 240;
  static const double _maximumCardWidth = 360;
  static const double _singleCardMaxWidth = 552;
  static const double _navigationSpace = 48;
  static const double _scrollTolerance = 1;

  final ScrollController _controller = ScrollController();
  var _metricsUpdateScheduled = false;
  var _hasOverflow = false;
  var _canScrollBack = false;
  var _canScrollForward = false;
  var _cardStride = _minimumCardWidth + _gap;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_updateScrollMetrics);
  }

  @override
  void didUpdateWidget(covariant HomeAccountComparisonGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.itemCount != widget.itemCount ||
        oldWidget.hasSummaryItem != widget.hasSummaryItem ||
        oldWidget.itemHeight != widget.itemHeight) {
      _scheduleMetricsUpdate();
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_updateScrollMetrics);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.itemCount <= 0) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : _singleCardMaxWidth;
        final layout = _layoutFor(availableWidth);
        _cardStride = layout.cardWidth + _gap;
        _scheduleMetricsUpdate();

        if (widget.itemCount == 1) {
          return Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: layout.cardWidth,
              height: widget.itemHeight,
              child: widget.itemBuilder(context, 0),
            ),
          );
        }

        final firstAccountIndex = widget.hasSummaryItem ? 1 : 0;
        final accountCount = widget.itemCount - firstAccountIndex;
        return SizedBox(
          height: widget.itemHeight,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (widget.hasSummaryItem) ...[
                SizedBox(
                  width: layout.cardWidth,
                  child: widget.itemBuilder(context, 0),
                ),
                const SizedBox(width: _gap),
              ],
              if (accountCount > 0)
                Expanded(
                  child: _AccountRail(
                    controller: _controller,
                    itemCount: accountCount,
                    firstItemIndex: firstAccountIndex,
                    cardWidth: layout.cardWidth,
                    itemHeight: widget.itemHeight,
                    itemBuilder: widget.itemBuilder,
                    hasOverflow: _hasOverflow,
                    canScrollBack: _canScrollBack,
                    canScrollForward: _canScrollForward,
                    showsNavigation: layout.reservesNavigation,
                    onPrevious: () => _scrollBy(-_cardStride),
                    onNext: () => _scrollBy(_cardStride),
                    onPointerSignal: _handlePointerSignal,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  _ComparisonLayout _layoutFor(double availableWidth) {
    if (widget.itemCount == 1) {
      return _ComparisonLayout(
        cardWidth: math.min(availableWidth, _singleCardMaxWidth),
        reservesNavigation: false,
      );
    }

    final slotsWithoutNavigation = _visibleSlotCount(
      availableWidth,
      minimumWidth: _minimumCardWidth,
    );
    final reservesNavigation = widget.itemCount > slotsWithoutNavigation;
    final cardsWidth = math.max(
      0.0,
      availableWidth - (reservesNavigation ? _navigationSpace : 0),
    );
    var visibleSlots = _visibleSlotCount(
      cardsWidth,
      minimumWidth: reservesNavigation ? _overflowCardWidth : _minimumCardWidth,
    );
    if (widget.hasSummaryItem && widget.itemCount > 1) {
      visibleSlots = math.max(2, visibleSlots);
    }
    final cardWidth = (cardsWidth - _gap * (visibleSlots - 1)) / visibleSlots;
    return _ComparisonLayout(
      cardWidth: cardWidth.clamp(0, _maximumCardWidth).toDouble(),
      reservesNavigation: reservesNavigation,
    );
  }

  int _visibleSlotCount(double width, {required double minimumWidth}) =>
      ((width + _gap) / (minimumWidth + _gap)).floor().clamp(
        1,
        widget.itemCount,
      );

  void _scheduleMetricsUpdate() {
    if (_metricsUpdateScheduled) return;
    _metricsUpdateScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _metricsUpdateScheduled = false;
      if (mounted) _updateScrollMetrics();
    });
  }

  void _updateScrollMetrics() {
    if (!_controller.hasClients) return;
    final position = _controller.position;
    final hasOverflow = position.maxScrollExtent > _scrollTolerance;
    final canScrollBack = hasOverflow && position.pixels > _scrollTolerance;
    final canScrollForward =
        hasOverflow &&
        position.pixels < position.maxScrollExtent - _scrollTolerance;
    if (hasOverflow == _hasOverflow &&
        canScrollBack == _canScrollBack &&
        canScrollForward == _canScrollForward) {
      return;
    }
    setState(() {
      _hasOverflow = hasOverflow;
      _canScrollBack = canScrollBack;
      _canScrollForward = canScrollForward;
    });
  }

  void _scrollBy(double delta) {
    if (!_controller.hasClients) return;
    final target = (_controller.offset + delta).clamp(
      _controller.position.minScrollExtent,
      _controller.position.maxScrollExtent,
    );
    final duration = CKMotion.durationOf(context, CKMotion.standard);
    if (duration == Duration.zero) {
      _controller.jumpTo(target);
      return;
    }
    _controller.animateTo(
      target,
      duration: duration,
      curve: CKMotion.standardCurve,
    );
  }

  void _handlePointerSignal(PointerSignalEvent event) {
    if (event is! PointerScrollEvent ||
        !_hasOverflow ||
        !_controller.hasClients) {
      return;
    }
    final delta = event.scrollDelta.dx.abs() > event.scrollDelta.dy.abs()
        ? event.scrollDelta.dx
        : event.scrollDelta.dy;
    if (delta == 0) return;
    final target = (_controller.offset + delta).clamp(
      _controller.position.minScrollExtent,
      _controller.position.maxScrollExtent,
    );
    _controller.jumpTo(target);
  }
}

class _ComparisonLayout {
  const _ComparisonLayout({
    required this.cardWidth,
    required this.reservesNavigation,
  });

  final double cardWidth;
  final bool reservesNavigation;
}

class _AccountRail extends StatelessWidget {
  const _AccountRail({
    required this.controller,
    required this.itemCount,
    required this.firstItemIndex,
    required this.cardWidth,
    required this.itemHeight,
    required this.itemBuilder,
    required this.hasOverflow,
    required this.canScrollBack,
    required this.canScrollForward,
    required this.showsNavigation,
    required this.onPrevious,
    required this.onNext,
    required this.onPointerSignal,
  });

  final ScrollController controller;
  final int itemCount;
  final int firstItemIndex;
  final double cardWidth;
  final double itemHeight;
  final IndexedWidgetBuilder itemBuilder;
  final bool hasOverflow;
  final bool canScrollBack;
  final bool canScrollForward;
  final bool showsNavigation;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final void Function(PointerSignalEvent) onPointerSignal;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showsNavigation) ...[
          _RailNavigation(
            visible: hasOverflow,
            canScrollBack: canScrollBack,
            canScrollForward: canScrollForward,
            onPrevious: onPrevious,
            onNext: onNext,
          ),
          const SizedBox(width: CKSpacing.xs),
        ],
        Expanded(
          child: ClipRect(
            child: Listener(
              onPointerSignal: onPointerSignal,
              child: SingleChildScrollView(
                key: const ValueKey('home-comparison-account-rail'),
                controller: controller,
                scrollDirection: Axis.horizontal,
                physics: const ClampingScrollPhysics(),
                child: Row(
                  children: [
                    for (
                      var localIndex = 0;
                      localIndex < itemCount;
                      localIndex++
                    ) ...[
                      if (localIndex > 0) const SizedBox(width: CKSpacing.md),
                      SizedBox(
                        width: cardWidth,
                        height: itemHeight,
                        child: itemBuilder(
                          context,
                          firstItemIndex + localIndex,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _RailNavigation extends StatelessWidget {
  const _RailNavigation({
    required this.visible,
    required this.canScrollBack,
    required this.canScrollForward,
    required this.onPrevious,
    required this.onNext,
  });

  final bool visible;
  final bool canScrollBack;
  final bool canScrollForward;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      child: Align(
        alignment: Alignment.center,
        child: visible
            ? Material(
                color: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.96),
                borderRadius: BorderRadius.circular(CKRadius.pill),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _RailButton(
                      key: const ValueKey('home-comparison-previous'),
                      tooltip: MaterialLocalizations.of(
                        context,
                      ).previousPageTooltip,
                      icon: Icons.keyboard_arrow_up_rounded,
                      onPressed: canScrollBack ? onPrevious : null,
                    ),
                    _RailButton(
                      key: const ValueKey('home-comparison-next'),
                      tooltip: MaterialLocalizations.of(
                        context,
                      ).nextPageTooltip,
                      icon: Icons.keyboard_arrow_down_rounded,
                      onPressed: canScrollForward ? onNext : null,
                    ),
                  ],
                ),
              )
            : const SizedBox.shrink(),
      ),
    );
  }
}

class _RailButton extends StatelessWidget {
  const _RailButton({
    super.key,
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints.tightFor(width: 40, height: 40),
      iconSize: 22,
      icon: Icon(icon),
    );
  }
}
