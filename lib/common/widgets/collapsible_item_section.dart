import 'package:flutter/material.dart';

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
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final bool expanded;
  final VoidCallback onToggle;
  final Widget child;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    margin: margin,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color:
          Theme.of(context).cardTheme.color ??
          Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: Theme.of(
          context,
        ).colorScheme.outlineVariant.withValues(alpha: 0.32),
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: onToggle,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                AnimatedRotation(
                  turns: expanded ? 0.25 : 0,
                  duration: const Duration(milliseconds: 160),
                  curve: Curves.easeOutCubic,
                  child: Icon(
                    Icons.chevron_right_rounded,
                    size: 22,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.72),
                  ),
                ),
                const SizedBox(width: 4),
                if (leading != null) ...[leading!, const SizedBox(width: 9)],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      if (subtitle != null)
                        Text(
                          subtitle!,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
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
        AnimatedSize(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: expanded
              ? Padding(padding: const EdgeInsets.only(top: 12), child: child)
              : const SizedBox(width: double.infinity),
        ),
      ],
    ),
  );
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
    const progressRed = Color(0xFFE0302B);
    final colorScheme = Theme.of(context).colorScheme;
    final normalized = progress.clamp(0.0, 1.0).toDouble();
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
              progressColor: progressRed,
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                color: colorScheme.surfaceContainerHighest.withValues(
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
