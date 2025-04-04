import 'dart:convert';
import 'dart:io';
import 'package:clashkingapp/core/services/api_service.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class TokenService {
  Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('access_token');
    final refreshToken = prefs.getString('refresh_token');
    final deviceId = await getDeviceId();

    if (accessToken == null || refreshToken == null) {
      return null;
    }

    if (isTokenExpired(accessToken)) {
      print("🔄 Access Token has expired. Trying to refresh...");
      final newAccessToken = await refreshAccessToken(refreshToken, deviceId);

      if (newAccessToken != null) {
        return newAccessToken;
      } else {
        print(
            "❌ Impossible de rafraîchir le token, l'utilisateur doit se reconnecter.");
        await clearTokens();
        return null;
      }
    }

    return accessToken;
  }

  Future<String?> refreshAccessToken(
      String refreshToken, String deviceId) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiService.apiUrl}/auth/refresh'),
        headers: {'Content-Type': 'application/json'},
        body:
            jsonEncode({"refresh_token": refreshToken, "device_id": deviceId}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final newAccessToken = data['access_token'];

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('access_token', newAccessToken);

        return newAccessToken;
      } else {
        print("❌ Erreur lors du rafraîchissement du token: ${response.body}");
        return null;
      }
    } catch (e) {
      print("❌ Exception lors du rafraîchissement du token: $e");
      return null;
    }
  }

  Future<void> saveTokens(String accessToken, String refreshToken) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', accessToken);
    await prefs.setString('refresh_token', refreshToken);
  }

  Future<void> clearTokens() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('refresh_token');
  }

  bool isTokenExpired(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) {
        return true;
      }
      final payload = json
          .decode(utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))));
      final exp = payload['exp'];
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      return now >= exp;
    } catch (e) {
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
        return androidInfo.id ?? "unknown-android-device";
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        return iosInfo.identifierForVendor ?? "unknown-ios-device";
      } else {
        return "unsupported-platform";
      }
    } catch (e) {
      print("❌ Erreur getDeviceId: $e");
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
        return androidInfo.model ?? "unknown-android-model";
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        return iosInfo.name ?? "unknown-ios-name";
      } else {
        return "unsupported-platform";
      }
    } catch (e) {
      print("❌ Erreur getDeviceName: $e");
      return "unknown-device";
    }
  }
}
