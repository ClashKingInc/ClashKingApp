const mockInit = jest.fn();
const mockSetContext = jest.fn();
const mockSetUser = jest.fn();
const mockCaptureException = jest.fn();
const mockSetTag = jest.fn();

jest.mock('./sentry-sdk', () => ({
  init: (...args: unknown[]) => mockInit(...args),
  setContext: (...args: unknown[]) => mockSetContext(...args),
  setUser: (...args: unknown[]) => mockSetUser(...args),
  captureException: (...args: unknown[]) => mockCaptureException(...args),
  withScope: (callback: (scope: { setTag: typeof mockSetTag }) => void) =>
    callback({ setTag: mockSetTag }),
}));

jest.mock('expo-application', () => ({
  applicationId: 'com.clashking.apps',
  nativeApplicationVersion: '0.3.5',
  nativeBuildVersion: '25',
}));

jest.mock('expo-constants', () => ({ default: { expoConfig: undefined } }));

// Jest must install the SDK boundary before this module is evaluated.
// eslint-disable-next-line import/first
import {
  addHttpBreadcrumb,
  clearUser,
  createBeforeSend,
  initializeObservability,
  registerNavigationContainer,
  reportException,
  resetObservabilityForTesting,
  sanitizeEvent,
  sanitizeHttpUrl,
  setAuthenticatedUser,
} from './observability';

