import { parseLocalNotificationPreferences } from '../../../core/dto/notification-preferences';
import { announcementDismissalStorageKey, STORAGE_KEYS } from '../../../core/storage/storage';
import type { StringStore } from '../../../services/storage/auth-storage';
import type { AppAnnouncement } from './app-announcement';

export class AnnouncementPresentationService {
  constructor(private readonly preferences: StringStore) {}

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
