bool hasPendingDiscordAuthResultWeb() => false;

Map<String, String>? consumeDiscordAuthResultWeb() => null;

Future<void> startDiscordAuthRedirectWeb(Uri url, String codeVerifier) async {
  throw UnsupportedError(
    "startDiscordAuthRedirectWeb is only supported on Web.",
  );
}
