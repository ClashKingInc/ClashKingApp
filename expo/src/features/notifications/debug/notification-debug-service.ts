import { ImageAssets } from '../../../core/assets/image-assets';
import type { MessageKey } from '../../../i18n';

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
  readonly testNotificationTypes: readonly { readonly id: string; readonly labelKey: MessageKey }[];
  readonly service: {
    sendTestNotification(sampleId: string): Promise<string>;
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

const NOTIFICATION_TEST_SAMPLES = [
  {
    id: 'legend-defense', labelKey: 'notifGroupLegendDefenses', label: 'Legend defense',
    group: 'Legend League', title: 'Legend defense',
    body: 'Archer Queen attacked Barbarian King: 2 stars, 86%.',
    assetUrl: ImageAssets.legendBlazon,
  },
  {
    id: 'event-cwl', labelKey: 'cwlClanWarLeague', label: 'CWL started',
    group: 'Events', title: 'Clan War League has started',
    body: 'Clan War League is now live in game.', assetUrl: ImageAssets.cwlSwordsNoBorder,
  },
  {
    id: 'event-clan-games', labelKey: 'gameClanGames', label: 'Clan Games started',
    group: 'Events', title: 'Clan Games have started',
    body: 'Clan Games are now live in game.', assetUrl: ImageAssets.clanGamesMedals,
  },
  {
    id: 'event-raid-weekend', labelKey: 'todoEventRaidWeekend', label: 'Raid Weekend started',
    group: 'Events', title: 'Raid Weekend has started',
    body: 'Raid Weekend is now live in game.', assetUrl: ImageAssets.raidAttacks,
  },
  {
    id: 'event-season', labelKey: 'notifNewSeasonStarted', label: 'Season started',
    group: 'Events', title: 'A new season has started',
    body: 'The new Clash of Clans season is now live.', assetUrl: ImageAssets.iconGoldPass,
  },
  {
    id: 'announcement', labelKey: 'notifGroupAppAnnouncements', label: 'App announcement',
    group: 'Announcements', title: 'ClashKing announcement',
    body: 'This is a test app announcement.', assetUrl: ImageAssets.darkModeLogo,
  },
  {
    id: 'admin-post', labelKey: 'postsTitle', label: 'Published post',
    group: 'Announcements', title: 'New from ClashKing',
    body: 'Open this notification to read the post.', assetUrl: ImageAssets.darkModeLogo,
  },
  {
    id: 'war-reminder', labelKey: 'notifGroupWarReminders', label: 'War attacks remaining',
    group: 'War reminders', title: 'War attacks remaining',
    body: '5 hours remaining & 1 attack left in war!', assetUrl: ImageAssets.attacks,
  },
  {
    id: 'raid-reminder', labelKey: 'notifGroupRaidReminders', label: 'Raid attacks remaining',
    group: 'Raid reminders', title: 'Raid attacks remaining',
    body: '5 hours remaining & 2 attacks left in Raid Weekend!', assetUrl: ImageAssets.raidAttacks,
  },
  {
    id: 'monthly-support', labelKey: 'notifGroupMonthlySupport', label: 'Creator support reminder',
    group: 'Monthly support', title: 'New Season is Live',
    body: "A new season has started. If you're getting the Gold Pass, consider using creator code ClashKing.",
    assetUrl: ImageAssets.iconGoldPass,
  },
] as const satisfies readonly (NotificationSample & { readonly labelKey: MessageKey })[];

export class InvalidNotificationSampleError extends Error {
  readonly code = 'invalid_sample';

  constructor(sampleId: string) {
    super(`Unknown notification debug sample: ${sampleId}`);
    this.name = 'InvalidNotificationSampleError';
  }
}

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
    testNotificationTypes: NOTIFICATION_TEST_SAMPLES.map(({ id, labelKey }) => ({ id, labelKey })),
    service: {
      async sendTestNotification(sampleId) {
        const sample = NOTIFICATION_TEST_SAMPLES.find((candidate) => candidate.id === sampleId);
        if (!sample) throw new InvalidNotificationSampleError(sampleId);
        const result = await service.showSample(sample);
        return result.title ?? sample.title;
      },
    },
  };
}
