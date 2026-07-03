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
  final TabAlignment? tabAlignment;

  const ScrollableTab({
    super.key,
    this.tabBarDecoration,
    this.labelColor,
    this.labelPadding,
    this.labelStyle,
    this.unselectedLabelColor,
    this.onTap,
    this.scrollable = false,
    this.tabAlignment,
    required this.tabs,
    required this.children,
  }) : assert(tabs.length == children.length);

  @override
  State<ScrollableTab> createState() => _ScrollableTabState();
}

class _ScrollableTabState extends State<ScrollableTab> {
  int _selectedIndex = 0;

  void _selectIndex(int index) {
    if (index < 0 || index >= widget.tabs.length || index == _selectedIndex) {
      return;
    }
    setState(() => _selectedIndex = index);
    widget.onTap?.call(index);
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      key: ValueKey(_selectedIndex),
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
              tabAlignment:
                  widget.tabAlignment ??
                  (widget.scrollable ? TabAlignment.start : TabAlignment.fill),
              labelColor: widget.labelColor,
              labelPadding: widget.labelPadding,
              labelStyle: widget.labelStyle,
              unselectedLabelColor: widget.unselectedLabelColor,
              tabs: widget.tabs,
              onTap: (index) {
                _selectIndex(index);
              },
            ),
          ),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onHorizontalDragEnd: (details) {
              final velocity = details.primaryVelocity ?? 0;
              if (velocity < -220) {
                _selectIndex(_selectedIndex + 1);
              } else if (velocity > 220) {
                _selectIndex(_selectedIndex - 1);
              }
            },
            child: widget.children[_selectedIndex],
          ),
        ],
      ),
    );
  }
}
