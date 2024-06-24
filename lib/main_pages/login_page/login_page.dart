import 'package:clashkingapp/core/startup_widget.dart';
import 'package:flutter/material.dart';
//import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:http/http.dart' as http;
import 'dart:math'; // Pour Random
import 'dart:convert'; // Pour ascii
import 'package:crypto/crypto.dart'; // Pour sha256
import 'package:shared_preferences/shared_preferences.dart';
import 'package:clashkingapp/global_keys.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:clashkingapp/main_pages/login_page/guest_login_page.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

//import 'dart:html' as html;

class LoginPage extends StatefulWidget {
  @override
  LoginPageState createState() => LoginPageState();
}

class LoginPageState extends State<LoginPage> {
  final String clientId = dotenv.env['DISCORD_CLIENT_ID']!;
  final String redirectUri = dotenv.env['DISCORD_REDIRECT_URI']!;
  final String clientSecret = dotenv.env['DISCORD_CLIENT_SECRET']!;
  final String callbackUrlScheme = dotenv.env['DISCORD_CALLBACK_URL_SCHEME']!;
  // final String redirectWebUri = dotenv.env['DISCORD_REDIRECT_URI_WEB']!;
  // Discord n'utilise pas clientSecret dans le flux d'authentification côté client, donc il pourrait ne pas être nécessaire ici

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        // Permet le défilement
        child: Center(
          child: ConstrainedBox(
            constraints:
                BoxConstraints(minHeight: MediaQuery.of(context).size.height),
            child: Column(
              mainAxisAlignment:
                  MainAxisAlignment.center, // Centre verticalement
              children: [
                Column(
                  children: [
                    SizedBox(
                      height: 150,
                      width: 150,
                      child: CachedNetworkImage(
                          imageUrl:
                              "https://clashkingfiles.b-cdn.net/logos/ClashKing-crown-logo.png"),
                    ),
                    SizedBox(
                      width: 250,
                      child: CachedNetworkImage(
                          imageUrl:
                              "https://clashkingfiles.b-cdn.net/logos/ClashKing-name-logo.png"),
                    ),
                  ],
                ),
                SizedBox(height: 64),
                ButtonTheme(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.secondary,
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
                SizedBox(height: 16), // Espace entre les boutons
                ButtonTheme(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
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
                  child: Text(AppLocalizations.of(context)!.needHelpJoinDiscord, style: Theme.of(context).textTheme.bodyMedium?.copyWith(decoration: TextDecoration.underline)),
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

  // Fonction pour lancer le processus d'authentification
  Future<void> discordSignIn(BuildContext context) async {
    String codeVerifier;
    String codeChallenge;
    // Construct the URL
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

// Present the dialog to the user
    try {
      final result = await FlutterWebAuth2.authenticate(
          url: url.toString(), callbackUrlScheme: callbackUrlScheme);

// Extract code from resulting URL
      final code = Uri.parse(result).queryParameters['code'];

// Construct an Uri to Discord's oauth2 endpoint
      final tokenUrl = Uri.https('discord.com', '/api/oauth2/token');

      // Use this code to get an access token
      final response = await http.post(tokenUrl, body: {
        'client_id': clientId,
        'client_secret': clientSecret,
        'grant_type': 'authorization_code',
        'code': code,
        'redirect_uri': redirectUri,
        'code_verifier': codeVerifier
      });

      // Get the access token from the response
      final accessToken = jsonDecode(response.body)['access_token'] as String;

      // Save the access token using shared_preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_type', 'discord');
      await prefs.setString('access_token', accessToken);

      // Save the expiration date of the access token
      int expiresIn = jsonDecode(response.body)['expires_in'];
      DateTime expirationDate =
          DateTime.now().add(Duration(seconds: expiresIn));
      await prefs.setString(
          'expiration_date', expirationDate.toIso8601String());

      // Navigate to MyHomePage
      globalNavigatorKey.currentState!.pushReplacement(
        MaterialPageRoute(builder: (context) => StartupWidget()),
      );
    } catch (exception, stackTrace) {
      Sentry.captureException(exception, stackTrace: stackTrace);
    }
  }

/*
  Future<void> signInWithDiscordFromWeb(BuildContext context) async {
    final url = Uri.https('discord.com', '/api/oauth2/authorize', {
      'response_type': 'code',
      'client_id': clientId,
      'scope': 'identify email',
      'redirect_uri': redirectWebUri,
      'prompt': 'consent',
    });


    html.window.console.log(url.toString());

    // Redirigez l'utilisateur vers l'URL d'authentification
    html.window.location.href = url.toString();

    if (globalNavigatorKey.currentState != null) {
      globalNavigatorKey.currentState!.pushReplacement(
        MaterialPageRoute(builder: (context) => StartupWidget()),
      );
    }
  }*/
}
