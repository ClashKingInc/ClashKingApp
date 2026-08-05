import 'dart:ui' as ui;

import 'package:clashkingapp/common/widgets/mobile_web_image.dart';
import 'package:flutter/material.dart';

class InfoProfileTabData {
  const InfoProfileTabData({
    required this.label,
    this.imageUrl,
    this.icon,
    this.trailing,
  });

  final String label;
  final String? imageUrl;
  final IconData? icon;
  final Widget? trailing;
}

/// Shared detail-page navigation used below Player, Clan, and tracker headers.
class InfoProfileTabs extends StatefulWidget {
  const InfoProfileTabs({
    super.key,
    required this.tabs,
    required this.selectedIndex,
    required this.onTabSelected,
    this.alwaysScrollable = false,
    this.controller,
  });

  final List<InfoProfileTabData> tabs;
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;
  final bool alwaysScrollable;
  final TabController? controller;

  @override
  State<InfoProfileTabs> createState() => _InfoProfileTabsState();
}

/// Pinned counterpart to [InfoProfileTabs] for image-backed detail headers.
///
/// The overlay materializes as the in-flow tabs approach the system safe area,
/// then keeps navigation below the status bar while content scrolls underneath
/// the same compact material. Keeping this beside [InfoProfileTabs] ensures
/// the pinned and in-flow controls always share the same tab implementation.
class PinnedInfoProfileTabs extends StatelessWidget {
  const PinnedInfoProfileTabs({
    super.key,
    required this.tabs,
    required this.selectedIndex,
    required this.onTabSelected,
    required this.progress,
    this.alwaysScrollable = false,
    this.controller,
  });

  final List<InfoProfileTabData> tabs;
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;
  final double progress;
  final bool alwaysScrollable;
  final TabController? controller;

  static const double tabHeight = 50;

  /// The pinned and in-flow controls cross-fade only at the final edge of the
  /// collapse. This keeps the progressive status-bar treatment without
  /// rendering two dividers or indicators at visibly different heights.
  static double tabsOpacityFor(double progress) => Curves.easeOutCubic
      .transform(((progress.clamp(0.0, 1.0) - 0.82) / 0.18).clamp(0.0, 1.0));

  static double inFlowTabsOpacityFor(double progress) =>
      1 - tabsOpacityFor(progress);

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final safeTop = media.padding.top;
    final clampedProgress = progress.clamp(0.0, 1.0);
    final highContrast = media.highContrast;
    final surface = Theme.of(context).scaffoldBackgroundColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final chromeColor = isDark ? Colors.black : surface;
    final tabOpacity = tabsOpacityFor(clampedProgress);

    if (clampedProgress <= 0) return const SizedBox.shrink();

