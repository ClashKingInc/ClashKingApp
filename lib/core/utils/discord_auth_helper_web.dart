import 'dart:async';
import 'package:universal_html/html.dart' as html;

const _discordCodeKey = 'ck-discord-auth-code';
const _discordVerifierKey = 'ck-discord-auth-code-verifier';
const _discordCompleteParameter = 'discord_auth';
const _discordCompleteValue = 'complete';

bool hasPendingDiscordAuthResultWeb() {
  return Uri.base.queryParameters[_discordCompleteParameter] ==
          _discordCompleteValue ||
      html.window.sessionStorage[_discordCodeKey] != null;
}

Map<String, String>? consumeDiscordAuthResultWeb() {
  final code = html.window.sessionStorage.remove(_discordCodeKey);
  final verifier = html.window.sessionStorage.remove(_discordVerifierKey);

  final currentUri = Uri.base;
  if (currentUri.queryParameters.containsKey(_discordCompleteParameter)) {
    final cleanedParameters = Map<String, String>.from(
      currentUri.queryParameters,
    )..remove(_discordCompleteParameter);
    final cleanedUri = currentUri.replace(
      queryParameters: cleanedParameters.isEmpty ? null : cleanedParameters,
    );
    html.window.history.replaceState(
      null,
      html.document.title,
      cleanedUri.toString(),
    );
  }

  if (code == null || verifier == null) return null;
  return {'code': code, 'code_verifier': verifier};
}

Future<void> startDiscordAuthRedirectWeb(Uri url, String codeVerifier) async {
  html.window.sessionStorage[_discordVerifierKey] = codeVerifier;
  html.window.location.assign(url.toString());

  // A successful navigation unloads this page before the delay completes. If
  // an embedded browser blocks the redirect, fail instead of leaving the login
  // button in a permanent loading state.
  await Future<void>.delayed(const Duration(seconds: 10));
  throw StateError('Discord authentication redirect was blocked.');
}
