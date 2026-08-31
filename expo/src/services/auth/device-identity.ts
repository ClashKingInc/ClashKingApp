import * as Application from 'expo-application';
import * as Crypto from 'expo-crypto';
import * as Device from 'expo-device';
import { Platform } from 'react-native';

import { STORAGE_KEYS } from '../../core/storage/storage';
import type { LegacyFlutterStorageBridge, StringStore } from '../storage/auth-storage';
import type { DeviceIdentity } from './token-service';

export class ExpoDeviceIdentity implements DeviceIdentity {
  private deviceId: Promise<string> | null = null;
  private deviceName: Promise<string> | null = null;

  constructor(
    private readonly secureStore: StringStore,
    private readonly legacyBridge?: Pick<LegacyFlutterStorageBridge, 'readSecureValue'>,
  ) {}

  getDeviceId(): Promise<string> {
    this.deviceId ??= this.loadDeviceId();
    return this.deviceId;
  }

  getDeviceName(): Promise<string> {
    this.deviceName ??= this.loadDeviceName();
    return this.deviceName;
  }

  private async loadDeviceId(): Promise<string> {
    try {
      if (Platform.OS === 'web') {
        return globalThis.navigator?.userAgent ?? 'unknown-web-device';
      }
      // Flutter's device_info_plus AndroidInfo.id is android.os.Build.ID.
      // Keep using that value so an Expo upgrade can refresh the Flutter
      // session and unregister the same push-device record.
      if (Platform.OS === 'android') return flutterCompatibleAndroidDeviceId(Device.osBuildId);
      if (Platform.OS === 'ios') {
        const vendorId = await Application.getIosIdForVendorAsync();
        if (vendorId !== null) return vendorId;
        return this.loadIosFallbackId();
      }
      return 'unsupported-platform';
    } catch {
      return 'unknown-device';
    }
  }

  private async loadIosFallbackId(): Promise<string> {
    return loadMigratedIosFallbackId(this.secureStore, this.legacyBridge, () =>
      Crypto.randomUUID(),
    );
  }

  private async loadDeviceName(): Promise<string> {
    try {
      if (Platform.OS === 'web') return browserName();
      if (Platform.OS === 'android') {
        return Device.modelName ?? 'unknown-device';
      }
      if (Platform.OS === 'ios') {
        return Device.deviceName ?? 'unknown-device';
      }
      return 'unsupported-platform';
    } catch {
      return 'unknown-device';
    }
  }
}

export function flutterCompatibleAndroidDeviceId(osBuildId: string | null): string {
  return osBuildId ?? 'unknown-device';
}

export async function loadMigratedIosFallbackId(
  secureStore: StringStore,
  legacyBridge: Pick<LegacyFlutterStorageBridge, 'readSecureValue'> | undefined,
  generate: () => string,
): Promise<string> {
  const existing = await secureStore.getItem(STORAGE_KEYS.deviceIdFallback);
  if (existing !== null) return existing;
  const legacy = await legacyBridge?.readSecureValue(STORAGE_KEYS.deviceIdFallback, false);
  const resolved = legacy ?? generate();
  await secureStore.setItem(STORAGE_KEYS.deviceIdFallback, resolved);
  return resolved;
}

function browserName(): string {
  const userAgent = globalThis.navigator?.userAgent.toLowerCase() ?? '';
  if (userAgent.includes('firefox')) return 'firefox';
  if (userAgent.includes('edg/')) return 'edge';
  if (userAgent.includes('chrome')) return 'chrome';
  if (userAgent.includes('safari')) return 'safari';
  return 'unknown-browser';
}
