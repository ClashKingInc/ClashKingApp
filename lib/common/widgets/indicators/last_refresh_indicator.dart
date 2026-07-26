import 'dart:async';
import 'package:flutter/material.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

class LastRefreshIndicator extends StatefulWidget {
  final DateTime? lastRefresh;

  /// Optional: makes the indicator tappable. Without it the widget keeps its
  /// original read-only behaviour.
  final Future<void> Function()? onRefresh;

  const LastRefreshIndicator({
    super.key,
    required this.lastRefresh,
    this.onRefresh,
  });

  @override
  State<LastRefreshIndicator> createState() => _LastRefreshIndicatorState();
}

class _LastRefreshIndicatorState extends State<LastRefreshIndicator> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void didUpdateWidget(LastRefreshIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.lastRefresh != widget.lastRefresh) {
      _startTimer();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    // Update every minute to keep time relative displays current
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  String _formatRefreshTime(DateTime dateTime, BuildContext context) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    final localizations = AppLocalizations.of(context)!;

    if (difference.inMinutes < 1) {
      return localizations.timeJustNow;
    } else if (difference.inMinutes < 60) {
      return localizations.timeMinutesAgo(difference.inMinutes);
    } else if (difference.inHours < 24) {
      return localizations.timeHoursAgo(difference.inHours);
    } else {
      return DateFormat('MMM d, HH:mm').format(dateTime);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.lastRefresh == null) {
      return const SizedBox.shrink();
    }

    final formattedTime = _formatRefreshTime(widget.lastRefresh!, context);

    final colorScheme = Theme.of(context).colorScheme;
    final label = AppLocalizations.of(
      context,
    )!.generalLastRefresh(formattedTime);

    final row = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.refresh,
            size: 12,
            color: colorScheme.onSurface.withValues(alpha: 0.6),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );

    // The refresh glyph made this look actionable while it was inert, so the
    // obvious tap did nothing and pull-to-refresh had to be discovered. When
    // a caller wires [onRefresh] it becomes the button it already looked like.
    if (widget.onRefresh == null) return Center(child: row);

    return Center(
      child: Semantics(
        button: true,
        label: label,
        child: InkWell(
          onTap: widget.onRefresh,
          borderRadius: BorderRadius.circular(999),
          child: row,
        ),
      ),
    );
  }
}
