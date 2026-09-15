export interface LocalFileRecord {
  path: string;
  file: string | null;
  installedSha: string | null;
  pendingSha: string | null;
  bytes: number;
  lastViewed: number;
}
export interface FileIndexStorage {
  getString(key: string): Promise<string | null>;
  setString(key: string, value: string): Promise<void>;
  getKeys(): Promise<readonly string[]>;
  getMany(keys: readonly string[]): Promise<readonly (readonly [string, string | null])[]>;
  removeString(key: string): Promise<void>;
}
const LEGACY_KEY = 'asset-local-files-v2';
const PREFIX = 'asset-local-file-v3:';
const LAST_VIEWED_WRITE_INTERVAL_MS = 24 * 60 * 60 * 1_000;

/** One persistent record per file, hydrated once; only writes to the same file serialize. */
export class FileUpdateIndex {
  private readonly records = new Map<string, LocalFileRecord>();
  private readonly tails = new Map<string, Promise<unknown>>();
  private readonly listeners = new Set<() => void>();
  private available: ReadonlyMap<string, string> = new Map();
  private hydration?: Promise<void>;
  private revision = 0;
  constructor(
    private readonly storage: FileIndexStorage,
    private readonly now: () => number = Date.now,
  ) {}
  subscribe = (listener: () => void) => {
    this.listeners.add(listener);
    return () => {
      this.listeners.delete(listener);
    };
  };
  getRevision = () => this.revision;
  private changed() {
    this.revision++;
    for (const listener of this.listeners) listener();
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
    const keys = (await this.storage.getKeys()).filter((key) => key.startsWith(PREFIX));
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
        if (loaded.has(key)) continue;
        const record = this.decode(JSON.stringify(value));
        await this.storage.setString(PREFIX + encodeURIComponent(key), JSON.stringify(record));
        loaded.set(key, record);
      }
      // Delete only after all records have been durably migrated.
      await this.storage.removeString(LEGACY_KEY);
    }
    for (const [key, record] of loaded) this.records.set(key, record);
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
    return { path, file, installedSha, pendingSha, bytes, lastViewed };
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
  async get(key: string) {
    await this.hydrate();
    return this.peek(key);
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
        if (next) this.records.set(key, next);
        else this.records.delete(key);
        this.changed();
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
  async notice(available: ReadonlyMap<string, string>): Promise<void> {
    await this.hydrate();
    this.available = available;
    await Promise.all(
      [...this.records.keys()].map((key) =>
        this.update(key, (record) => {
          if (!record) return;
          const target = this.available.get(record.path);
          if (target) record.pendingSha = record.installedSha === target ? null : target;
          return record;
        }),
      ),
    );
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
      const target = this.available.get(path) ?? record.pendingSha ?? expected;
      if (target) record.pendingSha = record.installedSha === target ? null : target;
      if (viewedAt - record.lastViewed >= LAST_VIEWED_WRITE_INTERVAL_MS)
        record.lastViewed = viewedAt;
      return record;
    }))!;
  }
  async commit(key: string, file: string, sha: string, bytes = 0) {
    await this.update(key, (record) => {
      if (!record) throw new Error('Missing local asset record');
      const target = this.available.get(record.path) ?? record.pendingSha ?? record.installedSha;
      return {
        ...record,
        file,
        installedSha: sha,
        bytes,
        pendingSha: !target || target === sha ? null : target,
      };
    });
  }
  async remove(key: string) {
    await this.update(key, () => undefined);
  }
}
