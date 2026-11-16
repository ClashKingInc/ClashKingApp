import { parseLocalNotificationPreferences } from '../../../core/dto/notification-preferences';
import { announcementDismissalStorageKey, STORAGE_KEYS } from '../../../core/storage/storage';
import type { StringStore } from '../../../services/storage/auth-storage';
import type { AppAnnouncement } from './app-announcement';

export class AnnouncementPresentationService {
  private readKeys: Promise<Set<string>> | undefined;
  private readWrite: Promise<void> = Promise.resolve();

  constructor(private readonly preferences: StringStore) {}

  private readHistory(): Promise<Set<string>> {
    return (this.readKeys ??= this.preferences
      .getItem(STORAGE_KEYS.readAnnouncements)
      .then((raw) => {
        const values: unknown = raw ? JSON.parse(raw) : [];
        return new Set(
          Array.isArray(values)
            ? values.filter((key): key is string => typeof key === 'string').slice(-1000)
            : [],
        );
      })
      .catch(() => new Set<string>()));
  }

  async getReadKeys(): Promise<ReadonlySet<string>> {
    return new Set(await this.readHistory());
  }

  async markRead(announcement: AppAnnouncement): Promise<void> {
    const keys = await this.readHistory();
    keys.delete(announcement.presentationKey);
    keys.add(announcement.presentationKey);
    // History is device-local and bounded. Serialize writes so rapidly opened
    // articles cannot replace a newer snapshot with an older one.
    while (keys.size > 1000) keys.delete(keys.values().next().value!);
    const encoded = JSON.stringify([...keys]);
    this.readWrite = this.readWrite
      .catch(() => {})
      .then(() => this.preferences.setItem(STORAGE_KEYS.readAnnouncements, encoded));
    await this.readWrite;
  }

  async shouldPresent(announcement: AppAnnouncement): Promise<boolean> {
    const raw = await this.preferences.getItem(STORAGE_KEYS.notificationSettings);
    if (raw === null) return false;

    const settings = parseLocalNotificationPreferences(JSON.parse(raw) as unknown);
    if (!settings.announcements) return false;

    return (
      (await this.preferences.getItem(
        announcementDismissalStorageKey(announcement.presentationKey),
      )) !== 'true'
    );
  }

  markDismissed(announcement: AppAnnouncement): Promise<void> {
    return this.preferences.setItem(
      announcementDismissalStorageKey(announcement.presentationKey),
      'true',
    );
  }

  clearDismissal(announcement: AppAnnouncement): Promise<void> {
    return this.preferences.removeItem(
      announcementDismissalStorageKey(announcement.presentationKey),
    );
  }
}
