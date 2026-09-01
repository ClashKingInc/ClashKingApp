import type { NotificationPreferences } from '../../../core/dto/notification-preferences';
import type { AuthUser } from '../../auth/models';
import type { PushNotificationSetupResult } from '../../notifications/push/contracts';

export type SettingsThemeMode = 'system' | 'light' | 'dark';
export type SettingsDestination = 'notifications' | 'faq' | 'translation' | 'privacy';

export interface SettingsPresentationActions {
  changeLocale(locale: string): Promise<void>;
  changeTheme(mode: SettingsThemeMode): Promise<void>;
  changeAppIcon?(iconName: string | null): Promise<void>;
  open(destination: SettingsDestination): void;
  openDiscord(): void;
  showLicenses(): void;
  copyVersion(value: string): void;
  logout(): Promise<void>;
}

export type SettingsUser = Pick<AuthUser, 'username' | 'email' | 'avatarUrl'>;

export interface NotificationSettingsPresentationService {
  loadLocal(): Promise<NotificationPreferences>;
  load(): Promise<NotificationPreferences>;
  save(settings: NotificationPreferences): Promise<NotificationPreferences>;
  lastPushResult(): PushNotificationSetupResult | null;
  initializePush(): Promise<PushNotificationSetupResult>;
  requestPermissionAndRegister(): Promise<PushNotificationSetupResult>;
  tokenPreview(): Promise<string | null>;
  sendTestNotification?(): Promise<string>;
}

export interface PrivacyPresentationActions {
  requestExport(): Promise<Record<string, unknown>>;
  saveExport(fileName: string, data: string): Promise<void>;
  deleteAccount(): Promise<void>;
  openPrivacyPolicy(): void;
  contactSupport(): void;
  onDeleted(): void;
}

export interface ExternalSettingsActions {
  openCrowdin(): void;
  openDiscord(): void;
  openGitHub(): void;
  inviteBot(): void;
  openFanContentPolicy(): void;
  openPatreon(): void;
  useCreatorCode(): void;
  sendEmail(): boolean | void | Promise<boolean | void>;
  copySupportEmail(): Promise<void>;
  openPrivacy(): void;
}
