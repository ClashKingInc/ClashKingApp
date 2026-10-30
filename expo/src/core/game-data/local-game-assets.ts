import { isRecord, type JsonRecord } from './game-data-state';

// Production builds cannot opt into local preview data, even if a developer
// accidentally leaves the environment variable configured when exporting.
export const localGameAssetsUrl = __DEV__
  ? process.env.EXPO_PUBLIC_LOCAL_GAME_ASSETS_URL?.replace(/\/$/, '')
  : undefined;

export async function applyLocalGameAssets(
  bundle: JsonRecord,
  fetcher: typeof fetch,
): Promise<JsonRecord> {
  if (!localGameAssetsUrl) return bundle;
  try {
    const sections = await Promise.all(
      ['equipment', 'abilities'].map(async (name) => {
        const response = await fetcher(`${localGameAssetsUrl}/${name}.json`, { cache: 'no-store' });
        if (!response.ok) throw new Error(`Local ${name} preview unavailable`);
        const data: unknown = await response.json();
        if (!isRecord(data) || !Array.isArray(data.items))
          throw new Error(`Invalid local ${name} preview`);
        return [name, data.items] as const;
      }),
    );
    // In-memory only: never persist these development sections in the CDN cache.
    return { ...bundle, ...Object.fromEntries(sections) };
  } catch (error) {
    console.warn('Local game asset preview unavailable; retaining published data.', error);
    return bundle;
  }
}
