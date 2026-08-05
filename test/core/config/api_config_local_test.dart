import 'package:clashkingapp/core/config/api_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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

  test('production API environment targets the public v2 API', () {
    expect(
      ApiConfig.defaultApiV2UrlFor(ApiEnvironment.production),
      'https://v2-api.clashk.ing/v2',
    );
  });
}
