import 'dart:convert';

import 'package:clashkingapp/core/models/notification_preferences.dart';
import 'package:clashkingapp/core/services/notification_preferences_service.dart';
import 'package:clashkingapp/core/services/push_notification_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/fake_services.dart';

void main() {
  const responseBody = {
    'deviceId': 'device-1',
    'environment': 'sandbox',
    'notificationsEnabled': true,
    'warAttacksEnabled': false,
    'warStateEnabled': true,
    'warRemindersEnabled': true,
    'raidRemindersEnabled': true,
    'eventsEnabled': true,
    'announcementsEnabled': false,
    'monthlySupportEnabled': false,
    'reminderTimings': [15, 30, 60],
    'raidReminderTimings': [60, 180],
    'accounts': [
      {'playerTag': '#VERIFIED', 'source': 'verified', 'active': true},
    ],
  };

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test(
    'GET parses the exact camelCase response and persists V2 state',
    () async {
      final api = FakeApiService();
      const endpoint =
          '/notifications/preferences?device_id=device-1&environment=sandbox';
      api.getStubs[endpoint] = http.Response(jsonEncode(responseBody), 200);
      final service = NotificationPreferencesService(
        apiService: api,
        deviceIdProvider: () async => 'device-1',
        environmentProvider: () => 'sandbox',
      );

      final settings = await service.load();

      expect(api.getCallCounts[endpoint], 1);
      expect(settings.notificationsEnabled, isTrue);
      expect(settings.reminderTimings, [15, 30, 60]);
      expect(settings.accounts.map((account) => account.source), [
        NotificationAccountSource.verified,
      ]);
      final preferences = await SharedPreferences.getInstance();
      expect(
        preferences.getBool(
          PushNotificationService.notificationsEnabledPrefsKey,
        ),
        isTrue,
      );
    },
  );

  test('PUT sends categories without rewriting account selection', () async {
    final api = FakeApiService();
    api.putStubs[NotificationPreferencesService.endpoint] = http.Response(
      jsonEncode(responseBody),
      200,
    );
    final service = NotificationPreferencesService(
      apiService: api,
      deviceIdProvider: () async => 'device-1',
      environmentProvider: () => 'sandbox',
    );
    final settings = NotificationPreferences.fromJson({
      ...responseBody,
      'notificationsEnabled': true,
    });

    await service.save(settings);

    expect(api.lastPutBodies[NotificationPreferencesService.endpoint], {
      'deviceId': 'device-1',
      'environment': 'sandbox',
      'notificationsEnabled': true,
      'warAttacksEnabled': false,
      'warStateEnabled': true,
      'warRemindersEnabled': true,
      'eventsEnabled': true,
      'announcementsEnabled': false,
      'monthlySupportEnabled': false,
      'reminderTimings': [15, 30, 60],
    });
  });

  test('successful PUT remains successful when local caching fails', () async {
    final api = FakeApiService();
    api.putStubs[NotificationPreferencesService.endpoint] = http.Response(
      jsonEncode(responseBody),
      200,
    );
    final service = NotificationPreferencesService(
      apiService: api,
      deviceIdProvider: () async => 'device-1',
      environmentProvider: () => 'sandbox',
      preferencesProvider: () async => throw StateError('cache unavailable'),
    );

    final saved = await service.save(
      NotificationPreferences.fromJson(responseBody),
    );

    expect(saved.notificationsEnabled, isTrue);
  });

  test(
    'successful GET remains authoritative when local caching fails',
    () async {
      final api = FakeApiService();
      const endpoint =
          '/notifications/preferences?device_id=device-1&environment=sandbox';
      api.getStubs[endpoint] = http.Response(jsonEncode(responseBody), 200);
      final service = NotificationPreferencesService(
        apiService: api,
        deviceIdProvider: () async => 'device-1',
        environmentProvider: () => 'sandbox',
        preferencesProvider: () async => throw StateError('cache unavailable'),
      );

      final loaded = await service.load();

      expect(loaded.notificationsEnabled, isTrue);
    },
  );

  test('device opt-in loads V2 preferences before saving', () async {
    final api = FakeApiService();
    const query =
        '/notifications/preferences?device_id=device-1&environment=sandbox';
    api.getStubs[query] = http.Response(jsonEncode(responseBody), 200);
    api.putStubs[NotificationPreferencesService.endpoint] = http.Response(
      jsonEncode(responseBody),
      200,
    );
    final service = NotificationPreferencesService(
      apiService: api,
      deviceIdProvider: () async => 'device-1',
      environmentProvider: () => 'sandbox',
    );

    final saved = await service.setDeviceEnabled(true);

    expect(api.getCallCounts[query], 1);
    expect(saved.notificationsEnabled, isTrue);
    expect(api.lastPutBodies[NotificationPreferencesService.endpoint], {
      'deviceId': 'device-1',
      'environment': 'sandbox',
      'notificationsEnabled': true,
      'warAttacksEnabled': false,
      'warStateEnabled': true,
      'warRemindersEnabled': true,
      'eventsEnabled': true,
      'announcementsEnabled': false,
      'monthlySupportEnabled': false,
      'reminderTimings': [15, 30, 60],
    });
    final preferences = await SharedPreferences.getInstance();
    expect(
      preferences.getBool(PushNotificationService.notificationsEnabledPrefsKey),
      isTrue,
    );
  });

  test('account toggle uses the dedicated per-player endpoint', () async {
    final api = FakeApiService();
    const endpoint = '/notifications/accounts/%23VERIFIED';
    api.putStubs[endpoint] = http.Response(
      jsonEncode({
        'playerTag': '#VERIFIED',
        'source': 'verified',
        'active': true,
      }),
      200,
    );
    final service = NotificationPreferencesService(apiService: api);

    final account = await service.setAccountEnabled('#VERIFIED', true);

    expect(account.active, isTrue);
    expect(account.source, NotificationAccountSource.verified);
    expect(api.lastPutBodies[endpoint], {'enabled': true});
  });

  test('local defaults disable notifications and every category', () async {
    final service = NotificationPreferencesService(
      apiService: FakeApiService(),
      deviceIdProvider: () async => 'device-1',
      environmentProvider: () => 'sandbox',
    );

    final settings = await service.loadLocal();

    expect(settings.notificationsEnabled, isFalse);
    for (final category in NotificationCategory.values) {
      expect(settings.enabled(category), isFalse);
    }
    expect(settings.reminderTimings, isEmpty);
    expect(settings.accounts, isEmpty);
  });

  test('response model enforces final reminder minute bounds', () {
    expect(
      NotificationPreferences.fromJson({
        ...responseBody,
        'reminderTimings': [2820],
      }).reminderTimings,
      [2820],
    );
    expect(
      () => NotificationPreferences.fromJson({
        ...responseBody,
        'reminderTimings': [2821],
      }),
      throwsFormatException,
    );
    expect(
      () => NotificationPreferences.fromJson({
        ...responseBody,
        'reminderTimings': [15, 30, 60, 120],
      }),
      throwsFormatException,
    );
  });

  test('successful V2 sync removes legacy local preference keys', () async {
    SharedPreferences.setMockInitialValues({
      'notif_settings_enabled_types': ['war_attacks'],
      'notif_settings_war_attack_modes': ['defenses'],
      'notif_settings_event_types': ['clan_games'],
      'notif_settings_selected_town_halls': ['18'],
      'notif_settings_selected_clan_tags': ['#CLAN'],
    });
    final api = FakeApiService();
    const endpoint =
        '/notifications/preferences?device_id=device-1&environment=sandbox';
    api.getStubs[endpoint] = http.Response(jsonEncode(responseBody), 200);
    final service = NotificationPreferencesService(
      apiService: api,
      deviceIdProvider: () async => 'device-1',
      environmentProvider: () => 'sandbox',
    );

    await service.load();

    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getStringList('notif_settings_enabled_types'), isNull);
    expect(
      preferences.getStringList('notif_settings_war_attack_modes'),
      isNull,
    );
    expect(preferences.getStringList('notif_settings_event_types'), isNull);
    expect(
      preferences.getStringList('notif_settings_selected_town_halls'),
      isNull,
    );
    expect(
      preferences.getStringList('notif_settings_selected_clan_tags'),
      isNull,
    );
  });
}
