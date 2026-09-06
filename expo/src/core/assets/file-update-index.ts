export interface LocalFileRecord {
  path: string;
  file: string | null;
  sha: string | null;
  pendingSha: string | null;
  bytes: number;
  usedAt: number;
}
interface Storage {
  getString(key: string): Promise<string | null>;
  setString(key: string, value: string): Promise<void>;
}
const KEY = 'asset-local-files-v2';

/** Persistent installed/pending inventory; all mutations serialize, downloads do not. */
export class FileUpdateIndex {
  private tail: Promise<unknown> = Promise.resolve();
  private available: ReadonlyMap<string, string> = new Map();
  constructor(private readonly storage: Storage) {}
  private transact<T>(run: (records: Record<string, LocalFileRecord>) => T, write = true): Promise<T> {
    const operation = this.tail.then(async () => {
      const raw = await this.storage.getString(KEY);
      const records: Record<string, LocalFileRecord> = raw ? JSON.parse(raw) : {};
      const result = run(records);
      if (write) await this.storage.setString(KEY, JSON.stringify(records));
      return result;
    });
    this.tail = operation.catch(() => undefined);
    return operation;
  }
  all() { return this.transact((records) => ({ ...records }), false); }
  get(key: string) { return this.transact((records) => records[key] ? { ...records[key] } : undefined, false); }
  async notice(available: ReadonlyMap<string, string>): Promise<void> {
    await this.transact((records) => {
      for (const record of Object.values(records)) {
        const target = available.get(record.path);
        if (target) record.pendingSha = record.sha === target ? null : target;
      }
    });
    this.available = available;
  }
  prepare(key: string, path: string, expected?: string) {
    return this.transact((records) => {
      const record = records[key] ?? { path, file: null, sha: null, pendingSha: null, bytes: 0, usedAt: Date.now() };
      const target = this.available.get(path) ?? record.pendingSha ?? expected;
      if (target) record.pendingSha = record.sha === target ? null : target;
      record.usedAt = Date.now();
      records[key] = record;
      return { ...record };
    });
  }
  commit(key: string, file: string, sha: string, bytes = 0) {
    return this.transact((records) => {
      const record = records[key];
      if (!record) throw new Error('Missing local asset record');
      records[key] = { ...record, file, sha, bytes, usedAt: Date.now(),
        pendingSha: record.pendingSha === sha ? null :
          (record.pendingSha ?? (record.sha && record.sha !== sha ? record.sha : null)) };
    });
  }
  remove(key: string) { return this.transact((records) => { delete records[key]; }); }
}
