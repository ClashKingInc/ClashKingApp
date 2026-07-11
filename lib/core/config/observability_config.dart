abstract final class ObservabilityConfig {
  static double get tracesSampleRate => _parseRate(
    const String.fromEnvironment(
      'SENTRY_TRACES_SAMPLE_RATE',
      defaultValue: '0.10',
    ),
    0.10,
  );

  static double get replaySessionSampleRate => _parseRate(
    const String.fromEnvironment(
      'SENTRY_REPLAY_SESSION_SAMPLE_RATE',
      defaultValue: '0.01',
    ),
    0.01,
  );

  static double get replayErrorSampleRate => _parseRate(
    const String.fromEnvironment(
      'SENTRY_REPLAY_ERROR_SAMPLE_RATE',
      defaultValue: '0.25',
    ),
    0.25,
  );

  static double _parseRate(String value, double fallback) {
    return (double.tryParse(value) ?? fallback).clamp(0, 1).toDouble();
  }
}
