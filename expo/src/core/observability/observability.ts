import * as Application from 'expo-application';
import Constants from 'expo-constants';
import {
  captureException,
  init,
  setContext,
  setUser,
  withScope,
  type ErrorEvent,
} from './sentry-sdk';

import type { AuthUser } from '../../features/auth/models';
import { resolveObservabilityConfig } from './observability-config';

const DEFAULT_DEDUPE_WINDOW_MS = Number.POSITIVE_INFINITY;
const DEFAULT_DEDUPE_CAP = 256;
const REDACTED = '[redacted]';
let reportedObjects = new WeakSet<object>();
let beforeSend = createBeforeSend();
let initialized = false;
let enabled = false;

export function initializeObservability(): void {
  if (initialized) return;
  const version =
    Application.nativeApplicationVersion ?? Constants.expoConfig?.version ?? 'unknown';
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
    },
    {
      packageName,
      version,
      ...(buildNumber === undefined ? {} : { buildNumber }),
    },
  );
  if (!config.dsn) {
    initialized = true;
    return;
  }
  try {
    init({
      ...config,
      beforeSend,
      debug: false,
      sendDefaultPii: false,
      maxBreadcrumbs: 0,
      attachScreenshot: false,
      attachViewHierarchy: false,
      enableCaptureFailedRequests: false,
      sendClientReports: false,
      integrations: errorOnlyIntegrations,
    });
    setContext('selected_player', null);
    enabled = true;
  } catch {
    // Error reporting is optional and must never prevent the app from starting.
    enabled = false;
  } finally {
    initialized = true;
  }
}

export function registerNavigationContainer(container: unknown): void {
  void container;
}

export async function setAuthenticatedUser(_user: AuthUser): Promise<void> {
  if (!enabled) return;
  try {
    setUser(null);
  } catch {
    // Reporting failures cannot affect authentication.
  }
}

export async function clearUser(): Promise<void> {
  if (!enabled) return;
  try {
    setUser(null);
  } catch {
    // Reporting failures cannot affect logout.
  }
}

export function reportException(
  error: unknown,
  operation: string,
  dedupeKey: unknown = error,
): void {
  if (!enabled) return;
  if (isObject(dedupeKey)) {
    if (reportedObjects.has(dedupeKey)) return;
    reportedObjects.add(dedupeKey);
  }
  try {
    withScope((scope) => {
      scope.setTag('operation', sanitizeText(operation));
      captureException(error);
    });
  } catch {
    // Reporting failures cannot affect the operation being observed.
  }
}

export interface HttpBreadcrumbInput {
  readonly url: string;
  readonly method: string;
  readonly statusCode: number;
  readonly durationMs: number;
  readonly responseBodySize?: number;
}

