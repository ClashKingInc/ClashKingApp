import { FileUpdateIndex } from './file-update-index';

export interface ImageFiles {
  exists(file: string): Promise<boolean>;
  download(url: string, expectedSha: string): Promise<{ file: string; sha: string; bytes: number }>;
  remove(file: string): Promise<void>;
}

/** Owns originals and each requested size independently; never downloads from notice(). */
export class ManagedImageCache {
  private static readonly UNUSED_EXPIRY_MS = 30 * 24 * 60 * 60 * 1_000;
  private readonly downloads = new Map<string, Promise<string>>();
  private readonly resolutions = new Set<Promise<string>>();
  private clearing?: Promise<void>;
  private hydration?: Promise<void>;
  constructor(
    private readonly index: FileUpdateIndex,
    private readonly files: ImageFiles,
    private readonly now: () => number = Date.now,
  ) {}
  subscribe = (listener: () => void) => this.index.subscribe(listener);
  getRevision = () => this.index.getRevision();
  getSize = () => this.index.imageBytes();
  hydrate = () => {
    if (!this.hydration)
      this.hydration = this.hydrateAndPrune().catch((error) => {
        this.hydration = undefined;
        throw error;
      });
    return this.hydration;
  };
  private async hydrateAndPrune(): Promise<void> {
    await this.index.hydrate();
    const cutoff = this.now() - ManagedImageCache.UNUSED_EXPIRY_MS;
    for (const [key, record] of await this.index.unusedImagesBefore(cutoff)) {
      if (record.file) await this.files.remove(record.file).catch(() => undefined);
      await this.index.remove(key);
    }
  }
  peek(url: string) {
    return this.index.peek('image:' + url)?.file ?? undefined;
  }
  async resolve(
    url: string,
    path: string,
    expectedSha: string,
    showSaved: (file: string) => void,
  ): Promise<string> {
    if (this.clearing) await this.clearing;
    const operation = this.resolveActive(url, path, expectedSha, showSaved);
    this.resolutions.add(operation);
    try {
      return await operation;
    } finally {
      this.resolutions.delete(operation);
    }
  }
  private async resolveActive(
    url: string,
    path: string,
    expectedSha: string,
    showSaved: (file: string) => void,
  ): Promise<string> {
    const key = 'image:' + url;
    await this.hydrate();
    const record = await this.index.prepare(key, path, expectedSha);
    const saved = record.file && (await this.files.exists(record.file)) ? record.file : null;
    if (saved) showSaved(saved);
    if (saved && record.installedSha === expectedSha && !record.pendingSha) return saved;
    const target = record.pendingSha ?? expectedSha;
    const downloadKey = key + ':' + target;
    let download = this.downloads.get(downloadKey);
    if (!download) {
      download = this.replace(key, url, target, saved);
      this.downloads.set(downloadKey, download);
      void download.finally(() => this.downloads.delete(downloadKey)).catch(() => undefined);
    }
    try {
      return await download;
    } catch (error) {
      if (saved) return saved;
      throw error;
    }
  }
  private async replace(
    key: string,
    url: string,
    target: string,
    previous: string | null,
  ): Promise<string> {
    const result = await this.files.download(url, target);
    if (result.sha !== target) {
      await this.files.remove(result.file);
      throw new Error('Image source does not match the requested SHA');
    }
    try {
      await this.index.commit(key, result.file, result.sha, result.bytes);
    } catch (error) {
      await this.files.remove(result.file);
      throw error;
    }
    if (previous && previous !== result.file)
      await this.files.remove(previous).catch(() => undefined);
    return result.file;
  }
  clear(): Promise<void> {
    if (this.clearing) return this.clearing;
    this.clearing = this.clearFiles().finally(() => {
      this.clearing = undefined;
    });
    return this.clearing;
  }
  private async clearFiles(): Promise<void> {
    await Promise.allSettled([...this.resolutions]);
    for (const [key, record] of Object.entries(await this.index.all())) {
      if (!key.startsWith('image:')) continue;
      if (record.file) await this.files.remove(record.file);
      await this.index.remove(key);
    }
  }
}
