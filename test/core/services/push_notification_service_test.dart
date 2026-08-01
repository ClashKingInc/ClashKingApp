import 'package:clashkingapp/core/services/push_notification_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'device registration payload matches the final mobile device contract',
    () {
      final payload = buildNotificationDeviceRegistrationPayload(
        token: 'fcm-token',
        deviceId: 'device-1',
        provider: 'fcm',
        platform: 'ios',
        environment: 'sandbox',
        appVersion: '1.2.3',
        locale: 'en-US',
        authorizationStatus: 'authorized',
      );

      expect(payload, {
        'token': 'fcm-token',
        'device_id': 'device-1',
        'provider': 'fcm',
        'platform': 'ios',
        'environment': 'sandbox',
        'app_version': '1.2.3',
        'locale': 'en-US',
        'authorization_status': 'authorized',
      });
      expect(payload, isNot(contains('buildNumber')));
      expect(payload, isNot(contains('osVersion')));
      expect(payload, isNot(contains('deviceModel')));
      expect(payload, isNot(contains('build_number')));
      expect(payload, isNot(contains('os_version')));
      expect(payload, isNot(contains('device_model')));
      expect(payload, isNot(contains('timezone')));
    },
  );
}
