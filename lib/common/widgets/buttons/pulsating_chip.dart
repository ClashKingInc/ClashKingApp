import 'package:flutter/material.dart';

class PulsatingChip extends StatefulWidget {
  final Widget child;

  const PulsatingChip({super.key, required this.child});

  @override
  PulsatingChipState createState() => PulsatingChipState();
}

class PulsatingChipState extends State<PulsatingChip>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller
        ..stop()
        ..value = 0;
    } else if (!_controller.isAnimating) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).scaffoldBackgroundColor.withValues(
                  alpha: _controller.value * 0.9,
                ),
                spreadRadius: 0,
                blurRadius: 7,
              ),
            ],
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
