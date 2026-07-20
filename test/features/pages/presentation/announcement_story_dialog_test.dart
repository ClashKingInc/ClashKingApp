import 'package:clashkingapp/features/pages/presentation/announcement_story_dialog.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('embedded announcement stories are disabled on web', () {
    expect(supportsEmbeddedAnnouncementStories(isWeb: true), isFalse);
    expect(supportsEmbeddedAnnouncementStories(isWeb: false), isTrue);
  });
}
