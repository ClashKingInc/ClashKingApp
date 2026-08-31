import contract from '../../../../native/parity-contract.json';
import {
  NOTIFICATION_SETTINGS_SAMPLE,
  NotificationDebugService,
  createNotificationSettingsDebugAdapter,
  isNotificationDebugExposed,
  notificationSamplePayload,
} from './notification-debug-service';

function nativeBridge() {
  return {
    showDebugNotification: jest.fn(async () => ({
      scheduled: true as const,
      title: 'ClashKing notifications',
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
    await expect(adapter?.service.sendTestNotification()).resolves.toBe('ClashKing notifications');
    expect(adapter?.debugEnabled).toBe(true);
    expect(createNotificationSettingsDebugAdapter(service, false)).toBeNull();
    expect(
      createNotificationSettingsDebugAdapter(new NotificationDebugService('web', native), true),
    ).toBeNull();
  });
});
