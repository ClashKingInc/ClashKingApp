import { createHash } from 'node:crypto';
import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';

function readPublicFile(relativePath: string): string {
  return readFileSync(resolve(process.cwd(), 'public', relativePath), 'utf8');
}

describe('static web authentication contract', () => {
  it('keeps OAuth callback documents out of Cache Storage', () => {
    const serviceWorker = readPublicFile('sw.js');
    const appShell = serviceWorker.match(/const APP_SHELL = \[([\s\S]*?)\];/)?.[1];

    expect(appShell).toBeDefined();
    expect(appShell).not.toContain('/auth/');
    expect(appShell).toContain('/favicon.png');
    expect(serviceWorker).toContain('__CLASHKING_WEB_BUILD__');
    expect(serviceWorker).toContain("if (url.pathname.startsWith('/auth/')) return;");
  });

  it('serves callback documents without persistence or referrer leakage', () => {
    const headers = readPublicFile('_headers');

    expect(headers).toContain('/auth/*');
    expect(headers).toContain('Cache-Control: no-store');
    expect(headers).toContain('Referrer-Policy: no-referrer');
    expect(headers).toContain("default-src 'none'");
  });

  it('preserves the install manifest and iOS PWA chrome', () => {
    const manifest = JSON.parse(readPublicFile('manifest.webmanifest')) as Record<string, unknown>;
    expect(manifest).toMatchObject({
      name: 'clashkingapp',
      short_name: 'clashkingapp',
      start_url: '.',
      display: 'standalone',
      orientation: 'portrait-primary',
      background_color: '#0175C2',
      theme_color: '#0175C2',
      description:
        'ClashKing helps players and clans track wars, upgrades, rankings, and account progress.',
      prefer_related_applications: false,
    });
    expect(manifest).not.toHaveProperty('id');
    expect(manifest).not.toHaveProperty('scope');

    const document = readFileSync(resolve(process.cwd(), 'src', 'app', '+html.tsx'), 'utf8');
    expect(document).toContain('content="width=device-width, initial-scale=1.0"');
    expect(document).toContain('content="black"');
    expect(document).toContain('name="theme-color" content="#0175C2"');
    expect(document).toContain('<link rel="icon" type="image/png" href="/favicon.png" />');
    expect(document).not.toContain('maximum-scale=1');
    expect(document).not.toContain('black-translucent');
    expect(document).toContain('<picture id="splash">');
    expect(document).toContain('/splash/img/light-4x.png 4x');
    expect(document).toContain('/splash/img/dark-4x.png 4x');

    const splashHashes = {
      'light-1x.png': '719620e90b3e66a575c253d35cc032ea3d99bb59c064e8ddba649d2cbce9d279',
      'light-2x.png': '2249df8c6509d7dc79a12f0cccac5e355c0b1cda863928b84cceeb9f5fc9d23c',
      'light-3x.png': '169c76da1b22c81a058794165f18ed567e7d7017f44f30843387db10ef1cd629',
      'light-4x.png': '6a61ba101b5b8e5dcd9ba77f630cfc3813bda366938e9e8e58e30fdfc75a8a25',
      'dark-1x.png': '282594a7b52503ac29559bd18c5a47dcaf382af9e057083693edd5b2e60c0888',
      'dark-2x.png': 'fe24fa3ab8765426d6077d2db4b894e032376ea2282d39207166117d25b4db5d',
      'dark-3x.png': 'dd99d2be1206574cb3715b638d97240901b8ce4541c407511e5087246c91dee0',
      'dark-4x.png': 'c7ddfe404d69ea9422796d09ee8d4c09473ca878b1a3e7068475906b1b7a4ffd',
    } as const;
    for (const [fileName, expectedHash] of Object.entries(splashHashes)) {
      const contents = readFileSync(resolve(process.cwd(), 'public', 'splash', 'img', fileName));
      expect(createHash('sha256').update(contents).digest('hex')).toBe(expectedHash);
    }

    const favicon = readFileSync(resolve(process.cwd(), 'public', 'favicon.png'));
    expect(createHash('sha256').update(favicon).digest('hex')).toBe(
      '7ab2525f4b86b65d3e4c70358a17e5a1aaf6f437f99cbcc046dad73d59bb9015',
    );
    const expoConfig = readFileSync(resolve(process.cwd(), 'app.config.ts'), 'utf8');
    expect(expoConfig).not.toContain('favicon:');

    const layout = readFileSync(resolve(process.cwd(), 'src', 'app', '_layout.tsx'), 'utf8');
    const launchRuntime = readFileSync(
      resolve(process.cwd(), 'src', 'core', 'app', 'launch-screen-runtime.web.ts'),
      'utf8',
    );
    expect(layout).toContain('onLayout={handleRootLayout}');
    expect(layout).toContain('hideWebLaunchScreen()');
    expect(launchRuntime).toContain("getElementById('splash')?.remove()");
  });
});
