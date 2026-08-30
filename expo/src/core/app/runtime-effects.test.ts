import { RuntimeEffects, supportCreatorUrl } from './runtime-effects';

describe('runtime effects', () => {
  it('defers cold-start routes until authenticated navigation is ready', async () => {
    const effects = new RuntimeEffects();
    const routes: string[] = [];
    const posts = effects.openRoute('/posts');
    const search = effects.openRoute('/search');
    expect(routes).toEqual([]);

    const unbind = effects.bindRouteHandler((route) => {
      routes.push(route);
    });
    await Promise.all([posts, search]);
    expect(routes).toEqual(['/posts', '/search']);

    await effects.openRoute('/posts/42');
    unbind();
    expect(routes).toEqual(['/posts', '/search', '/posts/42']);
  });

  it('clears a deferred notification route during logout handoff', async () => {
    const effects = new RuntimeEffects();
    const pending = effects.openRoute('/upgrade-tracker');
    effects.clearPendingRoutes();
    await expect(pending).resolves.toBeUndefined();

    const handler = jest.fn();
    effects.bindRouteHandler(handler);
    expect(handler).not.toHaveBeenCalled();
  });

  it('defaults the permission primer to declined without mounted UI', async () => {
    const effects = new RuntimeEffects();
    expect(await effects.showPermissionPrimer()).toBe(false);
    const unbind = effects.bindPermissionPrimer(async () => true);
    expect(await effects.showPermissionPrimer()).toBe(true);
    unbind();
    expect(await effects.showPermissionPrimer()).toBe(false);
  });

  it('builds the same localized creator handoff URL as Flutter', () => {
    expect(supportCreatorUrl('en_US')).toBe(
      'https://link.clashofclans.com/en?action=SupportCreator&id=Clashking',
    );
    expect(supportCreatorUrl('PT_br')).toBe(
      'https://link.clashofclans.com/pt?action=SupportCreator&id=Clashking',
    );
  });
});
