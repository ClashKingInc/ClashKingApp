import 'package:flutter/material.dart';

/// A visual indicator widget that shows performance with color coding and progress
class PerformanceIndicator extends StatelessWidget {
  final double value;
  final double maxValue;
  final String label;
  final Widget? icon;
  final bool showPercentage;
  final Color? customColor;

  const PerformanceIndicator({
    super.key,
    required this.value,
    required this.maxValue,
    required this.label,
    this.icon,
    this.showPercentage = false,
    this.customColor,
  });

  Color _getPerformanceColor() {
    if (customColor != null) return customColor!;
    
    final percentage = (value / maxValue).clamp(0.0, 1.0);
    
    if (percentage >= 0.8) return Colors.green;
    if (percentage >= 0.6) return Colors.orange;
    if (percentage >= 0.4) return Colors.amber;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    final percentage = (value / maxValue).clamp(0.0, 1.0);
    final color = _getPerformanceColor();
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          icon!,
          const SizedBox(height: 4),
        ],
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Container(
          width: 80,
          height: 8,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: Colors.grey[300],
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: percentage,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: color,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          showPercentage 
            ? '${(percentage * 100).toStringAsFixed(1)}%'
            : value.toStringAsFixed(2),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}