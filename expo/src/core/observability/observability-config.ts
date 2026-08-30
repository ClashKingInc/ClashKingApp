export const DEFAULT_BETTER_STACK_DSN =
  'https://6wB3LFzRuW4wyEj1MJVx3SvG@s2574992.eu-fsn-3.betterstackdata.com/2574992';

export interface ObservabilityEnvironment {
  readonly EXPO_PUBLIC_CK_SENTRY_DSN?: string;
  readonly EXPO_PUBLIC_CK_API_ENV?: string;
  readonly EXPO_PUBLIC_CK_SENTRY_TRACES_SAMPLE_RATE_PERCENT?: string;
  readonly EXPO_PUBLIC_CK_SENTRY_REPLAY_SESSION_SAMPLE_RATE_PERCENT?: string;
  readonly EXPO_PUBLIC_CK_SENTRY_REPLAY_ON_ERROR_SAMPLE_RATE_PERCENT?: string;
}

export interface ObservabilityMetadata {
  readonly packageName: string;
  readonly version: string;
  readonly buildNumber?: string;
}

export function resolveObservabilityConfig(
  environment: ObservabilityEnvironment,
  metadata: ObservabilityMetadata,
) {
  return {
    dsn: environment.EXPO_PUBLIC_CK_SENTRY_DSN?.trim() || DEFAULT_BETTER_STACK_DSN,
    environment: sentryEnvironment(environment.EXPO_PUBLIC_CK_API_ENV),
    release: `${metadata.packageName}@${metadata.version}`,
    dist: metadata.buildNumber?.trim() || undefined,
    tracesSampleRate: percentageRate(environment.EXPO_PUBLIC_CK_SENTRY_TRACES_SAMPLE_RATE_PERCENT),
    replaysSessionSampleRate: percentageRate(
      environment.EXPO_PUBLIC_CK_SENTRY_REPLAY_SESSION_SAMPLE_RATE_PERCENT,
    ),
    replaysOnErrorSampleRate: percentageRate(
      environment.EXPO_PUBLIC_CK_SENTRY_REPLAY_ON_ERROR_SAMPLE_RATE_PERCENT,
    ),
  };
}

export function sentryEnvironment(value: string | undefined): string {
  switch (value?.trim().toLowerCase()) {
    case 'local':
    case 'development':
      return 'development';
    case 'stage':
    case 'staging':
      return 'staging';
    case 'prod':
    case 'production':
    case '':
    case undefined:
      return 'production';
    default:
      return value?.trim() || 'production';
  }
}

export function percentageRate(value: string | undefined): number {
  const parsed = Number(value);
  if (!Number.isFinite(parsed)) return 0;
  return Math.min(100, Math.max(0, parsed)) / 100;
}
