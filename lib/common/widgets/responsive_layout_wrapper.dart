import 'package:flutter/material.dart';
import 'package:clashkingapp/core/constants/layout_constants.dart';

class ResponsiveLayoutWrapper extends StatelessWidget {
  final Widget child;
  final Color? backgroundColor;

  const ResponsiveLayoutWrapper({
    super.key,
    required this.child,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: backgroundColor ?? Theme.of(context).scaffoldBackgroundColor,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: kMaxContentWidth),
          child: child,
        ),
      ),
    );
  }
}
