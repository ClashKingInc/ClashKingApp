import 'dart:convert';
import 'dart:io';
import 'package:clashkingapp/core/config/api_config.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:clashkingapp/core/utils/debug_utils.dart';
import 'package:clashkingapp/core/services/error_reporter.dart';

class TokenService {
  TokenService({
    FlutterSecureStorage? secureStorage,
    http.Client? client,
    DeviceInfoPlugin? deviceInfo,
  }) : _secureStorage = secureStorage ?? const FlutterSecureStorage(),
       _providedClient = client,
       _deviceInfo = deviceInfo ?? DeviceInfoPlugin();

  static final TokenService shared = TokenService();

  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  final FlutterSecureStorage _secureStorage;
  final http.Client? _providedClient;
  final DeviceInfoPlugin _deviceInfo;
  http.Client? _defaultClient;

  http.Client get _client =>
      _providedClient ?? (_defaultClient ??= http.Client());

  String? _cachedAccessToken;
  String? _cachedRefreshToken;
  bool _tokensLoaded = false;
  Future<(String?, String?)>? _tokenLoad;
  Future<String?>? _refreshInFlight;
  Future<String>? _deviceIdLoad;
  Future<String>? _deviceNameLoad;

  Future<String?> getAccessToken() async {
    final tokens = await _loadTokensOnce();
    final accessToken = tokens.$1;
    final refreshToken = tokens.$2;

    if (accessToken == null || refreshToken == null) {
      return null;
    }

    if (isTokenExpired(accessToken)) {
      DebugUtils.debugInfo("🔄 Access Token has expired. Trying to refresh...");
      return _refreshExpiredToken(refreshToken);
    }

    return accessToken;
  }

  Future<String?> _refreshExpiredToken(String refreshToken) async {
    final existing = _refreshInFlight;
    if (existing != null) return existing;

    final refresh = () async {
      final deviceId = await getDeviceId();
      final newAccessToken = await refreshAccessToken(refreshToken, deviceId);
      if (newAccessToken != null) return newAccessToken;

      DebugUtils.debugError(
        "Failed to refresh token, user must re-authenticate",
      );
      await clearTokens();
      return null;
    }();

    _refreshInFlight = refresh;
    try {
      return await refresh;
    } finally {
      if (identical(_refreshInFlight, refresh)) {
        _refreshInFlight = null;
      }
    }
  }

