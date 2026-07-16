import 'package:clashkingapp/core/services/remote_feature_flag_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RemoteFeatureFlag', () {
    test('parses the minimum app version contract', () {
      final flag = RemoteFeatureFlag.fromJson({
        'key': 'upgrade_tracker',
        'enabled': true,
        'rollout_percentage': 100,
        'platforms': ['android'],
        'min_app_version': '0.4.0',
      });

      expect(flag.minAppVersion, '0.4.0');
    });
  });

  group('minimum version comparison', () {
    test('accepts equal and newer semantic versions', () {
      expect(
        RemoteFeatureFlagService.meetsMinimumVersion('0.3.5', '0.3.5'),
        isTrue,
      );
      expect(
        RemoteFeatureFlagService.meetsMinimumVersion('0.4.0', '0.3.5'),
        isTrue,
      );
      expect(
        RemoteFeatureFlagService.meetsMinimumVersion('1.0.0', '0.99.99'),
        isTrue,
      );
    });

    test('rejects older semantic versions', () {
      expect(
        RemoteFeatureFlagService.meetsMinimumVersion('0.3.5', '0.3.6'),
        isFalse,
      );
      expect(
        RemoteFeatureFlagService.meetsMinimumVersion('0.3', '0.3.1'),
        isFalse,
      );
    });

    test('ignores build metadata and tolerates shortened versions', () {
      expect(
        RemoteFeatureFlagService.meetsMinimumVersion('0.3.5+25', '0.3.5'),
        isTrue,
      );
      expect(
        RemoteFeatureFlagService.meetsMinimumVersion('1.2', '1.2.0'),
        isTrue,
      );
    });
  });
}
