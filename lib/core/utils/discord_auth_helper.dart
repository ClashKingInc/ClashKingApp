import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:app_links/app_links.dart';
import 'package:crypto/crypto.dart';
import 'package:clashkingapp/core/utils/debug_utils.dart';
import 'package:url_launcher/url_launcher.dart';

import 'discord_auth_helper_web.dart'
    if (dart.library.io) 'discord_auth_helper_mobile.dart';

class DiscordAuthHelper {
  static const String discordClientId = "824653933347209227";
  static const String callbackUrlScheme = "clashking";

  static Future<Map<String, String>?> getDiscordAuthCode() async {
    final codeVerifier = _generateCodeVerifier();
    final codeChallenge = _generateCodeChallenge(codeVerifier);
    final state = _generateState();
    final redirectUri = getRedirectUri();

    DebugUtils.debugInfo("🔄 Redirect URI: $redirectUri");

    final url = Uri.https('discord.com', '/api/oauth2/authorize', {
      'response_type': 'code',
      'client_id': discordClientId,
      'scope': 'identify',
      'redirect_uri': redirectUri,
      'code_challenge': codeChallenge,
      'code_challenge_method': 'S256',
      'state': state,
    });

    DebugUtils.debugInfo("🔄 Discord auth URL: $url");

    try {
      if (kIsWeb) {
        final result = await getDiscordAuthCodeWeb(url, state);
        final code = result?['code'];
        return code != null
            ? {'code': code, 'code_verifier': codeVerifier}
            : null;
      } else {
        final result = await _launchDiscordAuth(url);
        if (result.queryParameters['state'] != state) {
          throw StateError('Discord OAuth state did not match this login.');
        }
        final oauthError = result.queryParameters['error'];
        if (oauthError == 'access_denied') {
          return null;
        }
        if (oauthError != null) {
          throw StateError(
            result.queryParameters['error_description'] ?? oauthError,
          );
        }
        final code = result.queryParameters['code'];
        return code != null
            ? {'code': code, 'code_verifier': codeVerifier}
            : null;
      }
    } catch (e) {
      DebugUtils.debugError(' Error getting Discord auth code: $e');
      rethrow;
    }
  }

  static String _generateState() {
    const charset =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_';
    return List.generate(
      64,
      (_) => charset[Random.secure().nextInt(charset.length)],
    ).join();
  }

  static String _generateCodeVerifier() {
    const String charset =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~';
    return List.generate(
      128,
      (i) => charset[Random.secure().nextInt(charset.length)],
    ).join();
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
      final origin = Uri.base.origin;
      final host = Uri.base.host;
      final isLocalHost = host == 'localhost' || host == '127.0.0.1';
      if (isLocalHost) return "$origin/auth/callback";
      return kReleaseMode
          ? "https://app.clashk.ing/auth/discord_callback.html"
          : "$origin/auth/discord_callback.html";
    } else {
      return "clashking://com.clashking.clashkingapp/oauth";
    }
  }

  static Future<Uri> _launchDiscordAuth(Uri url) async {
    final appLinks = AppLinks();
    final completer = Completer<Uri>();
    late final StreamSubscription<Uri> subscription;

    subscription = appLinks.uriLinkStream.listen(
      (uri) {
        if (_isOAuthRedirect(uri) && !completer.isCompleted) {
          completer.complete(uri);
        }
      },
      onError: (error) {
        if (!completer.isCompleted) {
          completer.completeError(error);
        }
      },
    );

    try {
      final launched = await launchUrl(
        url,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        throw Exception('Could not open Discord auth URL.');
      }

      return await completer.future.timeout(const Duration(minutes: 2));
    } finally {
      await subscription.cancel();
    }
  }

  static bool _isOAuthRedirect(Uri uri) {
    return uri.scheme == callbackUrlScheme &&
        uri.host == 'com.clashking.clashkingapp' &&
        uri.path == '/oauth';
  }
}
