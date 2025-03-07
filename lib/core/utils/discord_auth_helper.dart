import 'dart:math';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';

class DiscordAuthHelper {
  static const String discordClientId = "824653933347209227";
  static const String discordRedirectUri = "clashking://com.clashking.clashkingapp/oauth";
  static const String callbackUrlScheme = "clashking";

  static Future<Map<String, String>?> getDiscordAuthCode() async {
    final codeVerifier = _generateCodeVerifier();
    final codeChallenge = _generateCodeChallenge(codeVerifier);

    final url = Uri.https('discord.com', '/api/oauth2/authorize', {
      'response_type': 'code',
      'client_id': discordClientId,
      'scope': 'identify',
      'redirect_uri': discordRedirectUri,
      'code_challenge': codeChallenge,
      'code_challenge_method': 'S256',
    });

    try {
      final result = await FlutterWebAuth2.authenticate(
        url: url.toString(),
        callbackUrlScheme: callbackUrlScheme,
      );
      final code = Uri.parse(result).queryParameters['code'];
      return code != null ? {'code': code, 'code_verifier': codeVerifier} : null;
    } catch (e) {
      print('Error getting Discord auth code: $e');
      return null;
    }
  }

  static String _generateCodeVerifier() {
    const String charset = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~';
    return List.generate(128, (i) => charset[Random.secure().nextInt(charset.length)]).join();
  }

  static String _generateCodeChallenge(String codeVerifier) {
    return base64Url.encode(sha256.convert(ascii.encode(codeVerifier)).bytes)
        .replaceAll('=', '').replaceAll('+', '-').replaceAll('/', '_');
  }
}
