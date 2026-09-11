import * as Application from 'expo-application';
import Constants from 'expo-constants';
import * as Updates from 'expo-updates';
import * as Device from 'expo-device';
import { Platform } from 'react-native';

export interface VersionDeviceDetails {
  readonly platform: string;
  readonly version: string;
  readonly buildNumber: string;
  readonly modelName?: string | null;
  readonly modelId?: string | null;
  readonly osVersion?: string | null;
  readonly platformApiLevel?: number | null;
}

export function versionDeviceLabel(details: VersionDeviceDetails): string {
  let deviceData = 'Unknown Platform';
  if (details.platform === 'android') {
    deviceData = `Device: ${details.modelName ?? 'Unknown'}, OS: Android ${details.osVersion ?? 'Unknown'} (SDK ${details.platformApiLevel ?? 'Unknown'})`;
  } else if (details.platform === 'ios') {
    deviceData = `Device: ${details.modelId ?? details.modelName ?? 'Unknown'}, OS: iOS ${details.osVersion ?? 'Unknown'}`;
  }
  return `Version: ${details.version} (Build ${details.buildNumber})\n${deviceData}`;
}

export async function getVersionDeviceLabel(): Promise<string> {
  return versionDeviceLabel({
    platform: Platform.OS,
    ...runningAppVersion({
      platform: Platform.OS,
      nativeVersion: Application.nativeApplicationVersion,
      nativeBuild: Application.nativeBuildVersion,
      config: Constants.expoConfig,
      isDevelopment: __DEV__,
      isEmbeddedLaunch: !Updates.isEnabled || Updates.isEmbeddedLaunch,
      manifest: Updates.manifest,
    }),
    modelName: Device.modelName,
    modelId: typeof Device.modelId === 'string' ? Device.modelId : null,
    osVersion: Device.osVersion,
    platformApiLevel: Device.platformApiLevel,
  });
}

export function runningAppVersion(details: {
  platform: string;
  nativeVersion?: string | null;
  nativeBuild?: string | null;
  config?: {
    version?: string;
    ios?: { buildNumber?: string };
    android?: { versionCode?: number };
    extra?: Record<string, unknown>;
  } | null;
  isDevelopment?: boolean;
  isEmbeddedLaunch?: boolean;
  manifest?: unknown;
}): { version: string; buildNumber: string } {
  const config = details.config;
  const configuredBuild =
    details.platform === 'android'
      ? config?.android?.versionCode?.toString()
      : config?.ios?.buildNumber;
  if (details.isDevelopment) {
    return {
      version: config?.version || details.nativeVersion || 'unknown',
      buildNumber: configuredBuild || details.nativeBuild || 'unknown',
    };
  }
  if (details.isEmbeddedLaunch === false) {
    const metadata = (details.manifest as { metadata?: { version?: unknown } } | undefined)
      ?.metadata;
    return {
      version:
        (typeof metadata?.version === 'string' && metadata.version) ||
        config?.version ||
        details.nativeVersion ||
        'unknown',
      buildNumber: configuredBuild || details.nativeBuild || 'unknown',
    };
  }
  return {
    version: details.nativeVersion || config?.version || 'unknown',
    buildNumber: details.nativeBuild || configuredBuild || 'unknown',
  };
}
