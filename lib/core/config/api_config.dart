enum ApiEnvironment { production, staging, development, local }

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

  static ApiEnvironment get environment => environmentForName(_environmentName);

  static ApiEnvironment environmentForName(String name) {
    switch (name.toLowerCase()) {
      case 'local':
        return ApiEnvironment.local;
      case 'development':
        return ApiEnvironment.development;
      case 'stage':
      case 'staging':
        return ApiEnvironment.staging;
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
    return defaultApiBaseUrlFor(environment);
  }

  static String get apiUrlV1 => apiBaseUrl;

  static String get apiUrlV2 {
    if (_apiV2BaseOverride.isNotEmpty) {
      return _withoutTrailingSlash(_apiV2BaseOverride);
    }

    return _resolvedApiV2UrlFor(environment);
  }

  static String get proxyUrl {
    if (_proxyBaseOverride.isNotEmpty) {
      return _withoutTrailingSlash(_proxyBaseOverride);
    }

    return switch (environment) {
      ApiEnvironment.local => '$apiBaseUrl/proxy/v1',
      ApiEnvironment.development => '$apiBaseUrl/proxy/v1',
      ApiEnvironment.staging => '$apiBaseUrl/proxy/v1',
      ApiEnvironment.production => 'https://proxy.clashk.ing/v1',
    };
  }

  static String defaultApiBaseUrlFor(ApiEnvironment target) => switch (target) {
    ApiEnvironment.local => 'http://localhost:8000',
    ApiEnvironment.development => 'https://dev-api.clashk.ing',
    ApiEnvironment.staging => 'https://dev-api.clashk.ing',
    ApiEnvironment.production => 'https://v2.api.clashk.ing/v2',
  };

  static String defaultApiV2UrlFor(ApiEnvironment target) =>
      _defaultApiV2UrlFor(target);

  static String _resolvedApiV2UrlFor(ApiEnvironment target) {
    // Keep CK_API_BASE_URL useful for local development while production has
    // one canonical v2 host shared by the runtime getter and default helper.
    if (target == ApiEnvironment.local && _apiBaseOverride.isNotEmpty) {
      return '$apiBaseUrl/v2';
    }
    return _defaultApiV2UrlFor(target);
  }

  static String _defaultApiV2UrlFor(ApiEnvironment target) => switch (target) {
    ApiEnvironment.local => '${defaultApiBaseUrlFor(target)}/v2',
    ApiEnvironment.development => '${defaultApiBaseUrlFor(target)}/v2',
    ApiEnvironment.staging => '${defaultApiBaseUrlFor(target)}/v2',
    ApiEnvironment.production => 'https://v2.api.clashk.ing/v2',
  };

  static String defaultProxyUrlFor(ApiEnvironment target) => switch (target) {
    ApiEnvironment.local => '${defaultApiBaseUrlFor(target)}/proxy/v1',
    ApiEnvironment.development => '${defaultApiBaseUrlFor(target)}/proxy/v1',
    ApiEnvironment.staging => '${defaultApiBaseUrlFor(target)}/proxy/v1',
    ApiEnvironment.production => 'https://proxy.clashk.ing/v1',
  };

  static String _withoutTrailingSlash(String value) {
    var normalized = value;
    while (normalized.endsWith('/')) {
      normalized = normalized.substring(0, normalized.length - 1);
    }
    return normalized;
  }
}
