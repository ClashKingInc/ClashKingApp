import 'dart:convert';
import 'dart:io';
import 'package:clashkingapp/core/config/api_config.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:clashkingapp/core/utils/debug_utils.dart';
import 'package:clashkingapp/core/services/error_reporter.dart';
import 'package:clashkingapp/core/services/platform_http_client.dart';

class TokenService {
  TokenService({
    FlutterSecureStorage? secureStorage,
    FlutterSecureStorage? legacySecureStorage,
    http.Client? client,
    DeviceInfoPlugin? deviceInfo,
  }) : _secureStorage = secureStorage ?? _defaultSharedStorage,
       _legacySecureStorage =
           legacySecureStorage ??
           (secureStorage ?? const FlutterSecureStorage()),
       _providedClient = client,
       _deviceInfo = deviceInfo ?? DeviceInfoPlugin();

  static final TokenService shared = TokenService();

  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _sessionKey = 'shared_auth_session_v1';
  static const String _deviceIdFallbackKey = 'device_id_fallback';
  static const String _iosKeychainAccessGroup =
      'MZYXD43RX5.group.com.clashking.apps';
  static const FlutterSecureStorage _defaultSharedStorage =
      FlutterSecureStorage(
        iOptions: IOSOptions(
          groupId: _iosKeychainAccessGroup,
          accessibility: KeychainAccessibility.first_unlock_this_device,
        ),
      );
  static const MethodChannel _sharedAuthLockChannel = MethodChannel(
    'clashking/shared_auth_lock',
  );
  final FlutterSecureStorage _secureStorage;
  final FlutterSecureStorage _legacySecureStorage;
  final http.Client? _providedClient;
  final DeviceInfoPlugin _deviceInfo;
  http.Client? _defaultClient;

  http.Client get _client =>
      _providedClient ?? (_defaultClient ??= createPlatformHttpClient());

  String? _cachedAccessToken;
  String? _cachedRefreshToken;
  bool _tokensLoaded = false;
  Future<(String?, String?)>? _tokenLoad;
  Future<String?>? _refreshInFlight;
  Future<String>? _deviceIdLoad;
  Future<String>? _deviceNameLoad;

  Future<String?> getAccessToken() async {
    if (kIsWeb) {
      final cached = _cachedAccessToken;
      if (cached != null && !isTokenExpired(cached)) return cached;
      return _refreshWebAccessToken();
    }
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
    if (kIsWeb) return _refreshWebAccessToken();

    if (Platform.isIOS) {
      return _withIOSRefreshLock(
        () => _refreshAccessTokenWhileLocked(refreshToken, deviceId),
      );
    }

    return _refreshAccessTokenWhileLocked(refreshToken, deviceId);
  }

