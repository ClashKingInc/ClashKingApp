import 'package:clashkingapp/common/widgets/inputs/filter_dropdown.dart';
import 'package:clashkingapp/common/widgets/native_liquid_glass.dart';
import 'package:flutter/material.dart';

class ClanSummaryChips extends StatelessWidget {
  final List<Widget> children;
  final EdgeInsetsGeometry padding;
  final WrapAlignment alignment;
  final bool scrollable;

  const ClanSummaryChips({
    super.key,
    required this.children,
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
    this.alignment = WrapAlignment.center,
    this.scrollable = true,
  });

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();

    if (scrollable) {
      return Padding(
        padding: padding,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var index = 0; index < children.length; index++) ...[
                children[index],
                if (index < children.length - 1) const SizedBox(width: 6),
              ],
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: padding,
      child: Wrap(
        alignment: alignment,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 6,
        runSpacing: 6,
        children: children,
      ),
    );
  }
}

class ClanFilterRail extends StatelessWidget {
  final List<Widget> children;
  final EdgeInsetsGeometry padding;

  const ClanFilterRail({
    super.key,
    required this.children,
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
  });

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: padding,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var index = 0; index < children.length; index++) ...[
              children[index],
              if (index < children.length - 1) const SizedBox(width: 8),
            ],
          ],
        ),
      ),
    );
  }
}

class ClanFilterChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool selected;
  final VoidCallback onTap;
  final Color? color;

  const ClanFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final accent = color ?? colorScheme.primary;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        splashFactory: NoSplash.splashFactory,
        onTap: onTap,
        child: Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 11),
          decoration: BoxDecoration(
            color: selected
                ? accent.withValues(alpha: 0.16)
                : colorScheme.surfaceContainerHighest.withValues(alpha: 0.38),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected
                  ? accent.withValues(alpha: 0.42)
                  : colorScheme.outlineVariant.withValues(alpha: 0.28),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 15,
                  color: selected ? accent : colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 5),
              ],
              Text(
                label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
                  height: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ClanSummaryChip extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;
  final IconData? icon;
  final VoidCallback? onTap;
  final bool selected;

  const ClanSummaryChip({
    super.key,
    required this.label,
    required this.value,
    this.color,
    this.icon,
    this.onTap,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final accent = color ?? colorScheme.primary;
    final backgroundAlpha = selected ? 0.18 : 0.12;
    final borderAlpha = selected ? 0.38 : 0.20;

    final child = Container(
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: backgroundAlpha),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accent.withValues(alpha: borderAlpha)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon ?? Icons.circle_rounded,
            size: icon == null ? 10 : 14,
            color: accent,
          ),
          const SizedBox(width: 5),
          Text(
            value,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
          const SizedBox(width: 3),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
              height: 1,
            ),
          ),
        ],
      ),
    );

    if (onTap == null) return child;

    return Tooltip(
      message: label,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          splashFactory: NoSplash.splashFactory,
          onTap: onTap,
          child: child,
        ),
      ),
    );
  }
}

class ClanTabSearchSortBar extends StatefulWidget {
  final TextEditingController controller;
  final String query;
  final String hintText;
  final String sortBy;
  final ValueChanged<String> updateSortBy;
  final Map<String, String> sortByOptions;
  final double maxSortWidth;
  final EdgeInsetsGeometry padding;
  final Widget? leading;
  final Widget? trailing;

  const ClanTabSearchSortBar({
    super.key,
    required this.controller,
    required this.query,
    required this.hintText,
    required this.sortBy,
    required this.updateSortBy,
    required this.sortByOptions,
    this.maxSortWidth = 140,
    this.padding = const EdgeInsets.fromLTRB(16, 0, 16, 8),
    this.leading,
    this.trailing,
  });

  @override
  State<ClanTabSearchSortBar> createState() => _ClanTabSearchSortBarState();
}

class _ClanTabSearchSortBarState extends State<ClanTabSearchSortBar> {
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode()..addListener(_handleFocusChanged);
  }

  @override
  void dispose() {
    _focusNode
      ..removeListener(_handleFocusChanged)
      ..dispose();
    super.dispose();
  }

  void _handleFocusChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isFocused = _focusNode.hasFocus;

    return Padding(
      padding: widget.padding,
      child: Row(
        children: [
          if (widget.leading != null) ...[
            widget.leading!,
            const SizedBox(width: 10),
          ],
          Expanded(
            child: SizedBox(
              height: 44,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  IgnorePointer(
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 140),
                      opacity: isFocused ? 1 : 0,
                      child: NativeLiquidGlassBar(
                        height: 44,
                        cornerRadius: 22,
                        borderOpacity:
                            Theme.of(context).brightness == Brightness.dark
                            ? 0.22
                            : 0.30,
                        shadowOpacity:
                            Theme.of(context).brightness == Brightness.dark
                            ? 0.22
                            : 0.08,
                      ),
                    ),
                  ),
                  TextField(
                    controller: widget.controller,
                    focusNode: _focusNode,
                    textInputAction: TextInputAction.search,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface,
                    ),
                    decoration: InputDecoration(
                      hintText: widget.hintText,
                      hintStyle: Theme.of(context).textTheme.bodyMedium
                          ?.copyWith(color: colorScheme.onSurfaceVariant),
                      isDense: true,
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        size: 20,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      prefixIconConstraints: const BoxConstraints(
                        minWidth: 40,
                        minHeight: 44,
                      ),
                      suffixIcon: widget.query.isNotEmpty
                          ? IconButton(
                              icon: Icon(
                                Icons.close_rounded,
                                size: 18,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              onPressed: widget.controller.clear,
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          FilterDropdown(
            sortBy: widget.sortBy,
            updateSortBy: widget.updateSortBy,
            sortByOptions: widget.sortByOptions,
            maxWidth: widget.maxSortWidth,
          ),
          if (widget.trailing != null) ...[
            const SizedBox(width: 10),
            widget.trailing!,
          ],
        ],
      ),
    );
  }
}
