import { resolveObservabilityConfig, sentryEnvironment } from './observability-config';

describe('observability config', () => {
  it('keeps reporting disabled without a dedicated DSN and uses package metadata', () => {
    expect(
      resolveObservabilityConfig(
        {},
        {
          packageName: 'com.clashking.apps',
          version: '0.3.5',
          buildNumber: '25',
        },
      ),
    ).toEqual({
      dsn: undefined,
      environment: 'production',
      release: 'com.clashking.apps@0.3.5',
      dist: '25',
      tracesSampleRate: undefined,
      profilesSampleRate: undefined,
      replaysSessionSampleRate: undefined,
      replaysOnErrorSampleRate: undefined,
      enableLogs: false,
      enableAutoSessionTracking: false,
      enableAutoPerformanceTracing: false,
      enableAppStartTracking: false,
      enableNativeFramesTracking: false,
      enableStallTracking: false,
      enableUserInteractionTracing: false,
    });
  });

  it('honors the dedicated DSN but ignores telemetry sampling overrides', () => {
    const config = resolveObservabilityConfig(
      {
        EXPO_PUBLIC_CK_SENTRY_DSN: ' https://example.test/1 ',
        EXPO_PUBLIC_CK_API_ENV: 'development',
        EXPO_PUBLIC_CK_SENTRY_TRACES_SAMPLE_RATE_PERCENT: '125',
        EXPO_PUBLIC_CK_SENTRY_REPLAY_SESSION_SAMPLE_RATE_PERCENT: '-4',
        EXPO_PUBLIC_CK_SENTRY_REPLAY_ON_ERROR_SAMPLE_RATE_PERCENT: '2.5',
      },
      { packageName: 'app', version: '1' },
    );
    expect(config).toMatchObject({
      dsn: 'https://example.test/1',
      environment: 'development',
      tracesSampleRate: undefined,
      profilesSampleRate: undefined,
      replaysSessionSampleRate: undefined,
      replaysOnErrorSampleRate: undefined,
      enableLogs: false,
      enableAutoSessionTracking: false,
      enableAutoPerformanceTracing: false,
      enableAppStartTracking: false,
      enableNativeFramesTracking: false,
      enableStallTracking: false,
      enableUserInteractionTracing: false,
    });
  });

  it('maps API environments', () => {
    expect(sentryEnvironment('local')).toBe('development');
    expect(sentryEnvironment('development')).toBe('development');
    expect(sentryEnvironment('production')).toBe('production');
    expect(sentryEnvironment('preview')).toBe('preview');
  });
});
