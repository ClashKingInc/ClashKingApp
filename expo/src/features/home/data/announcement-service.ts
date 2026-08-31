import type { ApiClient } from '../../../core/api/client';
import { isRecord } from '../../player/models/parsing';
import { AppAnnouncement } from './app-announcement';

export type AnnouncementTarget = 'ios' | 'android' | 'all';

export interface AnnouncementArchivePage {
  readonly items: readonly AppAnnouncement[];
  readonly hasMore: boolean;
  readonly nextOffset: number;
}

export function announcementTarget(platform: string): AnnouncementTarget {
  return platform === 'ios' ? 'ios' : platform === 'android' ? 'android' : 'all';
}

export class AnnouncementService {
  constructor(
    private readonly api: ApiClient,
    private readonly platform: string,
    private readonly locale: () => string,
  ) {}

  async getActiveAnnouncement(): Promise<AppAnnouncement | null> {
    return (await this.getActiveAnnouncements())[0] ?? null;
  }

  async getActiveAnnouncements(): Promise<readonly AppAnnouncement[]> {
    try {
      const response = await this.api.requestRecord(
        `/app/announcements/active?target=${announcementTarget(this.platform)}&locale=${encodeURIComponent(this.languageCode())}`,
        { requiresAuth: false },
      );
      return decodeAnnouncementCollection(response);
    } catch {
      return [];
    }
  }

  async getAnnouncement(id: string): Promise<AppAnnouncement | null> {
    const targetId = id.trim();
    if (!targetId) return null;
    try {
      const response = await this.api.requestRecord(
        `/app/announcements/${encodeURIComponent(targetId)}?locale=${encodeURIComponent(this.languageCode())}`,
        { requiresAuth: false },
      );
      return decodeAnnouncement(response.item ?? response);
    } catch {
      return null;
    }
  }

  async getPublishedPosts(limit = 20, offset = 0): Promise<AnnouncementArchivePage> {
    const response = await this.api.requestRecord(
      `/app/posts?target=${announcementTarget(this.platform)}&limit=${limit}&offset=${offset}&locale=${encodeURIComponent(this.languageCode())}`,
      { requiresAuth: false },
    );
    const items = Array.isArray(response.items)
      ? response.items
          .map(decodeAnnouncement)
          .filter((item): item is AppAnnouncement => item !== null)
      : [];
    return {
      items,
      hasMore: response.has_more === true,
      nextOffset:
        typeof response.next_offset === 'number'
          ? Math.trunc(response.next_offset)
          : offset + items.length,
    };
  }

  private languageCode(): string {
    return this.locale().replace('-', '_').split('_', 1)[0] || 'en';
  }
}

function decodeAnnouncementCollection(response: Record<string, unknown>): AppAnnouncement[] {
  if (Array.isArray(response.items)) {
    return response.items
      .map(decodeAnnouncement)
      .filter((item): item is AppAnnouncement => item !== null);
  }
  const item = decodeAnnouncement(response.item);
  return item ? [item] : [];
}

function decodeAnnouncement(value: unknown): AppAnnouncement | null {
  if (!isRecord(value)) return null;
  const item = AppAnnouncement.fromJson(value);
  return item.title && item.subtitle ? item : null;
}
