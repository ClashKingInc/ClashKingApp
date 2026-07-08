import 'package:clashkingapp/common/theme/app_tokens.dart';
import 'package:flutter/material.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class FilterDropdown extends StatefulWidget {
  final String sortBy;
  final Function(String) updateSortBy;
  final Map<dynamic, String> sortByOptions;
  final double? maxWidth;

  const FilterDropdown({
    super.key,
    required this.sortBy,
    required this.updateSortBy,
    required this.sortByOptions,
    this.maxWidth,
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

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final width = widget.maxWidth ?? 240;

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: width),
      child: SizedBox(
        height: 40,
        child: DropdownButton2<String>(
          isExpanded: true,
          valueListenable: _valueNotifier,
          items: widget.sortByOptions.entries.map((entry) {
            final isSelected = entry.value == widget.sortBy;

            return DropdownItem<String>(
              value: entry.value,
              height: 40,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 6),
                decoration: BoxDecoration(
                  color: isSelected
                      ? colorScheme.surfaceContainerHighest.withValues(
                          alpha: 0.6,
                        )
                      : null,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: entry.key is String
                          ? Text(
                              entry.key,
                              maxLines: 1,
                              softWrap: false,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w400,
                              ),
                            )
                          : Row(children: entry.key as List<Widget>),
                    ),
                    if (isSelected)
                      Icon(
                        LucideIcons.check,
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
                return entry.key is String
                    ? Text(
                        entry.key,
                        maxLines: 1,
                        softWrap: false,
                        overflow: TextOverflow.ellipsis,
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: entry.key as List<Widget>,
                      );
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
            height: 40,
            padding: const EdgeInsets.only(left: 14, right: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.chip),
              color: colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.45,
              ),
              border: Border.all(
                color: colorScheme.outlineVariant.withValues(alpha: 0.32),
              ),
            ),
          ),
          iconStyleData: IconStyleData(
            icon: const Icon(LucideIcons.arrowDown),
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
      ),
    );
  }
}
