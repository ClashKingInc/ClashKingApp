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
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: colorScheme.primary, width: 3),
            ),
          ),
          child: DropdownButton2<String>(
            isExpanded: true,
            barrierColor: Colors.transparent,
            barrierCoversButton: false,
            barrierBlocksInteraction: false,
            valueListenable: _valueNotifier,
            items: widget.sortByOptions.entries.map((entry) {
              return DropdownItem<String>(
                value: entry.value,
                height: 40,
                child: entry.key is String
                    ? Center(child: Text(entry.key))
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: entry.key as List<Widget>,
                      ),
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
              decoration: BoxDecoration(color: Colors.transparent),
              elevation: 0,
            ),
            iconStyleData: IconStyleData(
              icon: const Icon(LucideIcons.arrowDown),
              iconSize: 16,
              iconEnabledColor: colorScheme.primary,
              iconDisabledColor: colorScheme.tertiary,
            ),
            dropdownStyleData: DropdownStyleData(
              width: width,
              maxHeight: 320,
              offset: const Offset(0, -3),
              elevation: 16,
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.18),
                ),
              ),
              scrollbarTheme: ScrollbarThemeData(
                thickness: WidgetStateProperty.all(0),
                thumbVisibility: WidgetStateProperty.all(false),
              ),
            ),
            menuItemStyleData: const MenuItemStyleData(
              padding: EdgeInsets.only(left: 14, right: 14),
            ),
          ),
        ),
      ),
    );
  }
}
