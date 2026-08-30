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
    this.fetchImplementation = options.fetchImplementation ?? fetch;
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
      const response = await this.fetchImplementation(url, { signal: controller.signal });
      if (!response.ok) return this.remember(url, url);
      const bytes = new Uint8Array(await response.arrayBuffer());
      return this.remember(url, `data:model/gltf-binary;base64,${encodeBase64(bytes)}`);
    } catch {
      return this.remember(url, url);
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
