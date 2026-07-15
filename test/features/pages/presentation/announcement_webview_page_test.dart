import 'package:clashkingapp/features/pages/presentation/announcement_webview_page.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:webview_flutter/webview_flutter.dart';

void main() {
  group('announcementNavigationDecision', () {
    test('allows navigation within the configured HTTPS origin', () {
      expect(
        announcementNavigationDecision(
          requestedUrl: 'https://news.clashk.ing/posts/june',
          initialUrl: 'https://news.clashk.ing/posts',
        ),
        NavigationDecision.navigate,
      );
    });

    test('blocks cross-origin and non-HTTPS navigation', () {
      expect(
        announcementNavigationDecision(
          requestedUrl: 'https://attacker.example/phishing',
          initialUrl: 'https://news.clashk.ing/posts',
        ),
        NavigationDecision.prevent,
      );
      expect(
        announcementNavigationDecision(
          requestedUrl: 'javascript:alert(1)',
          initialUrl: 'https://news.clashk.ing/posts',
        ),
        NavigationDecision.prevent,
      );
    });

    test('allows file navigation only for cached local stories', () {
      expect(
        announcementNavigationDecision(
          requestedUrl: 'file:///cache/story/index.html',
          loadsLocalFile: true,
        ),
        NavigationDecision.navigate,
      );
      expect(
        announcementNavigationDecision(
          requestedUrl: 'file:///data/private.txt',
        ),
        NavigationDecision.prevent,
      );
    });

    test('allows internal documents used by inline HTML content', () {
      expect(
        announcementNavigationDecision(requestedUrl: 'about:blank'),
        NavigationDecision.navigate,
      );
      expect(
        announcementNavigationDecision(
          requestedUrl: 'data:text/html,%3Ch1%3EPost%3C/h1%3E',
        ),
        NavigationDecision.navigate,
      );
    });
  });
}
