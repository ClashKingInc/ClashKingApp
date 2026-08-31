export type LegacyMigrationCapabilities = {
  platform: 'ios' | 'android';
  secureStorageReadable: boolean;
  sharedPreferencesReadable: boolean;
  destructiveReads: false;
  note: string;
};

export type WidgetPinRequestResult = {
  supported: boolean;
  requested: boolean;
};

export type NotificationDebugPayload = {
  sampleId: string;
  title: string;
  body: string;
  assetUrl: string;
  assetUrls: string[];
  threadIdentifier: string;
};

export type NotificationDebugResult = {
  scheduled: true;
  title: string;
  attachmentCount: number;
};

export type SaveFileOptions = {
  fileUri: string;
  fileName: string;
  mimeType: string;
};

export type SceneryAudioNativeStatus = {
  positionMilliseconds: number;
  durationMilliseconds: number;
  playing: boolean;
  loaded: boolean;
  buffering: boolean;
  didJustFinish: boolean;
};

export type ClashKingNativeModule = {
  addListener(
    event: 'onSceneryAudioStatus',
    listener: (status: SceneryAudioNativeStatus) => void,
  ): { remove(): void };
  prepareSceneryAudio(source: string): Promise<void>;
  playSceneryAudio(): Promise<void>;
  pauseSceneryAudio(): Promise<void>;
  seekSceneryAudio(positionMilliseconds: number): Promise<void>;
  releaseSceneryAudio(): Promise<void>;
  acquireSharedAuthRefreshLock(timeoutSeconds?: number): Promise<boolean>;
  releaseSharedAuthRefreshLock(): Promise<void>;
  supportsAlternateIcons(): Promise<boolean>;
  getAlternateIconName(): Promise<string | null>;
  setAlternateIconName(iconName: string | null): Promise<void>;
  showDebugNotification(payload: NotificationDebugPayload): Promise<NotificationDebugResult>;
  saveFile(options: SaveFileOptions): Promise<string>;
  setWidgetValue(key: string, value: string | null): Promise<void>;
  reloadWidgets(): Promise<void>;
  consumePendingWidgetAction(): Promise<string | null>;
  readLegacyWidgetValues(): Promise<Record<string, string>>;
  requestPinWarWidget(): Promise<WidgetPinRequestResult>;
  readSharedAuthSession(): Promise<string | null>;
  writeSharedAuthSession(encodedSession: string): Promise<void>;
  clearSharedAuthSession(): Promise<void>;
  getLegacyMigrationCapabilities(): LegacyMigrationCapabilities;
  readLegacyFlutterSecureValue(key: string, sharedAccessGroup?: boolean): Promise<string | null>;
  readAllLegacyFlutterSecureValues(sharedAccessGroup?: boolean): Promise<Record<string, string>>;
  readLegacyFlutterPreferences(
    keys: string[],
  ): Promise<Record<string, string | number | boolean | null>>;
  readAllLegacyFlutterPreferences(): Promise<Record<string, string | number | boolean | null>>;
};
