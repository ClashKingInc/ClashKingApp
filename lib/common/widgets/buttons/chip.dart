import 'package:clashkingapp/common/widgets/mobile_web_image.dart';
import 'package:flutter/material.dart';
import 'dart:async';

class ImageChip extends StatefulWidget {
  final String imageUrl;
  final String label;
  final Widget labelWidget;
  final double labelPadding;
  final String description;
  final Color? textColor;

  ImageChip({
    required this.imageUrl,
    this.label = '',
    this.labelWidget = const SizedBox(),
    this.labelPadding = 4,
    this.description = '',
    this.textColor,
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

  @override
  Widget build(BuildContext context) {
    final textColor =
        widget.textColor ?? Theme.of(context).colorScheme.onSurface;
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
        showDuration: Duration(seconds: 5),
        margin: EdgeInsets.symmetric(horizontal: 64),
        decoration: BoxDecoration(
          color:
              Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.9),
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
        child: Chip(
          avatar: CircleAvatar(
            backgroundColor: Colors.transparent,
            child: MobileWebImage(
              imageUrl: widget.imageUrl,
              fit: BoxFit.cover,
            ),
          ),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4))),
          labelPadding: EdgeInsets.symmetric(horizontal: widget.labelPadding),
          label: widget.label.isNotEmpty
              ? Text(widget.label,
                  style: Theme.of(context)
                      .textTheme
                      .labelLarge
                      ?.copyWith(color: textColor))
              : widget.labelWidget,
        ),
      ),
    );
  }
}

class IconChip extends StatefulWidget {
  final IconData icon;
  final String label;
  final int size;
  final Color? color;
  final double labelPadding;
  final String description;
  final Color? textColor; // Mark as final

  IconChip({
    required this.icon,
    required this.label,
    this.size = 24,
    this.color,
    this.labelPadding = 2,
    this.description = '',
    this.textColor,
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

  @override
  Widget build(BuildContext context) {
    final actualColor = widget.color ?? Theme.of(context).colorScheme.onSurface;
    final textColor =
        widget.textColor ?? Theme.of(context).colorScheme.onSurface;
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
            backgroundColor: Colors.transparent,
            child: Icon(widget.icon,
                size: widget.size.toDouble(), color: actualColor),
          ),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4))),
          labelPadding: EdgeInsets.symmetric(horizontal: widget.labelPadding),
          label: Text(widget.label,
              style: Theme.of(context)
                  .textTheme
                  .labelLarge
                  ?.copyWith(color: textColor)),
        ),
      ),
    );
  }
}

class CustomChip extends StatefulWidget {
  final Widget icon;
  final String label;
  final int size;
  final Color? color;
  final double labelPadding;
  final String description;

  CustomChip({
    required this.icon,
    required this.label,
    this.size = 24,
    this.color,
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
          labelPadding: EdgeInsets.symmetric(horizontal: widget.labelPadding),
          label:
              Text(widget.label, style: Theme.of(context).textTheme.labelLarge),
        ),
      ),
    );
  }
}
