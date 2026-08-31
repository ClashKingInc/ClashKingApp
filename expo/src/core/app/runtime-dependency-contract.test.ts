import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';

describe('app runtime dependency contract', () => {
  it('constructs feature services from leaf modules instead of UI-exporting barrels', () => {
    const runtime = readFileSync(
      resolve(process.cwd(), 'src', 'core', 'app', 'runtime.ts'),
      'utf8',
    );

    expect(runtime).not.toMatch(
      /from ['"]\.\.\/\.\.\/features\/(rankings|upgrade-tracker|subscription)['"]/,
    );
    expect(runtime).toContain("from '../../features/rankings/data/rankings-provider'");
    expect(runtime).toContain("from '../../features/rankings/data/rankings-service'");
    expect(runtime).toContain(
      "from '../../features/upgrade-tracker/data/upgrade-tracker-repository'",
    );
    expect(runtime).toContain(
      "from '../../features/upgrade-tracker/data/upgrade-widget-sync-service'",
    );
    expect(runtime).toContain("from '../../features/subscription/subscription-service'");
  });

  it('subscribes the authenticated shell to refreshed auth state', () => {
    const authenticatedRoot = readFileSync(
      resolve(process.cwd(), 'src', 'core', 'app', 'authenticated-root.tsx'),
      'utf8',
    );

    expect(authenticatedRoot).toContain('useSyncExternalStore');
    expect(authenticatedRoot).toContain('runtime.auth.subscribe(listener)');
    expect(authenticatedRoot).toContain('followerCount={authState.followerCount}');
    expect(authenticatedRoot).not.toContain('followerCount={runtime.auth.state.followerCount}');
  });
});
