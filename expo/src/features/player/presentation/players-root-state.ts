import type {
  NotificationAccount,
  NotificationPreferences,
} from '../../../core/dto/notification-preferences';
import { canonicalTag } from '../../../core/domain/tags';

export function withUpdatedNotificationAccount(
  preferences: NotificationPreferences,
  updated: NotificationAccount,
): NotificationPreferences {
  const tag = canonicalTag(updated.tag);
  const accounts = preferences.accounts.filter(
    (account) => canonicalTag(account.tag) !== tag,
  );
  return {
    ...preferences,
    accounts: [...accounts, updated],
  };
}
