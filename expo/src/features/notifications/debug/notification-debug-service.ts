import { ImageAssets } from '../../../core/assets/image-assets';

export type NotificationDebugPlatform = 'ios' | 'android' | 'web';

export interface NotificationSample {
  readonly id: string;
  readonly label: string;
  readonly group: string;
  readonly title: string;
  readonly body: string;
  readonly assetUrl: string;
}

export interface NotificationDebugPayload {
  readonly sampleId: string;
  readonly title: string;
  readonly body: string;
  readonly assetUrl: string;
  readonly assetUrls: readonly string[];
  readonly threadIdentifier: string;
}

export interface NotificationDebugResult {
  readonly scheduled: true;
  readonly title: string;
  readonly attachmentCount: number;
}

export interface NativeNotificationDebugBridge {
  showDebugNotification(payload: NotificationDebugPayload): Promise<NotificationDebugResult>;
}

export interface NotificationSettingsDebugAdapter {
  readonly debugEnabled: true;
  readonly service: {
    sendTestNotification(): Promise<string>;
  };
}

export const NOTIFICATION_SETTINGS_SAMPLE: NotificationSample = {
  id: 'notificationSettings',
  label: 'Notification settings',
  group: 'ClashKing',
  title: 'ClashKing notifications',
  body: 'Push notifications are configured for this device.',
  assetUrl: ImageAssets.darkModeLogo,
};

export class UnsupportedNotificationDebugPlatformError extends Error {
  readonly code = 'unsupported';

  constructor() {
    super('Notification debug samples are only supported on iOS.');
    this.name = 'UnsupportedNotificationDebugPlatformError';
  }
}

export function notificationSamplePayload(sample: NotificationSample): NotificationDebugPayload {
  return {
    sampleId: sample.id,
    title: sample.title,
    body: sample.body,
    assetUrl: sample.assetUrl,
    assetUrls: [sample.assetUrl],
    threadIdentifier: sample.group,
  };
}

export function isNotificationDebugExposed(
  platform: NotificationDebugPlatform,
  debugBuild: boolean,
): boolean {
  return debugBuild && platform === 'ios';
}

export class NotificationDebugService {
  constructor(
    private readonly platform: NotificationDebugPlatform,
    private readonly native: NativeNotificationDebugBridge | undefined,
  ) {}

  get isSupportedPlatform(): boolean {
    return this.platform === 'ios';
  }

  async showSample(sample: NotificationSample): Promise<NotificationDebugResult> {
    if (!this.isSupportedPlatform) throw new UnsupportedNotificationDebugPlatformError();
    if (this.native === undefined) {
      throw new Error('ClashKing native notification-debug bridge is unavailable.');
    }
    return this.native.showDebugNotification(notificationSamplePayload(sample));
  }
}

export function createNotificationSettingsDebugAdapter(
  service: NotificationDebugService,
  debugBuild: boolean,
): NotificationSettingsDebugAdapter | null {
  if (!debugBuild || !service.isSupportedPlatform) return null;
  return {
    debugEnabled: true,
    service: {
      async sendTestNotification() {
        const result = await service.showSample(NOTIFICATION_SETTINGS_SAMPLE);
        return result.title ?? NOTIFICATION_SETTINGS_SAMPLE.title;
      },
    },
  };
}
