import {
  ActiveAnnouncementsEndpoint,
  AnnouncementEndpoint,
  PostsEndpoint,
} from '@clashking/api-contracts/expo';
import { Effect } from 'effect';

import type { ContractApiService } from '../../../core/api/contract-api';
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
    private readonly api: ContractApiService,
    private readonly platform: string,
    private readonly locale: () => string,
  ) {}

  async getActiveAnnouncement(): Promise<AppAnnouncement | null> {
    return (await this.getActiveAnnouncements())[0] ?? null;
  }

  async getActiveAnnouncements(): Promise<readonly AppAnnouncement[]> {
    try {
      const response = await Effect.runPromise(
        this.api.execute(ActiveAnnouncementsEndpoint, {
          path: {},
          query: {
            target: announcementTarget(this.platform),
            locale: this.languageCode(),
          },
          body: {},
        }),
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
      const response = await Effect.runPromise(
        this.api.execute(AnnouncementEndpoint, {
          path: { announcementId: targetId },
          query: { locale: this.languageCode() },
          body: {},
        }),
      );
      return decodeAnnouncement(response.item ?? response);
    } catch {
      return null;
    }
  }

  async getPublishedPosts(limit = 20, offset = 0): Promise<AnnouncementArchivePage> {
    const response = await Effect.runPromise(
      this.api.execute(PostsEndpoint, {
        path: {},
        query: {
          target: announcementTarget(this.platform),
          limit,
          offset,
          locale: this.languageCode(),
        },
        body: {},
      }),
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
