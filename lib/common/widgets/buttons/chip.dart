import 'dart:async';

import 'package:clashkingapp/common/theme/app_tokens.dart';
import 'package:clashkingapp/common/widgets/mobile_web_image.dart';
import 'package:flutter/material.dart';

class _GlassChipShell extends StatelessWidget {
  const _GlassChipShell({
    required this.iconContent,
    this.label = '',
    this.labelWidget,
    this.labelStyle,
    this.labelGap = 6,
    this.tint,
    this.borderColorOverride,
  });

  final Widget iconContent;
  final String label;
  final Widget? labelWidget;
  final TextStyle? labelStyle;
  final double labelGap;
  final Color? tint;
  final Color? borderColorOverride;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(5, 4, 10, 4),
      decoration: BoxDecoration(
        color: tint != null
            ? tint!.withValues(alpha: 0.14)
            : colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(AppRadius.chip),
        border: Border.all(
          color:
              borderColorOverride ??
              colorScheme.outlineVariant.withValues(alpha: 0.32),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: colorScheme.surface.withValues(alpha: 0.72),
              shape: BoxShape.circle,
            ),
            child: SizedBox.square(
              dimension: 22,
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: FittedBox(fit: BoxFit.contain, child: iconContent),
              ),
            ),
          ),
          SizedBox(width: labelGap),
          labelWidget ??
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: labelStyle,
              ),
        ],
      ),
    );
  }
}

class ImageChip extends StatefulWidget {
  const ImageChip({
    super.key,
    required this.imageUrl,
    this.label = '',
    this.labelWidget = const SizedBox(),
    this.labelPadding = 4,
    this.description,
    this.textColor,
    this.edgeColor,
    this.context,
    this.onTap,
  });

  final String imageUrl;
  final String label;
  final Widget labelWidget;
  final double labelPadding;
  final String? description;
  final Color? textColor;
  final Color? edgeColor;
  final BuildContext? context;
  final GestureTapCallback? onTap;

  @override
  ImageChipState createState() => ImageChipState();
}

class ImageChipState extends State<ImageChip> {
  final GlobalKey<TooltipState> _tooltipKey = GlobalKey<TooltipState>();
  bool _isTooltipVisible = false;
  Timer? _timer;

  void _toggleTooltip() {
    final dynamic tooltip = _tooltipKey.currentState;
    if (_isTooltipVisible) {
      tooltip?.deactivate();
      _timer?.cancel();
    } else {
      tooltip?.ensureTooltipVisible();
      _timer = Timer(const Duration(seconds: 5), () {
        tooltip?.deactivate();
        setState(() {
          _isTooltipVisible = false;
        });
      });
    }
    setState(() {
      _isTooltipVisible = !_isTooltipVisible;
    });
  }

  Widget _buildChip(Color textColor, Color? borderColorOverride) {
    return _GlassChipShell(
      iconContent: MobileWebImage(imageUrl: widget.imageUrl, fit: BoxFit.cover),
      label: widget.label,
      labelWidget: widget.label.isEmpty ? widget.labelWidget : null,
      labelGap: widget.labelPadding,
      borderColorOverride: borderColorOverride,
      labelStyle: Theme.of(
        context,
      ).textTheme.labelLarge?.copyWith(color: textColor),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textColor =
        widget.textColor ?? Theme.of(context).colorScheme.onSurface;
    return GestureDetector(
      onTap: widget.description != null ? _toggleTooltip : widget.onTap,
      child: widget.description != null
          ? Tooltip(
              textAlign: TextAlign.center,
              key: _tooltipKey,
              message: widget.description,
              textStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
              showDuration: const Duration(seconds: 5),
              margin: const EdgeInsets.symmetric(horizontal: 64),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).scaffoldBackgroundColor.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(4),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    spreadRadius: 2,
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: _buildChip(textColor, widget.edgeColor),
            )
          : _buildChip(textColor, widget.edgeColor),
    );
  }
}