  Future<String?> refreshAccessToken(
    String refreshToken,
    String deviceId,
  ) async {
    try {
      final response = await _client
          .post(
            Uri.parse('${ApiConfig.apiUrlV2}/auth/refresh'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              "refresh_token": refreshToken,
              "device_id": deviceId,
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final newAccessToken = data['access_token'];

        if (newAccessToken == null || newAccessToken.isEmpty) {
          Sentry.captureMessage(
            "Token refresh API returned empty access token",
          );
          return null;
        }

        await _secureStorage.write(key: _accessTokenKey, value: newAccessToken);
        _cachedAccessToken = newAccessToken;
        _tokensLoaded = true;

        DebugUtils.debugSuccess("Token refreshed successfully");
        return newAccessToken;
      } else {
        Sentry.captureMessage(
          "Token refresh failed with status ${response.statusCode}",
        );
        return null;
      }
    } catch (e, stackTrace) {
      ErrorReporter.captureException(
        e,
        stackTrace: stackTrace,
        operation: 'token.refresh',
      );
      return null;
    }
  }

  Future<void> saveTokens(String accessToken, String refreshToken) async {
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      _secureStorage.write(key: _accessTokenKey, value: accessToken),
      _secureStorage.write(key: _refreshTokenKey, value: refreshToken),
      prefs.remove(_accessTokenKey),
      prefs.remove(_refreshTokenKey),
    ]);
    _cachedAccessToken = accessToken;
    _cachedRefreshToken = refreshToken;
    _tokensLoaded = true;
  }

  Future<void> clearTokens() async {
    _cachedAccessToken = null;
    _cachedRefreshToken = null;
    _tokensLoaded = true;
    _tokenLoad = null;
    _refreshInFlight = null;
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      _secureStorage.delete(key: _accessTokenKey),
      _secureStorage.delete(key: _refreshTokenKey),
      prefs.remove(_accessTokenKey),
      prefs.remove(_refreshTokenKey),
    ]);
  }

  bool isTokenExpired(String token) {
    try {
      if (token.isEmpty) {
        return true;
      }

      final parts = token.split('.');
      if (parts.length != 3) {
        DebugUtils.debugWarning(
          "⚠️ Invalid JWT token format: expected 3 parts, got ${parts.length}",
        );
        return true;
      }

      final payload = json.decode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
      );

      final exp = payload['exp'];
      if (exp == null) {
        DebugUtils.debugWarning("⚠️ JWT token missing expiration claim");
        return true;
      }

      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      const bufferTime = 30; // Add 30 second buffer before expiration

      return now >= (exp - bufferTime);
    } catch (e, stackTrace) {
      ErrorReporter.captureException(
        e,
        stackTrace: stackTrace,
        operation: 'token.parse_expiration',
      );
      return true;
    }
  }

  Future<String> getDeviceId() async {
    return _deviceIdLoad ??= _loadDeviceId();
  }

  Future<String> _loadDeviceId() async {
    try {
      if (kIsWeb) {
        final webInfo = await _deviceInfo.webBrowserInfo;
        return webInfo.userAgent ?? "unknown-web-device";
      } else if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        return androidInfo.id;
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        final vendorId = iosInfo.identifierForVendor;
        if (vendorId != null) return vendorId;
        // identifierForVendor is null when the device hasn't been unlocked
        // after reboot or under MDM restrictions — fall back to a stable UUID
        // persisted in the keychain so the same device always gets the same ID.
        const fallbackKey = 'device_id_fallback';
        final stored = await _secureStorage.read(key: fallbackKey);
        if (stored != null) return stored;
        final generated = const Uuid().v4();
        await _secureStorage.write(key: fallbackKey, value: generated);
        return generated;
      } else {
        return "unsupported-platform";
      }
    } catch (e, stackTrace) {
      ErrorReporter.captureException(
        e,
        stackTrace: stackTrace,
        operation: 'device.identity',
      );
      return "unknown-device";
    }
  }

  Future<String> getDeviceName() async {
    return _deviceNameLoad ??= _loadDeviceName();
  }

  Future<String> _loadDeviceName() async {
    try {
      if (kIsWeb) {
        final webInfo = await _deviceInfo.webBrowserInfo;
        return webInfo.browserName.name; // ex: "chrome", "safari"
      } else if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        return androidInfo.model;
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        return iosInfo.name;
      } else {
        return "unsupported-platform";
      }
    } catch (e) {
      DebugUtils.debugError(" Erreur getDeviceName: $e");
      return "unknown-device";
    }
  }

  Future<(String?, String?)> _loadTokensOnce() async {
    if (_tokensLoaded) return (_cachedAccessToken, _cachedRefreshToken);

    final existing = _tokenLoad;
    if (existing != null) return existing;

    final load = _readTokens();
    _tokenLoad = load;
    try {
      final tokens = await load;
      _cachedAccessToken = tokens.$1;
      _cachedRefreshToken = tokens.$2;
      _tokensLoaded = true;
      return tokens;
    } finally {
      if (identical(_tokenLoad, load)) _tokenLoad = null;
    }
  }

  Future<(String?, String?)> _readTokens() async {
    final storedTokens = await Future.wait([
      _secureStorage.read(key: _accessTokenKey),
      _secureStorage.read(key: _refreshTokenKey),
    ]);
    String? accessToken = storedTokens[0];
    String? refreshToken = storedTokens[1];

    if (accessToken != null && refreshToken != null) {
      return (accessToken, refreshToken);
    }

    final prefs = await SharedPreferences.getInstance();
    final legacyAccessToken = prefs.getString(_accessTokenKey);
    final legacyRefreshToken = prefs.getString(_refreshTokenKey);

    if (legacyAccessToken != null) {
      await _secureStorage.write(
        key: _accessTokenKey,
        value: legacyAccessToken,
      );
      await prefs.remove(_accessTokenKey);
      accessToken = legacyAccessToken;
    }

    if (legacyRefreshToken != null) {
      await _secureStorage.write(
        key: _refreshTokenKey,
        value: legacyRefreshToken,
      );
      await prefs.remove(_refreshTokenKey);
      refreshToken = legacyRefreshToken;
    }

    return (accessToken, refreshToken);
  }
}
