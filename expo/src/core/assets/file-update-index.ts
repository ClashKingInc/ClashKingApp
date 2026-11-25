export interface LocalFileRecord {
  path: string;
  file: string | null;
  installedSha: string | null;
  pendingSha: string | null;
  bytes: number;
  lastViewed: number;
  pixels?: number;
  fullSize?: boolean;
}
export interface FileIndexStorage {
  getString(key: string): Promise<string | null>;
  setString(key: string, value: string): Promise<void>;
  getKeys(): Promise<readonly string[]>;
  getMany(keys: readonly string[]): Promise<readonly (readonly [string, string | null])[]>;
  removeString(key: string): Promise<void>;
  removeStrings?(keys: readonly string[]): Promise<void>;
}
const LEGACY_KEY = 'asset-local-files-v2';
const PREFIX = 'asset-local-file-v3:';
const IMAGE_PREFIX = PREFIX + encodeURIComponent('image:');
const LAST_VIEWED_WRITE_INTERVAL_MS = 24 * 60 * 60 * 1_000;

/** Installed image files, hydrated on first use. Writes to the same file serialize. */
export class FileUpdateIndex {
  private readonly records = new Map<string, LocalFileRecord>();
  private readonly imageKeysByPath = new Map<string, Set<string>>();
  private readonly tails = new Map<string, Promise<unknown>>();
  private readonly listeners = new Set<() => void>();
  private readonly imageListeners = new Map<string, Set<() => void>>();
  private hydration?: Promise<void>;
  private revision = 0;
  constructor(
    private readonly storage: FileIndexStorage,
    private readonly now: () => number = Date.now,
    private readonly availableVersion: (path: string) => string | undefined = () => undefined,
  ) {}
  subscribe = (listener: () => void) => {
    this.listeners.add(listener);
    return () => {
      this.listeners.delete(listener);
    };
  };
  getRevision = () => this.revision;
  subscribeImage(path: string, listener: () => void) {
    const listeners = this.imageListeners.get(path) ?? new Set<() => void>();
    listeners.add(listener);
    this.imageListeners.set(path, listeners);
    return () => {
      listeners.delete(listener);
      if (!listeners.size) this.imageListeners.delete(path);
    };
  }
  private changed(imagePaths: Iterable<string> = this.imageListeners.keys()) {
    this.revision++;
    for (const listener of this.listeners) listener();
    for (const path of imagePaths)
      for (const listener of this.imageListeners.get(path) ?? []) listener();
  }
  hydrate(): Promise<void> {
    if (!this.hydration)
      this.hydration = this.load().catch((error) => {
        this.hydration = undefined;
        throw error;
      });
    return this.hydration;
  }
  private async load() {
    const keys = (await this.storage.getKeys()).filter((key) => key.startsWith(IMAGE_PREFIX));
    const loaded = new Map<string, LocalFileRecord>();
    for (let offset = 0; offset < keys.length; offset += 128) {
      for (const [key, raw] of await this.storage.getMany(keys.slice(offset, offset + 128))) {
        if (raw) {
          const record = this.decode(raw);
          loaded.set(decodeURIComponent(key.slice(PREFIX.length)), record);
          if (raw !== JSON.stringify(record))
            await this.storage.setString(key, JSON.stringify(record));
        }
      }
    }
    const legacy = await this.storage.getString(LEGACY_KEY);
    if (legacy) {
      for (const [key, value] of Object.entries(JSON.parse(legacy))) {
        if (!key.startsWith('image:') || loaded.has(key)) continue;
        const record = this.decode(JSON.stringify(value));
        await this.storage.setString(PREFIX + encodeURIComponent(key), JSON.stringify(record));
        loaded.set(key, record);
      }
      // Delete only after all records have been durably migrated.
      await this.storage.removeString(LEGACY_KEY);
    }
    for (const [key, record] of loaded) this.setRecord(key, record);
    this.changed();
  }
  private decode(raw: string): LocalFileRecord {
    const parsed = JSON.parse(raw);
    const { path, file, pendingSha, bytes } = parsed;
    const installedSha = parsed.installedSha ?? parsed.sha ?? null;
    const lastViewed = parsed.lastViewed ?? this.now();
    if (
      typeof path !== 'string' ||
      (file !== null && typeof file !== 'string') ||
      (installedSha !== null && typeof installedSha !== 'string') ||
      (pendingSha !== null && typeof pendingSha !== 'string') ||
      typeof bytes !== 'number' ||
      !Number.isFinite(bytes) ||
      bytes < 0 ||
      typeof lastViewed !== 'number' ||
      !Number.isFinite(lastViewed) ||
      lastViewed < 0
    )
      throw new Error('Invalid local file record');
    const pixels =
      typeof parsed.pixels === 'number' && parsed.pixels > 0 && Number.isFinite(parsed.pixels)
        ? parsed.pixels
        : undefined;
    const fullSize = parsed.fullSize === true ? true : undefined;
    return { path, file, installedSha, pendingSha, bytes, lastViewed, pixels, fullSize };
  }
  private setRecord(key: string, next?: LocalFileRecord) {
    const previous = this.records.get(key);
    if (key.startsWith('image:') && previous?.path !== next?.path) {
      if (previous) {
        const keys = this.imageKeysByPath.get(previous.path);
        keys?.delete(key);
        if (!keys?.size) this.imageKeysByPath.delete(previous.path);
      }
      if (next) {
        const keys = this.imageKeysByPath.get(next.path) ?? new Set<string>();
        keys.add(key);
        this.imageKeysByPath.set(next.path, keys);
      }
    }
    if (next) this.records.set(key, next);
    else this.records.delete(key);
  }
  imagesForPath(path: string) {
    return [...(this.imageKeysByPath.get(path) ?? [])].flatMap((key) => {
      const record = this.records.get(key);
      return record?.file ? [{ key, ...record, file: record.file }] : [];
    });
  }
  peek(key: string) {
    const record = this.records.get(key);
    return record ? { ...record } : undefined;
  }
  imageBytes = () =>
    [...this.records].reduce(
      (sum, [key, record]) => sum + (key.startsWith('image:') && record.file ? record.bytes : 0),
      0,
    );
  async unusedImagesBefore(cutoff: number) {
    await this.hydrate();
    return [...this.records]
      .filter(([key, record]) => key.startsWith('image:') && record.lastViewed < cutoff)
      .map(([key, record]) => [key, { ...record }] as const);
  }
  async all() {
    await this.hydrate();
    return Object.fromEntries([...this.records].map(([key, record]) => [key, { ...record }]));
  }
  private async update(
    key: string,
    transform: (record?: LocalFileRecord) => LocalFileRecord | undefined,
  ) {
    await this.hydrate();
    const operation = (this.tails.get(key) ?? Promise.resolve()).then(async () => {
      const before = this.records.get(key);
      const next = transform(before ? { ...before } : undefined);
      if (JSON.stringify(before) !== JSON.stringify(next)) {
        if (next)
          await this.storage.setString(PREFIX + encodeURIComponent(key), JSON.stringify(next));
        else await this.storage.removeString(PREFIX + encodeURIComponent(key));
        this.setRecord(key, next);
        const path = next?.path ?? before?.path;
        this.changed(key.startsWith('image:') && path !== undefined ? [path] : []);
      }
      return next ? { ...next } : undefined;
    });
    this.tails.set(key, operation);
    try {
      return await operation;
    } finally {
      if (this.tails.get(key) === operation) this.tails.delete(key);
    }
  }
  async prepare(key: string, path: string, expected?: string): Promise<LocalFileRecord> {
    return (await this.update(key, (saved) => {
      const viewedAt = this.now();
      const record = saved ?? {
        path,
        file: null,
        installedSha: null,
        pendingSha: null,
        bytes: 0,
        lastViewed: viewedAt,
      };
      const target = this.availableVersion(path) ?? record.pendingSha ?? expected;
      if (target) record.pendingSha = record.installedSha === target ? null : target;
      if (viewedAt - record.lastViewed >= LAST_VIEWED_WRITE_INTERVAL_MS)
        record.lastViewed = viewedAt;
      return record;
    }))!;
  }
  async commitImage(
    key: string,
    path: string,
    image: { file: string; sha: string; bytes: number; pixels?: number; fullSize?: boolean },
  ) {
    await this.update(key, (record) => {
      const target = this.availableVersion(path) ?? record?.pendingSha;
      if (target && target !== image.sha) throw new Error('Image version was superseded');
      return {
        path,
        file: image.file,
        installedSha: image.sha,
        pendingSha: null,
        bytes: image.bytes,
        lastViewed: this.now(),
        pixels: image.pixels,
        fullSize: image.fullSize || undefined,
      };
    });
  }
  /** Batch cache resets and notify mounted images once, not once per file. */
  async removeMany(keys: readonly string[]) {
    await this.hydrate();
    await Promise.allSettled(keys.map((key) => this.tails.get(key)));
    const storageKeys = keys.map((key) => PREFIX + encodeURIComponent(key));
    if (this.storage.removeStrings) await this.storage.removeStrings(storageKeys);
    else await Promise.all(storageKeys.map((key) => this.storage.removeString(key)));
    const imagePaths = new Set<string>();
    for (const key of keys) {
      const record = this.records.get(key);
      if (key.startsWith('image:') && record) imagePaths.add(record.path);
      this.setRecord(key);
    }
    if (keys.length) this.changed(imagePaths);
  }
  async remove(key: string) {
    await this.update(key, () => undefined);
  }

  async removeImageFile(key: string, file: string) {
    await this.update(key, (record) => (record?.file === file ? undefined : record));
  }
}
