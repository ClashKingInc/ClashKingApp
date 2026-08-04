import 'package:clashking_design_system/clashking_design_system.dart';
import 'package:flutter/material.dart';

/// A skeleton loading widget that shows a shimmer effect while content loads
class SkeletonLoader extends StatefulWidget {
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final EdgeInsets? margin;

  const SkeletonLoader({
    super.key,
    this.width,
    this.height,
    this.borderRadius,
    this.margin,
  });

  @override
  State<SkeletonLoader> createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<SkeletonLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller
        ..stop()
        ..value = 0.5;
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return Container(
      width: widget.width,
      height: widget.height,
      margin: widget.margin,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              borderRadius:
                  widget.borderRadius ?? BorderRadius.circular(CKSpacing.sm),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.grey[300]!.withValues(alpha: 0.2),
                  Colors.grey[100]!.withValues(alpha: 0.2),
                  Colors.grey[300]!.withValues(alpha: 0.2),
                ],
                stops: [
                  (reduceMotion ? 0.2 : _animation.value - 0.3),
                  (reduceMotion ? 0.5 : _animation.value),
                  (reduceMotion ? 0.8 : _animation.value + 0.3),
                ].map((stop) => stop.clamp(0.0, 1.0)).toList(),
              ),
            ),
          );
        },
      ),
    );
  }
}

class SkeletonActionIndicator extends StatelessWidget {
  final double width;
  final double height;

  const SkeletonActionIndicator({super.key, this.width = 20, this.height = 8});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: width,
      child: Center(
        child: SkeletonLoader(
          width: width,
          height: height,
          borderRadius: BorderRadius.circular(height),
        ),
      ),
    );
  }
}

class SkeletonListItem extends StatelessWidget {
  final bool leading;
  final bool trailing;
  final int lines;
  final EdgeInsetsGeometry padding;

  const SkeletonListItem({
    super.key,
    this.leading = true,
    this.trailing = true,
    this.lines = 2,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final radius = BorderRadius.circular(CKRadius.card);

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.28),
        borderRadius: radius,
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.36),
        ),
      ),
      child: Row(
        children: [
          if (leading) ...[
            SkeletonLoader(
              width: 48,
              height: 48,
              borderRadius: BorderRadius.circular(CKRadius.control),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonLoader(
                  width: double.infinity,
                  height: 16,
                  borderRadius: BorderRadius.circular(CKSpacing.xs),
                ),
                if (lines > 1) ...[
                  const SizedBox(height: 10),
                  SkeletonLoader(
                    width: 160,
                    height: 12,
                    borderRadius: BorderRadius.circular(CKSpacing.xs),
                  ),
                ],
                if (lines > 2) ...[
                  const SizedBox(height: 10),
                  SkeletonLoader(
                    width: 96,
                    height: 12,
                    borderRadius: BorderRadius.circular(CKSpacing.xs),
                  ),
                ],
              ],
            ),
          ),
          if (trailing) ...[
            const SizedBox(width: 12),
            SkeletonLoader(
              width: 36,
              height: 24,
              borderRadius: BorderRadius.circular(CKRadius.chip),
            ),
          ],
        ],
      ),
    );
  }
}

class SkeletonList extends StatelessWidget {
  final int itemCount;
  final EdgeInsetsGeometry padding;
  final bool leading;
  final bool trailing;
  final int lines;

  const SkeletonList({
    super.key,
    this.itemCount = 5,
    this.padding = EdgeInsets.zero,
    this.leading = true,
    this.trailing = true,
    this.lines = 2,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Column(
        children: List.generate(
          itemCount,
          (index) => Padding(
            padding: EdgeInsets.only(bottom: index == itemCount - 1 ? 0 : 12),
            child: SkeletonListItem(
              leading: leading,
              trailing: trailing,
              lines: lines,
            ),
          ),
        ),
      ),
    );
  }
}

class SkeletonPage extends StatelessWidget {
  final int itemCount;
  final EdgeInsetsGeometry padding;
  final bool includeHeader;

  const SkeletonPage({
    super.key,
    this.itemCount = 5,
    this.padding = const EdgeInsets.all(16),
    this.includeHeader = true,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: padding,
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (includeHeader) ...[
            SkeletonLoader(
              width: 180,
              height: 24,
              borderRadius: BorderRadius.circular(CKSpacing.sm),
            ),
            const SizedBox(height: 10),
            SkeletonLoader(
              width: 260,
              height: 14,
              borderRadius: BorderRadius.circular(CKSpacing.xs),
            ),
            const SizedBox(height: 20),
          ],
          SkeletonList(itemCount: itemCount),
        ],
      ),
    );
  }
}

