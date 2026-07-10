import 'dart:async';
import 'dart:io';

import 'package:clashkingapp/features/pages/models/app_announcement.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

typedef AnnouncementCacheDirectoryLoader = Future<Directory> Function();

class AnnouncementStoryCacheService {
  AnnouncementStoryCacheService({
    http.Client? client,
    AnnouncementCacheDirectoryLoader? directoryLoader,
  }) : _client = client ?? http.Client(),
       _directoryLoader = directoryLoader ?? getApplicationSupportDirectory;

  static final Map<String, Future<String?>> _inFlight = {};

  final http.Client _client;
  final AnnouncementCacheDirectoryLoader _directoryLoader;

  Future<String?> prepare(AppAnnouncement announcement) {
    final storyUrl = announcement.storyUrl;
    if (storyUrl == null || storyUrl.isEmpty) {
      return Future.value(null);
    }

    return _inFlight.putIfAbsent(
      announcement.presentationKey,
      () => _prepare(announcement, storyUrl).whenComplete(() {
        _inFlight.remove(announcement.presentationKey);
      }),
    );
  }

  Future<String?> _prepare(
    AppAnnouncement announcement,
    String storyUrl,
  ) async {
    try {
      final supportDirectory = await _directoryLoader();
      final cacheDirectory = Directory(
        '${supportDirectory.path}/announcement_stories',
      );
      await cacheDirectory.create(recursive: true);

      final cacheFile = File(
        '${cacheDirectory.path}/${_safeName(announcement.presentationKey)}.html',
      );
      if (await cacheFile.exists() && await cacheFile.length() > 0) {
        return cacheFile.path;
      }

      final response = await _client
          .get(Uri.parse(storyUrl))
          .timeout(const Duration(seconds: 20));
      if (response.statusCode != HttpStatus.ok || response.bodyBytes.isEmpty) {
        return null;
      }

      final temporaryFile = File('${cacheFile.path}.download');
      await temporaryFile.writeAsBytes(response.bodyBytes, flush: true);
      await temporaryFile.rename(cacheFile.path);
      return cacheFile.path;
    } catch (_) {
      return null;
    }
  }

  static String _safeName(String value) =>
      value.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
}
