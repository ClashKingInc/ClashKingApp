import 'package:clashkingapp/core/config/api_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('recognizes staging aliases as a distinct API environment', () {
    expect(ApiConfig.environmentForName('staging'), ApiEnvironment.staging);
    expect(ApiConfig.environmentForName('stage'), ApiEnvironment.staging);
    expect(ApiConfig.environmentForName('StAgInG'), ApiEnvironment.staging);
  });

  test('recognizes development aliases as a distinct API environment', () {
    expect(
      ApiConfig.environmentForName('development'),
      ApiEnvironment.development,
    );
  });

  test('local API environment targets the local Go API server', () {
    expect(
      ApiConfig.defaultApiBaseUrlFor(ApiEnvironment.local),
      'http://localhost:8000',
    );
    expect(
      ApiConfig.defaultApiV2UrlFor(ApiEnvironment.local),
      'http://localhost:8000/v2',
    );
    expect(
      ApiConfig.defaultProxyUrlFor(ApiEnvironment.local),
      'http://localhost:8000/proxy/v1',
    );
  });

  test('staging uses the dev API origin for v1, v2, and proxy requests', () {
    expect(
      ApiConfig.defaultApiBaseUrlFor(ApiEnvironment.staging),
      'https://dev-api.clashk.ing',
    );
    expect(
      ApiConfig.defaultApiV2UrlFor(ApiEnvironment.staging),
      'https://dev-api.clashk.ing/v2',
    );
    expect(
      ApiConfig.defaultProxyUrlFor(ApiEnvironment.staging),
      'https://dev-api.clashk.ing/proxy/v1',
    );
  });

  test(
    'development uses the dev API origin for v1, v2, and proxy requests',
    () {
      expect(
        ApiConfig.defaultApiBaseUrlFor(ApiEnvironment.development),
        'https://dev-api.clashk.ing',
      );
      expect(
        ApiConfig.defaultApiV2UrlFor(ApiEnvironment.development),
        'https://dev-api.clashk.ing/v2',
      );
      expect(
        ApiConfig.defaultProxyUrlFor(ApiEnvironment.development),
        'https://dev-api.clashk.ing/proxy/v1',
      );
    },
  );

  test('production API environment targets the public v2 API', () {
    expect(
      ApiConfig.defaultApiV2UrlFor(ApiEnvironment.production),
      'https://v2-api.clashk.ing/v2',
    );
    expect(
      ApiConfig.defaultProxyUrlFor(ApiEnvironment.production),
      'https://proxy.clashk.ing/v1',
    );
  });
}
