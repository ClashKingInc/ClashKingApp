import {
  deleteToken,
  getInitialNotification,
  getMessaging,
  getAPNSToken,
  setAPNSToken,
  getToken,
  onMessage,
  onNotificationOpenedApp,
  onTokenRefresh,
  setBackgroundMessageHandler,
} from '@react-native-firebase/messaging';
import * as Notifications from 'expo-notifications';
import { AndroidImportance } from 'expo-notifications';
import { File, Paths } from 'expo-file-system';
import { Platform } from 'react-native';
import type {
  PushAuthorizationStatus,
  PushData,
  PushMessage,
  PushRuntime,
  PushUnsubscribe,
} from './contracts';
import {
  foregroundNotificationContent,
  isClashKingLocalNotification,
  LOCAL_NOTIFICATION_IDENTIFIER_PREFIX,
  mapPushAuthorizationStatus,
} from './expo-push-contract';

export const PUSH_NOTIFICATION_CHANNEL = {
  id: 'clashking_push',
  name: 'ClashKing alerts',
  description: 'War, CWL, account, and ClashKing announcement alerts.',
} as const;

function authorizationStatus(
  permissions: Notifications.NotificationPermissionsStatus,
): PushAuthorizationStatus {
  return mapPushAuthorizationStatus({
    platform: Platform.OS === 'ios' || Platform.OS === 'android' ? Platform.OS : 'web',
    granted: permissions.granted,
    permissionStatus: permissions.status,
    iosStatus: permissions.ios?.status,
  });
}

type FirebaseRemoteMessage = NonNullable<Awaited<ReturnType<typeof getInitialNotification>>>;

function messageFromFirebase(message: FirebaseRemoteMessage): PushMessage {
  return {
    messageId: message.messageId,
    data: message.data,
    notification: message.notification
      ? {
          title: message.notification.title,
          body: message.notification.body,
        }
      : undefined,
  };
}

function notificationData(response: Notifications.NotificationResponse | null): PushData | null {
  if (!response || !isClashKingLocalNotification(response.notification.request.identifier)) {
    return null;
  }
  return response.notification.request.content.data ?? null;
}

export class ExpoPushRuntime implements PushRuntime {
  private responseSubscription: Notifications.EventSubscription | null = null;
  private localNotificationSequence = 0;
  private tokenRequest: Promise<string | null> | null = null;

  async initializeLocalNotifications(
    onResponse: (data: PushData) => void,
  ): Promise<PushUnsubscribe> {
    Notifications.setNotificationHandler({
      handleNotification: async () => ({
        shouldShowBanner: true,
        shouldShowList: true,
        shouldPlaySound: true,
        shouldSetBadge: true,
      }),
    });
    if (Platform.OS === 'android') {
      await Notifications.setNotificationChannelAsync(PUSH_NOTIFICATION_CHANNEL.id, {
        name: PUSH_NOTIFICATION_CHANNEL.name,
        description: PUSH_NOTIFICATION_CHANNEL.description,
        importance: AndroidImportance.HIGH,
      });
    }
    this.responseSubscription?.remove();
    this.responseSubscription = Notifications.addNotificationResponseReceivedListener(
      (response) => {
        const data = notificationData(response);
        if (data !== null) onResponse(data);
      },
    );
    return () => {
      this.responseSubscription?.remove();
      this.responseSubscription = null;
    };
  }

  async getAuthorizationStatus(): Promise<PushAuthorizationStatus> {
    return authorizationStatus(await Notifications.getPermissionsAsync());
  }

  async requestAuthorization(): Promise<PushAuthorizationStatus> {
    const permissions = await Notifications.requestPermissionsAsync({
      ios: {
        allowAlert: true,
        allowBadge: true,
        allowSound: true,
        allowDisplayInCarPlay: false,
        allowCriticalAlerts: false,
        allowProvisional: false,
      },
    });
    return authorizationStatus(permissions);
  }

  getToken(): Promise<string | null> {
    // Startup and the Enable action can overlap. Expo replaces an outstanding
    // native token promise when called again, so both callers share one attempt.
    if (this.tokenRequest !== null) return this.tokenRequest;
    const request = this.requestToken();
    this.tokenRequest = request;
    void request.finally(() => {
      if (this.tokenRequest === request) this.tokenRequest = null;
    }).catch(() => undefined);
    return request;
  }

