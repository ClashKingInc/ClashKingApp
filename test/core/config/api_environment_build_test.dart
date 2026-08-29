import 'package:clashkingapp/core/config/api_config.dart';
import 'package:clashkingapp/core/config/observability_config.dart';
import 'package:clashkingapp/core/services/push_notification_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const environmentName = String.fromEnvironment(
    'CK_API_ENV',
    defaultValue: 'production',
  );

  test('CK_API_ENV=$environmentName configures every environment consumer', () {
    final expected = switch (environmentName) {
      'local' => const _ExpectedEnvironment(
        environment: ApiEnvironment.local,
        apiBaseUrl: 'http://localhost:8000',
        apiV2Url: 'http://localhost:8000/v2',
        proxyUrl: 'http://localhost:8000/proxy/v1',
        observabilityEnvironment: 'development',
        pushEnvironment: 'sandbox',
      ),
      'development' => const _ExpectedEnvironment(
        environment: ApiEnvironment.development,
        apiBaseUrl: 'https://dev-api.clashk.ing',
        apiV2Url: 'https://dev-api.clashk.ing/v2',
        proxyUrl: 'https://dev-api.clashk.ing/proxy/v1',
        observabilityEnvironment: 'development',
        pushEnvironment: 'sandbox',
      ),
      'staging' => const _ExpectedEnvironment(
        environment: ApiEnvironment.staging,
        apiBaseUrl: 'https://dev-api.clashk.ing',
        apiV2Url: 'https://dev-api.clashk.ing/v2',
        proxyUrl: 'https://dev-api.clashk.ing/proxy/v1',
        observabilityEnvironment: 'staging',
        pushEnvironment: 'sandbox',
      ),
      'production' => const _ExpectedEnvironment(
        environment: ApiEnvironment.production,
        apiBaseUrl: 'https://v2.api.clashk.ing/v2',
        apiV2Url: 'https://v2.api.clashk.ing/v2',
        proxyUrl: 'https://v2.api.clashk.ing/proxy/v1',
        observabilityEnvironment: 'production',
        pushEnvironment: 'production',
      ),
      _ => throw UnsupportedError(
        'Run this test with a supported CK_API_ENV value.',
      ),
    };

    expect(ApiConfig.environment, expected.environment);
    expect(ApiConfig.apiBaseUrl, expected.apiBaseUrl);
    expect(ApiConfig.apiUrlV2, expected.apiV2Url);
    expect(ApiConfig.proxyUrl, expected.proxyUrl);
    expect(ObservabilityConfig.environment, expected.observabilityEnvironment);
    expect(PushNotificationService.environment, expected.pushEnvironment);
  });
}

class _ExpectedEnvironment {
  const _ExpectedEnvironment({
    required this.environment,
    required this.apiBaseUrl,
    required this.apiV2Url,
    required this.proxyUrl,
    required this.observabilityEnvironment,
    required this.pushEnvironment,
  });

  final ApiEnvironment environment;
  final String apiBaseUrl;
  final String apiV2Url;
  final String proxyUrl;
  final String observabilityEnvironment;
  final String pushEnvironment;
}
