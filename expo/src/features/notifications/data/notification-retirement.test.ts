import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';

import {
  createDefaultNotificationPreferences,
  parseNotificationPreferences,
  serializeNotificationPreferencesForLocalStorage,
  serializeNotificationPreferencesForPut,
} from '../../../core/dto/notification-preferences';

describe('user-confirmed Legend notification retirement', () => {
  it('keeps retired preferences out of defaults, decoded state, requests, and local storage', () => {
    const defaults = createDefaultNotificationPreferences('device-1', 'production');
    const request = serializeNotificationPreferencesForPut(defaults, 'device-1', 'production');
    const decoded = parseNotificationPreferences({ ...request, accounts: [] });
    const stored = serializeNotificationPreferencesForLocalStorage(decoded);

    for (const value of [defaults, request, decoded, stored]) {
      expect(Object.keys(value).filter((key) => /legend/i.test(key))).toEqual([]);
      expect(value.notificationsEnabled).toBe(false);
    }
    expect(request).toMatchObject({ warAttacksEnabled: false, raidRemindersEnabled: false });
    expect(decoded).toMatchObject({ warAttacks: false, raidReminders: false });
  });

  it('does not reintroduce retired model fields or settings controls', () => {
    const dto = readFileSync(
      resolve(process.cwd(), 'src/core/dto/notification-preferences.ts'),
      'utf8',
    );
    const settings = readFileSync(
      resolve(process.cwd(), 'src/features/settings/presentation/notification-settings-screen.tsx'),
      'utf8',
    );
    for (const source of [dto, settings]) {
      expect(source).not.toMatch(
        /legendAttacks|legendDefenses|legend_attacks_enabled|legend_defenses_enabled/,
      );
    }
    expect(settings).toContain("category: 'warAttacks'");
    expect(settings).toContain("category: 'warState'");
  });
});
