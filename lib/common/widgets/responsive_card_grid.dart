import 'package:flutter/material.dart';

class ResponsiveCardGrid extends StatelessWidget {
  const ResponsiveCardGrid({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.minItemWidth = 420,
    this.maxColumns = 3,
    this.spacing = 12,
  });

  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final double minItemWidth;
  final int maxColumns;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final columns = ((availableWidth + spacing) / (minItemWidth + spacing))
            .floor()
            .clamp(1, maxColumns);
        final itemWidth =
            (availableWidth - (spacing * (columns - 1))) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: List.generate(
            itemCount,
            (index) =>
                SizedBox(width: itemWidth, child: itemBuilder(context, index)),
          ),
        );
      },
    );
  }
}
