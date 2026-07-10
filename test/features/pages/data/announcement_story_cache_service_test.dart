import 'dart:io';

import 'package:clashkingapp/features/pages/data/announcement_story_cache_service.dart';
import 'package:clashkingapp/features/pages/models/app_announcement.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory temporaryDirectory;

  setUp(() async {
    temporaryDirectory = await Directory.systemTemp.createTemp(
      'announcement-story-cache-test-',
    );
  });

  tearDown(() async {
    await temporaryDirectory.delete(recursive: true);
  });

  test('downloads once and reuses the versioned cached story', () async {
    var requests = 0;
    final client = MockClient((request) async {
      requests++;
      return http.Response('<html>Anime Fury</html>', HttpStatus.ok);
    });
    final service = AnnouncementStoryCacheService(
      client: client,
      directoryLoader: () async => temporaryDirectory,
    );

    final firstPath = await service.prepare(AppAnnouncement.animeFury);
    final secondPath = await service.prepare(AppAnnouncement.animeFury);

    expect(firstPath, isNotNull);
    expect(secondPath, firstPath);
    expect(requests, 1);
    expect(await File(firstPath!).readAsString(), contains('Anime Fury'));
  });
}