class IconChip extends StatefulWidget {
  const IconChip({
    super.key,
    required this.icon,
    required this.label,
    this.size = 24,
    this.color,
    this.labelPadding = 2,
    this.description,
    this.textColor,
    this.edgeColor,
    this.context,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final int size;
  final Color? color;
  final double labelPadding;
  final String? description;
  final Color? textColor;
  final Color? edgeColor;
  final BuildContext? context;
  final GestureTapCallback? onTap;

  @override
  IconChipState createState() => IconChipState();
}

class IconChipState extends State<IconChip> {
  final GlobalKey<TooltipState> _tooltipKey = GlobalKey<TooltipState>();
  bool _isTooltipVisible = false;
  Timer? _timer;

  void _toggleTooltip() {
    final tooltip = _tooltipKey.currentState;
    if (_isTooltipVisible) {
      tooltip?.deactivate();
      _timer?.cancel();
    } else {
      tooltip?.ensureTooltipVisible();
      _timer?.cancel();
      _timer = Timer(const Duration(seconds: 5), () {
        if (_isTooltipVisible) {
          tooltip?.deactivate();
          if (mounted) {
            setState(() {
              _isTooltipVisible = false;
            });
          }
        }
      });
    }
    setState(() {
      _isTooltipVisible = !_isTooltipVisible;
    });
  }

  Widget _buildChip(
    Color textColor,
    Color? borderColorOverride,
    Color actualColor,
  ) {
    return _GlassChipShell(
      iconContent: Icon(
        widget.icon,
        size: widget.size.toDouble(),
        color: actualColor,
      ),
      label: widget.label,
      labelGap: widget.labelPadding,
      tint: widget.color,
      borderColorOverride: borderColorOverride,
      labelStyle: Theme.of(
        context,
      ).textTheme.labelLarge?.copyWith(color: textColor),
    );
  }

  @override
  Widget build(BuildContext context) {
    final actualColor = widget.color ?? Theme.of(context).colorScheme.onSurface;
    final textColor =
        widget.textColor ?? Theme.of(context).colorScheme.onSurface;
    return GestureDetector(
      onTap: widget.description != null ? _toggleTooltip : widget.onTap,
      child: widget.description != null
          ? Tooltip(
              textAlign: TextAlign.center,
              key: _tooltipKey,
              message: widget.description,
              textStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
              margin: const EdgeInsets.symmetric(horizontal: 64),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).scaffoldBackgroundColor.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    spreadRadius: 2,
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: _buildChip(textColor, widget.edgeColor, actualColor),
            )
          : _buildChip(textColor, widget.edgeColor, actualColor),
    );
  }
}

class CustomChip extends StatefulWidget {
  const CustomChip({
    super.key,
    required this.icon,
    required this.label,
    this.size = 24,
    this.color,
    this.edgeColor,
    this.labelPadding = 2,
    this.description = '',
  });

  final Widget icon;
  final String label;
  final int size;
  final Color? color;
  final Color? edgeColor;
  final double labelPadding;
  final String description;

  @override
  CustomChipState createState() => CustomChipState();
}

class CustomChipState extends State<CustomChip> {
  final GlobalKey<TooltipState> _tooltipKey = GlobalKey<TooltipState>();
  bool _isTooltipVisible = false;
  Timer? _timer;

  void _toggleTooltip() {
    final tooltip = _tooltipKey.currentState;
    if (_isTooltipVisible) {
      tooltip?.deactivate();
      _timer?.cancel();
    } else {
      tooltip?.ensureTooltipVisible();
      _timer?.cancel();
      _timer = Timer(const Duration(seconds: 5), () {
        if (_isTooltipVisible) {
          tooltip?.deactivate();
          if (mounted) {
            setState(() {
              _isTooltipVisible = false;
            });
          }
        }
      });
    }
    setState(() {
      _isTooltipVisible = !_isTooltipVisible;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggleTooltip,
      child: Tooltip(
        textAlign: TextAlign.center,
        key: _tooltipKey,
        message: widget.description,
        textStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Theme.of(context).colorScheme.onSurface,
        ),
        margin: const EdgeInsets.symmetric(horizontal: 64),
        decoration: BoxDecoration(
          color: Theme.of(
            context,
          ).scaffoldBackgroundColor.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              spreadRadius: 2,
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: _GlassChipShell(
          iconContent: widget.icon,
          label: widget.label,
          labelGap: widget.labelPadding,
          tint: widget.color,
          borderColorOverride: widget.edgeColor,
          labelStyle: Theme.of(context).textTheme.labelLarge,
        ),
      ),
    );
  }
}
