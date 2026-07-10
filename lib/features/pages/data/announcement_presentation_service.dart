import 'package:clashkingapp/features/pages/models/app_announcement.dart';
import 'package:shared_preferences/shared_preferences.dart';

typedef AnnouncementPreferencesLoader = Future<SharedPreferences> Function();

class AnnouncementPresentationService {
  AnnouncementPresentationService({
    AnnouncementPreferencesLoader? preferencesLoader,
  }) : _preferencesLoader = preferencesLoader ?? SharedPreferences.getInstance;

  static const notificationPreferenceLabel = 'App announcements';
  static const _enabledTypesKey = 'notif_settings_enabled_types';
  static const _dismissedPrefix = 'announcement_dismissed_';

  final AnnouncementPreferencesLoader _preferencesLoader;

  Future<bool> shouldPresent(AppAnnouncement announcement) async {
    final preferences = await _preferencesLoader();
    final enabledTypes = preferences.getStringList(_enabledTypesKey);
    final announcementsEnabled =
        enabledTypes == null ||
        enabledTypes.contains(notificationPreferenceLabel);
    if (!announcementsEnabled) {
      return false;
    }

    return !(preferences.getBool(_keyFor(announcement)) ?? false);
  }

  Future<void> markDismissed(AppAnnouncement announcement) async {
    final preferences = await _preferencesLoader();
    await preferences.setBool(_keyFor(announcement), true);
  }

  Future<void> clearDismissal(AppAnnouncement announcement) async {
    final preferences = await _preferencesLoader();
    await preferences.remove(_keyFor(announcement));
  }

  static String _keyFor(AppAnnouncement announcement) =>
      '$_dismissedPrefix${announcement.presentationKey}';
}
