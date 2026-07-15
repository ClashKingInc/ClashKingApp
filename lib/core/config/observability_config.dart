class ObservabilityConfig {
  ObservabilityConfig._();

  static const String _defaultBetterStackDsn =
      'https://6wB3LFzRuW4wyEj1MJVx3SvG@s2574992.eu-fsn-3.betterstackdata.com/2574992';
  static const String _dsn = String.fromEnvironment('CK_SENTRY_DSN');
  static const String _apiEnvironment = String.fromEnvironment(
    'CK_API_ENV',
    defaultValue: 'prod',
  );
  static const int _tracesSampleRatePercent = int.fromEnvironment(
    'CK_SENTRY_TRACES_SAMPLE_RATE_PERCENT',
    defaultValue: 0,
  );
  static const int _replaySessionSampleRatePercent = int.fromEnvironment(
    'CK_SENTRY_REPLAY_SESSION_SAMPLE_RATE_PERCENT',
    defaultValue: 0,
  );
  static const int _replayOnErrorSampleRatePercent = int.fromEnvironment(
    'CK_SENTRY_REPLAY_ON_ERROR_SAMPLE_RATE_PERCENT',
    defaultValue: 0,
  );

  static String get dsn {
    final override = _dsn.trim();
    return override.isNotEmpty ? override : _defaultBetterStackDsn;
  }

  static bool get isEnabled => dsn.isNotEmpty;

  static String get environment {
    return switch (_apiEnvironment.toLowerCase()) {
      'local' || 'dev' || 'development' => 'development',
      'prod' || 'production' => 'production',
      final value when value.isNotEmpty => value,
      _ => 'production',
    };
  }

  static double get tracesSampleRate =>
      _sampleRateFromPercent(_tracesSampleRatePercent);

  static double get replaySessionSampleRate =>
      _sampleRateFromPercent(_replaySessionSampleRatePercent);

  static double get replayOnErrorSampleRate =>
      _sampleRateFromPercent(_replayOnErrorSampleRatePercent);

  static double get replayErrorSampleRate => replayOnErrorSampleRate;

  static double _sampleRateFromPercent(int value) {
    final clamped = value.clamp(0, 100);
    return clamped / 100;
  }
}
