import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:clashkingapp/core/services/token_service.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'dart:io';

class ApiService {
  static const String apiUrlV1 = "https://dev.api.clashk.ing";
  static const String apiUrlV2 = "https://dev.api.clashk.ing/v2";
  static const String assetUrl = "https://assets.clashk.ing";
  static const String proxyUrl = "https://proxy.clashk.ing/v1";
  static const String cocAssetsUrl = "https://coc-assets.clashk.ing";
  static const String bunnyUrl = "https://cdn.clashk.ing";
  static const String discordUrl = "https://discord.gg/clashking";

  // Config storage
  static String? _sentryDsn;
  static String? get sentryDsn => _sentryDsn;

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
      final response = await http.post(
        Uri.parse('$apiUrlV2$endpoint'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 15));
      return _handleResponse(response, endpoint);
    } catch (e, stackTrace) {
      _handleError(e, stackTrace, 'POST $endpoint');
      rethrow;
    }
  }

  Map<String, dynamic> _handleResponse(http.Response response, String endpoint) {
    switch (response.statusCode) {
      case 200:
      case 201:
        try {
          return json.decode(response.body);
        } catch (e) {
          throw FormatException('Invalid JSON response from $endpoint');
        }
      case 400:
        throw BadRequestException('Bad request to $endpoint: ${response.body}');
      case 401:
        throw UnauthorizedException('Unauthorized request to $endpoint');
      case 403:
        throw ForbiddenException('Forbidden request to $endpoint');
      case 404:
        throw NotFoundException('Resource not found: $endpoint');
      case 429:
        throw RateLimitException('Rate limit exceeded for $endpoint');
      case 500:
      case 502:
      case 503:
      case 504:
        throw ServerException('Server error ${response.statusCode} for $endpoint');
      default:
        throw ApiException('HTTP ${response.statusCode}: ${response.body}');
    }
  }

  void _handleError(dynamic error, StackTrace stackTrace, String operation) {
    String errorMessage = 'API operation failed: $operation';
    
    if (error is SocketException) {
      errorMessage = 'Network error during $operation: No internet connection';
    } else if (error is TimeoutException) {
      errorMessage = 'Timeout error during $operation';
    } else if (error is FormatException) {
      errorMessage = 'Data format error during $operation';
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
        Uri.parse('$apiUrlV2/app/public-config'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final config = json.decode(response.body);
        _sentryDsn = config['sentry_dsn'];
      } else {
        print('Failed to load config: ${response.statusCode}');
      }
    } catch (e) {
      print('Error loading config: $e');
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
