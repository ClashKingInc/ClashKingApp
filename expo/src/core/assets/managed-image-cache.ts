import { FileUpdateIndex } from './file-update-index';

export interface ImageFiles {
  exists(file: string): Promise<boolean>;
  download(url: string, expectedSha: string): Promise<{ file: string; sha: string; bytes: number }>;
  remove(file: string): Promise<void>;
}

/** Owns originals and each requested size independently; never downloads from notice(). */
export class ManagedImageCache {
  private readonly downloads = new Map<string, Promise<string>>();
  constructor(private readonly index: FileUpdateIndex, private readonly files: ImageFiles) {}
  async resolve(url: string, path: string, expectedSha: string, showSaved: (file: string) => void): Promise<string> {
    const key = 'image:' + url;
    const record = await this.index.prepare(key, path, expectedSha);
    const saved = record.file && await this.files.exists(record.file) ? record.file : null;
    if (saved) showSaved(saved);
    if (saved && record.sha === expectedSha && !record.pendingSha) return saved;
    const target = record.pendingSha ?? expectedSha;
    const downloadKey = key + ':' + target;
    let download = this.downloads.get(downloadKey);
    if (!download) {
      download = this.replace(key, url, target, saved);
      this.downloads.set(downloadKey, download);
      void download.finally(() => this.downloads.delete(downloadKey)).catch(() => undefined);
    }
    try { return await download; }
    catch (error) { if (saved) return saved; throw error; }
  }
  private async replace(key: string, url: string, target: string, previous: string | null): Promise<string> {
    const result = await this.files.download(url, target);
    if (result.sha !== target) {
      await this.files.remove(result.file);
      throw new Error('Image source does not match the requested SHA');
    }
    try { await this.index.commit(key, result.file, result.sha, result.bytes); }
    catch (error) { await this.files.remove(result.file); throw error; }
    if (previous && previous !== result.file) await this.files.remove(previous).catch(() => undefined);
    await this.trim(key);
    return result.file;
  }
  private async trim(keep: string): Promise<void> {
    const records = Object.entries(await this.index.all()).filter(([key]) => key.startsWith('image:'));
    let bytes = records.reduce((sum, [, record]) => sum + record.bytes, 0);
    let count = records.length;
    for (const [key, record] of records.sort((a, b) => a[1].usedAt - b[1].usedAt)) {
      if (count <= 512 && bytes <= 256 * 1024 * 1024) break;
      if (key === keep) continue;
      if (record.file) await this.files.remove(record.file);
      await this.index.remove(key);
      bytes -= record.bytes;
      count--;
    }
  }
  async clear(): Promise<void> {
    await Promise.allSettled(this.downloads.values());
    for (const [key, record] of Object.entries(await this.index.all())) {
      if (!key.startsWith('image:')) continue;
      if (record.file) await this.files.remove(record.file);
      await this.index.remove(key);
    }
  }
}
