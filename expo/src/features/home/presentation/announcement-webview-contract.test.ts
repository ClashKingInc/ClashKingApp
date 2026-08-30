import {
  announcementNavigationDecision,
  announcementStoryMessageFromNavigation,
  parseAnnouncementStoryMessage,
} from './announcement-webview-contract';

test('allows only internal documents, cached files, and the configured HTTPS origin', () => {
  expect(announcementNavigationDecision({ requestedUrl: 'about:blank' })).toBe('navigate');
  expect(
    announcementNavigationDecision({
      requestedUrl: 'file:///cache/story.html',
      loadsLocalFile: true,
    }),
  ).toBe('navigate');
  expect(
    announcementNavigationDecision({
      requestedUrl: 'https://news.clashk.ing/posts/june',
      initialUrl: 'https://news.clashk.ing/posts',
    }),
  ).toBe('navigate');
  expect(
    announcementNavigationDecision({
      requestedUrl: 'https://attacker.example/phishing',
      initialUrl: 'https://news.clashk.ing/posts',
    }),
  ).toBe('prevent');
  expect(announcementNavigationDecision({ requestedUrl: 'javascript:alert(1)' })).toBe('prevent');
});

test('accepts bridge navigation only for trusted local stories and known messages', () => {
  expect(
    announcementStoryMessageFromNavigation({
      requestedUrl: 'clashking-story://message?payload=%7B%22type%22%3A%22complete%22%7D',
      isTrustedLocalStory: true,
    }),
  ).toBe('{"type":"complete"}');
  expect(
    announcementStoryMessageFromNavigation({
      requestedUrl: 'clashking-story://message?payload=close',
      isTrustedLocalStory: false,
    }),
  ).toBeNull();
  expect(parseAnnouncementStoryMessage('{"type":"ready"}')).toBe('ready');
  expect(parseAnnouncementStoryMessage('{"type":"unknown"}')).toBeNull();
  expect(parseAnnouncementStoryMessage('close')).toBeNull();
});
