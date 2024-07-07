import 'package:clashkingapp/core/startup_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:http/http.dart' as http;
import 'dart:math'; // Pour Random
import 'dart:convert'; // Pour ascii
import 'package:crypto/crypto.dart'; // Pour sha256
import 'package:clashkingapp/core/functions.dart';
import 'package:clashkingapp/global_keys.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:clashkingapp/main_pages/login_page/guest_login_page.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

class LoginPage extends StatefulWidget {
  @override
  LoginPageState createState() => LoginPageState();
}

class LoginPageState extends State<LoginPage> {
  final String clientId = dotenv.env['DISCORD_CLIENT_ID']!;
  final String redirectUri = dotenv.env['DISCORD_REDIRECT_URI']!;
  final String clientSecret = dotenv.env['DISCORD_CLIENT_SECRET']!;
  final String callbackUrlScheme = dotenv.env['DISCORD_CALLBACK_URL_SCHEME']!;

  @override
  Widget build(BuildContext context) {
    // Check if the theme is light or dark
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Set the appropriate image URLs based on the theme
    final logoUrl = isDarkMode
        ? "https://clashkingfiles.b-cdn.net/logos/crown-arrow-dark-bg/ClashKing-1.png"
        : "https://clashkingfiles.b-cdn.net/logos/crown-arrow-white-bg/ClashKing-2.png";
    final textLogoUrl = isDarkMode
        ? "https://clashkingfiles.b-cdn.net/logos/crown-arrow-dark-bg/CK-text-dark-bg.png"
        : "https://clashkingfiles.b-cdn.net/logos/crown-arrow-white-bg/CK-text-white-bg.png";

    return Scaffold(
      body: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints:
                BoxConstraints(minHeight: MediaQuery.of(context).size.height),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Column(
                  children: [
                    SizedBox(
                      height: 150,
                      width: 150,
                      child: CachedNetworkImage(imageUrl: logoUrl),
                    ),
                    SizedBox(height: 8),
                    SizedBox(
                      width: 250,
                      child: CachedNetworkImage(imageUrl: textLogoUrl),
                    ),
                  ],
                ),
                SizedBox(height: 48),
                ButtonTheme(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      minimumSize: Size(240, 48),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.discord, size: 24),
                        SizedBox(width: 8),
                        Text(AppLocalizations.of(context)!.signInWithDiscord),
                      ],
                    ),
                    onPressed: () async {
                      await discordSignIn(context);
                    },
                  ),
                ),
                SizedBox(height: 16),
                ButtonTheme(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.secondary,
                      minimumSize: Size(240, 48),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.group_add, size: 24),
                        SizedBox(width: 8),
                        Text(AppLocalizations.of(context)!.guestMode),
                      ],
                    ),
                    onPressed: () async {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                            builder: (context) => GuestLoginPage()),
                      );
                    },
                  ),
                ),
                SizedBox(height: 8),
                TextButton(
                  child: Text(AppLocalizations.of(context)!.needHelpJoinDiscord,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(decoration: TextDecoration.underline)),
                  onPressed: () async {
                    launchUrl(Uri.parse('https://discord.gg/clashking'));
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> discordSignIn(BuildContext context) async {
    String codeVerifier;
    String codeChallenge;
    String generateCodeVerifier() {
      const String charset =
          'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~';
      return List.generate(
          128, (i) => charset[Random.secure().nextInt(charset.length)]).join();
    }

    String generateCodeChallenge(String codeVerifier) {
      var bytes = ascii.encode(codeVerifier);
      var digest = sha256.convert(bytes);
      String codeChallenge = base64Url
          .encode(digest.bytes)
          .replaceAll("=", "")
          .replaceAll("+", "-")
          .replaceAll("/", "_");
      return codeChallenge;
    }

    codeVerifier = generateCodeVerifier();
    codeChallenge = generateCodeChallenge(codeVerifier);
    final url = Uri.https('discord.com', '/api/oauth2/authorize', {
      'response_type': 'code',
      'client_id': clientId,
      'scope': 'identify email',
      'redirect_uri': redirectUri,
      'code_challenge': codeChallenge,
      'code_challenge_method': 'S256',
    });

    try {
      final result = await FlutterWebAuth2.authenticate(
          url: url.toString(), callbackUrlScheme: callbackUrlScheme);

      final code = Uri.parse(result).queryParameters['code'];
      final tokenUrl = Uri.https('discord.com', '/api/oauth2/token');
      final response = await http.post(tokenUrl, body: {
        'client_id': clientId,
        'client_secret': clientSecret,
        'grant_type': 'authorization_code',
        'code': code,
        'redirect_uri': redirectUri,
        'code_verifier': codeVerifier
      });

      final accessToken = jsonDecode(response.body)['access_token'] as String;
      await storePrefs('user_type', 'discord');
      await storePrefs('access_token', accessToken);

      int expiresIn = jsonDecode(response.body)['expires_in'];
      DateTime expirationDate =
          DateTime.now().add(Duration(seconds: expiresIn));
      await storePrefs('expiration_date', expirationDate.toIso8601String());

      globalNavigatorKey.currentState!.pushReplacement(
        MaterialPageRoute(builder: (context) => StartupWidget()),
      );
    } catch (exception, stackTrace) {
      Sentry.captureException(exception, stackTrace: stackTrace);
    }
  }
}
