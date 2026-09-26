import { AppAnnouncement } from './app-announcement';
import { AnnouncementService, announcementTarget } from './announcement-service';
import { createContractTestApi } from '../../../core/api/contract-api.testing';

const announcement = {
  id: 'a',
  version: '1',
  title: 'T',
  subtitle: 'S',
  body_blocks: [],
  presentation_type: 'article',
  show_on_home: true,
  pinned_on_home: false,
  status: 'live',
};
const apiFor = (fetchImplementation: typeof fetch) =>
  createContractTestApi({ baseUrl: 'https://api.test', fetchImplementation });

describe('announcements', () => {
  it('maps targets exactly', () => {
    expect(announcementTarget('ios')).toBe('ios');
    expect(announcementTarget('android')).toBe('android');
    expect(announcementTarget('web')).toBe('all');
  });

  it('preserves API-returned media URLs without a client CDN rewrite', async () => {
    const bannerUrl = 'https://api.clashk.ing/v2/media/announcement-hero.png';
    const storyUrl = 'https://api.clashk.ing/v2/media/announcement-story.html';
    const fetchImplementation = jest.fn().mockResolvedValue(
      new Response(
        JSON.stringify({
          item: {
            ...announcement,
            banner_image_url: bannerUrl,
            presentation_type: 'story',
            story_url: storyUrl,
          },
        }),
      ),
    );
    const service = new AnnouncementService(apiFor(fetchImplementation), 'ios', () => 'en');
    await expect(service.getAnnouncement('a')).resolves.toMatchObject({
      bannerImageUrl: bannerUrl,
      storyUrl,
    });
  });

  it('converts supported body blocks to the same safe document structure', () => {
    const item = AppAnnouncement.fromJson({
      id: 'a',
      title: 'Title',
      subtitle: 'Subtitle',
      banner_image_url: 'https://example.com/hero.png',
      body_blocks: [
        { type: 'heading', text: '<News>' },
        { type: 'paragraph', text: 'A & B' },
        { type: 'bullet_list', items: ['One', ''] },
        { type: 'image', url: 'javascript:alert(1)', caption: 'bad' },
      ],
    });
    expect(item.body).toContain('&lt;News&gt;');
    expect(item.body).toContain('A &amp; B');
    expect(item.body).toContain('<li>One</li>');
    expect(item.body).not.toContain('javascript:');
    expect(item.hasReadableBody).toBe(true);
  });

  it('keeps active fetch best-effort and uses language-only locale', async () => {
    const fetchImplementation = jest
      .fn()
      .mockResolvedValueOnce(
        new Response(JSON.stringify({ item: announcement, items: [announcement] })),
      )
      .mockRejectedValueOnce(new Error('offline'));
    const service = new AnnouncementService(apiFor(fetchImplementation), 'ios', () => 'en_GB');
    await expect(service.getActiveAnnouncements()).resolves.toHaveLength(1);
    const request = fetchImplementation.mock.calls[0]![0] as Request;
    expect(request.url).toBe('https://api.test/v2/app/announcements/active?target=ios&locale=en');
    expect(request.headers.has('authorization')).toBe(false);
    await expect(service.getActiveAnnouncements()).resolves.toEqual([]);
  });

  it('resolves an exact notification through the public announcement route', async () => {
    const fetchImplementation = jest.fn().mockResolvedValue(
      new Response(
        JSON.stringify({
          item: {
            ...announcement,
            id: 'target',
            title: 'Target',
            subtitle: 'Notification',
          },
        }),
      ),
    );
    const service = new AnnouncementService(apiFor(fetchImplementation), 'android', () => 'fr_CA');

    await expect(service.getAnnouncement(' target ')).resolves.toMatchObject({ id: 'target' });
    const request = fetchImplementation.mock.calls[0]![0] as Request;
    expect(request.url).toBe('https://api.test/v2/app/announcements/target?locale=fr');
    expect(request.headers.has('authorization')).toBe(false);
  });

  it('keeps exact notification lookup best-effort', async () => {
    const fetchImplementation = jest.fn().mockRejectedValue(new Error('missing'));
    const service = new AnnouncementService(apiFor(fetchImplementation), 'web', () => 'en');

    await expect(service.getAnnouncement('missing')).resolves.toBeNull();
    expect(fetchImplementation).toHaveBeenCalledTimes(1);
  });
});
