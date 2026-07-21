import 'package:clashkingapp/common/widgets/mobile_web_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class InfoProfileTabData {
  const InfoProfileTabData({required this.label, this.imageUrl, this.icon});

  final String label;
  final String? imageUrl;
  final IconData? icon;
}

/// Shared detail-page navigation used below Player, Clan, and tracker headers.
class InfoProfileTabs extends StatefulWidget {
  const InfoProfileTabs({
    super.key,
    required this.tabs,
    required this.selectedIndex,
    required this.onTabSelected,
    this.alwaysScrollable = false,
  });

  final List<InfoProfileTabData> tabs;
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;
  final bool alwaysScrollable;

  @override
  State<InfoProfileTabs> createState() => _InfoProfileTabsState();
}

class _InfoProfileTabsState extends State<InfoProfileTabs>
    with TickerProviderStateMixin {
  late TabController _controller;

  @override
  void initState() {
    super.initState();
    _controller = _createController();
  }

  TabController _createController() => TabController(
    length: widget.tabs.length,
    vsync: this,
    initialIndex: widget.selectedIndex.clamp(0, widget.tabs.length - 1),
  );

  @override
  void didUpdateWidget(covariant InfoProfileTabs oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tabs.length != widget.tabs.length) {
      _controller.dispose();
      _controller = _createController();
      return;
    }
    if (_controller.index != widget.selectedIndex) {
      _controller.animateTo(
        widget.selectedIndex,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDesktopWeb = kIsWeb && MediaQuery.sizeOf(context).width >= 900;
    final isScrollable = widget.alwaysScrollable || !isDesktopWeb;
    return DecoratedBox(
      decoration: BoxDecoration(color: scheme.surface),
      child: SizedBox(
        height: 50,
        child: TabBar(
          controller: _controller,
          isScrollable: isScrollable,
          tabAlignment: isScrollable ? TabAlignment.start : TabAlignment.fill,
          padding: EdgeInsets.symmetric(horizontal: isScrollable ? 6 : 0),
          labelPadding: EdgeInsets.symmetric(horizontal: isScrollable ? 10 : 0),
          labelColor: scheme.onSurface,
          unselectedLabelColor: scheme.onSurface,
          indicatorColor: scheme.primary,
          indicatorWeight: 2.5,
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: scheme.outlineVariant.withValues(alpha: 0.35),
          splashFactory: NoSplash.splashFactory,
          overlayColor: const WidgetStatePropertyAll(Colors.transparent),
          onTap: widget.onTabSelected,
          tabs: [
            for (var index = 0; index < widget.tabs.length; index++)
              _InfoProfileTab(
                data: widget.tabs[index],
                selected: widget.selectedIndex == index,
              ),
          ],
        ),
      ),
    );
  }
}

class _InfoProfileTab extends StatelessWidget {
  const _InfoProfileTab({required this.data, required this.selected});

  final InfoProfileTabData data;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final foreground = scheme.onSurface.withValues(alpha: selected ? 1 : 0.64);
    return Tab(
      height: 48,
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (data.imageUrl case final imageUrl?)
              MobileWebImage(imageUrl: imageUrl, width: 18, height: 18)
            else
              Icon(
                data.icon ?? Icons.circle_rounded,
                size: 18,
                color: foreground,
              ),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                data.label,
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: foreground,
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
