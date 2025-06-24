import 'package:clashkingapp/common/widgets/mobile_web_image.dart';
import 'package:flutter/material.dart';
import 'dart:async';

class ImageChip extends StatefulWidget {
  final String imageUrl;
  final String label;
  final Widget labelWidget;
  final double labelPadding;
  final String? description;
  final Color? textColor;
  final Color? edgeColor;
  final BuildContext? context;
  final GestureTapCallback? onTap;

  ImageChip({
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
      _timer = Timer(Duration(seconds: 5), () {
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

  Widget _buildChip(Color textColor, Color edgeColor) {
    return Chip(
      avatar: CircleAvatar(
        backgroundColor: Colors.transparent,
        child: MobileWebImage(
          imageUrl: widget.imageUrl,
          fit: BoxFit.cover,
        ),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: edgeColor),
      ),
      labelPadding: EdgeInsets.symmetric(horizontal: widget.labelPadding),
      label: widget.label.isNotEmpty
          ? Text(
              widget.label,
              style: Theme.of(context)
                  .textTheme
                  .labelLarge
                  ?.copyWith(color: textColor),
            )
          : widget.labelWidget,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        widget.textColor ?? Theme.of(context).colorScheme.onSurface;
    final edgeColor = widget.edgeColor ??
        (isDarkMode
            ? Colors.white.withValues(alpha: 0.2)
            : Colors.black.withValues(alpha: 0.2));
    return GestureDetector(
        onTap: widget.description != null ? _toggleTooltip : widget.onTap,
        child: widget.description != null
            ? Tooltip(
                textAlign: TextAlign.center,
                key: _tooltipKey,
                message: widget.description,
                textStyle: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: Theme.of(context).colorScheme.onSurface),
                showDuration: Duration(seconds: 5),
                margin: EdgeInsets.symmetric(horizontal: 64),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .scaffoldBackgroundColor
                      .withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      spreadRadius: 2,
                      blurRadius: 2,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
                child: _buildChip(textColor, edgeColor),
              )
            : _buildChip(textColor, edgeColor));
  }
}

class IconChip extends StatefulWidget {
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

  IconChip({
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
      _timer = Timer(Duration(seconds: 5), () {
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

  Widget _buildChip(Color textColor, Color edgeColor, Color actualColor) {
    return Chip(
      avatar: CircleAvatar(
        backgroundColor: Colors.transparent,
        child:
            Icon(widget.icon, size: widget.size.toDouble(), color: actualColor),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: edgeColor),
      ),
      labelPadding: EdgeInsets.symmetric(horizontal: widget.labelPadding),
      label: Text(widget.label,
          style: Theme.of(context)
              .textTheme
              .labelLarge
              ?.copyWith(color: textColor)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final actualColor = widget.color ?? Theme.of(context).colorScheme.onSurface;
    final textColor =
        widget.textColor ?? Theme.of(context).colorScheme.onSurface;
    final edgeColor = widget.edgeColor ??
        (Theme.of(context).brightness == Brightness.dark
            ? Colors.white.withValues(alpha: 0.2)
            : Colors.black.withValues(alpha: 0.2));
    return GestureDetector(
      onTap: widget.description != null ? _toggleTooltip : widget.onTap,
      child: widget.description != null
          ? Tooltip(
              textAlign: TextAlign.center,
              key: _tooltipKey,
              message: widget.description,
              textStyle: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Theme.of(context).colorScheme.onSurface),
              margin: EdgeInsets.symmetric(horizontal: 64),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .scaffoldBackgroundColor
                    .withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    spreadRadius: 2,
                    blurRadius: 2,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
              child: _buildChip(
                textColor,
                edgeColor,
                actualColor,
              ),
            )
          : _buildChip(
              textColor,
              edgeColor,
              actualColor,
            ),
    );
  }
}

class CustomChip extends StatefulWidget {
  final Widget icon;
  final String label;
  final int size;
  final Color? color;
  final Color? edgeColor;
  final double labelPadding;
  final String description;

  CustomChip({
    required this.icon,
    required this.label,
    this.size = 24,
    this.color,
    this.edgeColor,
    this.labelPadding = 2,
    this.description = '',
  });

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
      _timer = Timer(Duration(seconds: 5), () {
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
    final edgeColor = widget.edgeColor ??
        (Theme.of(context).brightness == Brightness.dark
            ? Colors.white.withValues(alpha: 0.2)
            : Colors.black.withValues(alpha: 0.2));
    return GestureDetector(
      onTap: _toggleTooltip,
      child: Tooltip(
        textAlign: TextAlign.center,
        key: _tooltipKey,
        message: widget.description,
        textStyle: Theme.of(context)
            .textTheme
            .bodyMedium
            ?.copyWith(color: Theme.of(context).colorScheme.onSurface),
        margin: EdgeInsets.symmetric(horizontal: 64),
        decoration: BoxDecoration(
          color:
              Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              spreadRadius: 2,
              blurRadius: 2,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Chip(
          avatar: CircleAvatar(
              backgroundColor: Colors.transparent, child: widget.icon),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: edgeColor),
          ),
          labelPadding: EdgeInsets.symmetric(horizontal: widget.labelPadding),
          label:
              Text(widget.label, style: Theme.of(context).textTheme.labelLarge),
        ),
      ),
    );
  }
}
