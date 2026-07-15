import 'package:clashkingapp/features/pages/data/announcement_presentation_service.dart';
import 'package:clashkingapp/features/pages/models/app_announcement.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const testAnnouncement = AppAnnouncement(
  id: 'announcement-1',
  version: '2',
  title: 'Test update',
  subtitle: 'Test story',
  storyUrl: 'https://example.com/story.html',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test(
    'shows an announcement until its ID and version are dismissed',
    () async {
      final service = AnnouncementPresentationService();
      const announcement = testAnnouncement;

      expect(await service.shouldPresent(announcement), isTrue);

      await service.markDismissed(announcement);

      expect(await service.shouldPresent(announcement), isFalse);
    },
  );

  test(
    'a new announcement version is shown after an earlier version',
    () async {
      final service = AnnouncementPresentationService();
      const versionOne = testAnnouncement;
      const versionTwo = AppAnnouncement(
        id: 'announcement-1',
        version: '3',
        title: 'Anime Fury',
        subtitle: 'Updated story',
      );

      await service.markDismissed(versionOne);

      expect(await service.shouldPresent(versionTwo), isTrue);
    },
  );

  test('respects the app announcement notification preference', () async {
    SharedPreferences.setMockInitialValues({
      'notif_settings_enabled_types': <String>['Events'],
    });
    final service = AnnouncementPresentationService();

    expect(await service.shouldPresent(testAnnouncement), isFalse);
  });
}
