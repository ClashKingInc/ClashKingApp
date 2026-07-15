import 'dart:convert';

import 'package:clashkingapp/core/services/api_service.dart';
import 'package:clashkingapp/features/pages/data/announcement_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('loads a paginated archive of current and past posts', () async {
    final client = MockClient((request) async {
      expect(request.url.path, endsWith('/app/posts'));
      expect(request.url.queryParameters['offset'], '20');
      return http.Response(
        jsonEncode({
          'items': [
            {
              'id': 'past',
              'title': 'Previous update',
              'subtitle': 'Release notes',
              'status': 'expired',
              'published_at': '2026-06-01T10:00:00Z',
            },
          ],
          'has_more': true,
          'next_offset': 21,
        }),
        200,
        headers: {'content-type': 'application/json'},
      );
    });
    final service = AnnouncementService(apiService: ApiService(client: client));

    final page = await service.getPublishedPosts(offset: 20);

    expect(page.items.single.status, 'expired');
    expect(page.items.single.publishedAt, DateTime.utc(2026, 6, 1, 10));
    expect(page.hasMore, isTrue);
    expect(page.nextOffset, 21);
  });

  test('keeps the API home order so pinned posts stay first', () async {
    final client = MockClient(
      (request) async => http.Response(
        jsonEncode({
          'items': [
            {'id': 'pinned', 'title': 'Pinned', 'subtitle': 'First'},
            {'id': 'newer', 'title': 'Newer', 'subtitle': 'Second'},
          ],
        }),
        200,
        headers: {'content-type': 'application/json'},
      ),
    );
    final service = AnnouncementService(apiService: ApiService(client: client));

    final announcements = await service.getActiveAnnouncements();

    expect(announcements.map((item) => item.id), ['pinned', 'newer']);
  });

  test('loads the exact published post used by a push notification', () async {
    final client = MockClient((request) async {
      expect(request.url.path, endsWith('/app/announcements/post-1'));
      return http.Response(
        jsonEncode({
          'item': {
            'id': 'post-1',
            'title': 'Update',
            'subtitle': 'New features',
            'story_url': 'https://cdn.example.com/update.html',
            'body_blocks': [
              {'type': 'paragraph', 'text': 'Details'},
            ],
          },
        }),
        200,
        headers: {'content-type': 'application/json'},
      );
    });
    final service = AnnouncementService(apiService: ApiService(client: client));

    final announcement = await service.getAnnouncement('post-1');

    expect(announcement?.id, 'post-1');
    expect(announcement?.storyUrl, 'https://cdn.example.com/update.html');
    expect(announcement?.body, contains('Details'));
  });
}
