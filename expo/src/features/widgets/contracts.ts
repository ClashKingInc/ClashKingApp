import type { StringStore } from '../../services/storage/auth-storage';

export type WidgetPlatform = 'ios' | 'android' | 'web';

export interface NativeWidgetBridge {
  setWidgetValue(key: string, value: string | null): Promise<void>;
  reloadWidgets(): Promise<void>;
  consumePendingWidgetAction(): Promise<string | null>;
  readLegacyWidgetValues(): Promise<Record<string, string>>;
  requestPinWarWidget(): Promise<WidgetPinRequestResult>;
}

export interface WidgetPinRequestResult {
  readonly supported: boolean;
  readonly requested: boolean;
}

export interface WidgetMigrationResult {
  readonly migratedKeys: readonly string[];
  readonly sourceValuesRetained: true;
}

export interface WidgetFeatureFlags {
  refresh(): Promise<void>;
  isEnabled(key: string, fallback?: boolean): boolean;
}

export interface WidgetBackgroundScheduler {
  registerPeriodicTask(taskName: string, minimumIntervalMinutes: number): Promise<void>;
}

export interface WarWidgetClanOption {
  readonly tag: string;
  readonly name: string;
  readonly badgeUrl?: string;
}

export interface WarWidgetPlayerProfile {
  readonly tag: string;
  readonly clanOverview: {
    readonly tag: string;
    readonly name: string;
    readonly badgeUrls: {
      readonly small?: string;
      readonly medium: string;
      readonly large?: string;
    };
  };
}

export interface WarWidgetBookmarkedClan {
  readonly tag: string;
  readonly name: string;
  readonly badgeUrl?: string;
}

export interface WidgetErrorContext {
  readonly operation:
    | 'widget.update'
    | 'widget.refresh'
    | 'widget.fetch_war_summary'
    | 'widget.background'
    | 'widget.action';
  readonly error: unknown;
}

export interface WarWidgetServiceOptions {
  readonly platform: WidgetPlatform;
  readonly native: NativeWidgetBridge;
  /** Expo-owned mirror for native widget values and one-time Flutter migration state. */
  readonly mirror: StringStore;
  readonly preferences: StringStore;
  readonly featureFlags: WidgetFeatureFlags;
  readonly backgroundScheduler?: WidgetBackgroundScheduler;
  readonly proxyUrl: string;
  readonly apiV2Url: string;
  readonly loadWarSummary: (clanTag: string) => Promise<unknown>;
  readonly getFirstAvailableAccount: () => Promise<string | null>;
  readonly loadPlayerClanTag: (playerTag: string) => Promise<string | null>;
  readonly now?: () => Date;
  readonly reportError?: (context: WidgetErrorContext) => void | Promise<void>;
  readonly log?: (message: string) => void;
}
