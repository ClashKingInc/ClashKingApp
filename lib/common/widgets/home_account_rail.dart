import 'package:clashking_design_system/clashking_design_system.dart';
import 'package:clashkingapp/common/widgets/mobile_web_image.dart';
import 'package:flutter/material.dart';

/// One entry of a [HomeAccountRail].
class HomeAccountRailEntry {
  const HomeAccountRailEntry({
    required this.label,
    this.imageUrl,
    this.fallbackIcon,
    this.hasPendingActions,
  });

  /// Identifies the entry — shown when selected, and always exposed to
  /// tooltips and screen readers.
  final String label;

  final String? imageUrl;
  final IconData? fallbackIcon;

  /// Drives the badge on the avatar: red when something is still expected of
  /// this account, green when it's settled, nothing when unknown.
  ///
  /// This is the one place a status dot earns its keep — an avatar carries no
  /// text, so the badge answers "who still has something to do" without
  /// opening each account in turn, which is precisely what the pager could
  /// never show.
  final bool? hasPendingActions;
}

/// Account switcher in a home card's header, in place of pager dots.
///
/// Dots only said "there are 4 pages": finding a given account meant swiping
/// through the others and back, and nothing said which page was whose. The
/// rail names them and jumps straight there.
///
/// Only the selected entry expands to show its label. Several accounts
/// commonly share a town hall level, so the artwork alone can't tell them
/// apart — but a label under every avatar made the rail wide and ragged, so
/// the unselected ones stay plain circles and are identified by tapping,
/// which is how you switch account anyway.
///
/// Past a handful of entries the rail scrolls horizontally. That stays
/// workable because the order is the one the user set in account management,
/// so a given account's position is stable and learnable.
class HomeAccountRail extends StatelessWidget {
  const HomeAccountRail({
    super.key,
    required this.entries,
    required this.selectedIndex,
    required this.onSelect,
  });

  final List<HomeAccountRailEntry> entries;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  /// Height the rail occupies — home cards size their headers against this.
  ///
  /// The visible pill stays [_pillHeight]; the rest is invisible padding that
  /// brings the tap target to the 44pt/48dp minimum. Sizing the row to the
  /// pill alone made every account a 28px target, worse than the 42px
  /// `HeaderIconButton` the design system already flags as too small.
  static const double height = 44;

  static const double _pillHeight = 28;

  /// Keeps one long account name from pushing the rest of the rail off-screen.
  static const double _maxLabelWidth = 92;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) return const SizedBox.shrink();

    // A single account still gets its pill, just not as a control: hiding the
    // rail outright left the card with no name and no town hall at all, since
    // the ring had taken the artwork's place. It reads as a label rather than
    // a switcher because there is nothing to switch to.
    if (entries.length == 1) {
      return SizedBox(
        height: height,
        child: Align(
          alignment: Alignment.centerLeft,
          child: _RailItem(entry: entries.first, selected: true, onTap: null),
        ),
      );
    }

    return SizedBox(
      height: height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        // Always accept the horizontal drag, even when every entry already
        // fits. Otherwise the rail declines the gesture, it bubbles up to the
        // app's main PageView, and trying to check for more accounts silently
        // navigates to the Players tab instead.
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        itemCount: entries.length,
        separatorBuilder: (context, index) => const SizedBox(width: 4),
        itemBuilder: (context, index) => _RailItem(
          entry: entries[index],
          selected: index == selectedIndex,
          onTap: () => onSelect(index),
        ),
      ),
    );
  }
}

/// Small badge on an avatar's corner: red while the account still has
/// something to do, green once it's settled.
///
/// Ringed in the card's own surface colour so it stays legible whatever the
/// town hall artwork behind it looks like.
class _PendingBadge extends StatelessWidget {
  const _PendingBadge({required this.pending});

  final bool pending;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: 9,
      height: 9,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        // Filled when something is pending, hollow once settled: red and
        // green sit on the commonest colour-blindness axis, so the state has
        // to survive without the hue.
        color: pending ? CKColors.lossRed : Colors.transparent,
        border: Border.all(
          color: pending ? colorScheme.surface : CKColors.donationGreen,
          width: pending ? 1.4 : 2,
        ),
      ),
    );
  }
}

class _RailItem extends StatelessWidget {
  const _RailItem({
    required this.entry,
    required this.selected,
    required this.onTap,
  });

  final HomeAccountRailEntry entry;
  final bool selected;

  /// Null when the rail holds a single account: the pill is then a label, so
  /// it must not advertise a tap that would do nothing.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final fallback = Icon(
      entry.fallbackIcon ?? Icons.person_rounded,
      size: 16,
      color: colorScheme.onSurfaceVariant,
    );

    return Tooltip(
      message: entry.label,
      child: Semantics(
        button: onTap != null,
        selected: selected,
        label: entry.label,
        child: InkResponse(
          onTap: onTap,
          radius: HomeAccountRail.height * 0.7,
          child: SizedBox(
            height: HomeAccountRail.height,
            child: Center(
              child: Container(
                height: HomeAccountRail._pillHeight,
                padding: EdgeInsets.only(right: selected ? 9 : 0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(CKRadius.pill),
                  color: colorScheme.surfaceContainerHighest.withValues(
                    alpha: selected ? 0.55 : 0.25,
                  ),
                  border: Border.all(
                    color: selected
                        ? colorScheme.primary
                        : colorScheme.outlineVariant.withValues(alpha: 0.24),
                    width: selected ? 1.6 : 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox.square(
                      dimension: HomeAccountRail._pillHeight - 2,
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: Opacity(
                              // Unselected entries recede so the rail reads as one
                              // control rather than a row of equal buttons.
                              opacity: selected ? 1 : 0.5,
                              child: Padding(
                                padding: const EdgeInsets.all(3),
                                child: entry.imageUrl != null
                                    ? MobileWebImage(
                                        imageUrl: entry.imageUrl!,
                                        fit: BoxFit.contain,
                                        errorWidget: (context, url, error) =>
                                            fallback,
                                      )
                                    : fallback,
                              ),
                            ),
                          ),
                          if (entry.hasPendingActions != null)
                            Positioned(
                              right: 0,
                              top: 0,
                              child: _PendingBadge(
                                pending: entry.hasPendingActions!,
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (selected) ...[
                      const SizedBox(width: 5),
                      ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: HomeAccountRail._maxLabelWidth,
                        ),
                        child: Text(
                          entry.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(
                                color: colorScheme.onSurface,
                                fontWeight: FontWeight.w900,
                                height: 1,
                              ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
