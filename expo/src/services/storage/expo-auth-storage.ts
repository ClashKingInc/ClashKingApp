import AsyncStorage from '@react-native-async-storage/async-storage';
import ClashKingNative from '@clashking/native';
import * as SecureStore from 'expo-secure-store';
import { Platform } from 'react-native';

import { SECURE_STORAGE_KEYS } from '../../core/storage/storage';
import type {
  LegacyFlutterStorageBridge,
  LegacyMigrationCapabilities,
  RuntimePlatform,
  StringStore,
} from './auth-storage';

export const SHARED_AUTH_KEYCHAIN_ACCESS_GROUP = 'MZYXD43RX5.group.com.clashking.apps';
export const SHARED_AUTH_KEYCHAIN_SERVICE = 'flutter_secure_storage_service';

const secureStoreOptions: SecureStore.SecureStoreOptions = {
  accessGroup: SHARED_AUTH_KEYCHAIN_ACCESS_GROUP,
  keychainService: SHARED_AUTH_KEYCHAIN_SERVICE,
  keychainAccessible: SecureStore.AFTER_FIRST_UNLOCK_THIS_DEVICE_ONLY,
};

export class ExpoSharedAuthSecureStore implements StringStore {
  getItem(key: string): Promise<string | null> {
    if (key === SECURE_STORAGE_KEYS.sharedAuthSession && Platform.OS !== 'web') {
      return ClashKingNative.readSharedAuthSession();
    }
    return SecureStore.getItemAsync(key, secureStoreOptions);
  }

  async setItem(key: string, value: string): Promise<void> {
    if (key === SECURE_STORAGE_KEYS.sharedAuthSession && Platform.OS !== 'web') {
      await ClashKingNative.writeSharedAuthSession(value);
      return;
    }
    await SecureStore.setItemAsync(key, value, secureStoreOptions);
  }

  async removeItem(key: string): Promise<void> {
    if (key === SECURE_STORAGE_KEYS.sharedAuthSession && Platform.OS !== 'web') {
      await ClashKingNative.clearSharedAuthSession();
      return;
    }
    await SecureStore.deleteItemAsync(key, secureStoreOptions);
  }
}

export class ExpoPreferenceStore implements StringStore {
  getItem(key: string): Promise<string | null> {
    return AsyncStorage.getItem(key);
  }

  getString(key: string): Promise<string | null> {
    return this.getItem(key);
  }

  async setItem(key: string, value: string): Promise<void> {
    await AsyncStorage.setItem(key, value);
  }

  setString(key: string, value: string): Promise<void> {
    return this.setItem(key, value);
  }

  async removeItem(key: string): Promise<void> {
    await AsyncStorage.removeItem(key);
  }

  remove(key: string): Promise<void> {
    return this.removeItem(key);
  }

  async clear(): Promise<void> {
    await AsyncStorage.clear();
  }
}

export class ClashKingLegacyFlutterBridge implements LegacyFlutterStorageBridge {
  getCapabilities(): LegacyMigrationCapabilities {
    return ClashKingNative.getLegacyMigrationCapabilities();
  }

  readSecureValue(key: string, sharedAccessGroup = false): Promise<string | null> {
    return ClashKingNative.readLegacyFlutterSecureValue(key, sharedAccessGroup);
  }

  readAllSecureValues(sharedAccessGroup = false): Promise<Record<string, string>> {
    return ClashKingNative.readAllLegacyFlutterSecureValues(sharedAccessGroup);
  }

  readPreferences(
    keys: readonly string[],
  ): Promise<Record<string, string | number | boolean | null>> {
    return ClashKingNative.readLegacyFlutterPreferences([...keys]);
  }

  readAllPreferences(): Promise<Record<string, string | number | boolean | null>> {
    return ClashKingNative.readAllLegacyFlutterPreferences();
  }
}

export function currentRuntimePlatform(): RuntimePlatform {
  if (Platform.OS === 'ios') return 'ios';
  if (Platform.OS === 'android') return 'android';
  return 'web';
}
