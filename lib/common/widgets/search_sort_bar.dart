import 'package:clashkingapp/common/widgets/inputs/filter_dropdown.dart';
import 'package:clashkingapp/common/widgets/native_liquid_glass.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// Standard search field + sort dropdown row for list-style tabs (clan
/// members, war log, war stats, capital raid members...). The glass
/// search field plus compact [FilterDropdown] combo used by every
/// searchable/sortable list in the app.
class ClanTabSearchSortBar extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: padding,
      child: Row(
        children: [
          if (leading != null) ...[leading!, const SizedBox(width: 10)],
          Expanded(
            child: SizedBox(
              height: 44,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  NativeLiquidGlassBar(
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
                  TextField(
                    controller: controller,
                    textInputAction: TextInputAction.search,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface,
                    ),
                    decoration: InputDecoration(
                      hintText: hintText,
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
                      suffixIcon: query.isNotEmpty
                          ? IconButton(
                              tooltip: AppLocalizations.of(
                                context,
                              )!.searchClear,
                              icon: Icon(
                                Icons.close_rounded,
                                size: 18,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              onPressed: controller.clear,
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
            sortBy: sortBy,
            updateSortBy: updateSortBy,
            sortByOptions: sortByOptions,
            maxWidth: maxSortWidth,
          ),
          if (trailing != null) ...[const SizedBox(width: 10), trailing!],
        ],
      ),
    );
  }
}
