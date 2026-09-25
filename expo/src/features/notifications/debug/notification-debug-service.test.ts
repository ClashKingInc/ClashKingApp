import contract from '../../../../native/parity-contract.json';
import { ImageAssets } from '../../../core/assets/image-assets';
import {
  NOTIFICATION_SETTINGS_SAMPLE,
  NotificationDebugService,
  createNotificationSettingsDebugAdapter,
  isNotificationDebugExposed,
  notificationSamplePayload,
  type NotificationDebugPayload,
} from './notification-debug-service';

function nativeBridge() {
  return {
    showDebugNotification: jest.fn(async (payload: NotificationDebugPayload) => ({
      scheduled: true as const,
      title: payload.title,
      attachmentCount: 1,
    })),
  };
}

describe('NotificationDebugService', () => {
  test('matches the exact Flutter settings sample and wire payload', () => {
    expect(NOTIFICATION_SETTINGS_SAMPLE).toEqual(contract.notificationDebug.sample);
    expect(notificationSamplePayload(NOTIFICATION_SETTINGS_SAMPLE)).toEqual({
      sampleId: 'notificationSettings',
      title: 'ClashKing notifications',
      body: 'Push notifications are configured for this device.',
      assetUrl: NOTIFICATION_SETTINGS_SAMPLE.assetUrl,
      assetUrls: [NOTIFICATION_SETTINGS_SAMPLE.assetUrl],
      threadIdentifier: 'ClashKing',
    });
  });

  test('delegates on iOS and preserves the scheduling result shape', async () => {
    const native = nativeBridge();
    const service = new NotificationDebugService('ios', native);
    await expect(service.showSample(NOTIFICATION_SETTINGS_SAMPLE)).resolves.toEqual({
      scheduled: true,
      title: 'ClashKing notifications',
      attachmentCount: 1,
    });
    expect(native.showDebugNotification).toHaveBeenCalledWith(
      notificationSamplePayload(NOTIFICATION_SETTINGS_SAMPLE),
    );
  });

  test('keeps debug exposure iOS-only and rejects unsupported calls', async () => {
    expect(isNotificationDebugExposed('ios', true)).toBe(true);
    expect(isNotificationDebugExposed('ios', false)).toBe(false);
    expect(isNotificationDebugExposed('android', true)).toBe(false);
    const native = nativeBridge();
    await expect(
      new NotificationDebugService('android', native).showSample(NOTIFICATION_SETTINGS_SAMPLE),
    ).rejects.toMatchObject({ code: 'unsupported' });
    expect(native.showDebugNotification).not.toHaveBeenCalled();
  });

  test('builds the precise optional settings adapter only for debug iOS', async () => {
    const native = nativeBridge();
    const service = new NotificationDebugService('ios', native);
    const adapter = createNotificationSettingsDebugAdapter(service, true);
    await expect(adapter?.service.sendTestNotification('legend-defense')).resolves.toBe('Legend defense');
    expect(adapter?.debugEnabled).toBe(true);
    expect(createNotificationSettingsDebugAdapter(service, false)).toBeNull();
    expect(
      createNotificationSettingsDebugAdapter(new NotificationDebugService('web', native), true),
    ).toBeNull();
  });

  test('offers only current supported types and sends their representative artwork', async () => {
    const native = nativeBridge();
    const adapter = createNotificationSettingsDebugAdapter(new NotificationDebugService('ios', native), true)!;
    expect(adapter.testNotificationTypes).toEqual([
      { id: 'legend-defense', labelKey: 'notifGroupLegendDefenses' },
      { id: 'event-cwl', labelKey: 'cwlClanWarLeague' },
      { id: 'event-clan-games', labelKey: 'gameClanGames' },
      { id: 'event-raid-weekend', labelKey: 'todoEventRaidWeekend' },
      { id: 'event-season', labelKey: 'notifNewSeasonStarted' },
      { id: 'announcement', labelKey: 'notifGroupAppAnnouncements' },
      { id: 'admin-post', labelKey: 'postsTitle' },
      { id: 'war-reminder', labelKey: 'notifGroupWarReminders' },
      { id: 'raid-reminder', labelKey: 'notifGroupRaidReminders' },
      { id: 'monthly-support', labelKey: 'notifGroupMonthlySupport' },
    ]);
    const expectedAssets: Record<string, string> = {
      'legend-defense': ImageAssets.legendBlazon,
      'event-cwl': ImageAssets.cwlSwordsNoBorder,
      'event-clan-games': ImageAssets.clanGamesMedals,
      'event-raid-weekend': ImageAssets.raidAttacks,
      'event-season': ImageAssets.iconGoldPass,
      announcement: ImageAssets.darkModeLogo,
      'admin-post': ImageAssets.darkModeLogo,
      'war-reminder': ImageAssets.attacks,
      'raid-reminder': ImageAssets.raidAttacks,
      'monthly-support': ImageAssets.iconGoldPass,
    };
    for (const { id } of adapter.testNotificationTypes) {
      await expect(adapter.service.sendTestNotification(id)).resolves.toEqual(expect.any(String));
      expect(native.showDebugNotification).toHaveBeenLastCalledWith(
        expect.objectContaining({
          sampleId: id,
          assetUrl: expectedAssets[id],
          assetUrls: [expectedAssets[id]],
          title: expect.any(String),
          body: expect.any(String),
        }),
      );
    }
    const sent = native.showDebugNotification.mock.calls.map(([payload]) => payload);
    expect(sent.find(({ sampleId }) => sampleId === 'war-reminder')).toMatchObject({
      title: 'War attacks remaining',
      body: '5 hours remaining & 1 attack left in war!',
      threadIdentifier: 'War reminders',
    });
    expect(sent.find(({ sampleId }) => sampleId === 'raid-reminder')).toMatchObject({
      title: 'Raid attacks remaining',
      body: '5 hours remaining & 2 attacks left in Raid Weekend!',
      threadIdentifier: 'Raid reminders',
    });
    const offeredIds = adapter.testNotificationTypes.map(({ id }) => id);
    for (const retiredId of ['war-start', 'war-score', 'cwl-attack', 'war-state', 'cwl-state']) {
      expect(offeredIds).not.toContain(retiredId);
    }
  });

  test('rejects unknown sample ids without touching the native bridge', async () => {
    const native = nativeBridge();
    const adapter = createNotificationSettingsDebugAdapter(new NotificationDebugService('ios', native), true)!;
    await expect(adapter.service.sendTestNotification('war-score')).rejects.toMatchObject({
      code: 'invalid_sample',
    });
    expect(native.showDebugNotification).not.toHaveBeenCalled();
  });
});
