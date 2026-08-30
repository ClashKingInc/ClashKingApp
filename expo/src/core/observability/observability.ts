import * as Application from 'expo-application';
import Constants from 'expo-constants';
import {
  addBreadcrumb as sentryAddBreadcrumb,
  breadcrumbsIntegration,
  captureException,
  init,
  reactNavigationIntegration,
  setContext,
  setUser,
  withScope,
} from './sentry-sdk';

import type { AuthUser } from '../../features/auth/models';
import { resolveObservabilityConfig } from './observability-config';

const navigationIntegration = reactNavigationIntegration();
const safeBreadcrumbsIntegration = breadcrumbsIntegration({
  fetch: false,
  history: false,
  xhr: false,
});
const reportedObjects = new WeakSet<object>();
let initialized = false;

export function initializeObservability(): void {
  if (initialized) return;
  const version = Application.nativeApplicationVersion ?? Constants.expoConfig?.version ?? '0.3.5';
  const packageName =
    Application.applicationId ??
    Constants.expoConfig?.ios?.bundleIdentifier ??
    Constants.expoConfig?.android?.package ??
    'com.clashking.apps';
  const buildNumber =
    Application.nativeBuildVersion ??
    Constants.expoConfig?.ios?.buildNumber ??
    Constants.expoConfig?.android?.versionCode?.toString();
  const config = resolveObservabilityConfig(
    {
      EXPO_PUBLIC_CK_SENTRY_DSN: process.env.EXPO_PUBLIC_CK_SENTRY_DSN,
      EXPO_PUBLIC_CK_API_ENV: process.env.EXPO_PUBLIC_CK_API_ENV,
      EXPO_PUBLIC_CK_SENTRY_TRACES_SAMPLE_RATE_PERCENT:
        process.env.EXPO_PUBLIC_CK_SENTRY_TRACES_SAMPLE_RATE_PERCENT,
      EXPO_PUBLIC_CK_SENTRY_REPLAY_SESSION_SAMPLE_RATE_PERCENT:
        process.env.EXPO_PUBLIC_CK_SENTRY_REPLAY_SESSION_SAMPLE_RATE_PERCENT,
      EXPO_PUBLIC_CK_SENTRY_REPLAY_ON_ERROR_SAMPLE_RATE_PERCENT:
        process.env.EXPO_PUBLIC_CK_SENTRY_REPLAY_ON_ERROR_SAMPLE_RATE_PERCENT,
    },
    {
      packageName,
      version,
      ...(buildNumber === undefined ? {} : { buildNumber }),
    },
  );
  init({
    ...config,
    debug: false,
    sendDefaultPii: false,
    integrations: (defaultIntegrations) => [
      ...defaultIntegrations.filter((integration) => integration.name !== 'Breadcrumbs'),
      safeBreadcrumbsIntegration,
      navigationIntegration,
    ],
  });
  setContext('selected_player', null);
  initialized = true;
}

export function registerNavigationContainer(container: unknown): void {
  navigationIntegration.registerNavigationContainer(container);
}

export async function setAuthenticatedUser(user: AuthUser): Promise<void> {
  const id = user.userId.trim();
  setUser(id.length === 0 ? null : { id });
}

export async function clearUser(): Promise<void> {
  setUser(null);
}

export function reportException(
  error: unknown,
  operation: string,
  dedupeKey: unknown = error,
): void {
  if (isObject(dedupeKey)) {
    if (reportedObjects.has(dedupeKey)) return;
    reportedObjects.add(dedupeKey);
  }
  withScope((scope) => {
    scope.setTag('operation', operation);
    captureException(error);
  });
}

export interface HttpBreadcrumbInput {
  readonly url: string;
  readonly method: string;
  readonly statusCode: number;
  readonly durationMs: number;
  readonly responseBodySize: number;
}

export function addHttpBreadcrumb(input: HttpBreadcrumbInput): void {
  sentryAddBreadcrumb({
    category: 'http',
    type: 'http',
    level: input.statusCode >= 400 ? 'warning' : 'info',
    data: {
      url: sanitizeHttpUrl(input.url),
      method: input.method,
      status_code: input.statusCode,
      request_duration: input.durationMs,
      response_body_size: input.responseBodySize,
    },
  });
}

export function sanitizeHttpUrl(value: string): string {
  try {
    const url = new URL(value);
    url.search = '';
    url.hash = '';
    url.pathname = redactLinkUserId(url.pathname);
    return url.toString();
  } catch {
    return redactLinkUserId(value.split(/[?#]/, 1)[0] ?? value);
  }
}

function redactLinkUserId(path: string): string {
  const segments = path.split('/');
  for (let index = 0; index < segments.length - 1; index += 1) {
    if (segments[index] === 'links') segments[index + 1] = ':user_id';
  }
  return segments.join('/');
}

function isObject(value: unknown): value is object {
  return (typeof value === 'object' && value !== null) || typeof value === 'function';
}
