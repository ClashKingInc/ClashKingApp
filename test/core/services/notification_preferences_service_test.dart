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
    'deviceEnabled': false,
    'notificationsEnabled': true,
    'autoAddVerifiedAccounts': true,
    'leagueBattlesEnabled': true,
    'warAttacksEnabled': false,
    'warStateEnabled': true,
    'warRemindersEnabled': true,
    'eventsEnabled': true,
    'announcementsEnabled': false,
    'upgradeFinishesEnabled': true,
    'monthlySupportEnabled': false,
    'reminderTimings': [15, 30, 60],
    'accounts': [
      {'playerTag': '#VERIFIED', 'source': 'verified', 'active': true},
      {'playerTag': '#BOOKMARK', 'source': 'bookmarked', 'active': false},
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
      expect(settings.deviceEnabled, isFalse);
      expect(settings.leagueBattles, isTrue);
      expect(settings.reminderTimings, [15, 30, 60]);
      expect(settings.accounts.map((account) => account.source), [
        NotificationAccountSource.verified,
        NotificationAccountSource.bookmarked,
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

  test('PUT sends only the final fields and account tags', () async {
    final api = FakeApiService();
    api.putStubs[NotificationPreferencesService.endpoint] = http.Response(
      jsonEncode({...responseBody, 'deviceEnabled': true}),
      200,
    );
    final service = NotificationPreferencesService(
      apiService: api,
      deviceIdProvider: () async => 'device-1',
      environmentProvider: () => 'sandbox',
    );
    final settings = NotificationPreferences.fromJson({
      ...responseBody,
      'deviceEnabled': true,
      'notificationsEnabled': true,
      'autoAddVerifiedAccounts': true,
    });

    await service.save(settings);

    expect(api.lastPutBodies[NotificationPreferencesService.endpoint], {
      'deviceId': 'device-1',
      'environment': 'sandbox',
      'deviceEnabled': true,
      'notificationsEnabled': true,
      'autoAddVerifiedAccounts': true,
      'leagueBattlesEnabled': true,
      'warAttacksEnabled': false,
      'warStateEnabled': true,
      'warRemindersEnabled': true,
      'eventsEnabled': true,
      'announcementsEnabled': false,
      'upgradeFinishesEnabled': true,
      'monthlySupportEnabled': false,
      'reminderTimings': [15, 30, 60],
      'accountTags': ['#VERIFIED', '#BOOKMARK'],
    });
  });

  test('device opt-in loads V2 preferences before saving', () async {
    final api = FakeApiService();
    const query =
        '/notifications/preferences?device_id=device-1&environment=sandbox';
    api.getStubs[query] = http.Response(jsonEncode(responseBody), 200);
    api.putStubs[NotificationPreferencesService.endpoint] = http.Response(
      jsonEncode({...responseBody, 'deviceEnabled': true}),
      200,
    );
    final service = NotificationPreferencesService(
      apiService: api,
      deviceIdProvider: () async => 'device-1',
      environmentProvider: () => 'sandbox',
    );

    final saved = await service.setDeviceEnabled(true);

    expect(api.getCallCounts[query], 1);
    expect(saved.deviceEnabled, isTrue);
    expect(api.lastPutBodies[NotificationPreferencesService.endpoint], {
      'deviceId': 'device-1',
      'environment': 'sandbox',
      'deviceEnabled': true,
      'notificationsEnabled': true,
      'autoAddVerifiedAccounts': true,
      'leagueBattlesEnabled': true,
      'warAttacksEnabled': false,
      'warStateEnabled': true,
      'warRemindersEnabled': true,
      'eventsEnabled': true,
      'announcementsEnabled': false,
      'upgradeFinishesEnabled': true,
      'monthlySupportEnabled': false,
      'reminderTimings': [15, 30, 60],
      'accountTags': ['#VERIFIED', '#BOOKMARK'],
    });
    final preferences = await SharedPreferences.getInstance();
    expect(
      preferences.getBool(PushNotificationService.notificationsEnabledPrefsKey),
      isTrue,
    );
  });

  test('local defaults disable device and every category', () async {
    final service = NotificationPreferencesService(
      apiService: FakeApiService(),
      deviceIdProvider: () async => 'device-1',
      environmentProvider: () => 'sandbox',
    );

    final settings = await service.loadLocal();

    expect(settings.deviceEnabled, isFalse);
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
