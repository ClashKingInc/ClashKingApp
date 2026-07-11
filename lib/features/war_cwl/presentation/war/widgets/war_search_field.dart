import 'package:clashkingapp/common/widgets/liquid_glass.dart';
import 'package:flutter/material.dart';

class WarSearchField extends StatelessWidget {
  final TextEditingController controller;
  final String query;
  final String hintText;

  const WarSearchField({
    super.key,
    required this.controller,
    required this.query,
    required this.hintText,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      height: 44,
      child: Stack(
        fit: StackFit.expand,
        children: [
          LiquidGlassBar(
            height: 44,
            cornerRadius: 22,
            borderOpacity: Theme.of(context).brightness == Brightness.dark
                ? 0.22
                : 0.30,
            shadowOpacity: Theme.of(context).brightness == Brightness.dark
                ? 0.22
                : 0.08,
          ),
          TextField(
            controller: controller,
            textInputAction: TextInputAction.search,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
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
                      tooltip: MaterialLocalizations.of(
                        context,
                      ).deleteButtonTooltip,
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
    );
  }
}
