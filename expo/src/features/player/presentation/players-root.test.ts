import {
  createDefaultNotificationPreferences,
  type NotificationAccount,
} from '../../../core/dto/notification-preferences';
import { withUpdatedNotificationAccount } from './players-root-state';

describe('PlayersRoot notification state', () => {
  const verified: NotificationAccount = {
    playerTag: '#AAA',
    source: 'verified',
    active: true,
  };

  test('replaces an account case-insensitively without duplicating it', () => {
    const preferences = {
      ...createDefaultNotificationPreferences(),
      accounts: [{ ...verified, playerTag: '#aaa', active: false }],
    };

    expect(withUpdatedNotificationAccount(preferences, verified).accounts).toEqual([verified]);
  });

  test('removes an account when the server returns it inactive', () => {
    const preferences = {
      ...createDefaultNotificationPreferences(),
      accounts: [verified],
    };

    expect(
      withUpdatedNotificationAccount(preferences, { ...verified, active: false }).accounts,
    ).toEqual([]);
  });
});
