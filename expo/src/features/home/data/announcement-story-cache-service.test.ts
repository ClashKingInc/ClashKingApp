import {
  AnnouncementStoryCacheService,
  type AnnouncementStoryCacheAdapter,
} from './announcement-story-cache-service';
import { AppAnnouncement } from './app-announcement';

const story = new AppAnnouncement(
  'announcement/1',
  'Anime Fury',
  'June update',
  '2',
  null,
  null,
  null,
  'https://cdn.example.com/story.html',
  null,
);

test('downloads once, deduplicates concurrent preparation, and reuses the versioned cache', async () => {
  let cached: string | null = null;
  const download = jest.fn(async (_url: string, fileName: string) => {
    cached = `file:///documents/${fileName}`;
    return cached;
  });
  const adapter: AnnouncementStoryCacheAdapter = {
    cachedUri: jest.fn(async () => cached),
    download,
  };
  const service = new AnnouncementStoryCacheService(adapter);

  const [first, second] = await Promise.all([service.prepare(story), service.prepare(story)]);
  const third = await service.prepare(story);

  expect(first).toBe('file:///documents/announcement_1_2.html');
  expect(second).toBe(first);
  expect(third).toBe(first);
  expect(download).toHaveBeenCalledTimes(1);
});

test('rejects non-HTTPS story downloads', async () => {
  const adapter: AnnouncementStoryCacheAdapter = {
    cachedUri: jest.fn(),
    download: jest.fn(),
  };
  const unsafe = new AppAnnouncement(
    'unsafe',
    'Unsafe',
    'Story',
    null,
    null,
    null,
    null,
    'javascript:alert(1)',
    null,
  );
  await expect(new AnnouncementStoryCacheService(adapter).prepare(unsafe)).resolves.toBeNull();
  expect(adapter.download).not.toHaveBeenCalled();
});
