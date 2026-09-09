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
    dsn: environment.EXPO_PUBLIC_CK_SENTRY_DSN?.trim() || undefined,
    environment: sentryEnvironment(environment.EXPO_PUBLIC_CK_API_ENV),
    release: `${metadata.packageName}@${metadata.version}`,
    dist: metadata.buildNumber?.trim() || undefined,
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
  };
}

export function sentryEnvironment(value: string | undefined): string {
  switch (value?.trim().toLowerCase()) {
    case 'local':
    case 'development':
      return 'development';
    case 'prod':
    case 'production':
    case '':
    case undefined:
      return 'production';
    default:
      return value?.trim() || 'production';
  }
}
