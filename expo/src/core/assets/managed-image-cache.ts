import { FileUpdateIndex } from './file-update-index';

export interface ImageRequest {
  url: string;
  path: string;
  sha: string;
  size?: number;
}

type SavedImage = ReturnType<FileUpdateIndex['imagesForPath']>[number];
type Download = { request: ImageRequest; promise: Promise<string> };

function capacity(record: SavedImage): number {
  if (record.fullSize) return Infinity;
  // Older installs have the requested size in the URL but no decoded metadata.
  return (
    record.pixels ??
    (Number(new URL(record.key.slice('image:'.length)).searchParams.get('size')) || 0)
  );
}

function covers(request: ImageRequest, record: SavedImage): boolean {
  return record.key === 'image:' + request.url || capacity(record) >= (request.size ?? Infinity);
}

export interface ImageFiles {
  exists(file: string): Promise<boolean>;
  download(
    request: ImageRequest,
    signal?: AbortSignal,
    validateReplacement?: boolean,
  ): Promise<{ file: string; sha: string; bytes: number; pixels?: number; fullSize?: boolean }>;
  remove(file: string): Promise<void>;
  clearAll?(): Promise<void>;
}

/** Shares suitable variants of the same source without changing the on-disk URL keys. */
export class ManagedImageCache {
  private static readonly UNUSED_EXPIRY_MS = 30 * 24 * 60 * 60 * 1_000;
  private readonly downloads = new Map<string, Set<Download>>();
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
  subscribeImage(path: string, listener: () => void) {
    return this.index.subscribeImage(path, listener);
  }
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
  private candidates(request: ImageRequest): SavedImage[] {
    return this.index
      .imagesForPath(request.path)
      .filter((record) => covers(request, record))
      .sort(
        (a, b) =>
          Number(b.installedSha === request.sha) - Number(a.installedSha === request.sha) ||
          a.bytes - b.bytes,
      );
  }
  peek(request: ImageRequest) {
    return this.candidates(request)[0]?.file;
  }
  async resolve(request: ImageRequest, showSaved: (file: string) => void): Promise<string> {
    if (this.clearing) await this.clearing;
    const operation = this.resolveActive(request, showSaved, this.generation);
    this.resolutions.add(operation);
    try {
      return await operation;
    } finally {
      this.resolutions.delete(operation);
    }
  }
  private async resolveActive(
    request: ImageRequest,
    showSaved: (file: string) => void,
    generation: number,
  ): Promise<string> {
    const ensureActive = () => {
      if (generation !== this.generation) throw new Error('Image cache was cleared');
    };
    await this.hydrate();
    ensureActive();
    let saved: SavedImage | undefined;
    for (const record of this.candidates(request)) {
      const exists = await this.files.exists(record.file);
      ensureActive();
      if (exists) {
        saved = record;
        break;
      }
      await this.index.removeImageFile(record.key, record.file);
      ensureActive();
    }
    if (saved) {
      showSaved(saved.file);
      await this.index.prepare(saved.key, request.path, request.sha);
      ensureActive();
      if (saved.installedSha === request.sha) return saved.file;
    }

    const key = 'image:' + request.url;
    // A sibling may have finished while this request was checking files.
    const current = this.candidates(request).find((item) => item.installedSha === request.sha);
    if (current && (await this.files.exists(current.file))) {
      ensureActive();
      return current.file;
    }
    ensureActive();
    const group = request.path + ':' + request.sha;
    const running = this.downloads.get(group) ?? new Set<Download>();
    let download = [...running].find(
      ({ request: other }) =>
        other.url === request.url || (other.size ?? Infinity) >= (request.size ?? Infinity),
    );
    if (!download) {
      const previous = this.index.peek(key)?.file ?? null;
      const validateReplacement = Boolean(previous || saved);
      const promise = this.replace(key, request, previous, generation, validateReplacement);
      download = { request, promise };
      const entry = download;
      running.add(entry);
      this.downloads.set(group, running);
      void promise
        .finally(() => {
          running.delete(entry);
          if (!running.size) this.downloads.delete(group);
        })
        .catch(() => undefined);
    }
    try {
      return await download.promise;
    } catch (error) {
      ensureActive();
      if (saved) return saved.file;
      // A larger request can fail independently of the requested variant.
      if (download.request.url !== request.url)
        return this.resolveActive(request, showSaved, generation);
      throw error;
    }
  }
  async invalidate(path: string, file: string): Promise<void> {
    const saved = this.index.imagesForPath(path).find((item) => item.file === file);
    if (!saved) return;
    await this.index.removeImageFile(saved.key, file);
    await this.files.remove(file);
  }
  private async replace(
    key: string,
    request: ImageRequest,
    previous: string | null,
    generation: number,
    validateReplacement: boolean,
  ): Promise<string> {
    const controller = new AbortController();
    this.controllers.add(controller);
    let result;
    try {
      result = await this.files.download(request, controller.signal, validateReplacement);
    } finally {
      this.controllers.delete(controller);
    }
    if (generation !== this.generation) {
      await this.files.remove(result.file);
      throw new Error('Image cache was cleared');
    }
    if (result.sha !== request.sha) {
      await this.files.remove(result.file);
      throw new Error('Image source does not match the requested SHA');
    }
    try {
      await this.index.commitImage(key, request.path, result);
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
