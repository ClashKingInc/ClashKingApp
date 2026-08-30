import {
  ExpoPushRuntime,
  registerPushNotificationBackgroundHandler,
  type PushRuntime,
} from '../../features/notifications/push';

export function createPlatformPushRuntime(): PushRuntime {
  return new ExpoPushRuntime();
}

export function registerPlatformPushBackgroundHandler(
  reportError?: (error: unknown) => void | Promise<void>,
): void {
  registerPushNotificationBackgroundHandler({ reportError });
}
