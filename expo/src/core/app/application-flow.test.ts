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
});
