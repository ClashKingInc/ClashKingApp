import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';

import {
  createDefaultNotificationPreferences,
  parseNotificationPreferences,
  serializeNotificationPreferencesForLocalStorage,
  serializeNotificationPreferencesForPut,
} from '../../../core/dto/notification-preferences';

describe('Legend defense notification contract', () => {
  it('keeps attacks retired while carrying defenses through every preference shape', () => {
    const defaults = createDefaultNotificationPreferences();
    const request = serializeNotificationPreferencesForPut(defaults);
    const decoded = parseNotificationPreferences({ ...request, accounts: [] });
    const stored = serializeNotificationPreferencesForLocalStorage(decoded);

    for (const value of [defaults, request, decoded, stored]) {
      expect(Object.keys(value).filter((key) => /legendAttacks/i.test(key))).toEqual([]);
    }
    expect(request).toMatchObject({ legendDefensesEnabled: false });
    expect(decoded).toMatchObject({ legendDefenses: false });
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
        /legendAttacks|legend_attacks_enabled/,
      );
    }
    expect(dto).toContain('legendDefenses');
    expect(settings).toContain("category: 'legendDefenses'");
    expect(settings).toContain("category: 'warAttacks'");
    expect(settings).toContain("category: 'warState'");
  });
});
