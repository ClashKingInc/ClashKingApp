export type NotificationCategory =
  | 'warAttacks'
  | 'warState'
  | 'warReminders'
  | 'raidReminders'
  | 'events'
  | 'announcements'
  | 'monthlySupport'
  | 'legendDefenses';

export interface NotificationAccount {
  readonly tag: string;
  readonly enabled: boolean;
}

export interface NotificationPreferences {
  readonly warAttacks: boolean;
  readonly warState: boolean;
  readonly warReminders: boolean;
  readonly raidReminders: boolean;
  readonly events: boolean;
  readonly announcements: boolean;
  readonly monthlySupport: boolean;
  readonly legendDefenses: boolean;
  readonly reminderTimings: readonly number[];
  readonly raidReminderTimings: readonly number[];
  readonly accounts: readonly NotificationAccount[];
}

export function createDefaultNotificationPreferences(): NotificationPreferences {
  return {
    warAttacks: false,
    warState: false,
    warReminders: false,
    raidReminders: false,
    events: false,
    announcements: false,
    monthlySupport: false,
    legendDefenses: false,
    reminderTimings: [],
    raidReminderTimings: [],
    accounts: [],
  };
}

export function isNotificationCategoryEnabled(
  preferences: NotificationPreferences,
  category: NotificationCategory,
): boolean {
  return preferences[category];
}

export function withNotificationCategory(
  preferences: NotificationPreferences,
  category: NotificationCategory,
  enabled: boolean,
): NotificationPreferences {
  return { ...preferences, [category]: enabled };
}

export function parseNotificationPreferences(value: unknown): NotificationPreferences {
  const json = expectRecord(value, 'notification preferences');
  return {
    warAttacks: expectBoolean(json.warAttacksEnabled, 'warAttacksEnabled'),
    warState: expectBoolean(json.warStateEnabled, 'warStateEnabled'),
    warReminders: expectBoolean(json.warRemindersEnabled, 'warRemindersEnabled'),
    raidReminders: expectBoolean(json.raidRemindersEnabled, 'raidRemindersEnabled'),
    events: expectBoolean(json.eventsEnabled, 'eventsEnabled'),
    announcements: expectBoolean(json.announcementsEnabled, 'announcementsEnabled'),
    monthlySupport: expectBoolean(json.monthlySupportEnabled, 'monthlySupportEnabled'),
    legendDefenses: expectBoolean(json.legendDefensesEnabled, 'legendDefensesEnabled'),
    reminderTimings: parseReminderTimings(json.reminderTimings, 2820, false, 'reminder timings'),
    raidReminderTimings: parseReminderTimings(
      json.raidReminderTimings,
      4320,
      true,
      'Raid Weekend reminder timings',
    ),
    accounts: expectArray(json.accounts, 'notification accounts').map(parseNotificationAccount),
  };
}

/** Reads the prior on-device snapshot only; network payloads remain strict RC19 shapes. */
export function parseLocalNotificationPreferences(value: unknown): NotificationPreferences {
  const json = expectRecord(value, 'local notification preferences');
  const accounts = Array.isArray(json.accounts)
    ? json.accounts.flatMap((value) => {
        if (!isRecord(value)) return [];
        if (typeof value.tag === 'string' && typeof value.enabled === 'boolean') return [value];
        if (
          value.source === 'verified' &&
          typeof value.playerTag === 'string' &&
          typeof value.active === 'boolean'
        ) {
          return [{ tag: value.playerTag, enabled: value.active }];
        }
        return [];
      })
    : [];
  return parseNotificationPreferences({
    ...json,
    raidRemindersEnabled: json.raidRemindersEnabled ?? false,
    raidReminderTimings: json.raidReminderTimings ?? [],
    legendDefensesEnabled: json.legendDefensesEnabled ?? false,
    accounts,
  });
}

export function serializeNotificationPreferencesForPut(preferences: NotificationPreferences) {
  return {
    warAttacksEnabled: preferences.warAttacks,
    warStateEnabled: preferences.warState,
    warRemindersEnabled: preferences.warReminders,
    raidRemindersEnabled: preferences.raidReminders,
    eventsEnabled: preferences.events,
    announcementsEnabled: preferences.announcements,
    monthlySupportEnabled: preferences.monthlySupport,
    legendDefensesEnabled: preferences.legendDefenses,
    reminderTimings: [...preferences.reminderTimings],
    raidReminderTimings: [...preferences.raidReminderTimings],
  };
}

export function serializeNotificationPreferencesForLocalStorage(
  preferences: NotificationPreferences,
): Record<string, unknown> {
  return {
    ...serializeNotificationPreferencesForPut(preferences),
    accounts: preferences.accounts.map((account) => ({ ...account })),
  };
}

export function parseNotificationAccount(value: unknown): NotificationAccount {
  const json = expectRecord(value, 'notification account');
  return {
    tag: expectString(json.tag, 'notification account tag', true),
    enabled: expectBoolean(json.enabled, 'notification account enabled'),
  };
}

function parseReminderTimings(
  value: unknown,
  maximum: number,
  requiresQuarterHour: boolean,
  label: string,
): readonly number[] {
  const timings = expectArray(value, label).map((item) => {
    if (typeof item !== 'number' || !Number.isInteger(item)) {
      throw new TypeError(`Invalid ${label}`);
    }
    return item;
  });
  if (
    timings.length > 3 ||
    timings.some(
      (timing) => timing < 1 || timing > maximum || (requiresQuarterHour && timing % 15 !== 0),
    ) ||
    new Set(timings).size !== timings.length
  ) {
    throw new TypeError(`Invalid ${label}`);
  }
  return timings;
}

function expectRecord(value: unknown, label: string): Record<string, unknown> {
  if (!isRecord(value)) throw new TypeError(`Invalid ${label}`);
  return value;
}

function expectString(value: unknown, label: string, nonEmpty = false): string {
  if (typeof value !== 'string' || (nonEmpty && value.length === 0)) {
    throw new TypeError(`Invalid ${label}`);
  }
  return value;
}

function expectBoolean(value: unknown, label: string): boolean {
  if (typeof value !== 'boolean') throw new TypeError(`Invalid ${label}`);
  return value;
}

function expectArray(value: unknown, label: string): readonly unknown[] {
  if (!Array.isArray(value)) throw new TypeError(`Invalid ${label}`);
  return value;
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === 'object' && value !== null && !Array.isArray(value);
}
