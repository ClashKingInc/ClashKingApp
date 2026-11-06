import { FileUpdateIndex } from './file-update-index';

export interface ImageFiles {
  exists(file: string): Promise<boolean>;
  download(
    url: string,
    expectedSha: string,
    signal?: AbortSignal,
  ): Promise<{ file: string; sha: string; bytes: number }>;
  remove(file: string): Promise<void>;
  clearAll?(): Promise<void>;
}

/** Owns originals and each requested size independently; never downloads from notice(). */
export class ManagedImageCache {
  private static readonly UNUSED_EXPIRY_MS = 30 * 24 * 60 * 60 * 1_000;
  private readonly downloads = new Map<string, Promise<string>>();
  private readonly resolutions = new Set<Promise<string>>();
  private clearing?: Promise<void>;
  private generation = 0;
  private controllers = new Set<AbortController>();
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
    const operation = this.resolveActive(url, path, expectedSha, showSaved, this.generation);
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
    generation: number,
  ): Promise<string> {
    const ensureActive = () => {
      if (generation !== this.generation) throw new Error('Image cache was cleared');
    };
    const key = 'image:' + url;
    await this.hydrate();
    ensureActive();
    const record = await this.index.prepare(key, path, expectedSha);
    ensureActive();
    const saved = record.file && (await this.files.exists(record.file)) ? record.file : null;
    ensureActive();
    if (saved) showSaved(saved);
    if (saved && record.installedSha === expectedSha && !record.pendingSha) return saved;
    const target = record.pendingSha ?? expectedSha;
    const downloadKey = key + ':' + target;
    let download = this.downloads.get(downloadKey);
    if (!download) {
      download = this.replace(key, url, target, saved, generation);
      this.downloads.set(downloadKey, download);
      void download.finally(() => this.downloads.delete(downloadKey)).catch(() => undefined);
    }
    try {
      return await download;
    } catch (error) {
      ensureActive();
      if (saved) return saved;
      throw error;
    }
  }
  private async replace(
    key: string,
    url: string,
    target: string,
    previous: string | null,
    generation: number,
  ): Promise<string> {
    const controller = new AbortController();
    this.controllers.add(controller);
    let result;
    try {
      result = await this.files.download(url, target, controller.signal);
    } finally {
      this.controllers.delete(controller);
    }
    if (generation !== this.generation) {
      await this.files.remove(result.file);
      throw new Error('Image cache was cleared');
    }
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
    // Invalidate first: late downloads must not repopulate a cleared cache.
    this.generation++;
    for (const controller of this.controllers) controller.abort();
    await Promise.allSettled([...this.resolutions]);
    const records = Object.entries(await this.index.all()).filter(([key]) =>
      key.startsWith('image:'),
    );
    if (this.files.clearAll) await this.files.clearAll();
    else
      await Promise.all(
        records.map(([, record]) =>
          record.file ? this.files.remove(record.file) : Promise.resolve(),
        ),
      );
    await this.index.removeMany(records.map(([key]) => key));
  }
}
