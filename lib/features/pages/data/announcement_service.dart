import 'package:clashkingapp/core/services/api_service.dart';
import 'package:clashkingapp/core/services/game_data_service.dart';
import 'package:clashkingapp/features/pages/models/app_announcement.dart';
import 'package:flutter/foundation.dart';

class AnnouncementArchivePage {
  const AnnouncementArchivePage({
    required this.items,
    required this.hasMore,
    required this.nextOffset,
  });

  final List<AppAnnouncement> items;
  final bool hasMore;
  final int nextOffset;
}

class AnnouncementService {
  AnnouncementService({ApiService? apiService})
    : _apiService = apiService ?? ApiService.shared;

  final ApiService _apiService;

  Future<AppAnnouncement?> getActiveAnnouncement() async {
    final announcements = await getActiveAnnouncements();
    return announcements.isEmpty ? null : announcements.first;
  }

  Future<List<AppAnnouncement>> getActiveAnnouncements() async {
    try {
      final locale = await GameDataService.resolvePreferredLocale();
      final target = announcementTarget(
        isWeb: kIsWeb,
        platform: defaultTargetPlatform,
      );
      final response = await _apiService.get(
        '/app/announcements/active?target=$target&locale=${Uri.encodeQueryComponent(locale.languageCode)}',
        requiresAuth: false,
      );
      final items = response['items'];
      if (items is List) {
        return items
            .whereType<Map<String, dynamic>>()
            .map(AppAnnouncement.fromJson)
            .where(
              (announcement) =>
                  announcement.title.isNotEmpty &&
                  announcement.subtitle.isNotEmpty,
            )
            .toList();
      }
      final item = response['item'];
      if (item is! Map<String, dynamic>) {
        return const [];
      }
      final announcement = AppAnnouncement.fromJson(item);
      if (announcement.title.isEmpty || announcement.subtitle.isEmpty) {
        return const [];
      }
      return [announcement];
    } catch (_) {
      return const [];
    }
  }

  Future<AppAnnouncement?> getAnnouncement(String id) async {
    if (id.trim().isEmpty) return null;
    try {
      final locale = await GameDataService.resolvePreferredLocale();
      final response = await _apiService.get(
        '/app/announcements/${Uri.encodeComponent(id)}?locale=${Uri.encodeQueryComponent(locale.languageCode)}',
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

  Future<AnnouncementArchivePage> getPublishedPosts({
    int limit = 20,
    int offset = 0,
  }) async {
    final locale = await GameDataService.resolvePreferredLocale();
    final target = announcementTarget(
      isWeb: kIsWeb,
      platform: defaultTargetPlatform,
    );
    final response = await _apiService.get(
      '/app/posts?target=$target&limit=$limit&offset=$offset&locale=${Uri.encodeQueryComponent(locale.languageCode)}',
      requiresAuth: false,
    );
    final rawItems = response['items'];
    final items = rawItems is List
        ? rawItems
              .whereType<Map<String, dynamic>>()
              .map(AppAnnouncement.fromJson)
              .where(
                (announcement) =>
                    announcement.title.isNotEmpty &&
                    announcement.subtitle.isNotEmpty,
              )
              .toList()
        : <AppAnnouncement>[];
    return AnnouncementArchivePage(
      items: items,
      hasMore: response['has_more'] == true,
      nextOffset:
          (response['next_offset'] as num?)?.toInt() ?? offset + items.length,
    );
  }
}

String announcementTarget({
  required bool isWeb,
  required TargetPlatform platform,
}) {
  if (isWeb) return 'all';
  return switch (platform) {
    TargetPlatform.iOS => 'ios',
    TargetPlatform.android => 'android',
    _ => 'all',
  };
}