  private async requestToken(): Promise<string | null> {
    const messaging = getMessaging();
    let apnsToken: string | null = null;
    if (Platform.OS === 'ios') {
      try {
        apnsToken = await getAPNSToken(messaging);
      } catch (error) {
        // Firebase rejects this read before iOS registration, rather than
        // returning null. Continue to Expo's registration in that one case.
        if ((error as { code?: string }).code !== 'messaging/unregistered') throw error;
      }
    }
    if (Platform.OS === 'ios' && apnsToken === null) {
      // Expo owns notification permission/registration. Its delegate may receive
      // APNs before Firebase does, so explicitly pass the native token to FCM.
      // Never request an FCM token until APNs is ready; a timeout is retryable.
      let timeout: ReturnType<typeof setTimeout> | undefined;
      try {
        const token = await Promise.race([
          Notifications.getDevicePushTokenAsync(),
          new Promise<null>((resolve) => {
            timeout = setTimeout(() => resolve(null), 10_000);
          }),
        ]);
        if (token === null) return null;
        if (token.type !== 'ios' || typeof token.data !== 'string') return null;
        await setAPNSToken(messaging, token.data);
      } finally {
        if (timeout !== undefined) clearTimeout(timeout);
      }
    }
    return getToken(messaging);
  }

  deleteToken(): Promise<void> {
    return deleteToken(getMessaging());
  }

  async showLocalNotification(message: PushMessage): Promise<void> {
    const content = foregroundNotificationContent(message);
    // iOS local notifications require an on-disk attachment; remote pushes use
    // NotificationService instead. Never let an image failure swallow the alert.
    const attachment = content.attachments?.[0];
    if (Platform.OS === 'ios' && attachment) {
      try {
        const file = await File.downloadFileAsync(
          attachment.url,
          new File(Paths.cache, `push-${Date.now()}-${this.localNotificationSequence}.png`),
        );
        const native = (await import('@clashking/native')).default;
        attachment.url = await native.padNotificationThumbnail(file.uri);
      } catch {
        delete content.attachments;
      }
    } else {
      delete content.attachments;
    }
    await Notifications.scheduleNotificationAsync({
      identifier: `${LOCAL_NOTIFICATION_IDENTIFIER_PREFIX}${Date.now()}_${this.localNotificationSequence++}`,
      content: {
        ...content,
        sound: 'default',
      },
      trigger: Platform.OS === 'android' ? { channelId: PUSH_NOTIFICATION_CHANNEL.id } : null,
    });
  }

  onForegroundMessage(listener: (message: PushMessage) => void): PushUnsubscribe {
    return onMessage(getMessaging(), (message) => listener(messageFromFirebase(message)));
  }

  onNotificationOpened(listener: (message: PushMessage) => void): PushUnsubscribe {
    return onNotificationOpenedApp(getMessaging(), (message) =>
      listener(messageFromFirebase(message)),
    );
  }

  onTokenRefresh(listener: (token: string) => void): PushUnsubscribe {
    return onTokenRefresh(getMessaging(), listener);
  }

  async getInitialMessage(): Promise<PushMessage | null> {
    const message = await getInitialNotification(getMessaging());
    return message === null ? null : messageFromFirebase(message);
  }

  async getInitialLocalResponse(): Promise<PushData | null> {
    const response = await Notifications.getLastNotificationResponseAsync();
    const data = notificationData(response);
    if (data === null) return null;
    await Notifications.clearLastNotificationResponseAsync();
    return data;
  }
}

export interface BackgroundPushHandlerOptions {
  readonly onMessage?: (message: PushMessage) => void | Promise<void>;
  readonly reportError?: (error: unknown) => void | Promise<void>;
}

/** Call once at module scope in the native entry point, before React mounts. */
export function registerPushNotificationBackgroundHandler(
  options: BackgroundPushHandlerOptions = {},
): void {
  if (Platform.OS !== 'ios' && Platform.OS !== 'android') return;
  setBackgroundMessageHandler(getMessaging(), async (message) => {
    try {
      await options.onMessage?.(messageFromFirebase(message));
    } catch (error) {
      try {
        await options.reportError?.(error);
      } catch {
        // Background error reporting must not reject the native handler.
      }
    }
  });
}
