import 'package:clashkingapp/core/startup_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:http/http.dart' as http;
import 'dart:math'; // Pour Random
import 'dart:convert'; // Pour ascii
import 'package:crypto/crypto.dart'; // Pour sha256
import 'package:shared_preferences/shared_preferences.dart';
import 'package:clashkingapp/global_keys.dart';
//import 'dart:html' as html;

class LoginPage extends StatelessWidget {
  // Assurez-vous d'avoir initialisé dotenv avant de l'utiliser pour charger les variables d'environnement
  final String clientId = dotenv.env['DISCORD_CLIENT_ID']!;
  final String redirectUri = dotenv.env['DISCORD_REDIRECT_URI']!;
  final String clientSecret = dotenv.env['DISCORD_CLIENT_SECRET']!;
  final String callbackUrlScheme = dotenv.env['DISCORD_CALLBACK_URL_SCHEME']!;
  final String redirectWebUri = dotenv.env['DISCORD_REDIRECT_URI_WEB']!;
  // Discord n'utilise pas clientSecret dans le flux d'authentification côté client, donc il pourrait ne pas être nécessaire ici

  // Fonction pour lancer le processus d'authentification
  Future<void> signInWithDiscordFromMobile(BuildContext context) async {
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
      print("Result: $result");

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
    } catch (e) {
      print("Error: $e");
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          child: Text('Se connecter avec Discord'),
          onPressed: () async {
              await signInWithDiscordFromMobile(context);

            /*if (kIsWeb) {
              await signInWithDiscordFromWeb(context);
            } else {
              await signInWithDiscordFromMobile(context);
            }*/
          },
        ),
      ),
    );
  }
}
