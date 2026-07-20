import 'package:clashkingapp/features/pages/presentation/announcement_story_dialog.dart';
import 'package:clashkingapp/features/pages/models/app_announcement.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('embedded announcement stories are disabled on web', () {
    expect(supportsEmbeddedAnnouncementStories(isWeb: true), isFalse);
    expect(supportsEmbeddedAnnouncementStories(isWeb: false), isTrue);
  });

  test('web stories open only trusted HTTPS URLs', () {
    const story = AppAnnouncement(
      id: 'story',
      title: 'Story',
      subtitle: 'Details',
      storyUrl: 'https://cdn.example.com/story.html',
    );
    const unsafeStory = AppAnnouncement(
      id: 'unsafe',
      title: 'Unsafe',
      subtitle: 'Details',
      storyUrl: 'javascript:alert(1)',
    );

    expect(
      announcementStoryWebUri(story),
      Uri.parse('https://cdn.example.com/story.html'),
    );
    expect(announcementStoryWebUri(unsafeStory), isNull);
  });
}
