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
