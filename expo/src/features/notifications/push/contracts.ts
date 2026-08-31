import type { ApiClient, ApiEnvironment } from '../../../core/api/client';
import type { TokenService } from '../../../services/auth/token-service';
import type { StringStore } from '../../../services/storage/auth-storage';

export type PushPlatform = 'ios' | 'android' | 'web';

export type PushAuthorizationStatus =
  'notDetermined' | 'denied' | 'authorized' | 'provisional' | 'ephemeral';

export type PushNotificationSetupState =
  | 'unsupported'
  | 'notConfigured'
  | 'initializing'
  | 'ready'
  | 'permissionRequired'
  | 'permissionDenied'
  | 'tokenUnavailable';

export interface PushNotificationSetupResult {
  readonly state: PushNotificationSetupState;
  readonly authorizationStatus?: PushAuthorizationStatus;
  readonly token?: string;
  readonly message?: string;
}

export type PushData = Readonly<Record<string, unknown>>;

export interface PushMessage {
  readonly messageId?: string;
  readonly data?: PushData;
  readonly notification?: {
    readonly title?: string;
    readonly body?: string;
  };
}

export type PushUnsubscribe = () => void;

/** Native effects used by the state machine; isolated so service tests never load native modules. */
export interface PushRuntime {
  initializeLocalNotifications(
    onResponse: (data: PushData) => void,
  ): Promise<PushUnsubscribe | void>;
  getAuthorizationStatus(): Promise<PushAuthorizationStatus>;
  requestAuthorization(): Promise<PushAuthorizationStatus>;
  getToken(): Promise<string | null>;
  deleteToken(): Promise<void>;
  showLocalNotification(message: PushMessage): Promise<void>;
  onForegroundMessage(listener: (message: PushMessage) => void): PushUnsubscribe;
  onNotificationOpened(listener: (message: PushMessage) => void): PushUnsubscribe;
  onTokenRefresh(listener: (token: string) => void): PushUnsubscribe;
  getInitialMessage(): Promise<PushMessage | null>;
  getInitialLocalResponse(): Promise<PushData | null>;
}

export type PushFeature = 'posts' | 'upgradeTracker';

export interface PushErrorContext {
  readonly operation:
    | 'initialize'
    | 'permission'
    | 'register'
    | 'unregister'
    | 'cleanup'
    | 'foreground-message'
    | 'navigation'
    | 'primer-callback';
  readonly error: unknown;
}

export interface PushNotificationServiceOptions {
  readonly platform: PushPlatform;
  readonly apiEnvironment: ApiEnvironment;
  readonly api: Pick<ApiClient, 'request'>;
  readonly preferences: StringStore;
  readonly tokenService: Pick<TokenService, 'getDeviceId'>;
  readonly runtime?: PushRuntime;
  readonly pushApiV2BaseUrlOverride?: string;
  readonly appVersion: () => string;
  readonly locale: () => string;
  readonly isFeatureEnabled: (feature: PushFeature) => boolean;
  readonly openRoute: (route: SupportedPushRoute) => void | Promise<void>;
  readonly openAdminPost: (postId: string) => void | Promise<void>;
  readonly showPermissionPrimer?: () => boolean | Promise<boolean>;
  readonly reportError?: (context: PushErrorContext) => void | Promise<void>;
  readonly log?: (message: string) => void;
}

export type SupportedPushRoute =
  '/support-creator' | '/settings/support' | '/posts' | '/search' | '/upgrade-tracker';
