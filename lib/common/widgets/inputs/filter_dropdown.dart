import 'package:flutter/material.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:lucide_icons/lucide_icons.dart';

class FilterDropdown extends StatelessWidget {
  final String sortBy;
  final Function(String) updateSortBy;
  final Map<dynamic, String> sortByOptions;

  FilterDropdown({required this.sortBy, required this.updateSortBy, required this.sortByOptions});

  @override
  Widget build(BuildContext context) {
    return DropdownButton2<String>(
      value: sortBy,
      items: sortByOptions.entries.map((entry) {
        return DropdownMenuItem<String>(
          value: entry.value,
          child: entry.key is String
            ? Center(child: Text(entry.key),)
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: entry.key as List<Widget>
              ),
        );
      }).toList(),
      alignment: Alignment.center,
      onChanged: (String? newValue) {
        updateSortBy(newValue!);
      },
      style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
      underline: Container(),
      buttonStyleData: ButtonStyleData(
        height: 40,
        padding: EdgeInsets.only(left: 14, right: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: Theme.of(context).colorScheme.surface,
        ),
        elevation: 2,
      ),
      iconStyleData: IconStyleData(
        icon: Icon(LucideIcons.arrowDown),
        iconSize: 16,
        iconEnabledColor: Theme.of(context).colorScheme.primary,
        iconDisabledColor: Theme.of(context).colorScheme.tertiary,
      ),
      dropdownStyleData: DropdownStyleData(
        elevation: 16,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(10),
        ),
        scrollbarTheme: ScrollbarThemeData(
          radius: const Radius.circular(40),
          thickness: WidgetStateProperty.all(6),
          thumbVisibility: WidgetStateProperty.all(true),
        ),
      ),
      menuItemStyleData: const MenuItemStyleData(
        height: 40,
        padding: EdgeInsets.only(left: 14, right: 14),
      ),
    );
  }
}
