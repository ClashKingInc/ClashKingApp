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
      await scope.setUser(SentryUser(id: user.userId));
    });
  }

  static Future<void> clearUser() async {
    await Sentry.configureScope((scope) async {
      await scope.setUser(null);
    });
  }

  static Future<void> setSelectedPlayerTag(String? _) async {
    await Sentry.configureScope((scope) {
      scope.removeContexts('selected_player');
    });
  }
}
