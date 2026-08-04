import 'package:clashkingapp/common/theme/app_tokens.dart';
import 'package:flutter/material.dart';
import 'package:dropdown_button2/dropdown_button2.dart';

class FilterDropdown extends StatefulWidget {
  final String sortBy;
  final Function(String) updateSortBy;
  final Map<dynamic, String> sortByOptions;
  final double? maxWidth;
  final double height;
  final IconData? leadingIcon;
  final bool fillWidth;
  final Widget? customButton;

  const FilterDropdown({
    super.key,
    required this.sortBy,
    required this.updateSortBy,
    required this.sortByOptions,
    this.maxWidth,
    this.height = 40,
    this.leadingIcon,
    this.fillWidth = false,
    this.customButton,
  });

  @override
  State<FilterDropdown> createState() => _FilterDropdownState();
}

class _FilterDropdownState extends State<FilterDropdown> {
  late final ValueNotifier<String?> _valueNotifier;

  @override
  void initState() {
    super.initState();
    _valueNotifier = ValueNotifier(widget.sortBy);
  }

  @override
  void didUpdateWidget(FilterDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sortBy != widget.sortBy) {
      _valueNotifier.value = widget.sortBy;
    }
  }

  @override
  void dispose() {
    _valueNotifier.dispose();
    super.dispose();
  }

  Widget _buildLabel(
    BuildContext context,
    dynamic label, {
    required bool isSelected,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textStyle = TextStyle(
      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
    );

    if (label is! String) {
      return DefaultTextStyle.merge(
        style: textStyle,
        child: Row(children: label as List<Widget>),
      );
    }

    if (widget.leadingIcon == null) {
      return Text(
        label,
        maxLines: 1,
        softWrap: false,
        overflow: TextOverflow.ellipsis,
        style: textStyle,
      );
    }

    return Row(
      children: [
        Icon(widget.leadingIcon, size: 16, color: colorScheme.onSurfaceVariant),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.ellipsis,
            style: textStyle,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.fillWidth) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth.isFinite
              ? constraints.maxWidth
              : widget.maxWidth ?? 240;
          return _buildDropdown(context, width);
        },
      );
    }

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: widget.maxWidth ?? 240),
      child: _buildDropdown(context, widget.maxWidth ?? 240),
    );
  }

  Widget _buildDropdown(BuildContext context, double width) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      height: widget.height,
      width: widget.fillWidth ? double.infinity : null,
      child: DropdownButton2<String>(
        isExpanded: true,
        customButton: widget.customButton,
        valueListenable: _valueNotifier,
        items: widget.sortByOptions.entries.map((entry) {
          final isSelected = entry.value == widget.sortBy;

          return DropdownItem<String>(
            value: entry.value,
            height: widget.height,
            child: Container(
              width: double.infinity,
              height: widget.height - 4,
              alignment: AlignmentDirectional.centerStart,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: isSelected
                    ? colorScheme.surfaceContainerHighest.withValues(
                        alpha: 0.74,
                      )
                    : null,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildLabel(
                      context,
                      entry.key,
                      isSelected: isSelected,
                    ),
                  ),
                  if (isSelected)
                    Icon(
                      Icons.check_rounded,
                      size: 16,
                      color: colorScheme.onSurface,
                    ),
                ],
              ),
            ),
          );
        }).toList(),
        selectedItemBuilder: (context) =>
            widget.sortByOptions.entries.map((entry) {
              return _buildLabel(context, entry.key, isSelected: false);
            }).toList(),
        alignment: Alignment.center,
        onChanged: (String? newValue) {
          if (newValue != null) {
            _valueNotifier.value = newValue;
            widget.updateSortBy(newValue);
          }
        },
        style: TextStyle(color: colorScheme.onSurface),
        underline: Container(),
        buttonStyleData: ButtonStyleData(
          height: widget.height,
          padding: const EdgeInsets.only(left: 14, right: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.chip),
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.32),
            ),
          ),
        ),
        iconStyleData: IconStyleData(
          icon: const Icon(Icons.keyboard_arrow_down_rounded),
          iconSize: 16,
          // Not colorScheme.primary: this app's brand red doesn't clear
          // 4.5:1 contrast against a dark surface — onSurface always does.
          iconEnabledColor: colorScheme.onSurface,
          iconDisabledColor: colorScheme.tertiary,
        ),
        dropdownStyleData: DropdownStyleData(
          width: width,
          maxHeight: 320,
          elevation: 4,
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(AppRadius.chip),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.32),
            ),
          ),
          scrollbarTheme: ScrollbarThemeData(
            thickness: WidgetStateProperty.all(0),
            thumbVisibility: WidgetStateProperty.all(false),
            trackVisibility: WidgetStateProperty.all(false),
          ),
        ),
        menuItemStyleData: const MenuItemStyleData(
          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        ),
      ),
    );
  }
}
