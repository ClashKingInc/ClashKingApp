import type {
  NotificationAccount,
  NotificationPreferences,
} from '../../../core/dto/notification-preferences';
import { canonicalTag } from '../../../core/domain/tags';

export function withUpdatedNotificationAccount(
  preferences: NotificationPreferences,
  updated: NotificationAccount,
): NotificationPreferences {
  const tag = canonicalTag(updated.playerTag);
  const accounts = preferences.accounts.filter(
    (account) => canonicalTag(account.playerTag) !== tag,
  );
  return {
    ...preferences,
    accounts: updated.active ? [...accounts, updated] : accounts,
  };
}
