import 'package:clashkingapp/core/config/api_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('recognizes staging aliases as a distinct API environment', () {
    expect(ApiConfig.environmentForName('staging'), ApiEnvironment.staging);
    expect(ApiConfig.environmentForName('stage'), ApiEnvironment.staging);
    expect(ApiConfig.environmentForName('StAgInG'), ApiEnvironment.staging);
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

  test('production API environment targets the dev v2 API', () {
    expect(
      ApiConfig.defaultApiV2UrlFor(ApiEnvironment.production),
      'https://dev-api.clashk.ing/v2',
    );
    expect(
      ApiConfig.defaultProxyUrlFor(ApiEnvironment.production),
      'https://proxy.clashk.ing/v1',
    );
  });
}
