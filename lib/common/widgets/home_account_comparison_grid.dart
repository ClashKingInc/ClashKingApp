import 'package:flutter/material.dart';

/// Responsive Home layout for a combined summary followed by account cards.
///
/// Wide screens expose every account for direct comparison. Compact screens
/// keep using the account rail and pager owned by each Home card.
class HomeAccountComparisonGrid extends StatelessWidget {
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

  static const double _gap = 12;
  static const double _singleCardMaxWidth = 552;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final firstAccountIndex = hasSummaryItem ? 1 : 0;
        final accountCount = itemCount - firstAccountIndex;
        final columns = constraints.maxWidth >= 1040 && accountCount >= 3
            ? 3
            : constraints.maxWidth >= 700 && accountCount >= 2
            ? 2
            : 1;
        final availableWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : _singleCardMaxWidth;
        final cardWidth = accountCount == 1 && !hasSummaryItem
            ? availableWidth.clamp(0, _singleCardMaxWidth).toDouble()
            : (availableWidth - _gap * (columns - 1)) / columns;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (hasSummaryItem)
              SizedBox(
                height: itemHeight,
                width: availableWidth,
                child: itemBuilder(context, 0),
              ),
            if (hasSummaryItem && accountCount > 0)
              const SizedBox(height: _gap),
            if (accountCount > 0)
              Wrap(
                spacing: _gap,
                runSpacing: _gap,
                children: [
                  for (
                    var index = firstAccountIndex;
                    index < itemCount;
                    index++
                  )
                    SizedBox(
                      width: cardWidth,
                      height: itemHeight,
                      child: itemBuilder(context, index),
                    ),
                ],
              ),
          ],
        );
      },
    );
  }
}
