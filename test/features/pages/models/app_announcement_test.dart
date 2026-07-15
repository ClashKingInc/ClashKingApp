import 'package:clashkingapp/features/pages/models/app_announcement.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('converts admin post blocks to safe readable HTML', () {
    final announcement = AppAnnouncement.fromJson({
      'id': 'post-1',
      'title': 'Update',
      'subtitle': 'What changed',
      'target_route': '/war-cwl',
      'body_blocks': [
        {'type': 'heading', 'text': 'New <features>'},
        {'type': 'paragraph', 'text': 'Safer & faster'},
        {
          'type': 'bullet_list',
          'items': ['One', 'Two'],
        },
        {'type': 'image', 'url': 'javascript:alert(1)', 'caption': 'Unsafe'},
      ],
    });

    expect(announcement.targetRoute, '/war-cwl');
    expect(announcement.body, contains('New &lt;features&gt;'));
    expect(announcement.body, contains('Safer &amp; faster'));
    expect(announcement.body, contains('<li>One</li>'));
    expect(announcement.body, isNot(contains('javascript:')));
  });
}
