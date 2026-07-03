import 'package:clashkingapp/common/theme/app_tokens.dart';
import 'package:flutter/material.dart';

/// Dense stat pill — a vertical, many-per-row sibling of the chip/MetricChip
/// glass family, used for compact CWL/war stat breakdowns (6-8 per row).
class StatTile extends StatelessWidget {
  final String label;
  final String value;
  final Widget icon;

  const StatTile({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: 56,
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.32),
        borderRadius: BorderRadius.circular(AppRadius.chip),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.32),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Center(child: icon),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
