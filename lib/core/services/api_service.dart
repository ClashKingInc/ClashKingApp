import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:clashkingapp/core/services/token_service.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'dart:io';
import 'package:clashkingapp/core/utils/debug_utils.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';
import 'package:clashkingapp/core/constants/global_keys.dart';

class ApiService {
  ApiService({http.Client? client}) : _client = client ?? http.Client();

  static const String apiUrlV1 = "https://api.clashk.ing";
  static const String apiUrlV2 = "https://go.api.clashk.ing/v2";
  static const String assetUrl = "https://assets.clashk.ing";
  static const String proxyUrl = "https://proxy.clashk.ing/v1";
  static const String cocAssetsUrl = "https://coc-assets.clashk.ing";
  static const String bunnyUrl = "https://cdn.clashk.ing";
  static const String discordUrl = "https://discord.gg/clashking";
  static const Duration _defaultTimeout = Duration(seconds: 15);

  // Config storage
  static String? _sentryDsn;
  static String? get sentryDsn => _sentryDsn;
  final http.Client _client;

  static AppLocalizations? _currentL10n() {
    final context = globalNavigatorKey.currentContext;
    if (context == null) {
      return null;
    }
    return AppLocalizations.of(context);
  }

  static String _localized(
    String fallback,
    String Function(AppLocalizations l10n) builder,
  ) {
    final l10n = _currentL10n();
    if (l10n == null) {
      return fallback;
    }
    return builder(l10n);
  }

  static String decodeResponseBody(http.Response response) {
    return utf8.decode(response.bodyBytes, allowMalformed: true);
  }

  Future<Map<String, dynamic>> get(
    String endpoint, {
    bool requiresAuth = true,
  }) async {
    final response = await getResponse(
      endpoint,
      requiresAuth: requiresAuth,
    );
    return _expectMapResponse(response, endpoint);
  }

  Future<Map<String, dynamic>> post(
    String endpoint,
    Map<String, String> body, {
    bool requiresAuth = false,
  }) async {
    final response = await postResponse(
      endpoint,
      body: body,
      requiresAuth: requiresAuth,
    );
    return _expectMapResponse(response, endpoint);
  }

  Future<http.Response> getResponse(
    String endpoint, {
    bool requiresAuth = false,
    String? url,
    Duration timeout = _defaultTimeout,
  }) async {
    return _requestResponse(
      'GET',
      endpoint: endpoint,
      url: url,
      requiresAuth: requiresAuth,
      timeout: timeout,
    );
  }

  Future<http.Response> postResponse(
    String endpoint, {
    Object? body,
    bool requiresAuth = false,
    String? url,
    Duration timeout = _defaultTimeout,
  }) async {
    return _requestResponse(
      'POST',
      endpoint: endpoint,
      url: url,
      body: body,
      requiresAuth: requiresAuth,
      timeout: timeout,
    );
  }

  Future<http.Response> putResponse(
    String endpoint, {
    Object? body,
    bool requiresAuth = false,
    String? url,
    Duration timeout = _defaultTimeout,
  }) async {
    return _requestResponse(
      'PUT',
      endpoint: endpoint,
      url: url,
      body: body,
      requiresAuth: requiresAuth,
      timeout: timeout,
    );
  }

  Future<http.Response> deleteResponse(
    String endpoint, {
    Object? body,
    bool requiresAuth = false,
    String? url,
    Duration timeout = _defaultTimeout,
  }) async {
    return _requestResponse(
      'DELETE',
      endpoint: endpoint,
      url: url,
      body: body,
      requiresAuth: requiresAuth,
      timeout: timeout,
    );
  }

  Map<String, dynamic> _expectMapResponse(
    http.Response response,
    String endpoint,
  ) {
    final data = _handleResponse(response, endpoint);
    if (data is Map<String, dynamic>) {
      return data;
    }

    throw FormatException(
      _localized(
        'Invalid response type for $endpoint.',
        (l10n) => l10n.apiErrorInvalidJsonResponse(endpoint),
      ),
    );
  }

  dynamic _handleResponse(http.Response response, String endpoint) {
    DebugUtils.debugInfo("Handling response status: ${response.statusCode}");
    final responseBody = decodeResponseBody(response);
    switch (response.statusCode) {
      case 200:
      case 201:
        try {
          return json.decode(responseBody);
        } catch (e) {
          throw FormatException(
            _localized(
              'Invalid JSON response for $endpoint.',
              (l10n) => l10n.apiErrorInvalidJsonResponse(endpoint),
            ),
          );
        }
      case 400:
        String? specificMessage = _extractApiErrorMessage(responseBody);
        throw BadRequestException(
          specificMessage ??
              _localized(
                'Bad request for $endpoint.',
                (l10n) => l10n.apiErrorBadRequest(endpoint, responseBody),
              ),
        );
      case 401:
        throw UnauthorizedException(
          _localized(
            'Unauthorized request for $endpoint.',
            (l10n) => l10n.apiErrorUnauthorized(endpoint),
          ),
        );
      case 403:
        throw ForbiddenException(
          _localized(
            'Forbidden request for $endpoint.',
            (l10n) => l10n.apiErrorForbidden(endpoint),
          ),
        );
      case 404:
        throw NotFoundException(
          _localized(
            'Resource not found for $endpoint.',
            (l10n) => l10n.apiErrorNotFound(endpoint),
          ),
        );
      case 409:
        throw EmailVerificationRequiredException(
          _localized(
            'Email verification is required.',
            (l10n) => l10n.authEmailVerificationExpired,
          ),
        );
      case 429:
        throw RateLimitException(
          _localized(
            'Rate limit exceeded for $endpoint.',
            (l10n) => l10n.apiErrorRateLimit(endpoint),
          ),
        );
      case 500:
      case 502:
      case 503:
      case 504:
        throw ServerException(
          _localized(
            'Server error ${response.statusCode} for $endpoint.',
            (l10n) => l10n.apiErrorServer(response.statusCode, endpoint),
          ),
        );
      default:
        throw ApiException(
          _localized(
            'API error ${response.statusCode}.',
            (l10n) => l10n.apiErrorGeneric(response.statusCode, responseBody),
          ),
        );
    }
  }

