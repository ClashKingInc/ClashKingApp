import {
  DEFAULT_BETTER_STACK_DSN,
  percentageRate,
  resolveObservabilityConfig,
  sentryEnvironment,
} from './observability-config';

describe('observability config', () => {
  it('uses the Better Stack defaults and package metadata', () => {
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
      dsn: DEFAULT_BETTER_STACK_DSN,
      environment: 'production',
      release: 'com.clashking.apps@0.3.5',
      dist: '25',
      tracesSampleRate: 0,
      replaysSessionSampleRate: 0,
      replaysOnErrorSampleRate: 0,
    });
  });

  it('honors the public DSN override and clamps percentage rates', () => {
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
      tracesSampleRate: 1,
      replaysSessionSampleRate: 0,
      replaysOnErrorSampleRate: 0.025,
    });
  });

  it('maps API environments and treats invalid percentages as zero', () => {
    expect(sentryEnvironment('local')).toBe('development');
    expect(sentryEnvironment('development')).toBe('development');
    expect(sentryEnvironment('production')).toBe('production');
    expect(sentryEnvironment('preview')).toBe('preview');
    expect(percentageRate('not-a-number')).toBe(0);
  });
});
