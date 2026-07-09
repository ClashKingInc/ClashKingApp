import 'package:clashkingapp/core/models/user.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

class ObservabilityService {
  ObservabilityService._();

  static Future<void> setAuthenticatedUser(User? user) async {
    if (user == null || user.userId.trim().isEmpty) {
      await clearUser();
      return;
    }

    await Sentry.configureScope((scope) async {
      await scope.setUser(
        SentryUser(
          id: user.userId,
          username: user.username.isEmpty ? null : user.username,
          data: {
            'auth_methods': user.authMethods,
            'has_email_auth': user.hasEmailAuth,
            'has_discord_auth': user.hasDiscordAuth,
          },
        ),
      );
    });
  }

  static Future<void> clearUser() async {
    await Sentry.configureScope((scope) async {
      await scope.setUser(null);
    });
  }

  static Future<void> setSelectedPlayerTag(String? playerTag) async {
    final normalized = playerTag?.trim();
    await Sentry.configureScope((scope) {
      if (normalized == null || normalized.isEmpty) {
        scope.removeContexts('selected_player');
      } else {
        scope.setContexts('selected_player', {'tag': normalized});
      }
    });
  }
}
