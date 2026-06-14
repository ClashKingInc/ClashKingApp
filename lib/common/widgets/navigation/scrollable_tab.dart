import 'package:flutter/material.dart';

class ScrollableTab extends StatefulWidget {
  final Decoration? tabBarDecoration;
  final Color? labelColor;
  final EdgeInsetsGeometry? labelPadding;
  final TextStyle? labelStyle;
  final Color? unselectedLabelColor;
  final ValueChanged<int>? onTap;
  final List<Widget> tabs;
  final List<Widget> children;
  final bool scrollable;

  const ScrollableTab({
    super.key,
    this.tabBarDecoration,
    this.labelColor,
    this.labelPadding,
    this.labelStyle,
    this.unselectedLabelColor,
    this.onTap,
    this.scrollable = false,
    required this.tabs,
    required this.children,
  }) : assert(tabs.length == children.length);

  @override
  State<ScrollableTab> createState() => _ScrollableTabState();
}

class _ScrollableTabState extends State<ScrollableTab> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: widget.tabs.length,
      initialIndex: _selectedIndex,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          DecoratedBox(
            decoration: widget.tabBarDecoration ?? const BoxDecoration(),
            child: TabBar(
              isScrollable: widget.scrollable,
              tabAlignment: widget.scrollable
                  ? TabAlignment.start
                  : TabAlignment.fill,
              labelColor: widget.labelColor,
              labelPadding: widget.labelPadding,
              labelStyle: widget.labelStyle,
              unselectedLabelColor: widget.unselectedLabelColor,
              tabs: widget.tabs,
              onTap: (index) {
                setState(() => _selectedIndex = index);
                widget.onTap?.call(index);
              },
            ),
          ),
          widget.children[_selectedIndex],
        ],
      ),
    );
  }
}
