import { act, renderHook } from '@testing-library/react-native';

import { AnnouncementStoryCacheService, AppAnnouncement } from '../data';
import { postArticleHtml } from './announcement-article-screen';
import {
  announcementStoryWebUrl,
  openAnnouncementStoryWindow,
  useAnnouncementPresentation,
} from './announcement-presenter';
import { isHomeAnnouncementOpenable } from './event-banner';

jest.mock('react-native-webview', () => ({
  WebView: jest.requireActual<typeof import('react-native')>('react-native').View,
}));

const story = (storyUrl: string | null, htmlUrl: string | null = null) =>
  new AppAnnouncement('story', 'Story', 'Details', null, null, null, htmlUrl, storyUrl, null);

test('web stories open trusted HTTPS in a separate window and fall back to html URL', () => {
  expect(announcementStoryWebUrl(story('javascript:alert(1)', 'https://news.example/story'))).toBe(
    'https://news.example/story',
  );
  const openWindow = jest.fn(() => ({}));
  expect(openAnnouncementStoryWindow(story('https://cdn.example/story'), openWindow)).toBe(true);
  expect(openWindow).toHaveBeenCalledWith('https://cdn.example/story');
  expect(openAnnouncementStoryWindow(story('http://unsafe.example'), openWindow)).toBe(false);
});

test('article HTML removes the duplicated generated hero image only when a native hero is shown', () => {
  const html =
    '<body><img class="hero" src="https://cdn.example/hero.png" alt=""><p>Body</p></body>';
  expect(postArticleHtml(html, true)).toBe('<body><p>Body</p></body>');
  expect(postArticleHtml(html, false)).toBe(html);
});

test('Home only makes announcements actionable when Flutter has readable content', () => {
  expect(
    isHomeAnnouncementOpenable({ id: 'empty', title: 'Empty', subtitle: '', imageUrl: 'x' }),
  ).toBe(false);
  expect(
    isHomeAnnouncementOpenable({ id: 'body', title: 'Body', subtitle: '', html: '<p>x</p>' }),
  ).toBe(true);
  expect(
    isHomeAnnouncementOpenable({
      id: 'story',
      title: 'Story',
      subtitle: '',
      storyUrl: 'https://example.com/story',
    }),
  ).toBe(true);
});

test('a controller-prepared story is presented without a second cache lookup', async () => {
  const adapter = {
    cachedUri: jest.fn(async () => null),
    download: jest.fn(async () => null),
  };
  const cache = new AnnouncementStoryCacheService(adapter);
  const hook = await renderHook(() => useAnnouncementPresentation(cache));
  let displayed!: Promise<boolean>;
  await act(async () => {
    displayed = hook.result.current.openPreparedStory(
      story('https://cdn.example/story'),
      'file:///prepared-story.html',
    );
    await Promise.resolve();
  });
  expect(adapter.cachedUri).not.toHaveBeenCalled();
  expect(adapter.download).not.toHaveBeenCalled();
  await act(async () => hook.result.current.closeAnnouncement());
  await expect(displayed).resolves.toBe(true);
});
