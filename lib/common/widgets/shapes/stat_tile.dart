import 'package:clashking_design_system/clashking_design_system.dart';
import 'package:flutter/material.dart';

/// Dense stat pill — a vertical, many-per-row sibling of the chip/MetricChip
/// glass family, used for compact CWL/war stat breakdowns (6-8 per row).
class StatTile extends StatelessWidget {
  final String label;
  final String value;
  final Widget icon;
  final String? semanticLabel;

  const StatTile({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    return CKStatTile(
      label: label,
      value: value,
      icon: icon,
      semanticLabel: semanticLabel,
    );
  }
}
