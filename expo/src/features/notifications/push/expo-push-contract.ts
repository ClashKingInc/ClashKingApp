import type { PushAuthorizationStatus, PushMessage, PushPlatform } from './contracts';

export const LOCAL_NOTIFICATION_IDENTIFIER_PREFIX = 'clashking_foreground_';

export function mapPushAuthorizationStatus(input: {
  platform: PushPlatform;
  granted: boolean;
  permissionStatus: string;
  iosStatus?: number;
}): PushAuthorizationStatus {
  if (input.platform === 'ios') {
    switch (input.iosStatus) {
      case 1:
        return 'denied';
      case 2:
        return 'authorized';
      case 3:
        return 'provisional';
      case 4:
        return 'ephemeral';
      default:
        return 'notDetermined';
    }
  }
  if (input.granted) return 'authorized';
  return input.permissionStatus === 'denied' ? 'denied' : 'notDetermined';
}

export function isClashKingLocalNotification(identifier: string): boolean {
  return identifier.startsWith(LOCAL_NOTIFICATION_IDENTIFIER_PREFIX);
}

export function foregroundNotificationContent(message: PushMessage): {
  title: string;
  body: string;
  data: Record<string, unknown>;
} {
  const data = message.data ?? {};
  return {
    title: message.notification?.title ?? (data.title == null ? 'ClashKing' : String(data.title)),
    body:
      message.notification?.body ?? (data.body == null ? 'New ClashKing alert' : String(data.body)),
    data: { ...data },
  };
}
