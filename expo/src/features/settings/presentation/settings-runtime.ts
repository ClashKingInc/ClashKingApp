import * as Application from 'expo-application';
import Constants from 'expo-constants';
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
    version: Application.nativeApplicationVersion ?? Constants.expoConfig?.version ?? '0.3.5',
    buildNumber:
      Application.nativeBuildVersion ??
      String(
        Constants.expoConfig?.ios?.buildNumber ?? Constants.expoConfig?.android?.versionCode ?? '',
      ),
    modelName: Device.modelName,
    modelId: typeof Device.modelId === 'string' ? Device.modelId : null,
    osVersion: Device.osVersion,
    platformApiLevel: Device.platformApiLevel,
  });
}
