import 'dart:convert';
import 'dart:io';
import 'package:clashkingapp/core/services/api_service.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:clashkingapp/core/utils/debug_utils.dart';

class TokenService {
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  Future<String?> getAccessToken() async {
    final tokens = await _readTokens();
    final accessToken = tokens.$1;
    final refreshToken = tokens.$2;
    final deviceId = await getDeviceId();

    if (accessToken == null || refreshToken == null) {
      return null;
    }

    if (isTokenExpired(accessToken)) {
      DebugUtils.debugInfo("🔄 Access Token has expired. Trying to refresh...");
      final newAccessToken = await refreshAccessToken(refreshToken, deviceId);

      if (newAccessToken != null) {
        return newAccessToken;
      } else {
        DebugUtils.debugError(
            " Failed to refresh token, user must re-authenticate");
        await clearTokens();
        return null;
      }
    }

    return accessToken;
  }

  Future<String?> refreshAccessToken(
      String refreshToken, String deviceId) async {
    try {
      final response = await http
          .post(
            Uri.parse('${ApiService.apiUrlV2}/auth/refresh'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(
                {"refresh_token": refreshToken, "device_id": deviceId}),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final newAccessToken = data['access_token'];

        if (newAccessToken == null || newAccessToken.isEmpty) {
          Sentry.captureMessage(
              "Token refresh API returned empty access token");
          return null;
        }

        await _secureStorage.write(
          key: _accessTokenKey,
          value: newAccessToken,
        );

        DebugUtils.debugSuccess("Token refreshed successfully");
        return newAccessToken;
      } else {
        Sentry.captureMessage(
          "Token refresh failed with status ${response.statusCode}",
        );
        return null;
      }
    } catch (e, stackTrace) {
      final errorMessage = "Exception during token refresh: $e";
      Sentry.captureException(e, stackTrace: stackTrace);
      Sentry.captureMessage(errorMessage);
      return null;
    }
  }

  Future<void> saveTokens(String accessToken, String refreshToken) async {
    await _secureStorage.write(key: _accessTokenKey, value: accessToken);
    await _secureStorage.write(key: _refreshTokenKey, value: refreshToken);

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accessTokenKey);
    await prefs.remove(_refreshTokenKey);
  }

  Future<void> clearTokens() async {
    await _secureStorage.delete(key: _accessTokenKey);
    await _secureStorage.delete(key: _refreshTokenKey);

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accessTokenKey);
    await prefs.remove(_refreshTokenKey);
  }

  bool isTokenExpired(String token) {
    try {
      if (token.isEmpty) {
        return true;
      }

      final parts = token.split('.');
      if (parts.length != 3) {
        DebugUtils.debugWarning(
            "⚠️ Invalid JWT token format: expected 3 parts, got ${parts.length}");
        return true;
      }

      final payload = json
          .decode(utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))));

      final exp = payload['exp'];
      if (exp == null) {
        DebugUtils.debugWarning("⚠️ JWT token missing expiration claim");
        return true;
      }

      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      const bufferTime = 30; // Add 30 second buffer before expiration

      return now >= (exp - bufferTime);
    } catch (e, stackTrace) {
      Sentry.captureException(e, stackTrace: stackTrace);
      Sentry.captureMessage("Error parsing JWT token expiration");
      return true;
    }
  }

  Future<String> getDeviceId() async {
    final deviceInfo = DeviceInfoPlugin();

    try {
      if (kIsWeb) {
        final webInfo = await deviceInfo.webBrowserInfo;
        return webInfo.userAgent ?? "unknown-web-device";
      } else if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        return androidInfo.id;
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
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
      Sentry.captureException(e, stackTrace: stackTrace);
      return "unknown-device";
    }
  }

  Future<String> getDeviceName() async {
    final deviceInfo = DeviceInfoPlugin();

    try {
      if (kIsWeb) {
        final webInfo = await deviceInfo.webBrowserInfo;
        return webInfo.browserName.name; // ex: "chrome", "safari"
      } else if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        return androidInfo.model;
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        return iosInfo.name;
      } else {
        return "unsupported-platform";
      }
    } catch (e) {
      DebugUtils.debugError(" Erreur getDeviceName: $e");
      return "unknown-device";
    }
  }

  Future<(String?, String?)> _readTokens() async {
    String? accessToken = await _secureStorage.read(key: _accessTokenKey);
    String? refreshToken = await _secureStorage.read(key: _refreshTokenKey);

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