describe('observability service', () => {
  beforeEach(() => {
    jest.clearAllMocks();
    process.env.EXPO_PUBLIC_CK_SENTRY_DSN = 'https://public@example.test/1';
    resetObservabilityForTesting();
  });

  afterAll(() => {
    delete process.env.EXPO_PUBLIC_CK_SENTRY_DSN;
  });

  it('initializes without PII and removes selected-player context', () => {
    initializeObservability();
    expect(mockInit).toHaveBeenCalledWith(
      expect.objectContaining({
        release: 'com.clashking.apps@0.3.5',
        dist: '25',
        debug: false,
        sendDefaultPii: false,
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
        maxBreadcrumbs: 0,
        attachScreenshot: false,
        attachViewHierarchy: false,
        enableCaptureFailedRequests: false,
        sendClientReports: false,
        beforeSend: expect.any(Function),
      }),
    );
    expect(mockSetContext).toHaveBeenCalledWith('selected_player', null);
    const options = mockInit.mock.calls[0]?.[0] as {
      integrations: (defaults: readonly unknown[]) => readonly unknown[];
    };
    const defaultIntegration = { name: 'GlobalHandlers' };
    const unsafeBreadcrumbs = { name: 'Breadcrumbs', options: { xhr: true } };
    const tracing = { name: 'ReactNativeTracing' };
    const replay = { name: 'Replay' };
    const profiling = { name: 'Profiling' };
    const browserSession = { name: 'BrowserSession' };
    const httpContext = { name: 'HttpContext' };
    expect(
      options.integrations([
        defaultIntegration,
        unsafeBreadcrumbs,
        tracing,
        replay,
        profiling,
        browserSession,
        httpContext,
      ]),
    ).toEqual([defaultIntegration]);
  });

  it('uses the built-in app DSN when an environment override is blank', () => {
    process.env.EXPO_PUBLIC_CK_SENTRY_DSN = '   ';
    initializeObservability();
    expect(mockInit).toHaveBeenCalledWith(
      expect.objectContaining({
        dsn: 'https://dd63e00ff0707d03b77f7837e60718b3@o4509853737353216.ingest.de.sentry.io/4512054295461968',
      }),
    );
    expect(mockSetContext).toHaveBeenCalledWith('selected_player', null);
  });

  it('fails open when the SDK cannot initialize', () => {
    mockInit.mockImplementationOnce(() => {
      throw new Error('native SDK unavailable');
    });
    expect(() => initializeObservability()).not.toThrow();
    registerNavigationContainer({});
    reportException(new Error('app still works'), 'startup');
    expect(mockCaptureException).not.toHaveBeenCalled();
  });

  it('keeps navigation registration inert in errors-only mode', () => {
    initializeObservability();
    const container = {};
    expect(() => registerNavigationContainer(container)).not.toThrow();
  });

  it('never attaches authenticated profile data and clears scope on logout', async () => {
    initializeObservability();
    await setAuthenticatedUser({
      userId: '42',
      username: 'not-sent',
      avatarUrl: 'not-sent',
      authMethods: [],
      email: 'not-sent@example.test',
    });
    await clearUser();
    expect(mockSetUser).toHaveBeenNthCalledWith(1, null);
    expect(mockSetUser).toHaveBeenNthCalledWith(2, null);
  });

  it('clears the Sentry user when the authenticated id is empty', async () => {
    initializeObservability();
    await setAuthenticatedUser({
      userId: '   ',
      username: 'not-sent',
      avatarUrl: '',
      authMethods: [],
      email: null,
    });
    expect(mockSetUser).toHaveBeenCalledWith(null);
  });

  it('deduplicates object exceptions and tags the operation', () => {
    initializeObservability();
    const error = new Error('boom');
    reportException(error, 'first');
    reportException(error, 'second');
    expect(mockCaptureException).toHaveBeenCalledTimes(1);
    expect(mockSetTag).toHaveBeenCalledWith('operation', 'first');
  });

  it('reports primitive exceptions each time', () => {
    initializeObservability();
    reportException('boom', 'first');
    reportException('boom', 'second');
    expect(mockCaptureException).toHaveBeenCalledTimes(2);
  });

  it('deduplicates a sanitized capture by the original exception object', () => {
    initializeObservability();
    const original = new Error('raw endpoint /links/42?token=secret');
    const diagnostic = new Error('API request failed for /links/:user_id.');
    reportException(diagnostic, 'GET /links/:user_id', original);
    reportException(original, 'startup.bootstrap');
    expect(mockCaptureException).toHaveBeenCalledTimes(1);
    expect(mockCaptureException).toHaveBeenCalledWith(diagnostic);
  });

  it('sanitizes HTTP URLs while keeping breadcrumb collection disabled', () => {
    initializeObservability();
    expect(sanitizeHttpUrl('https://api.test/v2/links/42/player?q=secret#part')).toBe(
      'https://api.test/v2/links/:user_id/player',
    );
    addHttpBreadcrumb({
      url: 'https://api.test/v2/links/42?q=secret',
      method: 'GET',
      statusCode: 404,
      durationMs: 12,
      responseBodySize: 9,
    });
  });

  it('deduplicates equivalent new error events within the bounded window', () => {
    let time = 1_000;
    const scrub = createBeforeSend({ now: () => time, windowMs: 100, maxSignatures: 4 });
    const first = {
      type: undefined,
      event_id: 'first',
      exception: {
        values: [
          {
            type: 'Error',
            value: 'boom',
            stacktrace: { frames: [{ filename: 'app.ts', function: 'load', lineno: 42 }] },
          },
        ],
      },
      tags: { operation: 'startup' },
    };
    expect(scrub(first)).not.toBeNull();
    expect(scrub({ ...first, event_id: 'second' })).toBeNull();
    expect(scrub({ ...first, event_id: 'third', message: 'different' })).not.toBeNull();
    time += 101;
    expect(scrub({ ...first, event_id: 'fourth' })).not.toBeNull();
  });

  it('reports an equivalent error signature only once per app session by default', () => {
    let time = 1_000;
    const scrub = createBeforeSend({ now: () => time });
    const first = { type: undefined, message: 'same failure', tags: { operation: 'refresh' } };
    expect(scrub(first)).not.toBeNull();
    time += 86_400_000;
    expect(scrub({ ...first, event_id: 'later' })).toBeNull();
  });

  it('bounds the signature cache and evicts the oldest signature', () => {
    const scrub = createBeforeSend({ now: () => 1_000, windowMs: 10_000, maxSignatures: 2 });
    expect(scrub({ type: undefined, message: 'one' })).not.toBeNull();
    expect(scrub({ type: undefined, message: 'two' })).not.toBeNull();
    expect(scrub({ type: undefined, message: 'three' })).not.toBeNull();
    expect(scrub({ type: undefined, message: 'one' })).not.toBeNull();
    expect(scrub({ type: undefined, message: 'three' })).toBeNull();
  });

  it('scrubs event PII and secrets while retaining release and sanitized stack context', () => {
    const event = sanitizeEvent({
      type: undefined,
      release: 'com.clashking.apps@0.4.2',
      dist: '25',
      message:
        'failed https://api.test/v2/links/42?token=secret for person@example.test from 192.168.1.2',
      tags: { operation: 'GET https://api.test/v2/links/42?key=secret', unsafe: 'secret' },
      user: { id: '42', email: 'person@example.test' },
      request: { url: 'https://api.test/private?token=secret' },
      breadcrumbs: [
        {
          message: 'Bearer abc.def',
          data: { token: 'secret', url: 'https://api.test/path?secret=yes' },
        },
      ],
      contexts: { device: { model: 'iPhone', user_id: '42', email: 'person@example.test' } },
      extra: { password: 'secret', note: 'person@example.test' },
      exception: {
        values: [
          {
            type: 'Error',
            value: 'token=secret at person@example.test',
            stacktrace: {
              frames: [
                {
                  filename: 'https://app.test/index.js?token=secret#frame',
                  function: 'Bearer abc123',
                  vars: { token: 'secret' },
                },
              ],
            },
          },
        ],
      },
    });

    expect(event.release).toBe('com.clashking.apps@0.4.2');
    expect(event.dist).toBe('25');
    expect(event.user).toBeUndefined();
    expect(event.request).toBeUndefined();
    expect(event.tags).toEqual({ operation: 'GET https://api.test/v2/links/:user_id' });
    expect(event.message).toBe(
      'failed https://api.test/v2/links/:user_id for [redacted-email] from [redacted-ip]',
    );
    expect(event.breadcrumbs).toBeUndefined();
    expect(event.contexts).toBeUndefined();
    expect(event.extra).toBeUndefined();
    expect(event.exception?.values?.[0]?.value).toBe('token=[redacted] at [redacted-email]');
    expect(event.exception?.values?.[0]?.stacktrace?.frames?.[0]).toMatchObject({
      filename: 'https://app.test/index.js',
      function: 'Bearer [redacted]',
      vars: undefined,
    });
  });
});
