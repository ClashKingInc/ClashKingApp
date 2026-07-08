enum ApiEnvironment { production, local }

class ApiConfig {
  ApiConfig._();

  static const String _environmentName = String.fromEnvironment(
    'CK_API_ENV',
    defaultValue: 'prod',
  );
  static const String _apiBaseOverride = String.fromEnvironment(
    'CK_API_BASE_URL',
  );
  static const String _apiV2BaseOverride = String.fromEnvironment(
    'CK_API_V2_BASE_URL',
  );
  static const String _proxyBaseOverride = String.fromEnvironment(
    'CK_PROXY_BASE_URL',
  );

  static ApiEnvironment get environment {
    switch (_environmentName.toLowerCase()) {
      case 'local':
      case 'dev':
      case 'development':
        return ApiEnvironment.local;
      case 'prod':
      case 'production':
      default:
        return ApiEnvironment.production;
    }
  }

  static String get apiBaseUrl {
    if (_apiBaseOverride.isNotEmpty) {
      return _withoutTrailingSlash(_apiBaseOverride);
    }

    return switch (environment) {
      ApiEnvironment.local => 'https://local-api.clashk.ing',
      ApiEnvironment.production => 'https://api.clashk.ing',
    };
  }

  static String get apiUrlV1 => apiBaseUrl;

  static String get apiUrlV2 {
    if (_apiV2BaseOverride.isNotEmpty) {
      return _withoutTrailingSlash(_apiV2BaseOverride);
    }

    return switch (environment) {
      ApiEnvironment.local => '$apiBaseUrl/v2',
      ApiEnvironment.production => 'https://local-api.clashk.ing/v2',
    };
  }

  static String get proxyUrl {
    if (_proxyBaseOverride.isNotEmpty) {
      return _withoutTrailingSlash(_proxyBaseOverride);
    }

    return switch (environment) {
      ApiEnvironment.local => 'https://local-api.clashk.ing/proxy/v1',
      ApiEnvironment.production => 'https://proxy.clashk.ing/v1',
    };
  }

  static String _withoutTrailingSlash(String value) {
    var normalized = value;
    while (normalized.endsWith('/')) {
      normalized = normalized.substring(0, normalized.length - 1);
    }
    return normalized;
  }
}
