export type NotificationAccountSource = 'verified' | 'bookmarked';

export type NotificationCategory =
  | 'legendAttacks'
  | 'legendDefenses'
  | 'warAttacks'
  | 'warState'
  | 'warReminders'
  | 'raidReminders'
  | 'events'
  | 'announcements'
  | 'monthlySupport';

export interface NotificationAccount {
  readonly playerTag: string;
  readonly source: NotificationAccountSource;
  readonly active: boolean;
}

export interface NotificationPreferences {
  readonly deviceId: string;
  readonly environment: string;
  readonly notificationsEnabled: boolean;
  readonly legendAttacks: boolean;
  readonly legendDefenses: boolean;
  readonly warAttacks: boolean;
  readonly warState: boolean;
  readonly warReminders: boolean;
  readonly raidReminders: boolean;
  readonly events: boolean;
  readonly announcements: boolean;
  readonly monthlySupport: boolean;
  readonly reminderTimings: readonly number[];
  readonly raidReminderTimings: readonly number[];
  readonly accounts: readonly NotificationAccount[];
}

/**
 * Known persistence mismatch: the live transport schema exposes the two raid
 * reminder fields below, but clashking_api and clashking_schemas do not yet
 * persist them. Keep parsing strict; transport support is not proof that a
 * saved value will survive a later load on another device.
 */
export const NOTIFICATION_RAID_BACKEND_INCOMPATIBILITY =
  'clashking_api exposes but does not persist raidRemindersEnabled and raidReminderTimings';

export function createDefaultNotificationPreferences(
  deviceId = '',
  environment = 'production',
): NotificationPreferences {
  return {
    deviceId,
    environment,
    notificationsEnabled: false,
    legendAttacks: false,
    legendDefenses: false,
    warAttacks: false,
    warState: false,
    warReminders: false,
    raidReminders: false,
    events: false,
    announcements: false,
    monthlySupport: false,
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
  const reminderTimings = parseReminderTimings(
    json.reminderTimings,
    2820,
    false,
    'reminder timings',
  );
  const raidReminderTimings = parseReminderTimings(
    json.raidReminderTimings,
    4320,
    true,
    'Raid Weekend reminder timings',
  );
  const accounts = expectArray(json.accounts, 'notification accounts').map(
    parseNotificationAccount,
  );
  return {
    deviceId: expectString(json.deviceId, 'deviceId'),
    environment: expectString(json.environment, 'environment'),
    notificationsEnabled: expectBoolean(json.notificationsEnabled, 'notificationsEnabled'),
    legendAttacks: expectBoolean(json.legendAttacksEnabled, 'legendAttacksEnabled'),
    legendDefenses: expectBoolean(json.legendDefensesEnabled, 'legendDefensesEnabled'),
    warAttacks: expectBoolean(json.warAttacksEnabled, 'warAttacksEnabled'),
    warState: expectBoolean(json.warStateEnabled, 'warStateEnabled'),
    warReminders: expectBoolean(json.warRemindersEnabled, 'warRemindersEnabled'),
    raidReminders: expectBoolean(json.raidRemindersEnabled, 'raidRemindersEnabled'),
    events: expectBoolean(json.eventsEnabled, 'eventsEnabled'),
    announcements: expectBoolean(json.announcementsEnabled, 'announcementsEnabled'),
    monthlySupport: expectBoolean(json.monthlySupportEnabled, 'monthlySupportEnabled'),
    reminderTimings,
    raidReminderTimings,
    accounts,
  };
}

export function parseLocalNotificationPreferences(value: unknown): NotificationPreferences {
  const json = expectRecord(value, 'local notification preferences');
  const accounts = Array.isArray(json.accounts)
    ? json.accounts.filter(
        (account) => isRecord(account) && String(account.source ?? '') === 'verified',
      )
    : json.accounts;
  return parseNotificationPreferences({
    ...json,
    legendAttacksEnabled: json.legendAttacksEnabled ?? false,
    legendDefensesEnabled: json.legendDefensesEnabled ?? false,
    raidRemindersEnabled: json.raidRemindersEnabled ?? false,
    raidReminderTimings: json.raidReminderTimings ?? [],
    accounts,
  });
}

export function serializeNotificationPreferencesForPut(
  preferences: NotificationPreferences,
  deviceId: string,
  environment: string,
): Record<string, unknown> {
  return {
    deviceId,
    environment,
    notificationsEnabled: preferences.notificationsEnabled,
    legendAttacksEnabled: preferences.legendAttacks,
    legendDefensesEnabled: preferences.legendDefenses,
    warAttacksEnabled: preferences.warAttacks,
    warStateEnabled: preferences.warState,
    warRemindersEnabled: preferences.warReminders,
    raidRemindersEnabled: preferences.raidReminders,
    eventsEnabled: preferences.events,
    announcementsEnabled: preferences.announcements,
    monthlySupportEnabled: preferences.monthlySupport,
    reminderTimings: [...preferences.reminderTimings],
    raidReminderTimings: [...preferences.raidReminderTimings],
  };
}

export function serializeNotificationPreferencesForLocalStorage(
  preferences: NotificationPreferences,
): Record<string, unknown> {
  return {
    ...serializeNotificationPreferencesForPut(
      preferences,
      preferences.deviceId,
      preferences.environment,
    ),
    accounts: preferences.accounts.map((account) => ({ ...account })),
  };
}

export function parseNotificationAccount(value: unknown): NotificationAccount {
  const json = expectRecord(value, 'notification account');
  const source = expectString(json.source, 'notification account source');
  if (source !== 'verified' && source !== 'bookmarked') {
    throw new TypeError('Unsupported notification account source');
  }
  return {
    playerTag: expectString(json.playerTag, 'notification account', true),
    source,
    active: typeof json.active === 'boolean' ? json.active : true,
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
