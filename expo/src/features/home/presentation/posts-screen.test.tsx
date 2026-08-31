import { fireEvent, render, waitFor } from '@testing-library/react-native';
import { StyleSheet } from 'react-native';
import { SafeAreaProvider } from 'react-native-safe-area-context';

import { I18nProvider } from '../../../i18n';
import { CKThemeProvider } from '../../../ui';
import { AppAnnouncement, type AnnouncementService } from '../data';
import { PostsScreen } from './posts-screen';

jest.mock('react-native-webview', () => ({
  WebView: jest.requireActual<typeof import('react-native')>('react-native').View,
}));
jest.mock('@clashking/native', () => ({ __esModule: true, default: {} }));

const firstPost = new AppAnnouncement(
  'post-1',
  'June update',
  'Release notes',
  null,
  '<html><body>Details</body></html>',
  'https://cdn.example.com/june-update.png',
  null,
  null,
  null,
  'article',
  'expired',
  new Date('2026-06-01T10:00:00Z'),
);

test('renders the archive, paginates, and opens an article with the production copy', async () => {
  const getPublishedPosts = jest
    .fn()
    .mockResolvedValueOnce({ items: [firstPost], hasMore: true, nextOffset: 1 })
    .mockResolvedValueOnce({ items: [], hasMore: false, nextOffset: 1 });
  const service = {
    getPublishedPosts,
    getAnnouncement: jest.fn(async () => null),
  } as unknown as AnnouncementService;
  const screen = await render(
    <SafeAreaProvider
      initialMetrics={{
        frame: { x: 0, y: 0, width: 390, height: 844 },
        insets: { top: 47, right: 0, bottom: 34, left: 0 },
      }}
    >
      <I18nProvider locale="en">
        <CKThemeProvider preference="light">
          <PostsScreen service={service} onBack={jest.fn()} />
        </CKThemeProvider>
      </I18nProvider>
    </SafeAreaProvider>,
  );

  await waitFor(() => expect(screen.getByRole('button', { name: 'June update' })).toBeTruthy());
  expect(screen.getByTestId('post-archive-image')).toBeTruthy();
  expect(screen.getByRole('button', { name: 'Back' })).toBeTruthy();
  expect(
    screen.getByText('ClashKing news, update stories, and previous announcements.'),
  ).toBeTruthy();
  await fireEvent.press(screen.getByText('Load more'));
  await waitFor(() => expect(getPublishedPosts).toHaveBeenLastCalledWith(20, 1));

  await fireEvent.press(screen.getByRole('button', { name: 'June update' }));
  expect(screen.getByTestId('post-article-hero-image')).toBeTruthy();
  expect(screen.getAllByText('June update').length).toBeGreaterThan(1);
  expect(screen.getAllByText('Release notes').length).toBeGreaterThan(1);
});

test('mirrors archive card direction for an app-selected RTL locale', async () => {
  const service = {
    getPublishedPosts: jest.fn(async () => ({ items: [firstPost], hasMore: false, nextOffset: 1 })),
    getAnnouncement: jest.fn(async () => null),
  } as unknown as AnnouncementService;
  const screen = await render(
    <SafeAreaProvider
      initialMetrics={{
        frame: { x: 0, y: 0, width: 390, height: 844 },
        insets: { top: 47, right: 0, bottom: 34, left: 0 },
      }}
    >
      <I18nProvider locale="ar">
        <CKThemeProvider preference="light">
          <PostsScreen service={service} />
        </CKThemeProvider>
      </I18nProvider>
    </SafeAreaProvider>,
  );

  await waitFor(() => expect(screen.getByTestId('post-card-title-row')).toBeTruthy());
  expect(
    StyleSheet.flatten(screen.getByTestId('post-card-title-row').props.style).flexDirection,
  ).toBe('row-reverse');
});
