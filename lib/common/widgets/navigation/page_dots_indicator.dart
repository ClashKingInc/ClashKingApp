import 'package:clashking_design_system/clashking_design_system.dart';
import 'package:flutter/material.dart';

/// Animates [controller] to [page], respecting reduced-motion settings.
/// Shared by every swipeable Home dashboard card pager.
void animatePagerTo(BuildContext context, PageController controller, int page) {
  if (!controller.hasClients) return;
  if (CKMotion.animationsDisabled(context)) {
    controller.jumpToPage(page);
    return;
  }
  controller.animateToPage(
    page,
    duration: CKMotion.fast,
    curve: CKMotion.standardCurve,
  );
}

/// Dot-pager indicator shared by the Home dashboard's swipeable cards
/// (to-do, Ranked League, Upgrade Tracker) so they read as one family.
class PageDotsIndicator extends StatelessWidget {
  const PageDotsIndicator({
    super.key,
    required this.count,
    required this.index,
    this.onDotTap,
    this.tooltipForIndex,
  });

  final int count;
  final int index;
  final ValueChanged<int>? onDotTap;
  final String Function(int index)? tooltipForIndex;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(count, (dotIndex) {
        final selected = dotIndex == index;
        final dot = AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: selected ? 18 : 7,
          height: 7,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: selected
                ? colorScheme.onSurface
                : colorScheme.onSurface.withValues(alpha: 0.24),
            borderRadius: BorderRadius.circular(999),
          ),
        );
        if (onDotTap == null) return dot;
        final tappableDot = InkResponse(
          radius: 14,
          onTap: () => onDotTap!(dotIndex),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 1, vertical: 8),
            child: dot,
          ),
        );
        final tooltip = tooltipForIndex?.call(dotIndex);
        if (tooltip == null) return tappableDot;
        return Tooltip(message: tooltip, child: tappableDot);
      }),
    );
  }
}
