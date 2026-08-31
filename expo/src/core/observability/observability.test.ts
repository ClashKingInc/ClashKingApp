const mockRegisterNavigationContainer = jest.fn();
const mockInit = jest.fn();
const mockSetContext = jest.fn();
const mockSetUser = jest.fn();
const mockCaptureException = jest.fn();
const mockAddBreadcrumb = jest.fn();
const mockSetTag = jest.fn();

jest.mock('./sentry-sdk', () => ({
  breadcrumbsIntegration: (options: unknown) => ({ name: 'Breadcrumbs', options }),
  reactNavigationIntegration: () => ({
    name: 'ReactNavigation',
    registerNavigationContainer: (...args: unknown[]) => mockRegisterNavigationContainer(...args),
  }),
  init: (...args: unknown[]) => mockInit(...args),
  setContext: (...args: unknown[]) => mockSetContext(...args),
  setUser: (...args: unknown[]) => mockSetUser(...args),
  captureException: (...args: unknown[]) => mockCaptureException(...args),
  addBreadcrumb: (...args: unknown[]) => mockAddBreadcrumb(...args),
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
  initializeObservability,
  registerNavigationContainer,
  reportException,
  sanitizeHttpUrl,
  setAuthenticatedUser,
} from './observability';

describe('observability service', () => {
  beforeEach(() => jest.clearAllMocks());

  it('initializes without PII and removes selected-player context', () => {
    initializeObservability();
    expect(mockInit).toHaveBeenCalledWith(
      expect.objectContaining({
        release: 'com.clashking.apps@0.3.5',
        dist: '25',
        debug: false,
        sendDefaultPii: false,
        replaysSessionSampleRate: 0,
        replaysOnErrorSampleRate: 0,
      }),
    );
    expect(mockSetContext).toHaveBeenCalledWith('selected_player', null);
    const options = mockInit.mock.calls[0]?.[0] as {
      integrations: (defaults: readonly unknown[]) => readonly unknown[];
    };
    const defaultIntegration = { name: 'Default' };
    const unsafeBreadcrumbs = { name: 'Breadcrumbs', options: { xhr: true } };
    expect(options.integrations([defaultIntegration, unsafeBreadcrumbs])).toEqual([
      defaultIntegration,
      {
        name: 'Breadcrumbs',
        options: { fetch: false, history: false, xhr: false },
      },
      expect.objectContaining({ name: 'ReactNavigation' }),
    ]);
  });

  it('registers Expo Router navigation with the Sentry integration', () => {
    const container = {};
    registerNavigationContainer(container);
    expect(mockRegisterNavigationContainer).toHaveBeenCalledWith(container);
  });

  it('sets only the authenticated user id and clears it on logout', async () => {
    await setAuthenticatedUser({
      userId: '42',
      username: 'not-sent',
      avatarUrl: 'not-sent',
      authMethods: [],
      email: 'not-sent@example.test',
    });
    await clearUser();
    expect(mockSetUser).toHaveBeenNthCalledWith(1, { id: '42' });
    expect(mockSetUser).toHaveBeenNthCalledWith(2, null);
  });

  it('clears the Sentry user when the authenticated id is empty', async () => {
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
    const error = new Error('boom');
    reportException(error, 'first');
    reportException(error, 'second');
    expect(mockCaptureException).toHaveBeenCalledTimes(1);
    expect(mockSetTag).toHaveBeenCalledWith('operation', 'first');
  });

  it('reports primitive exceptions each time', () => {
    reportException('boom', 'first');
    reportException('boom', 'second');
    expect(mockCaptureException).toHaveBeenCalledTimes(2);
  });

  it('deduplicates a sanitized capture by the original exception object', () => {
    const original = new Error('raw endpoint /links/42?token=secret');
    const diagnostic = new Error('API request failed for /links/:user_id.');
    reportException(diagnostic, 'GET /links/:user_id', original);
    reportException(original, 'startup.bootstrap');
    expect(mockCaptureException).toHaveBeenCalledTimes(1);
    expect(mockCaptureException).toHaveBeenCalledWith(diagnostic);
  });

  it('sanitizes HTTP breadcrumb URLs and records response metadata', () => {
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
    expect(mockAddBreadcrumb).toHaveBeenCalledWith(
      expect.objectContaining({
        level: 'warning',
        data: expect.objectContaining({ url: 'https://api.test/v2/links/:user_id' }),
      }),
    );
  });
});