export function addHttpBreadcrumb(input: HttpBreadcrumbInput): void {
  void input;
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

export function createBeforeSend({
  now = Date.now,
  windowMs = DEFAULT_DEDUPE_WINDOW_MS,
  maxSignatures = DEFAULT_DEDUPE_CAP,
}: {
  readonly now?: () => number;
  readonly windowMs?: number;
  readonly maxSignatures?: number;
} = {}): (event: ErrorEvent) => ErrorEvent | null {
  const recent = new Map<string, number>();
  return (event) => {
    const sanitized = sanitizeEvent(event);
    const current = now();
    const cutoff = current - Math.max(0, windowMs);
    for (const [signature, timestamp] of recent) {
      if (timestamp > cutoff) break;
      recent.delete(signature);
    }
    const signature = eventSignature(sanitized);
    if (signature !== null) {
      const lastSeen = recent.get(signature);
      if (lastSeen !== undefined && current - lastSeen < windowMs) return null;
      recent.delete(signature);
      recent.set(signature, current);
    }
    const cap = Math.max(1, maxSignatures);
    while (recent.size > cap) {
      const oldest = recent.keys().next().value as string | undefined;
      if (oldest === undefined) break;
      recent.delete(oldest);
    }
    return sanitized;
  };
}

export function sanitizeEvent(event: ErrorEvent): ErrorEvent {
  return {
    ...event,
    message: event.message === undefined ? undefined : sanitizeText(event.message),
    transaction: event.transaction === undefined ? undefined : sanitizeText(event.transaction),
    server_name: undefined,
    user: undefined,
    request: undefined,
    fingerprint: undefined,
    tags:
      event.tags?.operation === undefined
        ? undefined
        : { operation: sanitizeText(String(event.tags.operation)) },
    breadcrumbs: undefined,
    contexts: undefined,
    extra: undefined,
    logentry:
      event.logentry === undefined
        ? undefined
        : {
            ...event.logentry,
            message:
              event.logentry.message === undefined
                ? undefined
                : sanitizeText(event.logentry.message),
            params: event.logentry.params?.map((value) =>
              typeof value === 'string' ? sanitizeText(value) : REDACTED,
            ),
          },
    exception:
      event.exception === undefined
        ? undefined
        : {
            ...event.exception,
            values: event.exception.values?.map((exception) => ({
              ...exception,
              value: exception.value === undefined ? undefined : sanitizeText(exception.value),
              stacktrace:
                exception.stacktrace === undefined
                  ? undefined
                  : {
                      ...exception.stacktrace,
                      frames: exception.stacktrace.frames?.map((frame) => ({
                        ...frame,
                        filename:
                          frame.filename === undefined
                            ? undefined
                            : sanitizeStackLocation(frame.filename),
                        abs_path:
                          frame.abs_path === undefined
                            ? undefined
                            : sanitizeStackLocation(frame.abs_path),
                        module: frame.module === undefined ? undefined : sanitizeText(frame.module),
                        function:
                          frame.function === undefined ? undefined : sanitizeText(frame.function),
                        vars: undefined,
                      })),
                    },
            })),
          },
  };
}

function eventSignature(event: ErrorEvent): string | null {
  const exceptions =
    event.exception?.values
      ?.map((exception) => {
        const frames = exception.stacktrace?.frames
          ?.slice(-5)
          .map(
            (frame) =>
              `${frame.filename ?? frame.abs_path ?? ''}:${frame.function ?? ''}:${frame.lineno ?? ''}:${frame.colno ?? ''}`,
          )
          .join('|');
        return `${exception.type ?? ''}:${exception.value ?? ''}:${frames ?? ''}`;
      })
      .join('||') ?? '';
  const description = `${String(event.tags?.operation ?? '')}\u0000${event.message ?? ''}\u0000${exceptions}`;
  return description === '\u0000\u0000' ? null : hashSignature(description);
}

function hashSignature(value: string): string {
  let hash = 0x811c9dc5;
  for (let index = 0; index < value.length; index += 1) {
    hash ^= value.charCodeAt(index);
    hash = Math.imul(hash, 0x01000193);
  }
  return (hash >>> 0).toString(16).padStart(8, '0');
}

function sanitizeStackLocation(value: string): string {
  return /^https?:\/\//i.test(value) ? sanitizeHttpUrl(value) : sanitizeText(value);
}

function sanitizeText(value: string): string {
  return value
    .replace(/https?:\/\/[^\s"'<>]+/gi, (url) => sanitizeHttpUrl(url))
    .replace(/\b[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}\b/gi, '[redacted-email]')
    .replace(/\bBearer\s+[A-Za-z0-9._~+/=-]+/gi, 'Bearer [redacted]')
    .replace(
      /\b(access_token|api_key|authorization|code|cookie|password|refresh_token|secret|session|token)=[^\s&,;]+/gi,
      '$1=[redacted]',
    )
    .replace(/\beyJ[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\b/g, '[redacted-token]')
    .replace(/\b(?:\d{1,3}\.){3}\d{1,3}\b/g, '[redacted-ip]');
}

export function resetObservabilityForTesting(): void {
  initialized = false;
  enabled = false;
  reportedObjects = new WeakSet<object>();
  beforeSend = createBeforeSend();
}

const OMITTED_ERROR_INTEGRATIONS = new Set([
  'Breadcrumbs',
  'BrowserSession',
  'ConversationId',
  'CultureContext',
  'DeviceContext',
  'ExpoContext',
  'HttpContext',
  'PrimitiveTag',
  'ReactNativeInfo',
]);

export function errorOnlyIntegrations<T extends { name: string }>(integrations: T[]): T[] {
  return integrations.filter(
    (integration) =>
      !OMITTED_ERROR_INTEGRATIONS.has(integration.name) &&
      !/(log|profil|replay|session|tracing)/i.test(integration.name),
  );
}

function isObject(value: unknown): value is object {
  return (typeof value === 'object' && value !== null) || typeof value === 'function';
}