  Future<String?> _refreshAccessTokenWhileLocked(
    String refreshToken,
    String deviceId,
  ) async {
    try {
      // The widget may have rotated the refresh token while this process still
      // had the previous session cached. Always re-read after taking the
      // cross-process lock and avoid a second refresh when possible.
      final latest = await _readStoredSession();
      if (latest.accessToken != null &&
          latest.refreshToken != null &&
          !isTokenExpired(latest.accessToken!)) {
        _cacheSession(latest);
        return latest.accessToken;
      }

      // A logout may have cleared the stored session while this refresh was
      // waiting for the iOS cross-process lock. Never resurrect that session
      // with the token captured before the lock was acquired.
      final currentRefreshToken = latest.refreshToken;
      if (currentRefreshToken == null) return null;
      if (currentRefreshToken != refreshToken) {
        DebugUtils.debugInfo(
          'Using the refresh token rotated by another process.',
        );
      }
      final currentDeviceId = latest.deviceId ?? deviceId;
      final response = await _client
          .post(
            Uri.parse('${ApiConfig.apiUrlV2}/auth/refresh'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              "refresh_token": currentRefreshToken,
              "device_id": currentDeviceId,
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final newAccessToken = data['access_token'];
        final newRefreshToken = data['refresh_token'];

        if (newAccessToken is! String ||
            newAccessToken.isEmpty ||
            newRefreshToken is! String ||
            newRefreshToken.isEmpty) {
          Sentry.captureMessage(
            "Token refresh API returned empty replacement tokens",
          );
          return null;
        }

        await _saveTokens(
          newAccessToken,
          newRefreshToken,
          deviceId: currentDeviceId,
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
      ErrorReporter.captureException(
        e,
        stackTrace: stackTrace,
        operation: 'token.refresh',
      );
      return null;
    }
  }

  Future<T?> _withIOSRefreshLock<T>(Future<T?> Function() operation) async {
    try {
      await _sharedAuthLockChannel.invokeMethod<void>('acquire');
    } on PlatformException catch (error, stackTrace) {
      ErrorReporter.captureException(
        error,
        stackTrace: stackTrace,
        operation: 'token.refresh_lock_acquire',
      );
      return null;
    }

    try {
      return await operation();
    } finally {
      try {
        await _sharedAuthLockChannel.invokeMethod<void>('release');
      } on PlatformException catch (error, stackTrace) {
        ErrorReporter.captureException(
          error,
          stackTrace: stackTrace,
          operation: 'token.refresh_lock_release',
        );
      }
    }
  }

  Future<String?> _refreshWebAccessToken() async {
    final existing = _refreshInFlight;
    if (existing != null) return existing;

    final refresh = () async {
      try {
        final response = await _client
            .post(Uri.parse('${ApiConfig.apiUrlV2}/auth/web/refresh'))
            .timeout(const Duration(seconds: 10));
        if (response.statusCode != 200) {
          _cachedAccessToken = null;
          return null;
        }
        final data = json.decode(response.body);
        final token = data['access_token'];
        if (token is! String || token.isEmpty) return null;
        await saveWebAccessToken(token);
        return token;
      } catch (e, stackTrace) {
        ErrorReporter.captureException(
          e,
          stackTrace: stackTrace,
          operation: 'token.web_refresh',
        );
        return null;
      }
    }();
    _refreshInFlight = refresh;
    try {
      return await refresh;
    } finally {
      if (identical(_refreshInFlight, refresh)) _refreshInFlight = null;
    }
  }

  Future<void> saveWebAccessToken(String accessToken) async {
    _cachedAccessToken = accessToken;
    _cachedRefreshToken = null;
    _tokensLoaded = true;
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.remove(_accessTokenKey),
      prefs.remove(_refreshTokenKey),
      _secureStorage.delete(key: _accessTokenKey),
      _secureStorage.delete(key: _refreshTokenKey),
    ]);
  }

  Future<void> saveTokens(String accessToken, String refreshToken) async {
    if (kIsWeb) {
      return saveWebAccessToken(accessToken);
    }

    final deviceId = Platform.isIOS ? await getDeviceId() : null;
    if (Platform.isIOS) {
      final saved = await _withIOSRefreshLock<bool>(() async {
        await _saveTokens(accessToken, refreshToken, deviceId: deviceId);
        return true;
      });
      if (saved != true) {
        throw StateError('Could not acquire the shared authentication lock.');
      }
      return;
    }
    await _saveTokens(accessToken, refreshToken, deviceId: deviceId);
  }

  Future<void> _saveTokens(
    String accessToken,
    String refreshToken, {
    String? deviceId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final session = _StoredSession(
      accessToken: accessToken,
      refreshToken: refreshToken,
      deviceId: deviceId,
    );

    await _secureStorage.write(key: _sessionKey, value: session.encode());
    await Future.wait([
      _legacySecureStorage.delete(key: _accessTokenKey),
      _legacySecureStorage.delete(key: _refreshTokenKey),
      prefs.remove(_accessTokenKey),
      prefs.remove(_refreshTokenKey),
    ]);
    _cacheSession(session);
  }

  Future<void> clearTokens() async {
    if (!kIsWeb && Platform.isIOS) {
      final cleared = await _withIOSRefreshLock<bool>(() async {
        await _clearTokensUnlocked();
        return true;
      });
      if (cleared != true) {
        throw StateError('Could not acquire the shared authentication lock.');
      }
      return;
    }
    await _clearTokensUnlocked();
  }

  Future<void> _clearTokensUnlocked() async {
    _cachedAccessToken = null;
    _cachedRefreshToken = null;
    _tokensLoaded = true;
    _tokenLoad = null;
    _refreshInFlight = null;
    final prefs = await SharedPreferences.getInstance();
    if (kIsWeb) {
      await Future.wait([
        prefs.remove(_accessTokenKey),
        prefs.remove(_refreshTokenKey),
        _secureStorage.delete(key: _accessTokenKey),
        _secureStorage.delete(key: _refreshTokenKey),
      ]);
      return;
    }

    await Future.wait([
      _secureStorage.delete(key: _sessionKey),
      _legacySecureStorage.delete(key: _accessTokenKey),
      _legacySecureStorage.delete(key: _refreshTokenKey),
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
        return await loadIOSFallbackDeviceId();
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

  @visibleForTesting
  Future<String> loadIOSFallbackDeviceId() async {
    final stored = await _secureStorage.read(key: _deviceIdFallbackKey);
    if (stored != null) return stored;

    final legacy = await _legacySecureStorage.read(key: _deviceIdFallbackKey);
    if (legacy != null) {
      await _secureStorage.write(key: _deviceIdFallbackKey, value: legacy);
      return legacy;
    }

    final generated = const Uuid().v4();
    await _secureStorage.write(key: _deviceIdFallbackKey, value: generated);
    return generated;
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
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await Future.wait([
        prefs.remove(_accessTokenKey),
        prefs.remove(_refreshTokenKey),
        _secureStorage.delete(key: _accessTokenKey),
        _secureStorage.delete(key: _refreshTokenKey),
      ]);
      return (_cachedAccessToken, null);
    }

    final session = await _readStoredSession();
    return (session.accessToken, session.refreshToken);
  }

  Future<_StoredSession> _readStoredSession() async {
    final encodedSession = await _secureStorage.read(key: _sessionKey);
    var session = _StoredSession.tryDecode(encodedSession);
    if (session.accessToken != null && session.refreshToken != null) {
      if (Platform.isIOS && session.deviceId == null) {
        session = session.copyWith(deviceId: await getDeviceId());
        await _secureStorage.write(key: _sessionKey, value: session.encode());
      }
      return session;
    }

    final storedTokens = await Future.wait([
      _legacySecureStorage.read(key: _accessTokenKey),
      _legacySecureStorage.read(key: _refreshTokenKey),
    ]);
    String? accessToken = storedTokens[0];
    String? refreshToken = storedTokens[1];

    final prefs = await SharedPreferences.getInstance();
    final legacyAccessToken = prefs.getString(_accessTokenKey);
    final legacyRefreshToken = prefs.getString(_refreshTokenKey);

    accessToken ??= legacyAccessToken;
    refreshToken ??= legacyRefreshToken;

    if (accessToken != null && refreshToken != null) {
      final deviceId = Platform.isIOS ? await getDeviceId() : null;
      session = _StoredSession(
        accessToken: accessToken,
        refreshToken: refreshToken,
        deviceId: deviceId,
      );
      await _secureStorage.write(key: _sessionKey, value: session.encode());
      await Future.wait([
        _legacySecureStorage.delete(key: _accessTokenKey),
        _legacySecureStorage.delete(key: _refreshTokenKey),
        prefs.remove(_accessTokenKey),
        prefs.remove(_refreshTokenKey),
      ]);
    }

    return session;
  }

  void _cacheSession(_StoredSession session) {
    _cachedAccessToken = session.accessToken;
    _cachedRefreshToken = session.refreshToken;
    _tokensLoaded = true;
  }
}

class _StoredSession {
  const _StoredSession({this.accessToken, this.refreshToken, this.deviceId});

  final String? accessToken;
  final String? refreshToken;
  final String? deviceId;

  static _StoredSession tryDecode(String? value) {
    if (value == null || value.isEmpty) return const _StoredSession();
    try {
      final decoded = jsonDecode(value);
      if (decoded is! Map) return const _StoredSession();
      final accessToken = decoded['access_token'];
      final refreshToken = decoded['refresh_token'];
      final deviceId = decoded['device_id'];
      return _StoredSession(
        accessToken: accessToken is String && accessToken.isNotEmpty
            ? accessToken
            : null,
        refreshToken: refreshToken is String && refreshToken.isNotEmpty
            ? refreshToken
            : null,
        deviceId: deviceId is String && deviceId.isNotEmpty ? deviceId : null,
      );
    } catch (_) {
      return const _StoredSession();
    }
  }

  String encode() => jsonEncode({
    'access_token': accessToken,
    'refresh_token': refreshToken,
    if (deviceId != null) 'device_id': deviceId,
  });

  _StoredSession copyWith({String? deviceId}) => _StoredSession(
    accessToken: accessToken,
    refreshToken: refreshToken,
    deviceId: deviceId ?? this.deviceId,
  );
}
