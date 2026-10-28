import { Asset } from 'expo-asset';
import { File } from 'expo-file-system';
import { Platform } from 'react-native';


export interface AchievementModelCacheOptions {
  readonly fetchImplementation?: typeof fetch;
  readonly timeoutMs?: number;
}

export class AchievementModelCache {
  private readonly fetchImplementation: typeof fetch;
  private readonly timeoutMs: number;
  private readonly resolvedSources = new Map<string, string>();
  private readonly pendingSources = new Map<string, Promise<string>>();

  constructor(options: AchievementModelCacheOptions = {}) {
    // Browser fetch must retain its global receiver when stored on a class.
    // Otherwise the cache can fail before requesting bytes, while direct CDN
    // viewer fallbacks make the old achievements appear to work.
    this.fetchImplementation = options.fetchImplementation ?? globalThis.fetch.bind(globalThis);
    this.timeoutMs = options.timeoutMs ?? 15_000;
  }

  peek(url: string): string | undefined {
    return this.resolvedSources.get(url);
  }

  resolve(url: string): Promise<string> {
    const resolved = this.resolvedSources.get(url);
    if (resolved !== undefined) return Promise.resolve(resolved);
    const pending = this.pendingSources.get(url);
    if (pending !== undefined) return pending;
    const download = this.download(url);
    this.pendingSources.set(url, download);
    return download;
  }

  private async download(url: string): Promise<string> {
    const controller = new AbortController();
    const timer = setTimeout(() => controller.abort(), this.timeoutMs);
    try {
      if (url === 'derived:verified_accounts') {
        const asset = Asset.fromModule(
          // Keep the verified badge bundled independently of future tournaments.
          // eslint-disable-next-line @typescript-eslint/no-require-imports
          require('../../../../assets/clashking/achievements/verified-accounts.glb'),
        );
        // The browser receives Metro's asset path through the app's HTTPS
        // proxy. Avoid downloadAsync here: its URI can retain the HTTP Metro
        // origin even though the same file is available from the app origin.
        if (Platform.OS === 'web') {
          const source = new URL(asset.uri, globalThis.location?.href);
          const uri = globalThis.location?.origin
            ? new URL(`${source.pathname}${source.search}`, globalThis.location.origin).href
            : source.href;
          const response = await this.fetchImplementation(uri, { signal: controller.signal });
          if (!response.ok)
            throw new Error(`Bundled achievement asset failed (${response.status}).`);
          return this.remember(
            url,
            `data:model/gltf-binary;base64,${encodeBase64(new Uint8Array(await response.arrayBuffer()))}`,
          );
        }
        await asset.downloadAsync();
        const uri = asset.localUri ?? asset.uri;
        const encoded = uri.startsWith('file:')
          ? await new File(uri).base64()
          : encodeBase64(
              new Uint8Array(
                await (
                  await this.fetchImplementation(uri, { signal: controller.signal })
                ).arrayBuffer(),
              ),
            );
        return this.remember(url, `data:model/gltf-binary;base64,${encoded}`);
      }
      const response = await this.fetchImplementation(url, { signal: controller.signal });
      if (!response.ok) return url;
      const bytes = new Uint8Array(await response.arrayBuffer());
      return this.remember(url, `data:model/gltf-binary;base64,${encodeBase64(bytes)}`);
    } catch (error) {
      if (__DEV__) {
        console.warn(
          'Achievement model cache failed:',
          error instanceof Error ? error.message : String(error),
        );
      }
      // A temporary CDN failure must remain retryable when the viewer reopens.
      return url;
    } finally {
      clearTimeout(timer);
      this.pendingSources.delete(url);
    }
  }

  private remember(url: string, source: string): string {
    this.resolvedSources.set(url, source);
    return source;
  }
}

export const sharedAchievementModelCache = new AchievementModelCache();

function encodeBase64(bytes: Uint8Array): string {
  const alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
  let result = '';
  for (let index = 0; index < bytes.length; index += 3) {
    const first = bytes[index] ?? 0;
    const second = bytes[index + 1] ?? 0;
    const third = bytes[index + 2] ?? 0;
    const value = (first << 16) | (second << 8) | third;
    result += alphabet[(value >> 18) & 63];
    result += alphabet[(value >> 12) & 63];
    result += index + 1 < bytes.length ? alphabet[(value >> 6) & 63] : '=';
    result += index + 2 < bytes.length ? alphabet[value & 63] : '=';
  }
  return result;
}
