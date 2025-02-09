class Env {
  const Env._();

  // TODO: remove secrets

  // Add new variables here after adding it to config.json

  static const discordClientId = String.fromEnvironment('DISCORD_CLIENT_ID');
  static const discordClientSecret =
      String.fromEnvironment('DISCORD_CLIENT_SECRET');
  static const discordRedirectUri =
      String.fromEnvironment('DISCORD_REDIRECT_URI');
  static const discordCallbackUrlScheme =
      String.fromEnvironment('DISCORD_CALLBACK_URL_SCHEME');
  static const discordCocLogin = String.fromEnvironment('DISCORDCOC_LOGIN');
  static const discordCocPassword =
      String.fromEnvironment('DISCORDCOC_PASSWORD');
  static const sentryDsn = String.fromEnvironment('SENTRY_DSN');
  static const encryptionKey = String.fromEnvironment('ENCRYPTION_KEY');
  static const hmacKey = String.fromEnvironment('HMAC_KEY');
}
