import type { PushRuntime } from '../../features/notifications/push/contracts';

export function createPlatformPushRuntime(): PushRuntime | undefined {
  return undefined;
}

export function registerPlatformPushBackgroundHandler(): void {
  // Flutter web does not register a Firebase background-message handler.
}
