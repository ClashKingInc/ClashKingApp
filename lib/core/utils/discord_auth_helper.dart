import 'package:flutter/foundation.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:clashkingapp/core/utils/debug_utils.dart';

import 'discord_auth_helper_web.dart'
    if (dart.library.io) 'discord_auth_helper_mobile.dart';
 
class DiscordAuthHelper {
  static const String discordClientId = "824653933347209227";
  static const String callbackUrlScheme = "clashking";

  static Future<Map<String, String>?> getDiscordAuthCode() async {
    final codeVerifier = _generateCodeVerifier();
    final codeChallenge = _generateCodeChallenge(codeVerifier);
    final redirectUri = getRedirectUri();

    DebugUtils.debugInfo("🔄 Redirect URI: $redirectUri");

    final url = Uri.https('discord.com', '/api/oauth2/authorize', {
      'response_type': 'code',
      'client_id': discordClientId,
      'scope': 'identify',
      'redirect_uri': redirectUri,
      'code_challenge': codeChallenge,
      'code_challenge_method': 'S256',
    });

    DebugUtils.debugInfo("🔄 Discord auth URL: $url");

    try {
      if (kIsWeb) {
        final code = await getDiscordAuthCodeWeb(url);
        DebugUtils.debugInfo("🔄 Discord auth code (Web): $code");
        return code != null
            ? {'code': code, 'code_verifier': codeVerifier}
            : null;
      } else {
        final result = await FlutterWebAuth2.authenticate(
          url: url.toString(),
          callbackUrlScheme: callbackUrlScheme,
        );
        DebugUtils.debugInfo("🔄 Discord auth result (Mobile): $result");
        final code = Uri.parse(result).queryParameters['code'];
        DebugUtils.debugInfo("🔄 Discord auth code (Mobile): $code");
        return code != null
            ? {'code': code, 'code_verifier': codeVerifier}
            : null;
      }
    } catch (e) {
      DebugUtils.debugError(' Error getting Discord auth code: $e');
      return null;
    }
  }

  static String _generateCodeVerifier() {
    const String charset =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~';
    return List.generate(
        128, (i) => charset[Random.secure().nextInt(charset.length)]).join();
  }

  static String _generateCodeChallenge(String codeVerifier) {
    return base64Url
        .encode(sha256.convert(ascii.encode(codeVerifier)).bytes)
        .replaceAll('=', '')
        .replaceAll('+', '-')
        .replaceAll('/', '_');
  }

  static String getRedirectUri() {
    if (kIsWeb) {
      return kReleaseMode
          ? "https://clashk.ing/auth/discord_callback.html"
          : "http://localhost:28850/auth/discord_callback.html";
    } else {
      return "clashking://com.clashking.clashkingapp/oauth";
    }
  }
}
