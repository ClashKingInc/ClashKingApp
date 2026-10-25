import { appendFileSync } from 'node:fs';
import { pathToFileURL } from 'node:url';

export const RELEASE_TRACKS = ['alpha', 'beta', 'production'];

export function releaseEnvironment(track) {
  const profiles = {
    alpha: ['local', 'https://local-api.clashk.ing', 'https://local-app.clashk.ing'],
    beta: ['development', 'https://dev-api.clashk.ing', 'https://dev-app.clashk.ing'],
    production: ['production', 'https://api.clashk.ing', 'https://app.clashk.ing'],
  };
  if (!RELEASE_TRACKS.includes(track)) throw new Error(`Unsupported release track: ${track}`);
  const [environment, apiOrigin, appOrigin] = profiles[track];
  return {
    EXPO_NO_DOTENV: '1',
    EXPO_PUBLIC_CK_API_ENV: environment,
    EXPO_PUBLIC_CK_API_BASE_URL: track === 'production' ? `${apiOrigin}/v2` : apiOrigin,
    EXPO_PUBLIC_CK_API_V2_BASE_URL: `${apiOrigin}/v2`,
    EXPO_PUBLIC_CK_PROXY_BASE_URL: `${apiOrigin}/proxy/v1`,
    EXPO_PUBLIC_CK_PUSH_API_V2_BASE_URL: `${apiOrigin}/v2`,
    EXPO_PUBLIC_CK_WEB_DISCORD_REDIRECT_URI: `${appOrigin}/auth/callback`,
    EXPO_PUBLIC_CK_DISCORD_SIGN_IN_ENABLED: 'true',
    // Local API token exchange uses the beta Discord application. The native
    // client must authorize with that same ID, not the production fallback.
    EXPO_PUBLIC_CK_DISCORD_CLIENT_ID:
      track === 'alpha' ? '808566437199216691' : '824653933347209227',
    CK_UPDATES_URL: `${apiOrigin}/v2/app/updates/manifest`,
  };
}

if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
  const values = releaseEnvironment(process.env.CK_RELEASE_TRACK);
  if (!process.env.GITHUB_ENV) throw new Error('GITHUB_ENV is required.');
  appendFileSync(
    process.env.GITHUB_ENV,
    Object.entries(values)
      .map(([key, value]) => `${key}=${value}\n`)
      .join(''),
  );
  console.log(
    `Configured ${process.env.CK_RELEASE_TRACK}: ${values.EXPO_PUBLIC_CK_API_V2_BASE_URL}`,
  );
}
