import 'dart:async';
import 'dart:collection';

/// Maximum number of independent per-tag requests the app starts at once.
const int maxConcurrentTagRequests = 25;

final _sharedTagRequestLimiter = _AsyncRequestLimiter(maxConcurrentTagRequests);

class _AsyncRequestLimiter {
  _AsyncRequestLimiter(this.maxConcurrent);

  final int maxConcurrent;
  final Queue<void Function()> _pending = Queue<void Function()>();
  int _active = 0;

  Future<R> run<R>(FutureOr<R> Function() operation) {
    final completer = Completer<R>();

    void start() {
      _active++;
      unawaited(() async {
        try {
          completer.complete(await operation());
        } catch (error, stackTrace) {
          completer.completeError(error, stackTrace);
        } finally {
          _active--;
          if (_pending.isNotEmpty) _pending.removeFirst()();
        }
      }());
    }

    if (_active < maxConcurrent) {
      start();
    } else {
      _pending.addLast(start);
    }
    return completer.future;
  }
}

/// Maps [items] while keeping at most [maxConcurrent] operations in flight.
///
/// Results preserve input order. All queued work is allowed to finish before
/// the first error is rethrown, matching `Future.wait`'s non-eager behavior.
Future<List<R>> mapWithConcurrencyLimit<T, R>(
  Iterable<T> items,
  FutureOr<R> Function(T item) operation, {
  int maxConcurrent = maxConcurrentTagRequests,
}) async {
  if (maxConcurrent < 1) {
    throw ArgumentError.value(maxConcurrent, 'maxConcurrent', 'must be >= 1');
  }

  final values = items.toList(growable: false);
  if (values.isEmpty) return <R>[];
  final limiter = maxConcurrent == maxConcurrentTagRequests
      ? _sharedTagRequestLimiter
      : _AsyncRequestLimiter(maxConcurrent);

  final results = List<Object?>.filled(values.length, null);
  final errors = List<Object?>.filled(values.length, null);
  final stackTraces = List<StackTrace?>.filled(values.length, null);
  var nextIndex = 0;

  Future<void> worker() async {
    while (nextIndex < values.length) {
      final index = nextIndex++;
      try {
        results[index] = await limiter.run(() => operation(values[index]));
      } catch (error, stackTrace) {
        errors[index] = error;
        stackTraces[index] = stackTrace;
      }
    }
  }

  final workerCount = values.length < maxConcurrent
      ? values.length
      : maxConcurrent;
  await Future.wait(List.generate(workerCount, (_) => worker()));

  final errorIndex = errors.indexWhere((error) => error != null);
  if (errorIndex >= 0) {
    Error.throwWithStackTrace(errors[errorIndex]!, stackTraces[errorIndex]!);
  }
  return List<R>.generate(
    results.length,
    (index) => results[index] as R,
    growable: false,
  );
}