class SkeletonLoadingDialog extends StatelessWidget {
  const SkeletonLoadingDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: Material(
          color: Colors.transparent,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 28),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(CKRadius.card),
              border: Border.all(
                color: colorScheme.outlineVariant.withValues(alpha: 0.36),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Row(
              children: [
                SkeletonLoader(
                  width: 48,
                  height: 48,
                  borderRadius: BorderRadius.circular(CKRadius.control),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SkeletonLoader(
                        width: double.infinity,
                        height: 16,
                        borderRadius: BorderRadius.circular(CKSpacing.xs),
                      ),
                      const SizedBox(height: 10),
                      SkeletonLoader(
                        width: 140,
                        height: 12,
                        borderRadius: BorderRadius.circular(CKSpacing.xs),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A pre-built skeleton for war stats cards
class WarStatsSkeletonCard extends StatelessWidget {
  const WarStatsSkeletonCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50]!.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(CKRadius.control),
        border: Border.all(color: Colors.grey[200]!.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          // Avatar skeleton
          SkeletonLoader(
            width: 50,
            height: 50,
            borderRadius: BorderRadius.circular(CKSpacing.sm),
          ),
          const SizedBox(width: 12),

          // Content skeleton
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name skeleton
                SkeletonLoader(
                  width: double.infinity,
                  height: 16,
                  borderRadius: BorderRadius.circular(CKSpacing.xs),
                ),
                const SizedBox(height: 8),

                // Performance indicators skeleton
                Row(
                  children: [
                    // Stars skeleton
                    SkeletonLoader(
                      width: 60,
                      height: 12,
                      borderRadius: BorderRadius.circular(CKSpacing.sm - 2),
                    ),
                    const SizedBox(width: 12),

                    // Destruction skeleton
                    SkeletonLoader(
                      width: 40,
                      height: 12,
                      borderRadius: BorderRadius.circular(CKSpacing.sm - 2),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Date skeleton
                SkeletonLoader(
                  width: 80,
                  height: 10,
                  borderRadius: BorderRadius.circular(CKSpacing.xs),
                ),
              ],
            ),
          ),

          // Performance indicator skeleton
          SkeletonLoader(
            width: 40,
            height: 24,
            borderRadius: BorderRadius.circular(CKRadius.control),
          ),
        ],
      ),
    );
  }
}

/// A pre-built skeleton for stat cards
class StatCardSkeleton extends StatelessWidget {
  const StatCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50]!.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(CKRadius.control),
        border: Border.all(color: Colors.grey[200]!.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          // Title skeleton
          SkeletonLoader(
            width: double.infinity,
            height: 16,
            borderRadius: BorderRadius.circular(CKSpacing.xs),
          ),
          const SizedBox(height: 16),

          // Performance indicators skeleton
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Stars skeleton
              Column(
                children: [
                  SkeletonLoader(
                    width: 60,
                    height: 16,
                    borderRadius: BorderRadius.circular(CKSpacing.sm),
                  ),
                  const SizedBox(height: 8),
                  SkeletonLoader(
                    width: 30,
                    height: 12,
                    borderRadius: BorderRadius.circular(CKSpacing.sm - 2),
                  ),
                ],
              ),

              // Destruction skeleton
              Column(
                children: [
                  SkeletonLoader(
                    width: 60,
                    height: 8,
                    borderRadius: BorderRadius.circular(CKSpacing.xs),
                  ),
                  const SizedBox(height: 8),
                  SkeletonLoader(
                    width: 40,
                    height: 12,
                    borderRadius: BorderRadius.circular(CKSpacing.sm - 2),
                  ),
                ],
              ),

              // Count skeleton
              Column(
                children: [
                  SkeletonLoader(
                    width: 20,
                    height: 20,
                    borderRadius: BorderRadius.circular(CKSpacing.md - 2),
                  ),
                  const SizedBox(height: 8),
                  SkeletonLoader(
                    width: 25,
                    height: 12,
                    borderRadius: BorderRadius.circular(CKSpacing.sm - 2),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
