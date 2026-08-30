import {
  createDefaultNotificationPreferences,
  serializeNotificationPreferencesForLocalStorage,
} from '../../../core/dto/notification-preferences';
import { STORAGE_KEYS } from '../../../core/storage/storage';
import type { StringStore } from '../../../services/storage/auth-storage';
import { AnnouncementPresentationService } from './announcement-presentation-service';
import { AppAnnouncement } from './app-announcement';

class MemoryStore implements StringStore {
  readonly values = new Map<string, string>();
  async getItem(key: string) {
    return this.values.get(key) ?? null;
  }
  async setItem(key: string, value: string) {
    this.values.set(key, value);
  }
  async removeItem(key: string) {
    this.values.delete(key);
  }
}

const announcement = (version: string) =>
  new AppAnnouncement(
    'announcement-1',
    'Anime Fury',
    'June update',
    version,
    null,
    null,
    null,
    'https://cdn.example.com/story.html',
    null,
  );

describe('AnnouncementPresentationService', () => {
  test('respects the announcement preference and versioned dismissal', async () => {
    const store = new MemoryStore();
    const enabled = {
      ...createDefaultNotificationPreferences('device-1', 'production'),
      announcements: true,
    };
    await store.setItem(
      STORAGE_KEYS.notificationSettings,
      JSON.stringify(serializeNotificationPreferencesForLocalStorage(enabled)),
    );
    const service = new AnnouncementPresentationService(store);

    await expect(service.shouldPresent(announcement('2'))).resolves.toBe(true);
    await service.markDismissed(announcement('2'));
    await expect(service.shouldPresent(announcement('2'))).resolves.toBe(false);
    await expect(service.shouldPresent(announcement('3'))).resolves.toBe(true);
  });

  test('defaults to hidden without a persisted opt-in', async () => {
    await expect(
      new AnnouncementPresentationService(new MemoryStore()).shouldPresent(announcement('2')),
    ).resolves.toBe(false);
  });
});
