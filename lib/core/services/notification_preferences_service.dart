import 'dart:convert';
import 'dart:io';

import 'package:clashkingapp/core/models/notification_preferences.dart';
import 'package:clashkingapp/core/services/api_service.dart';
import 'package:clashkingapp/core/services/push_notification_service.dart';
import 'package:clashkingapp/core/services/token_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationPreferencesService {
  NotificationPreferencesService({
    ApiService? apiService,
    Future<String> Function()? deviceIdProvider,
    String Function()? environmentProvider,
    Future<SharedPreferences> Function()? preferencesProvider,
  }) : _apiService = apiService ?? ApiService.shared,
       _deviceIdProvider =
           deviceIdProvider ?? (() => TokenService().getDeviceId()),
       _environmentProvider =
           environmentProvider ?? (() => PushNotificationService.environment),
       _preferencesProvider =
           preferencesProvider ?? SharedPreferences.getInstance;

  static const endpoint = '/notifications/preferences';
  static const localKey = 'notification_settings_v2';
  static const _legacyKeys = [
    'notif_settings_enabled_types',
    'notif_settings_war_attack_modes',
    'notif_settings_event_types',
    'notif_settings_reminder_timings',
    'notif_settings_war_state_types',
    'notif_settings_account_scope',
    'notif_settings_selected_accounts',
    'notif_settings_selected_town_halls',
    'notif_settings_selected_clan_tags',
    'notif_settings_limited_account_types',
    'notif_settings_accounts_by_type',
  ];

  final ApiService _apiService;
  final Future<String> Function() _deviceIdProvider;
  final String Function() _environmentProvider;
  final Future<SharedPreferences> Function() _preferencesProvider;

  Future<NotificationPreferences> load() async {
    final deviceId = await _deviceIdProvider();
    final environment = _environmentProvider();
    final query = Uri(
      path: endpoint,
      queryParameters: {'device_id': deviceId, 'environment': environment},
    ).toString();
    final response = await _apiService.getResponse(
      query,
      requiresAuth: true,
      url: PushNotificationService.urlFor(query),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw HttpException(
        'Failed to load notification preferences (${response.statusCode})',
        uri: response.request?.url,
      );
    }
    final settings = _decode(response);
    await _persist(settings);
    return settings;
  }

  Future<NotificationPreferences> save(NotificationPreferences settings) async {
    final deviceId = await _deviceIdProvider();
    final environment = _environmentProvider();
    final response = await _apiService.putResponse(
      endpoint,
      body: settings.toPutJson(deviceId: deviceId, environment: environment),
      requiresAuth: true,
      url: PushNotificationService.urlFor(endpoint),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw HttpException(
        'Failed to save notification preferences (${response.statusCode})',
        uri: response.request?.url,
      );
    }
    final saved = _decode(response);
    await _persist(saved);
    return saved;
  }

  Future<NotificationPreferences> setDeviceEnabled(bool enabled) async {
    final current = await loadLocal();
    return save(current.copyWith(deviceEnabled: enabled));
  }

  Future<NotificationPreferences> loadLocal() async {
    final preferences = await _preferencesProvider();
    final raw = preferences.getString(localKey);
    if (raw == null) {
      return NotificationPreferences(
        deviceId: await _deviceIdProvider(),
        environment: _environmentProvider(),
      );
    }
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Invalid local notification preferences');
    }
    return NotificationPreferences.fromJson(decoded);
  }

  NotificationPreferences _decode(dynamic response) {
    final decoded = jsonDecode(ApiService.decodeResponseBody(response));
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Invalid notification preferences response');
    }
    return NotificationPreferences.fromJson(decoded);
  }

  Future<void> _persist(NotificationPreferences settings) async {
    final preferences = await _preferencesProvider();
    await preferences.setString(localKey, jsonEncode(settings.toLocalJson()));
    await preferences.setBool(
      PushNotificationService.notificationsEnabledPrefsKey,
      settings.deviceEnabled,
    );
    for (final key in _legacyKeys) {
      await preferences.remove(key);
    }
  }
}
