import { AppAnnouncement } from './app-announcement';
import { AnnouncementService, announcementTarget } from './announcement-service';

describe('announcements', () => {
  it('maps targets exactly', () => {
    expect(announcementTarget('ios')).toBe('ios');
    expect(announcementTarget('android')).toBe('android');
    expect(announcementTarget('web')).toBe('all');
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
    const requestRecord = jest
      .fn()
      .mockResolvedValueOnce({ items: [{ id: 'a', title: 'T', subtitle: 'S' }] })
      .mockRejectedValueOnce(new Error('offline'));
    const service = new AnnouncementService({ requestRecord } as never, 'ios', () => 'en_GB');
    await expect(service.getActiveAnnouncements()).resolves.toHaveLength(1);
    expect(requestRecord).toHaveBeenCalledWith('/app/announcements/active?target=ios&locale=en', {
      requiresAuth: false,
    });
    await expect(service.getActiveAnnouncements()).resolves.toEqual([]);
  });

  it('resolves an exact notification through the public announcement route', async () => {
    const requestRecord = jest.fn().mockResolvedValue({
      id: 'target',
      title: 'Target',
      subtitle: 'Notification',
    });
    const service = new AnnouncementService({ requestRecord } as never, 'android', () => 'fr_CA');

    await expect(service.getAnnouncement(' target ')).resolves.toMatchObject({ id: 'target' });
    expect(requestRecord).toHaveBeenCalledWith('/app/announcements/target?locale=fr', {
      requiresAuth: false,
    });
  });

  it('keeps exact notification lookup best-effort', async () => {
    const requestRecord = jest.fn().mockRejectedValue(new Error('missing'));
    const service = new AnnouncementService({ requestRecord } as never, 'web', () => 'en');

    await expect(service.getAnnouncement('missing')).resolves.toBeNull();
    expect(requestRecord).toHaveBeenCalledTimes(1);
  });
});
