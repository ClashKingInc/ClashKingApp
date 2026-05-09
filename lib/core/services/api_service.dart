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
  static const String apiUrlV1 = "https://api.clashk.ing";
  static const String apiUrlV2 = "https://go.api.clashk.ing/v2";
  static const String assetUrl = "https://assets.clashk.ing";
  static const String proxyUrl = "https://proxy.clashk.ing/v1";
  static const String cocAssetsUrl = "https://coc-assets.clashk.ing";
  static const String bunnyUrl = "https://cdn.clashk.ing";
  static const String discordUrl = "https://discord.gg/clashking";

  // Config storage
  static String? _sentryDsn;
  static String? get sentryDsn => _sentryDsn;

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

  Future<Map<String, dynamic>> get(String endpoint) async {
    try {
      final token = await TokenService().getAccessToken();
      final response = await http.get(
        Uri.parse('$apiUrlV2$endpoint'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 15));
      return _handleResponse(response, endpoint);
    } catch (e, stackTrace) {
      _handleError(e, stackTrace, 'GET $endpoint');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> post(
      String endpoint, Map<String, String> body) async {
    try {
      final response = await http
          .post(
            Uri.parse('$apiUrlV2$endpoint'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 15));
      DebugUtils.debugInfo("Response status: ${response.statusCode}");
      return _handleResponse(response, endpoint);
    } catch (e, stackTrace) {
      _handleError(e, stackTrace, 'POST $endpoint');
      rethrow;
    }
  }

  Map<String, dynamic> _handleResponse(
      http.Response response, String endpoint) {
    DebugUtils.debugInfo("Handling response status: ${response.statusCode}");
    switch (response.statusCode) {
      case 200:
      case 201:
        try {
          return json.decode(response.body);
        } catch (e) {
          throw FormatException(
            _localized(
              'Invalid JSON response for $endpoint.',
              (l10n) => l10n.apiErrorInvalidJsonResponse(endpoint),
            ),
          );
        }
      case 400:
        String? specificMessage = _extractApiErrorMessage(response.body);
        throw BadRequestException(
          specificMessage ??
              _localized(
                'Bad request for $endpoint.',
                (l10n) => l10n.apiErrorBadRequest(endpoint, response.body),
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
            (l10n) => l10n.apiErrorGeneric(response.statusCode, response.body),
          ),
        );
    }
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
