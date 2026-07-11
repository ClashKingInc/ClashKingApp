import 'package:sentry_flutter/sentry_flutter.dart';

/// Reports each exception object once as it propagates through transport,
/// domain, and presentation layers. This keeps useful context without sending
/// duplicate Sentry events for the same failure.
abstract final class ErrorReporter {
  static final Expando<bool> _reported = Expando<bool>('sentry-reported');

  static void captureException(
    Object error, {
    StackTrace? stackTrace,
    String? operation,
  }) {
    if (!_markReported(error)) return;

    Sentry.captureException(
      error,
      stackTrace: stackTrace,
      withScope: operation == null
          ? null
          : (scope) => scope.setTag('operation', operation),
    );
  }

  static bool _markReported(Object error) {
    // Expandos cannot be attached to these canonical/value-like objects.
    if (error is String || error is num || error is bool || error is Record) {
      return true;
    }
    if (_reported[error] == true) return false;
    _reported[error] = true;
    return true;
  }
}
