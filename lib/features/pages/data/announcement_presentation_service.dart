import 'dart:convert';

import 'package:clashkingapp/core/models/notification_preferences.dart';
import 'package:clashkingapp/core/services/notification_preferences_service.dart';
import 'package:clashkingapp/features/pages/models/app_announcement.dart';
import 'package:shared_preferences/shared_preferences.dart';

typedef AnnouncementPreferencesLoader = Future<SharedPreferences> Function();

class AnnouncementPresentationService {
  AnnouncementPresentationService({
    AnnouncementPreferencesLoader? preferencesLoader,
  }) : _preferencesLoader = preferencesLoader ?? SharedPreferences.getInstance;

  static const _dismissedPrefix = 'announcement_dismissed_';

  final AnnouncementPreferencesLoader _preferencesLoader;

  Future<bool> shouldPresent(AppAnnouncement announcement) async {
    final preferences = await _preferencesLoader();
    final raw = preferences.getString(NotificationPreferencesService.localKey);
    final announcementsEnabled = raw == null
        ? false
        : NotificationPreferences.fromJson(
            Map<String, dynamic>.from(jsonDecode(raw) as Map),
          ).announcements;
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
