import { appRoutes } from '../../navigation/route-manifest';
import { appLinkPath, parseAppLink } from './app-link';
import { appLinkInbox, queueAppLink } from './link-inbox';

describe('public app links', () => {
  test.each(appRoutes.map((route) => [route.id, route.href]))(
    'opens %s via HTTPS and custom scheme',
    (page, path) => {
      for (const url of [`https://app.clashk.ing${path}`, `clashking://${path.slice(1)}`]) {
        expect(parseAppLink(url)).toEqual({ kind: 'page', page, params: {} });
      }
    },
  );
  test.each([
    '/player/2ABC?tab=battles',
    '/clan/2ABC?tab=warLog',
    '/clan/2ABC/capital?day=2026-09-04',
    '/clan/2ABC/war',
    '/clan/2ABC/war/20260904T120000.000Z',
    '/clan/2ABC/cwl?season=2026-09&tab=members&round=2',
    '/posts/article-1',
    '/settings/notifications',
    '/settings/faq?q=widget&question=widgets',
    '/settings/licenses?package=expo',
    '/settings/translation',
    '/settings/privacy',
    '/upgrade-tracker?player=%232ABC&tab=builder',
    '/ranked?player=%232ABC&day=2026-09-04',
    '/stats?audience=world&section=clans&start=2026-08-01&end=2026-08-31',
    '/game-assets?asset=Buildings%2Ftownhall.png&format=png',
  ])('round-trips %s', (path) => {
    const link = parseAppLink(path);
    expect(link).not.toBeNull();
    expect(parseAppLink(appLinkPath(link!))).toEqual(link);
  });
  test.each([
    '/auth/login',
    '/auth/register',
    '/auth/callback?code=secret',
    '/auth/reset-password?token=secret',
    'clashking://oauth?code=secret',
    'https://evil.test/player/ABC',
    '//evil.test/player/ABC',
    'http://app.clashk.ing/player/ABC',
    'https://user:secret@app.clashk.ing/',
    '/player/%2FABC',
    '/player/ABC/extra',
    '/clan/ABC/war/arbitrary-id',
    '/clan/ABC/cwl/extra',
    '/clan/ABC/cwl?season=2026-13',
    '/clan/ABC/cwl?round=8',
    '/ranked?day=2026-02-30',
    '/stats?start=bad',
    '/todo?player=%23bad%20tag',
    '/search?q=%00',
    '/unknown',
    '/player/#ABC',
  ])('rejects unsafe or unsupported link %s', (url) => expect(parseAppLink(url)).toBeNull());
  test('retains supported query-tag links', () => {
    expect(parseAppLink('clashking://player?player_tag=%23abc')).toEqual({
      kind: 'player',
      tag: '#ABC',
      params: {},
    });
    expect(parseAppLink('clashking://clan?tag=abc')).toEqual({
      kind: 'clan',
      tag: '#ABC',
      params: {},
    });
  });
  test('preserves the latest destination until authenticated navigation subscribes', async () => {
    await appLinkInbox.getInitialUrl();
    queueAppLink('clashking://player/ABC');
    expect(queueAppLink('clashking://oauth?code=private')).toBe(false);
    queueAppLink('clashking://clan/XYZ');
    expect(await appLinkInbox.getInitialUrl()).toBe('clashking://clan/XYZ');
    expect(await appLinkInbox.getInitialUrl()).toBeNull();
    const listener = jest.fn();
    const stop = appLinkInbox.subscribe(listener);
    queueAppLink('clashking://settings/faq');
    expect(listener).toHaveBeenCalledWith('clashking://settings/faq');
    stop();
  });
});
