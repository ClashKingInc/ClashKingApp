import 'package:clashkingapp/common/theme/app_tokens.dart';
import 'package:flutter/material.dart';

/// Shared "chip family" for clan-family detail screens (clan, CWL,
/// capital, war stats): a horizontal rail of stat pills (read-only,
/// [ClanSummaryChip]) and a horizontal rail of toggleable filter pills
/// ([ClanFilterChip]) — the two recurring chip shapes across every
/// screen built with the flat-card design system (see the "Design
/// System" section in the project's CLAUDE.md).
class ClanSummaryChips extends StatelessWidget {
  final List<Widget> children;
  final EdgeInsetsGeometry padding;
  final WrapAlignment alignment;
  final bool scrollable;

  const ClanSummaryChips({
    super.key,
    required this.children,
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
    this.alignment = WrapAlignment.center,
    this.scrollable = true,
  });

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();

    if (scrollable) {
      return Padding(
        padding: padding,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var index = 0; index < children.length; index++) ...[
                children[index],
                if (index < children.length - 1) const SizedBox(width: 6),
              ],
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: padding,
      child: Wrap(
        alignment: alignment,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 6,
        runSpacing: 6,
        children: children,
      ),
    );
  }
}

/// Horizontal-scroll rail for [ClanFilterChip]s (or any pill-shaped
/// toggle), same recipe as [ClanSummaryChips] but with wider chip
/// spacing to suit tappable filters rather than read-only stats.
class ClanFilterRail extends StatelessWidget {
  final List<Widget> children;
  final EdgeInsetsGeometry padding;

  const ClanFilterRail({
    super.key,
    required this.children,
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
  });

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: padding,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var index = 0; index < children.length; index++) ...[
              children[index],
              if (index < children.length - 1) const SizedBox(width: 8),
            ],
          ],
        ),
      ),
    );
  }
}

/// Tappable filter pill: icon-in-circle-free flat pill, tinted with
/// [color] (falls back to the theme primary) when [selected]. The
/// default toggle control for filter rows across clan-style screens.
class ClanFilterChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool selected;
  final VoidCallback onTap;
  final Color? color;

  const ClanFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final accent = color ?? colorScheme.primary;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        splashFactory: NoSplash.splashFactory,
        onTap: onTap,
        child: Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 11),
          decoration: BoxDecoration(
            color: selected
                ? accent.withValues(alpha: 0.16)
                : colorScheme.surfaceContainerHighest.withValues(alpha: 0.38),
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(
              color: selected
                  ? accent.withValues(alpha: 0.42)
                  : colorScheme.outlineVariant.withValues(alpha: 0.28),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 15,
                  color: selected ? accent : colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 5),
              ],
              Text(
                label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
                  height: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Read-only stat pill: dot-or-icon, bold value, muted label — the
/// default way to surface a single number (attacks, loot, rank...) in a
/// horizontal summary row. Optionally tappable via [onTap].
class ClanSummaryChip extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;
  final IconData? icon;
  final VoidCallback? onTap;
  final bool selected;

  const ClanSummaryChip({
    super.key,
    required this.label,
    required this.value,
    this.color,
    this.icon,
    this.onTap,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final accent = color ?? colorScheme.primary;
    final backgroundAlpha = selected ? 0.18 : 0.12;
    final borderAlpha = selected ? 0.38 : 0.20;

    final child = Container(
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: backgroundAlpha),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: accent.withValues(alpha: borderAlpha)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon ?? Icons.circle_rounded,
            size: icon == null ? 10 : 14,
            color: accent,
          ),
          const SizedBox(width: 5),
          Text(
            value,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
          const SizedBox(width: 3),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
              height: 1,
            ),
          ),
        ],
      ),
    );

    if (onTap == null) return child;

    return Tooltip(
      message: label,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          splashFactory: NoSplash.splashFactory,
          onTap: onTap,
          child: child,
        ),
      ),
    );
  }
}
