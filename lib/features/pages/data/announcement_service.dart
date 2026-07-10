import 'package:clashkingapp/core/services/api_service.dart';
import 'package:clashkingapp/features/pages/models/app_announcement.dart';
import 'package:flutter/foundation.dart';

class AnnouncementService {
  AnnouncementService({ApiService? apiService})
    : _apiService = apiService ?? ApiService();

  final ApiService _apiService;

  AppAnnouncement getOpeningAnnouncement() => AppAnnouncement.animeFury;

  Future<AppAnnouncement?> getActiveAnnouncement() async {
    try {
      final target = switch (defaultTargetPlatform) {
        TargetPlatform.iOS => 'ios',
        TargetPlatform.android => 'android',
        _ => 'all',
      };
      final response = await _apiService.get(
        '/app/announcements/active?target=$target',
        requiresAuth: false,
      );
      final item = response['item'];
      if (item is! Map<String, dynamic>) {
        return null;
      }
      final announcement = AppAnnouncement.fromJson(item);
      if (announcement.title.isEmpty || announcement.subtitle.isEmpty) {
        return null;
      }
      return announcement;
    } catch (_) {
      return null;
    }
  }
}
