import {
  createDefaultNotificationPreferences,
  type NotificationAccount,
} from '../../../core/dto/notification-preferences';
import { withUpdatedNotificationAccount } from './players-root-state';

describe('PlayersRoot notification state', () => {
  const verified: NotificationAccount = {
    tag: '#AAA',
    enabled: true,
  };

  test('replaces an account case-insensitively without duplicating it', () => {
    const preferences = {
      ...createDefaultNotificationPreferences(),
      accounts: [{ ...verified, tag: '#aaa', enabled: false }],
    };

    expect(withUpdatedNotificationAccount(preferences, verified).accounts).toEqual([verified]);
  });

  test('retains an account when the server returns it disabled', () => {
    const preferences = {
      ...createDefaultNotificationPreferences(),
      accounts: [verified],
    };

    expect(
      withUpdatedNotificationAccount(preferences, { ...verified, enabled: false }).accounts,
    ).toEqual([{ ...verified, enabled: false }]);
  });
});
