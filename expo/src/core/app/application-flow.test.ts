import { sceneForPostAuthDestination, sceneForStartupResult } from './application-flow';

describe('application route decisions', () => {
  it('keeps the verified-account requirement after login', () => {
    expect(sceneForPostAuthDestination('account-setup')).toEqual({ kind: 'account-setup' });
    expect(sceneForPostAuthDestination('home')).toEqual({ kind: 'home' });
  });

  it('preserves startup maintenance and network classification', () => {
    expect(
      sceneForStartupResult({
        destination: 'maintenance',
        authenticated: false,
        hasVerifiedAccount: false,
        failure: new Error('503'),
        networkError: false,
        requestPushPermission: false,
      }),
    ).toEqual({ kind: 'maintenance' });
    expect(
      sceneForStartupResult({
        destination: 'error',
        authenticated: true,
        hasVerifiedAccount: false,
        failure: new Error('network'),
        networkError: true,
        requestPushPermission: false,
      }),
    ).toEqual({ kind: 'error', networkError: true });
  });

  it('maps a forced update to a non-bypassable update scene', () => {
    expect(
      sceneForStartupResult({
        destination: 'update',
        authenticated: true,
        hasVerifiedAccount: false,
        failure: null,
        networkError: false,
        requestPushPermission: false,
        update: {
          minimumVersion: '0.4.0',
          storeUrl: 'https://apps.apple.com/app/id123',
          message: 'A newer ClashKing build is required.',
        },
      }),
    ).toEqual({
      kind: 'update',
      storeUrl: 'https://apps.apple.com/app/id123',
      message: 'A newer ClashKing build is required.',
    });
  });
});
