import assert from 'node:assert/strict';
import test from 'node:test';

import { apiEnvironmentForName, resolveApiConfiguration } from '../config/api-config.ts';
import { canonicalTag, normalizeTag } from '../domain/tags.ts';
import {
  APP_FEATURE_FLAGS,
  isFeatureFlagEnabled,
  meetsMinimumVersion,
  stableFeatureBucket,
} from '../feature-flags/feature-flags.ts';
import {
  NOTIFICATION_RAID_BACKEND_INCOMPATIBILITY,
  parseNotificationPreferences,
} from '../dto/notification-preferences.ts';
import { serializeStoredAuthSession, tryParseStoredAuthSession } from '../dto/auth-session.ts';

test('API environment aliases and overrides match Flutter', () => {
  assert.equal(apiEnvironmentForName('stage'), 'staging');
  assert.equal(apiEnvironmentForName('anything'), 'production');
  assert.deepEqual(
    resolveApiConfiguration({
      CK_API_ENV: 'local',
      CK_API_BASE_URL: 'http://127.0.0.1:9000///',
    }),
    {
      environment: 'local',
      apiBaseUrl: 'http://127.0.0.1:9000',
      apiV2Url: 'http://127.0.0.1:9000/v2',
      proxyUrl: 'http://127.0.0.1:9000/proxy/v1',
    },
  );
  assert.equal(
    resolveApiConfiguration({
      CK_API_ENV: 'prod',
      CK_API_BASE_URL: 'https://ignored-for-v2.example',
    }).apiV2Url,
    'https://api.clashk.ing/v2',
  );
});

test('tag normalization matches cache and API forms', () => {
  assert.equal(normalizeTag(' ##abc123 '), 'ABC123');
  assert.equal(canonicalTag(' #abc123 '), '#ABC123');
  assert.equal(canonicalTag(''), '');
});

test('feature evaluation preserves version, time, platform, and rollout rules', () => {
  assert.equal(meetsMinimumVersion('1.2.0+99', '1.2'), true);
  assert.equal(meetsMinimumVersion('1.2-beta', '1.2.1'), false);
  assert.equal(stableFeatureBucket('notifications', 42), 41);
  const base = {
    key: APP_FEATURE_FLAGS.notifications,
    enabled: true,
    rolloutPercentage: 100,
    platforms: ['ios'],
    startsAt: new Date('2026-01-01T00:00:00Z'),
    endsAt: new Date('2026-02-01T00:00:00Z'),
  };
  assert.equal(
    isFeatureFlagEnabled(base, base.key, {
      platform: 'ios',
      appVersion: '1.0.0',
      installationSeed: 42,
      now: new Date('2026-01-31T23:59:59Z'),
    }),
    true,
  );
  assert.equal(
    isFeatureFlagEnabled(base, base.key, {
      platform: 'ios',
      appVersion: '1.0.0',
      installationSeed: 42,
      now: new Date('2026-02-01T00:00:00Z'),
    }),
    false,
  );
});

test('notification DTO deliberately exposes the unresolved raid backend mismatch', () => {
  assert.match(NOTIFICATION_RAID_BACKEND_INCOMPATIBILITY, /clashking_api/);
  const currentBackendShape = {
    deviceId: 'device',
    environment: 'production',
    notificationsEnabled: true,
    legendAttacksEnabled: true,
    legendDefensesEnabled: true,
    warAttacksEnabled: true,
    warStateEnabled: true,
    warRemindersEnabled: true,
    eventsEnabled: true,
    announcementsEnabled: true,
    monthlySupportEnabled: true,
    reminderTimings: [60],
    accounts: [],
  };
  assert.throws(
    () => parseNotificationPreferences(currentBackendShape),
    /Raid Weekend reminder timings|raidReminderTimings/,
  );
  assert.doesNotThrow(() =>
    parseNotificationPreferences({
      ...currentBackendShape,
      raidRemindersEnabled: false,
      raidReminderTimings: [15, 60],
    }),
  );
});

test('shared auth session retains the Flutter wire keys', () => {
  const encoded = serializeStoredAuthSession({
    accessToken: 'access',
    refreshToken: 'refresh',
    deviceId: 'device',
  });
  assert.equal(encoded, '{"access_token":"access","refresh_token":"refresh","device_id":"device"}');
  assert.deepEqual(tryParseStoredAuthSession(encoded), {
    accessToken: 'access',
    refreshToken: 'refresh',
    deviceId: 'device',
  });
  assert.equal(tryParseStoredAuthSession('{broken').accessToken, null);
});
