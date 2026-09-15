import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';

describe('app runtime dependency contract', () => {
  it('captures links before authentication and consumes that inbox inside the authenticated shell', () => {
    const layout = readFileSync(resolve(process.cwd(), 'src/app/_layout.tsx'), 'utf8');
    const authenticatedRoot = readFileSync(
      resolve(process.cwd(), 'src/core/app/authenticated-root.tsx'),
      'utf8',
    );
    expect(layout).toContain('const links = new ExpoDeepLinkRuntime();');
    expect(layout).toContain('queueAppLink(url);');
    expect(layout).toContain('if (active && !receivedEvent && url) queueAppLink(url);');
    expect(layout).toMatch(/return \(\) => \{\s*active = false;\s*stop\(\);/);
    expect(authenticatedRoot).toContain('startDeepLinkHandling(appLinkInbox, handler,');
    expect(authenticatedRoot).toContain('runtime.wars.loadLinkedCwl(link.tag, link.params.season)');
    expect(authenticatedRoot).toMatch(
      /WarCwlService\.fetchWarDataFromTime\(\s*runtime\.contractApi,\s*link\.tag,\s*end,?\s*\)/,
    );
    expect(authenticatedRoot).not.toContain('runtime.api');
    expect(authenticatedRoot).toContain(
      'if (!active || generation !== navigationGeneration.current) return;',
    );
  });

  it('mounts the same application at direct public destinations with static screen entries', () => {
    const destination = readFileSync(
      resolve(process.cwd(), 'src/app/[...destination].tsx'),
      'utf8',
    );
    expect(destination).toContain('export default ApplicationRoot;');
    expect(destination).toContain('return [');
    for (const path of ['players', 'clans', 'war', 'search', 'settings/faq', 'settings/licenses']) {
      expect(destination).toContain(`'${path}'`);
    }
    expect(destination).toContain("destination: path.split('/')");
  });

  it('mounts application bootstrap inside the single-owner OTA gate', () => {
    const root = readFileSync(resolve(process.cwd(), 'src/core/app/application-root.tsx'), 'utf8');
    expect(root).toMatch(
      /export function ApplicationRoot\(\)\s*\{\s*return\s*\(\s*<StartupUpdateGate>\s*<ApplicationContent\s*\/>\s*<\/StartupUpdateGate>/,
    );
    const bootstrap = root.slice(root.indexOf('function ApplicationContent()'));
    expect(bootstrap).toContain('void runStartup();');
    expect(bootstrap).toContain('await initializeApplication({');
    const config = readFileSync(resolve(process.cwd(), 'app.config.ts'), 'utf8');
    expect(config).toContain("const updatesEnabled = process.env.CK_ENABLE_UPDATES === 'true';");
    expect(config).toContain("'https://api.clashk.ing/v2/app/updates/manifest'");
    expect(config).toContain("requestHeaders: { 'expo-channel-name': updateChannel }");
    expect(config).toContain("codeSigningMetadata: { keyid: 'main', alg: 'rsa-v1_5-sha256' as const }");
    expect(config).toContain(
      "throw new Error('CK_UPDATES_CERTIFICATE_PATH is required when release updates are enabled.')",
    );
    expect(config).toContain("checkAutomatically: 'NEVER'");
    expect(config).not.toContain("checkAutomatically: 'ON_LOAD'");
  });

  it('hydrates linked account data before leaving account setup', () => {
    const root = readFileSync(resolve(process.cwd(), 'src/core/app/application-root.tsx'), 'utf8');
    const authenticatedRoot = readFileSync(
      resolve(process.cwd(), 'src/core/app/authenticated-root.tsx'),
      'utf8',
    );
    expect(root).toMatch(
      /await runtime\.accountBootstrap\.initialize\([\s\S]*?\);\s*setScene\(\{ kind: 'home' \}\)/,
    );
    expect(authenticatedRoot).toMatch(
      /await runtime\.accountBootstrap\.initialize\(user\?\.userId \?\? null\);\s*closeSecondary\(\)/,
    );
  });

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
