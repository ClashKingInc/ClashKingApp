import 'package:clashking_design_system/clashking_design_system.dart';
import 'package:flutter/material.dart';
import 'package:sliver_tools/sliver_tools.dart';

/// Shared collapsible item-section shell used by Player Info and the upgrade
/// tracker so their hierarchy, spacing, and motion stay in sync.
class CollapsibleItemSection extends StatelessWidget {
  const CollapsibleItemSection({
    super.key,
    required this.title,
    required this.expanded,
    required this.onToggle,
    required this.child,
    this.leading,
    this.subtitle,
    this.trailing,
    this.margin = const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
    this.animateContent = true,
    this.showContent = true,
    this.surfaceWhenExpanded = true,
    this.showSurface = true,
    this.contentPadding = const EdgeInsets.all(CKSpacing.md),
    this.expandedSpacing = 12,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final bool expanded;
  final VoidCallback onToggle;
  final Widget child;
  final EdgeInsetsGeometry margin;
  final bool animateContent;
  final bool showContent;
  final bool surfaceWhenExpanded;
  final bool showSurface;
  final EdgeInsetsGeometry contentPadding;
  final double expandedSpacing;

  @override
  Widget build(BuildContext context) {
    final expandedChild = expanded
        ? Padding(
            padding: EdgeInsets.only(top: expandedSpacing),
            child: child,
          )
        : const SizedBox(width: double.infinity);
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44),
          child: InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(CKRadius.control),
            splashFactory: NoSplash.splashFactory,
            overlayColor: const WidgetStatePropertyAll(Colors.transparent),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  AnimatedRotation(
                    turns: expanded ? 0.25 : 0,
                    duration: CKMotion.durationOf(context, CKMotion.fast),
                    curve: CKMotion.standardCurve,
                    child: Icon(
                      Icons.chevron_right_rounded,
                      size: 22,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.72),
                    ),
                  ),
                  const SizedBox(width: CKSpacing.xs),
                  if (leading != null) ...[
                    leading!,
                    const SizedBox(width: CKSpacing.sm),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: CKTypography.of(
                            context,
                            CKTextRole.sectionTitle,
                          ),
                        ),
                        if (subtitle != null)
                          Text(
                            subtitle!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: CKTypography.of(context, CKTextRole.metadata)
                                .copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                          ),
                      ],
                    ),
                  ),
                  ?trailing,
                ],
              ),
            ),
          ),
        ),
        if (showContent)
          if (animateContent)
            AnimatedSize(
              duration: CKMotion.durationOf(context, CKMotion.standard),
              curve: CKMotion.standardCurve,
              alignment: Alignment.topCenter,
              child: expandedChild,
            )
          else
            expandedChild,
      ],
    );
    final section = !showSurface || (expanded && !surfaceWhenExpanded)
        ? Padding(padding: contentPadding, child: content)
        : CKSectionPanel(padding: contentPadding, child: content);
    return Container(width: double.infinity, margin: margin, child: section);
  }
}

class CompactItemGrid extends StatelessWidget {
  const CompactItemGrid({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.spacing = 8,
    this.minTileSize = 54,
  });

  final int itemCount;
  final Widget Function(BuildContext context, int index, double size)
  itemBuilder;
  final double spacing;
  final double minTileSize;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final columns =
          ((constraints.maxWidth + spacing) / (minTileSize + spacing))
              .floor()
              .clamp(1, 999);
      final tileSize =
          (constraints.maxWidth - (columns - 1) * spacing) / columns;
      return Wrap(
        spacing: spacing,
        runSpacing: spacing,
        children: List.generate(
          itemCount,
          (index) => itemBuilder(context, index, tileSize),
        ),
      );
    },
  );
}

/// Sliver-native counterpart to [CollapsibleItemSection]. Keeps large grids
/// lazy while giving Upgrades and Collection the same quiet section shell.
class SliverItemSectionPanel extends StatelessWidget {
  const SliverItemSectionPanel({
    super.key,
    required this.slivers,
    required this.margin,
  });

  final List<Widget> slivers;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) => SliverAnimatedPaintExtent(
    duration: CKMotion.durationOf(context, CKMotion.standard),
    curve: CKMotion.standardCurve,
    child: SliverPadding(
      padding: margin,
      sliver: DecoratedSliver(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(CKRadius.panel),
          border: Border.all(
            color: Theme.of(
              context,
            ).colorScheme.outlineVariant.withValues(alpha: CKOpacity.border),
          ),
        ),
        sliver: SliverPadding(
          padding: const EdgeInsets.all(CKSpacing.xs),
          sliver: SliverMainAxisGroup(slivers: slivers),
        ),
      ),
    ),
  );
}

class SectionProgressBadge extends StatelessWidget {
  const SectionProgressBadge({
    super.key,
    required this.progress,
    required this.onTap,
    this.tooltip = 'Tap for remaining upgrade cost and time',
  });

  final double progress;
  final VoidCallback onTap;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final normalized = progress.clamp(0.0, 1.0).toDouble();
    final progressColor = normalized >= 1
        ? CKUpgradeColors.completion
        : const Color(0xFFE0302B);
    final percentage = normalized * 100;
    final label = percentage % 1 == 0
        ? percentage.toInt().toString()
        : percentage.toStringAsFixed(1);
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: onTap,
          child: CustomPaint(
            foregroundPainter: _SectionPercentOutlinePainter(
              progress: normalized,
              trackColor: colorScheme.outlineVariant.withValues(alpha: 0.58),
              progressColor: progressColor,
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                color: normalized >= 1
                    ? progressColor.withValues(alpha: 0.14)
                    : colorScheme.surfaceContainerHighest.withValues(
                        alpha: 0.55,
                      ),
              ),
              child: Text(
                '$label%',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionPercentOutlinePainter extends CustomPainter {
  const _SectionPercentOutlinePainter({
    required this.progress,
    required this.trackColor,
    required this.progressColor,
  });

  final double progress;
  final Color trackColor;
  final Color progressColor;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          (Offset.zero & size).deflate(1),
          const Radius.circular(999),
        ),
      );
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..color = trackColor,
    );
    for (final metric in path.computeMetrics()) {
      canvas.drawPath(
        metric.extractPath(0, metric.length * progress),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round
          ..color = progressColor,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SectionPercentOutlinePainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.trackColor != trackColor ||
      oldDelegate.progressColor != progressColor;
}
