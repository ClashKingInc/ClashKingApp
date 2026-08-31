import { Directory, File, Paths } from 'expo-file-system';

import type { AppAnnouncement } from './app-announcement';

export interface AnnouncementStoryCacheAdapter {
  cachedUri(fileName: string): Promise<string | null>;
  download(url: string, fileName: string): Promise<string | null>;
}

export class ExpoAnnouncementStoryCacheAdapter implements AnnouncementStoryCacheAdapter {
  async cachedUri(fileName: string): Promise<string | null> {
    const file = this.file(fileName);
    return file.exists && (file.size ?? 0) > 0 ? file.uri : null;
  }

  async download(url: string, fileName: string): Promise<string | null> {
    const directory = new Directory(Paths.document, 'announcement_stories');
    directory.create({ intermediates: true, idempotent: true });

    const destination = new File(directory, fileName);
    const temporary = new File(directory, `${fileName}.download`);
    if (temporary.exists) temporary.delete();

    try {
      const downloaded = await File.downloadFileAsync(url, temporary, { idempotent: true });
      if ((downloaded.size ?? 0) <= 0) return null;
      await downloaded.move(destination, { overwrite: true });
      return destination.uri;
    } finally {
      if (temporary.exists) temporary.delete();
    }
  }

  private file(fileName: string): File {
    return new File(Paths.document, 'announcement_stories', fileName);
  }
}

export class AnnouncementStoryCacheService {
  private static readonly inFlight = new Map<string, Promise<string | null>>();

  constructor(
    private readonly adapter: AnnouncementStoryCacheAdapter = new ExpoAnnouncementStoryCacheAdapter(),
  ) {}

  prepare(announcement: AppAnnouncement): Promise<string | null> {
    const storyUrl = announcement.storyUrl;
    if (!isTrustedHttpsUrl(storyUrl)) return Promise.resolve(null);

    const existing = AnnouncementStoryCacheService.inFlight.get(announcement.presentationKey);
    if (existing) return existing;

    const operation = this.prepareStory(
      storyUrl,
      `${safeAnnouncementStoryName(announcement.presentationKey)}.html`,
    ).finally(() => AnnouncementStoryCacheService.inFlight.delete(announcement.presentationKey));
    AnnouncementStoryCacheService.inFlight.set(announcement.presentationKey, operation);
    return operation;
  }

  private async prepareStory(url: string, fileName: string): Promise<string | null> {
    try {
      return (
        (await this.adapter.cachedUri(fileName)) ?? (await this.adapter.download(url, fileName))
      );
    } catch {
      return null;
    }
  }
}

export function safeAnnouncementStoryName(value: string): string {
  return value.replace(/[^a-zA-Z0-9._-]/g, '_');
}

export function isTrustedHttpsUrl(value: string | null | undefined): value is string {
  if (!value) return false;
  try {
    const url = new URL(value);
    return url.protocol === 'https:' && url.hostname.length > 0;
  } catch {
    return false;
  }
}

export const sharedAnnouncementStoryCache = new AnnouncementStoryCacheService();
