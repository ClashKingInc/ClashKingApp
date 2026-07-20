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
}