  Future<http.Response> _requestResponse(
    String method, {
    required String endpoint,
    String? url,
    Object? body,
    required bool requiresAuth,
    required Duration timeout,
  }) async {
    final operationTarget = url ?? endpoint;

    try {
      final resolvedUri = Uri.parse(url ?? '$apiUrlV2$endpoint');
      final headers = await _buildHeaders(requiresAuth: requiresAuth);
      final requestBody = _encodeBody(body);

      switch (method) {
        case 'GET':
          return await _client.get(resolvedUri, headers: headers).timeout(
                timeout,
              );
        case 'POST':
          return await _client
              .post(resolvedUri, headers: headers, body: requestBody)
              .timeout(timeout);
        case 'PUT':
          return await _client
              .put(resolvedUri, headers: headers, body: requestBody)
              .timeout(timeout);
        case 'DELETE':
          return await _client
              .delete(resolvedUri, headers: headers, body: requestBody)
              .timeout(timeout);
        default:
          throw UnsupportedError('Unsupported HTTP method: $method');
      }
    } catch (e, stackTrace) {
      _handleError(e, stackTrace, '$method $operationTarget');
      rethrow;
    }
  }

  Future<Map<String, String>> _buildHeaders({
    required bool requiresAuth,
  }) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };

    if (requiresAuth) {
      final token = await TokenService().getAccessToken();
      if (token == null) {
        throw UnauthorizedException(
          _localized(
            'User is not authenticated.',
            (l10n) => l10n.apiErrorUnauthorized('/auth'),
          ),
        );
      }
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }

  Object? _encodeBody(Object? body) {
    if (body == null || body is String) {
      return body;
    }
    return jsonEncode(body);
  }

  String? _extractApiErrorMessage(String responseBody) {
    try {
      final Map<String, dynamic> errorData = json.decode(responseBody);
      return errorData['detail'] as String?;
    } catch (e) {
      return null;
    }
  }

  void _handleError(dynamic error, StackTrace stackTrace, String operation) {
    String errorMessage = _localized(
      'API operation failed: $operation.',
      (l10n) => l10n.apiErrorOperationFailed(operation),
    );

    if (error is SocketException) {
      errorMessage = _localized(
        'Network error during $operation.',
        (l10n) => l10n.apiErrorNetworkOperation(operation),
      );
    } else if (error is TimeoutException) {
      errorMessage = _localized(
        'Timeout during $operation.',
        (l10n) => l10n.apiErrorTimeoutOperation(operation),
      );
    } else if (error is FormatException) {
      errorMessage = _localized(
        'Data format error during $operation.',
        (l10n) => l10n.apiErrorDataFormatOperation(operation),
      );
    }

    Sentry.captureException(error, stackTrace: stackTrace);
    Sentry.captureMessage(errorMessage);
  }

  static String cocAssetsProxyUrl(String url) {
    if (url.startsWith('https://api-assets.clashofclans.com')) {
      return url.replaceFirst(
        'https://api-assets.clashofclans.com',
        cocAssetsUrl,
      );
    }
    return url;
  }

  static Future<void> loadConfig() async {
    try {
      final response = await http.get(
        Uri.parse('$apiUrlV2/public-config'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final config = json.decode(response.body);
        _sentryDsn = config['sentry_dsn'];
      } else {
        DebugUtils.debugError('Failed to load config: ${response.statusCode}');
      }
    } catch (e) {
      DebugUtils.debugError('Error loading config: $e');
    }
  }

  static String getErrorMessage(dynamic error) {
    if (error is BadRequestException) {
      return error.message;
    } else if (error is UnauthorizedException) {
      return error.message;
    } else if (error is ForbiddenException) {
      return error.message;
    } else if (error is NotFoundException) {
      return error.message;
    } else if (error is EmailVerificationRequiredException) {
      return error.message;
    } else if (error is RateLimitException) {
      return error.message;
    } else if (error is ServerException) {
      return error.message;
    } else if (error is ApiException) {
      return error.message;
    } else if (error is SocketException) {
      return _localized(
        'Network connection error.',
        (l10n) => l10n.apiErrorNetworkConnection,
      );
    } else if (error is TimeoutException) {
      return _localized(
        'Request timeout.',
        (l10n) => l10n.apiErrorTimeout,
      );
    } else if (error is FormatException) {
      return _localized(
        'Invalid response format.',
        (l10n) => l10n.apiErrorInvalidFormat,
      );
    } else {
      return error.toString().replaceFirst('Exception: ', '');
    }
  }
}

class ApiException implements Exception {
  final String message;
  ApiException(this.message);
  @override
  String toString() => 'ApiException: $message';
}

class BadRequestException extends ApiException {
  BadRequestException(super.message);
}

class UnauthorizedException extends ApiException {
  UnauthorizedException(super.message);
}

class ForbiddenException extends ApiException {
  ForbiddenException(super.message);
}

class NotFoundException extends ApiException {
  NotFoundException(super.message);
}

class RateLimitException extends ApiException {
  RateLimitException(super.message);
}

class ServerException extends ApiException {
  ServerException(super.message);
}

class EmailVerificationRequiredException extends ApiException {
  EmailVerificationRequiredException(super.message);
}