    return IgnorePointer(
      ignoring: tabOpacity < 0.98,
      child: SizedBox(
        height: safeTop + tabHeight,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: safeTop,
              child: ClipRect(
                child: BackdropFilter(
                  filter: ui.ImageFilter.blur(
                    sigmaX: highContrast ? 0 : 16 * clampedProgress,
                    sigmaY: highContrast ? 0 : 16 * clampedProgress,
                    tileMode: TileMode.decal,
                  ),
                  child: ColoredBox(
                    color: chromeColor.withValues(
                      alpha: highContrast
                          ? clampedProgress
                          : 0.90 * clampedProgress,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: safeTop,
              left: 0,
              right: 0,
              height: tabHeight,
              child: Opacity(
                opacity: tabOpacity,
                child: InfoProfileTabs(
                  tabs: tabs,
                  selectedIndex: selectedIndex,
                  onTabSelected: onTabSelected,
                  alwaysScrollable: alwaysScrollable,
                  controller: controller,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shared hero-header + subtab layout for detail and feature pages.
///
/// When [pages] is supplied, every page remains attached to the same
/// [NestedScrollView] coordinator and horizontal movement is driven by the
/// same [TabController] as the indicator. Inactive page positions are reset
/// on pointer-down, so the destination is already at its content top while it
/// follows the finger instead of being corrected after the swipe settles.
///
/// Data-driven screens can supply a single [body] instead. Their horizontal
/// gesture changes the tab and resets the coordinated inner scroll in the
/// same frame, which avoids carrying the previous section's offset into the
/// replacement content.
class InfoProfileTabScaffold extends StatefulWidget {
  const InfoProfileTabScaffold({
    super.key,
    required this.header,
    required this.tabs,
    required this.selectedIndex,
    required this.onTabSelected,
    this.pages,
    this.body,
    this.alwaysScrollable = false,
    this.tabsTopSpacing = 0,
    this.nestedScrollPhysics,
  }) : assert(
         (pages == null) != (body == null),
         'Provide either pages or body, but not both.',
       ),
       assert(pages == null || pages.length == tabs.length);

  final Widget header;
  final List<InfoProfileTabData> tabs;
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;
  final List<Widget>? pages;
  final Widget? body;
  final bool alwaysScrollable;
  final double tabsTopSpacing;
  final ScrollPhysics? nestedScrollPhysics;

  @override
  State<InfoProfileTabScaffold> createState() => _InfoProfileTabScaffoldState();
}

class _InfoProfileTabScaffoldState extends State<InfoProfileTabScaffold>
    with TickerProviderStateMixin {
  static const double _chromeRamp = 12;

  final _outerController = ScrollController();
  final _nestedScrollKey = GlobalKey<NestedScrollViewState>();
  final _tabsKey = GlobalKey();
  final _bodyScrollKey = GlobalKey();
  final _chromeProgress = ValueNotifier<double>(0);
  late TabController _tabController;
  late List<GlobalKey> _pageScrollKeys;
  var _syncingExternalSelection = false;

  int get _selectedIndex =>
      widget.selectedIndex.clamp(0, widget.tabs.length - 1);

  bool get _usesPages => widget.pages != null;

  @override
  void initState() {
    super.initState();
    _tabController = _createController();
    _pageScrollKeys = _createPageKeys();
    _outerController.addListener(_updateChrome);
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateChrome());
  }

  TabController _createController() => TabController(
    length: widget.tabs.length,
    vsync: this,
    initialIndex: widget.selectedIndex.clamp(0, widget.tabs.length - 1),
  )..addListener(_handleControllerChange);

  List<GlobalKey> _createPageKeys() =>
      List.generate(widget.tabs.length, (_) => GlobalKey());

  @override
  void didUpdateWidget(covariant InfoProfileTabScaffold oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tabs.length != widget.tabs.length) {
      _tabController.removeListener(_handleControllerChange);
      _tabController.dispose();
      _tabController = _createController();
      _pageScrollKeys = _createPageKeys();
      return;
    }

    final selected = _selectedIndex;
    if (!_tabController.indexIsChanging &&
        _tabController.offset.abs() < 0.001 &&
        _tabController.index != selected) {
      _syncingExternalSelection = true;
      try {
        _tabController.index = selected;
      } finally {
        _syncingExternalSelection = false;
      }
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleControllerChange);
    _tabController.dispose();
    _outerController.removeListener(_updateChrome);
    _outerController.dispose();
    _chromeProgress.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        NestedScrollView(
          key: _nestedScrollKey,
          controller: _outerController,
          physics: widget.nestedScrollPhysics,
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            SliverToBoxAdapter(child: widget.header),
            SliverToBoxAdapter(
              child: ValueListenableBuilder<double>(
                valueListenable: _chromeProgress,
                child: Column(
                  children: [
                    if (widget.tabsTopSpacing > 0)
                      SizedBox(height: widget.tabsTopSpacing),
                    KeyedSubtree(
                      key: _tabsKey,
                      child: InfoProfileTabs(
                        selectedIndex: _selectedIndex,
                        onTabSelected: _selectTab,
                        alwaysScrollable: widget.alwaysScrollable,
                        tabs: widget.tabs,
                        controller: _tabController,
                      ),
                    ),
                  ],
                ),
                builder: (context, progress, child) => Opacity(
                  opacity: PinnedInfoProfileTabs.inFlowTabsOpacityFor(progress),
                  child: child,
                ),
              ),
            ),
          ],
          body: _usesPages ? _buildPager() : _buildSelectedBody(),
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: ValueListenableBuilder<double>(
            valueListenable: _chromeProgress,
            builder: (context, progress, _) => PinnedInfoProfileTabs(
              tabs: widget.tabs,
              selectedIndex: _selectedIndex,
              onTabSelected: _selectTab,
              alwaysScrollable: widget.alwaysScrollable,
              progress: progress,
              controller: _tabController,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPager() {
    final pages = widget.pages!;
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _preparePageSwipe(),
      child: TabBarView(
        controller: _tabController,
        children: [
          for (var index = 0; index < pages.length; index++)
            KeyedSubtree(key: _pageScrollKeys[index], child: pages[index]),
        ],
      ),
    );
  }

  Widget _buildSelectedBody() {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onHorizontalDragEnd: _handleBodySwipe,
      child: KeyedSubtree(key: _bodyScrollKey, child: widget.body!),
    );
  }

  void _selectTab(int index) {
    final target = index.clamp(0, widget.tabs.length - 1);
    if (target == _tabController.index) return;
    if (_usesPages) {
      _tabController.animateTo(
        target,
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
      );
      return;
    }

    _prepareBodySelection();
    _tabController.index = target;
  }

  void _handleBodySwipe(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    if (velocity.abs() < 240) return;
    final target = velocity < 0 ? _selectedIndex + 1 : _selectedIndex - 1;
    if (target < 0 || target >= widget.tabs.length) return;
    _prepareBodySelection();
    _tabController.index = target;
  }

  void _prepareBodySelection() {
    final previousOuterOffset = _outerController.hasClients
        ? _outerController.offset
        : null;
    _resetBodyToTop();
    if (previousOuterOffset != null && _outerController.hasClients) {
      _outerController.jumpTo(
        previousOuterOffset
            .clamp(
              _outerController.position.minScrollExtent,
              _outerController.position.maxScrollExtent,
            )
            .toDouble(),
      );
    }
  }

  void _preparePageSwipe() {
    _updateChrome();
    for (var index = 0; index < _pageScrollKeys.length; index++) {
      if (index == _selectedIndex) continue;
      _resetPageToTop(index);
    }
  }

  void _handleControllerChange() {
    if (_syncingExternalSelection) return;
    final index = _tabController.index;
    if (index != _selectedIndex) {
      if (_usesPages) {
        _resetPageToTop(index);
        if (_chromeProgress.value >= 0.98) _snapOuterToPinThreshold();
      }
      widget.onTabSelected(index);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _updateChrome();
    });
  }

  void _resetBodyToTop() {
    final position = _scrollableStateBelow(_bodyScrollKey)?.position;
    if (position != null && position.hasPixels && position.pixels != 0) {
      position.jumpTo(0);
    }
  }

  void _resetPageToTop(int index) {
    final position = _scrollableStateBelow(_pageScrollKeys[index])?.position;
    if (position != null && position.hasPixels && position.pixels != 0) {
      position.jumpTo(0);
    }
  }

  ScrollableState? _scrollableStateBelow(GlobalKey key) {
    final context = key.currentContext;
    if (context is! Element) return null;
    ScrollableState? result;
    void findScrollable(Element element) {
      if (result != null) return;
      if (element is StatefulElement && element.state is ScrollableState) {
        final scrollable = element.state as ScrollableState;
        if (axisDirectionToAxis(scrollable.position.axisDirection) ==
            Axis.vertical) {
          result = scrollable;
          return;
        }
      }
      element.visitChildElements(findScrollable);
    }

    context.visitChildElements(findScrollable);
    return result;
  }

  void _updateChrome() {
    if (!mounted || !_outerController.hasClients) return;
    final tabsContext = _tabsKey.currentContext;
    if (tabsContext == null) return;
    final renderObject = tabsContext.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) return;

    final safeTop = MediaQuery.paddingOf(context).top;
    final tabsTop = renderObject.localToGlobal(Offset.zero).dy;
    final progress = ((safeTop + _chromeRamp - tabsTop) / _chromeRamp).clamp(
      0.0,
      1.0,
    );
    if ((_chromeProgress.value - progress).abs() >= 0.005) {
      _chromeProgress.value = progress;
    }
  }

  void _snapOuterToPinThreshold() {
    final outerController = _nestedScrollKey.currentState?.outerController;
    final tabsRenderObject = _tabsKey.currentContext?.findRenderObject();
    if (outerController == null ||
        !outerController.hasClients ||
        tabsRenderObject is! RenderBox ||
        !tabsRenderObject.hasSize) {
      return;
    }

    final safeTop = MediaQuery.paddingOf(context).top;
    final tabsTop = tabsRenderObject.localToGlobal(Offset.zero).dy;
    if (tabsTop > safeTop) return;
    final targetOffset = (outerController.offset + tabsTop - safeTop).clamp(
      outerController.position.minScrollExtent,
      outerController.position.maxScrollExtent,
    );
    outerController.jumpTo(targetOffset);
  }
}

class _InfoProfileTabsState extends State<InfoProfileTabs>
    with TickerProviderStateMixin {
  TabController? _internalController;

  TabController get _controller => widget.controller ?? _internalController!;

  @override
  void initState() {
    super.initState();
    if (widget.controller == null) {
      _internalController = _createController();
    }
  }

  TabController _createController() => TabController(
    length: widget.tabs.length,
    vsync: this,
    initialIndex: widget.selectedIndex.clamp(0, widget.tabs.length - 1),
  );

  @override
  void didUpdateWidget(covariant InfoProfileTabs oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      if (oldWidget.controller == null) {
        _internalController?.dispose();
      }
      _internalController = widget.controller == null
          ? _createController()
          : null;
    } else if (widget.controller == null &&
        oldWidget.tabs.length != widget.tabs.length) {
      _internalController?.dispose();
      _internalController = _createController();
    }

    // An externally supplied controller is the single motion source for both
    // the TabBar and its TabBarView. The owning screen advances it directly,
    // so starting a second animateTo here would make the indicator trail the
    // page during a swipe.
    if (widget.controller == null &&
        _controller.index != widget.selectedIndex) {
      _controller.animateTo(
        widget.selectedIndex,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  void dispose() {
    _internalController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // Fill mode gives each tab an equal-width column with its label centered
    // inside it, instead of bunching tabs together and centering the group.
    // Screens with too many tabs to fit opt into scrolling explicitly via
    // alwaysScrollable (game_assets_page, stats_page) rather than this
    // defaulting to scrollable on every mobile screen.
    final isScrollable = widget.alwaysScrollable;
    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
      elevation: 0,
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
            if (data.trailing case final trailing?) ...[
              const SizedBox(width: 2),
              trailing,
            ],
          ],
        ),
      ),
    );
  }
}
